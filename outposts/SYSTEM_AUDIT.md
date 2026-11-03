# GRIDCHAIN / TIAMAT — full system audit

Date: 2026-11-01. Audited by inspection of the sealed core's ABI, the deployed
satellites, and the routing protocol. Every claim below is checkable with a
view call.

---

## 1. What is live

| Component | Address | State |
|---|---|---|
| **Core** | `unog.near` | sealed, 0 keys, code `Ae5uDVYK…`, 151 ops |
| **Bridge satellite** | `chiglet.unog.near` | RouteLock, code `Cd6wDoht…`, 3-of-5, bound to `unog.near` |
| **Ethereum outpost** | `0xAd558001…5142` | wPQOS, verified on Sourcify (exact match) |
| **Sui outpost** | `0x9953147d…bdae` | wPQOS package, immutable |
| **TON outpost** | `UQCJqL-7Q2…Zj9` | wPQOS routing controller |
| **Tron outpost** | `TCDYovDaXZ…eF6` | wPQOS, same audited bytecode as Ethereum |

Four outposts live, one bridge satellite live, one sealed core. All wrapped
supplies are **0** — nothing has been minted through a route yet.

## 2. The core's capabilities, as they actually exist

Scanned all 151 operations. The ones that matter for money movement:

| Op | Name | What it does |
|---|---|---|
| 2 | `withdraw` | gridchain NEAR balance -> a NEAR account |
| 3 | `deposit` | NEAR -> a gridchain account's balance |
| 5 | `voucher_mint` | mints TIAMAT against NEAR on the curve |
| 6 | `voucher_redeem` | burns TIAMAT for a pro-rata slice of the reserve |
| 10 | `claim` | escrows an amount under judges |
| 75 | `rail_withdraw` | the Intents rail exit |

`tiamat_quote({value})` returns the exact TIAMAT a deposit would issue:
**1 NEAR -> 0.999999996 TIAMAT** at the current supply.

## 3. The finding that shapes the whole interface

**`voucher_mint` and `voucher_redeem` are GRIDCHAIN ops.** They are not NEAR
methods: they travel inside a signed transaction submitted to `unog.near`'s
`tx` method, signed ed25519 by a GRIDCHAIN account key.

**A NEAR contract cannot produce that signature.** There is no signing host
function, and shipping a private key into a contract would expose it to every
node. So no contract can mint or redeem on a user's behalf by itself.

This is the reason the "terminal trick" exists, and it is why a naive
"mint desk contract" cannot work: the desk can accept NEAR, but it cannot
sign the transaction that turns NEAR into TIAMAT.

## 4. The correct architecture: desk + relayer

The interface is split into a contract that *records intent* and a relayer
that *executes it*. That is the only design that is both streamlined for the
user and safe for the key.

```
user ──(one call, NEAR)──> MintDesk ──event──> relayer ──signed tx──> core
                                │                                    │
                                └──────── TIAMAT forwarded ──────────┘
```

### 4.1 MintDesk (contract, on NEAR)

```
mint()   payable          # user sends NEAR, gets TIAMAT
redeem() via ft_on_transfer  # user sends TIAMAT, gets NEAR
quote(amount) view        # reads unog.near.tiamat_quote
```

The desk records `{user, amount, nonce}` and emits a standard event. It holds
no key and moves no value itself.

### 4.2 Relayer (off-chain, run by the attestors)

Watches the desk's events and, per request:
1. `deposit({to: <desk gridchain id>})` with the NEAR (mint) or uses the
   desk's TIAMAT balance (redeem).
2. Builds and signs the `voucher_mint` / `voucher_redeem` transaction with the
   desk's GRIDCHAIN key, which lives in the key ledger, never on-chain.
3. `ft_transfer` the TIAMAT to the user (mint) or `withdraw` the NEAR to the
   user (redeem).
4. Records the transaction hash against the desk's request nonce.

This is the same trust model as the bridge: **attested, bounded, auditable** —
not trustless. The desk's key is a hot key with a hard cap and a published
balance, and every action is a public transaction.

### 4.3 Why not a contract-held key

Because a contract's storage is readable by every validator and every archive
node. A key in contract storage is a published key. The relayer keeps it in
the ledger where it belongs.

## 5. Cross-chain purchase and redemption

The desk is on NEAR, so the cross-chain path is:

**Buy from Ethereum/Tron/TON/Sui:**
1. The user holds the chain's native token.
2. They swap or bridge it to NEAR (1Click, or the chain's own bridge).
3. They call `mint()` on the desk with NEAR.
4. The relayer mints and forwards TIAMAT to their NEAR account.
5. If they want it back on their chain, they lock it in `RouteLock` and the
   outpost mints wPQOS.

**Redeem from any chain:**
1. Burn wPQOS on the outpost -> a `RELEASE` ticket.
2. The attestors sign; `RouteLock.release()` sends TIAMAT on NEAR.
3. The user calls `redeem()` on the desk; the relayer burns and sends NEAR.
4. They bridge the NEAR out if they want.

The outpost tokens are therefore **claims on NEAR TIAMAT**, and the desk is the
only place where TIAMAT is created or destroyed.

## 6. Risks, stated plainly

| Risk | Severity | Mitigation |
|---|---|---|
| Desk relayer key compromise | **High** — it can mint without deposits | hard cap per epoch, published balance, key in ledger not contract |
| Attestor quorum compromise (3-of-5) | **High** — bounded by each outpost's cap | cap is immutable; 25% of supply max per outpost |
| Wrapped supply exceeds locked PQOS | **Critical if it happens** | `RouteLock` must be the only source of MINT tickets; the relayer must refuse to attest a lock it did not observe |
| Outpost pool mispricing | Medium | seed at `tiamat_quote`; bots will arb any gap |
| Sealed core defect | **Unfixable** | the core cannot be patched; only superseded by a new satellite |
| Single-operator concentration | Medium | Apache-2.0, public repos, published keys |

**The critical invariant to enforce in code, not prose:**

> the relayer must never sign a MINT ticket unless it has observed a
> corresponding `Locked` event in `RouteLock`, and the sum of all minted
> wPQOS must never exceed the TIAMAT held by `RouteLock`.

That check belongs in the relayer, and its state should be published.

## 7. What is missing before a public launch

1. **MintDesk + relayer** — the streamlined interface (this audit's subject).
2. **First end-to-end route** — lock, attest, mint, verify on one chain.
3. **Pool creation** on one DEX with real wrapped supply.
4. **A published attestor register** — who the five keys belong to.
5. **A cap policy** — the per-epoch mint limit for the desk.

## 8. Audit verdict

The deployed contracts are sound for what they claim: bounded, attested,
immutable, and honest about their trust model. The **interface** is not yet
built — and without it the protocol has no way for an ordinary user to obtain
TIAMAT, which is the whole point.

Building the desk and relayer is the correct next step. It is also the point
at which the key custody model must be written down publicly, because from
that moment a hot key exists that can mint.
