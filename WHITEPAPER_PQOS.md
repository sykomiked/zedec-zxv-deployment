# TIAMAT (PQOS)

## A sealed settlement contract on NEAR, and the token it issues

**Version 1.0 — 1 November 2026**
Scenic Bypass Consulting, LLC · 36N9 Genetics, LLC
Contract: `unog.near` · Code hash `Ae5uDVYKhZpwgCBDTcSQGk26azY4ytzBH69kUL2FD8y5`
Licence: Apache-2.0

---

## Abstract

TIAMAT (PQOS) is the token of GRIDCHAIN, a twelve-layer settlement
contract deployed on NEAR mainnet at `unog.near` and sealed on the day of
its deployment with zero access keys. The contract is not a wrapper around
a token: it is a complete, immutable piece of financial infrastructure
whose code hash is the base58 of its published artefact's SHA-256, and
which can be inspected in full with free view calls.

Three properties distinguish it. First, **post-quantum signature
verification runs inside the contract** — ML-DSA-87 (FIPS 204) and
SLH-DSA-SHAKE-256s (FIPS 205) — in ordinary WebAssembly, without host
functions or protocol changes. Second, **every monetary value is exact**:
integers with a fixed scale or reduced rationals, never floating point.
Third, **settlement is paraconsistent**: contested events are recorded as
a value and held, and only `TRUE` can release value.

The contract also carries a **period-finding module**: it verifies that a
claimed period is the true order of a base modulo N, recovers the factors
that period implies, and detects the period of a bounded state sequence.
This is the classical half of Shor's algorithm, used constructively — to
tell whether a legacy modulus is already broken, with a proof rather than
a warning.

TIAMAT is issued only against a NEAR reserve, on a deterministic
golden-ratio curve, with no admin mint, no premine and no privileged key.

---

## 1. The problem

Three failures are converging on financial infrastructure at once.

**The quantum transition.** Records signed today with classical keys can
be forged once a large fault-tolerant quantum computer exists, and data
encrypted today can be harvested now and decrypted later. The industry's
answer has largely been a roadmap. A roadmap is not a verification.

**Floating-point drift.** Core ledgers at scale still run on packed
decimal arithmetic. Re-platforming them onto floating-point environments
introduces representation drift: most decimal fractions cannot be
represented exactly in binary, rounding modes accumulate, and
reconciliation breaks appear in high-volume posting runs.

**Contested settlement.** Chargebacks, dual-presented instruments and
disputed corporate actions are handled by exception queues because
conventional systems have no first-class representation for "both sides
assert" or "neither side has proven". Software resolves this by panic, by
last-writer-wins, or by majority — three ways of destroying evidence.

## 2. The architecture

GRIDCHAIN is a twelve-layer contract (L2 to L13) on NEAR, plus a
fourteenth partition — User Space — that sits beside the layers as a
socket rather than a gear. Each layer is a fee grade and a capability
band: verification, transport, trust, logic, AI, settlement, adapters and
products.

The contract was assembled from twelve independently developed lanes and
passed **1,858,226 automated checks** with AddressSanitizer and
UndefinedBehaviorSanitizer enabled, a VM gate of 26 scenarios, and a
release build that is byte-identical between serial and parallel
compilation. The deployed artefact is 1,156,670 bytes, strict WebAssembly
MVP.

**Sealing.** After activation, the contract entered stage `LOCKED` and
the last access key was deleted. It now has zero keys. No one — including
its author — can redeploy it, upgrade it or change a parameter. Every
future capability must be a new satellite contract, pinned to the sealed
core by code hash.

This is the central design decision: **trust is replaced by
verification**. A user does not need to believe a promise about future
behaviour, because the future behaviour is fixed in bytes whose hash they
can read.

## 3. Exact arithmetic

Money in GRIDCHAIN is never a `float` or a `double`. Values are 128-bit
integers with a fixed scale, or reduced rationals (`num`, `den`, `valid`)
with overflow and division-by-zero invalidating rather than wrapping.

The practical consequence is that **IBM Z COBOL packed decimal
(`COMP-3`), EBCDIC and zoned decimal, FORTRAN numeric data and ISO
20022-shaped messages convert exactly**. A posting migrated from a
mainframe produces the same digits, and reconciliation differences caused
by rounding cannot enter the ledger.

## 4. Paraconsistent settlement

GRIDCHAIN's settlement logic is four-valued:

| Value | Code | Meaning | May it settle? |
|---|---|---|---|
| `NEITHER` | 0 | no evidence yet | no — held |
| `TRUE` | 1 | attested and valid | **yes** |
| `FALSE` | 2 | attested absent or invalid | no — refused |
| `BOTH` | 3 | evidence for and against | no — held as evidence |

The values are ordered on a single chain, `FALSE < NEITHER < BOTH <
TRUE`, and the combining operators are the minimum and maximum on that
chain. The property that matters is structural: **no combination of
non-TRUE values can produce TRUE**. A contradiction plus ignorance can
never release funds.

A disagreement is therefore a recorded state, not an exception. Oracles
that disagree produce `BOTH` and the funds stay escrowed. A cross-shard
callback that disagrees is isolated and earlier receipts stay committed. A
boot sequence prints success only when every self-check is `TRUE`.

## 5. Post-quantum verification

The contract verifies, in userland Wasm:

- **ML-DSA-87** (FIPS 204), at about 7.4 Tgas per verification;
- **SLH-DSA-SHAKE-256s** (FIPS 205), at about 53.6 Tgas;
- a **dual** mode requiring both.

