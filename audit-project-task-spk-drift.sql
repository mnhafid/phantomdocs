SET NOCOUNT ON;
PRINT '=== A. baseline volumes ===';
SELECT
  (SELECT COUNT(*) FROM project_tasks WHERE deleted_at IS NULL)                        AS tasks_live,
  (SELECT COUNT(*) FROM project_tasks WHERE deleted_at IS NULL AND spk_id IS NOT NULL)  AS tasks_with_spk_col,
  (SELECT COUNT(*) FROM spks WHERE deleted_at IS NULL)                                  AS spks_live,
  (SELECT COUNT(*) FROM spk_boqs)                                                       AS spk_boqs_all,
  (SELECT COUNT(*) FROM spk_boqs WHERE DeletedAt IS NOT NULL)                           AS spk_boqs_softdel,
  (SELECT COUNT(*) FROM spk_boqs WHERE project_task_boq_id IS NULL)                     AS spkboq_null_ptbid;

PRINT '';
PRINT '=== B. four-bucket diff: column vs structural path ===';
WITH structural AS (
  SELECT DISTINCT ptb.project_task_id AS task_id, sb.spk_id
  FROM spk_boqs sb
  JOIN project_task_boqs ptb ON ptb.id = sb.project_task_boq_id
  WHERE ptb.project_task_id IS NOT NULL
),
col AS (SELECT id AS task_id, spk_id FROM project_tasks WHERE spk_id IS NOT NULL)
SELECT
  (SELECT COUNT(*) FROM (SELECT task_id, spk_id FROM col
     EXCEPT SELECT task_id, spk_id FROM structural) x)      AS b1_column_only,
  (SELECT COUNT(*) FROM (SELECT task_id, spk_id FROM structural
     EXCEPT SELECT task_id, spk_id FROM col) x)             AS b2_structural_only,
  (SELECT COUNT(*) FROM col c JOIN structural s
     ON s.task_id = c.task_id AND s.spk_id <> c.spk_id)     AS b3_disagree,
  (SELECT COUNT(*) FROM (SELECT task_id FROM structural
     GROUP BY task_id HAVING COUNT(DISTINCT spk_id) > 1) x) AS b4_task_many_spks;

PRINT '';
PRINT '=== C. b2 breakdown by SPK status ===';
WITH structural AS (
  SELECT DISTINCT ptb.project_task_id AS task_id, sb.spk_id
  FROM spk_boqs sb JOIN project_task_boqs ptb ON ptb.id = sb.project_task_boq_id
  WHERE ptb.project_task_id IS NOT NULL),
col AS (SELECT id AS task_id, spk_id FROM project_tasks WHERE spk_id IS NOT NULL),
b2 AS (SELECT task_id, spk_id FROM structural EXCEPT SELECT task_id, spk_id FROM col)
SELECT ISNULL(s.status,'(spk row missing)') AS spk_status, s.is_various, COUNT(*) AS n
FROM b2 LEFT JOIN spks s ON s.spk_id = b2.spk_id
GROUP BY s.status, s.is_various ORDER BY n DESC;

PRINT '';
PRINT '=== D. blockers ===';
SELECT
  (SELECT COUNT(*) FROM spk_boqs sb JOIN project_task_boqs ptb ON ptb.id = sb.project_task_boq_id
     WHERE ptb.project_task_id IS NULL)                                     AS spkboq_task_null,
  (SELECT COUNT(*) FROM (SELECT project_task_boq_id FROM spk_boqs
     WHERE project_task_boq_id IS NOT NULL
     GROUP BY project_task_boq_id HAVING COUNT(*) > 1) x)                   AS ptb_dup_spkboq,
  (SELECT COUNT(*) FROM (SELECT project_task_boq_id FROM spk_boqs
     WHERE project_task_boq_id IS NOT NULL
     GROUP BY project_task_boq_id HAVING COUNT(DISTINCT spk_id) > 1) x)     AS ptb_on_many_spks,
  (SELECT COUNT(*) FROM project_tasks pt WHERE pt.spk_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM spks s WHERE s.spk_id = pt.spk_id))      AS orphan_spk_fk;

