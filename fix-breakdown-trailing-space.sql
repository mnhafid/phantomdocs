/* ---------------------------------------------------------------------------
   Trim leading/trailing whitespace from project_tasks.breakdown.

   WHY IT MATTERS: breakdown is the WBS path that every rollup matches by string
   prefix -- vwProjectTaskSummary joins children via the ancestor key, and C#
   ProjectTasksService.ComputeHeaderItd uses Breakdown.StartsWith(parent + ".").
   A header stored as '1.2 ' builds the prefix '1.2 .' which matches none of its
   children, so the header silently reports 0% plan and 0% actual even though its
   children have progress. Found on dev: project 42B6121E-8646-4D06-A7D4-28BE0801AE15,
   task 623AC4E3-5FEE-47AD-A37A-BD4781077A05, breakdown '[1.2 ]'.

   CAREFUL -- 'x ' = 'x' is TRUE in SQL Server (ANSI padding). A plain
   `WHERE breakdown <> LTRIM(RTRIM(breakdown))` finds NOTHING. Every query below
   uses DATALENGTH, which is the only reliable detector.

   Recurrence is prevented in code: ProjectTasksService now trims at all four
   write sites (MPP/Excel import, both create paths, update). The rebaseline
   import path already trimmed.

   Run steps 1 and 2 first and read the output before running step 3.
--------------------------------------------------------------------------- */

/* --- 1. What is affected? ---------------------------------------------- */
SELECT pt.project_id, pt.id, '[' + pt.breakdown + ']' AS raw_breakdown,
       DATALENGTH(pt.breakdown) AS bytes_now,
       DATALENGTH(LTRIM(RTRIM(pt.breakdown))) AS bytes_after,
       pt.data_type, pt.deleted_at
FROM dbo.project_tasks pt
WHERE DATALENGTH(pt.breakdown) <> DATALENGTH(LTRIM(RTRIM(pt.breakdown)))
ORDER BY pt.project_id, pt.breakdown;

/* --- 2. SAFETY CHECK: would trimming create a duplicate WBS in a project?
       Scoped to the rows step 1 would actually touch, so pre-existing duplicate
       WBS codes elsewhere (dev has two: a project with NULL breakdowns, and
       114AAC4B with two '1.2.1' rows) do not mask the real signal.
       Expect ZERO rows. If any come back, DO NOT run step 3 -- two tasks would
       end up sharing one WBS code and the rollups could double-count.

       NB: SQL Server ignores trailing spaces when comparing AND grouping, so
       '1.2 ' and '1.2' already collapse into one group -- which is exactly what
       makes this check meaningful.                                          */
SELECT victim.project_id,
       '[' + victim.breakdown + ']'               AS untrimmed_row,
       '[' + LTRIM(RTRIM(victim.breakdown)) + ']' AS would_become,
       (SELECT COUNT(*) FROM dbo.project_tasks other
        WHERE other.project_id = victim.project_id
          AND other.deleted_at IS NULL
          AND other.id <> victim.id
          AND other.breakdown = LTRIM(RTRIM(victim.breakdown))) AS would_collide_with
FROM dbo.project_tasks victim
WHERE victim.deleted_at IS NULL
  AND DATALENGTH(victim.breakdown) <> DATALENGTH(LTRIM(RTRIM(victim.breakdown)))
  AND EXISTS (SELECT 1 FROM dbo.project_tasks other
              WHERE other.project_id = victim.project_id
                AND other.deleted_at IS NULL
                AND other.id <> victim.id
                AND other.breakdown = LTRIM(RTRIM(victim.breakdown)));

/* --- 3. The fix. Idempotent: re-running changes nothing. ---------------- */
BEGIN TRANSACTION;

UPDATE dbo.project_tasks
SET    breakdown = LTRIM(RTRIM(breakdown))
WHERE  DATALENGTH(breakdown) <> DATALENGTH(LTRIM(RTRIM(breakdown)));

-- Confirm the count matches step 1 before committing.
PRINT CONCAT('rows trimmed: ', @@ROWCOUNT);

-- COMMIT;      -- uncomment once the count looks right
-- ROLLBACK;    -- otherwise

/* --- 4. Verify: expect zero rows, and the affected header now rolling up. */
-- SELECT COUNT(*) AS still_untrimmed FROM dbo.project_tasks
-- WHERE DATALENGTH(breakdown) <> DATALENGTH(LTRIM(RTRIM(breakdown)));
--
-- SELECT wbs, wbs_level, plan_progress_itd, actual_progress_itd
-- FROM dbo.vwProjectTaskSummary
-- WHERE project_id = '42B6121E-8646-4D06-A7D4-28BE0801AE15' ORDER BY wbs;
