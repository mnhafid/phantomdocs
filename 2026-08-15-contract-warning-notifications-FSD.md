# FSD: Contract Warning Notifications

| | |
|---|---|
| **Status** | Draft |
| **Related PRD** | [PRD](2026-08-15-contract-warning-notifications-PRD.md) |
| **Date** | 2026-08-15 |
| **Version** | 0.1 |

## 1. System Overview

One durable Quartz job (`ContractWarningJob`) evaluates every active contract against two thresholds read from Custom Config, and emails the contract's PICs once per threshold crossing.

```
  Quartz (frequency from                ┌──────────────────────────────────────┐
  contracts.warning_reminder_frequency) │ 1. Load 3 config rows                │
            or POST /internal      ───▶ │    time_remaining, remaining_value,  │
                                        │    reminder_frequency                │
                                        └──────────────┬───────────────────────┘
                                                       ▼
                                        ┌──────────────────────────────────────┐
                                        │ 2. Scan active contracts             │
                                        │    remainingDays = end − today       │
                                        │    valuePct = (value−spk)/value×100  │
                                        │    NO department filter              │
                                        └──────────────┬───────────────────────┘
                                                       ▼
                                        ┌──────────────────────────────────────┐
                                        │ 3. contract_warning_states           │
                                        │    over threshold + no row → send    │
                                        │    over threshold + row   → skip     │
                                        │    under threshold + row  → delete   │
                                        └──────────────┬───────────────────────┘
                                                       ▼
                                     one email per (contract, PIC) + in-app row
```

The same two threshold rows are read by `ContractsService.ApplyCriticalThresholdsAsync`, so Contract Critical in Contract Monitoring and these emails are driven by one set of numbers.

## 2. Scope

**In scope:** the two threshold detections, once-per-crossing state, recipient resolution to Contract PICs, the two email templates, the in-app notification, the scheduled job and its internal trigger, and repointing Contract Critical at the renamed config rows.

**Out of scope:** the existing `ContractDepletionNotifyJob` pipeline, which continues unchanged; per-contract overrides; `work_end_date`; a dedicated settings API (Custom Config CRUD already covers it); repeat nudges.

## 3. User Flows

### Flow A — time warning (US-01)

1. `contracts.warning_time_remaining` is set to 2. Contract `C` ends on 10 June.
2. Runs on 6 and 7 June compute `remainingDays` of 4 and 3 — above the threshold, so nothing happens and no state row exists.
3. The run on 8 June computes `remainingDays = 2`, which is `≤ 2`. No `contract_warning_states` row exists for `(C, time_remaining)`, so this is a crossing.
4. The job resolves `C`'s PICs from `contract_pics`, queues one email each, stages one in-app notification each, and writes the state row.
5. Runs on 9 and 10 June see the state row and send nothing.
6. An amendment extends `C` to 30 September. The next run computes `remainingDays` well above 2, deletes the state row, and `C` is re-armed for its next approach.

### Flow B — value warning (US-02)

1. `contracts.warning_remaining_available_value` is set to 12.25. Contract `C` has `contract_value` 1,000,000 and `spk_value` 870,000 → 13.00% remaining. Above threshold; nothing sent.
2. A new SPK takes `spk_value` to 877,500 → exactly 12.25%. The comparison is `≤`, so this is a crossing and the email goes out.
3. Further SPKs push it to 5% — the state row already exists, so nothing more is sent.
4. An amendment raises `contract_value`, taking the percentage back above 12.25. The state row is deleted and `C` is re-armed.

### Flow C — administrator retunes the thresholds (US-04, US-05)

1. Administrator opens Custom Config and edits `contracts.warning_time_remaining` from 2 to 30.
2. The next Contract Monitoring page load reads the same row, so Contract Critical's colouring changes in step with the warnings.
3. The next job run treats every contract within 30 days as crossed. Contracts that had no state row send immediately — this is the R4 volume risk, and the reason for the Phase 0 dry run.

## 4. Functional Requirements

### FR-001: Threshold configuration rows

