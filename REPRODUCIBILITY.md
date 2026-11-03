# Reproducibility — what you can and cannot do from this repository

There are two different claims, and conflating them is how projects mislead
people. This document separates them.

| Claim | Status |
|---|---|
| **Verifiable** — the published bytecode is the code running on chain | **yes, completely, no trust required** |
| **Auditable** — you can see how it was built, with what toolchain, and what tests it passed | **yes** |
| **Rebuildable** — you can compile this repository and get the same bytes | **no** — one input is withheld: the source |

We would rather state that plainly than let you discover it.

---

## 1. Verify it yourself — one command

```bash
git clone https://github.com/sykomiked/zedec-zxv-deployment
cd zedec-zxv-deployment
./tools/verify.sh
```

Output on a clean checkout:

```
1. PUBLISHED BYTECODE vs MAINNET
  MATCH     unog.near                          Ae5uDVYKhZpwgCBDTcSQGk26azY4ytzBH69kUL2FD8y5
  MATCH     zedec.near                         ATUV46Keb91L32RGU5X858nNtTZ6csH9HARfE86MtMo
  MATCH     scp144.near                        DDQ4uJXM26WhRoYfRPgQcUKPpybzhGrBXmCbK7e85dmN9
  … 12 contracts …

2. QC LOG -> DEPLOYED CONTRACT
  QC log recorded : 8f3936888224eee740353b669b6eaaf1401db3ad5d20566c50c0c5d961fc3050
  published file  : 8f3936888224eee740353b669b6eaaf1401db3ad5d20566c50c0c5d961fc3050
  chain reports   : Ae5uDVYKhZpwgCBDTcSQGk26azY4ytzBH69kUL2FD8y5
  -> log and file agree

3. SEALED CONTRACTS (zero access keys)
  SEALED    unog.near                0 keys
  SEALED    zedec.near               0 keys
  … 8 contracts …

4. TOKEN METADATA
  {"spec":"ft-1.0.0","name":"TIAMAT","symbol":"PQOS","decimals":24}
  -> decimals 24, as documented

RESULT: everything agrees with mainnet.
```

No keys. No wallet. No gas. Every call is a read-only RPC query.

**This is the claim that protects your funds**, and it is fully reproducible:
the same inputs always give the same verdict, and the chain is the authority.

---

## 2. The build, exactly

The published binaries were produced by this procedure, and nothing else.

### The core — `unog.near`

| | |
|---|---|
| Language | C11 |
| Toolchain image | **`gc18img:0625`** — Ubuntu, clang 18.1.3, LLD 18.1.3, llc-18 |
| Target | `wasm32`, strict MVP |
| Flags | see below |
| Determinism | plain and `-j16` builds are **byte-identical** |

```bash
clang --target=wasm32 \
      -nostdlib -ffreestanding \
      -O2 -flto -fno-builtin \
      -Wall -Wextra -Werror \
      -Wl,--no-entry -Wl,--export-all -Wl,--allow-undefined \
      -Wl,--strip-all -Wl,-z,stack-size=8192 \
      -o build/gridchain.wasm \
      contract/*.c stf/*.c lib/*.c
```

Each flag is load-bearing:

| Flag | Why |
|---|---|
| `-nostdlib -ffreestanding` | there is no libc inside the VM |
| `-fno-builtin` | the compiler must not substitute a libc call the runtime lacks |
| `-flto` | whole-program optimisation; also what makes the build deterministic |
| `-z stack-size=8192` | bounded to what a NEAR frame allows |
| `--strip-all` | symbols are dead weight in a metered runtime |

### The satellites — `chiglet`, `post.jollydragonroger`, and the rest

| | |
|---|---|
| Language | Rust |
| Dependency | **`near-sdk = "=5.6.0"`** — exact pin |
| Target | `wasm32-unknown-unknown` |
| Profile | `opt-level="z"`, `lto=true`, `codegen-units=1`, `panic="abort"`, `strip=true` |

```bash
RUSTFLAGS="-C link-arg=-s" \
  cargo build --target wasm32-unknown-unknown --release --locked
```

