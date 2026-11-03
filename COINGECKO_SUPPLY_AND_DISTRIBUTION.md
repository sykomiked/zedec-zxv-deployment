# CoinGecko submission — supply, distribution and holder data

All figures read from `unog.near` on NEAR mainnet, 2026-11-03.

---

## 1. Supply

| Field | Value |
|---|---|
| **Total supply** | **61.470008027182581764720275 PQOS** |
| **Circulating supply** | **60.760008027182405762520281 PQOS** |
| **Max supply** | **144,000,000,000 PQOS** (the curve's asymptote) |
| Decimals | 24 |
| Contract | `unog.near` (platform `near-protocol`) |

**How circulating is derived:** total supply minus tokens held by the protocol
itself, not by users.

```
total          61.470008027182581764720275
- bridge       -0.510000000000000000000000   (locked for an in-flight route)
- pool         -0.200000000000176002199994   (Ref 8992 liquidity)
= circulating  60.760008027182405762520281
```

**API source (authoritative).** NEAR has no REST endpoint for this; the chain
itself is the source. A single JSON-RPC call:

```
POST https://rpc.mainnet.fastnear.com
{"jsonrpc":"2.0","id":1,"method":"query","params":{
  "request_type":"call_function","finality":"final",
  "account_id":"unog.near","method_name":"ft_total_supply","args_base64":"e30="}}
```

The result is base64 of the decimal string. For circulating, the same call with
`ft_balance_of` for `chiglet.unog.near` and `v2.ref-finance.near`.

## 2. Distribution schedule — mint-on-demand, fully collateralised

**There is no pre-mine, no ICO, no private sale, no team allocation, no
advisor allocation, no treasury allocation, and no vesting of any kind.** Every
PQOS in existence was created by a user depositing collateral.

**The mechanism.** A mint deposits NEAR into the protocol reserve and the
protocol issues TIAMAT at the curve price:

```
backing per new TIAMAT = phi^(21 x supply / cap) NEAR
```

`phi` is the golden ratio. Because the exponent grows with supply, **the
collateral required per new token rises monotonically** — early minters are
cheaper than late ones, and the curve approaches the cap asymptotically at
144,000,000,000 PQOS. There is no schedule that can be accelerated by an
insider, because issuance is bounded by collateral, not by time.

**Redemption.** `voucher_redeem` burns TIAMAT and returns a pro-rata slice of
the whole reserve, so every token is redeemable against the collateral that
created it.

**Consequence for supply classification.** 100% of supply is "circulating" by
construction — there is no locked bucket, no vesting contract, and no unissued
reserve held by the team. The only non-circulating amount is what sits in
protocol contracts at any moment (bridge and pool balances).

## 3. Initial token allocation

| Allocation name | % of supply | TGE | Cliff (months) | Vesting (months) |
|---|---|---|---|---|
| **Public mint (on-demand, collateralised)** | **100%** | none — issued per deposit, continuously | **0** | **0** |
| Team / founders | 0% | — | — | — |
| Private sale / ICO | 0% | — | — | — |
| Treasury / ecosystem | 0% | — | — | — |
| Advisors | 0% | — | — | — |
| Liquidity / market making | 0% | — | — | — |

There is no token generation event in the conventional sense. Supply is created
when and only when a user deposits collateral.

## 4. Holder data

**Top holders page (verified reachable):**

```
https://pikespeak.ai/token/unog.near
```

Nearblocks equivalent (browser only — it blocks automated requests):

```
https://nearblocks.io/token/unog.near
```

**Current distribution:**

| Holder | PQOS | Share |
|---|---|---|
| `jollydragonroger.near` (owner) | 57.564003 | 93.65% |
| `chiglet.unog.near` (bridge) | 0.510000 | 0.83% |
| `v2.ref-finance.near` (pool 8992) | 0.200000 | 0.33% |
| protocol L2 accounts (mint account `92d909d9…`, desk, owner's gridchain id) | 3.196005 | 5.20% |

**Stated plainly:** the owner's wallet holds 93.65% of supply; a further 5.20% sits in the protocol's internal ledger accounts. Together that is 98.85%. That is the project
owner's wallet, and CoinGecko's reviewers will see it. It is a concentration
risk and should be disclosed rather than discovered.

## 5. Additional supply notes for the submission

- **Inflation:** none beyond mint-on-demand. No scheduled emissions, no
  staking rewards that mint, no rebase.
- **Burns:** `voucher_redeem` burns against the reserve. Supply can fall.
- **Cap:** 144,000,000,000 PQOS, enforced by the curve, not by an admin key.
- **Admin mint:** **none exists.** The core has no owner-mint path; it is
  sealed with zero access keys. This is verifiable: `unog.near` has no keys.
- **Supply history:** the token launched at zero and reached 61.47 PQOS purely
  through user deposits. No airdrop has occurred.
