# ZEDEC / ZXV — sovereign operating system and Web4 settlement layer

Deployed end-to-end on NEAR mainnet. Every claim in this repository is a
transaction hash, a code hash read from the chain, or a file in this repo.

---

## One-paragraph summary (NEAR Builders application)

> ZEDEC/ZXV is a sovereign, vertically integrated operating system and Web4
> settlement layer, deployed end-to-end on NEAR mainnet. The sealed kernel
> (`zedec.near`), post-quantum security module (`scp144.near`) and automation
> layer (`zedei.near`) underpin the platform launch at `unog.near`: a
> paraconsistent four-valued chain whose 151 operations, 214 ABI descriptors
> and 46 governance kinds are immutable, keyless and booted across 12 active
> layers. GRIDCHAIN/TIAMAT (PQOS) issues against NEAR collateral on a rising
> phi curve, with a one-call mint/redeem desk (`post.jollydragonroger.near`),
> an attested 3-of-5 bridge (`chiglet.unog.near`) charging 8.889 bps, and five
> live outposts: Ethereum (Sourcify exact-match), Sui, TON, Tron and Aptos.
> Every mint, lock, attestation and cross-chain transfer is a public
> transaction recorded in a forensic ledger. Attested, capped and auditable —
> not trustless, and we say so.

---

## The stack

| Layer | Account | Code hash | Role |
|---|---|---|---|
| **Kernel** | `zedec.near` | `ATUV46Keb91L32RGU5X858nNtTZ6csH9HARfE86MtMo` | the operating system |
| **Post-quantum security** | `scp144.near` | `DDQ4uJXM26WhRoYfRPgQcUKPybzhGrBXmCbK7e85dmN9` | SCP-144 lattice, ML-DSA / ML-KEM |
| **Automation** | `zedei.near` | `CRZgm89Yo8JsU6WgFjFmkrU8BRDZfMvieKQ2hozDLwjZ` | the automation layer |
| **Platform** | `unog.near` | `Ae5uDVYKhZpwgCBDTcSQGk26azY4ytzBH69kUL2FD8y5` | GRIDCHAIN / TIAMAT core — **sealed** |
| **Bridge satellite** | `chiglet.unog.near` | `DRq7Th7tfKdeZUMB4TsQVe23vELNiNnBc8qgpxhvW91h` | RouteLock, 3-of-5 attested |
| **Mint desk / kiosk** | `post.jollydragonroger.near` | `7z6gj4zjw6YEii4EQej9w4SZ8iScvsjgU7QY7KkqtQ7Z` | one-call mint and redeem |

**The core is sealed:** zero access keys, code hash immutable, 12 layers booted
and active with grade `TRUE`.

### Every deployed contract — twelve accounts

The six above plus six more, all hash-verified and all with published
bytecode. Full detail in [`CONTRACT_ADDRESSES.md`](CONTRACT_ADDRESSES.md).

| Account | Role | Code hash | Keys |
|---|---|---|---|
| `mission.unog.near` | ENVOY — jobs, bounties, the Mobius loop | `49rYaA4vZ2kyvvf7SY29ZqXasvDKYapiekRYXKkTUjRW` | **0** |
| `chancery.unog.near` | REGISTRAR — attestation tallies | `EUfXZxyK6nGy3VwD1oQLymiYcTM687L2j4recUDqg3YN` | **0** |
| `consulate.unog.near` | TRANSIT — the routes | `9JHAd3FRn56rhFzZuM4phMW6Kx1VRw2h5GDxMjgzeKPi` | **0** |
| `protocol.unog.near` | PROTOCOL — governance kernel | `Eg5SgH23zwstY4GDwGJHyCn752TJwCw15cLQ24ZwQJeo` | **0** |
| `36n9.zedei.near` | interface kernel, operator build | `3H4dqcbN2TEkrgsSWFEMovVWGhvVgatqUuGKLP5ji5US` | 1 |
| `outpost.jollydragonroger.near` | desk outpost (same binary as `zedei.near`) | `CRZgm89Yo8JsU6WgFjFmkrU8BRDZfMvieKQ2hozDLwjZ` | 1 |

**Seven of twelve are sealed with zero access keys** — no admin, no upgrade,
no recovery. The four with one key each hold operational keys for the relayer
and desk, disclosed rather than hidden.

## Outposts

