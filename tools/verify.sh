#!/usr/bin/env bash
# verify.sh — one command to check this repository against NEAR mainnet.
#
#   ./tools/verify.sh
#
# Requires: curl, python3. No keys, no wallet, no gas. Every call is a
# read-only RPC query.
#
# It answers:
#   1. Is every published .wasm byte-identical to the code running on chain?
#   2. Does the QC log's recorded hash equal the deployed hash?
#   3. Are the sealed contracts actually sealed (zero access keys)?
#   4. Is the token metadata what we say it is?
#
# Exit 0 = everything agrees with the chain.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0

# Public read-only endpoints. Tried in order, each retried, because a single
# free RPC will rate-limit a script that makes a dozen calls.
RPCS="${RPC:-https://rpc.mainnet.fastnear.com https://free.rpc.fastnear.com https://rpc.mainnet.near.org https://near.lava.build}"

say() { printf '%s\n' "$*"; }
rule() { printf '%s\n' "----------------------------------------------------------------------"; }

rpc() {
    # rpc <method> <params-json>  -> prints the JSON body, or nothing
    local method="$1" params="$2" body attempt rpc_url out
    body="{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$method\",\"params\":$params}"
    for attempt in 1 2 3; do
        for rpc_url in $RPCS; do
            out="$(curl -s --max-time 30 -H 'Content-Type: application/json' \
                    -d "$body" "$rpc_url" 2>/dev/null)"
            if printf '%s' "$out" | grep -q '"result"'; then
                printf '%s' "$out"
                return 0
            fi
            sleep 0.4
        done
    done
    return 1
}

# ---------------------------------------------------------------- 1. bytecode
say ""
say "1. PUBLISHED BYTECODE vs MAINNET"
rule

for wasm in "$ROOT"/bytecode/*.wasm; do
    [ -e "$wasm" ] || { say "  no .wasm files found"; FAIL=$((FAIL+1)); break; }
    account="$(basename "$wasm" .wasm)"
    remote="$(rpc query "{\"request_type\":\"view_account\",\"finality\":\"final\",\"account_id\":\"$account\"}" \
        | python3 -c 'import sys,json;print(json.load(sys.stdin).get("result",{}).get("code_hash",""))')"
    local_b58="$(python3 - "$wasm" <<'PY'
import hashlib, sys
alpha = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
data = open(sys.argv[1], "rb").read()
n = int.from_bytes(hashlib.sha256(data).digest(), "big")
s = ""
while n:
    n, r = divmod(n, 58)
    s = alpha[r] + s
print("1" * (32 - len(hashlib.sha256(data).digest().lstrip(b"\0"))) + s)
PY
)"
    if [ "$remote" = "$local_b58" ]; then
        printf '  MATCH     %-34s %s\n' "$account" "$remote"
    else
        printf '  MISMATCH  %-34s\n' "$account"
        printf '            local : %s\n' "$local_b58"
        printf '            chain : %s\n' "$remote"
        FAIL=$((FAIL+1))
    fi
done

# ------------------------------------------------------- 2. provenance chain
say ""
say "2. QC LOG -> DEPLOYED CONTRACT"
rule

qc="$(grep -o 'sha256 [a-f0-9]*' "$ROOT/build-logs/vm-gate-final/SUMMARY.txt" 2>/dev/null | awk '{print $2}' | head -1)"
if [ -z "$qc" ]; then
    say "  no recorded sha256 in build-logs/vm-gate-final/SUMMARY.txt"
    FAIL=$((FAIL+1))
else
    file_sha="$(python3 -c "import hashlib;print(hashlib.sha256(open('$ROOT/bytecode/unog.near.wasm','rb').read()).hexdigest())")"
    chain_b58="$(rpc query '{"request_type":"view_account","finality":"final","account_id":"unog.near"}' \
        | python3 -c 'import sys,json;print(json.load(sys.stdin).get("result",{}).get("code_hash",""))')"
    say "  QC log recorded : $qc"
    say "  published file  : $file_sha"
    say "  chain reports   : $chain_b58"
    if [ "$qc" = "$file_sha" ]; then
        say "  -> log and file agree"
    else
        say "  -> MISMATCH between log and file"
        FAIL=$((FAIL+1))
    fi
fi

# --------------------------------------------------------------- 3. sealed
say ""
say "3. SEALED CONTRACTS (zero access keys)"
rule

for account in unog.near zedec.near scp144.near zedei.near \
               mission.unog.near chancery.unog.near consulate.unog.near protocol.unog.near; do
    n="$(rpc query "{\"request_type\":\"view_access_key_list\",\"finality\":\"final\",\"account_id\":\"$account\"}" \
        | python3 -c 'import sys,json;r=json.load(sys.stdin).get("result");print(len(r["keys"]) if r else "ERR")')"
    if [ "$n" = "0" ]; then
        printf '  SEALED    %-24s 0 keys\n' "$account"
    elif [ "$n" = "ERR" ]; then
        printf '  ERROR     %-24s rpc failed\n' "$account"
        FAIL=$((FAIL+1))
    else
        printf '  NOT SEALED %-23s %s key(s)\n' "$account" "$n"
        FAIL=$((FAIL+1))
    fi
done

# ---------------------------------------------------------------- 4. token
say ""
say "4. TOKEN METADATA"
rule

meta="$(rpc query '{"request_type":"call_function","finality":"final","account_id":"unog.near","method_name":"ft_metadata","args_base64":"e30="}' \
    | python3 -c '
import sys, json
d = json.load(sys.stdin)
r = d.get("result")
if not r or "result" not in r:
    print("ERR"); raise SystemExit
# NEAR returns the return value as an array of byte values.
print(bytes(r["result"]).decode("utf-8", "ignore"))
')"
say "  $meta"

if printf '%s' "$meta" | grep -q '"decimals":24'; then
    say "  -> decimals 24, as documented"
else
    say "  -> decimals are NOT 24; documentation is wrong"
    FAIL=$((FAIL+1))
fi

# ---------------------------------------------------------------- verdict
say ""
rule
if [ "$FAIL" -eq 0 ]; then
    say "RESULT: everything agrees with mainnet."
    exit 0
fi
say "RESULT: $FAIL check(s) failed. The chain is right; this repository is wrong."
exit 1
