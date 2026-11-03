# Architecture

The system is one vertical stack: a sealed chain running inside a NEAR
contract, wrapped in satellites, bridged to five external chains, with every
layer addressable and every byte published.

---

## 1. The stack

```mermaid
graph TB
    subgraph L5["APPLICATION — front-ends, bots, routers"]
        UI["Mint desk UI"]
        BOT["Arbitrage bots"]
        DASH["Dashboards"]
    end

    subgraph L4["SETTLEMENT — unog.near, sealed, 0 keys"]
        CORE["GRIDCHAIN core<br/>151 ops · 214 ABI descriptors<br/>46 governance kinds · 12 booted layers"]
        AMM["Internal AMM<br/>create · add · swap · remove"]
        STORE["Content-addressed store"]
        GOV["Governance"]
    end

    subgraph L3["SATELLITES — bounded, hash-pinned"]
        BR["chiglet.unog.near<br/>RouteLock bridge"]
        DESK["post.jollydragonroger.near<br/>MintDesk / redemption"]
        ENV["mission.unog.near<br/>ENVOY"]
        REG["chancery.unog.near<br/>REGISTRAR"]
        TRN["consulate.unog.near<br/>TRANSIT"]
        PRT["protocol.unog.near<br/>PROTOCOL"]
    end

    subgraph L2["PLATFORM — NEAR mainnet"]
        K["zedec.near<br/>kernel"]
        PQ["scp144.near<br/>post-quantum engine"]
        IF["zedei.near<br/>interface / automation"]
    end

    subgraph L1["OUTPOSTS — 5 live, each cap-bounded"]
        ETH["Ethereum<br/>wPQOS"]
        SUI["Sui<br/>wrapped_pqos"]
        TON["TON<br/>wPQOS"]
        TRX["Tron<br/>wPQOS"]
        APT["Aptos<br/>wrapped_pqos"]
    end

    UI --> DESK
    BOT --> CORE
    DASH --> CORE
    DESK --> CORE
    BR --> CORE
    CORE --> AMM
    CORE --> STORE
    CORE --> GOV
    CORE -.->|hash-pinned| BR
    CORE -.->|hash-pinned| DESK
    CORE -.->|hash-pinned| ENV
    CORE -.->|hash-pinned| REG
    CORE -.->|hash-pinned| TRN
    CORE -.->|hash-pinned| PRT
    K --> CORE
    PQ --> CORE
    IF --> CORE
    BR ==>|3-of-5 attestation| ETH
    BR ==> SUI
    BR ==> TON
    BR ==> TRX
    BR ==> APT

    style CORE fill:#1a1a2e,stroke:#e94560,stroke-width:3px,color:#fff
    style BR fill:#16213e,stroke:#0f3460,stroke-width:2px,color:#fff
    style DESK fill:#16213e,stroke:#0f3460,stroke-width:2px,color:#fff
    style K fill:#0f3460,stroke:#533483,stroke-width:2px,color:#fff
    style PQ fill:#0f3460,stroke:#533483,stroke-width:2px,color:#fff
    style IF fill:#0f3460,stroke:#533483,stroke-width:2px,color:#fff
```

**ASCII fallback**, for terminals and print:

```
   APPLICATION      mint UI        arbitrage bots      dashboards
                       |                  |                 |
                       v                  v                 v
   SETTLEMENT     +----------------------------------------------+
   unog.near      |  GRIDCHAIN core - SEALED - ZERO ACCESS KEYS   |
   (1,156,670 B)  |  151 ops | 214 ABI | 46 governance | 12 layers|
                  |  internal AMM | content store | governance    |
                  +----------------------------------------------+
                       ^          ^          ^          ^
                       |          |          |          |
   SATELLITES     chiglet    post.jolly   mission    chancery / consulate / protocol
                  (bridge)   (mint desk)  (ENVOY)    (REGISTRAR / TRANSIT / PROTOCOL)
                       |
                       | 3-of-5 attestation, immutable cap per chain
                       v
   OUTPOSTS      Ethereum    Sui     TON     Tron    Aptos

   PLATFORM      zedec.near (kernel) | scp144.near (PQ) | zedei.near (interface)
```

---

## 2. Contract topology