- **Traces to:** G3, G5 / US-04, US-05
- **Priority:** Must
- **Description:** The system shall read both thresholds and the evaluation frequency from three Custom Config rows, and Contract Critical shall read the same two threshold rows.
- **Trigger / Input:** Every job run, and every `GetContractCriticalAsync` call.
- **Behavior:**

  | Row name | Item key | Type | Default | Consumed by |
  |---|---|---|---|---|
  | `contracts.warning_time_remaining` | `warning_time_remaining` | integer days, 1–3650 | 90 | This job + `ApplyCriticalThresholdsAsync` (`TimeThreshold`) |
  | `contracts.warning_remaining_available_value` | `warning_remaining_available_value` | decimal percent, 0–100 | 20.0 | This job + `ApplyCriticalThresholdsAsync` (`BudgetThreshold`) |
  | `contracts.warning_reminder_frequency` | `warning_reminder_frequency` | string, `daily` or `weekly` | `daily` | The Quartz trigger |

  `detail` uses the existing `[{ "key": ..., "value": ... }]` shape that `CustomConfigsByNamesAsync` and `ReadThreshold` already parse. The previous rows `contracts.time_threshold` and `contracts.budget_threshold` are renamed to the first two names by data migration, and `ApplyCriticalThresholdsAsync` is updated to the new names in the same change (A1).
- **Validation & Errors:** A missing row, malformed `detail`, or out-of-range value falls back to the default and logs a warning. The job never fails because configuration is bad — silence would be indistinguishable from "nothing is due".
- **Edge cases:** An unrecognised frequency leaves the trigger unset; the reconciler logs it explicitly rather than assuming a default schedule.
- **Acceptance criteria:**
  - Given the three rows exist with valid values, When a run starts, Then it uses those values.
  - Given `contracts.warning_time_remaining` is absent, When a run starts, Then it uses 90 and logs a warning.
  - Given the rows are renamed, When Contract Monitoring loads Contract Critical, Then it uses the same values the job used.
  - Given `contracts.warning_remaining_available_value` contains `"abc"`, When a run starts, Then it uses 20.0 and logs a warning.

### FR-002: Contract time-remaining warning

- **Traces to:** G1 / US-01
- **Priority:** Must
- **Description:** The system shall raise a time warning for a contract whose remaining days have fallen to the configured threshold or below.
- **Trigger / Input:** Each evaluation run.
- **Behavior:** For each in-scope contract (FR-005), `remainingDays = max(0, contract_end_date − today)`. A warning condition holds when `remainingDays ≤ warning_time_remaining`. Whether that condition produces an email is decided by FR-004.

  Worked example from the specification: threshold 2, `contract_end_date` 10 June → `remainingDays` reaches 2 on 8 June, so the warning fires on 8 June.
- **Validation & Errors:** A contract with a null or malformed end date is skipped and counted in the run summary.
- **Edge cases:**
  - A contract already past its end date is out of scope (FR-005 requires `contract_end_date ≥ today`), so no warning is sent for an expired contract.
  - `remainingDays = 0` (ends today) satisfies the condition for any threshold ≥ 0.
- **Acceptance criteria:**
  - Given threshold 2 and a contract ending 10 June, When the run executes on 8 June, Then the warning condition holds.
  - Given threshold 2 and a contract ending 10 June, When the run executes on 7 June, Then the condition does not hold.
  - Given a contract ending today, When the run executes, Then the condition holds.
  - Given a contract that ended yesterday, When the run executes, Then it is out of scope and no warning is raised.

### FR-003: Contract remaining-value warning

- **Traces to:** G2 / US-02
- **Priority:** Must
- **Description:** The system shall raise a value warning for a contract whose remaining value percentage has fallen to the configured threshold or below.
- **Trigger / Input:** Each evaluation run.
- **Behavior:** `valuePercentage = round(max(0, (contract_value − spk_value) / contract_value × 100), 2)` — identical to `GetContractCriticalAsync`'s calculation, including the 2-decimal rounding, so the two surfaces cannot disagree (A6). The condition holds when `valuePercentage ≤ warning_remaining_available_value`.

  Worked example: threshold 12.25 → a contract at exactly 12.25% fires; at 12.26% it does not.
- **Validation & Errors:** A contract with `contract_value ≤ 0` is out of scope (FR-005), so no division by zero is possible.
- **Edge cases:**
  - `spk_value` exceeding `contract_value` clamps the percentage to 0, which satisfies any threshold.
  - The comparison happens after rounding to 2 decimals, matching the dashboard exactly; comparing unrounded values would fire on contracts the dashboard shows as above threshold.
