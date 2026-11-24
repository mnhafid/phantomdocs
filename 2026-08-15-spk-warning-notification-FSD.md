# FSD: SPK Warning Notification

| | |
|---|---|
| **Status** | Draft |
| **Author** | Claude (grilled with mnhafid) |
| **Date** | 2026-08-15 |
| **Version** | 0.1 |
| **Related docs** | [2026-08-15-spk-warning-notification-PRD.md](2026-08-15-spk-warning-notification-PRD.md) · [2026-08-15-spk-warning-notification-TICKETS.md](2026-08-15-spk-warning-notification-TICKETS.md) |

## 1. Scope

Two warning triggers on SPK, both delivered to the SPK's field inspectors as email + in-app notification:

- **Release trigger** — fires synchronously inside the existing release flow, once per SPK.
- **Deviation trigger** — a daily Quartz job that compares actual vs plan progress for every released SPK and warns on breach, re-sending at a configured cadence.

Plus two Custom Configuration rows and one internal trigger endpoint for QA.

## 2. Existing components reused

| Component | Location | Used for |
|---|---|---|
| `IMailerService.QueueSend` | `Logics/Services/Mailer` | Email delivery (R4Mailer / SMTP switch is already handled). |
| `PhantomEmailTemplates` | `Logics/Services/Email/PhantomEmailTemplates.cs` | Embedded HTML bodies + `[key]` placeholder rendering. |
| `Notification` entity | `DataAccess/Entities/Notification.cs` | In-app notification rows. |
| `CustomConfigurationLookupExtensions.CustomConfigsByNamesAsync` + `DetailValue` / `DetailDouble` | `Logics/Services/CustomConfigurations/CustomConfigurationDetailExtensions.cs` | Reading both detail shapes (array-of-key/value from the admin UI, plain object from seeds). |
| `spk_boq_schedules` | `DataAccess/Entities/SpkBoqSchedule.cs` | `plan_weight` / `actual_weight`, the same source as `GetSpkSCurveDataAsync`. |
| `spk_field_inspectors` | `DataAccess/Entities/SpkFieldInspector.cs` | Recipient list. |
| Quartz durable job + `IServiceScopeFactory` pattern | `Logics/Services/DataScience/ContractDepletionNotifyJob.cs` | Job shape, `[DisallowConcurrentExecution]`, registration extension. |

**Deliberately not reused:** `ContractDepletionNotifySchedule`'s frequency→cron mapping and its startup reconciler. Here the job cron is fixed (daily 08:00) and the frequency governs *resend suppression*, not the trigger. That removes the reschedule path, the reconciler, and the class of bug where a restart inside the fire window silently skips a week.

## 3. Data model

### 3.1 New table `spk_deviation_warnings`

Tracks the current breach episode per SPK. Without it, `one_time` and `weekly` cannot be honoured.

| Column | Type | Null | Notes |
|---|---|---|---|
| `id` | uniqueidentifier | no | PK. |
| `spk_id` | uniqueidentifier | no | Unique index. FK-free, matching the SPK-document tables' current convention. |
| `last_notified_at` | datetime2 | no | Local time of the last warning sent for this episode. |
| `last_deviation` | float | no | Deviation (pp) at the last send. Diagnostics only. |
| `created_at` | datetime2 | no | |
| `updated_at` | datetime2 | yes | |

A row exists **only while the SPK is in breach**. Recovery deletes it (FR-011), which is what makes `one_time` mean "once per episode".

### 3.2 Custom Configuration rows

Seeded by an idempotent script under `DataAccess/Database/` (literal GUIDs, `NOT EXISTS` guard, no `DECLARE`/`GO` — the repo convention so it runs in DBeaver as one batch).

```
name: warning.spk_deviation_threshold
detail: [{"key":"spk_deviation_threshold","value":"5.00","note":"Warn when actual-plan progress <= -X percentage points"}]

name: warning.spk_reminder_frequency
detail: [{"key":"spk_reminder_frequency","value":"one_time","note":"daily | weekly | one_time"}]
```

## 4. Functional requirements

### Release trigger

**FR-001 — Release fires a notification.** *(US-01, G1)*
When `SpksService.ReleaseSpkAsync` successfully sets an SPK to `released`, the system queues a release notification to that SPK's recipients (FR-003) after the status change is committed. The existing guard "Only approved SPK can be released" already makes this at-most-once per SPK.

