# PRD: SPK BoQ Improvement

| | |
|---|---|
| **Status** | Draft |
| **Author** | Claude (grilled with mnhafid) |
| **Date** | 2026-08-26 |
| **Version** | 0.1 |
| **Related docs** | [2026-08-26-spk-boq-improvement-FSD.md](2026-08-26-spk-boq-improvement-FSD.md), [2026-08-26-spk-boq-improvement-TICKETS.md](2026-08-26-spk-boq-improvement-TICKETS.md), parent Notion page [SPK Boq Improvement](https://app.notion.com/p/3b3c1ab45b9780729889ebe1e54b3385) |

## 1. Overview

The SPK (Surat Perintah Kerja) BoQ feature lets a planner pick which contract-line items a project task consumes. Today the planner works inside a single submit-and-pray step: any line lost mid-edit is gone, the BOQ does not tell the planner which lines another task already took, and a contract can be over-spent without warning at submit time. The Input Progress screen adds another pain — there is no structured way to record weather, hourly progress, and on-site issues against an SPK BoQ. This work turns the SPK BoQ into a five-step wizard with autosaved drafts, makes the BOQ list task-aware, blocks submit when the contract budget goes negative, lets the BOQ list walk the project-task hierarchy to root, and adds an Input Progress screen for hourly progress capture with weather, issues, and attachments. It serves one role: the SPK planner. It is needed now because the wizard is the entry point for every SPK and the missing draft and budget gates have already cost planners real work.

## 2. Problem Statement

Four concrete problems, all visible in production data or confirmed by the FE team:

1. **No mid-edit recovery.** The current POST `/projects/tasks/boqs` is a full-replace atomic step. Planners who close the modal mid-edit, hit a network error, or get pulled away lose the entire selection. There is no in-progress state to resume from. Verified by the FE team: planners regularly re-build selections from scratch.
2. **Planners double-pick the same contract line.** Today `GET /contracts/boqs/details` returns the contract's BOQ lines without saying which lines another project task on the same contract already took. A planner can pick the same line twice and only one wins at submit time, with no signal at the picker. This corrupts SPK value at the aggregation level.
3. **Contract budget can be silently exceeded at submit.** The Contract Selected card shows remaining contract budget, current estimation cost, and remaining balance. Today a negative remaining balance blocks nothing — the submit goes through and the SPK value inflates past the contract ceiling. The FE team flagged this as a hard requirement to gate at submit time.
4. **No structured progress entry.** Once an SPK BoQ is submitted, progress capture has no Input Progress screen. SPK BoQ progress currently lands as raw ad-hoc remarks with no weather, no hourly breakdown, no issue flag, no attachment. Verified against the existing `spk_boq_progress` table which only stores aggregate numbers.

## 3. Goals & Success Metrics

| ID | Goal | Metric | Target |
|---|---|---|---|
| G1 | Planners never lose mid-edit selections | % of wizards opened that reach a successful submit | ≥ 85% within 30 days of rollout |
| G2 | Median time to complete the wizard drops meaningfully | Median time from wizard open to successful submit | ≤ 70% of the pre-rollout baseline within 30 days |
| G3 | Double-picking the same contract line stops | Duplicate `project_task_boq_details` rows per `project_task_id` at monthly check | 0 |
| G4 | Negative-remaining-balance submits stop | Contract budget overruns detected at submit time | ≥ 1 caught per month that would have shipped pre-rollout |
| G5 | Progress capture has structured weather, hourly breakdown, issues, and attachments | `spk_boq_progress_inputs` rows with non-null `weather_type` / at least one hour row / `issue` set when applicable | ≥ 95% within 30 days |

## 4. Non-Goals

| Not doing | Why cut |
|---|---|
| Per-user draft locking | Two planners on the same task overwrite each other silently. Agreed in the parent Notion page as the v1 trade-off; revisit if the workflow needs it. |
| Supervisor approval step between draft and submit | v1 is planner-only. Add later if accounting / project-control needs sign-off. |
| Editing the BOQ tree from this wizard | `parent_id` is read-only. FE renders the tree; planners cannot edit the BOQ hierarchy. |
| Migrating in-progress pre-existing selections into drafts | v1 is greenfield; nothing to migrate. The legacy POST `/projects/tasks/boqs` path stays open during transition. |
| Changing the project-task status lifecycle | `project_tasks.status` is taken by the `not started → in progress → finished` state machine. Overloading it breaks that. |
| Adding status flags to `project_task_boqs` | That table is read at ~13 sites across 6 other services. Missing one site means a draft line inflates SPK value or progress cost — silent, and it is money. |
| Changing contract / SPK value aggregation logic | Out of scope; the wizard only consumes existing aggregates. |

## 5. Users & Personas

| Persona | Description | Key need |
|---|---|---|
| SPK Planner | Builds and revises SPK BoQ selections per project task, captures progress. The single role for v1. | To build a selection without losing it mid-edit, see which lines another task already took, be told at submit time when the contract is over-budget, and capture progress with structured data. |

## 6. User Stories

| ID | Story | Priority (MoSCoW) |
|---|---|---|
| US-01 | As an SPK planner, I want to autosave the wizard's in-progress selection as I work, so that closing the modal mid-edit does not lose my work. | Must |
| US-02 | As an SPK planner, I want to see which contract lines another task already took when I open the Choose BOQ screen, so that I do not double-pick. | Must |
| US-03 | As an SPK planner, I want to be told at submit time when the contract remaining balance would go negative, so that I cannot overspend a contract silently. | Must |
| US-04 | As an SPK planner, I want to render the Choose BOQ as a tree (header rows containing items), so that I can navigate large BOQs without scrolling a flat list. | Must |
| US-05 | As an SPK planner, I want to discard an in-progress selection (Revise), so that I can start over. | Must |
| US-06 | As an SPK planner, I want the wizard to resume from the saved draft when I re-open the task, so that I do not re-build a half-done selection. | Must |
| US-07 | As an SPK planner, I want to capture progress against an SPK BoQ with weather, hourly breakdown, issue flag, remarks, and attachments, so that progress is structured. | Must |
| US-08 | As an SPK planner, I want issues captured at the progress screen to flow into Project Diary, so that on-site problems land in the diary without re-entry. | Must |

## 7. Requirements (high level)

1. Five-endpoint wizard: `GET /contracts/boqs/details` (with `project_task_id` query + `parent_id`), `POST /projects/tasks/boqs/draft`, `GET /projects/tasks/boqs/draft`, `DELETE /projects/tasks/boqs/draft`, `POST /projects/tasks/boqs/submit` (new explicit alias for the legacy `POST /projects/tasks/boqs`). Detail in FSD §4.
2. New `project_task_boq_drafts` table — one row per `project_task_id`, payload as `nvarchar(max)` JSON. Existence IS the draft state; submit deletes the row in the same transaction.
3. `parent_id` field on every `GET /contracts/boqs/details` row, computed by stripping the last `.` segment from `breakdown` and matching a header row in the same BOQ. Empty string when no parent.
4. Contract context on `GET /projects/tasks/boqs/draft`: `contract_name`, `contract_value`, `spk_remaining`. Sourced from the `contracts` row referenced by the draft. Empty strings when the contract is soft-deleted.
5. Submit gate: when `contract.ContractValue - contract.SpkValue < 0` after applying the submitted set, return 400 with the computed balance and refuse to write.
6. `project_tasks.estimated_cost_idr` added to the Project Task Detail response so the Contract Selected card can show current estimation cost.
7. Project task hierarchy walk: List SPK BoQ endpoint extends the project-task walk to root. Implementation detail: a recursive CTE or app-level loop, depending on existing pattern.
8. New Input Progress screen backed by `POST /api/v1/spks/boqs/progress/inputs` and `GET .../inputs?spk_boq_id=`. Payload: weather type enum, optional hourly rows for `00:00–23:00` in 1h increments, issue boolean, remarks, attachments.
9. Issue boolean flows into `project_diary` as a remark row, attributed to the SPK BoQ.

The full behavior, edge cases, and error codes live in the FSD.

## 8. Constraints & Dependencies

- **Stack constraint.** phiDev (.NET 8, EF Core, Carter-style endpoints, in-process Quartz, MinIO for files). No new dependencies; the existing `JsonElementConverter` (already wired for `projects.other` and similar) handles the draft payload.
- **DB constraint.** Postgres via the existing `PhantomDbContext` partial-class split. Migration must be additive; no schema rewrites.
- **Concurrency constraint.** Draft upsert is last-write-wins. No row-level locking, no optimistic concurrency token. Documented in the parent Notion page.
- **Tenant constraint.** All entities inherit tenant scoping from existing services. No new cross-tenant surface.
- **Permissions constraint.** Endpoints inherit the standard `R3ComponentFilter` and bearer auth. No new role-based gates in v1.

## 9. Assumptions

| ID | Assumption | Impact if wrong |
|---|---|---|
| A1 | Single user role (SPK planner) for v1. No approver / supervisor step. | Reopen PRD; add G6 + US for approval workflow; tickets T-X approval queue. |
| A2 | "Time to submit" baseline median is measurable from existing logs (last successful submit timestamp minus wizard open timestamp, when the latter is logged). | If wizard-open is not logged, the G2 metric becomes indirect (e.g. percent submitted within one session). Add a wizard-open log event first. |
| A3 | Median time to submit drops by ≥30% post-rollout. | If the actual drop is smaller, the G2 target fails but the feature is still shipped. Re-tune the target, not the feature. |
| A4 | Input Progress weather enum is fixed: Bright / Drizzly / Rain / Wet. | If a fifth value is needed (e.g. Storm), add as an enum extension; no schema migration since the column is `nvarchar`. |
| A5 | Hourly time range is fixed at 24 one-hour slots starting 00:00. Half-hour granularity is out of scope. | If half-hour is needed, the column model changes (start_minute + end_minute or two columns per hour). Defer; revisit if requested. |
| A6 | Issue boolean is sufficient; no separate severity enum. | If severity is needed, add an enum column and a migration. |
| A7 | Attachments use the existing MinIO infrastructure with the existing `attachments` table. | If a new attachment domain is needed (e.g. separate bucket), backend work multiplies. |
| A8 | Project-task hierarchy walk to root can be done with a recursive CTE on the `project_tasks` table using `parent_unique_id`. | If `parent_unique_id` is empty / inconsistent for older data, walk falls back to one-level. Validate before launch. |
| A9 | Submit-time contract balance check uses the post-write balance (contract value minus sum of SPK values after this submit lands). | If the check should be pre-write, the rollback story changes. Document the chosen semantics in FSD §4. |
| A10 | The `parent_id` matching rule excludes non-header rows (an item at the same depth is not a parent). | If item-as-parent is wanted, drop the header filter. Low-likelihood; flagged. |

## 10. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Two planners overwrite each other's draft silently | Medium | Low (per A1 trade-off) | UI warning banner. Surface `updated_at` to the FE so it can detect local-vs-server staleness. |
| Draft payload grows large for a big BOQ | Low | Medium (request size, JSON parse cost) | Bound payload size to 1 MB; reject with 413. Add an integration test with a synthetic 999-line payload. |
| Negative-balance submit gate trips too often (false positives) | Low | Medium (planner blocked) | Compute balance using `ContractValue - SpkValue` (post-write). Surface the exact number in the 400 body so the planner can adjust. |
| Migration ships without `phantomdb-migration-snapshot-drift` regression | High | High (CI / deploy breaks) | Run migration snapshot sync locally before merge; pre-flight check via DBeaver SQL. |
| `parent_id` mismatch across FE renderings | Low | Low | Pin the strip-last-segment rule in the FSD; lock the test file (`BoqDetailParentAndDraftContractTests`). |
| Input Progress hourly payload explosion | Low | Low | Cap at 24 rows per submit; reject extras with 400. |
| Project-task hierarchy recursion stack overflow | Low | Medium | Recursive CTE in SQL, not app-level loop. |

## 11. Release & Rollout

- **v1 (this PRD)** ships all five endpoint changes, the budget gate, the hierarchy walk, and the Input Progress screen behind a single feature flag: `feature.spk_boq_wizard`. Default OFF in dev, ON in staging.
- **Toggle day**: the wizard switch flips to ON in production. The legacy `POST /projects/tasks/boqs` stays open for one release as a fallback.
- **Cleanup**: feature flag retired after two releases of stable wizard usage; legacy POST removed at that point.
- **Comms**: short note in `#phi-fe` and `#phi-be` summarizing the new routes + the budget gate. FE team briefed on the wizard flow + the `parent_id` tree render.
- **Monitoring**: `wizard_open_total` and `wizard_submit_total` counters, plus `wizard_abandon_total` (last draft save without submit within 24h).

## 12. Open Questions

| ID | Question | Owner | Blocks |
|---|---|---|---|
| Q1 | Should the wizard-open event be logged before the wizard is shipped, so the G2 baseline exists? | FE team | G2 measurement |
| Q2 | Does `parent_unique_id` on `project_tasks` form a clean chain to root for all current data, or do some rows need backfill? | Backend | FR for hierarchy walk |
| Q3 | Is `attachments` (or whichever existing table) reused for Input Progress attachments, or is a new table required? | Backend | FR for attachments |
| Q4 | Should the budget gate's 400 message include the SPK value breakdown (so the planner knows which line tipped it over)? | Product | FR wording |