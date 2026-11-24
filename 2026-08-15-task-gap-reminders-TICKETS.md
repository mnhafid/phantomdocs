# Tickets: Project Task Gap Reminders

Source: [FSD](2026-08-15-task-gap-reminders-FSD.md) (v0.1) · Coverage: 13 FRs / 8 NFRs → 11 tickets, all covered

## Summary

| ID | Title | Epic | Size | Blocked by | Covers |
|---|---|---|---|---|---|
| T-01 | Add gap-state and reminder-schedule tables `[infra]` | E1 | M | — | FR-001 (schema), FR-009 (schema), FR-010 (schema) |
| T-02 | Track SPK/BoQ gap duration per task | E1 | M | T-01 | FR-001 |
| T-03 | Detect SPK-or-BoQ-empty findings | E1 | M | T-02 | FR-002, NFR-001 |
| T-04 | Detect SPK-not-released and no-PIC findings | E1 | M | T-01 | FR-003, FR-004 |
| T-05 | Resolve finding recipients with Project PIC fallback | E1 | S | T-03, T-04 | FR-005 |
| T-06 | Compose and queue the reminder email and in-app notification | E2 | M | T-05 | FR-006, FR-007, NFR-002, NFR-005, NFR-006, NFR-008 |
| T-07 | Evaluate per-project schedules and wire the daily Quartz job | E2 | M | T-06 | FR-008, NFR-003 |
| T-08 | Per-project reminder schedule API | E3 | S | T-01 | FR-009 |
| T-09 | Global threshold settings API | E3 | S | T-01 | FR-010 |
| T-10 | Internal run endpoint, dry-run mode, and run telemetry | E4 | M | T-07 | FR-011, FR-013, NFR-004, NFR-007 |
| T-11 | Decommission the without-SPK reminder | E4 | S | T-07 | FR-012 |

Suggested build order is the table order. T-08 and T-09 are independent of the detection chain once T-01 lands and can run in parallel with T-02…T-07.

## Epics

- **E1 — Detection:** find the four gaps correctly, and know how long each has existed.
- **E2 — Delivery:** turn findings into one email per project per recipient, on that project's cadence.
- **E3 — Configuration:** let administrators set cadence and thresholds without engineering.
- **E4 — Rollout:** run it on demand, prove what it will send before it sends, and remove what it replaces.

---

## T-01: Add gap-state and reminder-schedule tables `[infra]`

- **Epic:** E1 · **Size:** M · **Priority:** Must · **Blocked by:** —
- **Covers:** FR-001 (schema), FR-009 (schema), FR-010 (schema)

**Context**

