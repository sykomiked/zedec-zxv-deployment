# GRIDCHAIN / TIAMAT — forensic deployment record

Internal record. 2026-11-01. Every hash below was read from the chain or
computed from the deployed artefact; every transaction is public.

---

## 1. Deployed components

### 1.1 The sealed core

| | |
|---|---|
| Account | **`unog.near`** |
| Code hash | `Ae5uDVYKhZpwgCBDTcSQGk26azY4ytzBH69kUL2FD8y5` |
| Artefact SHA-256 | `8f3936888224eee740353b669b6eaaf1401db3ad5d20566c50c0c5d961fc3050` |
| Access keys | **0 — sealed, immutable** |
| Stage | LOCKED |
| Storage / balance | 1,191,700 B · 63.98 NEAR (11.57 staked for the wasm) |
| Layers | 12 booted + active, grade TRUE |
| ABI | 214 descriptors · 151 ops |

### 1.2 Bridge satellite — RouteLock

| | |
|---|---|
| Account | **`chiglet.unog.near`** |
| Code hash (current) | `Hro4CWX7mshPouPr8CzBLHqqB8RR92MoSLoScYq6htMv` |
| Superseded | `Cd6wDohtEvsHkxxjHi2TV72b8zg2T4Laum2BYUKaTd5C` (camelCase defect) |
| Redeploy tx | `9J9oM6Rx4Fx7XUWAunGyDTU7CcoF7HN8g9Tk8rzU4zLv` |
| State | `pqos` = unog.near · `chain_tag` = the core's · 3-of-5 · 0 locks |
| Storage / balance | 334,802 B · 4.79 NEAR |

### 1.3 Mint desk and redemption kiosk

| | |
|---|---|
| Account | **`post.jollydragonroger.near`** |
| Code hash (current) | `7z6gj4zjw6YEii4EQej9w4SZ8iScvsjgU7QY7KkqtQ7Z` |
| Superseded | `Fsovv4Mw8p1otCpk2KTogY2UBm78h9QKEu4SH7p5GSWa` (camelCase defect) |
| Gridchain id | `cecf95980687a5faa277ebe40e9d311527650402e2744ac457fce30e9aa59307` |
| State | `stats` `[1, 2, 0, 0, false]` — one mint, two redeems, none pending |
| Storage / balance | 250,515 B · 6.25 NEAR |

### 1.4 Outposts

| Chain | Receive address | Contract |
|---|---|---|
| **Ethereum** | `0xcB5AA2F26b4751279649c8b217D143D6781F2179` | `0xAd55800116817E3A0884B514BAb508aFd9e95142` |
| **Sui** | `0xcec7ff110ae7f8f1478f62ed8995cc8cb4fd04aca03392bf13b36214ae74047b` | package `0x9953147df1732aa900a3ad0f2580e2fc256a727b861ba96e2acc73e4beb2bdae` |
| **TON** | `UQCJqL-7Q20RrKOMSIUFcHXHN76LzjrxQYGBtAfBJ3MP5Zj9` | same (routing controller) |
| **Tron** | `TNfKQqj4vqPy3ma5chxkwqmuhPjNjMJKxP` | `TCDYovDaXZQsgbxDCcprFpyw2tR2ZYweF6` |

