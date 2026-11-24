# PRD: Project Task Gap Reminders

| | |
|---|---|
| **Status** | Draft |
| **Author** | Claude |
| **Date** | 2026-08-15 |
| **Version** | 0.1 |
| **Related docs** | [FSD](2026-08-15-task-gap-reminders-FSD.md) · [TICKETS](2026-08-15-task-gap-reminders-TICKETS.md) |

## 1. Overview

Project tasks routinely reach their start date with no SPK attached, no BoQ filled in, an SPK still sitting unreleased in draft, or nobody assigned as PIC. Nobody finds out until the task is already late. This feature gives PHANTOM a single daily job that detects those four gaps, and emails the person who can close each one — the Task PIC, or the Project PIC where there is no Task PIC — with one summary email per project containing a table of that person's offending tasks. Each project owner controls how often their project's reminders go out (daily, weekly, every N days, or once); a system administrator controls how many days before a task's start date the warnings begin.

## 2. Problem Statement

- A task cannot be executed without an SPK and a BoQ, but nothing in PHANTOM warns anyone that they are missing. The gap is only noticed when the task is overdue.
- An SPK that exists but has never been released to the vendor is functionally the same as no SPK — work cannot start — yet it looks "done" on the task row.
- Tasks without a PIC have no owner, so no reminder about anything else reaches anybody.
- PHANTOM already ships a reminder for tasks without an SPK (`ProjectTaskNotificationsService`), but it is ineffective in three ways found during research:
  - It computes a 2-month cutoff (`ProjectTaskNotificationsService.cs:141`) and **never applies it** — the date window is dead code, so the reminder ignores start dates entirely.
  - It sends to the **Project** PIC, not the Task PIC, and it never says *which* tasks are affected — the email carries only a project number.
  - It emits one email **per project per recipient with no task list**, so a recipient cannot act on it without opening the project and hunting.
- Reminder frequency today is global. A project with 400 tasks and a project with 4 tasks get the same cadence, so recipients either drown or hear nothing.

## 3. Goals & Success Metrics

| ID | Goal | Metric | Target |
|---|---|---|---|
| G1 | Tasks start with SPK and BoQ in place | % of tasks in `in progress` projects whose SPK and BoQ are both non-empty on their plan start date | ≥ 90%, measured 2 months after launch against the launch-day baseline |
| G2 | SPKs reach the vendor before work starts | % of tasks whose linked SPK has status `released` (or later) on or before plan start date | ≥ 85% within 2 months of launch |
| G3 | Every task in an active project has an owner | Count of non-deleted tasks in `in progress` projects with zero `project_task_pics` rows | 0 within 30 days of launch |
| G4 | Reminders stay actionable, not spam | Emails sent per recipient per project per scheduled run | Exactly 1 (hard cap, verified in the mailer log) |
| G5 | Configuration is self-service | Number of engineering tickets required to change a project's reminder cadence or the day thresholds | 0 — both are set through the API/UI |

Baselines for G1 and G2 are captured on launch day by running the detection job in dry-run mode; without that baseline the percentage targets are unfalsifiable.

## 4. Non-Goals

| Not doing | Why cut |
|---|---|
| Adding a new `release to vendor` SPK status | Confirmed during grilling that this maps to the existing `released` status. Adding a status would touch the SPK state machine, approvals, and every status filter in the codebase — a separate epic if it is ever genuinely wanted. |
| Per-task reminder overrides | Frequency is a project-level decision. Per-task settings multiply configuration surface for no evidence of need. |
| SMS / WhatsApp / push channels | Email plus the existing in-app notification covers the ask. Other channels are new integrations. |
| A cross-project digest ("all your gaps everywhere in one email") | The AC explicitly asks for 1 project = 1 email. A digest is the opposite grouping and would need its own recipient model. |
| Backfilling historical gap durations | The "empty for N days" clock starts at first job run. See A6 — backfilling from `created_at` would fire a launch-day email storm for tasks empty for years. |
| Frontend implementation | This repository is backend-only (`src-be`). This spec defines the API contract the Project page reminder modal consumes. |
| Reminders for `finished` / `finished with note` tasks, or for projects not `in progress` | Confirmed out of scope during grilling. |

