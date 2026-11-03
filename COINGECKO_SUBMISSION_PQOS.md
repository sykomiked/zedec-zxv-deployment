# CoinGecko submission — TIAMAT (PQOS)

Ready to paste into the CoinGecko request form. Every on-chain fact was read
from NEAR mainnet at the time of writing; the command that reproduces it is
given at the end.

---

## 1. What is the project about? *

TIAMAT (ticker PQOS) is the token of GRIDCHAIN, a twelve-layer settlement contract deployed on NEAR mainnet at unog.near and sealed on the day of its deployment with zero access keys. The contract is public financial infrastructure rather than an application: it verifies post-quantum signatures (ML-DSA-87 and SLH-DSA-SHAKE-256s) inside ordinary WebAssembly, keeps every monetary value in exact integer or rational arithmetic so no floating point ever touches money, settles through a four-valued paraconsistent logic in which only TRUE can release value, and carries a period-finding module that verifies Shor-style order results and recovers the factors they imply. TIAMAT is issued only against a NEAR reserve on a deterministic golden-ratio curve, with no admin mint, no premine and no privileged key.

## 2. What makes your project unique?

Five things distinguish it. First, the contract is sealed and provably so: zero access keys, stage LOCKED, and the code hash Ae5uDVYKhZpwgCBDTcSQGk26azY4ytzBH69kUL2FD8y5 is the base58 of the published artefact's SHA-256, so nobody, including the author, can change the code or a parameter. Second, post-quantum verification runs inside the contract itself rather than in a host function: ML-DSA-87 (FIPS 204) and SLH-DSA-SHAKE-256s (FIPS 205) verify in userland Wasm at about 7.4 and 53.6 Tgas. Third, arithmetic is exact end to end, so IBM Z COBOL COMP-3, EBCDIC, zoned decimal, FORTRAN and ISO 20022 data convert without rounding drift. Fourth, settlement is paraconsistent: contradictions are recorded as BOTH and held, never resolved by last-writer-wins, by majority or by a panic. Fifth, a period-finding module verifies orders and recovers factors, so a broken legacy modulus can be proven rather than merely suspected.

## 3. History of your project?

The project began as a freestanding C11 operating-system kernel (ZXV) cross-compiled for six machine targets: x86-64, AArch64, RISC-V 64, RISC-V 32, ARMv7 and WebAssembly. NEAR is one of those compilation targets, and the contracts are satellites fused to the kernel by pinned code hashes. Through 2024 and 2025 the work built the exact-arithmetic core, the post-quantum suites, the four-valued logic and the 144-dimensional integer construction. In October 2026 twelve independently developed lanes were assembled into one contract, which passed 1,858,226 automated checks and a byte-identical release build. On 1 November 2026 it was deployed at unog.near, activated, locked and sealed with zero keys; TIAMAT was minted on the curve and a TIAMAT/NEAR pool opened on Ref Finance the same day.

## 4. What's next for your project?

The sealed contract is the foundation, and growth happens through satellite contracts and integrations rather than edits. The immediate plan is to expand the deployed infrastructure with new satellite contracts for new capabilities, such as further post-quantum schemes, more legacy-finance adapters and additional verification lanes, each pinned to the sealed core by code hash. Alongside that, PQOS expands: deeper reserve-backed issuance on the curve, deeper liquidity across NEAR venues, and listings in the registries that make the token discoverable. The period-finding module is also intended as the state-loading primitive for reading and verifying other chains' state windows, so interoperability does not require holding another chain's native token.

## 5. What can your coin/token be used for?

TIAMAT is the unit of the contract's economy. It pays settlement fees, tribute and claims inside GRIDCHAIN; it is the reserve asset, minted against NEAR on a deterministic curve and redeemed for a pro-rata slice of the reserve through voucher_mint, voucher_redeem and the tiamat_quote view; it prices verified compute work in the compute lanes and escrows rewards in the work marketplace; and it trades against NEAR in Ref Finance pool 8992. Because the token contract is the settlement contract, holding TIAMAT is holding a claim on the same sealed ledger that performs the verification, rather than on a separate wrapper contract that merely points at one.

---

## Background for reviewers (not for the form)

**The contract.** Twelve layers (L2 to L13) plus a fourteenth partition, User Space, which sits beside the
layers as a socket rather than a gear. 214 ABI descriptors, 165 operations, 46 governance bodies. Deployed
artefact 1,156,670 bytes, strict WebAssembly MVP. Zero access keys, stage LOCKED.

**The build.** 1,858,226 checks with AddressSanitizer and UndefinedBehaviorSanitizer enabled; a VM gate of 26
scenarios; a release build that is byte-identical between serial and parallel compilation; no floating point in
any money path.

