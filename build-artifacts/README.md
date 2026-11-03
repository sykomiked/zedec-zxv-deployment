# Build artifacts

**Everything the build produced, in one place.** Twelve deployed WASM files,
their checksums, and the build-stage outputs behind them.

Nothing is elsewhere. If you are looking for a contract's compiled bytecode,
it is in this folder.

---

## The twelve deployed WASM

| File | Account | Bytes | Code hash |
|---|---|---|---|
| `unog.near.wasm` | `unog.near` | 1,156,670 | `Ae5uDVYKhZpwgCBDTcSQGk26azY4ytzBH69kUL2FD8y5` |
| `36n9.zedei.near.wasm` | `36n9.zedei.near` | 396,064 | `3H4dqcbN2TEkrgsSWFEMovVWGhvVgatqUuGKLP5ji5US` |
| `chiglet.unog.near.wasm` | `chiglet.unog.near` | 331,758 | `DRq7Th7tfKdeZUMB4TsQVe23vELNiNnBc8qgpxhvW91h` |
| `post.jollydragonroger.near.wasm` | `post.jollydragonroger.near` | 244,201 | `7z6gj4zjw6YEii4EQej9w4SZ8iScvsjgU7QY7KkqtQ7Z` |
| `zedec.near.wasm` | `zedec.near` | 90,380 | `ATUV46Keb91L32RGU5X858nNtTZ6csH9HARfE86MtMo` |
| `scp144.near.wasm` | `scp144.near` | 77,823 | `DDQ4uJXM26WhRoYfRPgQcUKPpybzhGrBXmCbK7e85dmN9` |
| `protocol.unog.near.wasm` | `protocol.unog.near` | 68,580 | `Eg5SgH23zwstY4GDwGJHyCn752TJwCw15cLQ24ZwQJeo` |
| `mission.unog.near.wasm` | `mission.unog.near` | 62,460 | `49rYaA4vZ2kyvvf7SY29ZqXasvDKYapiekRYXKkTUjRW` |
| `consulate.unog.near.wasm` | `consulate.unog.near` | 62,454 | `9JHAd3FRn56rhFzZuM4phMW6Kx1VRw2h5GDxMjgzeKPi` |
| `zedei.near.wasm` | `zedei.near` | 61,325 | `CRZgm89Yo8JsU6WgFjFmkrU8BRDZfMvieKQ2hozDLwjZ` |
| `outpost.jollydragonroger.near.wasm` | `outpost.jollydragonroger.near` | 61,325 | `CRZgm89Yo8JsU6WgFjFmkrU8BRDZfMvieKQ2hozDLwjZ` |
| `chancery.unog.near.wasm` | `chancery.unog.near` | 44,496 | `EUfXZxyK6nGy3VwD1oQLymiYcTM687L2j4recUDqg3YN` |

**Eleven distinct builds across twelve accounts.** `zedei.near` and
`outpost.jollydragonroger.near` run the same binary — identical SHA-256
(`a9bb7408…`).

Each file was pulled from the chain with `view_code`, decoded, hashed, and
compared to the code hash NEAR reports. All twelve matched on the first
attempt. `SHA256SUMS` is the machine-readable record.

---

## Checksums

```bash
cd build-artifacts && sha256sum -c SHA256SUMS
```

If a file fails that check it has been altered, and the chain is the authority.

`MANIFEST.md` carries the same table with the verification procedure.

---

## `build-stage/` — the outputs behind the binaries

| File | Bytes | What it is |
|---|---|---|
| `build-stage/gridchain.lto.wasm` | 1,155,965 | the intermediate after LTO, 705 bytes **before** the final link |
| `build-stage/gridchain.lto.wasm.resolution.txt` | 40,543 | the linker's symbol resolution map |
| `build-stage/scp144.near.local-build.wasm` | 77,823 | a local build that matches `scp144.near.wasm` byte-for-byte |
| `build-stage/README.md` | — | what each one proves |

The third is the strongest artefact in the repository: it was produced on the
build machine **before deployment**, and its SHA-256
(`b5794b89ddf54d19…`) is identical to the file pulled from chain, whose code
hash is `DDQ4uJXM26WhRoYfRPgQcUKPpybzhGrBXmCbK7e85dmN9`.

---

## Verify all of it

```bash
./tools/verify.sh            # every wasm vs mainnet, sealed keys, token metadata
python3 tools/prepublish_check.py   # no key material, wasm vs chain, history
```

---

## What is deliberately not here

| Withheld | Reason |
|---|---|
| `*.bc` LLVM bitcode, `.o` object files | carry the full intermediate representation — the algorithms, not the behaviour |
| the source tree | the protocol's design is the project's property |
| keys, mnemonics, attestor material | never published, in any form |

Everything that can affect a user's funds is verifiable from these files and
the chain. See [`../REPRODUCIBILITY.md`](../REPRODUCIBILITY.md) for the precise
split between what can be verified and what would need source to rebuild.
