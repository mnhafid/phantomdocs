# FSD: SPK BoQ Improvement

| | |
|---|---|
| **Status** | Draft |
| **Related PRD** | [2026-08-26-spk-boq-improvement-PRD.md](2026-08-26-spk-boq-improvement-PRD.md) |
| **Date** | 2026-08-26 |
| **Version** | 0.1 |

## 1. System Overview

The SPK BoQ Improvement feature adds five things to the existing SPK BoQ surface:

1. **A five-step wizard** with autosaved drafts so planners do not lose mid-edit selections.
2. **Task-aware Choose BOQ** that stamps each contract line with selection state and its BOQ-tree parent.
3. **A contract-budget gate** that blocks submit when the post-write balance would go negative.
4. **A project-task walk to root** so the SPK BoQ list shows the full task ancestry.
5. **An Input Progress screen** for hourly SPK BoQ progress capture with weather, issues, remarks, and attachments.

The wizard lives behind `feature.spk_boq_wizard`; the Input Progress screen shares the same flag. The legacy `POST /api/v1/projects/tasks/boqs` stays open for one release as a fallback.

### Flow

```
planner opens Task Detail modal
        │
        ▼
GET /projects/tasks/boqs/draft?project_task_id=X
        │  404 → start blank
        │  200 → rehydrate form from payload
        ▼
planner walks Choose BOQ (GET /contracts/boqs/details)
   every row has parent_id (tree), is_selected (this task),
   start_date / end_date (this task)
        │
        ▼
planner picks lines, sets dates/volume/remarks
   autosave → POST /projects/tasks/boqs/draft  (idempotent)
   revise   → DELETE /projects/tasks/boqs/draft
        │
        ▼
planner submits → POST /projects/tasks/boqs/submit
   backend checks contract balance ≥ 0
   full-replace project_task_boqs for this task
   delete draft in same tx
        │
        ▼
SPK BoQ rows ready, then progress capture begins
   POST /spks/boqs/progress/inputs   (hourly + weather + issue + attachment)
   GET  /spks/boqs/progress/inputs?spk_boq_id=...
```

## 2. Scope

In scope: everything in PRD §1 and PRD §7.

Out of scope: per-user draft locking, supervisor approval, BOQ tree editing, status flags on `project_task_boqs`, contract/SPK value aggregation changes, anything in PRD §4.

## 3. User Flows

### 3.1 Build a Selection (Happy Path)

1. Planner opens the Task Detail modal. The FE calls `GET /projects/tasks/boqs/draft?project_task_id=`.
2. **404** → the FE opens the modal blank. **200** → the FE rehydrates the form from `payload` and reads `contract_name`, `contract_value`, `spk_remaining` to populate the Contract Selected card.
3. Planner walks to the Choose BOQ screen. The FE calls `GET /contracts/boqs/details?contract_id=…&project_task_id=…` and renders the rows as a tree using `parent_id`. Rows where `is_selected === true` are greyed out and badged.
4. Planner picks lines, fills dates/volume/remarks. On any change the FE debounces and calls `POST /projects/tasks/boqs/draft` with the in-progress payload (same shape as the eventual submit).
5. Planner presses Revise. The FE calls `DELETE /projects/tasks/boqs/draft?project_task_id=` and closes the modal. The submitted set (if any) stays untouched.
6. Planner presses Submit. The FE calls `POST /projects/tasks/boqs/submit` with the complete set.

### 3.2 Submit Blocked by Budget

1. The submit endpoint computes `newBalance = contractValue - (spkValue + submittedSetTotal)`.
2. **newBalance < 0** → the endpoint returns 400 with the exact balance. The FE surfaces the message and keeps the draft intact.

### 3.3 Progress Capture

