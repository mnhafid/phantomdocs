# Review resume — `feat/estimatedCost` (ecff33eb)

## Verdict
**Request changes** (multiple P1 correctness/data-integrity issues).

## Scope
- `POST /projects/tasks/boqs` submit path with optional `spk_id` and multi-SPK/cross-linking.
- SPK line linking + task assignment mirror updates.
- Project task weight recomputation and USD/IDR conversions for task estimated costs.

## P1 defects (must fix)

### 1) Duplicate `spk_boq` rows crash BOQ recalculation when a line is re-linked to another SPK
**What happens**
- Submit links submitted lines to the provided SPK (`LinkSubmittedLinesToSpkAsync`) and then calls `RecalculateTaskBoqWeightsAndPlanAsync`.
- The SPK-BOQ recalculation service builds a map with `ToDictionary(sb => sb.ProjectTaskBoqId)`.

**Failure mode**
- If the same `project_task_boq_id` is present under multiple active `spk_boqs` rows (expected for multi-SPK re-linking/cross-link), `ToDictionary` throws a duplicate-key exception.
- Transaction rolls back → the second-SPK submit cannot succeed.

**Evidence**
- `ProjectTaskBoqsService.cs:560-572` (links + recalculation order)
- `SpkBoqRecalculationService.cs:78-100` (`ToDictionary(sb => sb.ProjectTaskBoqId, ...)`)

**Fix direction**
- Either prevent creation of additional active `spk_boqs` for an already-connected `project_task_boq_id`, or update recalculation logic to support multiple `spk_boq` rows per `project_task_boq_id`.

---

### 2) Project task weights double-count when a task BoQ is linked to multiple SPKs
**What happens**
- Task weight basis is recomputed from connected totals.
- The recomputation sums **one row per live `spk_boq`**.

**Failure mode**
- If a `project_task_boq` is connected to multiple SPKs, its `TotalPrice` contributes multiple times to the same project task’s basis.
- This inflates/warps weight shares and cascades financially wrong downstream values.

**Evidence**
- `SpksService.cs:4297-4327` (`connectedByTask` derived from `SpkBoqs` rows)

**Fix direction**
- Aggregate by distinct `ProjectTaskBoqId` per task before summing (or enforce a single active link per task BoQ where that’s intended).

---

### 3) Re-submit with the same `spk_id` leaves `project_task_spks.spk_cost` stale
**What happens**
- `EnsureTaskAssignedToSpkAsync` checks for an active assignment and skips assignment writes if one already exists.
- On subsequent submits, linked lines can change and SPK value/weights are recomputed, but the assignment cost mirror isn’t updated.

**Impact**
- `Spk.SpkValue` recomputation updates SPK totals.
- However `ProjectTaskSpk.SpkCost` (and the legacy primary mirror) can remain at the previous `taskCost`.

**Evidence**
- `ProjectTaskBoqsService.cs:681-703` (early-return logic when assignment already exists)

**Fix direction**
- Update `project_task_spks.spk_cost` (and `project_tasks.spk_id` / `project_tasks.spk_cost` mirror if applicable) whenever linked lines change, even when the assignment row already exists.

---

### 4) `estimated_cost` units inconsistent between list vs detail endpoints
**What happens**
- List endpoint converts `estimated_cost` using `usd_rate`.
- Detail endpoint does not convert `estimated_cost` via the same USD/IDR rule (while `estimated_cost_idr` remains raw).

**Impact**
- Clients see different meanings/units for the same field depending on endpoint.

**Evidence**
- List: `ProjectTasksService.cs:1178-1265` (`GetUsdRateAsync` + `BuildProjectTaskItdDto(..., usdRateForAll, ...)`)
- Detail mapping: `ProjectTasksService.cs:1267-1373` (`GetProjectTaskByIdAsync` calls `ProjectTasksHelper.MapToDto` + only converts SPK cost)
- Common DTO mapper: `ProjectTasksService.cs:1788-1829` (conversion guarded by `if (usdRate is > 0)`)

**Fix direction**
- Apply the same conversion rule to detail mapping, or explicitly make list/detail semantics different (and document it).

## P2 defects / test gaps

### 5) Submit tests rely on in-memory provider exception walls
**Evidence**
- `ProjectTaskBoqSubmitTests.cs:262-303` (new `Submit_WithSpkId_RecordsTheAssignment_Once` asserts state after expecting an in-memory `ExecuteUpdate` exception)

**Risk**
- In-memory EF behavior doesn’t validate relational uniqueness/transaction/rollback semantics.

**Fix direction**
- Add a relational harness test for: multi-SPK linking, duplicate-key handling, assignment cost refresh on re-submit, and correct weight basis.

## Verification performed
- `dotnet test Tests/Tests.csproj --filter FullyQualifiedName~ProjectTaskBoqSubmitTests --no-build --no-restore`
  - **Passed: 12**, **Skipped: 3**
- `dotnet test Tests/Tests.csproj --filter FullyQualifiedName~ProjectTaskEstimatedCostIdrTests --no-build --no-restore`
  - **Passed: 3**

Notes:
- Skipped submit tests mention relational harness gaps for `ExecuteUpdateAsync` / `ExecuteDeleteAsync`.
