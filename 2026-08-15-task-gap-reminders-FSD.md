# FSD: Project Task Gap Reminders

| | |
|---|---|
| **Status** | Draft |
| **Related PRD** | [PRD](2026-08-15-task-gap-reminders-PRD.md) |
| **Date** | 2026-08-15 |
| **Version** | 0.1 |

## 1. System Overview

One durable Quartz job (`TaskGapReminderJob`) runs daily at 08:00 local time. Each run has three stages: refresh the persisted gap state, decide which projects are due to send today, and compose one email per (project, recipient).

```
                    ┌────────────────────────────────────────────┐
  Quartz 08:00 ───▶ │ Stage 1 — RefreshGapStatesAsync            │
  (static trigger)  │  scan in-scope tasks                       │
  or POST /internal │  upsert  project_task_gap_states (new gap) │
                    │  delete  rows whose gap is now closed      │
                    └───────────────────┬────────────────────────┘
                                        ▼
                    ┌────────────────────────────────────────────┐
                    │ Stage 2 — per project, IsDueToday?         │
                    │  project_task_reminder_schedules           │
                    │  daily | weekly | custom(N) | one_time     │
                    └───────────────────┬────────────────────────┘
                                        ▼ (due projects only)
                    ┌────────────────────────────────────────────┐
                    │ Stage 3 — BuildFindings → group by         │
                    │  recipient → 1 email + 1 in-app row each   │
                    │  stamp last_sent_at / last_notified_at     │
                    └────────────────────────────────────────────┘
                                        │
                       IMailerService.QueueSend  +  INotificationDispatcher
```

Global day thresholds live in one `custom_configurations` row, so they need no new table. Per-project cadence lives in a new `project_task_reminder_schedules` table. Gap duration lives in a new `project_task_gap_states` table. Nothing else in PHANTOM changes except the removal of the superseded without-SPK reminder.

## 2. Scope

**In scope:** the four gap detections, gap-duration tracking, recipient resolution and fallback, email and in-app composition, per-project schedule evaluation, the five endpoints, and decommissioning `ProjectTaskNotificationsService`'s reminder path.

**Out of scope:** a new SPK status, per-task overrides, non-email channels, cross-project digests, historical backfill, and all frontend work. Tasks in projects that are not `in progress`, and tasks whose status is `finished` or `finished with note`, are never considered.

## 3. User Flows

### Flow A — Task PIC receives an SPK/BoQ gap reminder (US-01)

1. Day 0: task `T` in project `P` (status `in progress`) has no linked SPK. The 08:00 job writes a `project_task_gap_states` row for `(T, spk_empty)` with `first_detected_at = now`.
2. Days 1…N1−1: the job sees the gap is still open and leaves the row untouched. `T` is not reported.
3. Day N1: the gap has persisted N1 days. `T`'s plan start date is 12 days away, which is inside the N1-day window, so `T` becomes a finding.
4. The job resolves `T`'s PICs from `project_task_pics` → user `U`.
5. `P`'s schedule is `weekly`; today is Monday, so `P` is due. The job composes one email to `U` listing `T` (and any of `U`'s other findings in `P`), queues it, writes the in-app notification, and stamps `last_notified_at`.
6. `U` opens the SPK module, links an SPK to `T`.
7. Next run: the gap is closed, so the `(T, spk_empty)` row is deleted. `T` disappears from the email. If the SPK is later unlinked, a fresh row starts the clock again from zero.

### Flow B — Task PIC receives a not-released reminder (US-02)

1. Task `T` has SPK `S` with status `draft`. `T`'s plan start date is 10 days away and N2 is 14, so `T` is inside the window.
2. No duration tracking applies — the finding is evaluated fresh each run.
3. The finding is added to the same email as Flow A's findings for the same recipient and project, in its own section (A5).
4. When `S` moves to `released`, the finding disappears on the next run.

### Flow C — Project PIC receives a no-PIC reminder (US-03)

1. Task `T` in project `P` has no non-deleted `project_task_pics` rows.
2. The finding is raised regardless of `T`'s plan start date.
3. Recipients are `P`'s Project PICs. The email is separate from Flows A and B, because the recipient role and the action differ.

### Flow D — PIC-less task with a gap falls back (US-04)

1. Task `T` has no PIC **and** no BoQ, and the BoQ gap has persisted N1 days.
2. Recipient resolution for the BoQ finding finds no Task PIC, so it falls back to `P`'s Project PICs.
3. The Project PIC receives two emails about `P` that run: the gap email (Flows A/B grouping) and the no-PIC email (Flow C). This is intended — they describe different actions.

### Flow E — Administrator sets a project's cadence (US-05)

