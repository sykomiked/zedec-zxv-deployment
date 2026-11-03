# GRIDCHAIN / TIAMAT — public discovery

Everything a bot or a human needs to find, price and use the protocol.
Machine-readable twin: `gridchain.registry.json`.

---

## 1. What this is

A cross-chain settlement rail. **TIAMAT (PQOS)** is issued on NEAR against NEAR
collateral on a rising curve, and each outpost holds a **bounded, attested
representation** of it. The core is sealed and immutable; the outposts are
additive.

**Service fee: 8.889 basis points (889 ppm).** Clients never pay outpost gas —
the fee funds it. Readable on-chain before you trade: `fee_ppm()`.

## 2. Mint TIAMAT — one call, no terminal

```
post.jollydragonroger.near.mint()   with NEAR attached
```

The desk deposits your NEAR into the sealed core **in the same call**, so the
collateral is in the reserve before any TIAMAT exists. The core's curve prices
it: each new TIAMAT costs more NEAR as supply grows (`phi^(21*supply/cap)`).

**Quote first:** `unog.near.tiamat_quote({"value": "<yoctoNEAR>"})`

## 3. Redeem TIAMAT — one call

```
TIAMAT.ft_transfer_call({ receiver_id: "post.jollydragonroger.near", amount, msg: "" })
```

The relayer burns it against the reserve and returns NEAR.

## 4. Bridge to another chain

1. `ft_transfer_call` TIAMAT to **`chiglet.unog.near`** with
   `msg = "<chain_id>|<recipient>"` — e.g. `"1|0xabc…"` (quote-free by design).
2. The bridge records the lock, takes 8.889 bps, and emits `locked`.
3. The 3-of-5 attestors sign the MINT ticket.
4. The outpost mints wPQOS to the recipient.

**Reverse:** burn wPQOS on the outpost → the attestors sign a RELEASE ticket →
`chiglet.unog.near.release()` returns TIAMAT on NEAR.

## 5. Live endpoints

| Chain | Contract | Decimals | Scale from core | Explorer |
|---|---|---|---|---|
| **NEAR (core)** | `unog.near` | 24 | 1 | nearblocks |
| **NEAR (bridge)** | `chiglet.unog.near` | — | — | nearblocks |
| **NEAR (desk)** | `post.jollydragonroger.near` | — | — | nearblocks |
| **Ethereum** | `0xAd55800116817E3A0884B514BAb508aFd9e95142` | 18 | ÷1e6 | etherscan · **Sourcify exact_match** |
| **Sui** | `0x9953147d…bdae` | 9 | ÷1e15 | suiscan |
| **TON** | `UQCJqL-7Q20RrKOMSIUFcHXHN76LzjrxQYGBtAfBJ3MP5Zj9` | 9 | ÷1e15 | tonviewer |
| **Tron** | `TCDYovDaXZQsgbxDCcprFpyw2tR2ZYweF6` | 18 | ÷1e6 | tronscan |
| **Aptos** | `0xd82e1076…::wrapped_pqos` | 8 | ÷1e16 | aptos explorer |
| **Starknet** | account `0x06b0e99e…dfb6e` | — | — | voyager |

RPCs, pool IDs and per-chain views: see `gridchain.registry.json`.

## 6. Arbitrage

```
cost per round trip  ≈ 17.8 bps (two fees) + your gas
profitable spread    ≈ 20 bps
```

Read the core price (`tiamat_quote`) against each outpost's pool. The fee is
published on-chain, so a bot can price a lane before committing capital.

**The lanes are deliberately thin:** low enough that bots engage, wide enough
that they profit.

## 7. Pools

| Chain | Venue | Status |
|---|---|---|
| NEAR | Ref Finance pool **8992** | seeded, minimal |
| Ethereum | Uniswap V2/V3 | **not created** — needs paired depth |
| Sui | Cetus | **not created** — permissionless |
| TON | STON.fi / DeDust | **not created** |
| Tron | SunSwap / JustMoney | **not created** — rent energy first |
| Aptos | Thala / PancakeSwap | **not created** |

Stated plainly: **the tokens exist, the pools mostly do not.** A pool with no
depth is worse than none, so each is opened when paired liquidity is real.

## 8. What is not live yet

Cardano (validator builds, needs ADA) · Cosmos (wasm builds, needs OSMO on
Osmosis) · Tezos (Michelson written, client via Docker, key encoding pending).
These are registered when they deploy, not before.

## 9. Trust model — read this before depositing

**Attested, not trustless.** A 3-of-5 quorum signs every cross-chain mint. The
supply cap on each outpost is immutable and bounds what a compromised quorum
can create. The core cannot be edited; it can only be superseded.

Anyone claiming this is trustless is lying, including us.
