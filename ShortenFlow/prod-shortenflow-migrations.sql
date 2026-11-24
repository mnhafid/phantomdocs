-- Production DDL + backfill for the two ShortenFlow migrations, hand-run form:
--   20260812063201_AddProjectTaskSpks
--   20260817230252_AddProjectTaskBoqDrafts
--
-- Extracted from the migration files verbatim; every step is guarded so the whole file is
-- idempotent — a re-run changes nothing. Do NOT use `dotnet ef database update` on production:
-- the repo's migration history and the databases have drifted in both directions, and EF would
-- try to replay unrelated old migrations.
--
-- No GO, no DECLARE — but the guarded IF...BEGIN blocks hold several statements, so this file
-- must run AS A WHOLE SCRIPT, not through a client that splits on ';' (DBeaver: Execute Script /
-- Alt+X, or sqlcmd -i). Section order matters: the table before its backfill, both migrations
-- before their history rows.

-- ===========================================================================
-- 1. 20260812063201_AddProjectTaskSpks — schema
-- ===========================================================================

IF COL_LENGTH('project_tasks', 'spk_type') IS NULL
    ALTER TABLE project_tasks ADD spk_type nvarchar(20) NULL;

IF OBJECT_ID('project_task_spks') IS NULL
BEGIN
    CREATE TABLE project_task_spks
    (
        id                  uniqueidentifier NOT NULL CONSTRAINT DF_project_task_spks_id DEFAULT NEWID()
                                             CONSTRAINT PK_project_task_spks PRIMARY KEY,
        project_task_id     uniqueidentifier NOT NULL,
        spk_id              uniqueidentifier NOT NULL,
        spk_cost            float            NULL,
        is_primary          bit              NOT NULL CONSTRAINT DF_project_task_spks_is_primary DEFAULT 0,
        unassigned_at       datetime         NULL,
        unassigned_by       uniqueidentifier NULL,
        unassignment_reason nvarchar(100)    NULL,
        source              nvarchar(50)     NULL,
        created_at          datetime         NULL,
        created_by          uniqueidentifier NULL,
        updated_at          datetime         NULL,
        updated_by          uniqueidentifier NULL,
        deleted_at          datetime         NULL,
        deleted_by          uniqueidentifier NULL,
        CONSTRAINT FK_project_task_spks_project_tasks_project_task_id
            FOREIGN KEY (project_task_id) REFERENCES project_tasks (id),
        CONSTRAINT FK_project_task_spks_spks_spk_id
            FOREIGN KEY (spk_id) REFERENCES spks (spk_id)
    );

    CREATE INDEX IX_project_task_spks_spk_id
        ON project_task_spks (spk_id, unassigned_at);

    CREATE UNIQUE INDEX UX_project_task_spks_active
        ON project_task_spks (project_task_id, spk_id)
        WHERE [unassigned_at] IS NULL AND [deleted_at] IS NULL;

    CREATE UNIQUE INDEX UX_project_task_spks_primary
        ON project_task_spks (project_task_id)
        WHERE [is_primary] = 1 AND [unassigned_at] IS NULL AND [deleted_at] IS NULL;
END;

-- ---------------------------------------------------------------------------
-- 1a. Backfill — union of BOTH sources, not either alone: spk_boqs resolves only a subset
--     (various-WBS lines carry a null project_task_id) and the legacy column holds assignments
--     no spk_boqs row supports. The NOT EXISTS guards make each statement re-runnable, which the
--     EF original did not need (EF runs a migration once); a hand-run script has to.
-- ---------------------------------------------------------------------------

-- Every assignment the legacy column knows. Each becomes the primary.
INSERT INTO project_task_spks
    (id, project_task_id, spk_id, spk_cost, is_primary, source, created_at, created_by)
SELECT NEWID(), pt.id, pt.spk_id, pt.spk_cost, 1, 'column',
       COALESCE(pt.updated_at, pt.created_at, SYSUTCDATETIME()), pt.updated_by
FROM   project_tasks pt
WHERE  pt.spk_id IS NOT NULL
  AND  pt.deleted_at IS NULL
  AND  NOT EXISTS (SELECT 1 FROM project_task_spks x
                   WHERE x.project_task_id = pt.id AND x.spk_id = pt.spk_id);

