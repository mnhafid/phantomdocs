# Test Scenarios: Multi-SPK weight recalculation on one project task

Covers Luvus t57 (task weight = estimated cost), t58 (replay approved chains after a weight change), the s-curve / on-stream / task-summary equality, and the `POST /spks/boqs/recalculate-weights` backfill.
Environment: dev. Every scenario ends with the same three checks (§ Verification), so a failure is attributable to one step.

## Invariants under test

- Per link: `weighted_spk = line price ÷ SPK value × 100`, `weighted_project_task = line price ÷ Σ task lines × 100`. Each sums to 100 per SPK and per task.
- Per schedule row: `actual_weight_project_task = actual_progress ÷ 100 × weighted_project_task` **with the link's CURRENT share**, never the share at approval time.
- Per task: `project_task_schedules.actual_progress` on a date = Σ over live links of `actual_progress ÷ 100 × weighted_project_task`. Σ over dates ≤ 100.
- Task weight: `estimated_cost ÷ Σ item estimated_cost`. Never moved by SPK or BoQ changes.
- Per project: overall % = Σ(weight × progress) ÷ Σ weight. Task-summary first level-1 row, on-stream `overall_progress_percentage`, and the last `actual_weight` point of the s-curve are the same number.

## Seed (one project, fresh)

Upload a schedule with these tasks (cost from the .mpp, item total 50,000):

| WBS | type | estimated_cost | weight |
|---|---|---|---|
| 1 | header | 50,000 | (ignored) |
| 1.1 | item T1 "Analisa" | 15,000 | 0.30 |
| 1.2 | item T2 | 20,000 | 0.40 |
| 1.3 | item T3 | 10,000 | 0.20 |
| 1.4 | item T4 | 5,000 | 0.10 |

One approved IDR contract **C** with a BoQ that has at least three lines. All SPKs below are on C (same contract, as in the bug report).

Lines that will be attached to T1:

| line | price | volume | dates |
|---|---|---|---|
| L1 | 1,000,000 | 2 | today … today+8 |
| L2 | 900,000 | 3 | today … today+8 |
| L3 | 10,000,000 | 2 | today … today+8 |

---

## S1 — Single SPK, task fully delivered (baseline)

Steps
1. Submit L1 and L2 to T1: `POST /projects/tasks/boqs` (contract C, no spk_id).
2. Create SPK **A** on T1: `POST /spks` → released.
3. Input progress and approve to 100 %: L1 volume 2, L2 volume 3 (`POST /spks/boqs/progress`, then `/approval`).

Expected

| where | value |
|---|---|
| spk_boqs A.L1 / A.L2 weighted_spk | 52.63 / 47.37 |
| spk_boqs A.L1 / A.L2 weighted_project_task | 52.63 / 47.37 (task total 1,900,000) |
| task schedule Σ actual_progress (T1) | 100.00 |
| task list / task detail T1 actual | 100 % |
| task-summary row "1" actual_progress_itd | 30.00 |
| on-stream overall_progress_percentage | 30.00 |
| s-curve last actual_weight point | "30.00" |
| project_tasks.weight T1 | 0.30 (unchanged by any of the above) |

---

## S2 — Second SPK joins the task after progress exists (the bug)

Steps
4. Submit L3 to T1 (`POST /projects/tasks/boqs`, contract C).
5. Create SPK **B** on T1 with L3 → released. **No progress input yet.**

Expected — weights moved, actuals replayed, nothing exceeds 100

| where | value |
|---|---|
| weighted_project_task A.L1 / A.L2 / B.L3 | 8.40 / 7.56 / 84.03 (task total 11,900,000) |
| weighted_spk A.L1 / A.L2 / B.L3 | 52.63 / 47.37 / 100 (unchanged for A) |
| spk_boq_schedules A.L1 actual_weight_project_task (the 100 % day) | 8.40 (was 52.63 before step 4) |
| spk_boq_schedules A.L2 same | 7.56 |
| task schedule Σ actual_progress (T1) | **15.97**, not 100 and not 133 |
| task-summary "1" / on-stream / s-curve last actual | **4.79** (0.30 × 15.97) |
| project_tasks.weight T1 | 0.30 |
| SPK A physical_progress_value | 100 (SPK axis untouched) |

Before the fix step 5 left T1 at 100 % and the next step pushed it to 184 %.

---

## S3 — Second SPK delivered

Steps
6. Progress L3 volume 2 → approve.

Expected

| where | value |
|---|---|
| task schedule Σ actual_progress (T1) | 100.00 |
| project rollups (summary "1", on-stream, s-curve) | 30.00 |
| bug-report endpoints task detail, task list headers 1 and 1.1 | ≤ 100 |

---

## S4 — Partial progress on both SPKs

Reset with a fresh project (or new task) and run S1 steps 1–2, S2 steps 4–5 with **no** progress, then:
7. Approve A.L1 volume 1 (50 %), A.L2 volume 1.5 (50 %), B.L3 volume 0.5 (25 %).