PRINT '';
PRINT '=== E. spk_cost desync (defect 1) ===';
SELECT
  (SELECT COUNT(*) FROM project_tasks WHERE deleted_at IS NULL
     AND spk_id IS NULL AND spk_cost IS NOT NULL AND spk_cost <> 0)  AS cost_but_no_spk,
  (SELECT COUNT(*) FROM project_tasks WHERE deleted_at IS NULL
     AND spk_id IS NOT NULL AND (spk_cost IS NULL OR spk_cost = 0))  AS spk_but_no_cost,
  (SELECT COUNT(*) FROM project_tasks WHERE deleted_at IS NULL AND spk_cost IS NULL) AS cost_null;
SET NOCOUNT ON;
PRINT '=== F. does spk_cost equal SUM(project_task_boqs.total_price)? (linked tasks only) ===';
WITH boqsum AS (
  SELECT project_task_id, SUM(total_price) AS s
  FROM project_task_boqs WHERE deleted_at IS NULL AND project_task_id IS NOT NULL
  GROUP BY project_task_id
)
SELECT
  COUNT(*) AS linked_tasks,
  SUM(CASE WHEN ABS(ISNULL(pt.spk_cost,0) - ISNULL(b.s,0)) < 0.01 THEN 1 ELSE 0 END) AS matches_boq_sum,
  SUM(CASE WHEN ABS(ISNULL(pt.spk_cost,0) - ISNULL(b.s,0)) >= 0.01 THEN 1 ELSE 0 END) AS differs,
  SUM(CASE WHEN b.s IS NULL THEN 1 ELSE 0 END) AS task_has_no_boq_lines
FROM project_tasks pt
LEFT JOIN boqsum b ON b.project_task_id = pt.id
WHERE pt.deleted_at IS NULL AND pt.spk_id IS NOT NULL;

PRINT '';
PRINT '=== G. the 18 linked-but-no-cost tasks: do they have BOQ lines? ===';
WITH boqsum AS (
  SELECT project_task_id, SUM(total_price) AS s, COUNT(*) AS n
  FROM project_task_boqs WHERE deleted_at IS NULL AND project_task_id IS NOT NULL
  GROUP BY project_task_id)
SELECT TOP 20 pt.id AS task_id, pt.spk_cost, ISNULL(b.n,0) AS boq_lines, ISNULL(b.s,0) AS boq_sum, s.status AS spk_status
FROM project_tasks pt
LEFT JOIN boqsum b ON b.project_task_id = pt.id
LEFT JOIN spks s ON s.spk_id = pt.spk_id
WHERE pt.deleted_at IS NULL AND pt.spk_id IS NOT NULL AND (pt.spk_cost IS NULL OR pt.spk_cost = 0);

PRINT '';
PRINT '=== H. the task that already has TWO SPKs ===';
WITH structural AS (
  SELECT DISTINCT ptb.project_task_id AS task_id, sb.spk_id
  FROM spk_boqs sb JOIN project_task_boqs ptb ON ptb.id = sb.project_task_boq_id
  WHERE ptb.project_task_id IS NOT NULL)
SELECT st.task_id, st.spk_id, s.spk_no, s.status, s.is_various, pt.spk_id AS column_says
FROM structural st
JOIN spks s ON s.spk_id = st.spk_id
JOIN project_tasks pt ON pt.id = st.task_id
WHERE st.task_id IN (SELECT task_id FROM structural GROUP BY task_id HAVING COUNT(DISTINCT spk_id) > 1);

PRINT '';
PRINT '=== I. the 15 column-only rows: what SPK status? ===';
WITH structural AS (
  SELECT DISTINCT ptb.project_task_id AS task_id, sb.spk_id
  FROM spk_boqs sb JOIN project_task_boqs ptb ON ptb.id = sb.project_task_boq_id
  WHERE ptb.project_task_id IS NOT NULL),