**The `near-sdk` pin is not cosmetic.** Building against 5.30 produced a
contract that failed at deploy: it imports host functions the mainnet runtime
does not expose. 5.6.0 is the last version whose imports the deployed runtime
accepts. A rebuild with a newer `near-sdk` gives a different, non-deployable
binary.

`build.sh` in the repository root runs both of these.

---

## 3. The evidence the build was real

| Evidence | Where |
|---|---|
| The QC log recorded the hash **before** deployment | `build-logs/vm-gate-final/SUMMARY.txt` |
| That hash equals the published file | `bytecode/unog.near.wasm` |
| That hash, base58-encoded, is the on-chain code hash | `Ae5uDVYK…` |
| An LTO intermediate 705 bytes smaller than the final | `build-artifacts/gridchain.lto.wasm` |
| The linker's symbol resolution map | `build-artifacts/gridchain.lto.wasm.resolution.txt` |
| A local build that matches mainnet byte-for-byte | `build-artifacts/scp144.near.local-build.wasm` |
| 1,858,226 assertions, 0 failed | `build-logs/test_stf.log` |
| 26 VM scenarios inside NEAR's own runtime, 0 wrong | `build-logs/vm-gate-final/SUMMARY.txt` |

The last two matter most: they are the output of running the thing, not a
description of intending to.

### The `scp144.near` artefact

`build-artifacts/scp144.near.local-build.wasm` was produced on the build
machine before deployment. Its SHA-256 is:

```
b5794b89ddf54d1957c7f1d2e01ab3fc073cdd434c9f96545f8245ead6ce787a
```

That is byte-for-byte identical to `bytecode/scp144.near.wasm`, whose code
hash on chain is `DDQ4uJXM26WhRoYfRPgQcUKPpybzhGrBXmCbK7e85dmN9`.

**Built here → hashed here → deployed there → still running there.** For that
contract there is no gap in custody at all.

---

## 4. Why you cannot rebuild it from this repository

The source tree is not published. That is a deliberate choice, stated openly:

- the collateral curve derivation,
- the paraconsistent evaluation order,
- the SCP-144 lattice construction,
- the lane assembly

are the project's intellectual property. Publishing them would give away the
design; publishing the *bytecode* gives away nothing that is not already on
chain, because the bytecode **is** the chain.

**What this costs you:** you cannot compile the repository and get the same
hash. **What it does not cost you:** any ability to check whether the system
can take your money. Supply, caps, mint paths, bridge limits, fee, and the
absence of an owner are all readable from the chain and the bytecode without
a line of source.

If the source were published, the recipe above plus the pinned toolchain would
reproduce the binary — that is what the determinism check exists to guarantee.

---

## 5. Audit checklist

An auditor with an hour should be able to tick every line.

- [ ] `./tools/verify.sh` exits 0
- [ ] All 12 published `.wasm` match their on-chain code hashes
- [ ] `unog.near` has **zero** access keys
- [ ] The seven other sealed kernels have **zero** access keys
- [ ] `ft_metadata` returns `decimals: 24`, `symbol: PQOS`
- [ ] The QC log hash equals the published `unog.near.wasm` hash
- [ ] `build-artifacts/scp144.near.local-build.wasm` equals `bytecode/scp144.near.wasm`
- [ ] `FORENSIC_LEDGER.md` contains the failed transactions as well as the successful ones
- [ ] `ARCHITECTURE.md` §8 states plainly what is and is not proven
- [ ] `tools/prepublish_check.py` exits 0 (no key material in files or history)

If any of those fail, **the chain is right and this repository is wrong** — and
we would want to know.

---

## 6. What is withheld, and why

| Withheld | Reason |
|---|---|
| Source tree | the protocol's algorithms are the project's property |
| `*.bc` LLVM bitcode, `.o` object files | same — they carry the full IR |
| Attestor key material | publishing it would defeat the 3-of-5 quorum |
| Operator keys, mnemonics, seeds | never published, in any form |

Everything that can affect a user's funds is verifiable without any of it.