```mermaid
graph LR
    subgraph NEAR["NEAR mainnet"]
        direction TB
        Z["zedec.near<br/>ATUV46Keb…<br/>90,380 B"]
        S["scp144.near<br/>DDQ4uJXM…<br/>77,823 B"]
        I["zedei.near<br/>CRZgm89Y…<br/>61,325 B"]
        U["unog.near<br/>Ae5uDVYK…<br/>1,156,670 B"]
        C["chiglet.unog.near<br/>DRq7Th7tf…<br/>331,758 B"]
        P["post.jollydragonroger.near<br/>7z6gj4zjw…<br/>244,201 B"]
        M["mission.unog.near<br/>49rYaA4v…"]
        R["chancery.unog.near<br/>EUfXZxyK…"]
        T["consulate.unog.near<br/>9JHAd3FR…"]
        G["protocol.unog.near<br/>Eg5SgH23…"]
        O["outpost.jollydragonroger.near<br/>CRZgm89Y… (same as zedei)"]
        X["36n9.zedei.near<br/>3H4dqcbN…"]
        TR["trisolaris.near<br/>E8jZ1giW… (empty stub)"]
    end

    Z -->|boots| U
    S -->|verifies| U
    I -->|interfaces| U
    C -->|reads core tag| U
    P -->|deposits into| U
    M -->|jobs| U
    R -->|attestations| U
    T -->|routes| U
    G -->|governance seat| U
    O -->|desk variant| U
```

---

## 3. The sealed core

`unog.near` is a blockchain inside a contract. It owns its own accounts,
balances, nonces and state — separate from NEAR's account model.

```mermaid
graph TB
    subgraph CORE["unog.near — internal state"]
        ACC["Accounts<br/>32-byte id<br/>key = 0x00 || sha256('A' || id)"]
        BAL["Balances<br/>key = sha256('B' || account || asset)"]
        POOL["Pools<br/>bytewise a &lt; b ordering"]
        RES["Reserve<br/>NEAR collateral"]
        ABI["ABI registry<br/>214 descriptors"]
        GOVS["Governance<br/>46 kinds"]
        LAYERS["12 booted layers"]
    end

    NEARACC["NEAR account model<br/>(named accounts, yoctoNEAR)"]
    NEARACC -->|deposit| RES
    RES -->|voucher_mint| BAL
    BAL -->|OP_FT_EXPORT| NEARACC
    BAL -->|pool add/swap| POOL
    ABI --> CORE
```

**Storage key derivation** — this is the thing every client gets wrong:

| Record | Key |
|---|---|
| Account | `0x00 ‖ sha256("A" ‖ account_id)` |
| Balance | `sha256("B" ‖ account_id ‖ asset_id)` |
| NEAR→GRIDCHAIN account | `sha256("near-account:" ‖ accountId)` |

**There is no prefix scan.** A balance key hashes its preimage, so you cannot
enumerate accounts from keys — you must compute the key for a candidate and
look. That is deliberate: it makes the account set opaque while keeping every
individual balance provable.

---

## 4. The four-valued state machine

The protocol does not collapse contradictions. A verdict is one of four
values, and only one of them settles.

```mermaid
stateDiagram-v2
    [*] --> PENDING
    PENDING --> TRUE: quorum satisfied, caps respected
    PENDING --> FALSE: signature invalid / cap exceeded
    PENDING --> BOTH: conflicting valid attestations
    PENDING --> NEITHER: no valid attestation
    TRUE --> SETTLED: value releases
    FALSE --> REJECTED: fail closed
    BOTH --> HELD: explicit contradiction, no release
    NEITHER --> HELD
    SETTLED --> [*]
    REJECTED --> [*]
    HELD --> [*]

    note right of BOTH
        Two valid, conflicting claims.
        The system represents the conflict
        rather than picking a winner.
    end note
    note right of HELD
        Nothing settles. No value moves.
        Contradiction is a state, not a panic.
    end note
```

This is the paraconsistent core: `BOTH` is a first-class outcome, not an
error. A last-writer-wins system would silently pick one attestation; this one
stops and records that it cannot decide.

---

## 5. The token

TIAMAT (PQOS) is a 24-decimal NEP-141 asset with no admin mint.