1. Administrator opens project `P`, clicks the Reminder (email icon) button.
2. The UI calls `GET /projects/{projectId}/reminder-schedule` and shows the current setting, defaulting to `weekly`/active when no row exists.
3. Administrator picks `custom`, enters 3 days, saves.
4. The UI calls `PUT /projects/{projectId}/reminder-schedule`. The row is created or updated.
5. The next send lands on the following Monday (first-send rule), then every 3 days after that.

## 4. Functional Requirements

### FR-001: Gap state tracking

- **Traces to:** G1 / US-01
- **Priority:** Must
- **Description:** The system shall maintain, for each in-scope task, a persisted record of when each of its SPK-empty and BoQ-empty gaps was first observed.
- **Trigger / Input:** Stage 1 of every job run, including dry-run mode.
- **Behavior:**

  | Condition on this run | Existing `project_task_gap_states` row | Action |
  |---|---|---|
  | Gap present | none | Insert row: `first_detected_at = run timestamp`, `last_notified_at = NULL` |
  | Gap present | exists | Leave untouched (the clock keeps running) |
  | Gap absent | exists | Delete the row |
  | Gap absent | none | No action |
  | Task deleted, finished, or its project left `in progress` | exists | Delete the row |

  Gap types tracked: `spk_empty` (`project_tasks.spk_id IS NULL`) and `boq_empty` (no non-deleted `project_task_boqs` rows for the task). The not-released and no-PIC conditions are evaluated fresh each run and are **not** tracked here.
- **Validation & Errors:** Stage 1 runs inside one transaction per batch. A failure logs `[TaskGapReminder] Stage 1 failed` and aborts the run before any email is sent, so a partial state refresh can never produce a wrong duration in an email.
- **Edge cases:**
  - First run after deployment: every currently-open gap is inserted with `first_detected_at = now` (A6). No task can qualify for N1 days.
  - A gap closed and reopened restarts the clock at zero — deliberate, since the field was genuinely filled in between.
  - A task hard-deleted from the database leaves an orphan row; the FK cascade in §5 removes it.
  - Concurrency: only one job run executes at a time (Quartz `[DisallowConcurrentExecution]`), so no locking beyond that is required.
- **Acceptance criteria:**
  - Given a task with no SPK and no gap-state row, When the job runs, Then a `spk_empty` row is created with `first_detected_at` set to the run time.
  - Given a task with an open `boq_empty` row 5 days old, When the job runs and the BoQ is still empty, Then `first_detected_at` is unchanged.
  - Given a task with an open `spk_empty` row, When an SPK is linked and the job runs, Then the row is deleted.
  - Given a task whose project moves out of `in progress`, When the job runs, Then its gap-state rows are deleted.

### FR-002: SPK-or-BoQ-empty finding

- **Traces to:** G1 / US-01
- **Priority:** Must
- **Description:** The system shall raise a finding for a task whose SPK or BoQ has been empty for at least N1 consecutive days and whose plan start date is within N1 days or already past.
- **Trigger / Input:** Stage 3 of a run, for projects due today. N1 comes from the global settings (FR-010), default 30, valid range 1–365.
- **Behavior:** A task produces a finding when **all** of the following hold:

  | # | Condition |
  |---|---|
  | 1 | Project status = `in progress` and project not deleted |
  | 2 | Task not deleted and task status ∉ { `finished`, `finished with note` } |
  | 3 | A `project_task_gap_states` row exists for gap type `spk_empty` or `boq_empty` |
  | 4 | `run_date − first_detected_at ≥ N1 days` |
  | 5 | `plan_start_date ≤ run_date + N1 days` (inside the run-up window, or already past) |

  Condition 5 keeps far-future tasks quiet: a task starting in eight months does not generate warnings merely because it is empty. Once the start date passes, condition 5 stays satisfied and the finding persists until the gap closes or the task finishes (grilled decision: keep notifying).

  A task missing both SPK and BoQ produces **one** finding row listing both, not two rows.

  Each finding carries: task breakdown, task description, missing field(s), days empty (`run_date − first_detected_at`), plan start date, and an `isOverdue` flag (`plan_start_date < run_date`).
- **Validation & Errors:** If N1 is absent or unparsable from settings, the run uses the default 30 and logs a warning; it does not abort. A negative or zero N1 is rejected at write time by FR-010.
- **Edge cases:**
  - Header rows (`data_type = 'header'`) and milestones are included (A9, Q1).
  - A task whose plan start date is null cannot satisfy condition 5 and is skipped; logged at debug once per run with a count.
  - A task in a project with no PIC and no Task PIC produces a finding with no recipient; it is counted and logged, not silently dropped (FR-005).