**The four values.** `NEITHER` (0), `TRUE` (1), `FALSE` (2), `BOTH` (3), ordered `FALSE < NEITHER < BOTH <
TRUE`, with meet and join as the minimum and maximum on that chain. No combination of non-TRUE values can
produce TRUE.

**Live proofs.** Order of 2 mod 15 = 4 (`EkCfqYJsVZpTJfVseVNZbn539JFDsTr8NHopccWpw8JH`); 15 = 3 x 5 from the
period (`BZVtoC5UCeiBfcZTMURAFzH9tWXqKP63ivqFRAHkAgC5`); deployment
(`5uG2pyf9gVBMKxiL757CKTQm6T46LCEeZQZgPCSo98e8`).

## Trading Pair #1

| Field | Value |
|---|---|
| **Exchange Name** | **Rhea Finance** (CoinGecko exchange id `ref_finance`) |
| **Trading Pair** | **`UNOG.NEAR/WRAP.NEAR`** |
| **Exchange Trade URL** | **https://app.rhea.finance/** |
| Pair page (human) | https://app.rhea.finance/pool/8992 |
| Pool id | 8992 (simple pool, 0.3% fee) |
| Exchange contract | `v2.ref-finance.near` |

### Why these exact values

CoinGecko already tracks this exchange (id `ref_finance`, displayed as
"Rhea Finance"), and its ticker records for it use a specific format, read
live from `api.coingecko.com/api/v3/exchanges/ref_finance/tickers`:

- **Pair format:** `<BASE_CONTRACT_ID>/<TARGET_CONTRACT_ID>`, uppercased. For
  example `USDT.TETHER-TOKEN.NEAR/WRAP.NEAR` and
  `TOKEN.RHEALAB.NEAR/WRAP.NEAR`. The NEAR side is `WRAP.NEAR` in 59 of the
  100 recorded pairs. Our pair is therefore **`UNOG.NEAR/WRAP.NEAR`**.
- **Trade URL format:** every one of the 100 recorded pairs uses the same
  value, **`https://app.rhea.finance/`** — this DEX does not use per-pair
  URLs in CoinGecko's records.

### On-chain proof the pair exists

```
near view v2.ref-finance.near get_pool '{"pool_id":8992}'
# {"pool_kind":"SIMPLE_POOL","token_account_ids":["unog.near","wrap.near"],
#  "amounts":["181867782122557063017182","220000000000000000000000"],
#  "total_fee":30,"shares_total_supply":"1000027278307053270321362"}
```

```
near view unog.near ft_metadata '{}'
# {"spec":"ft-1.0.0","name":"TIAMAT","symbol":"PQOS","decimals":24}
```

The pair has traded: swap `6DgsX1qyJHESjGTekRfqnTkWtuq2PBawGpRFFSezXTLK`
(0.02 wNEAR in, 0.0181 TIAMAT out), which is what makes a price exist.

## Explorer links (5)

1. https://nearblocks.io/address/unog.near
2. https://explorer.near.org/accounts/unog.near
3. https://nearblocks.io/txns/5uG2pyf9gVBMKxiL757CKTQm6T46LCEeZQZgPCSo98e8
4. https://explorer.near.org/transactions/5uG2pyf9gVBMKxiL757CKTQm6T46LCEeZQZgPCSo98e8
5. https://near.social/#/jollydragonroger.near/widget/Post?item=jollydragonroger.near/post/main

## Token classification

| Field | Value |
|---|---|
| **Coin or token?** | **Token** (NEP-141 fungible token on NEAR) |
| **Blockchain Platform (1)** | **NEAR Protocol** |
| **Contract Address (1)** | **`unog.near`** |
| **Contract hash (base58, on-chain `code_hash`)** | **`Ae5uDVYKhZpwgCBDTcSQGk26azY4ytzBH69kUL2FD8y5`** |
| **Contract hash (hex, = wasm SHA-256)** | **`8f3936888224eee740353b669b6eaaf1401db3ad5d20566c50c0c5d961fc3050`** |
| **Contract Decimal Places (1)** | **24** |
| Total supply | 0.39 TIAMAT (`389999999999612924160593` base units) |
| Symbol | PQOS |
| Name | TIAMAT |

---

## Verification commands

