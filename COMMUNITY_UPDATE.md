# NEAR community update — post and tagline

Ready to paste into the NEAR forum, Discord, Telegram or X.

---

## Short description (1,000 characters max)

```
ZEDEC/ZXV is live on NEAR mainnet and every byte of it is public.

zedec.near (kernel), scp144.near (post-quantum engine) and zedei.near
(interface) sit beneath unog.near: a paraconsistent four-valued chain with
151 operations, 214 ABI descriptors, 46 governance kinds, 12 booted layers
and ZERO access keys. No admin mint. No upgrade path. No pause.

TIAMAT (PQOS) is issued only when someone deposits NEAR collateral, priced
by phi^(21 x supply / cap). 24 decimals. No premine, no ICO, no team or
treasury allocation. Redeem burns it and returns a pro-rata slice of the
reserve.

13 contract accounts are deployed, each hash-verified against the published
WASM. Five outposts are live - Ethereum, Sui, TON, Tron, Aptos - attested
3-of-5 with immutable caps. Fee: 8.889 bps.

Front-end developers wanted: everything is documented, the bytecode is
public, and you may charge a fair fee.

github.com/sykomiked/zedec-zxv-deployment
```

**Length: 929 characters** (limit 1,000).

---

## Tagline (140 characters max)

```
TIAMAT: minted only against NEAR collateral on a rising curve. No premine,
no admin mint, no upgrade path.
```

**Length: 106 characters** (limit 140).

### Alternates, if the tone needs to shift

| Tagline | Chars |
|---|---|
| `TIAMAT: every token is bought into existence with collateral. No premine, no team allocation, no admin mint.` | 106 |
| `TIAMAT: a settlement token with no owner. Sealed core, zero keys, collateral-backed issuance.` | 96 |
| `TIAMAT (PQOS): collateral-backed settlement on NEAR. Redeemable, verifiable, unownable.` | 86 |

---

## Longer post, for the forum or a blog (no limit)

**ZEDEC/ZXV — a sealed settlement stack on NEAR, now public**

We have deployed a complete vertical stack to NEAR mainnet, and we have
published the compiled bytecode of every contract so that nobody has to take
our word for any of it.

**What is deployed.** Six application contracts plus seven satellite kernels,
thirteen accounts in total, every one hash-verified against the exact bytes
running on chain. The kernel is `zedec.near`; the post-quantum engine is
`scp144.near`; the interface and automation layer is `zedei.near`; and above
them sits `unog.near`, a chain inside a contract — 151 operations, 214 ABI
descriptors, 46 governance kinds, 12 booted layers.

**What makes it unusual.** `unog.near` is sealed with zero access keys. There
is no admin function, no upgrade path, no pause switch and no owner. That is
verifiable by reading the account, not by trusting a disclosure.

**The token.** TIAMAT (PQOS) is a 24-decimal NEP-141 asset issued only on
demand. A minter deposits NEAR and receives tokens priced by
`phi^(21 × supply / cap)`, so the collateral per token rises monotonically and
supply approaches a hard asymptote. There was no premine, no ICO, no private
sale, no team allocation and no treasury allocation. Redemption burns the
token and returns a pro-rata slice of the reserve.

**The bridge.** PQOS can be locked on NEAR and represented on five chains:
Ethereum, Sui, TON, Tron and Aptos. Each outpost is pinned to the NEAR core by
an immutable code hash and carries an immutable supply cap. Settlement uses a
3-of-5 attestor quorum. **It is attested, not trustless, and we say so in the
documentation rather than in a footnote.**

**The fee.** 8.889 basis points per routed transfer. It funds destination-chain
gas so that clients never need the destination chain's native token.

**Why we are posting.** We need front-end developers. The protocol is
complete and documented; the interfaces are not. Everything required to build
one — call shapes, payload layouts, view methods, error codes, a working
reference implementation — is in the repository. Developers may charge a fair,
minimal fee out of the transaction flow for their work. See
`FRONTEND_BUILDERS.md`.

Repository: `https://github.com/sykomiked/zedec-zxv-deployment`
