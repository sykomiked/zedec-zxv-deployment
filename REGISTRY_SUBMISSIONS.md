# TIAMAT (PQOS) at `unog.near` — registry submission package

Every field is verified against NEAR mainnet at the time of writing. Paste
these into each registry's form. On-chain registries already done are marked.

---

## Verified token facts

| Field | Value |
|---|---|
| Name | TIAMAT |
| Symbol | PQOS |
| Contract | `unog.near` |
| Decimals | 24 |
| Standard | NEP-141 / NEP-145 / NEP-148 / NEP-297 |
| Total supply | 0.4 TIAMAT (`399999999995091219284575` base units) |
| Code hash | `Ae5uDVYKhZpwgCBDTcSQGk26azY4ytzBH69kUL2FD8y5` |
| Access keys | 0 (sealed, immutable) |
| Explorer | https://nearblocks.io/address/unog.near |
| Pool | RHEA Finance pool 8992, TIAMAT/NEAR, 0.3% fee |

```
curl -s https://rpc.mainnet.fastnear.com -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"query","params":{"request_type":"call_function","finality":"final","account_id":"unog.near","method_name":"ft_metadata","args_base64":"e30="}}'
```

## Status of each registry

| Registry | Status | Action |
|---|---|---|
| **RHEA Finance** (DEX) | **done** — pool 8992, tokens registered, first trade executed (`6DgsX1qy…`) | none |
| Nearblocks (explorer/indexer) | crawls automatically; token page appears once it indexes the pool | watch https://nearblocks.io/address/unog.near |
| DexScreener | automatic, **but a pair is only rendered after at least one trade** — done (`6DgsX1qy…`); still `null` at check time, so use the request form | https://dexscreener.com/ (Request a pair) with the fields below |
| GeckoTerminal | automatic (CoinGecko DEX tracker) | request via https://www.geckoterminal.com/ (Request a pool) |
| CoinGecko | **manual form** — text below | submit |
| CoinMarketCap | **manual form** — text below | submit |
| Meta Pool | not a DEX (liquid staking, stNEAR); no TIAMAT pool exists there | none (its grant track is separate) |
| Jumbo Exchange, Tonic, Sparrow | contracts are defunct or expose no pool interface | none |

## CoinGecko / CoinMarketCap form text

**Project name:** GRIDCHAIN (TIAMAT)

**What is the project about?**
GRIDCHAIN is a sealed, twelve-layer settlement contract on NEAR. Its token,
TIAMAT, is issued only against a NEAR reserve on a deterministic
golden-ratio curve: there is no admin mint, no premine and no privileged
key. The contract also verifies post-quantum signatures (ML-DSA-87,
SLH-DSA-SHAKE-256s) in ordinary Wasm, keeps every monetary value in exact
integer or rational arithmetic (no floating point), and records contested
events in a four-valued logic where only TRUE can settle. The code is
immutable: zero access keys, code hash published and independently
checkable.

**What makes it unique?**
1. The contract is sealed: nobody, including the author, can change the
   code or a parameter. Every claim is checkable with a free view call.
2. TIAMAT is issued on a curve against deposited NEAR; the reserve is
   public and the quote is a view (`tiamat_quote`).
3. Post-quantum verification runs inside the contract, not in a host
   function.
4. Exact arithmetic end to end: no rounding drift anywhere in the ledger.

**How many tokens are in circulation?**
0.4 TIAMAT (the whole supply; minted against 0.4 NEAR of reserve).

**Where can the token be traded?**
RHEA Finance, pool 8992 (TIAMAT/NEAR).

**Links**
- Contract: https://nearblocks.io/address/unog.near
- Pool: https://app.rhea.finance/pool/8992
- Source and audits: the project's public repositories and the Blue Book on
  `social.near` (`jollydragonroger.near/post/zedec_blue_book_v1`).

**Contract address:** `unog.near`

**Decimals:** 24

**Explorer:** Nearblocks

**Community:** NEAR Social `jollydragonroger.near`

## Honest notes for the forms

- Supply is deliberately tiny (0.4 TIAMAT) because the mint is
  reserve-backed; a large supply would require a large reserve.
- The pool is small. It is a real, live market, not a deep one.
- No certification, audit firm or listing has been obtained; nothing in
  this package claims otherwise.

## First trade (the indexer trigger)

A real dust trade was executed so a price exists and a pair can be rendered:

| Step | Transaction |
|---|---|
| 0.02 wNEAR into Ref | `CgmfDqcw8qZh8p1rqcPgxH6aovxdZ11HvaNtquDe1ugJ` |
| swap 0.02 wNEAR -> TIAMAT, pool 8992 | `6DgsX1qyJHESjGTekRfqnTkWtuq2PBawGpRFFSezXTLK` |

Pool after the trade: `181867782122557063017182` TIAMAT / `220000000000000000000000` wNEAR
(implied price ~1.21 wNEAR per TIAMAT). The trade emitted the standard NEP-141
`ft_transfer` events, which is what an event-driven indexer filters on.

## What not to do

- Do not run a loop of dust trades to "look active". It costs real money for
  no indexer benefit: indexers prioritise by volume and liquidity, not by
  transaction count on a 0.4 NEAR pool.
- Do not hammer RPC endpoints expecting indexers to notice. Indexers run
  their own ingestion from the block stream; public RPC request patterns are
  not an input to their queues.
