/*  Repair: spk_boqs.weighted_project_task (and the matching plan weights on the S-curve)

    WHY
    weighted_project_task is "this BoQ line's share of the TASK, as a percent". Two writers
    disagreed about it:

      * CreateSpkAsync divided by THIS CONTRACT's lines only, so an SPK that took the task's only
        line from its contract wrote 100 even when the task held lines from other contracts.
      * SpkBoqRecalculationService divided by the task's lines, but summed total_price RAW across
        contracts - adding 20 USD to 800,000 IDR and calling it 800,020.

    Neither reconciled the other, and Create SPK never triggered a task-wide recalculation, so the
    stored values depended on the order of operations. One task ended at 100 + 37.5 + 62.5 = 200%.

    THE RULE (now implemented in SpkBoqRecalculationService.RecalculateTaskBoqWeightsAndPlanAsync)
        weighted_project_task = base(line) / SUM(base(every live line of the task)) * 100
        base(line)            = total_price * usd_rate   when the line's contract is USD
                              = total_price              otherwise

    A line's currency comes from its own live draw: project_task_boq_details -> boq_details ->
    boqs -> contracts.currency. project_task_boqs records no contract of its own.

    IDR is the base. The base does not change the result - the factor cancels out of the ratio -
    it only decides where the rounding lands, and IDR lines (the common case) pass through exact.

    RATE
    Taken from custom_configurations 'usd_rate' at run time. There is no per-contract or historical
    rate stored anywhere, so this is the only rate available. For a task whose lines are all one
    currency the rate is irrelevant: it cancels. It only matters for the few tasks that mix.

    SCOPE
    Live links on live lines that belong to a project task. SPK-owned lines (project_task_id NULL)
    have no task to take a share of and are left alone.

    Run inside the transaction, check the two verification queries, then COMMIT.

    NO VARIABLES ANYWHERE: this runs statement-by-statement in a client that splits on ';'.
    The temp tables and the transaction both live for the SESSION, so keep it on one connection.
*/
SET NOCOUNT ON;

-- The running API writes spk_boqs and spk_boq_schedules too (recalculations, Quartz jobs), and the
-- schedule update touches thousands of rows, so lock escalation makes a collision likely. HIGH tells
-- SQL Server to pick the other session as the deadlock victim instead of this one.
SET DEADLOCK_PRIORITY HIGH;

BEGIN TRANSACTION;

-- The rate, evaluated ONCE into a temp table.
-- Not a variable: a JDBC client that splits the script on ';' runs each statement separately and a
-- DECLARE does not survive into the next one ("Must declare the scalar variable @rate"). Not an
-- inline subquery either: that gets evaluated per row and the script never finishes.
-- Missing, unparseable or zero all fall back to 1 - the same "skip the conversion" rule as the code.
SELECT TOP 1
    ISNULL(NULLIF(TRY_CAST(JSON_VALUE(CAST(cc.detail AS nvarchar(max)), '$[0].value') AS float), 0), 1) AS rate
INTO #rate
FROM custom_configurations cc
WHERE cc.name = 'usd_rate' AND cc.deleted_at IS NULL;

INSERT INTO #rate (rate) SELECT 1 WHERE NOT EXISTS (SELECT 1 FROM #rate);

-- base value per live link, and the task total it is a share of
SELECT
    sb.id                AS link_id,
    sb.project_task_boq_id,
    ptb.project_task_id,
    ptb.volume,
    ptb.start_date,
    ptb.end_date,
    CASE WHEN c.Currency = 'USD' THEN ptb.total_price * r.rate ELSE ptb.total_price END AS base_value,
    sb.weighted_project_task AS old_weight
INTO #link_base
FROM spk_boqs sb
JOIN project_task_boqs ptb       ON ptb.id = sb.project_task_boq_id AND ptb.deleted_at IS NULL
JOIN project_task_boq_details d  ON d.project_task_boq_id = ptb.id  AND d.deleted_at IS NULL
JOIN boq_details bd              ON bd.id = d.boq_detail_id
JOIN boqs b                      ON b.id = bd.boq_id
JOIN contracts c                 ON c.contract_id = b.contract_id
CROSS JOIN #rate r
WHERE sb.DeletedAt IS NULL
  AND ptb.project_task_id IS NOT NULL;