```mermaid
graph LR
    USER["User"] -->|deposit NEAR| RES["Reserve"]
    RES -->|price = phi^(21 × S / cap)| MINT["voucher_mint"]
    MINT -->|credit| L2["Internal GRIDCHAIN balance"]
    L2 -->|OP_FT_EXPORT| WALLET["NEP-141 wallet"]
    WALLET -->|ft_transfer_call| DESK["MintDesk"]
    DESK -->|voucher_redeem| BURN["Burn PQOS"]
    BURN -->|pro-rata slice| RES
    RES -->|payout| USER
    L2 -->|pool ops| AMM["Internal AMM"]
    WALLET -->|lock| BRIDGE["RouteLock"]
    BRIDGE -->|wrapped| OUT["Outpost"]
    OUT -->|burn| BRIDGE
    BRIDGE -->|release| WALLET
```

**The curve.** `backing per new TIAMAT = phi^(21 × supply / cap)`. Because the
exponent rises with supply, collateral per token rises monotonically and
supply approaches the cap asymptotically. Nobody can accelerate issuance by
waiting — issuance is bounded by collateral, not by time.

```
price
  ^                                        ......... cap = 144e9
  |                                 .....
  |                          .....
  |                   .....
  |            .....
  |      .....
  | ....
  +-------------------------------------------------> supply
   0                                           144,000,000,000
```

---

## 6. The bridge

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant T as unog.near (token)
    participant B as chiglet.unog.near
    participant R as Relayer
    participant A as Attestors (3-of-5)
    participant O as Outpost contract

    U->>T: ft_transfer_call(amount, "ethereum|0xRecipient")
    T->>B: ft_on_transfer(sender, amount, msg)
    B->>B: parse chain|recipient, record {nonce, amount, chain, recipient, sender}
    B-->>U: refund excess / confirm
    R->>B: poll for new requests
    R->>A: build ticket (nonce, amount, chain, recipient, chainTag)
    A-->>R: 3 signatures
    R->>O: mint(ticket, signatures[])
    O->>O: verify quorum + nonce + cap + chainTag
    alt all valid
        O-->>U: wPQOS minted
    else any invalid
        O-->>R: revert (Replay / Cap / Quorum)
    end
```

**`msg` is pipe-separated, not JSON.** The core parser rejects escaped quotes,
so a nested JSON message is silently refunded. This cost us a real transaction
to discover; it is documented here so it does not cost you one.

**Trust model.** The bridge is *attested*, not trustless. A 3-of-5 quorum can
mint on the destination chain, bounded by an immutable per-outpost cap. A
compromised quorum cannot exceed the cap and cannot mint on NEAR.

---

## 7. The internal AMM

```mermaid
graph LR
    A["OP_POOL_CREATE<br/>asset_a || asset_b || fee"] --> P["Pool"]
    B["OP_POOL_ADD<br/>a || b || amt_a || amt_b || min_shares"] --> P
    C["OP_POOL_SWAP<br/>a || b || input_asset || amt || min_out"] --> P
    D["OP_POOL_REMOVE<br/>a || b || shares || min_a || min_b"] --> P
    P --> V1["pool view"]
    P --> V2["position view"]
```

**Ordering matters:** `asset_a` must sort bytewise before `asset_b`. The NEAR
asset is all zeroes, so it always comes first. Wrong order returns `range` —
not an error message, just `range`.

---

## 8. What is proven, and what is not

| Claim | Status |
|---|---|
| 13 contracts deployed, hashes published | **verified** — every WASM SHA-256 matches chain |
| `unog.near` sealed with zero keys | **verified** — `view_access_key_list` returns empty |
| Mint, redeem, export, transfer | **proven on-chain** — see `FORENSIC_LEDGER.md` |
| Internal AMM create/add/swap/remove | **proven on-chain** |
| Lock → attest → mint on Ethereum | **proven** — 0.5 PQOS route completed |
| Sui, TON, Tron, Aptos contracts live | **verified** — deployed, capped, configured |
| Deep liquidity on any venue | **NOT YET** — pools hold fractions of a token |
| Trustless bridging | **NO** — 3-of-5 attested, cap-bounded, and we say so |
| Admin mint, pause, upgrade | **DOES NOT EXIST** — no such function, no key |

The last three lines are the ones a reviewer should check first. We would
rather be judged on an accurate description than a flattering one.