1. SPK BoQ progress entry opens the Input Progress screen for a given `spk_boq_id`.
2. Planner picks a weather type (Bright / Drizzly / Rain / Wet), fills the hourly rows for the hours they worked, ticks Issue if there was an on-site problem, attaches files, writes remarks.
3. FE calls `POST /spks/boqs/progress/inputs` with the payload.
4. **issue = true** → backend writes a Project Diary remark attributed to the SPK BoQ in the same transaction.

## 4. Functional Requirements

### FR-001: Choose BOQ — task-aware row stamping
- **Traces to:** G2, G3 / US-02, US-04
- **Priority:** Must
- **Description:** The system must stamp each `GET /contracts/boqs/details` row with `is_selected`, `start_date`, `end_date`, and `parent_id` when the caller passes `project_task_id`.
- **Trigger / Input:** `GET /api/v1/contracts/boqs/details?contract_id=&project_task_id=`
- **Behavior:**
  - `is_selected` = `true` when the line is taken by the task, either in the submitted set (`project_task_boqs` joined to `project_task_boq_details`) or in the task's draft (parsed JSON walk).
  - When both claim the same line, the draft wins on `start_date`/`end_date`.
  - `start_date`/`end_date` are formatted `dd-MM-yyyy` and reflect the draft when present, otherwise the submitted row.
  - `parent_id` is the UUID of the row whose `breakdown` is the prefix of this row's `breakdown` (last `.` segment stripped), restricted to header rows. Empty string `""` when no header matches. Always present, regardless of `project_task_id`.
- **Validation & Errors:**
  - Empty / whitespace / non-UUID `project_task_id` → treated as absent (no stamping, no error).
  - Malformed draft payload (any shape; the walker must not throw) → that draft contributes nothing; the row's selection state reflects only the submitted set.
- **Edge cases:** Soft-deleted `project_task_boqs` rows are ignored. Empty results page still returns 200 with `data.list = []`. Pagination unchanged from existing behavior.
- **Acceptance criteria:**
  - Given a task with both a submitted line and a draft line at the same `boq_detail_id`, when the FE calls with that task's id, the row's `is_selected` is `true` and `start_date`/`end_date` come from the draft.
  - Given no `project_task_id`, when the FE calls, none of `is_selected` / `start_date` / `end_date` appears in the response (byte-identical to pre-rollout for those keys); `parent_id` is present on every row.
  - Given a row whose `breakdown` prefix matches a header row in the same BOQ, when the FE calls, that row's `parent_id` equals the header row's id.
  - Given a row whose `breakdown` prefix matches no header row, when the FE calls, that row's `parent_id` is `""`.
  - Given an item row whose `breakdown` prefix matches an item row in the same BOQ, when the FE calls, that row's `parent_id` is `""` (items are not promoted to parents).

### FR-002: Save Draft
- **Traces to:** G1, G2 / US-01, US-06
- **Priority:** Must
- **Description:** The system must accept a verbatim in-progress payload via `POST /api/v1/projects/tasks/boqs/draft` and persist it under the task's draft row, replacing any prior draft.
- **Trigger / Input:** `POST /api/v1/projects/tasks/boqs/draft` body `SetProjectTaskBoqRequest` (same shape as submit).
- **Behavior:**
  - Read `project_task_id` and `contract_id` from the body; both must parse as non-empty UUIDs.
  - Upsert into `project_task_boq_drafts` keyed on `project_task_id` (unique index).
  - Touch `updated_at` / `updated_by` on every save. The `payload` column is set to the request body as raw JSON.
  - Do not touch `project_task_boqs` or `project_tasks.contract_id`.
- **Validation & Errors:**
  - 400 + `project_task_id is required and must be a valid UUID` when the field is missing or not a UUID.
  - 400 + `contract_id is required and must be a valid UUID` likewise.
  - 400 + `Request body must be a JSON object` when the body is not a JSON object.
  - 404 + `Data not found` when the task does not exist or is soft-deleted.
