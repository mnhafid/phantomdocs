# Tickets: SPK BoQ Improvement

Source: [2026-08-26-spk-boq-improvement-FSD.md](2026-08-26-spk-boq-improvement-FSD.md) (v0.1) · Coverage: 11 FRs + 6 NFRs → 11 tickets, all FRs covered

## Summary

| ID | Title | Epic | Size | Blocked by | Covers |
|---|---|---|---|---|---|
| T-01 | Add `parent_id` to Choose BOQ response | E2 | S | — | FR-001 (parent_id part) |
| T-02 | Add contract fields to Load Draft response | E1 | S | — | FR-003 (contract fields) |
| T-03 | Add POST `/projects/tasks/boqs/submit` alias route | E1 | S | — | FR-005 (alias) |
| T-04 | Wire submit-time contract budget gate | E3 | M | T-03 | FR-005 (budget gate), FR-009, NFR-002, NFR-005 |
| T-05 | Add `estimated_cost_idr` to Project Task Detail | E3 | S | — | FR-007 |
| T-06 | Extend List SPK BoQ to walk project-task hierarchy to root | E4 | M | — | FR-008 |
| T-07 | Migration: `project_task_boq_drafts` table | E1 | S | — | Data model §5 |
| T-08 | Migration: Input Progress tables | E5 | S | — | Data model §5 (Input Progress) |
| T-09 | Input Progress POST endpoint | E5 | M | T-08 | FR-010 |
| T-10 | Issue → Project Diary remark wiring | E5 | S | T-09 | FR-010 (issue flow) |
| T-11 | Input Progress GET endpoint | E5 | S | T-09 | FR-011 |
| T-12 | Feature flag + wizard_open / wizard_submit telemetry [infra] | E1 | M | T-01, T-02, T-03, T-04 | NFR-005 |

## Epics

- **E1 — Wizard drafts:** Save / load / discard / submit the in-progress BoQ selection. Five-step wizard data plane.
- **E2 — Choose BOQ stamping:** Make the BOQ list task-aware (is_selected / start / end / parent_id) so the FE can render the tree and disable already-taken rows.
- **E3 — Submit budget gate:** Block submit when the contract would go negative; surface the exact balance to the planner.
- **E4 — Project task hierarchy walk to root:** SPK BoQ list shows the full task ancestry up to the root.
- **E5 — Input Progress:** Hourly progress capture with weather, issue flag, remarks, attachments; issue → Project Diary.

---

## T-01: Add `parent_id` to Choose BOQ response

- **Epic:** E2 · **Size:** S · **Priority:** Must · **Blocked by:** —
- **Covers:** FR-001 (parent_id part)

**Context**
`GET /api/v1/contracts/boqs/details` returns a flat list of BOQ lines. The FE needs to render the BOQ as a tree using the `breakdown` hierarchy (e.g. `TBL.1.1.` → `TBL.1.1.1.`), but today each row has no pointer to its parent. A `parent_id` field lets the FE build the tree client-side without walking the full BOQ.

**Scope of work**
- Add `parent_id` to `BoqDetailDto`. Type `string`, default `""` (empty string for top-level rows or when no parent matches).
- Implement `ApplyParentIdsAsync(items, ct)` in `BoqsService.cs`: collect distinct parent breakdowns, fetch matching `BoqDetails` rows filtered to `DataType == "header"`, build `(BoqId, Code) → Id` map, assign each item.
- Call it after `ApplyTaskSelectionAsync` in both `GetBoqDetailsAsync` (paged) and `GetAllBoqDetailsAsync` (full).
- Helper `StripLastSegment(string?)` strips the last `.`-separated segment while preserving the trailing `.`.
- Tests: tree hierarchy (item→subheader, subheader→top, top→"", orphan→"", non-header not promoted).

**Acceptance criteria**
- Given a row whose `breakdown` is `TBL.1.1.1.` and a header row `TBL.1.1.`, when the FE calls `GET /details`, the first row's `parent_id` equals the header row's UUID.
- Given a top-level header `TBL.`, when the FE calls, `parent_id` is `""`.
- Given an item row whose prefix matches another item row (not a header), when the FE calls, `parent_id` is `""`.
- Given no `project_task_id` is passed, when the FE calls, every row still has `parent_id` (the field is always present).

