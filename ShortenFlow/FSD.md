# FSD: SPK BoQ Shorten Flow (as-built)

| | |
|---|---|
| **Type** | Functional specification — reverse-documented from merged code |
| **Status** | As-built on `feat/shortenflow` |
| **Date** | 2026-09-03 |
| **Version** | 1.0 |
| **Branch** | `feat/shortenflow` |
| **Related** | [PRD.md](PRD.md) · [data.sql](data.sql) · [../2026-08-26-spk-boq-improvement-FSD.md](../2026-08-26-spk-boq-improvement-FSD.md) · [README.md](README.md) |

## 1. Scope and method

This document describes the SPK BoQ shorten flow **as it exists in the code**, not as it was originally specced. Every statement below was read out of the source on `feat/shortenflow` and carries a `file:line` citation. Where the shipped behaviour differs from the 2026-08-26 spec, the code wins and the difference is recorded in §7.

**In scope:** the eight endpoints that make up the wizard, the five tables behind them, the validation rules, the v1/v2 split, and the four gaps.

**Out of scope:** the Input Progress screen (specced in the 2026-08-26 PRD §7.8, not built), BOQ export v2 (separate FSD, `../2026-09-02-boq-export-v2-by-contract-FSD.md`), and SPK approval/e-sign.

## 2. Domain model

Five tables carry the flow. Their grains and the invariant each one holds:

| Table | Grain | Invariant |
|---|---|---|
| `project_task_boqs` | one submitted BoQ line per task | soft-deleted, never hard-deleted. `type` ∈ {`inline`, `custom`} |
| `project_task_boq_details` | one **draw** per line, against one `boq_details` row | exactly one live detail per line — submit soft-deletes every other as an orphan |
| `project_task_boq_drafts` | one draft per task | `UX_project_task_boq_drafts_project_task_id` enforces one row. The row's **existence** is the draft state; there is no status column |
| `project_task_spks` | one SPK assignment per (task, SPK) | `UX_project_task_spks_active` (task, spk) blocks duplicates; `UX_project_task_spks_primary` (task) allows at most one primary. Rows are never deleted — `unassigned_at` closes them |
| `spk_boqs` | one link per (SPK, submitted line) | a line may be linked to **more than one** SPK. Audit columns here are PascalCase (`CreatedAt`/`CreatedBy`), unlike every neighbouring table |

Two denormalized mirrors ride alongside, and both can drift:

- `project_tasks.spk_id` / `.spk_cost` mirror the **primary** assignment only (`ProjectTaskSpk.cs:22`).
- `project_tasks.spk_type` is `"single"`, `"multi"`, or NULL, recomputed by `SpksService` on every assign/unassign from the live count of `project_task_spks` (`ProjectTask.cs:52-60`). It is the **only** field that reports a second assignment exists. `audit-project-task-spk-drift.sql` at the repo root is the repair script.

### 2.1 Why the draft payload is unnormalized JSON

`project_task_boq_drafts.payload` is `nvarchar(max)` holding the `SetProjectTaskBoqRequest` JSON verbatim (`ProjectTaskBoqDraft.cs:9-19`). A draft is *allowed to be incomplete* — half-filled dates, a missing `unit_id` — so columns with NOT NULL and FK constraints would reject data a draft must be able to hold. **Submit stays the only validation gate.**

## 3. The flow

```
  open task
      │
      ▼
  GET  /projects/tasks/boqs/draft?project_task_id=      ── resume, or data:null on a fresh task
      │
      ▼
  GET  /contracts/boqs/details?contract_id=&project_task_id=   ── the picker; parent_id + is_selected
      │
      ▼  (autosave, repeatedly)
  POST /projects/tasks/boqs/draft                        ── stored verbatim, never validated
      │
      ├──▶ POST /projects/tasks/boqs/draft/delete        ── "Revise": discard and start over
      │
      ▼
  POST /projects/tasks/boqs/submit                       ── the ONLY validation gate;
      │                                                     deletes the draft in the same transaction
      ▼
  GET  /projects/tasks/boqs?project_task_id=             ── read back the submitted set
```

## 4. Endpoint contracts

All routes sit inside `MapProjectTaskBoqs` (`ProjectTaskBoqsEndpoint.cs:56`): the v1 group at `:58`, the v2 group at `:73`. Both carry `.WithTags(...)` and `.AddEndpointFilter<R3ComponentFilter>()`, so authorization is inherited and no route declares its own.

