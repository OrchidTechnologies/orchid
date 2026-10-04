# BYOC protocol — bring your own client

How to talk to an Orchid GenAI server without using the bundled client. This is
the integration contract for **any** client: pay over a billing WebSocket, then
spend the resulting balance against an OpenAI-compatible inference HTTP API.

`gai-frontend` is deprecated; this document, not that client, is the spec.

---

## 1. Architecture

A server exposes **two independent network surfaces** bridged by one shared
secret, the `session_id`:

```
                  billing WebSocket (server.py)            inference HTTP (inference_api.py)
  ┌────────┐   invoice ───────────────►   ┌────────┐                         ┌────────────┐
  │ client │   ◄─────── pay (tickets)     │ billing│   Redis balance key     │ inference  │
  │ (yours)│   request_token ────────►    │ server │◄──── billing:balance ──►│ HTTP API   │
  │        │   ◄────── auth_token         │        │      :<session_id>      │ (OpenAI-   │
  │        │     {session_id, url}        └────────┘                         │  compatible)│
  │        │                                                                 │            │
  │        │   POST /v1/chat/completions  Authorization: Bearer <session_id> │            │
  │        │   ◄──────────────────────────────────────────────────────────► │            │
  └────────┘                                                                 └────────────┘
```

- **Billing WebSocket** (`server.py`): accepts Orchid nanopayment tickets and
  credits their expected value to a per-session balance in Redis.
- **Inference HTTP API** (`inference_api.py`): OpenAI-compatible; every request
  authenticates with the `session_id` as a bearer token and is metered against
  that session's balance.
- The two need not be the same host. The billing server tells the client which
  inference URL to use (`auth_token.inference_url`).

A separate JSON-RPC proxy (`rpc_api.py`, billed per method) exists for chain-RPC
relaying; it is out of scope here.

---

## 2. The session model (read this first)

The `session_id` **is** the Redis billing key (`billing:balance:<session_id>`)
AND a bearer capability for the inference API. Three consequences:

1. **It is money.** Anyone who holds a `session_id` can spend its balance on the
   inference API. Treat it like a secret API key. It is a 122-bit random UUIDv4
   (the websocket connection id), so it is unguessable, but it is sent in clear
   to the client and used as a plain `Bearer` token — use TLS (`wss://`/`https://`)
   end to end.
2. **Payment and spending are the same identity by construction.** The token the
   server returns in `auth_token` is the exact key your websocket payments
   credited. Pay on the socket → authenticate HTTP with the token it hands you →
   you are spending what you paid. (`server.py` derives `session_id =
   str(websocket.id)` once and uses it as the billing key, the balance pubsub
   channel, and the returned token — see the comment at the top of `session()`.)
3. **The session is bound to the live websocket connection.** The balance row
   persists in Redis, but the `session_id` is the connection's UUID: if the
   socket drops and you reconnect, you get a *new* `session_id` with a *fresh
   (zero)* balance, and any unspent balance under the old id is stranded. So:
   **keep the billing websocket open for the life of the session.** Resumable /
   client-named sessions are a known gap (see §7).

---

## 3. Billing WebSocket protocol

Connect to the billing `wss://` endpoint. All messages are JSON text frames with
a `type` field. Amounts are **integer wei** of the payment token (native xDAI on
Gnosis, chain 100).

### 3.1 Server → client: `invoice`

Sent immediately on connect, and again automatically whenever your balance falls
below the minimum (the server runs a balance monitor that re-invoices; see §3.5).

```json
{
  "type": "invoice",
  "amount": 4000000000000000,
  "commit": "0x<keccak(reveal)>",
  "recipient": "0x<recipient_address>"
}
```

- `amount` — expected value the server wants you to transfer, in wei. The first
  invoice is `2 × min_balance`; top-ups target restoring `2 × min_balance`.
  `min_balance = 2 × (price.invoice + price.payment)` (server config).
