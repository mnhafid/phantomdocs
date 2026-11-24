DECLARE @pid uniqueidentifier = '95A24C01-A4DA-4579-804E-3153831D59C1';
DECLARE @wbs varchar(50) = '1.3';

-- 1) What the summary API returns for this row (NULL here == "" in the JSON)
SELECT wbs, wbs_level, data_type, weight,
       plan_weight_itd, plan_progress_itd, actual_weight_itd, actual_progress_itd, variance
FROM dbo.vwProjectTaskSummary
WHERE project_id = @pid AND wbs = @wbs;

-- 2) The node itself + every descendant, with the two pieces of the view's formula
SELECT pt.breakdown, pt.data_type, pt.[weight], pt.[status],
       COALESCE((SELECT SUM(s.actual_weight)   FROM project_task_schedules s
                 WHERE s.project_task_id = pt.id AND s.date <= GETDATE()), 0) AS actual_weight_itd,
       COALESCE((SELECT SUM(s.actual_progress) FROM project_task_schedules s
                 WHERE s.project_task_id = pt.id AND s.date <= GETDATE()), 0) AS actual_progress_itd
FROM project_tasks pt
WHERE pt.project_id = @pid AND pt.deleted_at IS NULL
  AND (pt.breakdown = @wbs OR pt.breakdown LIKE @wbs + '.%')
ORDER BY LEN(pt.breakdown), pt.breakdown;

-- 3) The exact numerator / denominator the view computes for this header
SELECT
  (SELECT SUM(COALESCE((SELECT SUM(s.actual_weight) FROM project_task_schedules s
                        WHERE s.project_task_id = c.id AND s.date <= GETDATE()), 0))
   FROM project_tasks c
   WHERE c.project_id = @pid AND c.deleted_at IS NULL
     AND (c.breakdown = @wbs OR c.breakdown LIKE @wbs + '.%'))               AS numerator_actual_weight_itd,
  (SELECT SUM(c.[weight]) FROM project_tasks c
   WHERE c.project_id = @pid AND c.deleted_at IS NULL AND c.data_type = 'item'
     AND (c.breakdown = @wbs OR c.breakdown LIKE @wbs + '.%'))               AS denominator_sum_item_weight,
  (SELECT COUNT(*) FROM project_tasks c
   WHERE c.project_id = @pid AND c.deleted_at IS NULL AND c.data_type = 'item'
     AND (c.breakdown = @wbs OR c.breakdown LIKE @wbs + '.%'))               AS descendant_item_count;