| # | Route | Method | Handler | Registered |
|---|---|---|---|---|
| FR-001 | `/api/v1/projects/tasks/boqs` | GET | `GetProjectTaskBoqAsync` | `:83` |
| FR-002 | `/api/v2/projects/tasks/boqs` | GET | `GetProjectTaskBoqV2Async` | `:105` |
| FR-003 | `/api/v1/projects/tasks/boqs/list` | POST | same as FR-001, filter in body | `:127` |
| FR-004 | `/api/v1/projects/tasks/boqs` | POST | `SetProjectTaskBoqAsync` | `:152` |
| FR-005 | `/api/v1/projects/tasks/boqs/submit` | POST | **alias** of FR-004, same handler | `:160` |
| FR-006 | `/api/v1/projects/tasks/boqs/{id:guid}` | POST | `UpdateProjectTaskBoqAsync` | `:210` |
| FR-007 | `/api/v1/projects/tasks/boqs/draft` | POST | `SaveProjectTaskBoqDraftAsync` | `:241` |
| FR-008 | `/api/v1/projects/tasks/boqs/draft` | GET | `GetProjectTaskBoqDraftAsync` | `:281` |
| FR-009 | `/api/v2/projects/tasks/boqs/draft` | GET | `GetProjectTaskBoqDraftV2Async` | `:311` |
| FR-010 | `/api/v1/projects/tasks/boqs/draft/delete` | POST | `DeleteProjectTaskBoqDraftAsync` | `:338` |

Note FR-006 and FR-010 are `POST` despite being semantically PUT and DELETE. That is the existing house convention, not an oversight.

### FR-001 / FR-002 — read the submitted set

Both versions run one shared implementation, `GetProjectTaskBoqCoreAsync` (`ProjectTaskBoqsService.cs:125`), with an `isV2` flag. The flag adds fields; it never changes an existing one, which is what keeps the v1 body byte-identical.

Filters (`GetProjectTaskFilter`, `ProjectTaskBoqsDto.cs`): `project_task_id` (Guid?), `project_task_ids` (a `|`-separated list), `spk_id`, `search`. Rows are filtered on `deleted_at IS NULL` and ordered by `start_date`.

**The scalar-vs-list difference.** `spk_boqs` rows are grouped per `project_task_boq_id` and sorted `CreatedAt` descending. v1 reports only `[0]` — the newest link — in the scalar `spk_id`, `spk_boq_id`, `actual_volume`, `physical_progress`, `progress_cost` fields. When a line is linked to two SPKs, **v1 silently reports one and omits the other.** v2 adds `spks[]`, listing every link newest-first, and drops `contract_id` in favour of a full `contract` object plus `spk` and `spk_type`.

> Fixture: scenario S-B, line `SF.1.1.`, is deliberately linked to two SPKs so this divergence is observable. See `data.sql` §8.5.

`unit_price` on a nested `boq` object is **computed**, not stored: `total / quantity`, and only when `data_type = 'item'` AND `quantity > 0` AND `total > 0`; otherwise the empty string (`ProjectTaskBoqsService.cs:246-249`).

### FR-004 / FR-005 — submit

One handler, `SubmitProjectTaskBoqHandler` (`ProjectTaskBoqsEndpoint.cs:168`), behind two routes. `/submit` is the semantic alias the wizard calls; the bare POST is the legacy path and stays open.

`SetProjectTaskBoqAsync` (`ProjectTaskBoqsService.cs:424`) runs four steps:

**Step 0 — normalize, then validate, per row.**

`NormalizeLegacyRow` (`:324`) folds two pre-flattening client shapes onto the canonical row:
- `type: "item"` → `"inline"`. This is contract-BOQ vocabulary leaking into the task-BOQ field. No `item` row has ever persisted.
- A single nested `boq_details[]` entry is lifted onto the row (`boq_detail_id`, `unit_id`, `unit_price`). **More than one entry is rejected** — persistence upserts the row's single detail and soft-deletes every other as an orphan, so truncating to the first would *delete* the rest, not ignore them.
- A nested draw whose `total_price` disagrees with the row's by more than 0.01 is rejected: the row and its single draw describe the same money.

`ValidateRow` (`:291`) then requires `description`, a non-empty `unit_id`, `start_date`, `end_date`, a `boq_detail_id`, and `type` ∈ {`inline`, `custom`}.

**Step 1 — preconditions.** The task must exist and not be soft-deleted (404 `Data not found`). Its **project status must be `in progress`** or the submit is refused with *"You cannot set the SPK BoQ because the Project Details' status is not yet In Progress"* (`ProjectConstant.StatusInProgress`).

**Step 2 — every `boq_detail_id` must belong to `request.contract_id`.** `boq_details` is joined to `boqs` to read `contract_id`. A missing id → `BoQ Detail ID Not Found`; an id on another contract → `BoQ Detail ID Invalid : {id}`.

