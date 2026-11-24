ALTER VIEW [dbo].[vwProjectTaskSummary] AS
-- Header rollup mirrors ProjectTasksService.ComputeHeaderItd / ResolveHeaderProgress:
--   weight-weighted average of child progress, falling back to a plain average when the
--   children carry no weight, and to 0 when there are no children -- never NULL.
WITH schedules AS (
    SELECT pts.project_task_id, pts.plan_progress, pts.plan_weight,
           pts.actual_progress, pts.actual_weight
    FROM project_task_schedules pts
    JOIN project_tasks pt ON pts.project_task_id = pt.id
    JOIN projects p       ON pt.project_id = p.id
    WHERE pt.deleted_at IS NULL
      AND p.deleted_at IS NULL
      AND pt.data_type = 'item'
      -- ITD cut-off: same as C# (x.Date.Date <= today.Date), kept sargable
      AND pts.date < DATEADD(day, 1, CAST(GETDATE() AS date))
),
itd AS (
    SELECT project_task_id,
           SUM(plan_progress)   AS plan_progress_itd,
           SUM(plan_weight)     AS plan_weight_itd,
           SUM(actual_progress) AS actual_progress_itd,
           SUM(actual_weight)   AS actual_weight_itd
    FROM schedules
    GROUP BY project_task_id
),
tempProjectTask AS (
    SELECT
        pt.id, pt.project_id, pt.breakdown, pt.[description], pt.[weight],
        pt.data_type, pt.[status], pt.estimated_cost, p.category,
        (LEN(pt.breakdown) - LEN(REPLACE(pt.breakdown, '.', '')) + 1) AS wbs_level,
        COALESCE(i.plan_progress_itd,   0) AS plan_progress_itd,
        COALESCE(i.plan_weight_itd,     0) AS plan_weight_itd,
        COALESCE(i.actual_progress_itd, 0) AS actual_progress_itd,
        COALESCE(i.actual_weight_itd,   0) AS actual_weight_itd
    FROM project_tasks pt
    JOIN projects p    ON pt.project_id = p.id
    LEFT JOIN itd i    ON i.project_task_id = pt.id
    WHERE pt.deleted_at IS NULL
),
CalculatedData AS (
    SELECT
        tpt.project_id, tpt.breakdown AS wbs, tpt.wbs_level, tpt.[description], tpt.[weight],
        tpt.data_type, tpt.[status], tpt.estimated_cost, tpt.category AS project_category,

        CASE WHEN tpt.data_type = 'item' THEN tpt.plan_weight_itd
             ELSE COALESCE(r.plan_weight_sum, 0) END          AS plan_weight_itd,

        CASE WHEN tpt.data_type = 'item' THEN ROUND(tpt.plan_progress_itd, 2)
             ELSE ROUND(COALESCE(
                    CASE WHEN r.total_child_weight > 0 THEN r.weighted_plan / r.total_child_weight
                         WHEN r.child_count        > 0 THEN r.simple_plan   / r.child_count
                    END, 0), 2) END                           AS plan_progress_itd,

        CASE WHEN tpt.data_type = 'item' THEN tpt.actual_weight_itd
             ELSE COALESCE(r.actual_weight_sum, 0) END        AS actual_weight_itd,

        CASE WHEN tpt.data_type = 'item' THEN ROUND(tpt.actual_progress_itd, 2)
             ELSE ROUND(COALESCE(
                    CASE WHEN r.total_child_weight > 0 THEN r.weighted_actual / r.total_child_weight
                         WHEN r.child_count        > 0 THEN r.simple_actual   / r.child_count
                    END, 0), 2) END                           AS actual_progress_itd
    FROM tempProjectTask tpt
    OUTER APPLY (
        -- descendant leaf items at any depth, same set as
        -- allTasks.Where(t => t.DataType == "item" && t.Breakdown.StartsWith(task.Breakdown + "."))
        SELECT COUNT(*)                                AS child_count,
               SUM(c.[weight])                         AS total_child_weight,
               SUM(c.[weight] * c.plan_progress_itd)   AS weighted_plan,
               SUM(c.[weight] * c.actual_progress_itd) AS weighted_actual,
               SUM(c.plan_progress_itd)                AS simple_plan,
               SUM(c.actual_progress_itd)              AS simple_actual,
               SUM(c.plan_weight_itd)                  AS plan_weight_sum,
               SUM(c.actual_weight_itd)                AS actual_weight_sum
        FROM tempProjectTask c
        WHERE c.project_id = tpt.project_id
          AND c.data_type  = 'item'
          AND c.breakdown LIKE tpt.breakdown + '.%'
    ) r
)
SELECT *,
       ROUND(actual_progress_itd - plan_progress_itd, 2) AS variance
FROM CalculatedData
WHERE wbs_level IN (1, 2);