- **Acceptance criteria:**
  - Given threshold 12.25 and a contract at exactly 12.25%, When the run executes, Then the condition holds.
  - Given threshold 12.25 and a contract at 12.26%, When the run executes, Then the condition does not hold.
  - Given a contract whose `spk_value` exceeds `contract_value`, When the run executes, Then the percentage is 0 and the condition holds.
  - Given the same contract, When Contract Critical is loaded, Then it displays the same percentage the warning used.

### FR-004: Once-per-crossing state

- **Traces to:** G4
- **Priority:** Must
- **Description:** The system shall send each warning type at most once per contract per crossing, and re-arm the contract when the condition clears.
- **Trigger / Input:** Every run, after FR-002 and FR-003 evaluate.
- **Behavior:**

  | Condition holds? | `contract_warning_states` row exists? | Action |
  |---|---|---|
  | Yes | No | Send, then insert the row with `triggered_at` and `notified_at` |
  | Yes | Yes | Send nothing |
  | No | Yes | Delete the row (re-arm) |
  | No | No | Nothing |

  State is per `(contract_id, warning_type)`, where `warning_type` is `time_remaining` or `remaining_value`, so the two warnings arm and clear independently.
- **Validation & Errors:** The row is written only after the email is successfully queued. If queueing throws, no row is written, so the next run retries rather than losing the warning permanently.
- **Edge cases:**
  - Lowering a threshold can clear a condition and delete state; raising it later re-fires. This is correct — the administrator changed the policy.
  - Concurrency: `[DisallowConcurrentExecution]` on the job prevents two runs racing on the same contract.
  - A contract deleted from the database leaves an orphan row, removed by the FK cascade.
- **Acceptance criteria:**
  - Given a contract crossing the time threshold for the first time, When the run executes, Then one email is queued and one state row is created.
  - Given the same contract on the next run with the condition still true, When the run executes, Then no email is queued.
  - Given the contract is amended so the condition is false, When the run executes, Then the state row is deleted.
  - Given the contract later crosses again, When the run executes, Then an email is queued again.
  - Given queueing the email throws, When the run executes, Then no state row is written and the next run retries.
  - Given a contract over both thresholds, When the run executes, Then two emails are queued and two state rows are created.

### FR-005: Contract scope and recipients

- **Traces to:** G1, G2 / US-03
- **Priority:** Must
- **Description:** The system shall evaluate only active contracts, and shall send each warning to that contract's PICs.
- **Behavior:** A contract is in scope when **all** hold:

  | # | Condition |
  |---|---|
  | 1 | `deleted_at IS NULL` |
  | 2 | `status` matches `approved` (`ContractConstant.StatusApproved`) |
  | 3 | `start_date ≤ today ≤ contract_end_date` |
  | 4 | `contract_value > 0` |

  This mirrors `GetContractCriticalAsync`'s filter **minus the department filter**. `deptContext.ActiveDepartments` is request-scoped and empty in a background job; including it would silently match nothing (A5, R1).

  Recipients are the contract's `contract_pics`, joined to `users`, where the PIC row and the user are non-deleted, the user's status is null or `active`, and the email is non-empty — the same predicate `SendContractValueDepletionWarningNotificationAsync` uses. Each PIC receives their own personalised email (A4).
- **Validation & Errors:** A contract with no eligible PIC produces no email; the run logs `[ContractWarning] Contract {ContractNo} has no PIC — {Type} warning undeliverable` and **does not** write the state row, so the warning is not consumed by a send that never happened.
- **Edge cases:** A contract with three PICs produces three emails and one state row.
- **Acceptance criteria:**
  - Given a contract with status `draft` inside the time threshold, When the run executes, Then no warning is raised.
  - Given a contract whose `start_date` is in the future, When the run executes, Then it is out of scope.
  - Given a contract with `contract_value = 0`, When the run executes, Then it is out of scope and no division occurs.
  - Given the job runs with no user context, When contracts are queried, Then no department filter is applied and contracts across all departments are evaluated.
  - Given a contract with two eligible PICs, When it crosses a threshold, Then two emails are queued and one state row is written.
  - Given a contract with no eligible PIC, When it crosses a threshold, Then no state row is written and a warning is logged.

### FR-006: Email content

