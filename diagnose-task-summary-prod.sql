/* ---------------------------------------------------------------------------
   GET /projects/{id}/task-summary — production diagnostic.

   Confirmed so far: prod HAS IX_project_task_schedules_task_id_date.
   Still unknown, and each one is enough to cause the timeout on its own:
     Q1  does that index actually COVER the 4 columns the view sums?
         (dev's copy of the same-named index omits plan_progress -> 18x reads)
     Q2  does project_tasks have a project_id index at all?
     Q3  is prod still on the OLD quadratic view body?
     Q4  is prod simply much bigger than dev (390k schedule rows)?
     Q5  is it CPU, or is it blocking/waits from concurrent schedule writes?

   Every query here is read-only. Run all five, send back the output.
--------------------------------------------------------------------------- */

/* --- Q1 + Q2: full index definitions, both tables ---------------------- */
SELECT OBJECT_NAME(i.object_id) AS [table],
       i.name                   AS [index],
       i.type_desc,
       ISNULL((SELECT STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal)
               FROM sys.index_columns ic
               JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
               WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                 AND ic.is_included_column = 0), '-')          AS key_cols,
       ISNULL((SELECT STRING_AGG(c.name, ', ')
               FROM sys.index_columns ic
               JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
               WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                 AND ic.is_included_column = 1), '-')          AS included_cols,
       i.filter_definition,
       STATS_DATE(i.object_id, i.index_id)                     AS stats_last_updated
FROM sys.indexes i
WHERE i.object_id IN (OBJECT_ID('dbo.project_task_schedules'), OBJECT_ID('dbo.project_tasks'))
  AND i.type > 0
ORDER BY [table], [index];
-- PASS for Q1: included_cols contains ALL FOUR of
--              plan_progress, plan_weight, actual_progress, actual_weight.
-- PASS for Q2: some index on project_tasks has project_id as its first key col.

/* --- Q3: which view body is deployed? ---------------------------------- */
SELECT CASE WHEN definition LIKE '%SELECT pts.*%'
            THEN 'OLD - quadratic body (migration 20260718065055)'
            ELSE 'NEW - itd CTE + OUTER APPLY' END AS view_version,
       LEN(definition)                             AS definition_len
FROM sys.sql_modules
WHERE object_id = OBJECT_ID('dbo.vwProjectTaskSummary');

/* --- Q4: how much bigger is prod than dev? ----------------------------- */
SELECT (SELECT COUNT(*) FROM dbo.project_task_schedules)                 AS schedule_rows,   -- dev: 389,909
       (SELECT COUNT(*) FROM dbo.project_tasks WHERE deleted_at IS NULL) AS live_tasks,      -- dev:  17,312
       (SELECT COUNT(*) FROM dbo.projects WHERE deleted_at IS NULL)      AS live_projects;

/* --- Q5: what the server itself says about this query ------------------
   Cached plan stats for anything touching the view. If avg_worker_time is
   huge -> CPU/plan problem. If avg_elapsed_time >> avg_worker_time -> the
   query is WAITING (blocking on schedule writes, or IO), not computing.  */
SELECT TOP 10
       qs.execution_count,
       qs.total_worker_time  / qs.execution_count / 1000 AS avg_cpu_ms,
       qs.total_elapsed_time / qs.execution_count / 1000 AS avg_elapsed_ms,
       qs.total_logical_reads / qs.execution_count       AS avg_logical_reads,
       qs.max_elapsed_time / 1000                        AS max_elapsed_ms,
       qs.last_execution_time,
       SUBSTRING(st.text, 1, 200)                        AS query_start
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE st.text LIKE '%vwProjectTaskSummary%'
  AND st.text NOT LIKE '%dm_exec_query_stats%'
ORDER BY qs.total_elapsed_time DESC;

/* --- Q5b: is the plan for it a scan or a seek? Grab the actual plan. ----
   Run the endpoint's own query and look at the plan, substituting the
   project that times out.                                                */
-- SET STATISTICS IO ON; SET STATISTICS TIME ON;
-- SELECT * FROM dbo.vwProjectTaskSummary WHERE project_id = '<the slow project id>';
--   -> send back the STATISTICS IO line for project_task_schedules and the
--      "SQL Server Execution Times" for the statement.
