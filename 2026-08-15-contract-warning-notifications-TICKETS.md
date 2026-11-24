# Tickets: Contract Warning Notifications

Source: [FSD](2026-08-15-contract-warning-notifications-FSD.md) (v0.1) · Coverage: 10 FRs / 7 NFRs → 6 tickets, all covered

## Summary

| ID | Title | Epic | Size | Blocked by | Covers |
|---|---|---|---|---|---|
| C-01 | Rename threshold config rows and add the frequency row `[infra]` | E1 | M | — | FR-001, NFR-002 |
| C-02 | Add the contract warning state table `[infra]` | E1 | S | — | FR-004 (schema) |
| C-03 | Evaluate both thresholds with once-per-crossing state | E2 | M | C-01, C-02 | FR-002, FR-003, FR-004, FR-005, NFR-001, NFR-002, NFR-005 |
| C-04 | Contract warning email templates and in-app notification | E2 | M | C-03 | FR-006, FR-007, NFR-004, NFR-007 |
| C-05 | Schedule the job from the frequency row | E3 | S | C-04 | FR-008 |
| C-06 | Internal run endpoint, dry-run mode, and run telemetry | E3 | M | C-04 | FR-009, FR-010, NFR-003, NFR-006 |

Build in table order. C-01 and C-02 are independent and can run in parallel.

## Epics

- **E1 — Configuration and state:** one source of truth for the thresholds, and somewhere to record what has already been warned about.
- **E2 — Detection and delivery:** decide who crossed a line, and tell them once.
- **E3 — Scheduling and rollout:** run it on a cadence, and prove what it will send before it sends.

---

## C-01: Rename threshold config rows and add the frequency row `[infra]`

- **Epic:** E1 · **Size:** M · **Priority:** Must · **Blocked by:** —
- **Covers:** FR-001, NFR-002

**Context**