**FR-002 — Notification failure must not fail the release.** *(NFR-002)*
The notification work is wrapped so that any exception in recipient lookup, template rendering, or queueing is logged at Error and swallowed. A released SPK stays released. Releasing is the user-visible transaction; notifying is a side effect.

**FR-003 — Recipient resolution.** *(US-01, US-02)*
Recipients = users joined from `spk_field_inspectors` where `spk_field_inspectors.spk_id` matches, `spk_field_inspectors.deleted_at IS NULL`, `users.deleted_at IS NULL`, `users.status IS NULL OR users.status = 'active'`, and `users.email` is non-null and non-empty. Duplicates are removed by user id. If the set is empty, nothing is sent and a Warning is logged naming the SPK number.

**FR-004 — Release notification content.**
One email per (SPK, recipient) — an inspector on three released SPKs receives three emails, not a digest.

Subject: `SPK has been released`

Body: new embedded template `EmailSpkReleased.html`. Placeholders `[fullname]`, `[spk_name]`, `[spk_url]`. Copy:

```
Hello, [fullname]

This SPK, [spk_name] has been released.

            [ Go to SPK Detail ]          ← CTA button, href = [spk_url]

Please do not reply to this email with your password.
We will never ask for your password, and we strongly discourage you from sharing it to anyone.

Thanks,
The Phantom Team
```

In-app `Notification` row per recipient: title `SPK has been released`, message `This SPK, [spk_name] has been released.`, `web_link` and `mobile_link` = `[spk_url]`, `has_read = 0`, `user_id` = recipient.

### Deviation trigger

**FR-005 — Schedule.** *(US-02, G2)*
A durable Quartz job `SpkDeviationWarningJob` runs on cron `0 0 8 * * ?` (08:00 local, daily) with `[DisallowConcurrentExecution]` and `RequestRecovery()`, registered in the same style as `ContractDepletionNotifyJob`. Misfire handling: `WithMisfireHandlingInstructionFireAndProceed`.

**FR-006 — Candidate SPKs.**
Every SPK where `status = 'released'` and `deleted_at IS NULL`. Every other status — including `finished`, `finished with note`, `cancelled`, `on hold` — is excluded; an SPK leaving `released` therefore stops warning on the next run.

**FR-007 — Deviation formula.**
For each candidate SPK, over `spk_boq_schedules s` joined to `spk_boqs b` on `s.spk_boq_id = b.id` where `b.spk_id = <spk>` and `s.date <= today (local, date part)`:

```
deviation = SUM(s.actual_weight) - SUM(s.plan_weight)     // percentage points
```

Weights sum to 100 across an SPK's schedules, so the sums up to today are the cumulative plan/actual at today — the same quantities `GetSpkSCurveDataAsync` plots. The `*_accumulation` columns are **not** used: they are denormalized and would introduce a second source of truth. An SPK with no schedule rows on or before today is skipped (no data ≠ behind).

**FR-008 — Threshold resolution.** *(US-03, G3)*
Read `warning.spk_deviation_threshold` once per job run via `CustomConfigsByNamesAsync` + `DetailDouble("spk_deviation_threshold")`. Missing row, missing key, or unparseable value → default `5.00` and log at Information. The effective comparison always uses the magnitude: `threshold = -Math.Abs(value)`.

**FR-009 — Breach decision.**
An SPK is *in breach* when `deviation <= threshold` (e.g. `-7.00 <= -5.00`). Equality breaches — the acceptance criteria say "sama atau kurang dari".

**FR-010 — Frequency gate.** *(US-04, G4)*
Read `warning.spk_reminder_frequency` once per run via `DetailValue("spk_reminder_frequency")`, lower-cased and trimmed. Accepted: `daily`, `weekly`, `one_time`. Missing, empty, or unrecognised → `one_time`, logged at Information (unrecognised also logs the offending value at Warning). For an SPK in breach with an existing `spk_deviation_warnings` row:

