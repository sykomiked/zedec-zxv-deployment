# Outpost deployment — capital requirements

All figures in USD unless stated. Prices read from the 1Click/Intents feed on
2026-11-01: SOL $94.81 · SUI $0.8976 · APT $0.6334 · STRK $0.0428 · ETH
$2,289.32 · ADA $0.19237 · NEAR $4.26.

**Verified** means read from the protocol's own documentation; **estimate**
means it must be confirmed on-chain before spending.

---

## 1. Per-outpost infrastructure (before liquidity)

| Outpost | Token deploy | Pool creation | Gas buffer | **Subtotal** | Confidence |
|---|---|---|---|---|---|
| **Sui / Cetus** | ~0.02 SUI ($0.02) | permissionless ($0.02) | 0.1 SUI ($0.09) | **$0.13** | verified (Cetus docs: permissionless) |
| **Aptos / Thala** | ~0.01 APT ($0.01) | permissionless (~$0.02) | 0.05 APT ($0.03) | **$0.06** | estimate |
| **Starknet / Ekubo** | ~0.001 ETH ($2.29) | permissionless (~$0.50) | 0.002 ETH ($4.58) | **$7.37** | estimate (Starknet gas) |
| **Cardano / Minswap** | ~2 ADA ($0.38) | ~3 ADA ($0.58) | 2 ADA ($0.38) | **$1.34** | estimate |
| **TON / STON.fi** | ~0.1 TON ($0.50) | ~0.5 TON ($2.50) | 0.2 TON ($1.00) | **$4.00** | estimate |
| **Aurora / Trisolaris** | ~0.0001 ETH ($0.23) | ~0.001 ETH ($2.29) | 0.002 ETH ($4.58) | **$7.10** | gas verified (0.07 gwei) |
| **Solana / Raydium** | ~0.002 SOL ($0.19) | **0.15 SOL fee + rent = 0.19 SOL ($18.01)** | 0.01 SOL ($0.95) | **$19.15** | **verified** (Raydium docs) |

**Infrastructure total, all seven: ≈ $39.15.**
**Cheapest three (Sui, Aptos, Cardano): ≈ $1.53.**

## 2. Seed liquidity (the real cost)

A pool with no liquidity is a shop window. The rule: seed each outpost at
the core's quoted price so the first arbitrage is a rounding error, not a
drain.

| Outpost | Minimum credible seed | Comfortable seed |
|---|---|---|
| Sui | 5 PQOS + ~$25 of SUI | 20 PQOS + ~$100 |
| Aptos | 5 PQOS + ~$25 of APT | 20 PQOS + ~$100 |
| Starknet | 5 PQOS + ~$25 of ETH | 20 PQOS + ~$100 |
| Cardano | 5 PQOS + ~$25 of ADA | 20 PQOS + ~$100 |
| TON | 5 PQOS + ~$25 of TON | 20 PQOS + ~$100 |
| Aurora | 5 PQOS + ~$25 of ETH/WNEAR | 20 PQOS + ~$100 |
| Solana | 5 PQOS + ~$25 of SOL | 20 PQOS + ~$100 |

**Seven outposts at minimum seed: ≈ $175 of paired assets + 35 PQOS.**
PQOS is not free — it must be minted against NEAR on the core, or locked
from existing holdings.

## 3. Routing infrastructure

The attestor quorum is not free to run well.

| Item | Cost |
|---|---|
| 5 attestor keys, separate custody | $0 (hardware you already own) |
| 3-of-5 signing service (a small VPS each) | ~$15/month total |
| Monitoring (ticket lag, cap usage, state drift) | ~$5/month |
| **Operational, monthly** | **≈ $20** |

## 4. Recommended sequence and budget

| Phase | Outposts | Infrastructure | Seed | **Total** |
|---|---|---|---|---|
| **Phase 1** | Aurora | $7.10 | $25 | **$32.10** |
| **Phase 2** | Sui + Aptos | $0.19 | $50 | **$50.19** |
| **Phase 3** | Cardano + Starknet | $8.71 | $50 | **$58.71** |
| **Phase 4** | TON | $4.00 | $25 | **$29.00** |
| **Phase 5** | Solana | $19.15 | $25 | **$44.15** |
| | | | **Grand total** | **≈ $214** |

## 5. What you have now

| Asset | Amount | Value |
|---|---|---|
| NEAR (jollydragonroger) | ~51.7 NEAR | ~$220 |
| ETH on Ethereum (unbridged) | 0.01094 ETH | $25.04 |
| PQOS supply | 50.39 TIAMAT, fully backed | — |
| PQOS held in reserve (gridchain account) | ~46 TIAMAT | — |

**You can fund Phase 1 and Phase 2 today** from the ETH and a slice of the
NEAR. Phases 3–5 need either more capital or revenue.

## 6. Honest warnings

1. **The seed liquidity is the cost, not the contracts.** Contracts cost
   dollars; pools cost tens of dollars each.
2. **Seven thin pools are worse than two real ones.** A $25 pool is
   arbitraged to nothing by bots within hours if it is mispriced, and it
   signals weakness to anyone reading the chain.
3. **The attestor quorum is the trust boundary.** 3-of-5 keys held by one
   person is not decentralisation; the contracts say `attested` for that
   reason.