- `commit` — the lottery commitment, `keccak(reveal)`, chosen by the server. The
  server keeps `reveal` secret and uses it to claim winning tickets on-chain.
  **You sign over `commit` directly** (it is already one keccak of the reveal).
- `recipient` — the address that must be the ticket recipient.

### 3.2 Client → server: `payment`

Pay an invoice by sending one or more serialized tickets. The server processes
`tickets[0]`.

```json
{ "type": "payment", "tickets": ["<256-hex-char serialized ticket>"] }
```

See §4 for how to build the ticket. On success the server credits the ticket's
**expected value** (not its face value) to your session balance. No reply is sent
on success; on failure you get an `error` (§3.4).

### 3.3 Client → server: `request_token`

Once you have paid enough to exceed `min_balance`, request your session token.

```json
{ "type": "request_token", "orchid_account": "0x<funder_address>" }
```

- `orchid_account` is **advisory only**. The authoritative funder is the address
  signed into every ticket (`packed1`), which the server reads from the ticket
  itself. The declared `orchid_account` is kept only as a cross-check for logging;
  it is not trusted and may be omitted.

Server replies:

```json
{
  "type": "auth_token",
  "session_id": "<uuid>",
  "inference_url": "https://<inference-host>"
}
```

Use `session_id` as the bearer token for the inference API at `inference_url`.

### 3.4 Server → client: `error`

```json
{ "type": "error", "code": -6001 }
```

| code   | meaning                                                              |
|--------|---------------------------------------------------------------------|
| -6001  | payment rejected (missing/empty tickets, or ticket failed acceptance) |
| -6002  | auth-token issuance failed (billing error while charging the token) |

A rejected ticket also debits a small `error` fee from your balance. A ticket
that is merely *uncreditable for no fault* (e.g. the escrow RPC is temporarily
unavailable) is neither credited nor penalized — just retry on the next invoice.

### 3.5 Automatic top-ups

The server monitors your balance and pushes a fresh `invoice` whenever it drops
below `min_balance` (rate-limited to ~1/sec). A long-lived client should keep a
receive loop that answers any inbound `invoice` with a `payment`, so the session
stays funded without polling.

---

## 4. Building a ticket

A ticket is an Orchid lottery v1 probabilistic nanopayment. The reference
implementation is `OrchidAccount.create_ticket` in `account.py`; the canonical
on-chain format is `lottery1.sol :: claim_()`. To pay an invoice for expected
value `amount`:

1. **Read the funder's on-chain escrow.** Call `check_balance(token, funder,
   signer)` on the lottery contract; it returns `(balance, escrow)` where
   `escrow` (the upper 128 bits of the funder's account) is the at-risk
   **collateral** bond.
2. **Size the face at half the escrow:** `face = escrow // 2`. The recipient only
   honors tickets whose `2 × face ≤ escrow` (so the collateral the funder would
   forfeit by double-spending always exceeds 2× any single face — cheating is
   unprofitable). `face` must be `≥ amount` and `≤ uint128`; if `escrow` is too
   small to cover the invoice (`escrow < 2 × amount`), add collateral.
3. **Solve the win ratio so the booked EV equals the invoice:**
   `ratio = (amount << 64) // face − 1`. Then `EV = face × (ratio+1) / 2^64 ≤
   amount` (the floor favors the recipient). `face == amount` ⇒ `ratio =
   2^64−1` (guaranteed win); `face == 2×amount` ⇒ `ratio = 2^63−1` (P = ½).
4. **Pack and sign** per the contract bit layout:
   - `packed0 = face[0,128) | nonce64[128,192) | issued64[192,256)`
   - `packed1 = v(bit0) | funder[1,161) | ratio64[161,225) | expire_delta31[225,256)`
   - digest (EIP-191 v0): `keccak(0x19, 0x00, lotteryAddr, chainid, token,
     recipient, commit, packed0, packed1>>1, data=0)` — sign the digest **raw**
     (the 0x19/0x00 envelope is already inside it; do **not** wrap again in
     `personal_sign`).
