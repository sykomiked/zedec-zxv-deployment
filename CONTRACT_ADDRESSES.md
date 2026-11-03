# Contract addresses and deployment record

Every contract the ZEDEC/ZXV project has deployed to NEAR mainnet, with the
code hash read from the chain and the compiled WASM published in `bytecode/`.

**Twelve contract accounts. Twelve WASM files. Every SHA-256 verified against
the live code hash.** Two accounts share one binary (`zedei.near` and
`outpost.jollydragonroger.near`), so there are eleven distinct builds.

---

## The register

| # | Account | Role | Code hash (base58) | Size | Balance (NEAR) | Access keys |
|---|---|---|---|---|---|---|
| 1 | **`zedec.near`** | kernel | `ATUV46Keb91L32RGU5X858nNtTZ6csH9HARfE86MtMo` | 90,380 B | 1.4089 | **0** |
| 2 | **`scp144.near`** | post-quantum engine | `DDQ4uJXM26WhRoYfRPgQcUKPpybzhGrBXmCbK7e85dmN9` | 77,823 B | 1.6133 | **0** |
| 3 | **`zedei.near`** | interface / automation | `CRZgm89Yo8JsU6WgFjFmkrU8BRDZfMvieKQ2hozDLwjZ` | 61,325 B | 2.3141 | **0** |
| 4 | **`unog.near`** | **sealed GRIDCHAIN core** — 151 ops, 214 ABI descriptors, 46 governance kinds, 12 booted layers | `Ae5uDVYKhZpwgCBDTcSQGk26azY4ytzBH69kUL2FD8y5` | **1,156,670 B** | 76.2446 | **0** |
| 5 | **`chiglet.unog.near`** | RouteLock bridge — 3-of-5 attested, 889 ppm | `DRq7Th7tfKdeZUMB4TsQVe23vELNiNnBc8qgpxhvW91h` | 331,758 B | 4.7842 | 1 |
| 6 | **`post.jollydragonroger.near`** | MintDesk — mint and redemption kiosk | `7z6gj4zjw6YEii4EQej9w4SZ8iScvsjgU7QY7KkqtQ7Z` | 244,201 B | 6.2512 | 1 |
| 7 | **`mission.unog.near`** | ENVOY — jobs, bounties, the Mobius loop | `49rYaA4vZ2kyvvf7SY29ZqXasvDKYapiekRYXKkTUjRW` | 62,460 B | 1.4714 | **0** |
| 8 | **`chancery.unog.near`** | REGISTRAR — attestation tallies | `EUfXZxyK6nGy3VwD1oQLymiYcTM687L2j4recUDqg3YN` | 44,496 B | 1.5034 | **0** |
| 9 | **`consulate.unog.near`** | TRANSIT — the routes | `9JHAd3FRn56rhFzZuM4phMW6Kx1VRw2h5GDxMjgzeKPi` | 62,454 B | 0.8942 | **0** |
| 10 | **`protocol.unog.near`** | PROTOCOL — governance kernel, the DAO's one seat | `Eg5SgH23zwstY4GDwGJHyCn752TJwCw15cLQ24ZwQJeo` | 68,580 B | 0.8937 | **0** |
| 11 | **`36n9.zedei.near`** | interface kernel, operator build | `3H4dqcbN2TEkrgsSWFEMovVWGhvVgatqUuGKLP5ji5US` | 396,064 B | 5.2642 | 1 |
| 12 | **`outpost.jollydragonroger.near`** | desk outpost — **same binary as `zedei.near`** | `CRZgm89Yo8JsU6WgFjFmkrU8BRDZfMvieKQ2hozDLwjZ` | 61,325 B | 6.2467 | 1 |

**Balances and key counts read from mainnet on 2026-11-02.** Key counts are
the number of access keys on the account: `0` means **sealed** — no admin, no
upgrade, no recovery, no rug path. The four accounts with 1 key each hold
operational keys needed to run the relayer and desk; those are disclosed
rather than hidden.

---

## Verified: the published WASM is the on-chain code

Each file in `bytecode/` was pulled **from the chain itself** using
`view_code`, then hashed and compared to the reported code hash. All twelve
matched on the first attempt.

```bash
# reproduce it yourself — no trust required
curl -s https://rpc.mainnet.fastnear.com -H 'Content-Type: application/json' -d '{
  "jsonrpc":"2.0","id":1,"method":"query","params":{
    "request_type":"view_code","finality":"final","account_id":"unog.near"}}' \
| python3 -c 'import sys,json,base64,hashlib; d=json.load(sys.stdin)["result"];
c=base64.b64decode(d["code_base64"]); print(len(c), d["hash"])'

# then compare
sha256sum bytecode/unog.near.wasm
```