## 5. Users & Personas

| Persona | Description | Key need |
|---|---|---|
| **Task PIC** | The user assigned to a specific project task via `project_task_pics`. Usually an engineer or field supervisor responsible for delivery of that task. | To be told, before the task starts, exactly which of their tasks are missing an SPK or BoQ — with a link, not a hunt. |
| **Project PIC** | The user assigned to the project via `project_pics`. Accountable for the project as a whole. | To know which tasks in their project have no owner at all, and to catch gaps on tasks that have no Task PIC to warn. |
| **Project Administrator** | The user who configures the project from the Project page (Reminder / email icon button). | To set how often this project's reminders go out without asking engineering. |
| **System Administrator** | Manages PHANTOM-wide settings. | To set the day thresholds (N1, N2) once, for all projects. |

## 6. User Stories

| ID | Story | Priority |
|---|---|---|
| US-01 | As a **Task PIC**, I want one email per project listing my tasks whose SPK or BoQ has been empty for N1 days, so that I can fill them before the task starts. | Must |
| US-02 | As a **Task PIC**, I want to be warned when a task's SPK is still not released to the vendor N2 days before its plan start date, so that I can push the release through. | Must |
| US-03 | As a **Project PIC**, I want one email per project listing tasks that have no PIC assigned, so that I can assign owners. | Must |
| US-04 | As a **Project PIC**, I want gaps on PIC-less tasks to still reach me, so that no missing SPK or BoQ is silently dropped just because nobody owns the task. | Must |
| US-05 | As a **Project Administrator**, I want to set my project's reminder frequency to daily, weekly, every N days, or one time from the Project page Reminder button, so that the cadence matches how the project actually runs. | Must |
| US-06 | As a **System Administrator**, I want to set how many days before start date each warning begins, so that the lead time matches our procurement reality. | Must |
| US-07 | As a **recipient of any of the above**, I want at most one email per project per run, so that reminders stay readable. | Must |
| US-08 | As a **recipient**, I want the same reminder to appear in my in-app notification list, so that it is not lost if I miss the email. | Should |
| US-09 | As a **Project Administrator**, I want to turn my project's reminders off entirely, so that a dormant project stops emailing people. | Should |

## 7. Requirements (high level)

1. **Detect four gap types daily** on non-deleted tasks in `in progress` projects whose status is not `finished` / `finished with note`: SPK empty, BoQ empty, SPK present but not released, no PIC assigned. *(US-01, US-02, US-03)*
2. **Track how long the SPK/BoQ gaps have persisted**, so "empty for N1 consecutive days" is a real measurement rather than a snapshot. *(US-01)*
3. **Fire the SPK/BoQ warning** only when the gap has persisted N1 days *and* the task's plan start date is within N1 days or already past. Once fired, keep including the task until the gap is closed or the task finishes. *(US-01)*
4. **Fire the not-released warning** when the task's plan start date is within N2 days or already past and the linked SPK's status is not `released`, `finished`, or `finished with note`. *(US-02)*
5. **Fire the no-PIC warning** for any in-scope task with no PIC. No day threshold applies. *(US-03)*
6. **Resolve recipients**: SPK/BoQ and not-released findings go to the task's PICs; where a task has no PIC, they fall back to the Project PICs. No-PIC findings always go to the Project PICs. *(US-01, US-02, US-03, US-04)*
7. **Group into one email per (project, recipient) per run**, with a table of findings sectioned by gap type, each row naming the task, what is missing, how long it has been missing, the plan start date, and whether it is already overdue. *(US-07)*
8. **Write a matching in-app notification** for every email sent. *(US-08)*
9. **Evaluate each project's own schedule** — `daily`, `weekly`, `custom` (every N days), `one_time`, or inactive — to decide whether that project sends today. The first send for any schedule lands on a Monday. *(US-05, US-09)*
10. **Expose read/write APIs** for the per-project schedule and the global day thresholds. *(US-05, US-06)*
11. **Retire the existing `project-task-without-spk` reminder** so the two do not both email the same people about the same tasks. *(US-07)*