- **Edge cases:** Empty `spk_boqs` array is accepted. Half-filled dates, missing `unit_id`, arbitrary extra fields — all accepted. Payload size ≤ 1 MB; over → 413.
- **Acceptance criteria:**
  - Given a planner saves a draft, when the FE later calls `GET /projects/tasks/boqs/draft`, the saved payload is returned byte-for-byte.
  - Given a planner saves twice with different bodies, when the FE later calls `GET`, the latest body is returned.

### FR-003: Load Draft
- **Traces to:** G1, G2 / US-06
- **Priority:** Must
- **Description:** The system must return the saved draft for a task, with contract context, or 404 when no draft exists.
- **Trigger / Input:** `GET /api/v1/projects/tasks/boqs/draft?project_task_id=`
- **Behavior:**
  - Return `project_task_id`, `contract_id`, `contract_name`, `contract_value`, `spk_remaining`, `payload`, `created_at`, `updated_at`.
  - `payload` is the original JSON the planner PUT, returned byte-for-byte.
  - `contract_name` / `contract_value` / `spk_remaining` come from `contracts` filtered by `DeletedAt IS NULL`. When the contract is soft-deleted or absent, all three fields are empty strings.
  - `spk_remaining` = `ContractValue -` `SpkValue`, formatted with `0.##` invariant culture.
- **Validation & Errors:**
  - 400 + `Project Task is Required` when `project_task_id` is missing, empty, whitespace, or not a UUID.
  - 404 + `Data not found` when no draft row exists.
- **Acceptance criteria:**
  - Given a saved draft for contract `C`, when the FE loads it, `contract_name` matches `C.ContractTitle`, `contract_value` matches `C.ContractValue` (formatted `0.##`), `spk_remaining` equals `ContractValue - SpkValue`.
  - Given a saved draft whose contract was soft-deleted, when the FE loads it, all three contract fields are `""` (empty string), not `null`.
  - Given no draft, when the FE loads it, the endpoint returns 404 (the FE must treat this as "no draft yet", not as an error).

### FR-004: Discard Draft (Revise)
- **Traces to:** G1 / US-05
- **Priority:** Must
- **Description:** The system must delete the saved draft for a task without touching the submitted set.
- **Trigger / Input:** `DELETE /api/v1/projects/tasks/boqs/draft?project_task_id=`
- **Behavior:** Hard-delete the row in `project_task_boq_drafts`. Submitted rows in `project_task_boqs` are untouched.
- **Validation & Errors:**
  - 400 + `Project Task is Required` for bad `project_task_id`.
  - 404 + `Data not found` when no draft exists.
- **Acceptance criteria:**
  - Given a saved draft, when the planner presses Revise, the draft row is gone and a subsequent `GET /draft` returns 404.
  - Given a task with both a draft and a submitted set, when the planner presses Revise, only the draft is gone; the submitted set survives.

### FR-005: Submit (full replace + draft consume)
- **Traces to:** G1, G3, G4 / US-03, US-06
- **Priority:** Must
- **Description:** The system must accept a complete set via `POST /api/v1/projects/tasks/boqs/submit` (or the legacy `POST /api/v1/projects/tasks/boqs`), validate the budget gate, full-replace the task's submitted set, and delete the draft in the same transaction.
- **Trigger / Input:** `POST /api/v1/projects/tasks/boqs/submit` body `SetProjectTaskBoqRequest`. Same body as legacy endpoint.
- **Behavior:**
  - Validate every `spk_boq` row (description, unit_id, start_date, end_date, type in `inline|custom`) and every `boq_detail` row (`boq_detail_id`, `unit_id`).
  - Verify the task exists and the project is `in progress`; otherwise 400.
  - Verify every `boq_detail_id` exists and belongs to the request's `contract_id`; otherwise 400.
  - Compute `submittedSetTotal` = sum of `spk.boqs[*].total_price`.
  - **Budget gate:** compute `newBalance = contract.ContractValue - (contract.SpkValue + submittedSetTotal)`. If `newBalance < 0`, return 400 with the exact number and abort. Do not write.
  - Upsert all `spk_boqs` keyed on `(project_task_id, code, description, kind)`. Detail rows keyed on `(project_task_boq_id, boq_detail_id)`. Soft-delete orphans (set `DeletedAt` / `DeletedBy`).
  - Update `project_tasks.contract_id` to the request's `contract_id`.
  - Hard-delete the draft row in the same transaction.