**Step 3 — persist, full-replace, one transaction.**
- Upsert key for a line: `(project_task_id, code, description, kind)`. Not `(project_task_id, code)` — a breakdown code is **not** unique, since one source row fans out into one item per `kind`.
- Upsert key for a detail: `(project_task_boq_id, boq_detail_id)`.
- Lines and details absent from the new set are **soft-deleted**, not removed.
- `project_tasks.contract_id` is written via `ExecuteUpdateAsync` so the UPDATE always emits, regardless of EF change tracking.
- The task's draft is deleted **inside the transaction**, so a failed write leaves the planner's in-progress selection intact.

**Errors:** 400 on any `InvalidOperationException` (message passed through verbatim) or malformed JSON, mapped to a readable message by `ProjectTaskBoqsJsonErrorMapper`; 404 on `KeyNotFoundException`; 500 otherwise.

### FR-007 — save draft

Body is read as a raw `JsonElement`. Only two fields are read and validated (`ReadDraftKeys`, `:859`): `project_task_id` and `contract_id`, each required and a parseable non-empty GUID. Everything else is stored as-is.

Before storing, `NormalizeDraftPayload` (`:363`) applies the same two reshapes as submit — but **on the raw JSON**, not through the typed DTO. Round-tripping a half-filled form through `SetSpkBoqRequest` would coerce every absent field to its default (empty GUIDs, zero money the user never typed) and drop anything the DTO does not model. An already-canonical payload is stored byte-for-byte.

Upsert is keyed on `project_task_id` and is **last-write-wins**: no row lock, no concurrency token. Two planners on one task overwrite each other silently (PRD §4, accepted).

### FR-008 / FR-009 — read draft

`project_task_id` is bound as `string?` and parsed by hand. Missing/unparseable → 400 `Project Task is Required`. Binding it as `Guid?` would turn an empty `project_task_id=` into a 500, and the FE sends it empty when no task is in context.

**No draft is not an error.** The handler answers `200` with `data: null` — opening a modal on a fresh task is a normal state, and the FE should not have to special-case a status code. (`ApiResponse<T>.Data` carries no `JsonIgnore`, so the `data` key is present and null, not omitted.)

When a draft exists, `LoadDraftContextAsync` (`:715`) assembles the response:

| Field | Source | Empty/null when |
|---|---|---|
| `payload` | the stored JSON, verbatim | — |
| `contract_name` | `contracts.contract_title` | contract soft-deleted |
| `contract_value` | `contracts.contract_value`, `"0.##"` | contract soft-deleted |
| `spk_remaining` | `contract_value - spk_value`, `"0.##"` | contract soft-deleted |
| `contract` | full `ContractSimpleResponseDto` | contract soft-deleted → null |
| `spk` / `spk_type` | read from the **project task**, not the draft | task has no SPK → null |

Three implementation constraints are load-bearing here:

1. The contractor name is fetched in a **separate query**, not through `Contract.Contractor`. `contracts.contractor_id` is non-nullable, so EF treats that navigation as REQUIRED and inner-joins — which would drop the whole contract row whenever no contractor row matches. The column carries no FK guarantee, so that case is real.
2. The SPK row is materialised **before** `.ToString()`. Calling `Id.ToString()` inside an EF projection translates to SQL `CONVERT` and returns an UPPERCASE GUID, while the task list returns lowercase — and the FE compares these as strings.
3. `spk_remaining` is read from the stored `contracts.spk_value` column. Nothing in this path recomputes it.

v2 (`:691`) currently returns the identical body; the split exists so the two can diverge without one breaking the other.

### FR-010 — delete draft

The "Revise" path. Hard `ExecuteDeleteAsync` on `project_task_id`. Returns 404 `Data not found` when no row was deleted, so the FE can tell "discarded" from "there was nothing to discard".

## 5. The picker: `GET /contracts/boqs/details`

Not owned by this service, but the wizard cannot work without two fields it stamps (`BoqsService.cs`).

**`parent_id`** (`ApplyParentIdsAsync`, `:1106`) — the id of the row whose `breakdown` is this row's breakdown with the last `.` segment stripped (`StripLastSegment`, `:1140`); the **empty string** when there is no such row. `SF.1.1.` → parent `SF.1.`; `SF.1.` → `SF.` → no match → `""`. Headers are returned alongside items specifically so `parent_id` always names a row present in the same response.

**`is_selected`** (`ApplyTaskSelectionAsync`, `:1161`) — stamped only when `project_task_id` is supplied. Absent param → the three task fields (`is_selected`, `start_date`, `end_date`) stay null and are omitted, keeping the response byte-identical for callers that predate them.