The feature needs two small tables and one configuration row. See [FSD §5](2026-08-15-task-gap-reminders-FSD.md#5-data-model) for exact columns. Global thresholds deliberately reuse `custom_configurations` instead of adding a third table.

**Scope of work**

- Add `project_task_gap_states` and `project_task_reminder_schedules` per FSD §5, with the unique indexes on `(project_task_id, gap_type)` and `(project_id)`.
- Add matching EF entities and `DbSet`s on `PhantomDbContext`, following the shape of `ProjectTaskWithoutSpkNotification`.
- Generate the migration, then **hand-trim the spurious `permission_groups` / `TempId` diff** this repository's migration generation always sweeps in. Verify the trimmed migration applies cleanly to a fresh database.
- Seed the `custom_configurations` row `task_gap_reminder_thresholds` with `{"spkBoqEmptyDays":30,"spkNotReleasedDays":14}`. Write the seed as a self-contained `INSERT` with a literal GUID and inline subqueries — no `DECLARE`, no `GO` — so it runs in a JDBC client.

**Acceptance criteria**

- Given a fresh database, When the migration is applied, Then both tables exist with their unique indexes and no unrelated schema change is included.
- Given the seed script is run twice, When it completes, Then exactly one `task_gap_reminder_thresholds` row exists.
- Given a `project_tasks` row is hard-deleted, When the delete commits, Then its `project_task_gap_states` rows are removed by the cascade.

**Out of scope**

Dropping `project_task_without_spk_notifications` — that is T-11, one release later.

**Test notes**

Confirm `gap_type` and `frequency` are stored as the exact lowercase literals the FSD names; a case mismatch silently disables the whole feature. Check the column types against the dev database rather than assuming — this project has a documented history of dev-vs-model numeric type drift.

---

## T-02: Track SPK/BoQ gap duration per task

- **Epic:** E1 · **Size:** M · **Priority:** Must · **Blocked by:** T-01
- **Covers:** FR-001

**Context**

"Empty for N days" is a duration, not a snapshot, so the system has to remember when each gap opened. This is stage 1 of the job ([FSD FR-001](2026-08-15-task-gap-reminders-FSD.md#fr-001-gap-state-tracking)).

**Scope of work**

- Add `TaskGapReminderService.RefreshGapStatesAsync` implementing the four-row action table in FR-001.
- Scan in-scope tasks with set-based queries: one query for tasks with `spk_id IS NULL`, one left-join for tasks with no non-deleted `project_task_boqs`. No per-task queries.
- Insert rows for newly-observed gaps, leave existing rows untouched, delete rows for closed gaps and for tasks that left scope.
- Wrap the stage in a transaction; on failure, log `[TaskGapReminder] Stage 1 failed` and abort the run before any send.

**Acceptance criteria**

- Given a task with no SPK and no gap-state row, When the stage runs, Then a `spk_empty` row is created with `first_detected_at` at the run time.
- Given an open `boq_empty` row 5 days old and the BoQ still empty, When the stage runs, Then `first_detected_at` is unchanged.
- Given an open `spk_empty` row and an SPK is then linked, When the stage runs, Then the row is deleted.
- Given a task whose project moves out of `in progress`, When the stage runs, Then its gap-state rows are deleted.
- Given a gap that was closed and then reopened, When the stage runs, Then a new row is created with the current timestamp, not the original one.

**Out of scope**

Detecting `spk_not_released` and `no_pic` — those are evaluated fresh each run and never persisted (T-04).

**Test notes**

The first run after deployment must insert rows for every open gap and report zero qualifying tasks. Verify the reopen case explicitly: a gap closed and reopened restarts the clock, and a test that only covers open-and-stay-open will not catch a bug here.

---

## T-03: Detect SPK-or-BoQ-empty findings

- **Epic:** E1 · **Size:** M · **Priority:** Must · **Blocked by:** T-02
- **Covers:** FR-002, NFR-001

**Context**

The primary trigger: a task whose SPK or BoQ has been empty through the whole N1-day run-up to its start date ([FSD FR-002](2026-08-15-task-gap-reminders-FSD.md#fr-002-spk-or-boq-empty-finding)). Both conditions matter — the age filter alone would warn about tasks starting next year.

**Scope of work**

- Implement the five-condition rule from FR-002 as a single set-based query over `project_task_gap_states` joined to tasks and projects.
- Read N1 from the settings row; fall back to 30 with a warning if absent or unparsable.
- Merge a task missing both SPK and BoQ into one finding listing both, not two findings.
- Populate each finding with breakdown, description, missing field(s), `daysEmpty`, plan start date, and `isOverdue`.
- Skip tasks with a null plan start date; log one debug line with the count per run.

**Acceptance criteria**

- Given N1 = 30, a task empty 30 days, and a start date 10 days away, When detection runs, Then the task is a finding with `daysEmpty = 30`.
- Given N1 = 30 and a task empty 29 days, When detection runs, Then it is not a finding.
- Given N1 = 30, a task empty 40 days, and a start date 200 days away, When detection runs, Then it is not a finding.
- Given a task empty 40 days whose start date was 5 days ago, When detection runs, Then it is a finding with `isOverdue = true`.
- Given a task with status `finished with note` and no BoQ, When detection runs, Then it is not a finding.
- Given a task missing both SPK and BoQ, When detection runs, Then exactly one finding is produced naming both.

**Out of scope**

Recipient resolution (T-05) and email formatting (T-06). This ticket produces finding objects only.

**Test notes**

Hit the boundary at exactly N1 days and exactly N1 days of lead time — off-by-one here changes who gets emailed. Confirm NFR-001 by checking the generated SQL is a bounded number of statements, not one per task. Note that per [FSD A9](2026-08-15-task-gap-reminders-PRD.md#9-assumptions) header rows are currently **included**; if Q1 resolves to exclude them, the change is a single `data_type` predicate here and in T-04.

---

## T-04: Detect SPK-not-released and no-PIC findings

- **Epic:** E1 · **Size:** M · **Priority:** Must · **Blocked by:** T-01
- **Covers:** FR-003, FR-004

**Context**

Two window-based detections with no duration tracking ([FSD FR-003](2026-08-15-task-gap-reminders-FSD.md#fr-003-spk-not-released-finding), [FR-004](2026-08-15-task-gap-reminders-FSD.md#fr-004-task-without-pic-finding)). "Release to Vendor" maps to the existing `released` status — no new SPK status is being added.

**Scope of work**

- Implement FR-003 using the status table: findings for `draft`, `on hold`, `approved`, `canceled`; none for `released`, `finished`, `finished with note`. Read N2 from settings, default 14.
- A task with `spk_id IS NULL` belongs to T-03's detection and must never appear here.
- Log a warning when a task points at a deleted or missing SPK, and route it to the SPK-empty detection instead.
- Implement FR-004: any in-scope task with zero non-deleted `project_task_pics` rows whose user is non-deleted. No day threshold. Ignore `project_tasks.assignee` entirely.

**Acceptance criteria**

- Given N2 = 14, an SPK with status `draft`, and a start date 10 days away, When detection runs, Then the task is a finding showing status `draft`.
- Given an SPK with status `released`, When detection runs, Then the task is not a finding.
- Given an SPK with status `canceled` and a start date 3 days away, When detection runs, Then the task is a finding.
- Given N2 = 14, an SPK with status `draft`, and a start date 30 days away, When detection runs, Then the task is not a finding.
- Given a task with no `project_task_pics` rows, When detection runs, Then it is a no-PIC finding.
- Given a task whose only `project_task_pics` row is soft-deleted, When detection runs, Then it is a no-PIC finding.

**Out of scope**

Adding a `release to vendor` status to `SpkStatusConstants`. Confirmed during grilling that this is not wanted.

**Test notes**

Cover every value in `SpkStatusConstants` — a missed status here means either silent under-reporting or nuisance emails about released SPKs. Verify a task whose PIC user record is soft-deleted counts as unowned, not owned.

---

## T-05: Resolve finding recipients with Project PIC fallback

- **Epic:** E1 · **Size:** S · **Priority:** Must · **Blocked by:** T-03, T-04
- **Covers:** FR-005

**Context**

Findings are useless without an owner to send them to. Task-level findings go to Task PICs, falling back to Project PICs so PIC-less tasks are not silently dropped ([FSD FR-005](2026-08-15-task-gap-reminders-FSD.md#fr-005-recipient-resolution-and-fallback)).

**Scope of work**

- Batch-load Task PICs and Project PICs for the projects in play; no per-finding queries.
- Apply the eligibility predicate used elsewhere in this codebase: user non-deleted, status null or `active`, non-empty email.
- Fall back to Project PICs for FR-002/FR-003 findings on tasks with no eligible Task PIC. FR-004 findings always go to Project PICs.
- Deduplicate by user id so a user who is both Task PIC and Project PIC is resolved once.
- Count findings with no eligible recipient after fallback and expose the count to the run summary.

**Acceptance criteria**

- Given a task with two active Task PICs, When resolution runs, Then both users are recipients.
- Given a task with no Task PIC in a project with one Project PIC, When resolution runs for an FR-002 finding, Then the Project PIC is the recipient.
- Given a Task PIC whose user record is soft-deleted, When resolution runs, Then that user is not a recipient and the fallback applies.
- Given a user who is both the task's PIC and the project's PIC, When resolution runs, Then that user appears exactly once.
- Given a project with no Project PIC and 3 no-PIC findings, When resolution runs, Then 3 undeliverable findings are counted and one warning is logged naming the project.

**Out of scope**

Deciding which findings share an email — that grouping is T-06.

**Test notes**

The dedup case is the easy one to miss and produces visible duplicate emails. Test a project where the same person is Project PIC and Task PIC on some but not all tasks.

---

## T-06: Compose and queue the reminder email and in-app notification

- **Epic:** E2 · **Size:** M · **Priority:** Must · **Blocked by:** T-05
- **Covers:** FR-006, FR-007, NFR-002, NFR-005, NFR-006, NFR-008

**Context**

One email per (project, recipient) carrying a table of that recipient's findings — the thing the existing without-SPK reminder never did ([FSD FR-006](2026-08-15-task-gap-reminders-FSD.md#fr-006-email-composition-and-grouping)). `PhantomEmailTemplates.Render` has no loop construct, so the table body is built in code and injected as one placeholder.

**Scope of work**

- Add `EmailTaskGapReminder.html` to `Logics/Services/Email/Templates`, plus `Subject_`, `HtmlBody_`, and `TemplateName_` constants in `PhantomEmailTemplates`. Subject and body in Indonesian, matching the existing reminder templates.
- Build the findings table as an HTML string: columns Task, Missing, Empty for, Plan Start (`dd-MM-yyyy`), Status. Order by plan start ascending, overdue first. Cap at 50 rows and append `+N more task(s)` beyond that.
- HTML-escape every task-derived value before it enters the table.
- Merge FR-002 and FR-003 findings for the same (project, recipient) into one email with two labelled sections. Keep FR-004 findings in a separate email.
- Queue via `IMailerService.QueueSend` with `web_link = {AppSettingsConfig:WebBaseUrl}/projects/{projectId}/detail`.
- Stage one in-app notification per queued email through `INotificationDispatcher`, committed once per run.
- Add `task_rows` and `summary_line` to `EmailTemplateCatalog.SampleValues`.

**Acceptance criteria**

- Given a recipient with 2 SPK/BoQ findings and 1 not-released finding in one project, When composition runs, Then exactly one email is queued with both sections and 3 rows.
- Given a recipient with findings in 2 projects, When composition runs, Then 2 emails are queued.
- Given a recipient with 60 findings in one project, When composition runs, Then the email shows 50 rows and a `+10 more` line.
- Given a task description containing `<script>`, When the email is composed, Then the output contains escaped text and no live tag.
- Given an email is queued, When the run commits, Then exactly one in-app notification exists for that recipient with the project detail link.
- Given `EmailTemplateTester` runs, When it inspects the new template, Then it reports no unsupported placeholders.

**Out of scope**

Deciding whether a project sends today — that is T-07. This ticket composes whatever it is handed.

**Test notes**

Render the template in a real mail client, not just as a string: the existing templates carry Outlook conditional comments, and a hand-built table can break in Outlook while looking correct in a browser. Verify the 50-row cap with a project large enough to hit it.

---

## T-07: Evaluate per-project schedules and wire the daily Quartz job

- **Epic:** E2 · **Size:** M · **Priority:** Must · **Blocked by:** T-06
- **Covers:** FR-008, NFR-003

**Context**

Cadence is per project, but one Quartz trigger per project would be unmanageable. Instead one static daily trigger runs the job, and the job decides per project whether today is a send day ([FSD FR-008](2026-08-15-task-gap-reminders-FSD.md#fr-008-per-project-schedule-evaluation)).

**Scope of work**

- Add `TaskGapReminderJob` as a durable Quartz job with `[DisallowConcurrentExecution]` and a static daily cron trigger at 08:00, registered in a `TaskGapReminderSetup` extension following `ProjectReminderSetup`'s shape.
- Implement `IsDueToday` per the FR-008 frequency table, including the **first-send-on-Monday** rule that applies to every frequency when `last_sent_at IS NULL`.
- Treat a project with no schedule row as `weekly` and active.
- Treat a `custom` row with a null or non-positive `interval_days` as `weekly`, and log a warning.
- Stamp `last_sent_at` only when at least one email was queued for that project.
- Register the service in `AppServiceSetup.cs`.
- Keep every method at cognitive complexity ≤ 15: the job body is an orchestrator over `RefreshGapStatesAsync`, `IsDueToday`, `BuildFindings`, `ResolveRecipients`, `ComposeEmail`.

**Acceptance criteria**

- Given frequency `daily` and a prior send, When the job runs on any day, Then the project is due.
- Given frequency `weekly`, When the job runs on a Tuesday, Then the project is not due.
- Given frequency `custom` with `interval_days = 3` and `last_sent_at` 3 days ago, When the job runs, Then the project is due.
- Given frequency `one_time` with a non-null `last_sent_at`, When the job runs, Then the project is not due.
- Given no schedule row, When the job runs on a Monday, Then the project is due.
- Given `is_active = false` and frequency `daily`, When the job runs, Then the project is not due.
- Given a project that has never sent, frequency `daily`, When the job runs on a Wednesday, Then it is not due; When it runs the following Monday, Then it is due.
- Given a due project with zero findings, When the job runs, Then no email is queued and `last_sent_at` is unchanged.

**Out of scope**

The on-demand endpoint and dry-run mode (T-10).

**Test notes**

`IsDueToday` is pure logic over a date and a schedule row — cover the seven cases above as a plain unit test with an injected `TimeProvider`, no database. Remember that Quartz shares its persistent store with the deployed dev environment: do not create triggers by hand while testing, and confirm the static trigger is registered exactly once.

---

## T-08: Per-project reminder schedule API

- **Epic:** E3 · **Size:** S · **Priority:** Must · **Blocked by:** T-01
- **Covers:** FR-009

**Context**

Backs the frequency picker behind the Project page Reminder (email icon) button ([FSD FR-009](2026-08-15-task-gap-reminders-FSD.md#fr-009-per-project-reminder-schedule-api), shapes in §6).

**Scope of work**

- Add `GET` and `PUT /api/v1/projects/{projectId}/reminder-schedule` as a Carter endpoint following `ProjectRemindersEndpoint`'s structure.
- `GET` returns the stored row, or the `weekly`/active default when none exists.
- `PUT` upserts by `project_id` and clears `last_sent_at`, which re-arms a consumed `one_time` schedule.
- Validate per the FR-009 error table: `INVALID_FREQUENCY`, `INVALID_INTERVAL_DAYS`, `PROJECT_NOT_FOUND`.
- Store `interval_days` as null for any non-`custom` frequency.
- Register the service in `AppServiceSetup.cs`.

**Acceptance criteria**

- Given a project with no schedule, When `GET` is called, Then it returns `frequency = "weekly"`, `isActive = true`, `intervalDays = null`, `lastSentAt = null`.
- Given `frequency = "custom"` and `intervalDays = 3`, When `PUT` is called, Then the row is stored and `lastSentAt` is cleared.
- Given `frequency = "custom"` and `intervalDays = 0`, When `PUT` is called, Then the response is 400 `INVALID_INTERVAL_DAYS`.
- Given an unknown `projectId`, When `PUT` is called, Then the response is 404 `PROJECT_NOT_FOUND`.
- Given two concurrent `PUT`s for one project, When both complete, Then exactly one row exists.

**Out of scope**

The frontend modal. This repository is backend-only.

**Test notes**

Forgetting to register the service in `AppServiceSetup.cs` produces a startup crash with a misleading "Body was inferred" message — check startup, not just the endpoint. GUIDs projected through SQL translation come back uppercase while in-memory mapping returns lowercase; assert case-insensitively or normalise.

---

## T-09: Global threshold settings API

- **Epic:** E3 · **Size:** S · **Priority:** Must · **Blocked by:** T-01
- **Covers:** FR-010

**Context**

N1 and N2 live in one `custom_configurations` row rather than a new table ([FSD FR-010](2026-08-15-task-gap-reminders-FSD.md#fr-010-global-threshold-settings-api)).

**Scope of work**

- Add `GET` and `PUT /api/v1/settings/task-gap-reminder`, reading and writing the `task_gap_reminder_thresholds` row's `detail` JSON.
- `GET` returns 30 / 14 when the row is absent.
- Validate both values as integers in 1–365; reject with 400 `INVALID_THRESHOLD`.
- Guard the endpoints by registering them on an `/api/v1` group with `.AddEndpointFilter<R3ComponentFilter>()`, copied from `ProjectRemindersEndpoint`. **Do not add a new permission key or an `RbacRouteMaps` entry** — decided 2026-08-15; that map is only ported for Custom Configuration and the projects module is not in it.
- Tolerate malformed stored JSON: fall back to defaults and log a warning rather than throwing.

**Acceptance criteria**

- Given no settings row, When `GET` is called, Then it returns 30 and 14.
- Given `spkBoqEmptyDays = 45` and `spkNotReleasedDays = 7`, When `PUT` is called, Then the values persist and the next run uses them.
- Given `spkBoqEmptyDays = 0`, When `PUT` is called, Then the response is 400 `INVALID_THRESHOLD`.
- Given a caller without the settings permission, When `PUT` is called, Then the response is 403 `FORBIDDEN`.
- Given corrupt `detail` JSON, When a run reads the settings, Then it uses 30 / 14 and logs a warning instead of failing.

**Out of scope**

Per-project thresholds. Confirmed during grilling that N is global.

**Test notes**

The malformed-JSON path matters more than it looks: this row is hand-editable in the database, and an unhandled parse error here silently kills every reminder.

---

## T-10: Internal run endpoint, dry-run mode, and run telemetry

- **Epic:** E4 · **Size:** M · **Priority:** Must · **Blocked by:** T-07
- **Covers:** FR-011, FR-013, NFR-004, NFR-007

**Context**

The dry run is how Phase 0 measures the G1/G2 baselines, starts the A6 duration clock, and answers open question Q1 about header rows — all before a single email goes out ([FSD FR-011](2026-08-15-task-gap-reminders-FSD.md#fr-011-internal-run-trigger), [FR-013](2026-08-15-task-gap-reminders-FSD.md#fr-013-run-observability)).

**Scope of work**

- Add `POST /api/v1/projects/tasks/internal/task-gap-reminder?dryRun=` to the existing internal route group, following `ProjectTaskNotificationsEndpoint`'s internal-endpoint convention.
- `dryRun=true` refreshes gap states and builds findings, but queues no email, stages no notification, and stamps no timestamps.
- Return the run summary shape in FSD §6, including a breakdown of findings by `data_type` so Q1 can be decided from data.
- Return 409 `RUN_IN_PROGRESS` when a run is already executing.
- Emit the FR-013 structured summary line at the end of every run, plus a warning line per undeliverable finding.
- Wrap per-project composition so one project's failure is logged with its project number and does not abort the run.
- Confirm the internal route group is not published through the public ingress (NFR-004) and record where that was verified.

**Acceptance criteria**

- Given in-scope findings exist, When the endpoint is called, Then emails are queued and the response reports the counts.
- Given `dryRun=true`, When the endpoint is called, Then gap states are refreshed, the response reports what would have been sent, and no email is queued.
- Given a run is already executing, When the endpoint is called again, Then the response is 409 `RUN_IN_PROGRESS`.
- Given a completed run, When the log is inspected, Then one summary line contains every counter listed in FR-013.
- Given one project throws during composition, When the run completes, Then other projects still sent and the failure is logged with the project number.

**Out of scope**

An alerting rule for "no run in 48h" — that belongs to the monitoring configuration, not this codebase.

**Test notes**

Call the endpoint against a copy of dev data and read the summary before enabling the scheduled trigger. The finding counts from this run are the R1 and R2 evidence: if headers dominate the findings, raise Q1 with Product before go-live.

---

## T-11: Decommission the without-SPK reminder

- **Epic:** E4 · **Size:** S · **Priority:** Must · **Blocked by:** T-07
- **Covers:** FR-012

**Context**

The existing reminder emails the same people about a subset of the same tasks. Leaving both running is duplicate mail, so it goes in the same release ([FSD FR-012](2026-08-15-task-gap-reminders-FSD.md#fr-012-decommission-the-superseded-without-spk-reminder)).

**Scope of work**

- Unschedule `ProjectTaskNotificationTrigger` and delete the `ProjectTaskNotificationJob` from the Quartz store as idempotent startup code — not a local action, because the store is shared with the deployed dev environment.
- Remove `SendReminderAsync`, the `/projects/tasks/internal/project-task-without-spk-reminder` endpoint, and the `EmailReminderProjectTaskWithoutSpk` template and its constants.
- Keep `GET`/`POST /projects/tasks/notifications` and the `project_task_without_spk_notifications` table responding for one release so an in-flight frontend does not break. File a follow-up to drop both.

**Acceptance criteria**

- Given the release is deployed, When the old trigger's scheduled time arrives, Then no without-SPK email is sent.
- Given the old configuration endpoints are called after deploy, Then they still respond without error.
- Given the unschedule code runs twice, When it completes, Then it succeeds both times.

**Out of scope**

Dropping the old table and configuration endpoints — one release later, tracked by the follow-up.

**Test notes**

Verify against the shared Quartz store that the old trigger is actually gone, not merely absent from the code. A removed registration leaves an orphaned trigger row that keeps firing against a job type that no longer exists.

---

## Coverage check

| FR / NFR | Covered by |
|---|---|
| FR-001 | T-01, T-02 |
| FR-002 | T-03 |
| FR-003 | T-04 |
| FR-004 | T-04 |
| FR-005 | T-05 |
| FR-006 | T-06 |
| FR-007 | T-06 |
| FR-008 | T-07 |
| FR-009 | T-01, T-08 |
| FR-010 | T-01, T-09 |
| FR-011 | T-10 |
| FR-012 | T-11 |
| FR-013 | T-10 |
| NFR-001 | T-03 |
| NFR-002 | T-06 |
| NFR-003 | T-07 |
| NFR-004 | T-10 |
| NFR-005 | T-06 |
| NFR-006 | T-06 |
| NFR-007 | T-10 |
| NFR-008 | T-06 |

All 13 FRs and 8 NFRs are covered by at least one ticket. No ticket covers a requirement that does not exist.