All four carry `chainTag` = `db4d954a964be12303a7f6d2bc833e61a3c5deabc75a304eda57e2063485282e`
(the core's), an immutable supply cap and a 3-of-5 attested quorum.

The Ethereum contract is **verified on Sourcify, `exact_match`** (creation and
runtime): https://repo.sourcify.dev/contracts/full_match/1/0xAd55800116817E3A0884B514BAb508aFd9e95142/

## 2. Transaction ledger

### 2.1 Core deployment

| Step | Transaction |
|---|---|
| deploy `gridchain.wasm` | `5uG2pyf9gVBMKxiL757CKTQm6T46LCEeZQZgPCSo98e8` |
| `new` | `6Hbm7CTNXbFRZS8jPVVLwXtcYT1bwkrMP4LDb6rzaaAF` |
| `activate` | `2stuyFfx29R7fWJ5TuvP89EdXqe1LNMGZJmQsaNcfiSY` |
| `qc_lock` | `3rhV3iuso3ALbw76tAi7FnWjnZ9D22tr2xvU7QzCF4cF` |
| last key deleted | `CsY4CuPsnxbKiWBQTSFYpT85upxoxptwxtXijBU2p9in` |

### 2.2 Outpost deployment

| Chain | Transaction | Cost |
|---|---|---|
| Ethereum (buggy, deprecated) | `0x9f1efde36ea4dc34dc926eeacf620187c74118d83a1ef014cd9e9d2c43ec9803` | $0.121 |
| **Ethereum (live)** | `0x506bca7a480cae9b3407aca6136ee2bcfbcd8dba44229503825e079ad00b9297` | $0.137 |
| Sui | `9FqEuZ79NT15s79ziKQLfRVhccb84tRTmCk68qP145he` | 0.028 SUI |
| TON | Tact `system-cell` deploy, address `UQCJqL-7Q2…Zj9` | 0.15 TON |
| Tron | `TCDYovDaXZ…` (after `OUT_OF_ENERGY` retry) | 155 TRX energy |

### 2.3 First end-to-end mint

| Step | Transaction |
|---|---|
| user sends 0.1 NEAR to `mint()` | `3PdcLSG7kAC4MYnzWx9wxPeCXq5Mhckp6fryum3PguE2` |
| relayer mints 0.095 TIAMAT | `7VDUjE1VyhXSepFENDQCveNKimsBDGa4WYrWPFV4ccjz` |
| relayer exports 0.094 to user | `94pVg2tHhZfVUbwgK5AwCwFt6wDMqgEDuzS18WypWxNg` |
| book closed | `Aa7tnzhk8EhNM5cf141baWv9zkgaxxpd3nFH5J4awXYv` |

### 2.4 First end-to-end redeem

| Step | Transaction |
|---|---|
| user sends 0.01 TIAMAT to the desk | `5xeKBmFyYvY4gkwVUfo6tKS8hquXBWRbs6hLPgbs7PkZ` |
| import to the gridchain account | desk NEP-141 balance -> `"0"` |
| burn + withdraw | via the relayer |
| payout | `8hY5JST2oyPdmL94H1LrGN7xFTkr3aef7o6CcFo3ZRw3` |
| book closed | `3Sm9WtX4cyNr2J4mQZkxTABGJk6gVGXZVmnc16FuD9dL` |

## 3. Key custody

| Key | Location | Policy |
|---|---|---|
| Core | none — sealed | unrecoverable by design |
| Outpost keys (6) | `outposts/*.json`, mode 600 | **hot**, live |
| Attestors (secp256k1, 5) | `outposts/attestors/attestors.json` | hot |
| Attestors (ed25519, 5) | `outposts/attestors/attestors-ed25519.json` | hot |
| Desk gridchain key | `outposts/desk/desk-gridchain-key.json` | hot |
| **`chiglet.unog.near`** | **macOS Keychain**, service `near-mainnet-chiglet.unog.near` | hot — **the ledger file cannot sign; Keychain is authoritative** |
| `post.jollydragonroger.near` | `pq-keys/post.jollydragonroger.near__ml-dsa-65.json` | hot |

## 4. Audit findings this session

1. **EVM contract had no scale factor** — tickets carry 24-decimal NEAR units,
   the contract minted them as 18-decimal. Caught before any mint; superseded
   at a cost of $0.137.
2. **near-sdk 5.30 imports protocol features mainnet does not expose**
   (`use_global_contract`, `universal_state_init`, gas keys) -> `Link Error`.
   Pinned `=5.6.0`.
3. **`env::ed25519_verify` no longer exists** in the runtime; moved to
   `ed25519-dalek` in pure Rust.
4. **near-sdk 5's `#[near]` renames arguments to camelCase**, but the sealed
   core calls `ft_on_transfer` in snake_case. The transfer failed and the core
   **refunded silently**. Fixed with `#[near_bindgen]` on both the desk and
   the bridge.
5. **`near contract deploy` keeps storage.** A state written by an earlier
   build cannot be read by a newer one; redeploying does not repair it. The
   fix is an `#[init(ignore_state)]` migration.
6. **Tron caps a transaction's energy by its `feeLimit`**, not by the
   delegated energy. A 100 TRX fee limit gave 1.0M energy against 1.7M
   delegated and failed with `OUT_OF_ENERGY`, burning 10.24 TRX.
7. **A mint spends the amount AND pays a fee AND pays storage** — the deposit
   cannot equal the mint amount. Working buffer 0.005 NEAR.

## 5. What is proven, and what is not

**Proven on mainnet:**
- sealed core, 12 layers active, immutable
- four outposts deployed and bound to the core's chain tag
- mint: NEAR -> TIAMAT, end to end
- redeem: TIAMAT -> NEAR, end to end

**Not proven:**
- the bridge round trip (lock -> attest -> mint wPQOS) has never executed
- every outpost's wrapped supply is **0**
- no DEX pool exists on any chain
- no registry listing has been submitted except Sourcify verification

## 6. Registry status

| Registry | Status |
|---|---|
| **Sourcify** (Ethereum) | **verified, exact_match** |
| CoinGecko | submission package prepared, not submitted |
| DEX listings (Rhea, Uniswap, SunSwap, Cetus, STON.fi) | **blocked** — no wrapped supply to pool |
| Nearblocks / DexScreener / GeckoTerminal | automatic; nothing to index yet |

## 7. Honest summary

Nine contracts exist: one sealed core, one bridge, one desk and four outposts,
plus the superseded builds. Two of them move value in both directions and are
proven. The cross-chain bridge has never carried a single token, and every
statement about liquidity or listings must remain aspirational until it does.

The capital spent on infrastructure was **$0.29 on Ethereum, 0.028 SUI,
0.15 TON and 155 TRX** — everything else is untouched and available for the
first real bridge round trip.