- **Validation & Errors:**
  - 400 + `Request body is required` when the body is missing or empty.
  - 400 + field-specific message (via `ProjectTaskBoqsJsonErrorMapper`) when a field is malformed (e.g. empty `unit_id`).
  - 400 + `Data not found` mapped to 404 when the task does not exist.
  - 400 + `You cannot set the SPK BoQ because the Project Details' status is not yet In Progress` when the project is not in progress.
  - 400 + `BoQ Detail ID Not Found` / `BoQ Detail ID Invalid : <id>` for invalid boq detail ids.
  - 400 + `Contract remaining balance would be <amount>; cannot submit` for budget gate failures.
- **Edge cases:**
  - Failed validation never touches `project_task_boqs` or deletes the draft.
  - Submit returns no `data`; the FE re-`GET`s the task boqs to pick up the new ids.
- **Acceptance criteria:**
  - Given a complete payload, when the FE submits, every row not in the payload is soft-deleted; every row in the payload is upserted; the draft is gone.
  - Given a payload whose total would make `newBalance < 0`, when the FE submits, the response is 400 with the exact computed balance; no rows are written; the draft survives.

### FR-006: Contract balance snapshot on draft load
- **Traces to:** G4 / US-03
- **Priority:** Must
- **Description:** See FR-003 — `spk_remaining` is the contract's current balance, not a snapshot of submission state. This FR describes the wiring, not a new endpoint.

### FR-007: Project Task Detail — `estimated_cost_idr`
- **Traces to:** G4 / US-03
- **Priority:** Must
- **Description:** The system must include `estimated_cost_idr` in the Project Task Detail response so the FE's Contract Selected card can show the current estimation cost.
- **Trigger / Input:** Existing `GET /api/v1/projects/tasks/{id}` endpoint.
- **Behavior:** Map `project_tasks.estimated_cost` (or `EstimatedCost`) into a new `estimated_cost_idr` field in the response DTO. Currency IDR is the only supported currency for the wizard v1.
- **Validation & Errors:** None — passthrough field. Null when the source column is null.
- **Acceptance criteria:** Given a task with `estimated_cost = 250000`, when the FE calls Task Detail, the response includes `estimated_cost_idr: "250000"`. Null when unset.