"Selected" spans **both** sources (`BuildTaskSelectionAsync`, `:1184`): the submitted set (`project_task_boqs` ⋈ `project_task_boq_details`) **and** the task's unsubmitted draft. A line the planner picked but has not submitted must still read as taken, or they can pick it twice. **Draft wins on conflict** — it is the more recent statement of intent.

`project_task_id` is bound as `string?` here too, for the same 500-on-empty reason.

## 6. v1 / v2

| | v1 | v2 |
|---|---|---|
| List route | `/api/v1/projects/tasks/boqs` | `/api/v2/projects/tasks/boqs` |
| `contract_id` on the group | present | **dropped** — the id is on `contract` |
| `contract` object | — | full `ContractSimpleResponseDto` |
| `spk` + `spk_type` | — | present |
| per-line `spks[]` | — | every link, newest first |
| Draft route | `/api/v1/…/draft` | `/api/v2/…/draft` |
| Draft body | — | identical today |
| Save / delete draft | v1 only | not registered on v2 |

The v2 extras live on a **subclass**, `GetProjectTaskV2Response` (`ProjectTaskBoqsDto.cs`), not on the shared base — so v1 returns base instances and cannot emit them under any serializer setting.

Route names must be globally unique; `WithName("GetProjectTaskBoqDraft")` and `…DraftV2` are distinct or the app throws at startup.

## 7. Known gaps

### GAP-1 — the contract budget gate was never built

PRD §7 item 5 required: *"when `contract.ContractValue - contract.SpkValue < 0` after applying the submitted set, return 400 with the computed balance and refuse to write."*

**It does not exist.** `SetProjectTaskBoqAsync` (`:424`) contains no reference to `ContractValue`, `SpkValue`, or any balance check — the only place either column is read in this service is `FillCommonDraftFields` (`:829`), which *reports* `spk_remaining` on the draft response. A submit that drives the contract negative commits normally. G4 in the PRD ("negative-remaining-balance submits stop") is therefore unmet.

> Fixture: scenario S-C exists to make this visible. Contract B reports `spk_remaining: "-30000000"` and its two lines committed anyway.

### GAP-2 — header rows cannot be submitted

`ValidateRow` rejects any row whose `type` is not `inline`/`custom`, which excludes headers. This is deliberate and currently correct: `project_task_boqs` requires a `unit_id` and both dates, which a header does not have, so an accepted header would pass validation and then fail at persistence. Relaxing the type guard alone would move a 400 to a 500. See `task-boq-submit-400-FINDINGS.md`.

### GAP-3 — draft concurrency is last-write-wins

Accepted in the PRD (§8). Two planners on one task silently overwrite each other. Revisit only if the workflow needs it.

### GAP-4 — `spk_type` is maintained, not derived

It is written by `SpksService` on assign/unassign rather than computed from `project_task_spks` at read time, so a path that writes assignments without going through those helpers leaves it stale. `audit-project-task-spk-drift.sql` detects and repairs the drift. A task showing `"single"` while holding two live assignments is a real, observed state — not a fixture artifact.

### GAP-5 — no draw is scoped to its SPK

When a task is already linked to an SPK, submit checks only that each `boq_detail_id` belongs to the request's contract — not that it belongs to *that SPK*. Raised, not implemented; see `draft-spk-scope-and-search-FINDINGS.md` F1.

## 8. Fixture coverage

`data.sql` builds four scenarios on its own contractor, two contracts, two BOQs, one project and five tasks. Every row it owns has a literal GUID in the reserved `5F000000-0000-4000-8000-0000000000XX` range; §1 of the script deletes exactly those in FK order, so a re-run is idempotent and that block alone is the teardown.

| Scenario | Task id (`5F000000-0000-4000-8000-…`) | Exercises |
|---|---|---|
| **S-A** happy path | `…000000000210` | FR-001, FR-002 scalar fields, `spk_type: "single"`, recorded progress |
| **S-B** multi-SPK | `…000000000211` | FR-002 `spks[]`, `spk_type: "multi"`, GAP-4. Line `SF.1.1.` is on **two** SPKs |
| **S-C** over-budget | `…000000000212` | FR-008 negative `spk_remaining`, **GAP-1** |
| **S-D** saved draft | `…000000000213` | FR-008 resume, §5 `is_selected` sourced from a draft with no submitted rows |

The BOQ is hierarchical on purpose (`SF.1.` → `SF.1.1.`/`SF.1.2.`, `SF.2.` → `SF.2.1.`/`SF.2.2.`, plus a parentless `SF.3.`) so §5's `parent_id` climb has something to resolve, including the empty-string case at both the top of a branch and a flat top-level item.