col AS (SELECT id AS task_id, spk_id FROM project_tasks WHERE spk_id IS NOT NULL),
b1 AS (SELECT task_id, spk_id FROM col EXCEPT SELECT task_id, spk_id FROM structural)
SELECT s.status, s.is_various, COUNT(*) AS n
FROM b1 JOIN spks s ON s.spk_id = b1.spk_id
GROUP BY s.status, s.is_various ORDER BY n DESC;

PRINT '';
PRINT '=== J. how many spk_boqs belong to various SPKs (the 100 null-task rows) ===';
SELECT s.is_various, s.status, COUNT(*) AS spk_boq_rows
FROM spk_boqs sb
JOIN project_task_boqs ptb ON ptb.id = sb.project_task_boq_id
JOIN spks s ON s.spk_id = sb.spk_id
WHERE ptb.project_task_id IS NULL
GROUP BY s.is_various, s.status ORDER BY spk_boq_rows DESC;
SET NOCOUNT ON;
PRINT '=== K. the 18 mismatched tasks: various or not, and timing ===';
WITH boqsum AS (
  SELECT project_task_id, SUM(total_price) AS s, MIN(created_at) AS boq_created, MAX(ISNULL(updated_at,created_at)) AS boq_touched
  FROM project_task_boqs WHERE deleted_at IS NULL AND project_task_id IS NOT NULL
  GROUP BY project_task_id)
SELECT s.is_various, COUNT(*) AS tasks,
       SUM(CASE WHEN b.boq_touched > pt.updated_at THEN 1 ELSE 0 END) AS boq_changed_after_task,
       SUM(CASE WHEN b.boq_created > pt.updated_at THEN 1 ELSE 0 END) AS boq_created_after_task
FROM project_tasks pt
JOIN spks s ON s.spk_id = pt.spk_id
LEFT JOIN boqsum b ON b.project_task_id = pt.id
WHERE pt.deleted_at IS NULL AND pt.spk_id IS NOT NULL
  AND ABS(ISNULL(pt.spk_cost,0) - ISNULL(b.s,0)) >= 0.01
GROUP BY s.is_various;

PRINT '';
PRINT '=== L. same split for the 27 that MATCH ===';
WITH boqsum AS (
  SELECT project_task_id, SUM(total_price) AS s FROM project_task_boqs
  WHERE deleted_at IS NULL AND project_task_id IS NOT NULL GROUP BY project_task_id)
SELECT s.is_various, COUNT(*) AS tasks
FROM project_tasks pt JOIN spks s ON s.spk_id = pt.spk_id
LEFT JOIN boqsum b ON b.project_task_id = pt.id
WHERE pt.deleted_at IS NULL AND pt.spk_id IS NOT NULL
  AND ABS(ISNULL(pt.spk_cost,0) - ISNULL(b.s,0)) < 0.01
GROUP BY s.is_various;

PRINT '';
PRINT '=== M. sample timing detail for 5 mismatched tasks ===';
WITH boqsum AS (
  SELECT project_task_id, SUM(total_price) AS s, MIN(created_at) AS boq_created
  FROM project_task_boqs WHERE deleted_at IS NULL AND project_task_id IS NOT NULL
  GROUP BY project_task_id)
SELECT TOP 5 pt.id AS task_id, pt.spk_cost, b.s AS boq_sum,
       CONVERT(varchar(19), pt.updated_at, 120) AS task_updated,
       CONVERT(varchar(19), b.boq_created, 120) AS boq_created,
       s.is_various
FROM project_tasks pt JOIN spks s ON s.spk_id = pt.spk_id
LEFT JOIN boqsum b ON b.project_task_id = pt.id
WHERE pt.deleted_at IS NULL AND pt.spk_id IS NOT NULL
  AND ABS(ISNULL(pt.spk_cost,0) - ISNULL(b.s,0)) >= 0.01;