- **Acceptance criteria:**
  - Given N1 = 30, a task empty for 30 days, and a plan start date 10 days away, When the job runs for a due project, Then the task appears in the SPK/BoQ section of the email with `daysEmpty = 30`.
  - Given N1 = 30 and a task empty for 29 days, When the job runs, Then the task does not appear.
  - Given N1 = 30, a task empty for 40 days, and a plan start date 200 days away, When the job runs, Then the task does not appear (condition 5 fails).
  - Given a task empty for 40 days whose plan start date was 5 days ago, When the job runs, Then the task appears flagged as overdue.
  - Given a task with status `finished with note` and no BoQ, When the job runs, Then the task does not appear.

### FR-003: SPK-not-released finding

- **Traces to:** G2 / US-02
- **Priority:** Must
- **Description:** The system shall raise a finding for a task whose linked SPK has not reached `released` and whose plan start date is within N2 days or already past.
- **Trigger / Input:** Stage 3, evaluated fresh each run. N2 default 14, valid range 1–365.
- **Behavior:** A finding is raised when conditions 1 and 2 of FR-002 hold **and**:

  | # | Condition |
  |---|---|
  | 3 | `project_tasks.spk_id IS NOT NULL` (a task with no SPK is FR-002's, not this one's) |
  | 4 | The linked SPK's status ∉ { `released`, `finished`, `finished with note` } |
  | 5 | `plan_start_date ≤ run_date + N2 days` |

  Status mapping (A1, A2):

  | SPK status | Raises finding? | Rationale |
  |---|---|---|
  | `draft` | Yes | Not with the vendor |
  | `on hold` | Yes | Not with the vendor |
  | `approved` | Yes | Approved internally, not yet released |
  | `canceled` | Yes | Cannot be executed (A2) |
  | `released` | No | This is "Release to Vendor" (A1) |
  | `finished` | No | Already past release |
  | `finished with note` | No | Already past release |

  Each finding carries: task breakdown, task description, SPK number, current SPK status, plan start date, `isOverdue`.
- **Validation & Errors:** A task pointing at a deleted or non-existent SPK is treated as SPK-empty and handled by FR-002, not here; the mismatch is logged as a warning since it indicates data corruption.
- **Edge cases:** A task whose plan start date is null is skipped, as in FR-002.
- **Acceptance criteria:**
  - Given N2 = 14, a task whose SPK is `draft`, and a plan start date 10 days away, When the job runs for a due project, Then the task appears in the not-released section showing status `draft`.
  - Given a task whose SPK is `released`, When the job runs, Then the task does not appear.
  - Given a task whose SPK is `canceled` and a plan start date 3 days away, When the job runs, Then the task appears.
  - Given N2 = 14 and a task whose SPK is `draft` with a plan start date 30 days away, When the job runs, Then the task does not appear.
  - Given a task with `spk_id IS NULL`, When the job runs, Then it appears at most in the FR-002 section and never in this one.

### FR-004: Task-without-PIC finding

- **Traces to:** G3 / US-03
- **Priority:** Must
- **Description:** The system shall raise a finding for every in-scope task that has no PIC assigned.
- **Trigger / Input:** Stage 3, evaluated fresh each run. No day threshold applies.
- **Behavior:** A finding is raised when conditions 1 and 2 of FR-002 hold and the task has zero non-deleted `project_task_pics` rows whose user is non-deleted. Each finding carries task breakdown, description, plan start date, and `isOverdue`. Recipients are always the Project PICs (FR-005), and these findings go in their own email, never merged with FR-002/FR-003 findings.
- **Validation & Errors:** A project with no Project PIC produces findings with no recipient; the run logs `[TaskGapReminder] Project {ProjectNo} has no PIC — {Count} no-PIC finding(s) undeliverable` and continues.
- **Edge cases:**
  - A `project_task_pics` row pointing at a soft-deleted or inactive user does not count as a PIC — the task is treated as unowned.
  - `project_tasks.assignee` is ignored entirely (A3).
- **Acceptance criteria:**
  - Given a task with no `project_task_pics` rows in an `in progress` project, When the job runs for a due project, Then the task appears in the no-PIC email to the Project PIC.
  - Given a task whose only `project_task_pics` row has `deleted_at` set, When the job runs, Then the task appears as having no PIC.
  - Given a task with an active PIC, When the job runs, Then the task does not appear in the no-PIC email.
  - Given a project with no Project PIC and 3 PIC-less tasks, When the job runs, Then no email is sent and one warning line is logged naming the project and the count.

### FR-005: Recipient resolution and fallback

- **Traces to:** US-01, US-02, US-03, US-04
- **Priority:** Must
- **Description:** The system shall resolve each finding to one or more recipients, falling back to the Project PICs when a task has no Task PIC.
- **Behavior:**

  | Finding type | Primary recipient | Fallback |
  |---|---|---|
  | FR-002 (SPK/BoQ empty) | Task PICs | Project PICs |
  | FR-003 (SPK not released) | Task PICs | Project PICs |
  | FR-004 (no PIC) | Project PICs | none — logged if absent |

  A recipient is eligible only when the user is non-deleted, has status null or `active`, and has a non-empty email address. These are the same predicates the existing `ProjectRemindersService` uses. A task with several PICs sends the finding to each of them.

  A recipient sees only the findings resolved to them (A4) — never the whole project's table.