-- One row per task. DISTINCT on the line, not the link: a line under two SPKs carries two links
-- but contributes its value to the task once.
SELECT project_task_id, SUM(base_value) AS task_total
INTO #task_total
FROM (SELECT DISTINCT project_task_boq_id, project_task_id, base_value FROM #link_base) AS lines_
GROUP BY project_task_id;

SELECT lb.link_id,
       lb.project_task_id,
       lb.volume,
       lb.start_date,
       lb.end_date,
       lb.old_weight,
       lb.base_value / tt.task_total * 100 AS new_weight
INTO #fix
FROM #link_base lb
JOIN #task_total tt ON tt.project_task_id = lb.project_task_id
WHERE tt.task_total > 0;

-- 1. the link weight
UPDATE sb
SET sb.weighted_project_task = f.new_weight,
    sb.UpdatedAt = SYSDATETIME()
FROM spk_boqs sb
JOIN #fix f ON f.link_id = sb.id
WHERE ABS(sb.weighted_project_task - f.new_weight) > 0.000001;

-- 2. the same share on the S-curve, so plan_weight_project_task keeps agreeing with the link.
--    Per day it is (plan_volume / volume) * (base / task_total) * 100, and with the volume spread
--    evenly that reduces to new_weight / duration; the accumulation is that times the day index.
-- ROW_NUMBER cannot appear in an UPDATE ... SET, so the day index is materialised first.
SELECT s.id AS schedule_id,
       f.new_weight / NULLIF(DATEDIFF(day, f.start_date, f.end_date) + 1, 0) AS per_day,
       ROW_NUMBER() OVER (PARTITION BY s.spk_boq_id ORDER BY s.[date]) AS day_index
INTO #sched
FROM spk_boq_schedules s
JOIN #fix f ON f.link_id = s.spk_boq_id
WHERE f.volume > 0
  AND DATEDIFF(day, f.start_date, f.end_date) + 1 > 0;

-- Batched: one statement over every schedule row holds locks long enough to deadlock with the
-- application. 1,000 at a time keeps each grab short. The WHERE is also the loop's exit condition -
-- once a row matches it is no longer selected - and it is a tolerance, not equality, because these
-- are floats.
WHILE 1 = 1
BEGIN
    UPDATE TOP (1000) s
    SET s.plan_weight_project_task = sc.per_day,
        s.plan_weight_accumulation_project_task = sc.per_day * sc.day_index
    FROM spk_boq_schedules s
    JOIN #sched sc ON sc.schedule_id = s.id
    WHERE ABS(s.plan_weight_project_task - sc.per_day) > 0.000000001
       OR ABS(s.plan_weight_accumulation_project_task - sc.per_day * sc.day_index) > 0.000000001;

    IF @@ROWCOUNT = 0 BREAK;
END;

-- ── verification ──────────────────────────────────────────────────────────────
-- Expect: every task sums to 100 (within rounding), and no task is left wrong.
-- Sum ONE value per line, not per link: every link of a line carries the same weight, so summing
-- links would multiply a line by how many SPKs hold it. (SUM(DISTINCT value) is also wrong - it
-- collapses two different lines that happen to share a weight.)
SELECT 'tasks_not_summing_to_100' AS check_, COUNT(*) AS n FROM (
    SELECT per_line.project_task_id
    FROM (SELECT DISTINCT lb.project_task_id, lb.project_task_boq_id, sb2.weighted_project_task AS w
          FROM #link_base lb
          JOIN spk_boqs sb2 ON sb2.project_task_boq_id = lb.project_task_boq_id
                           AND sb2.DeletedAt IS NULL) AS per_line
    GROUP BY per_line.project_task_id
    HAVING ABS(SUM(per_line.w) - 100) > 0.01) x;

SELECT TOP 20 'changed' AS check_, f.project_task_id, f.link_id,
       f.old_weight, f.new_weight
FROM #fix f
WHERE ABS(f.old_weight - f.new_weight) > 0.01
ORDER BY f.project_task_id;

DROP TABLE #sched; DROP TABLE #fix; DROP TABLE #rate; DROP TABLE #task_total; DROP TABLE #link_base;

-- Verify above, then:  COMMIT TRANSACTION;   (or ROLLBACK TRANSACTION;)
