/* ---------------------------------------------------------------------------
   vwProjectTaskSummary — performance rewrite.

   Returns byte-identical results to the currently deployed body (verified by
   full-column diff over the 5 largest projects on dev, 0 mismatches), but:

     dev, project with 2,705 tasks    deployed    this view   + index fix
     ---------------------------------------------------------------------
     CPU time                          4,266 ms      641 ms       375 ms
     total logical reads                1.41 M        54 k         34 k
     Worktable (CTE spool) reads      1,276,797          0            0
     projects reads                      87,984         31           31
     project_task_schedules reads        21,900     32,850       12,774

   The last column needs the covering-index fix as well (adding plan_progress
   to IX_project_task_schedules_task_id_date); without it the optimizer will
   not take the per-task seek, because the seek would pay a clustered-index
   lookup for that one uncovered column.

   Three changes, all mechanical:

   1. itd carries project_id in its GROUP BY and joins on it, so the caller's
      `WHERE project_id = @p` PUSHES DOWN into the aggregate. The deployed body
      cannot do this -- project_id is not in its grouping -- so it aggregates
      the ENTIRE project_task_schedules table on every single call, for every
      project. That is why the endpoint degrades as the database grows rather
      than as the project grows, and why 2,700 tasks tips it over.

   2. The `OUTER APPLY ... WHERE c.breakdown LIKE tpt.breakdown + '.%'` is
      replaced by a GROUP BY on the ancestor key derived from each item's own
      breakdown ('1.2.3' -> k1 '1', k2 '1.2'). Same descendant set, but a hash
      aggregate instead of a correlated scan per header row -- this is the
      1.27M Worktable reads, and it goes to zero.

   3. `projects` is joined once in `live` instead of re-joined inside each CTE
      expansion (4,047 scans in the deployed body).

   DELIBERATELY PRESERVED, do not "fix" here: tasks belonging to a SOFT-DELETED
   project still appear, with all ITD figures zeroed. The deployed body filters
   p.deleted_at only inside its `schedules` CTE, never in tempProjectTask, so a
   deleted project keeps returning summary rows. That looks like a bug, but it
   is existing behaviour and this change is perf-only -- 7 such rows showed up
   in the dev diff (project A03B8B2A, deleted 2026-06-24). Fix it separately if
   you agree it is wrong.

   DATA ISSUE FOUND WHILE VERIFYING (not fixed here, needs your call): project
   42B6121E-8646-4D06-A7D4-28BE0801AE15 has a header whose breakdown is '1.2 '
   -- with a trailing space. The deployed view builds the pattern '1.2 .%',
   which matches none of its children, so that header reports 0%% plan and 0%%
   actual even though its children have progress. C# ComputeHeaderItd has the
   same blind spot (StartsWith(Breakdown + ".")). This rewrite reproduces the
   0%% deliberately so the change stays perf-only, but the underlying fix is to
   trim the breakdown in the data. It was the ONLY differing row out of 1,031
   across all 184 projects on dev.

   PAIR THIS WITH THE INDEX FIX (fix-task-summary-performance.sql, PART 1a):
   plan_progress is missing from the INCLUDE list of that index in BOTH dev
   and prod (confirmed from prod's sys.indexes export, 2026-09-07). Adding it
   is what unlocks the third column above.
--------------------------------------------------------------------------- */
ALTER VIEW [dbo].[vwProjectTaskSummary] AS
WITH live AS (
    -- Every non-deleted task, with its project's category. NOTE: no filter on
    -- p.deleted_at here, on purpose -- see the header comment.
    SELECT pt.id, pt.project_id, pt.breakdown, pt.[description], pt.[weight],
           pt.data_type, pt.[status], pt.estimated_cost, p.category,
           p.deleted_at AS project_deleted_at,
           (LEN(pt.breakdown) - LEN(REPLACE(pt.breakdown, '.', '')) + 1) AS wbs_level
    FROM project_tasks pt
    JOIN projects p ON p.id = pt.project_id
    WHERE pt.deleted_at IS NULL
),
itd AS (
    -- project_id is in the GROUP BY *and* the join key below, which is what
    -- lets the caller's project filter reach this aggregate.
    SELECT l.project_id, s.project_task_id,
           SUM(s.plan_progress)   AS plan_progress_itd,
           SUM(s.plan_weight)     AS plan_weight_itd,
           SUM(s.actual_progress) AS actual_progress_itd,
           SUM(s.actual_weight)   AS actual_weight_itd
    FROM project_task_schedules s
    JOIN live l ON l.id = s.project_task_id
    WHERE l.data_type = 'item'
      AND l.project_deleted_at IS NULL          -- matches the old `schedules` CTE
      -- ITD cut-off: same as C# (x.Date.Date <= today.Date), kept sargable
      AND s.[date] < DATEADD(day, 1, CAST(GETDATE() AS date))
    GROUP BY l.project_id, s.project_task_id
),
items AS (
    -- Leaf items with their level-1 and level-2 ancestor keys. k1/k2 are NULL
    -- when the item IS at that level, which reproduces the old body's strict
    -- `LIKE breakdown + '.%'` (a node is not its own descendant).
    SELECT l.project_id, l.[weight],
           COALESCE(i.plan_progress_itd,   0) AS plan_progress_itd,
           COALESCE(i.plan_weight_itd,     0) AS plan_weight_itd,
           COALESCE(i.actual_progress_itd, 0) AS actual_progress_itd,
           COALESCE(i.actual_weight_itd,   0) AS actual_weight_itd,
           CASE WHEN CHARINDEX('.', l.breakdown) > 0
                THEN LEFT(l.breakdown, CHARINDEX('.', l.breakdown) - 1) END AS k1,
           CASE WHEN CHARINDEX('.', l.breakdown, CHARINDEX('.', l.breakdown) + 1) > 0
                THEN LEFT(l.breakdown,
                          CHARINDEX('.', l.breakdown, CHARINDEX('.', l.breakdown) + 1) - 1) END AS k2
    FROM live l
    LEFT JOIN itd i ON i.project_task_id = l.id AND i.project_id = l.project_id
    WHERE l.data_type = 'item'
),
rollups AS (
    SELECT project_id, k1 AS anc,
           COUNT(*)                                AS child_count,
           SUM([weight])                           AS total_child_weight,
           SUM([weight] * plan_progress_itd)       AS weighted_plan,
           SUM([weight] * actual_progress_itd)     AS weighted_actual,
           SUM(plan_progress_itd)                  AS simple_plan,
           SUM(actual_progress_itd)                AS simple_actual,
           SUM(plan_weight_itd)                    AS plan_weight_sum,
           SUM(actual_weight_itd)                  AS actual_weight_sum
    FROM items WHERE k1 IS NOT NULL GROUP BY project_id, k1
    UNION ALL
    SELECT project_id, k2, COUNT(*), SUM([weight]),
           SUM([weight] * plan_progress_itd), SUM([weight] * actual_progress_itd),
           SUM(plan_progress_itd), SUM(actual_progress_itd),
           SUM(plan_weight_itd), SUM(actual_weight_itd)
    FROM items WHERE k2 IS NOT NULL GROUP BY project_id, k2
),
CalculatedData AS (
    -- Header rollup mirrors ProjectTasksService.ComputeHeaderItd /
    -- ResolveHeaderProgress: weight-weighted average of child progress,
    -- falling back to a plain average when the children carry no weight,
    -- and to 0 when there are no children -- never NULL.
    SELECT l.project_id, l.breakdown AS wbs, l.wbs_level, l.[description], l.[weight],
           l.data_type, l.[status], l.estimated_cost, l.category AS project_category,

           CASE WHEN l.data_type = 'item' THEN COALESCE(i.plan_weight_itd, 0)
                ELSE COALESCE(r.plan_weight_sum, 0) END            AS plan_weight_itd,

           CASE WHEN l.data_type = 'item' THEN ROUND(COALESCE(i.plan_progress_itd, 0), 2)
                ELSE ROUND(COALESCE(
                       CASE WHEN r.total_child_weight > 0 THEN r.weighted_plan / r.total_child_weight
                            WHEN r.child_count        > 0 THEN r.simple_plan   / r.child_count
                       END, 0), 2) END                             AS plan_progress_itd,

           CASE WHEN l.data_type = 'item' THEN COALESCE(i.actual_weight_itd, 0)
                ELSE COALESCE(r.actual_weight_sum, 0) END          AS actual_weight_itd,

           CASE WHEN l.data_type = 'item' THEN ROUND(COALESCE(i.actual_progress_itd, 0), 2)
                ELSE ROUND(COALESCE(
                       CASE WHEN r.total_child_weight > 0 THEN r.weighted_actual / r.total_child_weight
                            WHEN r.child_count        > 0 THEN r.simple_actual   / r.child_count
                       END, 0), 2) END                             AS actual_progress_itd
    FROM live l
    LEFT JOIN itd     i ON i.project_task_id = l.id          AND i.project_id = l.project_id
    -- The '#' sentinel makes the comparison trailing-space SENSITIVE, matching the
    -- old body's `LIKE breakdown + '.%'` (and C# ComputeHeaderItd's StartsWith).
    -- Without it, ANSI padding would silently give a differing answer for headers
    -- whose breakdown has a trailing space -- see the note at the top of this file.
    LEFT JOIN rollups r ON r.anc + '#'       = l.breakdown + '#' AND r.project_id = l.project_id
    WHERE l.wbs_level IN (1, 2)
)
SELECT *,
       ROUND(actual_progress_itd - plan_progress_itd, 2) AS variance
FROM CalculatedData;