```
curl -s https://rpc.mainnet.fastnear.com -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"query","params":{"request_type":"call_function","finality":"final","account_id":"unog.near","method_name":"ft_metadata","args_base64":"e30="}}'

curl -s https://rpc.mainnet.fastnear.com -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"query","params":{"request_type":"call_function","finality":"final","account_id":"unog.near","method_name":"ft_total_supply","args_base64":"e30="}}'

near account list-keys unog.near network-config mainnet now   # 0 keys
near view unog.near status                                    # stage 2 LOCKED
near view unog.near abi_version                               # 214 descriptors
```

## Token or coin? The answer is: **token**, and here is why

CoinGecko asks this, and the honest answer is **token**, not coin.

- A **coin** is the native asset of a blockchain: BTC on Bitcoin, ETH on
  Ethereum, NEAR on NEAR. It exists because the chain exists.
- A **token** is an asset issued by a contract that runs on someone else's
  blockchain: an ERC-20 on Ethereum, a NEP-141 on NEAR.

TIAMAT is a **NEP-141 contract at `unog.near` on NEAR**. It has no
blockchain of its own; its rules live in a contract that runs on NEAR and is
executed by NEAR validators. That makes it a token.

The nuance worth stating: TIAMAT is the economic unit of **GRIDCHAIN**, a
twelve-layer settlement system that behaves like an operating system but
runs as a contract. If GRIDCHAIN ever runs its own chain, TIAMAT would
become that chain's coin. **Today it is a token**, and the form should say
so. Calling it a coin before it has a chain would be a false statement to a
reviewer.

## Tokenomics disclosure (required reading for the reviewer)

**Minting is permissionless. Anyone can mint TIAMAT.**

There is no admin mint, no premine, no allowlist, no KYC gate and no
privileged key. Any account may deposit NEAR into `unog.near` and receive
TIAMAT issued by the contract's golden-ratio curve, at the same price
available to everyone else:

```
near call unog.near deposit '{"to":"<gridchain id>"}' --deposit <NEAR>
# then voucher_mint (OP 5) from that gridchain account
```

Consequences a reviewer should weigh:

1. **Supply is not capped by policy, only by demand.** Every unit in
   existence was bought with NEAR that sits in the reserve. The contract
   cannot mint without a deposit. At the time of writing the reserve holds
   **~51.17 NEAR** against a supply of **50.39 TIAMAT** — about **1.015 NEAR
   of backing per TIAMAT**, i.e. fully backed and slightly over.
2. **There is no insider allocation to disclose.** The authors hold no
   privileged position; whatever they hold was minted on the same curve.
3. **The price rises with supply, not with time.** Backing per new TIAMAT
   is `phi^(21 x supply / cap)` NEAR, so early minters pay less and later
   minters pay more. That is the whole of the incentive design.
4. **Redemption is symmetric.** `voucher_redeem` burns TIAMAT for a
   pro-rata slice of the reserve; supply can fall.
5. **The contract is sealed**, so this policy cannot be changed later,
   including by its authors. There is no governance switch that could
   introduce a mint.

## Honest notes for the reviewer

- The supply is deliberately small (0.39 TIAMAT) because every unit is
  reserve-backed; a larger supply requires a larger reserve.
- The pool is live but small. It is a real market, not a deep one.
- No certification, audit firm or listing has been obtained. Nothing in
  this package claims otherwise.

## Token icon

| | |
|---|---|
| Icon | 256x256 palette PNG, 16,203 bytes |
| sha256 | `cdd594893ee9c9096cf2f734087051c0f60dc44676c4c23b13de30817248e8ed` |
| IPFS | https://ipfs.filebase.io/ipfs/QmZ4u1vfm62QXUMMrc1AvWgvwnV9DS4roUkSzwYYJjfUdf |
| On-chain copy | GRIDCHAIN User Space slots 0-15 of the contract; the reassembled bytes hash to the same sha256 |
| NFT | `tiamat:1` on `unog.near` (NEP-171), minted to `jollydragonroger.near` |

## Website and white paper (IPFS)

| Item | CID | Gateway URL |
|---|---|---|
| Website (one page, self-contained) | `QmQxBKYceFJK19VjMDurB2zFzi96R5sXYsXGGDeWDgCAt3` | https://ipfs.filebase.io/ipfs/QmQxBKYceFJK19VjMDurB2zFzi96R5sXYsXGGDeWDgCAt3 |
| White paper (HTML) | `QmSJd1j1opsZhN6TxCuZJG4LS3VtbdAYNrPkAsyQT2DBFB` | https://ipfs.filebase.io/ipfs/QmSJd1j1opsZhN6TxCuZJG4LS3VtbdAYNrPkAsyQT2DBFB |

Pinned on Filebase (bucket `zxv`); the CID is the SHA-256-addressed content
hash, so the gateway URL and `ipfs://` URI name the same bytes.