**Out of scope**
- The three task-allocation keys (`is_selected` / `start_date` / `end_date`) — handled by `ApplyTaskSelectionAsync`, already shipped.

**Test notes**
- Use `BoqDetailTaskSelectionTests`-style fixture with seeded header + item rows.
- Cover: tree depth, orphan prefix, non-header-not-promoted.

---

## T-02: Add contract fields to Load Draft response

- **Epic:** E1 · **Size:** S · **Priority:** Must · **Blocked by:** —
- **Covers:** FR-003 (contract fields)

**Context**
`GET /projects/tasks/boqs/draft?project_task_id=` returns the saved payload. The FE's Contract Selected card shows remaining budget and current estimation cost. Without the contract fields on this response the FE would have to make a second round-trip to `GET /contracts/{id}` on every modal open.

**Scope of work**
- Add `ContractName` / `ContractValue` / `SpkRemaining` to `ProjectTaskBoqDraftResponse`. All `string`, default `""`.
- In `GetProjectTaskBoqDraftAsync`, after fetching the draft row, query `Contracts` filtered on `DeletedAt IS NULL` and select `(ContractTitle, ContractValue, SpkValue)`.
- `SpkRemaining = ContractValue - SpkValue`, format with `0.##` invariant culture.
- Empty strings when the contract is missing / soft-deleted — never `null`, never omitted.

**Acceptance criteria**
- Given a saved draft whose contract has `ContractTitle="X"`, `ContractValue=1000000`, `SpkValue=250000`, when the FE loads, `contract_name="X"`, `contract_value="1000000"`, `spk_remaining="750000"`.
- Given a saved draft whose contract was soft-deleted, when the FE loads, all three fields are `""`.
- Given a contract whose `SpkValue` equals `ContractValue`, when the FE loads, `spk_remaining="0"`.

**Out of scope**
- Estimated-cost field — separate ticket T-05.

**Test notes**
- Test the empty-string fallback path explicitly (the FE should treat empty as "missing", not "zero").

---

## T-03: Add POST `/projects/tasks/boqs/submit` alias route

- **Epic:** E1 · **Size:** S · **Priority:** Must · **Blocked by:** —
- **Covers:** FR-005 (alias)

**Context**
The wizard's final step ("SUBMIT") needs an explicit semantic path. The legacy `POST /projects/tasks/boqs` exists and is correct, but the wizard uses `/submit` to make the intent unambiguous.

**Scope of work**
- Extract the body of `MapSetProjectTaskBoq` (the legacy POST handler) into a private static method `SubmitProjectTaskBoqHandler`.
- `MapSetProjectTaskBoq` calls the handler at `POST /projects/tasks/boqs`.
- Add `MapSubmitProjectTaskBoq` calling the same handler at `POST /projects/tasks/boqs/submit`.
- Same `WithName`, `WithDescription`, error mapping.

**Acceptance criteria**
- Given a valid submit body sent to `POST /projects/tasks/boqs/submit`, when the endpoint runs, the same effect as the legacy endpoint (full replace + draft consume in one tx).
- Given a malformed body, when sent to either path, the same error response from either path.
- Route table shows both `/projects/tasks/boqs` (POST) and `/projects/tasks/boqs/submit` (POST) registered.

**Out of scope**
- The budget-gate logic — separate ticket T-04.

**Test notes**
- No new test needed; existing SetProjectTaskBoq tests cover the shared handler.

---

## T-04: Wire submit-time contract budget gate

- **Epic:** E3 · **Size:** M · **Priority:** Must · **Blocked by:** T-03
- **Covers:** FR-005 (budget gate), FR-009, NFR-002, NFR-005

**Context**
The Contract Selected card shows remaining contract budget. Today a negative remaining balance blocks nothing — submit goes through and SPK value inflates past the contract ceiling. The FE team requires this as a hard gate at submit time.