Expected: T1 = 0.5×8.40 + 0.5×7.56 + 0.25×84.03 = **28.99**; project = **8.70**.

---

## S5 — Backdated approval replays the chain

From S3 state:
8. Input A.L2 progress dated **before** the 100 % day with volume −1 → approve (a correction).

Expected: rows after that date are recomputed from the corrected accumulation; Σ actual on A.L2 = 66.67 %; T1 = 100 − 7.56×(1/3) = **97.48**; project 29.24. No row keeps a pre-correction accumulation.

---

## S6 — BoQ resubmitted with a new price (weights re-derived)

From S3 state:
9. Resubmit L1 with price 2,000,000 (`POST /projects/tasks/boqs`, same code/description so it upserts).

Expected: task total 12,900,000; weighted_project_task 15.50 / 6.98 / 77.52; SPK A value 2,900,000, weighted_spk 68.97 / 31.03; A's plan rows rebased; actual rows replayed; T1 still 100.00; project 30.00.

---

## S7 — Cancel SPK B (known gap, expected to FAIL until fixed)

From S3 state:
10. Cancel SPK B.

Expected: B's line L3 is soft-deleted; T1 drops to A's share only, **15.97**. Currently the task-schedule re-sum filters deleted links but not deleted lines, so T1 stays at 100. Tracked as the open item from the Go comparison.

---

## S8 — Backfill on a drifted project

Take any project on dev that shows > 100 (task f3d232f2 on project 51d64b19 before deploy is the reference).
11. `POST /spks/boqs/recalculate-weights` with body `{}` (or `{"project_task_ids":["<id>"]}`).

Expected: response `project_tasks_processed` > 0; every check in § Verification passes for the project; task weights equal estimated-cost shares; the 98.92 on project 51d64b19 becomes ≈ 31.

---

## Verification (run after every scenario)

Replace `@t` with the task id and `@p` with the project id.

```sql
-- V1: link shares sum to 100 per SPK and per task (expect 0 rows)
SELECT 'spk' k, sb.spk_id id, SUM(sb.weighted_spk) s FROM spk_boqs sb WHERE sb.DeletedAt IS NULL GROUP BY sb.spk_id HAVING ABS(SUM(sb.weighted_spk)-100)>0.01
UNION ALL
SELECT 'task', ptb.project_task_id, SUM(sb.weighted_project_task) FROM spk_boqs sb JOIN project_task_boqs ptb ON ptb.id=sb.project_task_boq_id
WHERE sb.DeletedAt IS NULL AND ptb.deleted_at IS NULL AND ptb.project_task_id=@t GROUP BY ptb.project_task_id HAVING ABS(SUM(sb.weighted_project_task)-100)>0.01;

-- V2: actual rows carry the CURRENT share (expect 0 rows)
SELECT sbs.id, sbs.[date], sbs.actual_weight_project_task, sbs.actual_progress/100*sb.weighted_project_task expected
FROM spk_boq_schedules sbs JOIN spk_boqs sb ON sb.id=sbs.spk_boq_id JOIN project_task_boqs ptb ON ptb.id=sb.project_task_boq_id
WHERE ptb.project_task_id=@t AND sb.DeletedAt IS NULL AND ABS(sbs.actual_weight_project_task - sbs.actual_progress/100*sb.weighted_project_task)>0.01;

-- V3: task ≤ 100 and equals the live re-sum; project rollups agree
SELECT SUM(actual_progress) task_total FROM project_task_schedules WHERE project_task_id=@t;           -- ≤ 100
SELECT actual_progress_itd FROM vwProjectTaskSummary WHERE project_id=@p AND wbs_level=1;             -- = on-stream = s-curve last point
SELECT breakdown, [weight], estimated_cost FROM project_tasks WHERE project_id=@p AND data_type='item'; -- weight = cost / Σ cost
```

API cross-check for V3, all three must print the same number:

```
GET /projects/{p}/task-summary            → first wbs_level 1 row .actual_progress_itd
GET /projects/{p}/on-stream               → .overall_progress_percentage
GET /projects/{p}/s-curve?refresh=true    → .actual_weight[last][1]
```

## Automated coverage

| scenario | xUnit test |
|---|---|
| S2 | `MultiSourceSpkTests.ActualRows_AreReplayedUnderTheNewTaskShare_WhenASecondSpkJoinsTheTask` |
| weight basis | `MultiSourceSpkTests.ProjectTaskWeights_FollowEstimatedCost_NotConnectedBoqTotals`, `ProjectTaskBoqSubmitTests.Submit_WithSpkId_RecordsTheAssignment_Once` |
| rollup equality | `ProjectScurveRebaselineShapeTests.ActualCurve_EndsOnTheSummaryRollup_NotOnStoredActualWeight` (feature branch), `OnstreamCardStatusTests` |
| S4, S5, S6, S7 | not yet automated |