Section 10 of the script is eight read-only `PASS`/`FAIL` assertions covering the row counts, the two live assignments on S-B, the `spk_type` values, the cross-link, the negative balance, S-D having a draft and no submitted lines, the unit-id placeholder substitution, and the `in progress` project status.

**Validation performed:** compiled clean under `SET NOEXEC ON` (object and column names all resolve) against the dev schema. Not loaded into any shared database.

### 8.1 Loading it

```bash
sqlcmd -S <server> -d phantomdb -U <user> -P '<pass>' -C \
  -i docs/ShortenFlow/data.sql
```

`FIXTURE_USER` (`314ee091-4525-4098-9c45-0b39edf8fad0`, R3TEST.tiar on dev) is the only environment-specific literal; the header block says how to re-derive it. Unit references are inline subqueries by name, so they resolve per environment on their own.

### 8.2 Smoke curls

Every endpoint 401s without a bearer token.

```bash
BASE=http://localhost:5000
TOK=<bearer>
TASK_A=5f000000-0000-4000-8000-000000000210
TASK_B=5f000000-0000-4000-8000-000000000211
TASK_C=5f000000-0000-4000-8000-000000000212
TASK_D=5f000000-0000-4000-8000-000000000213
CONTRACT_A=5f000000-0000-4000-8000-000000000002

# S-A — one SPK, two lines, progress on the first
curl -s -H "Authorization: Bearer $TOK" \
  "$BASE/api/v2/projects/tasks/boqs?project_task_id=$TASK_A" | jq '.data[0] | {spk_type, spk: .spk.spk_no, lines: [.spk_boqs[] | {description, total_price, physical_progress}]}'

# S-B — spk_type "multi", and SF.1.1. carrying TWO entries in spks[]
curl -s -H "Authorization: Bearer $TOK" \
  "$BASE/api/v2/projects/tasks/boqs?project_task_id=$TASK_B" | jq '.data[0] | {spk_type, spk: .spk.spk_no, lines: [.spk_boqs[] | {description, spk_id, spks: [.spks[].spk_no]}]}'

# S-C — negative spk_remaining, and nothing stopping a submit (GAP-1)
curl -s -H "Authorization: Bearer $TOK" \
  "$BASE/api/v1/projects/tasks/boqs/draft?project_task_id=$TASK_C" | jq '.data | {contract_name, contract_value, spk_remaining}'

# S-D — resume a draft
curl -s -H "Authorization: Bearer $TOK" \
  "$BASE/api/v2/projects/tasks/boqs/draft?project_task_id=$TASK_D" | jq '.data | {contract_name, spk_remaining, spk_type, payload}'

# no draft -> 200 with data: null, not an error
curl -s -H "Authorization: Bearer $TOK" \
  "$BASE/api/v1/projects/tasks/boqs/draft?project_task_id=$TASK_A" | jq '{status, data}'

# picker — parent_id tree, and is_selected from S-D's draft alone
curl -s -H "Authorization: Bearer $TOK" \
  "$BASE/api/v1/contracts/boqs/details?contract_id=$CONTRACT_A&project_task_id=$TASK_D" | jq '[.data[] | {breakdown, data_type, parent_id, is_selected}]'
```

## 9. References

| What | Where |
|---|---|
| Routes | `src-be/WebApi/Services/ProjectTaskBoqs/ProjectTaskBoqsEndpoint.cs` |
| Service | `src-be/Logics/Services/ProjectTaskBoqs/ProjectTaskBoqsService.cs` |
| DTOs | `src-be/Logics/Services/ProjectTaskBoqs/ProjectTaskBoqsDto.cs` |
| Picker (`parent_id`, `is_selected`) | `src-be/Logics/Services/Boqs/BoqsService.cs:1106-1240` |
| `estimated_cost_idr` | `src-be/Logics/Services/ProjectTasks/ProjectTasksHelper.cs:150` |
| Entities | `src-be/DataAccess/Entities/{ProjectTaskBoq,ProjectTaskBoqDetail,ProjectTaskBoqDraft,ProjectTaskSpk,SpkBoq}.cs` |
| Drift repair | `audit-project-task-spk-drift.sql` (repo root) |
| Tests | `src-be/Tests/BoqParentAndDraftContractTests.cs`, `src-be/Tests/ProjectTaskEstimatedCostIdrTests.cs` |
| Original spec | `docs/2026-08-26-spk-boq-improvement-{PRD,FSD,TICKETS}.md` |
| Open findings | `docs/ShortenFlow/*-FINDINGS.md` |