**Scope of work**
- In `SetProjectTaskBoqAsync` (service), after validation and before the writes:
  - Compute `submittedSetTotal = sum(spk.boqs[*].total_price)`.
  - Read `contract.ContractValue` and `contract.SpkValue` (already in scope via the contract-id check).
  - Compute `newBalance = ContractValue - (SpkValue + submittedSetTotal)`.
  - If `newBalance < 0`, throw `InvalidOperationException($"Contract remaining balance would be {newBalance}; cannot submit")`. The endpoint mapper returns 400.
- Do not enter the transaction; do not delete the draft; do not touch `project_task_boqs`.
- Log `wizard_submit_blocked` with `project_task_id`, `newBalance`, `submittedSetTotal` (NFR-005).

**Acceptance criteria**
- Given a payload whose `submittedSetTotal` makes `newBalance < 0`, when the FE submits, the endpoint returns 400 with the exact balance; no rows are written; the draft survives.
- Given a payload whose `submittedSetTotal` makes `newBalance >= 0`, when the FE submits, the endpoint proceeds as before.
- Given a contract that does not exist, when the FE submits, the endpoint still returns the legacy 400 (`BoQ Detail ID Invalid`) — the budget gate runs after the existing checks.

**Out of scope**
- Pre-write balance check (semantic is post-write, per PRD A9).
- Per-SPK breakdown of which line tipped the balance over.

**Test notes**
- Edge: `newBalance = 0` exactly (must be allowed, not blocked).
- Edge: contract soft-deleted between save and submit → existing behavior (existing contract lookup should be added or guarded).

---

## T-05: Add `estimated_cost_idr` to Project Task Detail

- **Epic:** E3 · **Size:** S · **Priority:** Must · **Blocked by:** —
- **Covers:** FR-007

**Context**
The Contract Selected card on the FE shows "Current estimation cost" sourced from the project task. Today the Project Task Detail response does not include this field.

**Scope of work**
- Add `estimated_cost_idr` (`string`, formatted `0.##`) to the Project Task Detail response DTO.
- Map from `project_tasks.estimated_cost` (nullable `double`).
- Null when source is null (empty string in the DTO).

**Acceptance criteria**
- Given a task with `estimated_cost = 250000`, when the FE calls Task Detail, the response includes `estimated_cost_idr: "250000"`.
- Given a task with `estimated_cost = null`, when the FE calls, the field is `""` or absent per the existing null-omission rule.

**Out of scope**
- Multi-currency — IDR only for v1.

**Test notes**
- Use the existing Task Detail test fixture.

---

## T-06: Extend List SPK BoQ to walk project-task hierarchy to root

- **Epic:** E4 · **Size:** M · **Priority:** Must · **Blocked by:** —
- **Covers:** FR-008

**Context**
The SPK BoQ list response today includes the project-task chain to a fixed depth (currently 2 levels per the Notion page). The FE wants the full ancestry to render `Root / Parent / Leaf`.

**Scope of work**
- Decide between recursive CTE (preferred) or app-level loop based on existing `parent_unique_id` chain.
- Implement the walk to root; stop at `parent_unique_id IS NULL`.
- Include each ancestor's id and description in the response row.
- Guard against cycles (revisit terminates) and orphans (missing parent terminates at the missing link).

**Acceptance criteria**
- Given a 3-level chain A → B → C → (root), when the FE lists SPK BoQs for C, the response includes the ancestry of C up to and including A.
- Given a 1-level task, the response includes just that one row in the ancestry.
- Given a cycle, the walk terminates at the first revisit; no infinite loop.

**Out of scope**
- Backfilling any missing `parent_unique_id` values (PRD A8 assumption; if the chain is dirty, walk falls back).

**Test notes**
- Verify against seeded tasks that have multi-level chains.
- Test cycle case explicitly with a deliberate loop in the seed data.

---

## T-07: Migration — `project_task_boq_drafts` table

- **Epic:** E1 · **Size:** S · **Priority:** Must · **Blocked by:** —
- **Covers:** Data model §5 (drafts)

**Context**
Drafts are stored verbatim as `nvarchar(max)` JSON. Existence IS the draft state. The unique index on `project_task_id` makes upsert trivial.