5. **Serialize** as the concatenation of four 32-byte big-endian hex words (no
   `0x`, zero-padded to 64 chars each): `packed0 ‖ packed1 ‖ r ‖ s` → 256 hex
   chars.

The server credits the **expected value** of the ticket at handoff and only
submits *winning* tickets on-chain, so most tickets never touch the chain — the
point of probabilistic payments. Economic rationale: the project's
DESIGN-DECISIONS notes (D3 EV-crediting, D10 ½-escrow face bound).

---

## 5. Inference HTTP API

OpenAI-compatible. Authenticate every metered call with
`Authorization: Bearer <session_id>`.

### Auth gate (`validate_session`)
A session is usable iff the token is non-empty, its balance row exists, and —
unless the server is in tools-only mode — `balance ≥ min_balance`. Otherwise the
call fails with an authentication / insufficient-balance error.

### `POST /v1/chat/completions`
OpenAI chat-completions request body. Set `"stream": true` for Server-Sent
Events (`text/event-stream`); otherwise a single JSON `ChatCompletion` is
returned. Billing: the server pre-debits a worst-case hold up front, then
**settles** against the upstream-reported usage when the response completes
(refunding the overage, or collecting a shortfall). Balance updates are also
published on the Redis channel `billing:balance:updates:<session_id>`, which the
billing websocket relays as top-up invoices.

### `GET /v1/models`
OpenAI-style model list (`{"data": [...]}`). No auth. Used by clients/connectors
(e.g. Hermes `fetch_models()`) to populate a model picker.

### `GET /v1/inference/models`
Server-internal model listing (endpoint → model metadata).

### `POST /v1/tools/list` · `POST /v1/tools/call`
Bearer-authenticated. List available tools, and execute one (billed per call,
refunded on timeout/failure). Tool calling is also available inline via the
chat-completions format.

---

## 6. Minimal client flow

```
1.  ws = connect(wss://billing-host)
2.  loop:
       msg = ws.recv()
       if msg.type == "invoice":
           ticket = build_ticket(msg.amount, msg.commit, msg.recipient)   # §4
           ws.send({type:"payment", tickets:[ticket]})
           if balance_now_sufficient:
               ws.send({type:"request_token", orchid_account: funder})
       if msg.type == "auth_token":
           session_id   = msg.session_id
           inference_url = msg.inference_url
           break
       if msg.type == "error":
           handle(msg.code)
3.  # keep ws open in the background, answering further `invoice` top-ups
4.  POST {inference_url}/v1/chat/completions
        Authorization: Bearer {session_id}
        body: { model, messages, stream }
```

A wallet-only client can stop after step 3 and just keep the session funded; an
inference-only client can skip the websocket entirely if it already holds a
valid `session_id` (e.g. one minted elsewhere and still funded).

---

## 7. Known properties, limits, and roadmap

- **Session = connection.** No resumable or client-named sessions yet; a dropped
  socket strands its balance (§2.3). A future revision should let a client present
  a stable identity (e.g. a signed funder claim) and rebind to its balance across
  connections. This is the main BYOC ergonomics gap.
- **`orchid_account` is advisory.** Funder authority lives in the signed ticket;
  the declared account is a logging cross-check only.
- **CORS** is handled at the proxy (Caddy), not in the app — browser clients rely
  on the proxy's headers.
- **Streaming** is real SSE on `/v1/chat/completions`. Tool calling uses the
  OpenAI format. These are the surfaces an OpenAI-compatible connector
  (e.g. a Hermes provider profile; see the project's Hermes integration notes)
  binds to.
- **Direction.** This API is the integration target for the shim → gai-router
  path; keeping it standard OpenAI-compatible is what makes "bring your own
  client" hold.
