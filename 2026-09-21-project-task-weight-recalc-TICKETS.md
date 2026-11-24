# Tickets: Project task weights break after SPK-mirror recalculation

Source: bug found while fixing `GET /projects/{id}/s-curve` vs `GET /projects/{id}/on-stream` disagreement (2026-09-21). No PRD/FSD — defect ticket.
Branch: `phi-dev`

| ID | Title | Size | Blocked by | Status |
|---|---|---|---|---|
| T-01 | Exclude headers from the weight denominator in `RecalculateProjectTaskWeightsAsync` | XS | — | applied (Luvus t55) |
| F-02 | Refresh stored schedule weights after recalculation | S | T-01 | applied (Luvus t56) |
| F-01 | Mixed basis: connected BoQ total vs estimated cost | XS | — | decided + applied 2026-09-22 (Luvus t57): estimated cost only |
| F-03 | Task > 100 % with multiple SPKs: replay approved chains after the task-wide pass | S | — | applied 2026-09-22 (Luvus t58) |

---

## T-01 — Exclude headers from the weight denominator

**Size:** XS · **Blocked by:** — · **Status:** applied

### Context

`ProjectTaskSpkMirror.RecalculateProjectTaskWeightsAsync` re-derives every task weight after a task's connected BoQ changes (SPK submit, task BoQ reset, task BoQ edit). Its denominator was `tasks.Sum(BasisOf)` over **all** non-deleted tasks, headers included. A header's `estimated_cost` is already the sum of its items, so each level of headers counts the same cost again: on a 3-level WBS the item weights sum to roughly 1/3 instead of 1.

Upload-time weighting (`ProjectTasksService.MapUploadTasks` → `ApplyTaskWeights`) skips headers when building `TotalEstimatedCost`. The mirror did not.

Evidence on dev, project `0d4c9624-7a22-4362-8bf5-59af97d762b1`: Σ item weight = 0.9998, with the 0.0002 gap being the five headers' 106,000 cost against the denominator.

Consumers that divide by, or assume, Σ item weight = 1: `vwProjectTaskSummary` header rollup (task-summary, on-stream card), the s-curve (as of today's fix), rebaseline snapshots.

### Work

`src-be/Logics/Services/Spks/ProjectTaskSpkMirror.cs`, `RecalculateProjectTaskWeightsAsync`:

- Build `total` from tasks whose `DataType` is not `header` (case-insensitive, same test as upload).
- Headers keep `BasisOf(header) / total` — their own estimated cost over the item total, identical to upload's cost branch.

### Acceptance criteria

```gherkin
Given a project with items A (cost 4000, one connected BoQ line 4000) and B (cost 4000)
  And a header H (cost 8000)
When project task weights are recalculated
Then A.weight = 0.5 and B.weight = 0.5
  And H.weight = 1.0
```

Test: `Tests/MultiSourceSpkTests.cs` → `ProjectTaskWeights_IgnoreHeaderCostInTheDenominator`. Existing `T01_ProjectTaskWeights_CountARowOnce_HoweverManySpksLinkIt` must still pass.

### Out of scope for T-01

- Existing projects whose weights were already recomputed with the old denominator stay wrong until the next recalculation trigger (any SPK submit / task BoQ change on that project). No backfill written; run `RecalculateProjectTaskWeightsAsync` per affected project if needed.

---

## Follow-ups

### F-01 — Mixed basis: connected BoQ total vs `.mpp` estimated cost

`BasisOf(task)` = Σ `project_task_boqs.total_price` of **SPK-connected** lines when there are any, else `estimated_cost`. This was a deliberate multi-source-SPK decision (see `docs/ShortenFlow/2026-09-07-multi-source-spk-TICKETS.md`, T-01) and is left as is. Two consequences worth a product decision:

- The two bases must be on the same scale. On dev project `0d4c9624-…` task 1.1.1 has `estimated_cost` 15,000 but connected lines totalling 525,000,000 IDR, so it carries 99.97 % of the project weight and every other task is ≈0. If `.mpp` estimated costs are entered in thousands (or another currency) this will happen in production too.
- Only the *connected* subset counts, so linking a line to an SPK changes the task's size, and the task's unconnected BoQ lines (here 683,333,333 of 1,208,333,333) do not count at all.

**Decided 2026-09-22:** estimated cost only. The user expects a finished 15,000-cost task to read as its cost share of the project (≈28 %), not 98 %. `RecalculateProjectTaskWeightsAsync` now weighs every task by `estimated_cost` over the item total; SPK links no longer change task size. Applied on `phi-dev`; the older mirror on `feat/fix-actual-progress` will conflict on merge — keep the estimated-cost basis and that branch's schedule refresh.

### F-02 — Stored schedule weights are not refreshed after a recalculation — **applied**

`project_task_schedules.plan_weight` / `actual_weight` (and their `_accumulation` columns) are written once at upload / progress input as `weight × progress / 100`. `RecalculateProjectTaskWeightsAsync` changes `weight` but never rewrites them, so they go stale. The s-curve no longer reads them (2026-09-21 fix derives live from `weight × progress`), but `ProjectsService` highlight (`Σ actual_weight` for today's progress), `ProjectTasksService` remaining-weight calc, and `SpkBoqsService` display still do.

Applied: `ProjectTaskSpkMirror.RefreshScheduleWeightsAsync` runs at the end of `RecalculateProjectTaskWeightsAsync` and rewrites `plan_weight = weight × plan_progress / 100`, `plan_weight_accumulation` (running sum per task in date order) and `actual_weight = weight × actual_progress / 100`. The caller's existing `SaveChanges` persists it. Test: `Tests/MultiSourceSpkTests.cs` → `ProjectTaskWeights_RefreshStoredScheduleWeights`.

### F-03 — Task progress > 100 % with multiple SPKs — **applied** (Luvus t58)

Actual rows stored the link's task share at approval time; a later line/SPK on the task shrank the share but left the rows, and later approvals replayed from their own date on top of the stale accumulation (dev task f3d232f2: 133 %). `RecalculateTaskBoqWeightsAndPlanAsync` now ends with `ReplayTaskActualsAsync`: every link's approved chain is replayed from its first approved progress, then the task schedule row is re-summed per approved date (soft-deleted links excluded). `POST /api/v1/spks/boqs/recalculate-weights` (empty body = all linked tasks) runs this and, since F-01, the project task weights too, so it is the single backfill call after deploy.
