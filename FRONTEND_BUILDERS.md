# Front-end builders — what we need and what you may charge

The protocol is finished. The interfaces are not.

Everything below is deployed on NEAR mainnet, documented, and callable today.
If you can build a clean web interface, you can build on this. **You may
charge a fair, minimal fee out of the transaction flow for your work.** We
will not complain, and the protocol will not fight you for it — the core is
sealed and has no opinion about who calls it.

---

## What we need

| # | Interface | What it does | Difficulty |
|---|---|---|---|
| 1 | **Mint desk** | deposit NEAR, receive TIAMAT, show the live curve price before the user commits | low |
| 2 | **Redeem desk** | send TIAMAT, receive a pro-rata slice of the reserve, show the quote first | low |
| 3 | **Bridge** | lock PQOS on NEAR, choose a destination chain, track the attestation and the mint | medium |
| 4 | **Pool / swap** | the internal AMM: create, add, swap, remove, plus the Ref Finance pair | medium |
| 5 | **Dashboard** | supply, reserve, curve position, holders, fee, route history | low |
| 6 | **Wallet** | internal GRIDCHAIN balance versus NEP-141 wallet balance, and the export step between them | medium |

The most valuable one is **#6 plus #1 together**: the single most common
confusion with this protocol is that minting credits an *internal* account,
and a separate export moves it to a wallet. An interface that makes that
visible removes the entire class of support question.

---

## The five call shapes you actually need

All are standard NEAR contract calls. Amounts are strings; addresses are
account IDs or 32-byte hex.

### 1. Mint — deposit NEAR, receive TIAMAT

```
contract : unog.near
method   : deposit
attach   : the NEAR you are depositing (yoctoNEAR)
args     : {} or { "account": "<32-byte hex>" }
returns  : { "ok": true, "minted_to": "<32-byte hex>" }
```

The mint is credited to a **GRIDCHAIN account**, not a wallet. Derive it as
`sha256("near-account:" + accountId)` if you want a stable per-user account,
or pass your own 32-byte id.

### 2. Export — move internal balance to a real NEP-141 wallet

```
contract : unog.near
method   : execute           (op = OP_FT_EXPORT)
args     : { "op": ..., "payload": <asset32 || amount || recipient> }
```

Requires a small NEAR balance on the *internal* account to pay the op fee.
Show that prerequisite in the UI or the export will fail with `funds`.

### 3. Redeem — send TIAMAT, receive NEAR

```
contract : post.jollydragonroger.near
method   : ft_on_transfer    (reached via ft_transfer_call on unog.near)
```

Practically: the user calls `ft_transfer_call` on the token contract
(`unog.near`) with `receiver_id = post.jollydragonroger.near`. The desk
records the request and the relayer settles it. Show the request state, not
just the transaction hash — settlement is a second step.

### 4. Bridge — lock PQOS for another chain

```
contract : unog.near
method   : ft_transfer_call
args     : { "receiver_id": "chiglet.unog.near",
             "amount": "<base units>",
             "msg": "<chain>|<recipient>" }
```

`msg` is **pipe-separated, not JSON**. The core parser rejects escaped quotes,
so `{"chain":...}` will fail. Example: `ethereum|0xcB5AA2F2...`.

`<chain>` is one of `ethereum`, `sui`, `ton`, `tron`, `aptos`.

### 5. Read state — everything a dashboard needs

| What | Call |
|---|---|
| total supply | `unog.near.ft_total_supply` |
| token metadata | `unog.near.ft_metadata` → decimals **24** |
| your balance | `unog.near.ft_balance_of({account_id})` |
| next mint price | `unog.near.tiamat_quote` |
| reserve | `unog.near` view (reserve record) |
| pool state | `unog.near.pool` with the pool key |
| your LP position | `unog.near.position` |
| bridge fee | `chiglet.unog.near.fee_ppm` → `889` (8.889 bps) |

---

## Charging a fee — how to do it properly

You are welcome to take a fee. Two clean ways:

**A. Add it to the call, transparently.** Wrap the user's action in your own
contract that takes a stated percentage, calls the protocol, and forwards the
rest. Show the fee in the confirmation screen. This is honest and auditable.

**B. Charge for the interface, not the transaction.** A flat subscription or a
one-off payment for the UI. Simpler, and nobody can accuse you of skimming.

**What we ask:** state the fee before the user signs, keep it minimal, and do
not take it out of collateral or out of a redemption the user is depending on.
A front-end that quietly shaves a redemption is the one thing that would make
this ecosystem look bad, and it would be your reputation, not ours.

**What we do not do:** we will not take a cut of your fee, we will not
whitelist you, and we cannot revoke you. The core has zero access keys and no
owner. There is no gate to pass and no permission to request.

---

## What exists to build against

| Resource | Where |
|---|---|
| Every deployed contract and its hash | `CONTRACT_ADDRESSES.md` |
| Every compiled WASM, hash-verified | `build-artifacts/` |
| How it was built | `BUILD_REPRODUCIBILITY.md` |
| Operation and payload layouts | `outposts/ROUTING_PROTOCOL.md` |
| Fee model | `outposts/FEE_AND_ARBITRAGE_ECONOMICS.md` |
| Machine-readable endpoints | `outposts/registry/gridchain.registry.json` |
| Working reference implementation | the relayer in `outposts/relayer/` |
| Token model | `WHITEPAPER_PQOS.md` |

The relayer is a complete, working client. It reads state, builds payloads,
signs, submits and confirms. If a call shape is unclear, that file is the
answer.

---

## The honest part

- **Liquidity is thin.** The Ref Finance pair exists and is real, but it holds
  fractions of a token. Do not build a UI that implies deep markets.
- **The bridge is attested, not trustless.** A 3-of-5 quorum signs cross-chain
  mints, bounded by immutable per-outpost caps.
- **Supply is small** — around 61 PQOS — and concentrated. That is the true
  state of a token that launched days ago through on-demand minting.

None of that stops you building. It just means the interface should tell the
truth, because the chain already does.

---

## Start here

1. Read `CONTRACT_ADDRESSES.md`.
2. Call `unog.near.ft_metadata` and `ft_total_supply`. If those return, you are
   connected.
3. Read `outposts/relayer/relayer.py` — it is the reference client.
4. Build the mint desk first. It is one call plus a quote, and it is the thing
   people need most.

Open an issue on the repository with what you are building and we will link it
from the README.
