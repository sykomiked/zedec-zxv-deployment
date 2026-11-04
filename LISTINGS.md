# Listings — what is submitted, what auto-indexes, what needs a human

There is a widespread assumption that token listings can be submitted through
an API. **They cannot.** Every major aggregator either indexes automatically
from on-chain data, or requires a manual review form.

This document records the true state of each venue so nobody wastes time
looking for an endpoint that does not exist.

---

## 1. Machine-readable token lists (published)

Two lists are published in this repository and are consumable by any wallet,
DEX UI or indexer that supports a token list.

| File | Contents |
|---|---|
| [`tokenlist.json`](tokenlist.json) | NEAR mainnet — PQOS at `unog.near`, 24 decimals |
| [`tokenlist-outposts.json`](tokenlist-outposts.json) | Wrapped PQOS on Ethereum, Tron (EVM format) and Sui, TON, Aptos (non-EVM) |

Raw URLs:

```
https://raw.githubusercontent.com/sykomiked/zedec-zxv-deployment/main/tokenlist.json
https://raw.githubusercontent.com/sykomiked/zedec-zxv-deployment/main/tokenlist-outposts.json
```

These are the only listing artefacts that can be *produced* programmatically.
Everything below requires either automatic indexing or a human.

---

## 2. Venue-by-venue status

### Automatic — nothing to submit, indexing depends on data

| Venue | Status | What governs it |
|---|---|---|
| **GeckoTerminal** | **indexed** | token page exists; supply data is stale (see §3) |
| **DexScreener** | **not indexed** | requires a pool with meaningful liquidity |
| **NearBlocks** | indexed | reads `ft_metadata` directly |
| **Pikespeak** | indexed | reads chain |
| **Ref Finance** | registered on-chain | `register_tokens` was executed on the router |

**DexScreener is the one worth understanding.** It returns `[]` for
`unog.near` — not because the token is invalid, but because its indexer only
picks up tokens that appear in a pool with real volume. A pool holding 0.18
PQOS does not qualify. **This cannot be fixed by submission; it is fixed by
liquidity.**

### Manual review — a form or an email, no API

| Venue | Path | Blocking requirement |
|---|---|---|
| **CoinGecko** | request form | submitted manually; pending |
| **CoinMarketCap** | request form | needs volume and a public track record |
| **CoinPaprika** | submission form | manual review |
| **LiveCoinWatch** | submission form | manual review |
| **CoinCodex** | submission form | manual review |
| **GeckoTerminal pool listing** | automatic | pool must have depth |
| **tokenlists.org** | form | no public API endpoint |

None of these accept a programmatic submission. Any service claiming to do so
is either a paid intermediary or reselling a manual form.

### Stale or inactive — do not bother

| Venue | Why |
|---|---|
| `alpha-fi/token-list` | last push 2020 |
| `odyssey-labs/token-list` | last push 2022 |
| `near-clp/token-list` | NEARswap era, inactive |
| `Nearblocks/spam-token-list` | a *spam* list — being absent from it is correct |

---

## 3. Known data defect — GeckoTerminal supply

GeckoTerminal's token record reports:

```json
{
  "address": "unog.near",
  "name": "TIAMAT",
  "symbol": "PQOS",
  "decimals": 24,
  "total_supply": "399999999995091219284575.0",
  "normalized_total_supply": "0.399999999995091",
  "price_usd": "4.7098485456",
  "coingecko_coin_id": null
}
```

**Their supply figure is 0.4 PQOS. The real supply is 61.47 PQOS.** The price
of $4.71 is derived from that stale figure and is therefore meaningless.

This is not something we can patch through an API — it is their indexer's
snapshot. It should correct on its own as the indexer refreshes, but it has
not yet. If it persists after the CoinGecko listing lands, it becomes worth
raising with GeckoTerminal directly.

**Do not quote that price anywhere.** It is wrong by a factor of ~150.

---

## 4. What actually moves the needle

Ranked by effect per unit of effort:

1. **Liquidity in Ref pool 8992.** DexScreener, GeckoTerminal pool pages and
   every downstream aggregator key off pool depth. This is the gate.
2. **The CoinGecko listing** (already submitted). Once approved, the
   `coingecko_coin_id` field populates across GeckoTerminal and downstream.
3. **A working front-end.** No aggregator indexes a token nobody can buy.
4. **Token list publication** — done, in this repository.

Everything else is paperwork.

---

## 5. What is deliberately not claimed

- We are **not** listed on CoinMarketCap, CoinPaprika, LiveCoinWatch or
  CoinCodex. No submission has been made to those.
- We are **not** indexed by DexScreener.
- The GeckoTerminal supply and price figures are **wrong** and are noted above
  rather than quietly ignored.

A listing claim that a reviewer checks and finds false costs more than the
listing would have earned.
