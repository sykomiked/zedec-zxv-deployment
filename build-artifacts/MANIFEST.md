# Compiled bytecode — verified against mainnet

Twelve WASM files, one per deployed NEAR contract account.

Each file was pulled **from the chain** with `view_code`, then hashed. Every
SHA-256 matched the code hash NEAR reports for that account. These are the
exact bytes executing on mainnet — not build outputs, not a snapshot.

---

## Files

| File | Account | Code hash (base58) | Bytes |
|---|---|---|---|
| `unog.near.wasm` | `unog.near` | `Ae5uDVYKhZpwgCBDTcSQGk26azY4ytzBH69kUL2FD8y5` | 1,156,670 |
| `36n9.zedei.near.wasm` | `36n9.zedei.near` | `3H4dqcbN2TEkrgsSWFEMovVWGhvVgatqUuGKLP5ji5US` | 396,064 |
| `chiglet.unog.near.wasm` | `chiglet.unog.near` | `DRq7Th7tfKdeZUMB4TsQVe23vELNiNnBc8qgpxhvW91h` | 331,758 |
| `post.jollydragonroger.near.wasm` | `post.jollydragonroger.near` | `7z6gj4zjw6YEii4EQej9w4SZ8iScvsjgU7QY7KkqtQ7Z` | 244,201 |
| `zedec.near.wasm` | `zedec.near` | `ATUV46Keb91L32RGU5X858nNtTZ6csH9HARfE86MtMo` | 90,380 |
| `scp144.near.wasm` | `scp144.near` | `DDQ4uJXM26WhRoYfRPgQcUKPpybzhGrBXmCbK7e85dmN9` | 77,823 |
| `protocol.unog.near.wasm` | `protocol.unog.near` | `Eg5SgH23zwstY4GDwGJHyCn752TJwCw15cLQ24ZwQJeo` | 68,580 |
| `mission.unog.near.wasm` | `mission.unog.near` | `49rYaA4vZ2kyvvf7SY29ZqXasvDKYapiekRYXKkTUjRW` | 62,460 |
| `consulate.unog.near.wasm` | `consulate.unog.near` | `9JHAd3FRn56rhFzZuM4phMW6Kx1VRw2h5GDxMjgzeKPi` | 62,454 |
| `zedei.near.wasm` | `zedei.near` | `CRZgm89Yo8JsU6WgFjFmkrU8BRDZfMvieKQ2hozDLwjZ` | 61,325 |
| `outpost.jollydragonroger.near.wasm` | `outpost.jollydragonroger.near` | `CRZgm89Yo8JsU6WgFjFmkrU8BRDZfMvieKQ2hozDLwjZ` | 61,325 |
| `chancery.unog.near.wasm` | `chancery.unog.near` | `EUfXZxyK6nGy3VwD1oQLymiYcTM687L2j4recUDqg3YN` | 44,496 |

**Eleven distinct builds across twelve accounts.** `zedei.near` and
`outpost.jollydragonroger.near` run the same binary — their SHA-256 values are
identical (`a9bb7408…`).

---

## Verify any file

```bash
# the published file
sha256sum unog.near.wasm

# what the chain is running
curl -s https://rpc.mainnet.fastnear.com -H 'Content-Type: application/json' -d '{
  "jsonrpc":"2.0","id":1,"method":"query","params":{
    "request_type":"view_code","finality":"final","account_id":"unog.near"}}' \
| python3 -c 'import sys,json,base64,hashlib;
d=json.load(sys.stdin)["result"]; c=base64.b64decode(d["code_base64"]);
print(hashlib.sha256(c).hexdigest()); print(d["hash"])'
```

The SHA-256 digest, base58-encoded, **is** the code hash NEAR reports. Equal
digests mean byte-for-byte identity.

---

## What is deliberately excluded

| Excluded | Why |
|---|---|
| `trisolaris.near` | third-party Ref Finance staking contract; not ours |
| compiler artefacts (`target/`, `.rlib`, debug info) | only the deployed binary is relevant to an auditor |
| build metadata, symbol maps | not part of the on-chain code |
| keys, mnemonics, attestor material | never published, in any form |

The source tree is not published. `BUILD_REPRODUCIBILITY.md` documents the
toolchain, flags and determinism checks so the build can be understood and
independently verified, without disclosing the protocol's internal algorithms.

---

## Integrity

`SHA256SUMS` in this directory is the machine-readable record:

```bash
cd bytecode && sha256sum -c SHA256SUMS
```

If any file fails that check, the file has been altered and the chain is the
authority.