PRINT '';
PRINT '=== N. per-link cost feasibility: can we compute cost per (task,spk) from spk_boqs? ===';
SELECT COUNT(*) AS resolvable_link_rows,
       COUNT(DISTINCT CONCAT(CONVERT(varchar(36),ptb.project_task_id),'|',CONVERT(varchar(36),sb.spk_id))) AS distinct_links
FROM spk_boqs sb
JOIN project_task_boqs ptb ON ptb.id = sb.project_task_boq_id
WHERE ptb.project_task_id IS NOT NULL AND ptb.deleted_at IS NULL;

-- ============================================================================
-- STANDING AUDIT + REPAIR  (run on a schedule after AddProjectTaskSpks ships)
--
-- project_task_spks is authoritative at task grain; project_tasks.spk_id mirrors
-- the single primary assignment. Nothing repairs a disagreement between
-- project_task_spks and spk_boqs automatically — checks 1 and 2 report for a
-- human. Only spk_type is auto-repairable, and REPAIR below is that statement.
-- See .claude/docs/adr/0007.
-- ============================================================================

PRINT '=== CHECK 1: legacy column disagrees with its primary assignment ===';
SELECT COUNT(*) AS mirror_mismatch
FROM   project_tasks pt
LEFT   JOIN project_task_spks l
       ON l.project_task_id = pt.id
      AND l.is_primary = 1
      AND l.unassigned_at IS NULL
      AND l.deleted_at IS NULL
WHERE  pt.deleted_at IS NULL
  AND  ISNULL(CONVERT(varchar(36), pt.spk_id), '~') <> ISNULL(CONVERT(varchar(36), l.spk_id), '~');

PRINT '';
PRINT '=== CHECK 2: task has active assignments but no primary among them ===';
SELECT COUNT(*) AS active_without_primary
FROM   project_tasks pt
WHERE  pt.deleted_at IS NULL
  AND  EXISTS (SELECT 1 FROM project_task_spks l
               WHERE l.project_task_id = pt.id AND l.unassigned_at IS NULL AND l.deleted_at IS NULL)
  AND  NOT EXISTS (SELECT 1 FROM project_task_spks l
                   WHERE l.project_task_id = pt.id AND l.is_primary = 1
                     AND l.unassigned_at IS NULL AND l.deleted_at IS NULL);

PRINT '';
PRINT '=== CHECK 3: spk_type disagrees with the count of active assignments ===';
SELECT COUNT(*) AS spk_type_wrong
FROM   project_tasks pt
OUTER  APPLY (SELECT COUNT(*) AS n FROM project_task_spks l
              WHERE l.project_task_id = pt.id AND l.unassigned_at IS NULL AND l.deleted_at IS NULL) a
WHERE  pt.deleted_at IS NULL
  AND  ISNULL(pt.spk_type, '~') <> ISNULL(
         CASE WHEN a.n = 0 THEN NULL WHEN a.n = 1 THEN 'single' ELSE 'multi' END, '~');

PRINT '';
PRINT '=== REPAIR: spk_type only. Idempotent — a second run changes 0 rows. ===';
UPDATE pt
SET    pt.spk_type = t.new_type
FROM   project_tasks pt
CROSS  APPLY (
    SELECT CASE WHEN a.n = 0 THEN NULL
                WHEN a.n = 1 THEN 'single'
                ELSE              'multi' END AS new_type
    FROM  (SELECT COUNT(*) AS n
           FROM   project_task_spks l
           WHERE  l.project_task_id = pt.id
             AND  l.unassigned_at IS NULL
             AND  l.deleted_at    IS NULL) a
) t
WHERE ISNULL(pt.spk_type, '~') <> ISNULL(t.new_type, '~');
PRINT CONCAT('spk_type rows repaired: ', @@ROWCOUNT);