Full behavior, error handling, and data shapes are specified in the [FSD](2026-08-15-task-gap-reminders-FSD.md).

## 8. Constraints & Dependencies

- **Quartz shares a persistent store with the deployed dev environment.** A schedule created from a local run appears in dev. Any manual testing must use the internal trigger endpoint, not a locally scheduled trigger.
- **Email delivery goes through `IMailerService`**, which switches between R4Mailer (default) and SMTP by the `MailerProvider` app setting. Sends are queued, so the job cannot confirm delivery — only that the message was queued.
- **Email templates are rendered by `PhantomEmailTemplates.Render`**, a flat placeholder substitution with no loop construct. The findings table must therefore be built as HTML in code and injected as a single placeholder. `EmailTemplateCatalog` must gain a sample value for that placeholder or it will report the template as having unsupported placeholders.
- **Cognitive complexity ≤ 15 per method** is a hard review gate (`CLAUDE.md`). The detection job naturally exceeds this and must be written as an orchestrator over focused helpers from the start.
- **EF migrations in this repository sweep a spurious `permission_groups`/`TempId` diff** into every generated migration. The migration for the two new tables must be hand-trimmed.
- **Depends on** `project_task_pics` (exists), `project_pics` (exists), `spks.status` (exists), `project_task_boqs` (exists), `INotificationDispatcher` (exists), `custom_configurations` (exists, reused for global settings).
- **Depends on frontend work** in the separate web repository for the Reminder-button configuration modal. The backend ships first; the API is usable via the endpoints in the FSD until then.

## 9. Assumptions

- **A1: "Release to Vendor" means the existing SPK status `released`.** Confirmed during grilling. — *Impact if wrong:* trigger 2.2 fires on the wrong condition and the whole feature needs a new SPK status added to the state machine, roughly tripling scope.
- **A2: A canceled SPK counts as "not released".** A task pointing at a canceled SPK cannot proceed, so it is treated like an unreleased one. — *Impact if wrong:* recipients get warnings about tasks they consider already dealt with.
- **A3: "Task PIC" means rows in `project_task_pics`, not the `project_tasks.assignee` column.** `project_task_pics` is the modern many-to-many table; `assignee` is a single legacy Guid. — *Impact if wrong:* the wrong people are emailed, or nobody is.
- **A4: One recipient receives only their own tasks.** A project with tasks split across two Task PICs produces two emails, each containing only that PIC's rows — not two copies of the full project table. — *Impact if wrong:* recipients see tasks they do not own, which is noise and a mild information-disclosure concern.
- **A5: Findings from the SPK/BoQ trigger and the not-released trigger are merged into one email per (project, recipient)** with separate sections, rather than two emails. Both go to the same person about the same project in the same run. — *Impact if wrong:* the literal "1 email per trigger per project" reading was wanted, and recipients get two emails; the change is a small one in the composition step.
- **A6: The "empty for N days" clock starts at the first job run after deployment, not at task creation.** Seeding from `created_at` would immediately qualify every task that has been empty for months and send a launch-day email storm. — *Impact if wrong:* the feature appears inert for the first N1 days after launch. Mitigation: seed the clock during the pre-launch dry run so it has already been ticking on go-live day.
- **A7: A project with no schedule row defaults to `weekly`, active.** Defaulting to inactive would make the feature send nothing until every project is individually configured. — *Impact if wrong:* projects that wanted silence start emailing; recoverable by setting `isActive = false`.
- **A8: The `custom` frequency's interval is counted from the last successful send, not from a fixed anchor date.** — *Impact if wrong:* cadence drifts relative to a calendar the user expected.
- **A9: Header rows (`data_type = 'header'`) and milestone tasks are in scope**, per the grilling answer that all task rows are checked. — *Impact if wrong:* recipients get warnings about summary rows that structurally can never carry an SPK or BoQ, which is the single most likely source of "this email is noise" complaints. Flagged as the highest-risk assumption; see R1.

