# Compilation artefacts

The build outputs that sit *around* the final bytecode — enough to see how the
binary was produced without publishing the compiler's internal representation.

| File | Size | SHA-256 (first 16) | What it is |
|---|---|---|---|
| `gridchain.lto.wasm` | 1,155,965 B | `ccd396892cbabb09` | the **intermediate** wasm after LTO, before the final link |
| `gridchain.lto.wasm.resolution.txt` | 40,543 B | `c88eb04326c90b06` | the linker's symbol resolution map |
| `scp144.near.local-build.wasm` | 77,823 B | `b5794b89ddf54d19` | a **local build output that matches mainnet exactly** |

---

## Why each one matters

### `gridchain.lto.wasm` — the step before the deployed binary

The deployed `unog.near` is 1,156,670 bytes. This intermediate is **1,155,965**
— 705 bytes smaller, because the final link has not yet appended the last
sections.

Having both means a reviewer can see that the build was a process, not a
single opaque jump from source to a hash:

```
sources  →  LTO  →  gridchain.lto.wasm (1,155,965)  →  final link  →  gridchain.wasm (1,156,670)
                                                                       ↓ sha256 8f393688…
                                                                       ↓ base58
                                                              Ae5uDVYK…  (deployed)
```

### `gridchain.lto.wasm.resolution.txt` — the linker's own account

Every symbol, where it came from, and whether it was resolved. This is the
file a linker writes when it has to prove to itself that nothing is missing.
It answers the question *"is this binary self-contained?"* better than any
prose can.

```
/tmp/gridchain-3dec9b.o
-r=/tmp/gridchain-3dec9b.o,gc_new,p
-r=/tmp/gridchain-3dec9b.o,gc_boot,p
```

`p` means defined and pulled in. An `u` would mean undefined — a symbol the
runtime would have to supply.

### `scp144.near.local-build.wasm` — the strongest artefact in the repository

This file was produced on the build machine, **before deployment**, from the
SCP-144 build target. Its SHA-256 is:

```
b5794b89ddf54d1957c7f1d2e01ab3fc073cdd434c9f96545f8245ead6ce787a
```

That is byte-for-byte identical to `../scp144.near.wasm`, which was
pulled from the chain with `view_code` and matches the code hash NEAR reports
for `scp144.near`:

```
DDQ4uJXM26WhRoYfRPgQcUKPpybzhGrBXmCbK7e85dmN9
```

So for `scp144.near` the chain of custody has no gap at all: **built here →
hashed here → deployed there → still running there.** The file name reflects
the build target that produced it, not the account it was deployed to; the
hash settles the question.

```bash
sha256sum build-artifacts/scp144.near.local-build.wasm ../scp144.near.wasm
# both lines must be identical
```

---

## What is deliberately not published

| Withheld | Reason |
|---|---|
| `*.bc` LLVM bitcode (`preopt`, `internalize`, `opt`, `precodegen`) | contains the full intermediate representation of the source — that is the protocol's algorithms, not its behaviour |
| `gridchain.mvp.o`, `gridchain.lto.wasm.lto.o` | object files with the same problem |
| `test_stf` (11.9 MB) | host test binary; the logs from running it are published instead |
| source tree | the design notes are the project's property |

The line is deliberate: **artefacts that show the pipeline are published;
artefacts that expose the algorithms are not.** A reviewer can verify
everything that can affect their funds — supply, caps, keys, mint paths,
bridge limits, and the absence of an owner — from the chain and the deployed
bytecode alone.

---

## Verification

```bash
# the intermediate is not the deployed binary — and should not be
sha256sum build-artifacts/gridchain.lto.wasm
# ccd396892cbabb09…   (≠ 8f393688…, the deployed one)

# the local build of scp144 IS the deployed binary
sha256sum build-artifacts/scp144.near.local-build.wasm ../scp144.near.wasm
# b5794b89ddf54d19…   (identical)
```

Run `python3 tools/prepublish_check.py` to confirm every published `.wasm`
still matches mainnet before any push.