- **Traces to:** US-01, US-02, US-03
- **Priority:** Must
- **Description:** The system shall send one email per contract per recipient, using the specified copy.
- **Behavior:** Two new templates in `Logics/Services/Email/Templates`, registered as `Subject_`/`HtmlBody_`/`TemplateName_` pairs on `PhantomEmailTemplates` so `EmailTemplateCatalog` discovers them.

  **Time warning** — `EmailContractTimeRemainingWarning.html`
  Subject: `Contract Remaining Time Below Threshold`

  > Hello, `{fullname}`
  >
  > This Contract, `{contract_name}` is about to end at `{contract_end_date}`
  >
  > \[CTA button → `{contract_url}`\]
  >
  > Please do not reply this email with your password.
  > We will never ask for your password, and we strongly discourage you from sharing it to anyone.
  >
  > Thanks,
  > The Phantom Team

  **Value warning** — `EmailContractRemainingValueWarning.html`
  Subject: `Contract Remaining Value Below Threshold`

  > Hello, `{fullname}`
  >
  > This Contract, `{contract_name}` has `{threshold_percentage}`% or less remaining value.
  >
  > \[CTA button → `{contract_url}`\]
  >
  > Please do not reply this email with your password.
  > We will never ask for your password, and we strongly discourage you from sharing it to anyone.
  >
  > Thanks,
  > The Phantom Team

  Placeholder mapping:

  | Placeholder | Source |
  |---|---|
  | `fullname` | The recipient PIC's `users.full_name` |
  | `contract_name` | `contracts.contract_title`, falling back to `contract_no` when empty (A2) |
  | `contract_end_date` | `contracts.contract_end_date`, formatted `dd-MM-yyyy` (A3) |
  | `threshold_percentage` | The configured `warning_remaining_available_value`, not the contract's actual percentage — the copy says "X% or less" |
  | `contract_url` | `{AppSettingsConfig:WebBaseUrl}/contracts/{contractId}/detail` |

- **Validation & Errors:** `contract_name` is HTML-escaped before rendering; it is user-entered text.
- **Edge cases:** A contract with neither title nor number renders the contract id, so the email is never about an unnamed thing.
- **Acceptance criteria:**
  - Given a time crossing, When the email is composed, Then the subject is exactly `Contract Remaining Time Below Threshold` and the body names the contract and its end date.
  - Given a value crossing with threshold 12.25, When the email is composed, Then the body reads `has 12.25% or less remaining value`.
  - Given a contract whose title contains HTML, When the email is composed, Then the markup is escaped.
  - Given a contract with an empty title, When the email is composed, Then the contract number is used.
  - Given `EmailTemplateTester` runs, When it inspects both templates, Then no unsupported placeholders are reported.

### FR-007: In-app notification

- **Traces to:** US-06
- **Priority:** Should
- **Description:** The system shall write one in-app notification per queued email.
- **Behavior:** Staged through `INotificationDispatcher` with the same `contract_url` and placeholder values, following `SendContractValueDepletionWarningNotificationAsync`'s pattern, and committed once per run.
- **Acceptance criteria:**
  - Given an email is queued, When the run commits, Then one notification row exists for that user linking to the contract detail page.
  - Given no email is queued for a contract, Then no notification row is created for it.

### FR-008: Scheduled evaluation

- **Traces to:** G1, G2
- **Priority:** Must
- **Description:** The system shall run the evaluation on the configured frequency.
- **Behavior:** `ContractWarningJob` is registered durably with no static trigger; the trigger is applied from `contracts.warning_reminder_frequency` at startup by a reconciler and re-applied whenever the row changes. This mirrors `ContractDepletionNotifySchedule` and `ContractDepletionNotifyReconciler` exactly, including the reason for the reconciler: without it a wiped Quartz store leaves the config row claiming a schedule while nothing is armed.

  | Frequency | Cron |
  |---|---|
  | `daily` | `0 0 8 * * ?` |
  | `weekly` | `0 0 8 ? * MON` |
- **Validation & Errors:** An unrecognised frequency leaves the trigger unset and logs it at startup.
- **Edge cases:** The Quartz store is shared with the deployed dev environment, so a locally armed trigger appears in dev. Developers use the internal endpoint instead.
- **Acceptance criteria:**
  - Given frequency `daily`, When the application starts, Then the trigger is armed at 08:00 daily.
  - Given frequency `hourly` (unsupported), When the application starts, Then no trigger is armed and a log line names the unusable value.
  - Given a wiped Quartz store and a valid frequency row, When the application starts, Then the trigger is re-armed.

### FR-009: Internal run trigger

