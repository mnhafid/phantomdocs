/* ---------------------------------------------------------------------------
   GET /api/v1/projects/{id}/task-summary — production timeout fix.

   ROOT CAUSE (measured, not guessed). The endpoint is a single
   `SELECT * FROM vwProjectTaskSummary WHERE project_id = @p`
   (ProjectTasksService.GetProjectTaskSummary). All the cost is in the view,
   and the view cannot be filtered by project:

     * its `itd` CTE groups only by project_task_id, so `project_id = @p`
       cannot push down -- EVERY call aggregates the WHOLE
       project_task_schedules table, for every project;
     * the header rollup `OUTER APPLY ... LIKE tpt.breakdown + '.%'` spools the
       task CTE once per header row;
     * `projects` is re-joined inside each CTE expansion.

   Cost therefore scales with total database size, not with the project's task
   count -- which is why it kept getting slower until 2,700 tasks tipped it
   past the request timeout.

   Measured on dev (389,909 schedule rows; project with 2,705 tasks), for the
   exact query the endpoint issues:

     deployed view ......  4,266 ms CPU, 1,410,000 logical reads
        of which Worktable (the CTE spool) ...... 1,276,797 reads
        of which projects, re-joined 4,047 times .... 87,984 reads

   Indexes alone will NOT fix this; the view body has to change too.

   Apply in this order.
--------------------------------------------------------------------------- */


/* =========================================================================
   PART 1 — Cover plan_progress.  (~1 min, no redeploy, safe on its own.)

   Prod's IX_project_task_schedules_task_id_date is
       KEY     (project_task_id, date)
       INCLUDE (plan_weight, actual_weight, actual_progress)
   -- confirmed from your sys.indexes export, 2026-09-07.

   plan_progress is missing, and the view sums it alongside the other three.
   That one uncovered column makes SQL Server abandon the per-task seek
   entirely and scan instead: 153,618 reads vs 12,774 on the same query.
   ========================================================================= */
CREATE NONCLUSTERED INDEX IX_project_task_schedules_task_id_date
    ON dbo.project_task_schedules (project_task_id, [date])
    INCLUDE (plan_progress, plan_weight, actual_progress, actual_weight)
    WITH (DROP_EXISTING = ON /*, ONLINE = ON -- Enterprise/Azure only */);
GO


/* =========================================================================
   PART 2 — Replace the view body.  This is the actual fix.

       -> see vwProjectTaskSummary-fast.sql in the repo root.

   It is a pure performance change. Verified on dev by full-column EXCEPT in
   BOTH directions over ALL 184 projects / 1,031 rows: zero differences.
   Even the two known quirks of the current body are reproduced deliberately
   (soft-deleted projects still returned with zeroed ITD; trailing-space
   breakdowns still rolling up to 0) -- both are documented in that file's
   header as separate decisions for you to make, not silently corrected.

   Result on the same dev query:  4,266 ms -> 375 ms CPU,  1.41 M -> 34 k reads.
   ========================================================================= */


/* =========================================================================
   PART 3 — Optional: index project_tasks for the breakdown rollup.

   Prod has IX_project_tasks_project_id_cover = KEY (project_id) INCLUDE
   (data_type, deleted_at, etc) -- breakdown and weight are NOT covered, so
   the rollup still pays lookups (20,911 reads on dev). Worth adding once
   PART 1 + 2 are in and you have a fresh measurement; skip it if the endpoint
   is already comfortably fast, since it is another index to maintain on a
   write-heavy table.
   ========================================================================= */
-- CREATE NONCLUSTERED INDEX IX_project_tasks_project_breakdown_live
--     ON dbo.project_tasks (project_id, breakdown)
--     INCLUDE (data_type, [weight], [status], estimated_cost)
--     WHERE deleted_at IS NULL;
-- GO


/* =========================================================================
   PART 4 — Verify in prod.
   ========================================================================= */
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO
-- substitute the project that was timing out
SELECT * FROM dbo.vwProjectTaskSummary
WHERE project_id = '00000000-0000-0000-0000-000000000000';
GO
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
-- Expect: Worktable 0 reads, projects < 100 reads, and CPU time in the
-- hundreds of ms rather than seconds.


/* =========================================================================
   PART 5 — Stop the drift.

   Neither index is in any EF migration; both were applied by hand, which is
   why they differ between environments and why a freshly provisioned box
   would be slow again. Same for the view body: prod's definition is 3,482
   chars, dev's is 4,193, and the last migration to touch it
   (20260718065055_FixVwProjectTaskSummaryFormula) contains neither. Fold
   PART 1 and PART 2 into one migration so all environments converge.
   ========================================================================= */
