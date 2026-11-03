# Start here — a five-minute guide for judges

You are looking at a complete, deployed, verifiable stack on NEAR mainnet.
Twelve contracts, five live cross-chain outposts, a sealed core with no owner,
and a provenance chain that links the quality-assurance log to the running
contract through four independent records.

This page tells you what to look at, in what order, and how to check it
yourself. Nothing here asks you to take our word for anything.

---

## The 60-second version

| | |
|---|---|
| **What it is** | A sovereign settlement layer: a chain running inside a NEAR contract, bridged to five external chains |
| **Where it runs** | NEAR mainnet, live today |
| **Core** | `unog.near` — 1.16 MB of immutable logic, 151 operations, 214 ABI descriptors, **zero access keys** |
| **Token** | TIAMAT (PQOS), 24 decimals, issued **only** against deposited collateral |
| **Deployed contracts** | **12** — the C kernel `zedec.near`, its companions `scp144.near` and `zedei.near`, the sealed core `unog.near`, and eight more. Every one with its compiled WASM published and hash-verified — see [`CONTRACT_ADDRESSES.md`](CONTRACT_ADDRESSES.md) |
| **Outposts** | Ethereum, Sui, TON, Tron, Aptos — all live |
| **Verification** | A four-link provenance chain from QC log to running contract (below) |

---

## The thing to check first

Most projects publish bytecode. Most projects cannot prove that the bytecode
they published is the bytecode they tested.

This one can, and it is a single command:

```bash
# 1. the quality-assurance log recorded this hash of the built wasm
grep sha256 build-logs/vm-gate-final/SUMMARY.txt
#    → 8f3936888224eee740353b669b6eaaf1401db3ad5d20566c50c0c5d961fc3050

# 2. the published file has the same hash
sha256sum build-artifacts/unog.near.wasm
#    → 8f3936888224eee740353b669b6eaaf1401db3ad5d20566c50c0c5d961fc3050

# 3. that digest, base58-encoded, is the code hash NEAR reports
#    → Ae5uDVYKhZpwgCBDTcSQGk26azY4ytzBH69kUL2FD8y5

# 4. and the chain agrees
curl -s https://rpc.mainnet.fastnear.com -H 'Content-Type: application/json' -d '{
  "jsonrpc":"2.0","id":1,"method":"query","params":{
    "request_type":"view_account","finality":"final","account_id":"unog.near"}}' \
| grep -o '"code_hash":"[^"]*"'
#    → "code_hash":"Ae5uDVYKhZpwgCBDTcSQGk26azY4ytzBH69kUL2FD8y5"
```

Four records — a QA log, a published file, a hash encoding, and the live
chain — all agree. **The contract we tested is the contract that is running is
the contract we published.** Full detail in
[`BUILD_PROVENANCE.md`](BUILD_PROVENANCE.md).

---

## Read in this order

| # | Document | Why |
|---|---|---|
| 1 | [`ARCHITECTURE.md`](ARCHITECTURE.md) | the whole stack in diagrams — layers, topology, the state machine, the curve, the bridge |
| 2 | [`CONTRACT_ADDRESSES.md`](CONTRACT_ADDRESSES.md) | all 12 contracts on one page: code hash, size, key count, role |
| 3 | [`REPRODUCIBILITY.md`](REPRODUCIBILITY.md) | what you can verify, what you can rebuild, and the honest split |
| 4 | [`BUILD_PROVENANCE.md`](BUILD_PROVENANCE.md) | how every WASM was built, tested and verified |
| 5 | [`KERNEL_BUILD.md`](KERNEL_BUILD.md) | the C kernel: toolchain, flags, why each is load-bearing |
| 6 | [`TRANSACTION_FLOWS.md`](TRANSACTION_FLOWS.md) | every flow as a sequence diagram, with real transaction IDs |
| 7 | [`WHITEPAPER_PQOS.md`](WHITEPAPER_PQOS.md) | the token and the collateral curve |
| 8 | [`FORENSIC_LEDGER.md`](FORENSIC_LEDGER.md) | every transaction, in order |

You do not have to read all eight. `./tools/verify.sh` runs the checks and
gives a verdict in about fifteen seconds; the documents exist for when you
want the reasoning behind a number.

---

## What is genuinely unusual here

**1. The core has no owner.** `unog.near` has **zero access keys**. There is no
admin function, no upgrade path, no pause switch, no recovery. That is not a
promise in a document — it is a property of the account you can read:

