# Build reproducibility

Publishing bytecode is only useful if someone can tell **how** it was made.
This document gives the toolchain, the flags, the build scripts and the
verification procedure — enough to reproduce the build environment and audit
the process. It does not contain the protocol's internal algorithms, and we
make no apology for that.

---

## 1. Toolchain

| Component | Version | Why pinned |
|---|---|---|
| Rust | stable, `wasm32-unknown-unknown` target | NEAR's runtime target |
| `near-sdk` | **exactly 5.6.0** | 5.30 imports host functions the mainnet runtime does not expose |
| `near-cli` / `near-cli-rs` | current | deploy and view |
| `cargo-near` | current | reproducible packaging |
| Linker flags | `-C link-arg=-s` | strip; the runtime does not need symbols |

**The near-sdk pin is not cosmetic.** Building against 5.30 produced a
contract that failed at deploy with unsupported host functions
(global-contract, universal-state-init). 5.6.0 is the last version whose
imports the deployed runtime accepts. Any rebuild must use it.

```toml
# Cargo.toml — the relevant lines
[lib]
crate-type = ["cdylib", "rlib"]

[dependencies]
near-sdk = "=5.6.0"

[profile.release]
codegen-units = 1
opt-level = "z"
lto = true
debug = false
panic = "abort"
strip = true
```

---

## 2. Build script

The build is one command per contract. Nothing exotic, nothing hidden.

```bash
#!/usr/bin/env bash
# build.sh — build a NEAR contract reproducibly
set -euo pipefail

TARGET=wasm32-unknown-unknown
export RUSTFLAGS="-C link-arg=-s"

rustup target add "$TARGET"

cargo build \
  --target "$TARGET" \
  --release \
  --locked

# cargo names it <crate>.wasm; we name it <account>.wasm
cp "target/$TARGET/release/${1}.wasm" "bytecode/${2}.wasm"

sha256sum "bytecode/${2}.wasm"
```

Usage:

```bash
./build.sh zedec  zedec.near
./build.sh scp144 scp144.near
./build.sh zedei  zedei.near
./build.sh gridchain unog.near
./build.sh routelock chiglet.unog.near
./build.sh mintdesk post.jollydragonroger.near
```

---

## 3. Determinism

Two properties were tested, not assumed:

| Test | Result |
|---|---|
| plain `cargo build --release` vs `-j16` parallel | **byte-identical** |
| rebuild on a clean target directory | **byte-identical** |

That matters because a non-deterministic build cannot be independently
verified — a reviewer who rebuilds and gets a different hash learns nothing.
`codegen-units = 1` and `lto = true` are what make it stable.

```bash
# reproduce the determinism check
cargo clean && cargo build --target wasm32-unknown-unknown --release --locked
sha256sum target/wasm32-unknown-unknown/release/*.wasm > /tmp/a.txt

cargo clean && cargo build --target wasm32-unknown-unknown --release --locked -j16
sha256sum target/wasm32-unknown-unknown/release/*.wasm > /tmp/b.txt

diff /tmp/a.txt /tmp/b.txt && echo "deterministic"
```

---

## 4. Verification — the part that actually matters

You do not have to trust our build. You can compare the published file to the
code running on chain, which is the only thing that can steal funds.

```bash
# 1. fetch the live code and its hash
curl -s https://rpc.mainnet.fastnear.com -H 'Content-Type: application/json' -d '{
  "jsonrpc":"2.0","id":1,"method":"query","params":{
    "request_type":"view_code","finality":"final","account_id":"zedec.near"}}' \
| python3 -c '
import sys, json, base64, hashlib
d = json.load(sys.stdin)["result"]
code = base64.b64decode(d["code_base64"])
print("size:", len(code))
print("chain hash:", d["hash"])
print("sha256:", hashlib.sha256(code).hexdigest())
'

# 2. compare against the published file
sha256sum bytecode/zedec.near.wasm

# 3. the two must be equal, and the base58 form of the digest
#    must equal the chain hash
```

All twelve published files were obtained this way and every one matched on
the first attempt. `bytecode/SHA256SUMS` is the record.

---

## 5. Quality gates

Before any deployment the build went through:

| Gate | Scope | Result |
|---|---|---|
| Host test suite | STF, ABI, quantum, pool, governance | pass |
| VM scenario suite | boot, layers, ops, error paths | pass |
| ASan + UBSan | memory safety across the host build | clean |
| Check count | 1,836,568 assertions | **0 failed** |
| Frame budget | worst-case execution per op | 74–77% of frame remaining |
| Boot self-check | 12 layers, 10/10 quantum self-test | pass |

See `QC_SUMMARY.md` for the full record.

---

## 6. Deployment procedure

The deployment sequence is fixed and recorded for every contract:

```bash
near contract deploy <account>.near \
  use-file bytecode/<account>.near.wasm \
  with-init-call <init_method> \
    json-args '<args>' \
    attached-deposit '0 NEAR' \
    with-key <key> \
  network-config mainnet \
  sign-with-keychain send
```

Notes that cost us real money to learn:

- **`near contract deploy` preserves storage.** A redeploy does not wipe
  state, so an incompatible prior state will break the new code. Migration or
  init-ignore-state handling is required, not optional.
- **Deploy, then verify.** Read back `code_hash` and compare to the local
  SHA-256 before considering a deployment complete. An accepted transaction
  is not a confirmed deployment.
- **Sealed contracts are sealed afterwards.** `unog.near`, `zedec.near`,
  `scp144.near`, `zedei.near` and the four governance kernels have **zero
  access keys**. That is a deliberate, irreversible act, performed after
  verification.

---

## 7. What is not published

The published WASM is the complete, executable contract. What we do not
publish:

- the internal algorithm designs (curve derivation, lane matrix construction,
  the paraconsistent evaluation order);
- the attestor key material (never published, in any form);
- the operator's private keys and mnemonics.

The bytecode is the ground truth for *behaviour*. The design notes are the
project's intellectual property. A reviewer can verify everything that can
affect their funds — supply, caps, keys, mint paths, bridge limits — from the
chain and the bytecode alone. Nothing that matters for safety is withheld.

---

## 8. Environment fingerprint

```
target      : wasm32-unknown-unknown
profile     : release (opt-level=z, lto=true, codegen-units=1, panic=abort)
linker      : -C link-arg=-s
near-sdk    : 5.6.0 (exact)
rust        : stable
```

If you rebuild with these settings and get a different hash, the difference is
in the source tree, not in the toolchain — and we would want to know.
