# Tickets: SPK Warning Notification

| | |
|---|---|
| **Date** | 2026-08-15 |
| **Related docs** | [PRD](2026-08-15-spk-warning-notification-PRD.md) · [FSD](2026-08-15-spk-warning-notification-FSD.md) |
| **Coverage** | All 15 FRs and 6 NFRs covered by 6 tickets. |

## Summary

| ID | Title | Size | Blocked by | Covers |
|---|---|---|---|---|
| T-01 | Config seed + `spk_deviation_warnings` table | S | — | FR-015, NFR-006 |
| T-02 | Warning settings reader (threshold + frequency) | S | T-01 | FR-008, FR-010, NFR-003 |
| T-03 | Recipient resolver + two email templates | S | — | FR-003, FR-004, FR-012, FR-012a, NFR-005 |
| T-04 | Release trigger | S | T-03 | FR-001, FR-002 |
| T-05 | Deviation calculator + warning job | M | T-02, T-03 | FR-005…FR-007, FR-009, FR-011, FR-013, NFR-001, NFR-004 |
| T-06 | Quartz registration + internal trigger endpoint | S | T-05 | FR-014 |

Build order is the table order. T-03 has no blockers and can start in parallel with T-01/T-02.

---

## T-01 — Config seed + `spk_deviation_warnings` table

**Size:** S · **Covers:** FR-015, NFR-006

Add the EF entity + `PhantomDb.SpkDeviationWarning.cs` configuration + migration for `spk_deviation_warnings` (columns per FSD §3.1, unique index on `spk_id`). Add `DataAccess/Database/seed_spk_warning_custom_configs.sql` inserting the two Custom Configuration rows with literal GUIDs and `NOT EXISTS` guards.

**Acceptance criteria**
- Given a fresh database, when migrations run, then `spk_deviation_warnings` exists with a unique index on `spk_id`.
- Given the seed script is run twice, when it completes, then exactly one row per config name exists and no error is raised.
- Given the seed script is pasted into DBeaver, when it is executed, then it runs as a single batch (no `DECLARE`, no `GO`).

**Notes**
- The migration diff will also sweep the known spurious `permission_groups`/`TempId` change — strip it before committing, as with every other migration in this repo.

---

## T-02 — Warning settings reader

**Size:** S · **Blocked by:** T-01 · **Covers:** FR-008, FR-010, NFR-003

A small reader that loads both config rows in one `CustomConfigsByNamesAsync` call and returns `(double Threshold, string Frequency)` with the FSD's defaults and normalisation. Threshold via `DetailDouble`, negated to `-Math.Abs(x)`. Frequency via `DetailValue`, trimmed + lower-cased, whitelist `daily|weekly|one_time`.

**Acceptance criteria**
- Given no config rows exist, when settings are read, then threshold is `-5.00` and frequency is `one_time`, each logged at Information.
- Given the threshold row holds `-5.00`, when settings are read, then the effective threshold is `-5.00` (identical to `5.00`).
- Given the threshold row holds `abc`, when settings are read, then the default is used and nothing throws.
- Given the frequency row holds `Weekly`, when settings are read, then frequency is `weekly`.
- Given the frequency row holds `monthly`, when settings are read, then frequency is `one_time` and a Warning names the value.
- Given the detail is in the object shape `{"spk_deviation_threshold": 5.0}`, when settings are read, then the value is found (both shapes round-trip).

---

## T-03 — Recipient resolver + email templates

**Size:** S · **Covers:** FR-003, FR-004, FR-012, FR-012a, NFR-005

One query returning eligible field inspectors for a set of SPK ids (FSD FR-003), plus two embedded HTML templates (`EmailSpkReleased.html`, `EmailSpkDeviationWarning.html`) and their `Subject_`/`HtmlBody_`/`TemplateName_` constants on `PhantomEmailTemplates`. Register both under `Logics.csproj` embedded resources.

Both templates are `EmailContractValueDepletionWarningNotification.html` **copied verbatim** with only the message paragraph, the CTA label and its href changed — that file already carries the exact CTA button, the "do not reply … with your password" pair and the "Thanks, The Phantom Team" sign-off the PO specified. Do not rebuild the shell.

