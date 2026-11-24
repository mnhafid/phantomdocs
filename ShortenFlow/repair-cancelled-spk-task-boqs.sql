-- Repair: task BoQ lines left live behind SPKs cancelled BEFORE c6f5734b (PR #1067).
--
-- c6f5734b made CancelSpkAsync soft-delete the project_task_boqs (and their details) reachable
-- from the cancelled SPK's spk_boqs rows. SPKs cancelled before that shipped never ran it, so
-- their lines are still live. Post-c6f5734b the combination "SPK is canceled AND its line is
-- live" cannot occur, which is what makes every row below provably debris.
--
-- Scope, deliberately: BoQ lines and their details ONLY. project_tasks.contract_id is NOT
-- touched -- a task may legitimately be contract-assigned with no SPK (the codebase queries
-- exactly that state), so clearing it blind would destroy real data. See D5 in the session
-- decisions and D2 in docs/ShortenFlow/spk-cancel-parity-FINDINGS.md.
--
-- Scoped by spk_boqs, never by project_task_id: a task may still hold another live SPK whose
-- lines must survive, and a various-WBS SPK's lines carry a NULL project_task_id entirely.
--
-- Written as single self-contained statements: no GO, no DECLARE, no batch variables, so it
-- runs one statement at a time in a JDBC client that splits on ';'.
-- Run A first, read the counts, then run B and C. Re-run A afterwards: it must return 0 rows.

-- ---------------------------------------------------------------------------
-- A. AUDIT (read-only). What would be repaired, and under which SPK.
-- ---------------------------------------------------------------------------
SELECT s.spk_id, s.spk_no, s.status, s.canceled_at,
       COUNT(DISTINCT ptb.id) AS live_lines,
       COUNT(DISTINCT ptbd.id) AS live_details
FROM spks s
JOIN spk_boqs sb           ON sb.spk_id = s.spk_id
JOIN project_task_boqs ptb ON ptb.id = sb.project_task_boq_id AND ptb.deleted_at IS NULL
LEFT JOIN project_task_boq_details ptbd
       ON ptbd.project_task_boq_id = ptb.id AND ptbd.deleted_at IS NULL
WHERE s.status = 'canceled'
GROUP BY s.spk_id, s.spk_no, s.status, s.canceled_at
ORDER BY s.canceled_at DESC;

-- ---------------------------------------------------------------------------
-- B. REPAIR the detail rows first, so a failure between B and C leaves details
--    hidden under a line that is still visible -- not orphan details under a
--    hidden line. Replace the two literals with the operator's user id / time.
-- ---------------------------------------------------------------------------
UPDATE ptbd
SET    ptbd.deleted_at = SYSDATETIME(),
       ptbd.deleted_by = '00000000-0000-0000-0000-000000000001'
FROM   project_task_boq_details ptbd
JOIN   project_task_boqs ptb ON ptb.id = ptbd.project_task_boq_id
JOIN   spk_boqs sb           ON sb.project_task_boq_id = ptb.id
JOIN   spks s                ON s.spk_id = sb.spk_id
WHERE  s.status = 'canceled'
  AND  ptbd.deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- C. REPAIR the lines.
-- ---------------------------------------------------------------------------
UPDATE ptb
SET    ptb.deleted_at = SYSDATETIME(),
       ptb.deleted_by = '00000000-0000-0000-0000-000000000001'
FROM   project_task_boqs ptb
JOIN   spk_boqs sb ON sb.project_task_boq_id = ptb.id
JOIN   spks s      ON s.spk_id = sb.spk_id
WHERE  s.status = 'canceled'
  AND  ptb.deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- D. VERIFY. Must return no rows. Re-run A as well.
-- ---------------------------------------------------------------------------
SELECT s.spk_no, ptb.id AS still_live_line
FROM spks s
JOIN spk_boqs sb           ON sb.spk_id = s.spk_id
JOIN project_task_boqs ptb ON ptb.id = sb.project_task_boq_id AND ptb.deleted_at IS NULL
WHERE s.status = 'canceled';
