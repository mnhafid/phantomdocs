-- Backfill: spk_boq_schedules plan_* columns that were never written (PHI-boq-progress-1 / t42).
--
-- Population: 61 live spk_boqs (720 schedule rows) created 2026-06-23..2026-07-26 whose schedule
-- rows exist but carry plan_volume_accumulation = plan_cost_accumulation = 0. Today's code cannot
-- produce that (SpksService.BuildSpkBoqPlanSchedules / SpkModificationsService both divide
-- unconditionally), so this is historical data, not a live bug — nothing after 2026-07-26 is affected.
--
-- Recomputes the same spread BuildSpkBoqPlanSchedules would have written:
--     plan_volume   = volume / duration            plan_progress = 100 / duration   (volume > 0)
--     plan_cost     = total_price / duration       plan_weight   = weight% / duration
--     *_accumulation = per-day value * day ordinal
--
-- duration = the number of schedule rows the spk_boq actually has, NOT
-- DATEDIFF(project_task_boqs.start_date, end_date): 4 of the 61 have had their BoQ dates edited since
-- and 2 hold a duplicated date, and only the row count makes the final accumulation land on the full
-- volume/cost, which is what the S-curve readers need.
--
-- Idempotent by scope: after a successful run these spk_boqs no longer match
-- HAVING MAX(plan_volume_accumulation) = 0, so a second run is a no-op. It does not repair drift.
--
-- Self-contained on purpose: no DECLARE, no GO, no temp tables — a JDBC client that splits on ';'
-- runs each statement as-is. Dry-run it under SET NOEXEC ON (PARSEONLY does not guard a GO-less file).

-- 1. Line weights, for the 19 rows in this population whose weighted_spk was never written either
--    (their SPK's spk_value is non-zero, so 0 is wrong). Left out, plan_weight below would inherit
--    the zero and a reader summing the daily slices would disagree with the line total.
WITH unplanned AS (
    SELECT sb.id
    FROM spk_boqs sb
    JOIN spk_boq_schedules s ON s.spk_boq_id = sb.id
    WHERE sb.DeletedAt IS NULL
    GROUP BY sb.id
    HAVING MAX(s.plan_volume_accumulation) = 0
),
weights AS (
    SELECT sb.id,
           CASE WHEN sp.spk_value > 0 THEN p.total_price / sp.spk_value * 100 ELSE 0 END AS w_spk,
           CASE WHEN tt.task_total > 0 THEN p.total_price / tt.task_total * 100 ELSE 0 END AS w_task
    FROM spk_boqs sb
    JOIN unplanned u ON u.id = sb.id
    JOIN project_task_boqs p ON p.id = sb.project_task_boq_id
    JOIN spks sp ON sp.spk_id = sb.spk_id
    OUTER APPLY (
        -- The task's lines that this SPK actually took, which is what CreateSpk's taskTotalByTask holds.
        SELECT SUM(p2.total_price) AS task_total
        FROM spk_boqs sb2
        JOIN project_task_boqs p2 ON p2.id = sb2.project_task_boq_id
        WHERE sb2.spk_id = sb.spk_id
          AND sb2.DeletedAt IS NULL
          AND p2.project_task_id = p.project_task_id
    ) tt
)
UPDATE sb
SET weighted_spk = w.w_spk,
    weighted_project_task = w.w_task
FROM spk_boqs sb
JOIN weights w ON w.id = sb.id
WHERE (sb.weighted_spk = 0 AND w.w_spk <> 0)
   OR (sb.weighted_project_task = 0 AND w.w_task <> 0);

-- 2. The daily plan spread itself.
WITH unplanned AS (
    SELECT sb.id
    FROM spk_boqs sb
    JOIN spk_boq_schedules s ON s.spk_boq_id = sb.id
    WHERE sb.DeletedAt IS NULL
    GROUP BY sb.id
    HAVING MAX(s.plan_volume_accumulation) = 0
),
spread AS (
    SELECT s.id,
           p.volume,
           p.total_price,
           sb.weighted_spk,
           sb.weighted_project_task,
           COUNT(*) OVER (PARTITION BY s.spk_boq_id) AS duration,
           ROW_NUMBER() OVER (PARTITION BY s.spk_boq_id ORDER BY s.date, s.id) AS day_no
    FROM spk_boq_schedules s
    JOIN unplanned u ON u.id = s.spk_boq_id
    JOIN spk_boqs sb ON sb.id = s.spk_boq_id
    JOIN project_task_boqs p ON p.id = sb.project_task_boq_id
)
UPDATE s
SET plan_volume = sp.volume / sp.duration,
    plan_volume_accumulation = sp.volume / sp.duration * sp.day_no,
    plan_progress = CASE WHEN sp.volume > 0 THEN 100.0 / sp.duration ELSE 0 END,
    plan_progress_accumulation = CASE WHEN sp.volume > 0 THEN 100.0 / sp.duration * sp.day_no ELSE 0 END,
    plan_weight = sp.weighted_spk / sp.duration,
    plan_weight_accumulation = sp.weighted_spk / sp.duration * sp.day_no,
    plan_weight_project_task = sp.weighted_project_task / sp.duration,
    plan_weight_accumulation_project_task = sp.weighted_project_task / sp.duration * sp.day_no,
    plan_cost = sp.total_price / sp.duration,
    plan_cost_accumulation = sp.total_price / sp.duration * sp.day_no
FROM spk_boq_schedules s
JOIN spread sp ON sp.id = s.id;