-- Assignments only spk_boqs knows. Not primary — the column already named its own.
-- spk_boqs is the one table whose audit columns are PascalCase (sb.DeletedAt, sb.CreatedAt).
-- Deliberately NO pt.spk_id IS NULL filter: a task whose column names one SPK can have BoQ
-- lines on a second, and that second assignment is exactly what this table exists to record.
INSERT INTO project_task_spks
    (id, project_task_id, spk_id, spk_cost, is_primary, source, created_at)
SELECT NEWID(), ptb.project_task_id, sb.spk_id,
       SUM(ptb.total_price), 0, 'spk_boqs', MIN(sb.CreatedAt)
FROM   spk_boqs sb
JOIN   project_task_boqs ptb ON ptb.id = sb.project_task_boq_id
JOIN   project_tasks pt      ON pt.id  = ptb.project_task_id
WHERE  sb.DeletedAt IS NULL
  AND  ptb.deleted_at IS NULL
  AND  pt.deleted_at IS NULL
  AND  ptb.project_task_id IS NOT NULL
  AND  NOT EXISTS (SELECT 1 FROM project_task_spks x
                   WHERE  x.project_task_id = ptb.project_task_id
                     AND  x.spk_id          = sb.spk_id)
GROUP BY ptb.project_task_id, sb.spk_id;

-- Close the assignments of every cancelled SPK, keeping the row as history.
UPDATE l
SET    l.unassigned_at       = COALESCE(s.canceled_at, SYSUTCDATETIME()),
       l.unassigned_by       = s.canceled_by,
       l.unassignment_reason = s.status,
       l.is_primary          = 0
FROM   project_task_spks l
JOIN   spks s ON s.spk_id = l.spk_id
WHERE  s.status = 'canceled'
  AND  l.unassigned_at IS NULL;

-- Derive spk_type from the assignments just written. Idempotent by construction.
UPDATE pt
SET    pt.spk_type = t.new_type
FROM   project_tasks pt
CROSS APPLY (
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

-- ===========================================================================
-- 2. 20260817230252_AddProjectTaskBoqDrafts
-- ===========================================================================

IF OBJECT_ID('project_task_boq_drafts') IS NULL
BEGIN
    CREATE TABLE project_task_boq_drafts
    (
        id              uniqueidentifier NOT NULL CONSTRAINT PK_project_task_boq_drafts PRIMARY KEY,
        project_task_id uniqueidentifier NOT NULL,
        contract_id     uniqueidentifier NOT NULL,
        payload         nvarchar(max)    NOT NULL,
        created_at      datetime         NOT NULL,
        created_by      uniqueidentifier NOT NULL,
        updated_at      datetime         NULL,
        updated_by      uniqueidentifier NULL
    );

    CREATE UNIQUE INDEX UX_project_task_boq_drafts_project_task_id
        ON project_task_boq_drafts (project_task_id);
END;

-- ===========================================================================
-- 3. Record both in __EFMigrationsHistory so EF tooling agrees with reality.
-- ===========================================================================

INSERT INTO __EFMigrationsHistory (MigrationId, ProductVersion)
SELECT '20260812063201_AddProjectTaskSpks', '8.0.0'
WHERE NOT EXISTS (SELECT 1 FROM __EFMigrationsHistory
                  WHERE MigrationId = '20260812063201_AddProjectTaskSpks');

INSERT INTO __EFMigrationsHistory (MigrationId, ProductVersion)
SELECT '20260817230252_AddProjectTaskBoqDrafts', '8.0.0'
WHERE NOT EXISTS (SELECT 1 FROM __EFMigrationsHistory
                  WHERE MigrationId = '20260817230252_AddProjectTaskBoqDrafts');

-- ===========================================================================
-- 4. VERIFY — run after. Expect: both tables listed, spk_type present, 2 history rows.
-- ===========================================================================

SELECT o.name FROM sys.objects o
WHERE o.name IN ('project_task_spks', 'project_task_boq_drafts');

SELECT COL_LENGTH('project_tasks', 'spk_type') AS spk_type_len;

SELECT MigrationId FROM __EFMigrationsHistory
WHERE MigrationId IN ('20260812063201_AddProjectTaskSpks',
                      '20260817230252_AddProjectTaskBoqDrafts');