## 10. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **R1 — Header/milestone rows flood the emails.** In a 400-task MPP import, a large share of rows are headers that will never have an SPK or BoQ, so every email is dominated by unactionable rows. | High | High | Ship the pre-launch dry run (T-09) and count what share of findings are headers. If it exceeds ~20%, revisit A9 and restrict to `data_type = 'item'` before go-live. Cheap to change: one predicate. |
| **R2 — Launch-day email storm.** Every in-progress project fires at once on the first Monday. | Medium | High | A6 grace period plus the dry run. Roll out with all projects `inactive` for one week if the dry run shows a large volume. |
| **R3 — Duplicate reminders during changeover.** The old without-SPK reminder and the new job both run. | High if not handled | Medium | T-08 removes the old Quartz trigger and endpoint in the same release, not a later one. |
| **R4 — Local development schedules leak into the deployed dev environment** through the shared Quartz store. | Medium | Medium | Detection is driven by one static daily trigger plus the internal endpoint; developers test through the endpoint and never create triggers by hand. |
| **R5 — The job silently stops firing** (Quartz misfire, unhandled exception mid-run). | Medium | High | Per-run structured log line with counts; the run is wrapped so one project's failure does not abort the rest; alert on "no run logged in 48h". |
| **R6 — Very large emails.** One PIC owning 300 gapped tasks receives an unreadable message. | Medium | Medium | Cap the table at 50 rows with a "+N more" line linking to the project. |
| **R7 — The internal trigger endpoint is unauthenticated**, matching the existing internal endpoints. Anyone who can reach the host can force a send. | Medium | Medium | Keep it on the internal route group and confirm it is not exposed by the ingress; noted as NFR-004 rather than silently inherited. |

## 11. Release & Rollout

1. **Phase 0 — dry run (pre-launch).** Deploy with the job in detect-and-log mode: gap states are written, no email is sent. Produces the G1/G2 baselines, starts the A6 clock, and answers R1 with real numbers.
2. **Phase 1 — MVP.** Enable sending. All projects default to `weekly` (A7), so the first real send is a Monday. Global thresholds seeded at N1 = 30 days, N2 = 14 days.
3. **Phase 2 — configuration UI.** Frontend adds the frequency picker to the Project page Reminder button. Until then the API is driven directly.
4. **Decommission.** The old without-SPK reminder is removed in the Phase 1 release, not left running alongside.

No feature flag beyond the dry-run mode: the per-project `is_active` field is the kill switch, and setting the global thresholds absurdly high is the emergency brake.

## 12. Open Questions

| # | Question | Owner | Blocks |
|---|---|---|---|
| Q1 | Should header and milestone rows be excluded after all? A9 says include; R1 says this is the likeliest noise source. Decide with dry-run data. | Product | Nothing — one predicate in FR-002/FR-003 |
| ~~Q2~~ | ~~Who may change the global thresholds, and under which permission key?~~ **Resolved 2026-08-15: reuse the existing guard — register on an `/api/v1` group with `R3ComponentFilter`, as `ProjectRemindersEndpoint` does. No new permission key, no `RbacRouteMaps` entry.** | — | Closed |
| Q3 | Should a project's `one_time` schedule re-arm automatically when new gaps appear, or stay off until a human re-arms it? Currently specified as stay-off. | Product | Nothing — FR-008 is decided, this is a possible follow-up |