- **Validation & Errors:** A finding with no eligible recipient after fallback is counted in the run log under `undeliverable`, never dropped silently.
- **Edge cases:**
  - The same user being both Task PIC and Project PIC receives the finding once (deduplicated by user id).
  - A user who is both a Task PIC on some tasks and the fallback recipient for other PIC-less tasks receives one merged gap email covering both sets.
- **Acceptance criteria:**
  - Given a task with two active Task PICs, When a finding is raised, Then both users receive it.
  - Given a task with no Task PIC in a project with one Project PIC, When an FR-002 finding is raised, Then the Project PIC receives it.
  - Given a Task PIC whose user record is soft-deleted, When a finding is raised, Then that user receives nothing and the fallback applies.
  - Given a user who is both the task's PIC and the project's PIC, When a finding is raised, Then exactly one email is queued for that user.

### FR-006: Email composition and grouping

- **Traces to:** G4 / US-07
- **Priority:** Must
- **Description:** The system shall send at most one gap email and at most one no-PIC email per (project, recipient) per run, each containing a table of that recipient's findings.
- **Behavior:**
  - Findings from FR-002 and FR-003 for the same (project, recipient) are merged into **one** email with two labelled sections (A5).
  - FR-004 findings form a **separate** email, because the recipient's required action differs.
  - Table columns: `Task` (breakdown — description), `Missing` (SPK / BoQ / SPK + BoQ / SPK not released — <status> / PIC), `Empty for` (days, blank for FR-003 and FR-004), `Plan Start` (dd-MM-yyyy), `Status` (Upcoming / **Overdue**).
  - Rows are ordered by plan start date ascending, overdue first.
  - The table is capped at 50 rows; when there are more, a final line reads `+N more task(s) — open the project to see all` (R6).
  - The email uses a new template `EmailTaskGapReminder.html` rendered by `PhantomEmailTemplates.Render`. Because that renderer has no loop construct, the table body is built as an HTML string in code and passed as the single `task_rows` placeholder. Placeholders: `fullname`, `project_number`, `task_rows`, `web_link`, `summary_line`.
  - `web_link` is `{AppSettingsConfig:WebBaseUrl}/projects/{projectId}/detail`, matching the existing reminders.
- **Validation & Errors:** Task descriptions are HTML-escaped before being placed in the table; unescaped user-entered task text would otherwise allow HTML injection into the email body.
- **Edge cases:**
  - A recipient with findings in three projects receives three emails, one per project.
  - A project due today with zero findings sends nothing and does not stamp `last_sent_at`, so a `one_time` schedule is not consumed by an empty run.
- **Acceptance criteria:**
  - Given a recipient with 2 SPK/BoQ findings and 1 not-released finding in one project, When the job runs, Then exactly one email is queued containing both sections and 3 rows.
  - Given a recipient with findings in 2 projects, When the job runs, Then 2 emails are queued.
  - Given a recipient with 60 findings in one project, When the job runs, Then the email shows 50 rows and a `+10 more` line.
  - Given a task description containing `<script>`, When the email is composed, Then the output contains the escaped text and no live tag.
  - Given a due project with no findings, When the job runs, Then no email is queued and `last_sent_at` is unchanged.

### FR-007: In-app notification alongside each email

- **Traces to:** US-08
- **Priority:** Should
- **Description:** The system shall write one in-app notification per email queued.
- **Behavior:** For every email queued by FR-006, a notification row is staged through `INotificationDispatcher` for the same recipient, with the same `web_link`, a title naming the gap class (`Project Task — SPK/BoQ Belum Lengkap` or `Project Task — Belum Ada PIC`) and a message naming the project number and the finding count. Staged notifications are committed once per run with a single `SaveChangesAsync`, following `ProjectRemindersService`'s pattern.
- **Edge cases:** If the mailer queue call throws, the notification for that recipient is not staged, so the two channels do not disagree.
- **Acceptance criteria:**
  - Given an email is queued for a recipient, When the run commits, Then exactly one notification row exists for that user with the project's detail link.
  - Given no email is queued for a project, When the run commits, Then no notification row is created for it.

### FR-008: Per-project schedule evaluation