These are ordinary contract calls. They require no host function, no
protocol upgrade and no coordination with the runtime. A contract, a DAO
or an agent can require a post-quantum attestation for a long-lived
decision today.

## 6. Period finding: the constructive use of Shor

Shor's algorithm has two halves. The quantum half finds the period of
`a^x mod N`. The classical half turns that period into factors.

The contract implements the classical half exactly, and uses it
defensively:

- **VERIFY** — confirms that `a^r ≡ 1 (mod N)` and that `r` is minimal
  (for every prime `p` dividing `r`, `a^(r/p) ≠ 1`). Returns `TRUE`,
  `FALSE`, or `NEITHER` when the bound is reached. It never guesses.
- **FACTOR** — from a verified even period, computes
  `gcd(a^(r/2) ± 1, N)`. A successful result is a *proof* that the modulus
  is broken, not a warning that it might be.
- **CYCLE** — finds the period of a bounded window of 64-bit states, which
  is how a repeating regime in an external chain's load states can be
  recognised rather than averaged away.

The arithmetic is written like a chip: fixed 64-bit registers, Russian
peasant multiplication (no 128-bit type), deterministic Miller-Rabin, no
allocation, no floating point. A verification completes in about 13.5
Tgas, leaving roughly three quarters of a NEAR transaction frame in hand.

The module is proven at boot: the contract's `boot` self-check verifies
the order of 2 modulo 15, recovers 15 = 3 × 5, and detects a known cycle
before any transaction can run.

## 7. TIAMAT

TIAMAT is a NEP-141 fungible token whose contract **is** the settlement
contract. It has 24 decimals and a supply that exists only because it was
issued against a reserve.

**Issuance.** `voucher_mint` accepts a NEAR deposit and issues TIAMAT on a
golden-ratio curve: the backing required per new TIAMAT rises as
`φ^(21 · supply / cap)`, with a base of one NEAR. The whole deposit joins
the reserve. `tiamat_quote` returns the amount that a given deposit would
issue, before the transaction is sent.

**Redemption.** `voucher_redeem` burns TIAMAT for a pro-rata slice of the
whole reserve.

**No privileged issuance.** There is no admin mint, no premine and no key
that can create TIAMAT. The only path to new supply is a deposit, and the
deposit is public.

**Uses.** TIAMAT is the unit of settlement inside the contract (fees,
tribute, claims), the reserve asset, the pricing unit for verified compute
work, and a traded asset: TIAMAT/NEAR is live on Ref Finance, pool 8992.

## 8. Verification

Every claim in this paper can be checked without trusting its authors:

```
near account list-keys unog.near network-config mainnet now   # zero keys
near view unog.near status                                    # stage 2 LOCKED
near view unog.near abi_version                               # 214 descriptors
near view unog.near layers                                    # 12 layers, TRUE
near view unog.near ft_metadata                               # TIAMAT / PQOS / 24
near view unog.near ft_total_supply                           # the supply
near view unog.near tiamat_quote '{"value":"1000000000000000000000000"}'
```

Live proofs of the period module:

- order of 2 mod 15 → `TRUE, order 4`, tx `EkCfqYJsVZpTJfVseVNZbn539JFDsTr8NHopccWpw8JH`
- 15 = 3 × 5 from the period, tx `BZVtoC5UCeiBfcZTMURAFzH9tWXqKP63ivqFRAHkAgC5`

## 9. Economics

- **Supply:** 0.39 TIAMAT, entirely reserve-backed. Small by design: every
  unit requires NEAR behind it.
- **Reserve:** public, readable, and increased only by deposits.
- **Fees:** the contract charges for storage and fuel in NEAR; the
  Sovereign Tribute is 0.08889% of value paid out or cleared, split in
  equal thirds to three public-good accounts.
- **Liquidity:** pool 8992 on Ref Finance, 0.3% fee.

There is no yield promised, no emissions schedule and no staking reward.
Value comes from use, not from dilution.

## 10. Roadmap

1. **Satellite expansion** — new contracts for new capabilities, each
   pinned to the sealed core. The core is never edited.
2. **Deeper liquidity and listings** — more venues, registry submissions,
   independent price discovery.
3. **The omnichain bootstrap** — using period finding to load and verify
   external chain state windows without holding another chain's native
   token.
4. **Agent and compute economy** — pricing verified agent work in the same
   ledger.

## 11. Limits and risks

- **No certification.** Nothing here has been validated by NIST CMVP, ISO,
  EMVCo, SWIFT or any regulator.
- **Small scale.** The supply and the pool are deliberately small; the
  market is real but shallow.
- **Sealing cuts both ways.** A defect cannot be patched. It can only be
  superseded by a new satellite, and funds held by a defective sealed
  contract cannot be rescued by its authors.
- **Single-author concentration.** The architecture is the work of one
  principal author with AI assistance; Apache-2.0 licensing and public
  repositories are the mitigation.
- **Novel constructions need review.** The period module and the integer
  lattice are new; they have passed extensive automated testing but not
  independent cryptanalysis.

## 12. Conclusion

A contract that cannot be changed is a strange thing to build in an
industry that assumes everything can be upgraded. It is also the only kind
of contract whose promises can be checked rather than believed.

TIAMAT is issued by such a contract: exact in its arithmetic,
post-quantum in its verification, paraconsistent in its settlement, and
sealed in its code. It asks not to be trusted, but to be verified.

---

*Copyright (c) 2024–2026 Michael Laurence Curzi, 36N9 Genetics, LLC and
Scenic Bypass Consulting, LLC. SPDX-License-Identifier: Apache-2.0.*
