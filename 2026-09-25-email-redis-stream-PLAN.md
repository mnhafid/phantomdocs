# Plan: send email through the Redis Streams queue

Status: plan + benchmark, no code yet. Branch target: `phi-dev`.

## Why

`MailerService.QueueSend` drops a closure into an in-memory `ConcurrentQueue` drained by
`QueuedProcessorBackgroundService`. Everything queued is lost on restart, deploy or crash; a
failed send is logged once and gone; only one node drains it. This week's production incident
(1,004 emails rejected by Mail3R with `resultInt` 400) was invisible partly because there was
no queue to look at — no pending count, no retry, no dead letters.

The repo already runs a Redis Streams consumer group (`RedisStreamConsumerService`) with
ack-after-success, reclaim of stale pending entries after `IdleClaimMs` (30 s), and a cap of
`MaxDeliveryAttempts` (5). The rebaseline and ETC handlers use it today. Email fits the same
contract with one handler and one publish call.

## Benchmark (2026-09-25, local Redis 7 via Homebrew, StackExchange.Redis 2.7.27, N = 2,000)

Harness: `scratchpad/mailbench/Program.cs`. It reproduces the app's publisher (`XADD MAXLEN ~ 10000`)
and consumer (`XREADGROUP COUNT 10`, `XACK` per entry, 1,000 ms idle sleep) against a throwaway
instance on port 6390. Production Redis is remote and shared, so absolute numbers there will be
higher by the network round trip (sub-millisecond on the PHI LAN); the ratios hold.

| measurement | result |
|---|---|
| enqueue, in-memory queue, 3 KB | 0.000 ms (a pointer copy) |
| XADD 3 KB html (typical approval email), p50 / p95 / p99 | 0.175 / 0.372 / 0.496 ms, 4,866 ops/s |
| XADD 3 KB + MinIO reference for the attachment | 0.165 / 0.364 / 0.499 ms, 5,128 ops/s |
| XADD 200 KB inline attachment (base64 xlsx) | 0.255 / 0.611 / 0.924 ms, 3,284 ops/s |
| Redis memory, 2,000 entries × 3 KB | 6.0 MB |
| Redis memory, 2,000 entries × 3 KB + MinIO reference | 6.1 MB |
| Redis memory, 2,000 entries × 200 KB inline attachment | **390.8 MB** |
| consume 2,000 × 3 KB, XREADGROUP count 10, XACK per entry (app today) | 321 ms, 6,231 msg/s |
| consume 2,000 × 3 KB, same with one batched XACK per read | 63 ms, 31,746 msg/s |
| idle → first delivery, poll loop sleeping 1,000 ms (app today), avg / max | 494 / 871 ms |
| durability: consumer dies holding 40 delivered entries, 60 unread | 40 reclaimed + 60 fresh = **100/100** |
| durability: in-memory queue after process restart | **0/100** |

Reading the numbers against the real load — production sends ~500 emails a day, peak 238 in one
hour (2026-09-24 15:00):

- **Throughput is not a factor.** The slowest publish path does 3,000+ per second; the consumer
  drains 6,000 per second even with the per-entry ack the app uses today. Mail3R (hundreds of
  milliseconds per send) is the bottleneck by three orders of magnitude, so batched XACK is not
  worth the code.
- **Attachments must go by reference.** Inline bytes multiply Redis memory by 65× per entry; at
  `MaxLenApprox` 10,000 that is 2 GB of Redis for a stream that otherwise needs 30 MB.
  `MailerAttachment` already carries `MinioBucket`/`MinioObject`; the handler fetches the bytes.
- **The 1 s poll adds under a second of latency**, which no email notices. `XREADGROUP BLOCK`
  is not worth changing the shared consumer loop for.
- **Durability is the whole point.** Every entry survived a simulated crash; the in-memory queue
  loses all of them.

## Design

```
QueueSend(msg)
   │  streams enabled?  ──no──▶ in-process queue (unchanged)
   ▼ yes
TryPublish("email", {event_type:"send", payload: EmailSendEvent json})
   │  false (Redis down) ──▶ in-process queue (fallback, log once)
   ▼ true
Redis stream phantom:streams:email  ──▶ RedisStreamConsumerService ──▶ EmailSendHandler
                                                                          │ resolve provider (R4 / SMTP)
                                                                          │ fetch attachments from MinIO
                                                                          ▼ SendAsync  → ack on success
                                                          failure → stays pending → reclaimed after 30 s → up to 5 attempts → error line + drop
```

`EmailSendEvent` = `MailerMessage` minus `Attachments[].Content`, plus a `MessageId` (Guid) and
the publisher's `request_id` so the mailer lines can still be tied to the request that queued them.

## Tickets

| ID | Title | Size | Blocked by |
|---|---|---|---|
| T-01 | `IStreamPublisher.TryPublishAsync` returning bool; `PublishAsync` keeps fail-open semantics | XS | — |
| T-02 | `EmailSendEvent` DTO + `EmailSendHandler` (stream `email`, event `send`): deserialise, fetch MinIO attachments, call the configured provider's `SendAsync`; carry `request_id` into LogContext | S | T-01 |
| T-03 | `MailerService.QueueSend`: publish when streams are enabled, fall back to the in-process queue when disabled or `TryPublishAsync` returns false; attachments with inline `Content` are written to MinIO first and published by reference | S | T-02 |
| T-04 | Config: `RedisStreams:Enabled = true` on dev, then prod; `RedisStreams:IdleClaimMs` stays 30,000; document in `example.appsettings.json` | XS | T-03 |
| T-05 | Diagnostics: `GET /streams/diagnostics` already lists pending per stream — add the `email` stream to the existing diagnostics endpoint's default list | XS | T-02 |

Tests: handler round-trip with a recording provider (both providers), fallback when `TryPublishAsync`
returns false, attachment reference resolution, and an in-memory-Redis-free unit test for the
event serialisation. The consumer itself is already covered.

## Risks and the decisions taken

- **At-least-once means possible duplicates** when the process dies between `SendAsync` and
  `XACK`. Accepted for now; approval and alert emails tolerate a repeat. If it bites, a `SETNX`
  on `MessageId` with a 24 h TTL before sending makes it effectively once.
- **Five attempts across 30-second reclaims ≈ 2.5 minutes** of retry. A Mail3R outage longer than
  that still drops mail, now with an error line per message instead of silence. A parking stream
  for exhausted entries is the follow-up if outages prove longer.
- **Prod Redis had connection aborts this week (t85).** The fallback in T-03 keeps sending during
  a Redis outage exactly as today; nothing gets worse.
- **Attachments written to MinIO before publish** add one MinIO write per report email (3 a day).

## Not doing

- Replacing `RedisStreamConsumerService` or adding a second consumer loop for email.
- Batched XACK or `XREADGROUP BLOCK` (see benchmark).
- A separate email microservice.