- **Traces to:** G5 / US-05, US-09
- **Priority:** Must
- **Description:** The system shall decide, per project and per run, whether that project sends today, based on the project's stored frequency.
- **Behavior:**

  | Frequency | Sends today when |
  |---|---|
  | `daily` | Always |
  | `weekly` | Today is Monday |
  | `custom` | `last_sent_at IS NULL` **or** `run_date − last_sent_at ≥ interval_days` |
  | `one_time` | `last_sent_at IS NULL` |
  | any, with `is_active = false` | Never |
  | no schedule row | Treated as `weekly`, active (A7) |

  **First-send rule:** when `last_sent_at IS NULL`, the project sends only if today is Monday, regardless of frequency. This implements "warning pertama di hari Senin" uniformly across all four frequencies.

  `last_sent_at` is stamped only when at least one email was actually queued for that project in that run (FR-006 edge case).
- **Validation & Errors:** A row with `frequency = 'custom'` and null or non-positive `interval_days` is rejected at write time (FR-009); if such a row exists anyway, the run treats the project as `weekly` and logs a warning.
- **Edge cases:**
  - A `one_time` schedule stays consumed until an administrator re-arms it by saving the schedule again, which clears `last_sent_at` (Q3).
  - Changing frequency does not clear `last_sent_at`, so switching from `weekly` to `custom` with interval 3 sends 3 days after the last weekly send, not immediately.
- **Acceptance criteria:**
  - Given a project with frequency `daily` that has sent before, When the job runs on any day, Then the project is due.
  - Given a project with frequency `weekly`, When the job runs on a Tuesday, Then the project is not due.
  - Given a project with frequency `custom`, `interval_days = 3`, `last_sent_at` 3 days ago, When the job runs, Then the project is due.
  - Given a project with frequency `one_time` and a non-null `last_sent_at`, When the job runs, Then the project is not due.
  - Given a project with no schedule row, When the job runs on a Monday, Then the project is due.
  - Given a project with `is_active = false` and frequency `daily`, When the job runs, Then the project is not due.
  - Given a project that has never sent and frequency `daily`, When the job runs on a Wednesday, Then the project is not due; When it runs on the following Monday, Then it is due.

### FR-009: Per-project reminder schedule API

- **Traces to:** G5 / US-05, US-09
- **Priority:** Must
- **Description:** The system shall expose read and write endpoints for a project's reminder schedule.
- **Behavior:** See §6 for shapes. `PUT` upserts by `project_id`. Re-saving a schedule clears `last_sent_at`, which re-arms a consumed `one_time` schedule and makes the next Monday the first send again.
- **Validation & Errors:**

  | Case | HTTP | Error |
  |---|---|---|
  | `projectId` not found or deleted | 404 | `PROJECT_NOT_FOUND` |
  | `frequency` not in { `daily`, `weekly`, `custom`, `one_time` } | 400 | `INVALID_FREQUENCY` |
  | `frequency = custom` and `intervalDays` null, < 1, or > 365 | 400 | `INVALID_INTERVAL_DAYS` |
  | `intervalDays` supplied with a non-`custom` frequency | 200 | Accepted and stored as null; the value is meaningless for other frequencies |
- **Edge cases:** Two concurrent `PUT`s for the same project resolve by the unique index on `project_id`; the second write updates rather than inserting a duplicate.
- **Acceptance criteria:**
  - Given a project with no schedule, When `GET` is called, Then it returns `frequency = "weekly"`, `isActive = true`, `intervalDays = null`, `lastSentAt = null`.
  - Given a valid body with `frequency = "custom"` and `intervalDays = 3`, When `PUT` is called, Then the row is stored and `lastSentAt` is cleared.
  - Given `frequency = "custom"` and `intervalDays = 0`, When `PUT` is called, Then the response is 400 `INVALID_INTERVAL_DAYS`.
  - Given an unknown `projectId`, When `PUT` is called, Then the response is 404 `PROJECT_NOT_FOUND`.

### FR-010: Global threshold settings API

- **Traces to:** G5 / US-06
- **Priority:** Must
- **Description:** The system shall expose read and write endpoints for the global day thresholds N1 and N2.
- **Behavior:** Values are stored as JSON in a single `custom_configurations` row with `name = 'task_gap_reminder_thresholds'` and `detail = {"spkBoqEmptyDays":30,"spkNotReleasedDays":14}`. `GET` returns the defaults 30/14 when the row does not exist. `PUT` upserts the row.
- **Validation & Errors:**

  | Case | HTTP | Error |
  |---|---|---|
  | Either value < 1 or > 365 | 400 | `INVALID_THRESHOLD` |
  | Either value missing | 400 | `INVALID_THRESHOLD` |
  | Caller lacks the settings permission | 403 | `FORBIDDEN` |
- **Edge cases:** A malformed `detail` JSON in the database falls back to the defaults and logs a warning rather than failing the job (FR-002).
- **Acceptance criteria:**
  - Given no settings row, When `GET` is called, Then it returns 30 and 14.
  - Given a body with `spkBoqEmptyDays = 45` and `spkNotReleasedDays = 7`, When `PUT` is called, Then the values are persisted and the next run uses them.
  - Given `spkBoqEmptyDays = 0`, When `PUT` is called, Then the response is 400 `INVALID_THRESHOLD`.