| Frequency | Re-send when |
|---|---|
| `daily` | `last_notified_at` is on an earlier local date than today |
| `weekly` | `last_notified_at` is 7 or more days before now |
| `one_time` | never (the row's existence is the suppression) |

An SPK in breach with **no** row is always sent, whatever the frequency — that is the first warning of the episode.

**FR-011 — Breach state lifecycle.**
- Sent, no existing row → insert `spk_deviation_warnings` with `last_notified_at = now`, `last_deviation = deviation`.
- Sent, existing row → update `last_notified_at`, `last_deviation`, `updated_at`.
- Not in breach and a row exists → **delete the row** (recovery). The next breach starts a fresh episode.
- Not in breach and no row → nothing.

**FR-012 — Deviation notification content.**
One email per (SPK, recipient), as in FR-004.

Subject: `SPK Deviation Exceeded`

Body: new embedded template `EmailSpkDeviationWarning.html`. Placeholders `[fullname]`, `[spk_name]`, `[threshold]`, `[spk_url]`. Copy:

```
Hello, [fullname]

This SPK, [spk_name] deviation has exceeded -[threshold]% threshold

            [ Go to SPK Detail ]          ← CTA button, href = [spk_url]

Please do not reply to this email with your password.
We will never ask for your password, and we strongly discourage you from sharing it to anyone.

Thanks,
The Phantom Team
```

`[threshold]` is the **magnitude** formatted to 2 decimals with invariant culture (`5.00`), because the template already writes the minus sign — a configured `-5.00` must not render as `--5.00%`. The measured deviation is not shown in the message; it is still persisted on `spk_deviation_warnings.last_deviation` and logged for diagnostics.

In-app `Notification` per recipient: title `SPK Deviation Exceeded`, message `This SPK, [spk_name] deviation has exceeded -[threshold]% threshold.`, links as in FR-004.

**FR-012a — `[spk_name]` and `[spk_url]`.**
`[spk_name]` renders as `<spk_no> — <spk_title>` (e.g. `SPK/2026/0142 — Perbaikan Flowline Sumur X`): the number alone is not human-recognisable in an inbox, the title alone is not unique. `[spk_url]` = `{AppSettingsConfig:WebBaseUrl}/spk/{spkId}/detail`. Both are shared by FR-004 and FR-012.

**FR-013 — Per-SPK failure isolation.**
Each SPK is processed inside its own try/catch. A failure on one SPK is logged with the SPK number and the run continues. The run logs a summary: candidates evaluated, in breach, sent, suppressed by frequency, skipped for no recipient, recovered, failed.

**FR-014 — Manual trigger.** *(US-05)*
`POST /api/v1/spks/internal/spk-deviation-warning` runs the same job body synchronously and returns the run summary. `AllowAnonymous()`, matching the existing internal reminder endpoint — it is an internal/cron-facing route, not part of the authenticated surface.

### Configuration surface

**FR-015 — No new config endpoint.** *(US-03, US-04, G3)*
Both rows are managed through the existing Custom Configuration CRUD (`/api/v1/custom-configurations`). Values are validated **on read** (FR-008, FR-010), not on write: the admin screen is generic and adding key-specific write validation there would couple it to this feature. The cost is that a typo is discovered by the job's log line rather than by a 400 — accepted, because every fallback path is a safe default rather than a crash.

## 5. Non-functional requirements

| ID | Requirement |
|---|---|
| NFR-001 | The deviation job issues one aggregate query for all candidate SPKs' plan/actual sums (`GROUP BY b.spk_id`) and one query for all recipients, not one per SPK. Target: a run over 1,000 released SPKs completes in under 30 seconds excluding mail queueing. |
| NFR-002 | No notification failure may roll back or block the business transaction that triggered it (FR-002), and no single SPK may abort a job run (FR-013). |
| NFR-003 | All timestamps use the injected `TimeProvider.GetLocalNow()`, never `DateTime.Now` — the codebase convention, and what makes the frequency gate testable. |
| NFR-004 | Every new method stays at cognitive complexity ≤ 15 per `CLAUDE.md`; the job body is an orchestrator over focused private helpers (`LoadSettings`, `ComputeDeviations`, `ShouldSend`, `SendWarning`, `ApplyRecovery`). |
| NFR-005 | Email bodies are rendered through `PhantomEmailTemplates.Render`, which HTML-encodes values — an SPK title containing `<` or `&` cannot inject markup. In-app title/message are plain text and are substituted verbatim, matching `NotificationDispatcher`. |
| NFR-006 | The seed script is idempotent and re-runnable (`NOT EXISTS` on `name`), and contains no `DECLARE`/`GO` so it executes as a single batch in the team's JDBC client. |

## 6. Interfaces

### `POST /api/v1/spks/internal/spk-deviation-warning`

Runs the deviation check immediately. No request body. `AllowAnonymous`.

**200**

```json
{
  "status": true,
  "message": "SPK deviation warning check completed",
  "elapsed": 812.4,
  "data": {
    "evaluated": 42,
    "in_breach": 5,
    "sent": 3,
    "suppressed": 2,
    "no_recipient": 1,
    "recovered": 4,
    "failed": 0
  }
}
```

**500** — `ApiResponseHelper.ServerError`, message `Failed to run SPK deviation warning check`.

No other new HTTP surface: the release trigger is internal to `ReleaseSpkAsync`, and configuration uses the existing Custom Configuration endpoints.

## 7. Edge cases

| Case | Behavior |
|---|---|
| SPK released with zero field inspectors | Nothing sent; Warning log names the SPK number. Counted as `no_recipient`. |
| Field inspector user deleted or inactive | Excluded by FR-003. |
| Field inspector with an empty email | Excluded from email **and** from the in-app notification (single recipient set — a user with no email is treated as not reachable, consistent with the project-task reminder). |
| SPK released but no BOQ schedules yet | Skipped by FR-007; not counted as breach. |
| All schedule dates in the future | Same as above — sums over `date <= today` are empty, skipped. |
| Deviation exactly equals the threshold | In breach (FR-009). |
| Deviation positive (ahead of plan) | Not in breach; any existing state row is deleted (FR-011). |
| Threshold configured as `-5.00` | Treated as `-5.00` via magnitude (FR-008). |
| Threshold configured as `abc` or blank | Default `5.00`, logged (FR-008). |
| Frequency configured as `Weekly` / `WEEKLY` | Accepted — comparison is trimmed and lower-cased (FR-010). |
| Frequency configured as `monthly` | Falls back to `one_time`, Warning logged with the value (FR-010). |
| Duplicate `custom_configurations` rows with the same name | Newest by `updated_at` wins — already handled by `CustomConfigsByNamesAsync`. |
| Job run overlaps the previous run | Prevented by `[DisallowConcurrentExecution]`. |
| SPK finishes while in breach | Dropped from candidates on the next run (FR-006). Its state row is left behind and is inert; it is cleaned up if the SPK ever returns to `released` and recovers. |
| Manual trigger fired while the cron run is in progress | The endpoint runs the service method directly, so it does not contend with the Quartz lock; the frequency gate keeps a double-fire from double-sending on the same day for `daily`/`weekly`/`one_time`. |

## 8. Test plan

Unit tests (in-memory `PhantomDbContext`, `FakeTimeProvider`, fake mailer — the existing `ProjectTaskNotificationFrequencyTests` shape):

1. Deviation formula sums only rows on or before today and returns actual − plan.
2. Breach at exactly the threshold sends; one pp above it does not.
3. Negative-signed threshold config produces the same result as positive.
4. `one_time`: second run on a later day with the SPK still in breach sends nothing.
5. `daily`: second run on a later day sends; second run on the same day does not.
6. `weekly`: run at +6 days does not send, at +7 days does.
7. Recovery deletes the state row, and a later re-breach sends again under `one_time`.
8. SPK with no active field inspector is skipped and does not create a state row.
9. Release trigger queues one email + one notification per eligible inspector.
10. A mailer exception during release does not prevent the SPK reaching `released`.

## 9. Traceability

| FR | Goal / Story |
|---|---|
| FR-001, FR-002, FR-003, FR-004, FR-012a | G1 / US-01 |
| FR-005, FR-006, FR-007, FR-009, FR-013 | G2 / US-02 |
| FR-008, FR-015 | G3 / US-03 |
| FR-010, FR-011, FR-015 | G3, G4 / US-04 |
| FR-012 | G1, G2 / US-01, US-02 |
| FR-014 | G2 / US-05 |
| NFR-001…NFR-006 | Cross-cutting |
