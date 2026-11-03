# Build logs

The actual output of the build and quality gates, not a summary written
afterwards.

| File | What it is |
|---|---|
| `host_build.log` | the exact compile line for the host test binary |
| `test_stf.log` | the host suite: **1,858,226 checks, 0 failed**, 404,247 store writes |
| `vm-gate-final/SUMMARY.txt` | the VM gate — 26 scenarios inside `nearrun`, every expectation matched, **QC: PASS** |
| `vm-gate-final/node_tests.log` | `nearrun` host integration tests |
| `DEPLOYMENT_TRANSCRIPT.txt` | the ten mainnet transactions of the core deployment, in order |

## The one line worth finding

`vm-gate-final/SUMMARY.txt` contains:

```
sha256 8f3936888224eee740353b669b6eaaf1401db3ad5d20566c50c0c5d961fc3050
```

That is the digest of the wasm the gate tested. It is the same digest as
`bytecode/unog.near.wasm`, and its base58 encoding is the code hash NEAR
reports for `unog.near`:

```
Ae5uDVYKhZpwgCBDTcSQGk26azY4ytzBH69kUL2FD8y5
```

A log written before deployment, a file published after it, and the live
chain all carry the same value. That is the whole point of publishing these
files. See [`../BUILD_PROVENANCE.md`](../BUILD_PROVENANCE.md).

## Reading the VM gate

```
vm admit_scenario           rc=0 calls=29  aborted=2
vm layerboot_scenario       rc=0 calls=79  aborted=17
expect layerboot: lifecycle: 79 calls, 0 wrong
QC: PASS
```

The `aborted=` counts are intentional. Those scenarios assert that invalid
input is rejected **for the right reason** — a fail-closed system is only as
good as its refusals, so the refusals are tested explicitly. `0 wrong` means
every call returned exactly what the expectation file said it should.

## Redaction

These files were scanned for key material before publication. They contain
none — no private keys, no seeds, no mnemonics. Transaction IDs and hashes
are public data by definition.