### FR-011: Internal run trigger

- **Traces to:** G1, G2, G3
- **Priority:** Must
- **Description:** The system shall expose an internal endpoint that executes one full job run on demand.
- **Behavior:** `POST /projects/tasks/internal/task-gap-reminder` runs stages 1–3 synchronously and returns a summary of the run. An optional `dryRun=true` query flag runs stages 1 and 3 but queues no email and stamps no timestamps — this is the Phase 0 rollout mode and the baseline-measurement tool. The endpoint sits in the existing internal route group, matching `ProjectTaskNotificationsEndpoint`'s `/projects/tasks/internal/...` convention.
- **Validation & Errors:** Concurrent invocations are serialised by the job's `[DisallowConcurrentExecution]`; a second caller receives 409 `RUN_IN_PROGRESS` rather than producing duplicate emails.
- **Edge cases:** A run that finds nothing returns 200 with zero counts, not an error.
- **Acceptance criteria:**
  - Given in-scope findings exist, When the endpoint is called, Then emails are queued and the response reports the counts.
  - Given `dryRun=true`, When the endpoint is called, Then gap states are refreshed, the response reports what would have been sent, and no email is queued.
  - Given a run is already executing, When the endpoint is called again, Then the response is 409 `RUN_IN_PROGRESS`.

### FR-012: Decommission the superseded without-SPK reminder

- **Traces to:** G4 / US-07
- **Priority:** Must
- **Description:** The system shall stop sending the existing `project-task-without-spk` reminder in the same release that enables this feature.
- **Behavior:** `ProjectTaskNotificationJob`'s Quartz trigger is unscheduled and its job removed; `SendReminderAsync`, its internal endpoint, and the `EmailReminderProjectTaskWithoutSpk` template are removed. The `GET`/`POST /projects/tasks/notifications` configuration endpoints and the `project_task_without_spk_notifications` table are retained read-only for one release so an in-flight frontend does not break, then dropped.
- **Validation & Errors:** Removing a Quartz job that does not exist is a no-op, so the migration step is idempotent.
- **Edge cases:** Because the Quartz store is shared with the deployed dev environment, the unschedule must run as startup code (or a one-off script), not only as a local action.
- **Acceptance criteria:**
  - Given the release is deployed, When the old trigger's time arrives, Then no without-SPK email is sent.
  - Given the old configuration endpoints are called, When the release is deployed, Then they still respond without error for one release cycle.

### FR-013: Run observability

- **Traces to:** G4, R5
- **Priority:** Must
- **Description:** The system shall emit one structured summary log line per run.
- **Behavior:** The line reports: run mode (scheduled / manual / dry-run), duration, tasks scanned, gap-state rows inserted and deleted, projects evaluated, projects due, findings by type, emails queued, recipients, and undeliverable findings. Per-project failures are logged and skipped so one bad project cannot abort the run.
- **Acceptance criteria:**
  - Given a completed run, When the log is inspected, Then one summary line contains all listed counters.
  - Given one project throws during composition, When the run completes, Then the other projects still sent and the failure is logged with the project number.

## 5. Data Model

### New table: `project_task_gap_states`

| Column | Type | Constraints |
|---|---|---|
| `id` | `uniqueidentifier` | PK |
| `project_task_id` | `uniqueidentifier` | NOT NULL, FK → `project_tasks(id)` ON DELETE CASCADE |
| `gap_type` | `varchar(20)` | NOT NULL, one of `spk_empty`, `boq_empty` |
| `first_detected_at` | `datetime2` | NOT NULL |
| `last_notified_at` | `datetime2` | NULL |

Unique index on `(project_task_id, gap_type)`. Non-clustered index on `first_detected_at` to support the age filter. Rows are transient working state, not history: they are deleted the moment a gap closes, so the table stays bounded by the number of open gaps. No PII.

### New table: `project_task_reminder_schedules`

| Column | Type | Constraints |
|---|---|---|
| `id` | `uniqueidentifier` | PK |
| `project_id` | `uniqueidentifier` | NOT NULL, UNIQUE, FK → `projects(id)` |
| `frequency` | `varchar(20)` | NOT NULL, DEFAULT `weekly`, one of `daily`, `weekly`, `custom`, `one_time` |
| `interval_days` | `int` | NULL, required when `frequency = custom`, range 1–365 |
| `is_active` | `bit` | NOT NULL, DEFAULT 1 |
| `last_sent_at` | `datetime2` | NULL |
| `created_at` / `created_by` | `datetime2` / `uniqueidentifier` | Standard audit columns |
| `updated_at` / `updated_by` | `datetime2` / `uniqueidentifier` | NULL |

### Reused: `custom_configurations`

One row, no schema change:

```
name        = 'task_gap_reminder_thresholds'
description = 'Day thresholds for project task gap reminders'
detail      = '{"spkBoqEmptyDays":30,"spkNotReleasedDays":14}'
```

### Read-only dependencies

`projects` (`status`, `project_no`), `project_tasks` (`spk_id`, `start_date`, `status`, `data_type`, `breakdown`, `description`, `deleted_at`), `project_task_boqs` (`project_task_id`, `deleted_at`), `project_task_pics`, `project_pics`, `users` (`email`, `full_name`, `status`, `deleted_at`), `spks` (`status`, `spk_no`).

### Deprecated

`project_task_without_spk_notifications` — retained one release, then dropped (FR-012).

## 6. Interfaces

All endpoints sit under `/api/v1` and follow the Carter service pattern used by `ProjectRemindersEndpoint`. The service must be registered in `AppServiceSetup.cs`, or startup fails with a "Body was inferred" binding error.

### `GET /api/v1/projects/{projectId}/reminder-schedule`

Auth: bearer. Returns the effective schedule, defaulting when no row exists.

All responses use the collection's standard envelope: `{ data, process_time, status, code, message }`. Field names are snake_case, matching the rest of the API.

```json
{
  "data": {
    "project_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "frequency": "weekly", "interval_days": null,
    "is_active": true, "last_sent_at": null
  },
  "process_time": "12.4021ms", "status": "success", "code": "00",
  "message": "get project reminder schedule succeed"
}
```

Errors: 404 `PROJECT_NOT_FOUND`.

### `PUT /api/v1/projects/{projectId}/reminder-schedule`

```json
{ "frequency": "custom", "interval_days": 3, "is_active": true }
```

Returns the stored schedule in the same shape as `GET`. Errors: 400 `INVALID_FREQUENCY`, 400 `INVALID_INTERVAL_DAYS`, 404 `PROJECT_NOT_FOUND`.

### `GET /api/v1/settings/task-gap-reminder`

```json
{
  "data": { "spk_boq_empty_days": 30, "spk_not_released_days": 14 },
  "process_time": "9.2210ms", "status": "success", "code": "00",
  "message": "get task gap reminder settings succeed"
}
```

### `PUT /api/v1/settings/task-gap-reminder`

```json
{ "spk_boq_empty_days": 45, "spk_not_released_days": 7 }
```

Errors: 400 `INVALID_THRESHOLD`, 403 `FORBIDDEN`.

### `POST /api/v1/projects/tasks/internal/task-gap-reminder?dryRun=false`

Internal route group, no bearer (matching existing internal reminder endpoints — see NFR-004).

```json
{
  "data": {
    "dry_run": false, "tasks_scanned": 4821,
    "gap_states_inserted": 12, "gap_states_deleted": 30, "projects_due": 7,
    "findings": { "spk_or_boq_empty": 41, "spk_not_released": 9, "no_pic": 6 },
    "emails_queued": 18, "undeliverable": 2, "duration_ms": 3120
  },
  "process_time": "3120.4471ms", "status": "success", "code": "00",
  "message": "send task gap reminder succeed"
}
```

Errors: 409 `RUN_IN_PROGRESS`.

### Events and integrations

Outbound only: `IMailerService.QueueSend` (R4Mailer or SMTP by configuration) and `INotificationDispatcher.StageFromTemplateAsync`. No events are consumed. Nothing is exposed to third parties.

## 7. Non-Functional Requirements

### NFR-001: Run performance
- **Requirement:** A full run over 500 projects and 50,000 tasks completes in under 120 seconds, with stage 1 issuing a bounded number of set-based queries rather than one query per task. No N+1 access to `project_task_boqs`, `project_task_pics`, or `spks`.
- **Traces to:** G1, G2, G3

### NFR-002: Email volume ceiling
- **Requirement:** No recipient receives more than one gap email and one no-PIC email per project per run, enforced by the grouping in FR-006 and verifiable from the mailer log.
- **Traces to:** G4

### NFR-003: Cognitive complexity
- **Requirement:** Every method added by this feature has cognitive complexity ≤ 15, per `CLAUDE.md`. The job is written as an orchestrator over named helpers (`RefreshGapStatesAsync`, `IsDueToday`, `BuildFindings`, `ResolveRecipients`, `ComposeEmail`), not as one long method.
- **Traces to:** G5

### NFR-004: Internal endpoint exposure
- **Requirement:** The internal run endpoint is reachable only from inside the deployment network. Its route group must not be published through the public ingress. This matches the existing internal reminder endpoints and is called out explicitly rather than inherited silently (R7).
- **Traces to:** G4

### NFR-005: Email content safety
- **Requirement:** All task-derived text in the email body is HTML-escaped. No user-entered value reaches the rendered template unescaped.
- **Traces to:** G4