The two thresholds already exist as `contracts.time_threshold` and `contracts.budget_threshold` and already drive Contract Critical through `ContractsService.ApplyCriticalThresholdsAsync`. The requirement is that the warnings and Contract Critical share these parameters, so the rows are renamed rather than duplicated ([FSD FR-001](2026-08-15-contract-warning-notifications-FSD.md#fr-001-threshold-configuration-rows)).

**Scope of work**

- Rename the two `custom_configurations` rows to `contracts.warning_time_remaining` and `contracts.warning_remaining_available_value`, preserving their current values.
- Update `ContractsService`'s `ContractBudgetThresholdConfigName` / `ContractTimeThresholdConfigName` constants and the item keys `ApplyCriticalThresholdsAsync` reads, so Contract Critical follows the rename in the same change.
- Add the `contracts.warning_reminder_frequency` row with `detail` `[{"key":"warning_reminder_frequency","value":"daily"}]`.
- Keep the reader tolerant: a missing row, malformed `detail`, or out-of-range value falls back to the documented default and logs a warning rather than throwing.
- Write the data migration as self-contained statements — literal GUIDs, inline subqueries, no `DECLARE`, no `GO` — so it runs in a JDBC client. Hand-trim the spurious `permission_groups` / `TempId` diff from the generated migration.

**Acceptance criteria**

- Given the migration has run, When Contract Monitoring loads Contract Critical, Then it reads the renamed rows and its colouring is unchanged from before the migration.
- Given `contracts.warning_time_remaining` is deleted, When Contract Critical loads, Then it falls back to 90 and logs a warning.
- Given `contracts.warning_remaining_available_value` contains `"abc"`, When it is read, Then the default 20.0 is used and a warning is logged.
- Given the migration is run twice, When it completes, Then the rows are correct both times.

**Out of scope**

A dedicated settings API. Custom Config CRUD already reads and writes these rows; a second write path would defeat the single-source-of-truth goal this ticket exists to protect.

**Test notes**

Verify Contract Critical **before and after** the migration and compare output — this ticket's whole risk is that the rename lands in the data but not in the code, or vice versa, silently resetting the dashboard to defaults. Confirm the `detail` shape matches what `CustomConfigsByNamesAsync` and `ReadThreshold` already parse: a different JSON shape parses to nothing and falls back to defaults without any error.

---

## C-02: Add the contract warning state table `[infra]`

- **Epic:** E1 · **Size:** S · **Priority:** Must · **Blocked by:** —
- **Covers:** FR-004 (schema)

**Context**

Warnings fire once per crossing, which needs a record of what has already been sent ([FSD §5](2026-08-15-contract-warning-notifications-FSD.md#5-data-model)).

**Scope of work**

- Add `contract_warning_states` with the columns and the unique index on `(contract_id, warning_type)` from FSD §5, with an `ON DELETE CASCADE` FK to `contracts`.
- Add the EF entity and `DbSet`.
- Hand-trim the migration.

**Acceptance criteria**

- Given a fresh database, When the migration is applied, Then the table and its unique index exist and no unrelated schema change is included.
- Given a contract is hard-deleted, When the delete commits, Then its warning state rows are removed by the cascade.
- Given two rows with the same `(contract_id, warning_type)`, When the second insert runs, Then it is rejected by the unique index.

**Out of scope**

Any read or write of the table — that is C-03.

**Test notes**

Check the column types against the dev database rather than trusting the model; this project has a documented history of dev-vs-model type drift.

---

## C-03: Evaluate both thresholds with once-per-crossing state

- **Epic:** E2 · **Size:** M · **Priority:** Must · **Blocked by:** C-01, C-02
- **Covers:** FR-002, FR-003, FR-004, FR-005, NFR-001, NFR-002, NFR-005

**Context**

The core of the feature: scan active contracts, compare against both thresholds, and decide which crossings are new ([FSD FR-002](2026-08-15-contract-warning-notifications-FSD.md#fr-002-contract-time-remaining-warning) through [FR-005](2026-08-15-contract-warning-notifications-FSD.md#fr-005-contract-scope-and-recipients)).

**Scope of work**

- Add `ContractWarningService` with the scope filter from FR-005: not deleted, status approved, `start_date ≤ today ≤ contract_end_date`, `contract_value > 0`. **Do not apply the department filter** — `deptContext` is request-scoped and empty in a job, so including it matches nothing.
- Extract the `remainingDays` and `valuePercentage` calculations into one shared helper used by both this service and `GetContractCriticalAsync`, so the two cannot drift (NFR-002).
- Implement the four-row state table from FR-004, writing the state row only after the email is queued successfully.
- Resolve recipients from `contract_pics` with the eligibility predicate `SendContractValueDepletionWarningNotificationAsync` already uses.
- Skip contracts with no eligible PIC without writing a state row, and log them.
- Load contracts, PICs, and state rows in a bounded set of queries — no per-contract access (NFR-001).
- Keep each method at cognitive complexity ≤ 15 by splitting into `LoadSettings`, `EvaluateContracts`, `ApplyWarningState`, `ResolveRecipients`.

**Acceptance criteria**

- Given threshold 2 and a contract ending 10 June, When the run executes on 8 June, Then the time condition holds; When it executes on 7 June, Then it does not.
- Given threshold 12.25 and a contract at exactly 12.25%, When the run executes, Then the value condition holds; at 12.26% it does not.
- Given a contract whose `spk_value` exceeds `contract_value`, When the run executes, Then the percentage is 0 and the condition holds.
- Given a first crossing, When the run executes, Then one state row is created; on the next run with the condition still true, no email is queued.
- Given an amendment clears the condition, When the run executes, Then the state row is deleted; when the contract crosses again, an email is queued again.
- Given queueing throws, When the run executes, Then no state row is written.
- Given a contract with status `draft` inside the threshold, When the run executes, Then no warning is raised.
- Given the job runs with no user context, When contracts are queried, Then contracts from all departments are evaluated.
- Given a contract with no eligible PIC crosses, When the run executes, Then no state row is written and a warning is logged.

**Out of scope**

Email templates and the in-app notification (C-04); scheduling (C-05).

**Test notes**

Test the department filter explicitly by running the service outside a request scope and asserting a non-zero contract count — this is the failure mode that looks exactly like "nothing is due" and would otherwise ship silently. Test both threshold boundaries at the exact value: `≤` is required, and the value comparison must happen **after** rounding to 2 decimals so it matches the dashboard.

---

## C-04: Contract warning email templates and in-app notification

- **Epic:** E2 · **Size:** M · **Priority:** Must · **Blocked by:** C-03
- **Covers:** FR-006, FR-007, NFR-004, NFR-007

**Context**

Two templates with copy specified verbatim in [FSD FR-006](2026-08-15-contract-warning-notifications-FSD.md#fr-006-email-content). The copy is English while the existing contract templates are Indonesian — that is intended, not an oversight.

**Scope of work**

- Add `EmailContractTimeRemainingWarning.html` and `EmailContractRemainingValueWarning.html` with the specified copy, subjects, and a CTA button to the contract detail page.
- Register `Subject_`/`HtmlBody_`/`TemplateName_` constants on `PhantomEmailTemplates` so `EmailTemplateCatalog` discovers both by reflection.
- Map placeholders per the FR-006 table. Note `threshold_percentage` is the **configured threshold**, not the contract's actual percentage — the copy reads "X% or less".
- Use `contract_title`, falling back to `contract_no`, then the contract id.
- HTML-escape all contract-derived text.
- Add any new placeholder keys to `EmailTemplateCatalog.SampleValues`.
- Stage one in-app notification per queued email through `INotificationDispatcher`, committed once per run.

**Acceptance criteria**

- Given a time crossing, When the email is composed, Then the subject is exactly `Contract Remaining Time Below Threshold` and the body names the contract and its end date in `dd-MM-yyyy`.
- Given a value crossing with threshold 12.25, When the email is composed, Then the body reads `has 12.25% or less remaining value`.
- Given a contract title containing HTML, When the email is composed, Then the markup is escaped.
- Given a contract with an empty title, When the email is composed, Then the contract number is used.
- Given an email is queued, When the run commits, Then one in-app notification exists for that recipient linking to the contract detail page.
- Given `EmailTemplateTester` runs, When it inspects both templates, Then no unsupported placeholders are reported.

**Out of scope**

Translating the copy to Indonesian, or changing the existing depletion warning's copy.

**Test notes**

Render both in a real mail client. The existing templates carry Outlook conditional comments and a CTA button that works in a browser can collapse in Outlook. Confirm `threshold_percentage` shows the configured number — using the contract's actual percentage here reads plausibly and would pass a careless review.

---

## C-05: Schedule the job from the frequency row

- **Epic:** E3 · **Size:** S · **Priority:** Must · **Blocked by:** C-04
- **Covers:** FR-008

**Context**

Same shape as the existing `ContractDepletionNotifySchedule` and its startup reconciler, for the same reason: without the reconciler, a wiped Quartz store leaves the config row claiming a schedule while nothing is armed ([FSD FR-008](2026-08-15-contract-warning-notifications-FSD.md#fr-008-scheduled-evaluation)).

**Scope of work**

- Register `ContractWarningJob` durably with `[DisallowConcurrentExecution]` and no static trigger.
- Add a schedule helper mapping `daily` → `0 0 8 * * ?` and `weekly` → `0 0 8 ? * MON`, plus a startup reconciler that arms the trigger from `contracts.warning_reminder_frequency`.
- Leave the trigger unset and log the value when the frequency is unrecognised.
- Re-apply the trigger when the frequency row is updated.
- Register the service in `AppServiceSetup.cs`.

**Acceptance criteria**

- Given frequency `daily`, When the application starts, Then the trigger is armed at 08:00 daily.
- Given frequency `hourly`, When the application starts, Then no trigger is armed and the unusable value is logged.
- Given a wiped Quartz store and a valid frequency row, When the application starts, Then the trigger is re-armed.
- Given the frequency row changes from `daily` to `weekly`, When it is saved, Then the trigger is rescheduled.

**Out of scope**

Per-contract schedules — the cadence is organisation-wide.

**Test notes**

The Quartz store is shared with the deployed dev environment: a trigger armed from a local run appears in dev. Test through the C-06 endpoint rather than by arming triggers locally, and confirm the job is registered exactly once.

---

## C-06: Internal run endpoint, dry-run mode, and run telemetry

- **Epic:** E3 · **Size:** M · **Priority:** Must · **Blocked by:** C-04
- **Covers:** FR-009, FR-010, NFR-003, NFR-006

**Context**

The dry run answers the volume question before anyone's inbox does: a 90-day default time threshold means every contract ending within 90 days fires on the first live run ([FSD FR-009](2026-08-15-contract-warning-notifications-FSD.md#fr-009-internal-run-trigger), [FR-010](2026-08-15-contract-warning-notifications-FSD.md#fr-010-run-observability)).

**Scope of work**

- Add `POST /api/v1/contracts/internal/warning-notification?dryRun=` to the internal route group, following the existing internal reminder endpoints.
- Dry run evaluates and reports but queues no email, stages no notification, and writes no state row.
- Return the summary shape in FSD §6.
- Return 409 `RUN_IN_PROGRESS` when a run is already executing.
- Emit the FR-010 structured summary line every run, including `contracts_evaluated`, plus a warning line per undeliverable warning.
- Wrap per-contract composition so one failure is logged with the contract number and does not abort the run.
- Confirm the internal route group is not published through the public ingress, and record where that was verified.

**Acceptance criteria**

- Given contracts over threshold, When the endpoint is called, Then emails are queued and the counts are reported.
- Given `dryRun=true`, When the endpoint is called, Then nothing is sent, no state row is written, and the counts show what would have fired.
- Given a run in progress, When the endpoint is called, Then the response is 409 `RUN_IN_PROGRESS`.
- Given a completed run, When the log is inspected, Then one summary line contains every counter including `contracts_evaluated`.
- Given one contract throws during composition, When the run completes, Then the others still sent and the failure is logged with the contract number.

**Out of scope**

An alerting rule for "no run in 48h" — that lives in monitoring configuration.

**Test notes**

Run against a copy of dev data with the production threshold values and read `conditions_met` before arming the schedule. A `contracts_evaluated` of zero means the department filter leaked in (C-03), not that no contracts are due — treat zero as a bug until proven otherwise.

---

## Coverage check

| FR / NFR | Covered by |
|---|---|
| FR-001 | C-01 |
| FR-002 | C-03 |
| FR-003 | C-03 |
| FR-004 | C-02, C-03 |
| FR-005 | C-03 |
| FR-006 | C-04 |
| FR-007 | C-04 |
| FR-008 | C-05 |
| FR-009 | C-06 |
| FR-010 | C-06 |
| NFR-001 | C-03 |
| NFR-002 | C-01, C-03 |
| NFR-003 | C-06 |
| NFR-004 | C-04 |
| NFR-005 | C-03 |
| NFR-006 | C-06 |
| NFR-007 | C-04 |

All 10 FRs and 7 NFRs are covered by at least one ticket.
