# Contract register

**Twelve contract accounts on NEAR mainnet. Eleven distinct builds.**
(`zedei.near` and `outpost.jollydragonroger.near` run the same binary.)

Every code hash below was read from the chain. Every compiled WASM is
published in [`build-artifacts/`](build-artifacts/) and matches its hash byte-for-byte.

---

## All twelve, one page

| # | Account | Role | Code hash | Size | Keys |
|---|---|---|---|---|---|
| 1 | **`zedec.near`** | **the C kernel** | `ATUV46Keb91L32RGU5X858nNtTZ6csH9HARfE86MtMo` | 90,380 B | **0** |
| 2 | **`scp144.near`** | post-quantum engine | `DDQ4uJXM26WhRoYfRPgQcUKPpybzhGrBXmCbK7e85dmN9` | 77,823 B | **0** |
| 3 | **`zedei.near`** | interface / automation | `CRZgm89Yo8JsU6WgFjFmkrU8BRDZfMvieKQ2hozDLwjZ` | 61,325 B | **0** |
| 4 | **`unog.near`** | sealed GRIDCHAIN core + TIAMAT | `Ae5uDVYKhZpwgCBDTcSQGk26azY4ytzBH69kUL2FD8y5` | 1,156,670 B | **0** |
| 5 | **`chiglet.unog.near`** | RouteLock bridge | `DRq7Th7tfKdeZUMB4TsQVe23vELNiNnBc8qgpxhvW91h` | 331,758 B | 1 |
| 6 | **`post.jollydragonroger.near`** | MintDesk | `7z6gj4zjw6YEii4EQej9w4SZ8iScvsjgU7QY7KkqtQ7Z` | 244,201 B | 1 |
| 7 | **`mission.unog.near`** | ENVOY — jobs, bounties | `49rYaA4vZ2kyvvf7SY29ZqXasvDKYapiekRYXKkTUjRW` | 62,460 B | **0** |
| 8 | **`chancery.unog.near`** | REGISTRAR — attestations | `EUfXZxyK6nGy3VwD1oQLymiYcTM687L2j4recUDqg3YN` | 44,496 B | **0** |
| 9 | **`consulate.unog.near`** | TRANSIT — the routes | `9JHAd3FRn56rhFzZuM4phMW6Kx1VRw2h5GDxMjgzeKPi` | 62,454 B | **0** |
| 10 | **`protocol.unog.near`** | PROTOCOL — governance seat | `Eg5SgH23zwstY4GDwGJHyCn752TJwCw15cLQ24ZwQJeo` | 68,580 B | **0** |
| 11 | **`36n9.zedei.near`** | interface kernel, operator build | `3H4dqcbN2TEkrgsSWFEMovVWGhvVgatqUuGKLP5ji5US` | 396,064 B | 1 |
| 12 | **`outpost.jollydragonroger.near`** | desk outpost — **same binary as `zedei.near`** | `CRZgm89Yo8JsU6WgFjFmkrU8BRDZfMvieKQ2hozDLwjZ` | 61,325 B | 1 |

**Eight of twelve are sealed with zero access keys.** No admin, no upgrade,
no pause, no recovery. The four with one key each hold relayer and desk keys,
disclosed rather than hidden.

Balances and key counts read from mainnet on 2026-11-02.

---

## Grouped by job

### The C kernel and its two companions

```
zedec.near     the kernel — boots the core, owns the layer table
scp144.near    the post-quantum engine — FIPS 204/205 verifiers, 145-state logic
zedei.near     the interface — blobs, factory, the callable surface
```

These three are written in **C11**, compiled with clang 18.1.3 to strict
wasm MVP. Build primitives are in [`build.sh`](build.sh) and
[`REPRODUCIBILITY.md`](REPRODUCIBILITY.md).

`zedec.near` is the entry point of the whole system: it is the contract that
knows the layer table and boots `unog.near`.

### The sealed core

```
unog.near      1.16 MB — 151 ops, 214 ABI descriptors, 46 governance kinds,
               12 booted layers, an internal AMM, a content store, governance
```

**Zero access keys.** There is no function to mint for an admin, pause the
chain, or upgrade the code. Verify it in one call:

```bash
near view-access-keys unog.near --nodeUrl https://rpc.mainnet.near.org
# → []
```

### The working satellites

```
chiglet.unog.near            bridge: ft_transfer_call with msg "chain|recipient"
post.jollydragonroger.near   desk: one-call mint, redemption via ft_on_transfer
```

Both use `#[near_bindgen]` rather than `#[near]` so that snake_case arguments
from the core deserialise correctly. Using `#[near]` silently refunded bridge
transfers for a day — see the failure catalogue in `TRANSACTION_FLOWS.md`.

### The four governance kernels

```
mission.unog.near      ENVOY      jobs, bounties, the Mobius loop
chancery.unog.near     REGISTRAR  attestation tallies
consulate.unog.near    TRANSIT    the routes
protocol.unog.near     PROTOCOL   the DAO's one seat
```

All four sealed with zero keys.

### Operator builds

```
36n9.zedei.near                 operator build of the interface kernel
outpost.jollydragonroger.near   desk outpost, same binary as zedei.near
```

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
| Aptos | `0xd82e10769f6b4280d45a13246ca1cfb66902de30702246e2014b195ddfd197b6::wrapped_pqos` | Move |

The original Ethereum contract `0x9f326c206BAcB6f6452e51c7F4aB87b71830CE70`
is **deprecated** — it lacked decimal scaling. It is listed because hiding a
mistake is worse than recording one.

---

## Verify all of it in one command

```bash
./tools/verify.sh
```

Checks all twelve hashes against mainnet, confirms the eight sealed contracts
have zero keys, reads the token metadata, and confirms the QC log hash equals
the deployed hash. Read-only RPC, no keys, no gas.

Or check a single account by hand:

```bash
curl -s https://rpc.mainnet.fastnear.com -H 'Content-Type: application/json' -d '{
  "jsonrpc":"2.0","id":1,"method":"query","params":{
    "request_type":"view_account","finality":"final","account_id":"zedec.near"}}'
```

If any hash here disagrees with the chain, **the chain is right and this
document is wrong** — and we would want to know.

---

## Accounts that are not contracts

So nobody mistakes a wallet for a deployment:

`jollydragonroger.near`, `robindebanks.near`, `crown.unog.near`,
`foundation.unog.near`, `sicily.unog.near`, `illumaheart.near`,
`9n63.zedei.near`, `iedez.zedei.near`, `raen.*.unog.near`,
`d832564654.near`, `99041590561356419m.near`, `etna.unog.near`,
`solver1.36n9.near`, `covenant-grid.near` — all hold no contract code.

`trisolaris.near` is **not ours**. It is a third-party Ref Finance staking
contract our account interacted with, and it is excluded from `build-artifacts/`
deliberately.