- **Traces to:** G1, G2
- **Priority:** Must
- **Description:** The system shall expose an internal endpoint that runs the evaluation on demand, with a dry-run mode.
- **Behavior:** `POST /api/v1/contracts/internal/warning-notification?dryRun=`. Dry run evaluates and reports without queueing email, staging notifications, or writing state. The response reports contracts evaluated, conditions met by type, emails queued, and undeliverable counts (FR-010).
- **Validation & Errors:** 409 `RUN_IN_PROGRESS` when a run is already executing.
- **Acceptance criteria:**
  - Given contracts over threshold, When the endpoint is called, Then emails are queued and counts are reported.
  - Given `dryRun=true`, When the endpoint is called, Then nothing is sent, no state row is written, and the counts show what would have fired.
  - Given a run in progress, When the endpoint is called, Then the response is 409 `RUN_IN_PROGRESS`.

### FR-010: Run observability

- **Traces to:** R1, R4
- **Priority:** Must
- **Description:** The system shall emit one structured summary line per run.
- **Behavior:** Reports mode, duration, contracts evaluated, conditions met per warning type, state rows inserted and deleted, emails queued, recipients, and undeliverable warnings. A per-contract failure is logged with the contract number and does not abort the run.
- **Acceptance criteria:**
  - Given a completed run, When the log is inspected, Then one line contains every counter, including contracts evaluated — the counter that makes the R1 department-filter failure visible.
  - Given one contract throws during composition, When the run completes, Then the others still sent and the failure is logged with the contract number.

## 5. Data Model

### New table: `contract_warning_states`

| Column | Type | Constraints |
|---|---|---|
| `id` | `uniqueidentifier` | PK |
| `contract_id` | `uniqueidentifier` | NOT NULL, FK → `contracts(contract_id)` ON DELETE CASCADE |
| `warning_type` | `varchar(30)` | NOT NULL, one of `time_remaining`, `remaining_value` |
| `triggered_at` | `datetime2` | NOT NULL |
| `notified_at` | `datetime2` | NULL |

Unique index on `(contract_id, warning_type)`. Transient working state, deleted when the condition clears; bounded by the number of contracts currently over threshold. No PII.

### Modified: `custom_configurations`

Renamed by migration:

| Before | After |
|---|---|
| `contracts.time_threshold` | `contracts.warning_time_remaining` |
| `contracts.budget_threshold` | `contracts.warning_remaining_available_value` |

Added:

```
name        = 'contracts.warning_reminder_frequency'
description = 'Evaluation cadence for contract warning notifications'
detail      = '[{"key":"warning_reminder_frequency","value":"daily"}]'
```

Write these as self-contained statements with literal GUIDs and no `DECLARE`/`GO`, so they run in a JDBC client.

### Read-only dependencies

`contracts` (`contract_id`, `contract_no`, `contract_title`, `contract_end_date`, `start_date`, `contract_value`, `spk_value`, `status`, `deleted_at`), `contract_pics`, `users`.

### Unchanged

`contract_value_depletion_warning_notifications` and `ds_contract_warning_dates` keep driving the existing depletion pipeline, which this feature does not touch.

## 6. Interfaces

### `POST /api/v1/contracts/internal/warning-notification?dryRun=false`

Internal route group, no bearer, matching the existing internal reminder endpoints. Not published through the public ingress (NFR-003).

```json
{
  "data": {
    "dry_run": false,
    "contracts_evaluated": 214,
    "conditions_met": { "time_remaining": 6, "remaining_value": 3 },
    "state_rows_inserted": 5,
    "state_rows_deleted": 2,
    "emails_queued": 7,
    "undeliverable": 1,
    "duration_ms": 840
  },
  "process_time": "840.2210ms",
  "status": "success",
  "code": "00",
  "message": "send contract warning notification succeed"
}
```

Errors: 409 `RUN_IN_PROGRESS`.

### Configuration

No new configuration endpoints. The three rows are read and written through the existing Custom Config CRUD: `GET /api/v1/custom-configurations`, `GET /api/v1/custom-configurations/name/{name}`, `POST /api/v1/custom-configurations/{id}/update`.

### Events and integrations

Outbound only: `IMailerService.QueueSend` and `INotificationDispatcher`. Nothing consumed, nothing third-party.

## 7. Non-Functional Requirements

### NFR-001: Run performance
- **Requirement:** A run over 5,000 contracts completes in under 30 seconds, loading contracts, PICs, and state rows in a bounded number of set-based queries rather than per contract.
- **Traces to:** G1, G2