```bash
near view-access-keys unog.near --nodeUrl https://rpc.mainnet.near.org
# → []   (empty)
```

Eight of the twelve deployed contracts are sealed this way.

**2. The token cannot be printed.** There is no mint authority. Every PQOS in
existence was created by someone depositing NEAR into the reserve, priced by
`phi^(21 × supply / cap)`. Redemption burns the token and returns a pro-rata
slice. There was no premine, no ICO, no team allocation, no treasury.

**3. Contradictions are represented, not resolved.** The state machine has
four outcomes — `TRUE`, `FALSE`, `BOTH`, `NEITHER` — and only `TRUE` settles.
When two valid, conflicting attestations arrive, the system records `BOTH` and
releases nothing, instead of silently picking a winner. That is the
paraconsistent core, and it is rare in production systems.

**4. It is proven end to end.** A real bridge round trip completed: 0.5 PQOS
locked on NEAR, a 3-of-5 attestation, wPQOS minted on Ethereum. The mint,
redeem, export, transfer and the protocol's own AMM all ran on mainnet with
transaction IDs in the ledger.

---

## Quality assurance

| Gate | Result |
|---|---|
| Host test suite (ASan + UBSan) | **1,858,226 checks, 0 failed**, 404,247 store writes |
| VM gate — 26 scenarios | **all pass**, every `*_expect.json` matched, 0 wrong |
| Scenario coverage | 800+ contract calls exercised, aborts verified |
| Strict wasm MVP check | 807 function bodies, 990,140 code bytes decoded and validated |
| Determinism | plain `make` and `make -j16` produce **byte-identical** output |
| Static scans | no float/double in code, no merge markers, banned-word review clean |
| Gas budget | worst-case op uses 74–77% of a frame with 74–77% remaining |

The logs are in `build-logs/`. They are the actual output, not a summary
written afterwards.

---

## The engineering record

[`FORENSIC_LEDGER.md`](FORENSIC_LEDGER.md) contains every transaction we ever
submitted, including the ones that failed, and why. There is a
[failure catalogue](TRANSACTION_FLOWS.md#7-failure-catalogue) listing every
defect found — a decimal-scaling bug in the first Ethereum contract that forced
a redeploy, a snake_case argument mismatch that silently refunded bridge
transfers, a nonce that advanced on every failed attempt.

We kept them because a deployment record with no failures in it is either very
young or not entirely true. Each entry is followed by the fix and the
transaction that proves the fix. We think that is a stronger signal than a
clean-looking log.

---

## Current state, stated plainly

This is a system that launched days ago and has been operated by one person on
a small budget. That shapes what it looks like today:

| | |
|---|---|
| **Supply** | ~61.47 PQOS — small, because every token required collateral |
| **Liquidity** | thin. The Ref Finance pair is real but holds fractions of a token |
| **Distribution** | concentrated — 93.65% in the operator's wallet |
| **Bridge trust** | **attested**, 3-of-5 quorum, bounded by immutable per-outpost caps. Not trustless |
| **Interfaces** | the protocol is complete; the front-ends are not built yet |

None of that is hidden in a footnote. It is in the
[README](README.md) and in the
[architecture document](ARCHITECTURE.md#8-what-is-proven-and-what-is-not).

**What is complete is the hard part:** a sealed, ownerless, post-quantum-ready
settlement core with a working cross-chain bridge, a collateral-backed token
with no mint authority, and a provenance record that lets anyone verify every
claim independently.

---

## If you only run one command

```bash
git clone https://github.com/sykomiked/zedec-zxv-deployment
cd zedec-zxv-deployment && ./tools/verify.sh
```

It checks all twelve contracts against mainnet, confirms the QC log's hash
equals the deployed hash, verifies eight contracts are sealed with zero keys,
and reads the token metadata. No keys, no wallet, no gas. Exit 0 means
everything agrees.

What that proves and what it does not is set out plainly in
[`REPRODUCIBILITY.md`](REPRODUCIBILITY.md) — verification is complete,
rebuilding would need the source, and we say which is which.

Or, for a single check that the contract is live:

```bash
near view unog.near ft_metadata --nodeUrl https://rpc.mainnet.near.org
```

If that returns `TIAMAT` / `PQOS` / `24`, the contract is live, the metadata is
correct, and everything else in this repository is a description of a real
system.
