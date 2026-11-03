# The C kernel — build primitives

The kernel is C, not Rust. This is the short version of how it is built and
why each choice matters. Full detail in [`REPRODUCIBILITY.md`](REPRODUCIBILITY.md).

---

## What "the kernel" means here

| Contract | Source | Built to |
|---|---|---|
| `zedec.near` | C11 | wasm32, strict MVP — **the entry point** |
| `scp144.near` | C11 | wasm32, strict MVP — post-quantum engine |
| `zedei.near` | C11 | wasm32, strict MVP — interface |
| `unog.near` | C11 | wasm32, strict MVP — the sealed core |

All four are C11 compiled to WebAssembly. The Rust satellites
(`chiglet`, `post.jollydragonroger`) sit on top.

---

## Toolchain

```
image   gc18img:0625        Ubuntu, clang 18.1.3, LLD 18.1.3, llc-18
target  wasm32              strict MVP — no post-MVP opcodes, no SIMD, no floats
```

Pinned to a container image so a rebuild years from now starts from the same
compiler. A different clang produces a different hash, which makes the build
unverifiable.

---

## The command

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

Run it through the script:

```bash
./build.sh core
./build.sh determinism     # proves the build is byte-identical across runs
```

---

## Why each flag is load-bearing

| Flag | Consequence if removed |
|---|---|
| `-nostdlib -ffreestanding` | the binary links against a libc the VM does not have |
| `-fno-builtin` | the compiler substitutes `memcpy`/`memset` calls the runtime lacks |
| `-flto` | output stops being deterministic across runs |
| `-z stack-size=8192` | the stack exceeds what a NEAR frame allows; calls die mid-execution |
| `--strip-all` | symbols inflate a metered binary for no benefit |
| `-Werror` | warnings that were real bugs (an uninitialised field, a truncating cast) ship silently |

The `-Wno-maybe-uninitialized` flag appears in the host build only, where GCC
false-positives on the arena allocator. The wasm build uses full `-Werror`.

---

## Strict-MVP validation

Before a wasm is accepted, every function body is decoded and checked:

```
tools/wasm_mvp_check.py
  → 807 function bodies
  → 990,140 code bytes decoded
  → no post-MVP opcodes, no floating point, no SIMD
```

This matters because NEAR's runtime is not a browser. An opcode the validator
accepts but the runtime does not implement fails at deploy — or worse, at the
first call.

---

## Determinism

```bash
make            # serial
make -j16       # parallel
cmp build/gridchain.wasm build/gridchain.wasm    # byte-identical
```

A non-deterministic build cannot be independently verified: a reviewer who
rebuilds and gets a different hash learns nothing. `-flto` with a pinned
compiler is what makes it stable.

---

## What the kernel actually contains

| | |
|---|---|
| Operations | 151 |
| ABI descriptors | 214 |
| Governance kinds | 46 |
| Booted layers | 12 |
| Floating point | **none** |
| Heap allocation in hot paths | **none** — pre-allocated arenas |
| Banned constructs | float/double for money, unbounded loops, dynamic dispatch |

The rule throughout is integer arithmetic with fixed scale, bounded rings with
an explicit full check, and fail-closed validation: check, reserve, compute,
mutate, commit — nothing written before it is checked.

---

## Evidence it worked

| Gate | Result | Log |
|---|---|---|
| Host suite, ASan + UBSan | **1,858,226 checks, 0 failed** | `build-logs/test_stf.log` |
| VM gate, 26 scenarios in NEAR's runtime | **QC: PASS**, 0 wrong | `build-logs/vm-gate-final/SUMMARY.txt` |
| Float/double in code | none | same |
| Merge markers | none | same |
| Gas budget | 74–77% of a frame remaining at worst case | `QC_SUMMARY.md` |

And the link between the build and the chain:

```
QC log recorded : 8f3936888224eee740353b669b6eaaf1401db3ad5d20566c50c0c5d961fc3050
published file  : 8f3936888224eee740353b669b6eaaf1401db3ad5d20566c50c0c5d961fc3050
chain reports   : Ae5uDVYKhZpwgCBDTcSQGk26azY4ytzBH69kUL2FD8y5   (= base58 of that digest)
```

Tested, published and running are the same bytes.
