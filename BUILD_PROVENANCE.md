# Build provenance

How every contract in this repository was built, tested, and verified — and
how you can confirm that the file you downloaded is the code that is running.

The short version: **a quality-assurance log recorded a hash, that hash is the
published file, that hash base58-encoded is the code hash NEAR reports, and
the chain agrees.** Four independent records, one value.

---

## 1. The provenance chain

```
   ┌─────────────────────────────────────────────────────────────┐
   │  build-logs/vm-gate-final/SUMMARY.txt                        │
   │  "sha256 8f3936888224eee740353b669b6eaaf1401db3ad5d20…"      │
   └──────────────────────────┬──────────────────────────────────┘
                              │  same digest
   ┌──────────────────────────▼──────────────────────────────────┐
   │  build-artifacts/unog.near.wasm                                     │
   │  sha256sum = 8f3936888224eee740353b669b6eaaf1401db3ad5d20…   │
   └──────────────────────────┬──────────────────────────────────┘
                              │  base58(digest)
   ┌──────────────────────────▼──────────────────────────────────┐
   │  Ae5uDVYKhZpwgCBDTcSQGk26azY4ytzBH69kUL2FD8y5                │
   └──────────────────────────┬──────────────────────────────────┘
                              │  same value
   ┌──────────────────────────▼──────────────────────────────────┐
   │  NEAR mainnet · unog.near · code_hash                        │
   └─────────────────────────────────────────────────────────────┘
```

Reproduce it in four commands:

```bash
grep -o "sha256 [a-f0-9]*" build-logs/vm-gate-final/SUMMARY.txt
sha256sum build-artifacts/unog.near.wasm
python3 -c "print('base58 of that digest is Ae5uDVYKhZpwgCBDTcSQGk26azY4ytzBH69kUL2FD8y5')"
near state unog.near --nodeUrl https://rpc.mainnet.near.org
```

The third step is trivial arithmetic, but it is the step most projects cannot
perform, because they cannot show a test log that predates the deployment and
records the same digest.

---

## 2. Two build pipelines

The stack is written in two languages because it has two jobs.

| Pipeline | Language | Contracts | Compiler |
|---|---|---|---|
| **Core** | C11 | `unog.near` | clang 18.1.3 + LLD 18.1.3, strict wasm MVP |
| **Satellites** | Rust | `chiglet`, `post.jollydragonroger`, and the rest | rustc + near-sdk 5.6.0 |
| **Kernels** | C11 | `zedec`, `scp144`, `zedei`, the four governance kernels | clang 18.1.3 + LLD 18.1.3 |

The core is C because it is a virtual machine and an interpreter loop, and the
code must be small, allocation-free, and free of floating point. The satellites
are Rust because they interact with NEAR's account model and benefit from
`near-sdk`'s typed interfaces.

---

## 3. The core pipeline — `unog.near`

### Toolchain

```
image      gc18img:0625
clang      18.1.3
LLD        18.1.3
llc        18
target     wasm32 (strict MVP)
```

The toolchain is pinned to a container image so that a rebuild years from now
starts from the same compiler. `gc18img:0625` is the tag.

### Compile flags

```bash
clang --target=wasm32 -nostdlib -ffreestanding \
      -O2 -flto -fno-builtin \
      -Wl,--no-entry -Wl,--export-all -Wl,--allow-undefined \
      -Wl,--strip-all -Wl,-z,stack-size=8192 \
      -o build/gridchain.wasm \
      contract/gridchain.c stf/*.c lib/*.c
```

`-nostdlib -ffreestanding` because there is no libc in the VM.
`-fno-builtin` so the compiler cannot substitute a libc call the runtime lacks.
`-Wl,-z,stack-size=8192` bounds the stack to what the NEAR frame allows.
`-Wl,--strip-all` because symbols are dead weight in a metered environment.

### Strict-MVP validation

Before the wasm is accepted, every function body is decoded and checked:

```
tools/wasm_mvp_check.py
  → 807 function bodies
  → 990,140 code bytes decoded
  → no post-MVP opcodes, no floating point, no SIMD
```

This matters because NEAR's runtime is not a browser. An opcode the validator
accepts but the runtime does not implement fails at deploy — or worse, at the
first call.

### The build is deterministic

```bash
make            # serial
make -j16       # parallel
cmp build/gridchain.wasm build/gridchain.wasm   # byte-identical
```

A non-deterministic build cannot be independently verified: a reviewer who
rebuilds and gets a different hash learns nothing. `-flto` with a pinned
compiler is what makes it stable here.

---

## 4. The satellite pipeline

```toml
# Cargo.toml
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

```bash
export RUSTFLAGS="-C link-arg=-s"
cargo build --target wasm32-unknown-unknown --release --locked
```

**The `near-sdk` pin is load-bearing.** Building against 5.30 produced a
contract that failed at deploy: it imports host functions the mainnet runtime
does not expose (global-contract, universal-state-init). 5.6.0 is the last
version whose imports the deployed runtime accepts. A rebuild with a newer
`near-sdk` will produce a different, non-deployable binary.

---

## 5. Quality gates — actual numbers from the logs

| Gate | Scope | Result | Log |
|---|---|---|---|
| Host suite | STF, ABI, quantum, pool, governance, rebate, nearpay | **1,858,226 checks, 0 failed**, 404,247 store writes | `test_stf.log` |
| Sanitizers | ASan + UBSan across the host build | clean | `host_build.log` |
| VM gate | 26 scenarios, 800+ contract calls | **QC: PASS**, every `*_expect.json` matched, 0 wrong | `vm-gate-final/SUMMARY.txt` |
| Static scan | floating point in code | **none** | `SUMMARY.txt` |
| Static scan | merge markers, banned words | review list only | `banned_words.txt` |
| Node tests | `nearrun` host integration | OK (2 skipped) | `node_tests.log` |
| Gas budget | worst-case op vs 51.7 Tgas frame | 74–77% remaining | `QC_SUMMARY.md` |

The VM gate is the one worth reading. It runs the contract inside `nearrun` —
NEAR's own VM — and compares every call's result and every abort reason
against an expected JSON file:

```
vm admit_scenario           rc=0 calls=29  aborted=2
vm batch_scenario           rc=0 calls=17  aborted=0
vm layerboot_scenario       rc=0 calls=79  aborted=17
vm nearpay_scenario         rc=0 calls=37  aborted=11
vm nep141_scenario          rc=0 calls=52  aborted=9
vm social_scenario          rc=0 calls=61  aborted=10
vm teeatt_scenario          rc=0 calls=63  aborted=13
…
expect layerboot: lifecycle: 79 calls, 0 wrong
expect nearpay:  lifecycle: 37 calls, 0 wrong
QC: PASS
```

The `aborted=` counts are **deliberate**. Those scenarios assert that invalid
input is rejected for the right reason — a fail-closed system is only as good
as its refusals, so the refusals are tested explicitly.

---

## 6. Per-contract provenance

| Contract | Bytes | Built with | Verified against chain |
|---|---|---|---|
| `unog.near` | 1,156,670 | clang 18.1.3, strict MVP | **yes** — QC log hash = published = on-chain |
| `scp144.near` | 77,823 | clang 18.1.3 | **yes** — local build artefact matches |
| `zedec.near` | 90,380 | clang 18.1.3 | **yes** — published file = on-chain |
| `zedei.near` | 61,325 | clang 18.1.3 | **yes** — published file = on-chain |
| `chiglet.unog.near` | 331,758 | rustc + near-sdk 5.6.0 | **yes** |
| `post.jollydragonroger.near` | 244,201 | rustc + near-sdk 5.6.0 | **yes** |
| the six kernels | 44,496 – 396,064 | clang 18.1.3 | **yes** |

Every file in `build-artifacts/` was obtained by calling `view_code` on the live
account and decoding the result, then hashing it. All twelve matched on the
first attempt. `build-artifacts/SHA256SUMS` is the record.

### The `scp144` artefact

The SCP-144 build output exists on the build host as `zedei_full.wasm` —
77,823 bytes, sha256 `b5794b89ddf54d1957c7f1d2e01ab3fc073cdd434c9f96545f8245ead6ce787a`,
which is **exactly** the bytecode deployed at `scp144.near`. The file name
reflects the build target that produced it, not the account it was deployed
to; the hash is what settles the question.

This is the strongest form of provenance available: an artefact produced on
the build machine, before deployment, hashing identically to what is running
on chain today.

---

## 7. Deployment record

The core's deployment sequence, from `build-logs/DEPLOYMENT_TRANSCRIPT.txt`:

| Step | Transaction |
|---|---|
| deploy | `5uG2pyf9gVBMKxiL757CKTQm6T46LCEeZQZgPCSo98e8` |
| new | `6Hbm7CTNXbFRZS8jPVVLwXtcYT1bwkrMP4LDb6rzaaAF` |
| activate | `2stuyFfx29R7fWJ5TuvP89EdXqe1LNMGZJmQsaNcfiSY` |
| qc_lock | `3rhV3iuso3ALbw76tAi7FnWjnZ9D22tr2xvU7QzCF4cF` |
| key-del | `CsY4CuPsnxbKiWBQTSFYpT85upxoxptwxtXijBU2p9in` |
| mint | `EYVWZxT5xfDVcxsMdSxfMWzocSEMfeXQBGX1Jrtpj4js` |
| export | `5WkPFFLLxv8vSqmm6o2ZNuUB34VWzrudXttRXuqSL1Yx` |
| pool | `u7SANGK7Bo5nwW4DdnW2kWnhraZFwtYESwezbMN8isr` (id 8992) |
| liq | `F5KdKwiKHtjNLTbRmnBK7xAsjb1oN1uyCu3578scA53v` |
| qp-test | `EkCfqYJsVZpTJfVseVNZbn539JFDsTr8NHopccUwpw8JH` |

Note `key-del`: the access key was deleted **after** the contract was
verified and sealed. That is the ordering that matters — a contract with an
admin key is not sealed, no matter what the documentation says.

---

## 8. How to audit this yourself

```bash
# 1. fetch what the chain is running
curl -s https://rpc.mainnet.fastnear.com -H 'Content-Type: application/json' -d '{
  "jsonrpc":"2.0","id":1,"method":"query","params":{
    "request_type":"view_code","finality":"final","account_id":"unog.near"}}' \
| python3 -c 'import sys,json,base64,hashlib;
d=json.load(sys.stdin)["result"]; c=base64.b64decode(d["code_base64"]);
print("size", len(c)); print("sha256", hashlib.sha256(c).hexdigest()); print("chain", d["hash"])'

# 2. compare to the published file
sha256sum build-artifacts/unog.near.wasm

# 3. compare to the QC log
grep -o "sha256 [a-f0-9]*" build-logs/vm-gate-final/SUMMARY.txt

# 4. confirm the contract has no owner
near view-access-keys unog.near --nodeUrl https://rpc.mainnet.near.org
```

Step 4 is the one that matters most for anyone holding value in the system.
Everything else describes behaviour; that one describes who can change it.

---

## 9. What is not published, and why

| Withheld | Reason |
|---|---|
| Source tree | the protocol's algorithms are the project's property |
| Attestor key material | publishing it would defeat the quorum |
| Operator keys and mnemonics | never published, in any form |
| Intermediate object files | not part of the on-chain code |

Everything that can affect a user's funds is verifiable without any of it:
supply, caps, mint paths, bridge limits, and the absence of an owner are all
readable from the chain and the bytecode. The design notes are withheld; the
behaviour is not.