`bytecode/SHA256SUMS` holds the raw SHA-256 of every file. The base58 code
hash NEAR reports is the same digest, base58-encoded — so a SHA-256 match
proves byte-for-byte identity with what is executing on chain.

---

## What each layer does

### Platform (NEAR-native)

- **`zedec.near`** — the kernel. Boots the core, owns the layer table.
- **`scp144.near`** — the post-quantum engine. FIPS 204 (ML-DSA) and FIPS 205
  (SLH-DSA) verifiers, the 145-state paraconsistent logic, the 144-lane
  matrix. Self-test 10/10.
- **`zedei.near`** — interface and automation. Blobs, factory, the callable
  surface that front-ends use.

### Settlement

- **`unog.near`** — the sealed core. A chain inside a contract: internal
  accounts, balances, nonces, an AMM, a content-addressed store, governance.
  1.15 MB of immutable logic with **zero access keys**. There is no function
  to mint for an admin, pause the chain, or upgrade the code. That is
  verifiable by reading the account, not by trusting this document.

### Satellites

- **`chiglet.unog.near`** — RouteLock. Accepts `ft_transfer_call` with
  `msg = "chain|recipient"`, records a request, exposes it to the relayer.
  Fee 889 ppm, read at `fee_ppm()`.
- **`post.jollydragonroger.near`** — MintDesk. One call mints; redemption
  arrives via `ft_on_transfer`.
- **`mission.unog.near`** (ENVOY), **`chancery.unog.near`** (REGISTRAR),
  **`consulate.unog.near`** (TRANSIT), **`protocol.unog.near`** (PROTOCOL) —
  the four governance and coordination kernels, all sealed with zero keys.
- **`36n9.zedei.near`** — operator build of the interface kernel.
- **`outpost.jollydragonroger.near`** — desk outpost running the same binary
  as `zedei.near`.

---

## The token

| Field | Value |
|---|---|
| Contract | **`unog.near`** |
| Platform | `near-protocol` |
| Name / Symbol | TIAMAT / PQOS |
| Decimals | **24** |
| Standard | NEP-141 (`ft-1.0.0`) |
| Asset ID | `a98479b58d9fb8e3353e33400b29d9e875d778b82ae195d3d93b7d648e03d7e4` |

NEAR contracts are **named accounts, not hex addresses**. There is no hash
form of `unog.near`, exactly as there is none for `wrap.near`.

---

## External outposts

| Chain | Contract | Notes |
|---|---|---|
| Ethereum | `0xAd55800116817E3A0884B514BAb508aFd9e95142` | Sourcify `exact_match`; `SCALE = 1e6`, 18 decimals, 3-of-5, cap 12.5 PQOS |
| Sui | `0x9953147df1732aa900a3ad0f2580e2fc256a727b861ba96e2acc73e4beb2bdae` | immutable package, module `wrapped_pqos` |
| TON | `UQCJqL-7Q20RrKOMSIUFcHXHN76LzjrxQYGBtAfBJ3MP5Zj9` | `chainId = 2`, cap 12.5 PQOS |
| Tron | `TCDYovDaXZQsgbxDCcprFpyw2tR2ZYweF6` | deployed after energy rental |
| Aptos | `0xd82e10769f6b4280d45a13246ca1cfb66902de30702246e2014b195ddfd197b6` | module `wrapped_pqos` |

The original Ethereum contract `0x9f326c206BAcB6f6452e51c7F4aB87b71830CE70`
is **deprecated** — it lacked decimal scaling. It is listed here because
hiding a mistake is worse than recording one.

---

## Accounts that are NOT contracts

For completeness, so nobody mistakes a wallet for a deployment:

`jollydragonroger.near`, `robindebanks.near`, `crown.unog.near`,
`foundation.unog.near`, `sicily.unog.near`, `illumaheart.near`,
`9n63.zedei.near`, `iedez.zedei.near`, `raen.*.unog.near`,
`d832564654.near`, `99041590561356419m.near`, `etna.unog.near`,
`solver1.36n9.near`, `covenant-grid.near` — all hold no contract code.

`trisolaris.near` is **not ours**. It is a third-party Ref Finance staking
contract that our account interacted with. It is excluded from `bytecode/`
deliberately.

---

## How to verify any of this

```bash
# code hash and balance
near state unog.near --nodeUrl https://rpc.mainnet.near.org

# access keys — expect an empty list for a sealed contract
near view-access-keys unog.near --nodeUrl https://rpc.mainnet.near.org

# the token's own metadata
near view unog.near ft_metadata

# supply
near view unog.near ft_total_supply

# bridge fee
near view chiglet.unog.near fee_ppm
```

If any hash in this document disagrees with the chain, **the chain is right
and this document is wrong** — and we would want to know.
