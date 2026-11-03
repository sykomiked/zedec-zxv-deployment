# GRIDCHAIN Route Protocol (GRP) v1

How an outpost on an external chain links back to the sealed core at
`unog.near`, and how arbitrage finds the routes.

---

## 1. The shape of the system

```
                     ┌──────────────────────────┐
                     │  unog.near (sealed core) │
                     │  PQOS supply + reserve   │
                     └────────────┬─────────────┘
                                  │ lock / release
                     ┌────────────▼─────────────┐
                     │   attestor quorum (M/N)  │
                     │  observes, signs tickets │
                     └────────────┬─────────────┘
        ┌──────────────┬──────────┼──────────┬──────────────┐
        ▼              ▼          ▼          ▼              ▼
   Aurora (EVM)     Sui        Aptos     Solana        Starknet
   wPQOS ERC-20   wPQOS coin  wPQOS coin wPQOS SPL    wPQOS ERC-20
```

The core never changes. Every outpost is a **satellite**: a separate
contract, pinned by code hash, that holds only wrapped PQOS — never the
reserve.

## 2. The invariant

> **Total wrapped PQOS across all outposts ≤ PQOS locked on the core.**

Every outpost enforces its own share of this with a hard supply cap. No
outpost can mint beyond its cap, even if its attestors are fully
compromised. The cap is set at deployment and is immutable.

Recommended caps (fractions of the NEAR supply at deployment):

| Outpost | Cap |
|---|---|
| Aurora | 25% |
| Sui | 15% |
| Aptos | 15% |
| Solana | 25% |
| Starknet | 10% |
| TON, Cardano | 5% each |

## 3. The route ticket

A ticket is the only thing that authorises a mint or a release. It is
chain-agnostic; each outpost encodes it in its own ABI.

```
GRP-TICKET-v1
  version     : u8   = 1
  direction   : u8   (0 = MINT on outpost, 1 = RELEASE on core)
  chain_id    : u32  (the destination chain)
  nonce       : u64  (monotonic per chain)
  amount      : u128 (base units, 24 decimals)
  recipient   : 32   (chain-native encoding, left-padded)
  expiry      : u64  (unix seconds)
```

`route_id = sha256("GRP-TICKET-v1" ‖ borsh(ticket))`

The signed digest is:

```
digest = sha256("GRP-SIG-v1" ‖ chain_tag ‖ route_id)
```

where `chain_tag` is the core's genesis tag, the same value the core
exposes as `status().chain_tag`.

## 4. Paraconsistent ticket state

Every outpost records four states per ticket, and **only `TRUE` executes**:

| State | Meaning | Effect |
|---|---|---|
| `NEITHER` (0) | no quorum yet | held |
| `TRUE` (1) | quorum of distinct attestors signed | **mints or releases** |
| `FALSE` (2) | an attestor refuted it, or expiry passed | refused, funds stay locked |
| `BOTH` (3) | conflicting signatures (one attestor signed twice with different payloads, or a refutation after a quorum) | **held as evidence, never executed** |

`BOTH` is the important one. A disagreement is not resolved by majority and
not by last-writer-wins; the ticket is frozen and the event is recorded.
That is the core's own rule, carried to the edge.

## 5. Attestors

The quorum is the bridge's weakest point, and this document says so plainly.

- `M` of `N` distinct attestor keys must sign the same `route_id`.
- Attestors are published at deployment, immutable afterwards.
- A ticket signed twice by the same attestor is `BOTH`, never `TRUE`.
- Recommended: `N = 5`, `M = 3`, keys held in separate custody.

**This is an attested bridge, not a trustless one.** A trustless design
would verify the core's state inside the outpost (a light client), which is
expensive and, for NEAR, not yet practical on every target chain. Every
outpost contract therefore states `attested` in its metadata so no user can
mistake it for something stronger.

## 6. The two directions

### Lock → Mint (NEAR to outpost)

1. A holder calls the core's `deposit`/`tx` path to lock PQOS against the
   route (the core's `cstore` op records the destination).
2. Attestors observe the lock, build a `MINT` ticket, sign the digest.
3. Anyone submits the ticket plus signatures to the outpost.
4. The outpost verifies quorum, cap, expiry and nonce, sets the ticket
   `TRUE`, and mints wPQOS to the recipient.

### Burn → Release (outpost to NEAR)

1. A holder calls `burn(amount, near_recipient)` on the outpost.
2. The outpost burns the wPQOS and emits a `RELEASE` ticket.
3. Attestors observe the burn, sign the release.
4. Anyone submits it to the core, which releases the locked PQOS.

The burn is immediate and irreversible on the outpost; the release is
attested on the core. That asymmetry is deliberate: a stalled release is
recoverable (the ticket stays valid until expiry), a double-mint is not.

## 7. Why arbitrage finds the routes

Arbitrage bots do not read this document. They read prices. Three things
make the routes visible:

1. **A pool on a CoinGecko-tracked DEX** at each outpost, so the pair is
   indexed and a price exists.
2. **The same symbol (`PQOS`) everywhere and a documented scale factor.**
   Decimals cannot be 24 on every chain: Sui and Solana hold `u64`
   balances, Aptos `u64`, EVM `uint256`. The mapping is fixed and published:

   | Chain | Decimals | Scale from NEAR base units |
   |---|---|---|
   | NEAR (core) | 24 | 1 |
   | Aurora / Starknet (EVM) | 18 | ÷ 1e6 |
   | Solana | 9 | ÷ 1e15 |
   | Sui | 9 | ÷ 1e15 |
   | Aptos | 8 | ÷ 1e16 |

   Each contract divides the ticket amount by its scale factor, so a ticket
   is always expressed in the core's units and the outpost converts once.
3. **A published price feed**: each outpost exposes `quote()` returning the
   wPQOS price in the chain's native unit, and the core exposes
   `tiamat_quote`. A bot that compares the two has everything it needs.

The danger is symmetrical: **a mispriced outpost pool is drained within
seconds.** Every outpost must be seeded at the core's quoted price, and the
cap limits the damage if it is not.

## 8. What each outpost contract must implement

| Requirement | Why |
|---|---|
| `mint(ticket, signatures)` with M-of-N | the only issuance path |
| `burn(amount, recipient)` emitting a release ticket | the only exit |
| immutable supply cap | limits attestor compromise |
| ticket state NEITHER/TRUE/FALSE/BOTH | the core's rule at the edge |
| nonce monotonicity | replay protection |
| expiry | bounded validity |
| `attested` in metadata | honesty about the trust model |
| no owner mint, no pause-by-owner | the core has no such switch either |

## 9. What this protocol does not do

- It does not verify NEAR state inside the outpost. That is the attestors' job.
- It does not make the outposts trustless. It makes them **bounded**.
- It does not guarantee liquidity. It guarantees that no more wPQOS can
  exist than is locked, and that a contradiction halts rather than guesses.