**Acceptance criteria**
- Given an SPK with three inspectors — one active with email, one soft-deleted, one active without an email — when recipients are resolved, then only the first is returned.
- Given the same user is listed twice on an SPK, when recipients are resolved, then they appear once.
- Given the release template is rendered, then the subject is `SPK has been released`, the body reads `This SPK, <spk_no> — <spk_title> has been released.` and the CTA links to `{WebBaseUrl}/spk/{id}/detail`.
- Given the deviation template is rendered with a configured threshold of `-5.00`, then the body reads `… has exceeded -5.00% threshold` — one minus sign, not two.
- Given an SPK title containing `<b>`, when the email body is rendered, then the tag is HTML-encoded in the output.
- Given both templates, when they are loaded, then neither returns an empty string (embedded-resource registration is correct).

---

## T-04 — Release trigger

**Size:** S · **Blocked by:** T-03 · **Covers:** FR-001, FR-002

Queue the release email + in-app notifications at the end of `SpksService.ReleaseSpkAsync`, after the status change is saved, inside a try/catch that logs and swallows.

**Acceptance criteria**
- Given an approved SPK with two eligible inspectors, when it is released, then two emails are queued and two `notifications` rows are created with the SPK detail link.
- Given an SPK with no eligible inspector, when it is released, then no email is queued and a Warning names the SPK number.
- Given the mailer throws, when the SPK is released, then the SPK status is still `released` and the error is logged.
- Given an SPK that is not `approved`, when release is attempted, then it fails as before and no notification is queued.

---

## T-05 — Deviation calculator + warning job

**Size:** M · **Blocked by:** T-02, T-03 · **Covers:** FR-005, FR-006, FR-007, FR-009, FR-011, FR-013, NFR-001, NFR-004

`SpkDeviationWarningService` with the run body: candidates → one aggregate query for plan/actual sums grouped by `spk_id` → breach decision → frequency gate → send → state upsert/delete → summary. Orchestrator plus focused helpers, each ≤ 15 cognitive complexity.

**Acceptance criteria**
- Given a released SPK with schedules summing to actual 45 / plan 52 up to today and threshold −5, when the job runs, then it is in breach and a warning is sent.
- Given schedule rows dated after today, when deviation is computed, then those rows are excluded from both sums.
- Given deviation is exactly −5.00 with threshold −5.00, when the job runs, then it is in breach.
- Given an SPK with status `finished`, when the job runs, then it is not evaluated.
- Given an SPK with no schedule rows on or before today, when the job runs, then it is skipped and no state row is created.
- Given frequency `one_time` and an SPK in breach with an existing state row, when the job runs the next day, then nothing is sent.
- Given frequency `daily` and an existing row from yesterday, when the job runs, then a warning is sent and `last_notified_at` moves to today.
- Given frequency `weekly` and an existing row from 6 days ago, when the job runs, then nothing is sent; at 7 days, a warning is sent.
- Given an SPK with a state row that recovers above the threshold, when the job runs, then the row is deleted; when it later breaches again under `one_time`, then a warning is sent.
- Given one SPK's send throws, when the job runs, then the remaining SPKs are still processed and the summary reports `failed: 1`.
- Given 1,000 released SPKs, when the job runs, then the number of database round trips does not scale with the SPK count (one aggregate query, one recipient query).

---

## T-06 — Quartz registration + internal trigger endpoint

**Size:** S · **Blocked by:** T-05 · **Covers:** FR-014

Register `SpkDeviationWarningJob` durably with cron `0 0 8 * * ?`, `[DisallowConcurrentExecution]`, `RequestRecovery()`, misfire `FireAndProceed` — mirroring `ContractDepletionNotifySetup`, minus the reconciler (the cron is static here). Add `POST /api/v1/spks/internal/spk-deviation-warning` returning the run summary. Register the service in `AppServiceSetup.cs`.

**Acceptance criteria**
- Given the app starts, when Quartz initialises, then the job and its trigger exist with cron `0 0 8 * * ?`.
- Given the internal endpoint is called with no auth header, when it completes, then it returns 200 with the run summary counters.
- Given the service throws, when the endpoint is called, then it returns 500 with `Failed to run SPK deviation warning check` and the exception is logged.
- Given the service is not registered in DI, when the app starts, then this is caught before merge — verify the endpoint responds rather than throwing the "Body was inferred" startup error.