4. **Every figure marked estimate must be confirmed on-chain before
   spending.** I will not spend against an unverified number.

---

## 7. Gas token per chain — do not confuse these

| Chain | Gas is paid in | **Not** |
|---|---|---|
| **Aurora** | **ETH** (native, verified: `eth_gasPrice` = 0.07 gwei) | **AURORA** is an ERC-20 governance token and pays no gas |
| **Starknet** | **ETH or STRK** (STRK added in v0.13.0; both accepted) | — |
| **Sui** | SUI | — |
| **Aptos** | APT | — |
| **Solana** | SOL | — |
| **Cardano** | ADA | — |
| **TON** | TON | — |
| **NEAR** | NEAR | PQOS never pays gas anywhere |

**The costly mistake:** sending the AURORA token to the Aurora outpost address.
It arrives, it is yours, and it cannot pay for a single transaction. Send ETH.

## 8. Revised plan under a smaller seed

Fewer outposts, done properly. Infrastructure bill for the first three:

| Outpost | Infrastructure |
|---|---|
| Aurora | $7.10 |
| Sui | $0.13 |
| Aptos | $0.06 |
| **Total** | **$7.29** |

Everything else is seed liquidity, and seed is the real constraint. Defer
Cardano, TON, Starknet and Solana until there is capital that can survive
being arbitraged.

---

## 9. Extended set: Ethereum mainnet, Polkadot, Cosmos, Tezos

Prices 2026-11-01: ETH $2,292.67 · DOT $0.9576 · GLMR $0.007955 · ASTR
$0.005740 · OSMO $0.04802 · ATOM $1.46 · XTZ $0.25008.

### Ethereum mainnet — the cheapest it has ever been

Measured live: `eth_gasPrice` = **0.03 gwei**.

| Item | Gas | Cost |
|---|---|---|
| Contract deploy (~1.5M gas) | 1,500,000 | 0.000049 ETH = **$0.11** |
| Uniswap pool creation (~500k) | 500,000 | 0.000016 ETH = **$0.04** |
| **Infrastructure total** | | **≈ $0.15** |

The same `WrappedPQOS.sol` that compiles for Aurora deploys here unchanged.
**Ethereum mainnet is now cheaper to enter than Sui was.** Seed liquidity
dominates entirely.

### Polkadot — via an EVM parachain, not ink!

CoinGecko tracks **StellaSwap**, **Beamswap**, **ArthSwap**, **Zenlink** and
**Hydration** — and StellaSwap/Beamswap/ArthSwap/Zenlink run on **EVM
parachains** (Moonbeam, Astar). So the Solidity contract deploys unchanged;
no ink! toolchain is needed.

| Item | Cost |
|---|---|
| Deploy on Moonbeam (~1.5M gas in GLMR) | ~0.5–2 GLMR = **$0.004–0.016** |
| StellaSwap pool creation | ~1–5 GLMR = **$0.008–0.04** |
| **Infrastructure total** | **≈ $0.05** |

Native DOT is *not* needed for the contract; GLMR pays gas on Moonbeam.

### Cosmos — Osmosis, CosmWasm

| Item | Cost |
|---|---|
| CosmWasm store + instantiate | ~2–5 OSMO = **$0.10–0.24** |
| Osmosis pool creation | ~1–10 OSMO = **$0.05–0.48** |
| **Infrastructure total** | **≈ $0.60** |

Requires a **CosmWasm contract in Rust** — new code, not a redeploy.
ATOM is not needed; OSMO pays gas on Osmosis.

### Tezos — Quipuswap / Spicyswap

| Item | Cost |
|---|---|
| Origination | ~0.1–1 XTZ = **$0.03–0.25** |
| Quipuswap pool | ~0.1–1 XTZ = **$0.03–0.25** |
| **Infrastructure total** | **≈ $0.50** |

Requires a **Michelson contract** (SmartPy or LIGO) — new code.

### Infrastructure totals across all ten outposts

| Outpost | Infra | Contract status |
|---|---|---|
| Sui | $0.13 | **DEPLOYED** |
| Aurora | $7.10 | compiled |
| Aptos | $0.06 | written |
| **Ethereum mainnet** | **$0.15** | **compiled — deployable today** |
| **Polkadot (Moonbeam)** | **$0.05** | **compiled — same Solidity** |
| Cosmos (Osmosis) | $0.60 | needs CosmWasm |
| Tezos | $0.50 | needs Michelson |
| Cardano | $1.34 | needs Aiken |
| Starknet | $7.37 | written |
| Solana | $19.15 | compiled |

**All ten, infrastructure only: ≈ $36.45.**

### The revised recommendation

Ethereum mainnet at $0.15 and Polkadot at $0.05 change the priority order.
Both use the **contract that is already compiled and tested**. With the
0.01094 ETH you already hold on Ethereum, you can deploy to **Ethereum
mainnet today** without bridging anything.

Suggested order now:

1. **Ethereum mainnet** — $0.15, contract ready, ETH already in the wallet.
2. **Polkadot/Moonbeam** — $0.05, same contract, needs GLMR.
3. **Aurora** — $7.10, still needs the ETH bridged.
4. **Solana** — $19.15, binary ready.
5. Cosmos, Tezos, Cardano — new contract languages, lower priority.