### FR-008: Project-task hierarchy walk to root
- **Traces to:** G2 / US-04
- **Priority:** Must
- **Description:** The system must walk the project-task chain to root when assembling the SPK BoQ list, so the FE can show the full task ancestry.
- **Trigger / Input:** Existing SPK BoQ list endpoints (the List endpoint called from Project Overview AFTER SPK BOQ CREATED).
- **Behavior:** Resolve each task's ancestors up to the root via `project_tasks.parent_unique_id`. Include each ancestor's id and description in the response row, so the FE can render `Root / Parent / Leaf`. The walk stops at the row whose `parent_unique_id IS NULL`.
- **Validation & Errors:** Cycles (a row's parent chain revisiting itself) terminate at the first revisit. Orphans (a row whose `parent_unique_id` points to a missing row) terminate at the missing link.
- **Acceptance criteria:**
  - Given a 3-level task chain A → B → C → (root), when the FE lists SPK BoQs for C, the response includes the ancestry of C up to and including A.
  - Given a 1-level task (its own root), the response includes just that one row in the ancestry.

### FR-009: Submit budget gate (semantics)
- **Traces to:** G4 / US-03
- **Priority:** Must
- **Description:** See FR-005 step "Budget gate". This FR records the semantic choice (post-write balance, not pre-write) and its rationale: the planner's submit must reflect the SPK value that would land, so a partial-submit trap is impossible. Documented as PRD A9.

### FR-010: Input Progress — capture hourly progress with weather, issue, remarks, attachments
- **Traces to:** G5 / US-07, US-08
- **Priority:** Must
- **Description:** The system must accept an Input Progress payload for an SPK BoQ and persist it; issues flow into Project Diary.
- **Trigger / Input:** `POST /api/v1/spks/boqs/progress/inputs` body `{ spk_boq_id, weather_type, hours: [{ start_minute, end_minute, actual_volume?, physical_progress?, remarks? }], issue: bool, remarks?, attachments: [attachment_id, ...] }`.
- **Behavior:**
  - Validate `weather_type ∈ {Bright, Drizzly, Rain, Wet}`.
  - Cap at 24 hour rows; reject extras.
  - Persist the input row; persist hour rows; link attachments; if `issue = true`, write a Project Diary remark attributed to the SPK BoQ (same transaction).
- **Validation & Errors:**
  - 400 + `weather_type must be one of Bright|Drizzly|Rain|Wet` for invalid values.
  - 400 + `hours cannot exceed 24 entries` for over-cap.
  - 400 + `spk_boq_id is required and must be a valid UUID` when missing or bad.
  - 404 + `Data not found` when the SPK BoQ does not exist or is soft-deleted.
- **Edge cases:** Empty `hours` array is accepted. `attachments` empty array is accepted. `remarks` empty is accepted.
- **Acceptance criteria:**
  - Given a planner submits an input with `issue = true` and `remarks = "Generator fuel spill"`, when the endpoint persists, a Project Diary remark with that body exists, attributed to the SPK BoQ.
  - Given an input with 25 hour rows, when the FE submits, the endpoint returns 400; no rows are written.
  - Given an input with `weather_type = "Storm"`, when the FE submits, the endpoint returns 400 (Storm is not a valid value in v1).

### FR-011: List Input Progress
- **Traces to:** G5 / US-07
- **Priority:** Must
- **Description:** The system must return the input rows for a given SPK BoQ, ordered by `created_at` descending.
- **Trigger / Input:** `GET /api/v1/spks/boqs/progress/inputs?spk_boq_id=`
- **Behavior:** Return up to N most-recent input rows for the SPK BoQ, with their hour rows inlined.
- **Acceptance criteria:** Given 3 inputs for SPK BoQ X, when the FE lists them, the response returns 3 rows, newest first, each with its hour rows.

## 5. Data Model

### New table

```sql
project_task_boq_drafts
  id              uniqueidentifier PRIMARY KEY
  project_task_id uniqueidentifier NOT NULL  -- UX_project_task_boq_drafts_project_task_id
  contract_id     uniqueidentifier NOT NULL
  payload         nvarchar(max)    NOT NULL
  created_at      datetime         NOT NULL
  created_by      uniqueidentifier NOT NULL
  updated_at      datetime         NULL
  updated_by      uniqueidentifier NULL
```

JSON payload stored via the existing `JsonElementConverter` (per `phantomdb-jsonelement-other-column.md`). Reuse, no new converter.

### Modified tables / columns

- `project_tasks.contract_id` — already a nullable UUID; the submit endpoint overwrites it. No migration needed.
- `project_tasks.estimated_cost` / `EstimatedCost` — already a nullable `double`; FR-007 maps it into `estimated_cost_idr` in the response DTO. No migration needed.

### Input Progress schema (new)

```
spk_boq_progress_inputs
  id              uniqueidentifier PRIMARY KEY
  spk_boq_id      uniqueidentifier NOT NULL  -- FK to spk_boqs
  weather_type    nvarchar(20)     NOT NULL  -- Bright|Drizzly|Rain|Wet
  issue           bit              NOT NULL
  remarks         nvarchar(max)    NULL
  created_at      datetime         NOT NULL
  created_by      uniqueidentifier NOT NULL

spk_boq_progress_input_hours
  id                    uniqueidentifier PRIMARY KEY
  progress_input_id      uniqueidentifier NOT NULL  -- FK to spk_boq_progress_inputs
  start_hour            int             NOT NULL  -- 0..23
  end_hour              int             NOT NULL  -- 1..24; start < end
  actual_volume         decimal(18,4)   NULL
  physical_progress     decimal(5,2)    NULL
  remarks               nvarchar(max)   NULL

spk_boq_progress_input_attachments
  progress_input_id  uniqueidentifier NOT NULL
  attachment_id      uniqueidentifier NOT NULL
  PRIMARY KEY (progress_input_id, attachment_id)
```

### Retention / PII

No new PII. Draft payloads may contain contract numbers and unit prices — same sensitivity as the submitted set, which is already covered. Input Progress attachments go to MinIO under the same bucket as other project attachments.

## 6. Interfaces

### Modified endpoints

| Method | Path | Notes |
|---|---|---|
| GET | `/api/v1/contracts/boqs/details` | + optional `project_task_id`. New `parent_id` field on every row. (FR-001) |
| POST | `/api/v1/projects/tasks/boqs/draft` | Was PUT in original spec; changed to POST per FE. (FR-002) |
| GET  | `/api/v1/projects/tasks/boqs/draft?project_task_id=` | + contract fields in response. (FR-003) |
| DELETE | `/api/v1/projects/tasks/boqs/draft?project_task_id=` | (FR-004) |
| POST | `/api/v1/projects/tasks/boqs/submit` | New alias; budget gate. (FR-005) |
| POST | `/api/v1/projects/tasks/boqs` | Legacy; shares handler with `/submit`. (FR-005) |
| GET  | `/api/v1/projects/tasks/{id}` | + `estimated_cost_idr` field. (FR-007) |
| (List SPK BoQ endpoints) | Various | + project-task ancestry to root. (FR-008) |

### New endpoints

| Method | Path | Notes |
|---|---|---|
| POST | `/api/v1/spks/boqs/progress/inputs` | (FR-010) |
| GET  | `/api/v1/spks/boqs/progress/inputs?spk_boq_id=` | (FR-011) |

### Consumed / produced events

None. All synchronous HTTP.

### Auth

Bearer token + `R3ComponentFilter` on every endpoint. No new permission roles in v1.

### Error code conventions

All endpoints return the standard envelope: `{ process_time, status, code, message, data }`. Validation errors map to 400 with a human-readable message; missing data → 404; unhandled exceptions → 500 + `logger.LogError`.

## 7. Non-Functional Requirements

### NFR-001: Performance — list endpoints
- **Requirement:** `GET /contracts/boqs/details` with `project_task_id` p95 ≤ 400 ms on the dev dataset; the parent-id stamping adds at most one extra SQL round-trip per request (single batched query by `BoqId + Code IN (...)`).
- **Traces to:** G2

### NFR-002: Performance — submit
- **Requirement:** `POST /projects/tasks/boqs/submit` p95 ≤ 800 ms including the budget-gate arithmetic. The contract value read joins the existing `Contracts` table by primary key; no extra indices required.

### NFR-003: Payload size
- **Requirement:** Draft payloads are capped at 1 MB. Over → 413 with message `Draft payload exceeds 1 MB`.
- **Traces to:** Risk (draft payload growth).

### NFR-004: Security — no privilege escalation
- **Requirement:** Wizard endpoints reuse the standard `R3ComponentFilter` and bearer; no new permission roles. The submit endpoint must reject calls when the project is not `in progress` — same as the legacy submit.
- **Traces to:** PRD §8.

### NFR-005: Observability
- **Requirement:** Every wizard endpoint logs `endpoint`, `project_task_id`, `actor_user_id`, `process_time_ms`, and outcome (`success|bad_request|not_found|server_error`). Submit additionally logs the computed `newBalance` so budget-gate failures are auditable. Input Progress logs `weather_type`, `hour_count`, `issue`.

### NFR-006: Backward compatibility — byte-identical default response
- **Requirement:** When `project_task_id` is omitted on `GET /contracts/boqs/details`, the response is byte-identical to pre-rollout for the three task-allocation keys (`is_selected`, `start_date`, `end_date`). The only new field always present is `parent_id`.

## 8. Permissions & Roles

| Endpoint | Planner | Approver (future) | Admin |
|---|---|---|---|
| All wizard endpoints | ✅ (v1) | (not in v1) | ✅ |
| Submit | ✅ | (not in v1) | ✅ |
| Input Progress | ✅ | (not in v1) | ✅ |

v1 inherits the existing `R3ComponentFilter`. v1 has a single role (SPK planner) per PRD A1.

## 9. Analytics & Telemetry

| Event | Properties | When | Maps to |
|---|---|---|---|
| `wizard_open` | `project_task_id` | Task Detail modal opens | G1, G2 baseline |
| `wizard_draft_save` | `project_task_id`, `payload_bytes` | POST /draft success | G1, G5 (proxy) |
| `wizard_submit` | `project_task_id`, `submitted_lines`, `submitted_total`, `new_balance` | POST /submit success | G1, G2, G4 |
| `wizard_submit_blocked` | `project_task_id`, `new_balance`, `submitted_total` | POST /submit 400 budget gate | G4 |
| `wizard_revise` | `project_task_id` | DELETE /draft success | G1 |
| `progress_input_saved` | `spk_boq_id`, `weather_type`, `hour_count`, `issue` | POST /inputs success | G5 |
| `boq_detail_double_pick` | `project_task_id`, `boq_detail_id` | FR-001 stamps detect a second claim attempt (future) | G3 |

G3 measurement today uses a SQL audit query (run monthly) until the analytics event ships.

## 10. Traceability Matrix

| PRD Goal / Story | FRs | NFRs |
|---|---|---|
| G1 (no mid-edit loss) | FR-002, FR-003, FR-004, FR-005 | NFR-003 |
| G2 (median time drops) | FR-001, FR-005, FR-008 | NFR-001 |
| G3 (no double-pick) | FR-001 | NFR-006 |
| G4 (no over-budget) | FR-005, FR-007, FR-009 | NFR-002, NFR-005 |
| G5 (structured progress) | FR-010, FR-011 | NFR-005 |
| US-01 | FR-002 | — |
| US-02 | FR-001 | NFR-006 |
| US-03 | FR-005, FR-007, FR-009 | NFR-002 |
| US-04 | FR-001, FR-008 | — |
| US-05 | FR-004 | — |
| US-06 | FR-002, FR-003, FR-005 | — |
| US-07 | FR-010, FR-011 | NFR-005 |
| US-08 | FR-010 | — |

## 11. Open Questions

| ID | Question | Owner | Blocks |
|---|---|---|---|
| Q1 | Wizard-open logging — does it ship before or with the wizard? | FE / Backend | G2 baseline |
| Q2 | Does `parent_unique_id` form a clean chain to root for all current data? | Backend | FR-008 implementation |
| Q3 | Existing `attachments` table reused, or new domain for Input Progress? | Backend | FR-010 |
| Q4 | Budget-gate 400 body — exact message format | Product + FE | FR-005 wording |
| Q5 | Should the wizard flag `feature.spk_boq_wizard` be a single flag for all four areas, or split per area? | Backend + DevOps | Release plan |
| Q6 | Input Progress attachments: same MinIO bucket / prefix as Project Diary attachments? | Backend | FR-010 |
| Q7 | Submit returns no data; FE re-`GET`s. Confirm no client wants the new ids in the response body. | FE | FR-005 response shape |