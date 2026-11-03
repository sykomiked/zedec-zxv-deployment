#!/usr/bin/env python3
"""Pre-publication check for the zedec-zxv-deployment repository.

Run before every push:

    python3 tools/prepublish_check.py

Three questions, answered with evidence:

  1. Does any published file contain key material?
  2. Does every published .wasm match the code running on mainnet?
  3. Does any commit in the local history contain key material?

Exit 0 means safe to publish. Anything else means stop.

Stdlib only. No network access is required for checks 1 and 3.
"""

import hashlib
import json
import os
import re
import subprocess
import sys
import urllib.request

RPC = "https://rpc.mainnet.fastnear.com"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BYTECODE = os.path.join(ROOT, "bytecode")

# Secrets known to have leaked once. Stored as SHA-256 digests so that this
# file does not reintroduce them. Any token whose digest appears here is a
# failure, wherever it is found.
FORBIDDEN_DIGESTS = {
    "8bd8fb5a89d0ac55c12ba97c683b18fcd0700b99832e0ef0f058ea32031140dc",  # mint seed
    "773f8e008e40441c08ea90cf75efdd99db0b7aa6d88a0f8015071a0304c6893a",  # demo-2 key
    "93fc284a24cefc96998fa11d333a7aae9c1a98ccd49c2486338e847a890a6617",  # chiglet prefix
}

# Patterns that indicate key material of any kind, known or not.
GENERIC_PATTERNS = [
    ("ed25519 private key", re.compile(r"ed25519:[1-9A-HJ-NP-Za-km-z]{80,}")),
    ("ml-dsa private key", re.compile(r"ml-dsa-6[45](?:-hash)?:[1-9A-HJ-NP-Za-km-z]{100,}")),
    ("PEM block", re.compile(r"-----BEGIN [A-Z ]*(?:PRIVATE KEY|OPENSSH|PGP)")),
    ("assigned secret", re.compile(
        r"(?:private_key|secret_key|privateKey|secretKey|mnemonic|seed_phrase)"
        r"['\"]?\s*[:=]\s*['\"]?[A-Za-z0-9+/=_\-]{20,}")),
    ("hex seed (64 bytes)", re.compile(r"\b[0-9a-f]{128}\b")),
    ("solana keypair array", re.compile(r"\[\s*\d{1,3}(?:\s*,\s*\d{1,3}){63}\s*\]")),
]

# Tokens worth digesting: anything that could be a key.
TOKEN_PATTERNS = [
    re.compile(r"[0-9a-f]{64}"),
    re.compile(r"[1-9A-HJ-NP-Za-km-z]{44,}"),
    re.compile(r"(?:ed25519|ml-dsa-6[45](?:-hash)?):[1-9A-HJ-NP-Za-km-z]+"),
]

SKIP_DIRS = {".git", "node_modules", "target", "__pycache__"}


def sh(args, **kw):
    return subprocess.run(args, cwd=ROOT, capture_output=True, text=True, **kw)


def tracked_files():
    out = sh(["git", "ls-files"])
    return out.stdout.splitlines() if out.returncode == 0 else []


def digest_hits(text):
    """Return the set of forbidden digests present in a block of text."""
    found = set()
    for pat in TOKEN_PATTERNS:
        for m in pat.finditer(text):
            d = hashlib.sha256(m.group(0).encode()).hexdigest()
            if d in FORBIDDEN_DIGESTS:
                found.add(d)
    return found


def scan_file(path):
    findings = []
    full = os.path.join(ROOT, path)
    if path.endswith(".wasm"):
        return findings
    try:
        with open(full, encoding="utf-8", errors="ignore") as fh:
            text = fh.read()
    except OSError:
        return findings
    for label, pat in GENERIC_PATTERNS:
        for m in pat.finditer(text):
            line = text[: m.start()].count("\n") + 1
            findings.append((label, line))
    for d in digest_hits(text):
        findings.append((f"forbidden secret {d[:12]}", 0))
    return findings


def base58(b):
    alpha = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    n = int.from_bytes(b, "big")
    s = ""
    while n:
        n, r = divmod(n, 58)
        s = alpha[r] + s
    return "1" * (len(b) - len(b.lstrip(b"\0"))) + s


def chain_code_hash(account):
    body = json.dumps({
        "jsonrpc": "2.0", "id": 1, "method": "query",
        "params": {"request_type": "view_account", "finality": "final",
                   "account_id": account},
    }).encode()
    req = urllib.request.Request(RPC, data=body,
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return json.load(r).get("result", {}).get("code_hash")
    except Exception as exc:  # noqa: BLE001 - reported, not raised
        return f"RPC-ERROR {exc}"


def verify_wasm():
    rows = []
    if not os.path.isdir(BYTECODE):
        return rows
    for name in sorted(os.listdir(BYTECODE)):
        if not name.endswith(".wasm"):
            continue
        account = name[: -len(".wasm")]
        with open(os.path.join(BYTECODE, name), "rb") as fh:
            data = fh.read()
        rows.append((account, len(data),
                     base58(hashlib.sha256(data).digest()),
                     chain_code_hash(account)))
    return rows


def history_scan():
    """Every blob reachable from any ref, checked for forbidden secrets."""
    revs = sh(["git", "rev-list", "--all"]).stdout.split()
    if not revs:
        return []
    # collect every distinct blob once
    blobs = set()
    for rev in revs:
        out = sh(["git", "ls-tree", "-r", rev]).stdout
        for line in out.splitlines():
            parts = line.split()
            if len(parts) == 4 and parts[1] == "blob":
                blobs.add(parts[2])
    hits = []
    for blob in blobs:
        data = subprocess.run(["git", "cat-file", "-p", blob], cwd=ROOT,
                              capture_output=True).stdout
        try:
            text = data.decode("utf-8", "ignore")
        except Exception:  # noqa: BLE001
            continue
        for d in digest_hits(text):
            hits.append((blob[:12], d[:12]))
    return hits


def main():
    failures = 0

    print("=" * 72)
    print("1. KEY MATERIAL IN PUBLISHED FILES")
    print("=" * 72)
    files = tracked_files()
    bad = []
    for f in files:
        for label, line in scan_file(f):
            bad.append((f, label, line))
    if bad:
        for f, label, line in bad:
            where = f":{line}" if line else ""
            print(f"  FAIL  {f}{where}  {label}")
        failures += len(bad)
    else:
        print(f"  PASS  {len(files)} files scanned, no key material")

    print()
    print("=" * 72)
    print("2. BYTECODE vs MAINNET")
    print("=" * 72)
    rows = verify_wasm()
    if not rows:
        print("  FAIL  no .wasm files found")
        failures += 1
    for account, size, local, remote in rows:
        ok = local == remote
        print(f"  {'MATCH' if ok else 'MISMATCH':<9} {account:<34} {size:>9,} B")
        if not ok:
            print(f"            local : {local}")
            print(f"            chain : {remote}")
            failures += 1
    print(f"  {len(rows)} contract(s) checked")

    print()
    print("=" * 72)
    print("3. KEY MATERIAL IN GIT HISTORY")
    print("=" * 72)
    hits = history_scan()
    if hits:
        for blob, d in hits:
            print(f"  FAIL  blob {blob} contains forbidden secret {d}")
        failures += len(hits)
    else:
        print("  PASS  no forbidden secret in any reachable commit")

    print()
    print("=" * 72)
    if failures:
        print(f"RESULT: {failures} problem(s). DO NOT PUBLISH.")
        return 1
    print("RESULT: clean. Safe to publish.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