### NFR-002: Threshold parity
- **Requirement:** The remaining-value percentage and remaining-day calculations are shared with Contract Critical — one implementation, used by both — so the two can never diverge through a copy that drifted.
- **Traces to:** G3

### NFR-003: Internal endpoint exposure
- **Requirement:** The internal run endpoint is reachable only inside the deployment network and is not published through the public ingress.
- **Traces to:** G4

### NFR-004: Email content safety
- **Requirement:** All contract-derived text is HTML-escaped before rendering.
- **Traces to:** G4

### NFR-005: Cognitive complexity
- **Requirement:** Every method added has cognitive complexity ≤ 15, per `CLAUDE.md`. The job is an orchestrator over `LoadSettings`, `EvaluateContracts`, `ApplyWarningState`, `ResolveRecipients`, `ComposeEmail`.
- **Traces to:** G5

### NFR-006: Observability
- **Requirement:** One structured summary line per run including `contracts_evaluated`, plus a warning line per undeliverable warning. No summary line for 48 hours is an alertable condition.
- **Traces to:** R1, R4

### NFR-007: Language
- **Requirement:** Both templates use the English copy specified in FR-006 verbatim. Log lines and error codes stay in English. This makes the contract mailbox bilingual alongside the existing Indonesian templates — a deliberate, recorded consequence.
- **Traces to:** US-01, US-02

## 8. Permissions & Roles

| Action | Contract PIC | Contract Admin | System Admin |
|---|---|---|---|
| Receive warnings for own contracts | ✅ | — | — |
| Read the three config rows | ✅ | ✅ | ✅ |
| Write the three config rows | ❌ | ✅ | ✅ |
| Call the internal run endpoint | ❌ | ❌ | ✅ (network-restricted) |

**Decided 2026-08-15: reuse the existing Custom Config permission, add nothing.** Because the three rows are written through the existing Custom Config CRUD endpoints, they are already gated by the `RbacRouteMaps` entries for that module — `("POST", "/api/v1/custom-configurations/{id}/update") → (obj 17, act 129)` for writes, and the `/api/v1/custom-configurations` read root (act 128) for reads. This feature adds no permission key and no route-map entry.

The internal run endpoint registers on a separate unfiltered `/api/v1` group, following `ProjectTaskNotificationsEndpoint`'s `internal_` group — not `AllowAnonymous`, which `R3ComponentFilter` ignores.

## 9. Analytics & Telemetry

| Event | Properties | When fired | Measures |
|---|---|---|---|
| `contract_warning.run` | mode, durationMs, contractsEvaluated, conditionsMet, emailsQueued, undeliverable | End of every run | G4, R1 |
| `contract_warning.crossed` | contractId, warningType, remainingDays or valuePercentage, threshold | On state-row insert | G1, G2 |
| `contract_warning.rearmed` | contractId, warningType, daysSinceTriggered | On state-row delete | G4 |
| `contract_warning.threshold_changed` | rowName, oldValue, newValue | On Custom Config write | G5 |

G1 and G2 are computed by joining `contract_warning.crossed` events to contract end dates; the events are the measurement, not a proxy for it.

## 10. Traceability Matrix

| PRD Goal/Story | FRs | NFRs |
|---|---|---|
| G1 / US-01 | FR-001, FR-002, FR-004, FR-005, FR-006, FR-008, FR-009 | NFR-001, NFR-006, NFR-007 |
| G2 / US-02 | FR-001, FR-003, FR-004, FR-005, FR-006, FR-008, FR-009 | NFR-001, NFR-006, NFR-007 |
| G3 / US-05 | FR-001, FR-003 | NFR-002 |
| G4 | FR-004, FR-010 | NFR-003, NFR-004 |
| G5 / US-04 | FR-001 | NFR-005 |
| US-03 | FR-005, FR-006 | — |
| US-06 | FR-007 | — |
| R1, R4 | FR-010 | NFR-006 |

## 11. Open Questions

| # | Question | Owner | Affects |
|---|---|---|---|
| Q1 | Should the time warning also consider `work_end_date`? | Product | FR-002 — one predicate |
| Q2 | Weekly nudge after the first email? | Product | FR-004 — follow-up |
| ~~Q3~~ | ~~Is the existing Custom Config write permission the right guard for these rows?~~ **Resolved 2026-08-15: yes — reuse it, add no new permission. See §8.** | — | Closed |