**Scope of work**
- EF migration adding `project_task_boq_drafts` table per the schema in FSD §5.
- Use the existing `JsonElementConverter` for the `payload` column.
- Unique index `UX_project_task_boq_drafts_project_task_id` on `project_task_id`.
- Apply via DBeaver per `phantomdb-migration-snapshot-drift.md`; do not trust the auto-generated model snapshot.

**Acceptance criteria**
- Given a fresh migration on an empty DB, the new table exists with the documented columns + unique index.
- Given a save + a second save, only one row exists for the `project_task_id`.

**Out of scope**
- The model snapshot file — handled by the next migration that touches anything else.

**Test notes**
- Verify the EF model snapshot in `PhantomDbContextModelSnapshot.cs` matches after a fresh `Add-Migration`.

---

## T-08: Migration — Input Progress tables

- **Epic:** E5 · **Size:** S · **Priority:** Must · **Blocked by:** —
- **Covers:** Data model §5 (Input Progress)

**Context**
Input Progress persists hourly progress rows with weather, issue, remarks, attachments.

**Scope of work**
- EF migration adding `spk_boq_progress_inputs`, `spk_boq_progress_input_hours`, `spk_boq_progress_input_attachments` per FSD §5.
- FKs to `spk_boqs` and to itself; composite PK on the attachments link table.
- Same DBeaver caveat as T-07.

**Acceptance criteria**
- Given a fresh migration on an empty DB, all three tables exist with documented columns + PKs + FKs.

**Out of scope**
- Index tuning beyond PKs / FKs.

**Test notes**
- Migration round-trip test: create, drop, recreate.

---

## T-09: Input Progress POST endpoint

- **Epic:** E5 · **Size:** M · **Priority:** Must · **Blocked by:** T-08
- **Covers:** FR-010

**Context**
Planners need to record hourly progress against an SPK BoQ with weather, hour breakdown, remarks. The body shape is fixed by the FSD.

**Scope of work**
- New endpoint `POST /api/v1/spks/boqs/progress/inputs`.
- Validate `spk_boq_id` is a valid UUID; the SPK BoQ exists and is not soft-deleted.
- Validate `weather_type ∈ {Bright, Drizzly, Rain, Wet}`.
- Cap `hours.Count <= 24`; reject over-cap with 400.
- Validate `start_hour ∈ 0..23`, `end_hour ∈ 1..24`, `start < end`.
- Persist input row + hour rows in one transaction. (Attachments and Issue → Diary in their own tickets T-11 / T-10.)
- Log `progress_input_saved` per NFR-005.

**Acceptance criteria**
- Given a valid payload with 5 hour rows, when the FE submits, the input row + 5 hour rows are persisted in one transaction.
- Given `weather_type = "Storm"`, when the FE submits, 400 with `weather_type must be one of Bright|Drizzly|Rain|Wet`.
- Given 25 hour rows, when the FE submits, 400 with `hours cannot exceed 24 entries`; no rows are written.
- Given `spk_boq_id = 00000000-0000-0000-0000-000000000000`, when the FE submits, 400 with `spk_boq_id is required and must be a valid UUID`.

**Out of scope**
- The issue → Project Diary wiring (T-10).
- The GET endpoint (T-11).
- Attachment linking (T-10).

**Test notes**
- Validation tests for every reject path.

---

## T-10: Issue → Project Diary remark + attachment linking

- **Epic:** E5 · **Size:** S · **Priority:** Must · **Blocked by:** T-09
- **Covers:** FR-010 (issue flow), FR-010 (attachments)

**Context**
When the planner ticks Issue on an Input Progress row, the on-site problem must flow into Project Diary without re-entry. Attachments must be linked from the existing attachment domain.

**Scope of work**
- Inside the Input Progress POST transaction: if `issue = true`, write a Project Diary remark row attributed to the SPK BoQ, body = the input row's `remarks` (or a default if null).
- Attachments: link each `attachment_id` in the input payload to the input row via `spk_boq_progress_input_attachments`. Validate each `attachment_id` exists in the chosen attachment table (TBD per Open Q3).