| Chain | Address | Notes |
|---|---|---|
| **Ethereum** | `0xAd55800116817E3A0884B514BAb508aFd9e95142` | verified **Sourcify exact_match**; bridge round trip proven |
| **Sui** | package `0x9953147df1732aa900a3ad0f2580e2fc256a727b861ba96e2acc73e4beb2bdae` | immutable |
| **TON** | `UQCJqL-7Q20RrKOMSIUFcHXHN76LzjrxQYGBtAfBJ3MP5Zj9` | Tact routing controller |
| **Tron** | `TCDYovDaXZQsgbxDCcprFpyw2tR2ZYweF6` | same audited bytecode as Ethereum |
| **Aptos** | `0xd82e10769f6b4280d45a13246ca1cfb66902de30702246e2014b195ddfd197b6::wrapped_pqos` | Move |
| **Starknet** | account `0x06b0e99e5aa8c0aadbec9d659ab23d1f4adae2c6d3cdc5497e4744ac1c7dfb6e` | deployed, funded |
| **Cardano** | validator hash `71c99ba5a9e791c2071b48622d1cd1925836745bf025281b3986ee76` | builds; awaiting ADA |
| **Cosmos** | CosmWasm 296 KB wasm | builds; awaiting OSMO on Osmosis |
| **Tezos** | hand-written Michelson | authored; client via Docker |

## What is proven, and what is not

**Proven on mainnet:** the sealed core; five live outposts; mint
(NEAR → TIAMAT); redeem (TIAMAT → NEAR); a complete bridge round trip
(lock → 3-of-5 attest → mint on Ethereum); the protocol's own AMM
(pool create / add / swap); transfer; export.

**Not yet:** most outpost pools have no depth; only the NEAR venues are
seeded. This repository states that plainly rather than listing empty markets.

## Repository contents

| File | Contents |
|---|---|
| **`JUDGES_START_HERE.md`** | **a five-minute guide for reviewers** — what to check, in what order, and the one command that proves the build |
| **`REPRODUCIBILITY.md`** | **what you can and cannot reproduce** — verification is complete, rebuilding needs the source; the honest split |
| **`tools/verify.sh`** | **one command** — checks all 12 contracts against mainnet, no keys, no gas |
| **`build.sh`** | the pinned build procedure for the core and the satellites |
| **`KERNEL_BUILD.md`** | the C kernel: toolchain, flags, why each one is load-bearing |
| **`ARCHITECTURE.md`** | **the whole stack, with diagrams** — layers, topology, storage keys, the four-valued machine, the curve, the bridge, the AMM |
| **`TRANSACTION_FLOWS.md`** | **every flow as a sequence diagram**, plus a catalogue of every failure mode and its fix |
| **`CONTRACT_ADDRESSES.md`** | **all twelve deployed contracts** — code hash, size, balance, key count, role, and how to verify each |
| **`BUILD_PROVENANCE.md`** | **how every WASM was built, tested and verified** — the four-link chain from QC log to live chain |
| **`build-artifacts/`** | **the compiled WASM of every deployed contract**, pulled from chain and hash-verified, with `SHA256SUMS` |
| **`build-artifacts/`** | **compilation artefacts** — the LTO intermediate, the linker resolution map, and a local build that matches mainnet byte-for-byte |
| **`build-logs/`** | **the actual build and QC output** — host suite, VM gate, deployment transcript |
| **`BUILD_REPRODUCIBILITY.md`** | toolchain, flags, determinism checks and the build scripts |
| **`FRONTEND_BUILDERS.md`** | what we need built, the five call shapes, and the fee you may charge |
| **`COMMUNITY_UPDATE.md`** | the ≤1,000-character post and the ≤140-character tagline |
| `FORENSIC_LEDGER.md` | every transaction, in order, with outcomes |
| `FORENSIC_DEPLOYMENT_RECORD.md` | consolidated deployment record and audit findings |
| `outposts/SYSTEM_AUDIT.md` | full system audit |
| `outposts/FEE_AND_ARBITRAGE_ECONOMICS.md` | the 8.889 bps model and why it is that number |
| `outposts/ROUTING_PROTOCOL.md` | GRIDCHAIN Route Protocol v1 |
| `outposts/CAPITAL_REQUIREMENTS.md` | per-chain costs, verified and estimated |
| `outposts/registry/gridchain.registry.json` | machine-readable endpoints for bots |
| `outposts/registry/DISCOVERY.md` | human-readable how-to |
| `WHITEPAPER_PQOS.md` | the token and the curve |
| `QC_SUMMARY.md` | 1.86M checks, 0 failed |
| `COINGECKO_SUPPLY_AND_DISTRIBUTION.md` | supply, distribution schedule, holder data |
| `COINGECKO_CATEGORIES_AND_INFO.md` | categories and the 24-vs-18 decimal disclosure |

## Front-end developers wanted

The protocol is finished. The interfaces are not.

Everything is documented, the bytecode is public, and there is no gate to
pass — the core has no owner to ask. **You may charge a fair, minimal fee out
of the transaction flow for your work.** We will not complain, and the
protocol cannot revoke you.

Start with [`FRONTEND_BUILDERS.md`](FRONTEND_BUILDERS.md). It lists the six
interfaces we need, the five call shapes that cover them, and how to take a
fee honestly.

## Trust model — read this first

**Attested, not trustless.** A 3-of-5 quorum signs every cross-chain mint. Each
outpost carries an immutable supply cap that bounds what a compromised quorum
could create. The core cannot be edited; it can only be superseded by a new
satellite.

Anyone claiming this is trustless is lying, including us.

## Licence

Apache-2.0.
