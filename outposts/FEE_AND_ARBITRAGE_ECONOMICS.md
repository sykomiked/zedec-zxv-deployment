# GRIDCHAIN — service fee and arbitrage economics

The bridge is a **service**, not a courtesy. The client never pays outpost gas
directly; the client pays a fee, and the service settles gas from the pool.

---

## 1. The fee

| | |
|---|---|
| Fee | **8.889 basis points** = 0.08889% = **889 ppm** |
| Where | charged on `RouteLock.ft_on_transfer`, at the moment of locking |
| What the client pays | the fee only — never gas on the destination chain |
| What the service pays | outpost gas (Ethereum, Tron, TON, Sui, Aptos) |
| Where the fee accrues | `fees_collected` on `chiglet.unog.near`, swept by `sweep_fees` |

**Worked example.** Lock 100 PQOS:

```
fee  = 100 * 889 / 1_000_000 = 0.08889 PQOS
net  = 99.91111 PQOS  -> this is what the ticket attests and what mints
```

The 0.08889 stays in the fee pool. A typical outpost mint costs a few cents;
at 8.889 bps a single 100 PQOS transfer covers it many times over. **The fee is
deliberately above cost** — the surplus is what funds the relayer, the RPC
budget and the operational margin.

## 2. Why the client is better off

A client bridging manually would have to:

1. acquire the destination chain's gas token (a separate purchase, often from a
   different exchange),
2. hold it indefinitely for a transfer that happens once,
3. manage the wallet on a chain they may never touch again.

The 8.889 bps fee removes all three. That is the product: **one fee, one call,
no gas token.**

## 3. Arbitrage lanes must stay profitable

Arbitrageurs make the price honest, and they will only do it if the spread
exceeds their cost. Their cost on a round trip is:

```
fee_in  (8.889 bps)  +  fee_out (8.889 bps)  +  their own gas  +  their margin
= about 17.8 bps  +  gas  +  margin
```

So a lane becomes live at roughly a **0.2% spread**. That is a low bar — real
cross-chain spreads are frequently 1–5% — which is exactly the design intent:
**make the lane easy enough to attract the bots, wide enough that they profit,
and thin enough that the price stays tight.**

If the fee ever needs to move, it is one constant (`FEE_PPM`) and a migration,
and it is published on-chain via `fee_ppm()` so any bot can read it before it
trades.

## 4. Who makes money

| Party | Makes money by |
|---|---|
| **The client** | one call, no gas token, no bridge UI |
| **The arbitrageur** | the spread above ~0.2% |
| **The protocol** | 8.889 bps per lock, minus real gas cost |
| **The LP** | pool fees on each arb trade |

Everyone in the chain has a reason to participate, and none of them is
subsidising another.

## 5. Tron is the reach play

Solana is dropped: its program rent (~1.89 SOL, ~$180) is out of proportion to
what it returns at this stage. **Tron is already live** at
`TCDYovDaXZQsgbxDCcprFpyw2tR2ZYweF6`, and it carries three properties Solana
does not, for this project:

1. **USDT liquidity** — Tron is the largest retail USDT rail in the world.
2. **SunSwap V2/V3 and JustMoney** are CoinGecko-tracked venues.
3. **Energy rental** makes gas a rentable, predictable line item rather than a
   volatile one — the fee pool can budget it exactly.

That is why Tron gets the next liquidity, and Solana waits.

## 6. What the fee does not cover

Stated plainly so nobody is surprised later:

- **NEAR-side gas** (storage, deposits) is paid by the relayer account, funded
  from the same pool.
- **The desk's mint** currently deducts fee and storage from the deposit
  itself. That is consistent with "the client pays a fee", but it should be
  normalised to the same 8.889 bps so the pricing is one number everywhere.
- **Refunds** on a failed route are manual today; the fee should be refunded
  with the principal.