**Acceptance criteria**
- Given `issue = true` and `remarks = "Generator fuel spill"`, when the FE submits, a Project Diary remark with that body exists, attributed to the SPK BoQ.
- Given `issue = false`, when the FE submits, no Project Diary row is written.
- Given `attachments = [a1, a2]`, when the FE submits, the input row is linked to both attachments.

**Out of scope**
- Standalone Project Diary creation outside the Input Progress flow.

**Test notes**
- Verify the Project Diary row's source / attribution columns match the FSD.

---

## T-11: Input Progress GET endpoint

- **Epic:** E5 · **Size:** S · **Priority:** Must · **Blocked by:** T-09
- **Covers:** FR-011

**Context**
The FE needs to render prior Input Progress rows for the SPK BoQ it is about to capture against. Newest first.

**Scope of work**
- New endpoint `GET /api/v1/spks/boqs/progress/inputs?spk_boq_id=`.
- Validate `spk_boq_id` is a valid UUID.
- Return up to N most-recent input rows (N is a constant; document the choice in the FSD), with hour rows inlined.
- Order by `created_at DESC`.

**Acceptance criteria**
- Given 3 inputs for SPK BoQ X, when the FE lists them, the response returns 3 rows newest first, each with its hour rows.
- Given a missing SPK BoQ, when the FE lists, 404 `Data not found`.
- Given `spk_boq_id` empty / non-UUID, 400.

**Out of scope**
- Pagination beyond the row cap.
- Search / filter beyond `spk_boq_id`.

**Test notes**
- Newest-first ordering test.

---

## T-12: Feature flag + telemetry [infra]

- **Epic:** E1 · **Size:** M · **Priority:** Must · **Blocked by:** T-01, T-02, T-03, T-04
- **Covers:** NFR-005 (and indirectly the G1 / G2 baselines)

**Context**
The wizard ships behind a flag; we need `wizard_open` and `wizard_submit` events before rollout so G2 has a baseline.

**Scope of work**
- Add `feature.spk_boq_wizard` flag. Default OFF in dev, ON in staging.
- Emit `wizard_open` from the FE on Task Detail modal open. (FE ticket; flag here as a backend dependency.)
- Emit `wizard_draft_save`, `wizard_submit`, `wizard_submit_blocked`, `wizard_revise` from the backend (already partially covered by NFR-005 — finish the wire).
- Emit `boq_detail_double_pick` once FR-001 lands + analytics event ships (defer; mark as future in NFR-005).
- Document flag toggle plan in the rollout section of the PRD (already there).

**Acceptance criteria**
- Given a developer sets the flag ON in dev, when they call the wizard endpoints, the responses succeed.
- Given the flag is OFF, the FE wizard stays disabled (FE owns the gate).
- Given the rollout, `wizard_open` and `wizard_submit` counters populate.

**Out of scope**
- Removing the flag after two stable releases.
- A/B experiment harness.

**Test notes**
- Flag toggle test (manual / smoke).

---

## Coverage check

| FR / NFR | Tickets |
|---|---|
| FR-001 | T-01 (parent_id), T-06 (hierarchy feeds tree) |
| FR-002 | T-07 (table) + already-shipped endpoint |
| FR-003 | T-02 (contract fields) + already-shipped endpoint |
| FR-004 | already-shipped |
| FR-005 | T-03 (alias), T-04 (budget gate), already-shipped core |
| FR-007 | T-05 |
| FR-008 | T-06 |
| FR-009 | T-04 |
| FR-010 | T-08 (table), T-09 (POST), T-10 (issue + attachments) |
| FR-011 | T-11 |
| NFR-001 | T-01 (one extra query budget) |
| NFR-002 | T-04 |
| NFR-003 | already-shipped (1 MB cap is the legacy endpoint's cap) |
| NFR-004 | already-shipped (R3ComponentFilter unchanged) |
| NFR-005 | T-12 |
| NFR-006 | T-01 (parent_id always present; the three task-allocation keys stay absent when project_task_id absent — already shipped) |

All 11 FRs and 6 NFRs covered. FR-002 / FR-004 are partially already-shipped and rely on existing tests; T-07 only covers the data model.