# CoinGecko submission — categories and additional information

Ready to paste. Each category includes its justification at 250+ characters.

---

## Category 1 — Infrastructure

**Infrastructure**

TIAMAT is the settlement asset of GRIDCHAIN, a cross-chain routing and
settlement layer that runs as a sealed contract on NEAR. The protocol provides
addressable infrastructure rather than an application: a four-valued state
machine with 151 operations, a content-addressed store, an internal automated
market maker, an oracle surface, and a publishable routing mesh. Other
protocols, bots and front-ends consume it as a service, paying 8.889 basis
points per route. It is infrastructure in the same sense that a settlement
network is: it does not compete with the applications on top of it, it carries
them.

## Category 2 — Interoperability / Cross-Chain Bridge

**Interoperability**

TIAMAT is designed to move across chains. A holder locks PQOS on NEAR through
the bridge satellite `chiglet.unog.near`; a 3-of-5 attestor quorum signs the
resulting ticket; and a bounded representation is minted on the destination
chain. Five outposts are live today — Ethereum, Sui, TON, Tron and Aptos — each
pinned to the NEAR core by an immutable code hash and an immutable supply cap.
The reverse path burns the wrapped token and releases the original on NEAR.
Every outpost publishes the same chain tag, the same fee, and the same
four-valued verdict logic, so a router can treat all of them uniformly.

## Category 3 — DeFi (Decentralised Finance)

**DeFi**

TIAMAT is issued on demand against collateral, not sold in advance. A minter
deposits NEAR and receives tokens priced by a rising curve — `phi^(21 × supply
/ cap)` NEAR per token — so backing per token increases monotonically and the
supply approaches a hard asymptote of 144,000,000,000. Redemption burns the
token for a pro-rata slice of the reserve. The protocol also operates its own
automated market maker (create, add, swap, remove) with a 30 bps pool fee, and
a service fee of 8.889 bps on routed transfers. There is no admin mint, no
emissions schedule and no rebase: every token in existence was created by
someone depositing collateral.

---

## Additional information (paste into the "Additional information" field)

**Decimals — please read this first.**

TIAMAT has **24 decimals** on-chain. The submission form accepted only 18
decimals, so 18 was entered to proceed. **The true value is 24.** One whole
TIAMAT is `1,000,000,000,000,000,000,000,000` base units. If the listing shows
a supply or price that is off by a factor of 10^6, this is why, and the 24
figure is the correct one.

**Contract and identity.**

- Contract / mint address: **`unog.near`** (platform `near-protocol`; NEAR
  contracts are named accounts, not hex addresses)
- Name: TIAMAT · Symbol: PQOS · Standard: NEP-141 (`ft-1.0.0`)
- Total supply at submission: **61.470008027182581764720275 PQOS**
- Circulating: **60.760008027182405762520281 PQOS**
- Maximum supply: **144,000,000,000 PQOS**, enforced by the curve, not by an
  admin key

**The mint-on-demand model.**

There was no pre-mine, no ICO, no private sale, no team allocation and no
vesting. Every PQOS in existence was minted by a user depositing collateral
into the sealed core. The price of the next token is set by the curve:

```
backing per new TIAMAT = phi^(21 × supply / cap) NEAR
```

`phi` is the golden ratio. Because the exponent grows with supply, the
collateral required per new token **rises monotonically** — early minters pay
less than late ones, and issuance cannot be accelerated by time or by an
insider. The curve approaches the cap asymptotically. Redemption runs the same
mechanism in reverse: `voucher_redeem` burns PQOS and returns a pro-rata slice
of the whole reserve.

**No admin mint exists.** The core `unog.near` is sealed with **zero access
keys** — verifiable on-chain. There is no owner-mint function, no pause, no
upgrade path. New capability is added by deploying satellite contracts that
reference the core's code hash, never by editing it.

**Cross-chain.** Wrapped PQOS exists on five chains, each with an immutable
supply cap and a 3-of-5 attested quorum: Ethereum
`0xAd55800116817E3A0884B514BAb508aFd9e95142` (verified on Sourcify,
`exact_match`), Sui package
`0x9953147df1732aa900a3ad0f2580e2fc256a727b861ba96e2acc73e4beb2bdae`, TON
`UQCJqL-7Q20RrKOMSIUFcHXHN76LzjrxQYGBtAfBJ3MP5Zj9`, Tron
`TCDYovDaXZQsgbxDCcprFpyw2tR2ZYweF6`, and Aptos
`0xd82e10769f6b4280d45a13246ca1cfb66902de30702246e2014b195ddfd197b6::wrapped_pqos`.

**Trading venues.** Ref Finance pool **8992**, PQOS/wNEAR:
`https://app.ref.finance/#/pools/8992`. The protocol also operates its own
internal AMM inside `unog.near` with a 30 bps fee.

**Fee.** 8.889 basis points (889 ppm) on routed transfers. Clients never pay
destination-chain gas directly; the fee funds it. The fee is readable on-chain
via `chiglet.unog.near.fee_ppm()`.

**Trust model — stated honestly.** The bridge is **attested, not trustless**. A
3-of-5 quorum signs cross-chain mints, and each outpost carries an immutable
cap that bounds what a compromised quorum could create. The core is sealed and
immutable. We would rather be judged on an accurate description than a
flattering one.

**Links.**
Repository: `https://github.com/sykomiked/zedec-zxv-deployment`
Holders: `https://pikespeak.ai/token/unog.near`
GeckoTerminal token page: `https://www.geckoterminal.com/near/tokens/unog.near`
