# SPK cancel parity — detach contract + drop task BoQ lines

**Date:** 2026-09-03
**Repo:** `phiDev` (.NET) · **Reference implementation:** `pms-backend` (Go)
**Status:** Findings + work prompt. Not implemented.

---

## 1. Problem

`CancelSpkAsync` (`src-be/Logics/Services/Spks/SpksService.cs:920`) delegates task detachment to `UnassignTasksFromSpkAsync` (`:4061`). That helper closes the `project_task_spks` assignments and clears `project_tasks.spk_id` / `spk_cost`, but it stops there.

The Go path it mirrors — `RemoveProjectTaskFromSPK` (`pms-backend/internal/app/repository/spk.go:82`, called only from `service/spk.go:1232` `CancelSpk`) — does four things in one transaction:

1. Resolve task ids:
   ```sql
   select distinct pt.id
   from spk_boqs sb
   join project_task_boqs ptb on sb.project_task_boq_id = ptb.id
   join project_tasks pt      on ptb.project_task_id = pt.id
   where sb.spk_id = ?
   ```
2. `project_tasks`: `contract_id = NULL`, `spk_id = NULL`, `spk_cost = 0`
3. Soft-delete `project_task_boq_details` (`deleted_at`, `deleted_by`) for every BoQ under those tasks
4. Soft-delete `project_task_boqs` (`deleted_at`, `deleted_by`) for those tasks

Missing on the .NET side: **step 2's `contract_id`**, **step 3**, **step 4**.

**Second defect in the same method:** `CancelSpkAsync:946` assigns `unassignedTaskIds` and never uses it. `RefreshSpkTypeAsync` runs on create (`:487`) and on connect (`:2552`) but not on cancel, so `project_tasks.spk_type` stays `single`/`multi` after the assignments are closed.

---

## 2. Decide before writing code

The Go behaviour cannot be copied literally — ADR 0007 (`.claude/docs/adr/0007-project-task-spk-id-retained-as-primary-assignment-mirror.md`) established that a task may hold several SPK assignments, which Go's data model does not have. Resolve each of these and record the choice.

### D1 — Scope of the BoQ soft-delete

Go deletes *every* `project_task_boqs` row of an affected task. Under multi-SPK that would destroy lines belonging to a different, still-active SPK.

**Recommended:** delete only lines reachable from `spk_boqs.spk_id = @spkId` via `spk_boqs.project_task_boq_id`.

Per ADR 0007, various-WBS `spk_boqs` rows carry a null `project_task_id` (100 of 137 in the audited set) — join through `project_task_boq_id`, **never** `project_task_id`.

### D2 — `contract_id` nulling

Go nulls it unconditionally. A task can legitimately be contract-assigned without an SPK — the codebase queries exactly that state (`pt.contract_id is not null and pt.spk_id is null`, e.g. `project_task.go:509`).

**Recommended:** null it only when no active `project_task_spks` row remains for the task after the unassign.

### D3 — `spk_boqs` and its children

Both entities carry a global `HasQueryFilter(r => r.DeletedAt == null)` (`PhantomDb.ProjectTaskBoq.cs:81,134`). Soft-deleting `project_task_boqs` makes `spkBoq.ProjectTaskBoq` resolve to null, and several call sites dereference it with `!`.

Decide whether the `spk_boqs` rows (and their `SpkBoqSchedule` / `SpkBoqProgress` children) are also closed, or left as SPK history — then make every consumer safe either way.

### D4 — Backfill

SPKs already canceled through the .NET path left their BoQ lines and `contract_id` behind. Decide whether a one-off repair script ships with this change. Pattern to follow: the repair statements in `audit-project-task-spk-drift.sql`.

---

## 3. Implement

- Extend `UnassignTasksFromSpkAsync` (or add a sibling helper it calls) to cover the two missing steps under the decisions above. It already runs inside the caller's transaction and the caller owns `SaveChanges` — **keep that contract.**
- Stamp `deleted_by` with the acting user, `deleted_at` with `timeProvider.GetLocalNow().DateTime`, matching the surrounding code.
- **Do not hard-delete.** Go's `ResetProjectTaskBoQ` (`pms-backend/internal/app/repository/project_task.go:71`) hard-deletes, and the commented-out soft-delete right above it shows that was a deliberate divergence for a different flow. Cancel soft-deletes.
- Call `RefreshSpkTypeAsync(unassignedTaskIds, ct)` after the `SaveChangesAsync` in `CancelSpkAsync`, then save again — same ordering as `:2552`.

---

## 4. Impacted — check each

| Location | Why |
|---|---|
| `SpkModificationsService.cs:423` | `spkBoq.ProjectTaskBoq!` null-forgiving dereference; also `:441-469`, which re-derives `SpkCost` from linked lines |
| `SpksService.cs:2489` | Join |
| `SpksService.cs:2542` | `SpkCost` sum — already filters `DeletedAt == null`, so it silently changes once lines are deleted |
| `SpksService.cs:2673`, `:2901` | Consumers |
| `SpkBoqsService.cs:132` + `spkBoqRecalculation.RecalculateTaskBoqWeightsAndPlanAsync` / `RecalculateApprovedProgressChainAsync` | Weights are a share of the task total, which moves when lines disappear |
| `ProjectTasksService.cs:3317` (`ExecuteUpdate` setting `SpkCost` to 0), `ProjectTasksHelper.cs:149-152` | The other writers/readers of the mirror |
| `ProjectRebaselinesHelper.cs`, `ProjectsService.cs` | `SpkCost` consumers |
| `CancelSpkAsync:985-995` | Already adjusts contract `SpkValue` / `SpkCount` for approved SPKs — confirm nulling `contract_id` does not double-count anywhere |
| `audit-project-task-spk-drift.sql` | Add a line for the new invariant: canceled SPK ⇒ no live `project_task_boqs` linked to it |

---

## 5. Tests

Follow ADR 0003 (gherkin + TDD gate). Extend `src-be/Tests/SpkModifyBoqTests.cs` and `src-be/Tests/ProjectTaskSpkAssignmentTests.cs`.

Minimum cases:

1. **Sole SPK** — cancel an SPK whose task holds only that SPK → `contract_id`, `spk_id`, `spk_cost` cleared; its `project_task_boqs` + `_details` soft-deleted; `spk_type` null.
2. **Shared task** — cancel one SPK of a task holding two → the other SPK's lines survive, `contract_id` retained, `spk_type` drops to `single`.
3. **Various-WBS** — cancel a various-WBS SPK (BoQ rows with null `project_task_id`) → resolved via `project_task_boq_id`, no rows missed.
4. **Idempotence** — already-canceled / no-assignment SPK → no error, no change.