### NFR-006: Language
- **Requirement:** Email subject and body are in Indonesian, consistent with the existing `Subject_ReminderProject` / `Subject_ReminderProjectTaskWithoutSpk` templates. Log lines and API error codes stay in English.
- **Traces to:** G1, G2, G3

### NFR-007: Observability
- **Requirement:** One structured summary line per run (FR-013), plus a warning line for every undeliverable finding. Absence of a summary line for 48 hours is an alertable condition.
- **Traces to:** R5

### NFR-008: Template catalog integrity
- **Requirement:** The new template's `task_rows` and `summary_line` placeholders are added to `EmailTemplateCatalog.SampleValues`, so `EmailTemplateTester` does not report the template as having unsupported placeholders.
- **Traces to:** G4

## 8. Permissions & Roles

| Action | Task PIC | Project PIC | Project Admin | System Admin |
|---|---|---|---|---|
| Receive gap emails for own tasks | ✅ | ✅ (fallback) | — | — |
| Receive no-PIC emails | — | ✅ | — | — |
| `GET` project reminder schedule | ✅ | ✅ | ✅ | ✅ |
| `PUT` project reminder schedule | ❌ | ✅ | ✅ | ✅ |
| `GET` global thresholds | ✅ | ✅ | ✅ | ✅ |
| `PUT` global thresholds | ❌ | ❌ | ❌ | ✅ |
| Call the internal run endpoint | ❌ | ❌ | ❌ | ✅ (network-restricted) |

**Enforcement — decided: reuse the existing mechanism, add no new permission.** The authenticated endpoints register on an `/api/v1` group carrying `.AddEndpointFilter<R3ComponentFilter>()`, exactly as `ProjectRemindersEndpoint` does. No new permission key, and no `RbacRouteMaps` entry — that map is only ported for Custom Configuration, and the projects module is not in it.

The internal run endpoint registers on a **separate `/api/v1` group with no filter**, following `ProjectTaskNotificationsEndpoint`'s `internal_` group. This is why it is not simply marked `AllowAnonymous`: `R3ComponentFilter` ignores `AllowAnonymous`, so an endpoint left on the filtered group would be gated no matter what the attribute says.

## 9. Analytics & Telemetry

| Event | Properties | When fired | Measures |
|---|---|---|---|
| `task_gap_reminder.run` | mode, durationMs, tasksScanned, projectsEvaluated, projectsDue, findingsByType, emailsQueued, recipients, undeliverable | End of every run | G4, R5 |
| `task_gap_reminder.email_queued` | projectId, recipientUserId, findingCount, sections | Per email | G4, NFR-002 |
| `task_gap_reminder.gap_opened` | projectTaskId, gapType | On gap-state insert | G1 baseline |
| `task_gap_reminder.gap_closed` | projectTaskId, gapType, ageDays | On gap-state delete | G1 — the age distribution is the direct measure of whether gaps are closing faster |
| `task_gap_reminder.schedule_changed` | projectId, frequency, intervalDays, isActive | On `PUT` schedule | G5 |

G1 and G2 are computed from a scheduled query over `project_tasks` joined to `project_task_boqs` and `spks` on plan start dates, not from these events; the events measure the reminder mechanism, the query measures the outcome. Both baselines come from the Phase 0 dry run.

## 10. Traceability Matrix

| PRD Goal/Story | FRs | NFRs |
|---|---|---|
| G1 / US-01 | FR-001, FR-002, FR-005, FR-006, FR-011 | NFR-001, NFR-006 |
| G2 / US-02 | FR-003, FR-005, FR-006, FR-011 | NFR-001, NFR-006 |
| G3 / US-03 | FR-004, FR-005, FR-006, FR-011 | NFR-001, NFR-006 |
| G4 / US-07 | FR-006, FR-012, FR-013 | NFR-002, NFR-004, NFR-005, NFR-008 |
| G5 / US-05, US-06, US-09 | FR-008, FR-009, FR-010 | NFR-003 |
| US-04 | FR-005 | — |
| US-08 | FR-007 | — |
| R5 | FR-013 | NFR-007 |

Every FR traces to at least one goal, and every goal has at least one FR.

## 11. Open Questions

| # | Question | Owner | Affects |
|---|---|---|---|
| Q1 | Include or exclude `data_type = 'header'` and milestone rows? Specified as included (A9); decide from Phase 0 dry-run data. | Product | FR-002, FR-003, FR-004 — one predicate each |
| ~~Q2~~ | ~~Which permission key guards `PUT /settings/task-gap-reminder`?~~ **Resolved 2026-08-15: reuse the existing `R3ComponentFilter` guard, add no new permission. See §8.** | — | Closed |
| Q3 | Should `one_time` re-arm automatically when new gaps appear? Specified as no. | Product | FR-008 — follow-up only |
