/* ============================================================================
   Project search: normalized search_code column + full-text index
   Manual/raw-SQL equivalent of EF migration:
       20260812121248_AddProjectSearchCodeAndFullTextIndex

   TARGET   : SQL Server. Full-Text Search must be installed on the instance.
   RUN AS   : SSMS / Azure Data Studio / sqlcmd (this script uses GO batch
              separators and CANNOT be wrapped in a single explicit transaction
              because CREATE FULLTEXT CATALOG/INDEX are not allowed inside one).
   SAFETY   : Every step is guarded with IF [NOT] EXISTS, so re-running is safe.
   SCHEMA   : assumes the table is [dbo].[projects] and the primary-key index is
              named PK_projects. Verify both first (see step 0b) and adjust if not.
   ============================================================================ */

------------------------------------------------------------------------------
-- 0a. Prerequisite: fail fast (with a clear message) if Full-Text isn't installed.
------------------------------------------------------------------------------
IF SERVERPROPERTY('IsFullTextInstalled') <> 1
BEGIN
    RAISERROR('ABORT: SQL Server Full-Text Search is not installed on this instance. Install the Full-Text feature, then re-run.', 16, 1);
    SET NOEXEC ON;   -- skip all remaining batches
END
GO

------------------------------------------------------------------------------
-- 0b. (Optional) Verify the PK index name used as KEY INDEX in step 4.
--     If this returns something other than 'PK_projects', change step 4 to match.
------------------------------------------------------------------------------
-- SELECT i.name AS pk_index_name
-- FROM sys.indexes i
-- WHERE i.object_id = OBJECT_ID('dbo.projects') AND i.is_primary_key = 1;
-- GO

------------------------------------------------------------------------------
-- 1. Persisted, normalized project_no for partial/cross-separator identifier
--    search (lowercase + strip  -  _  /  .  and space). Kept in sync by the
--    engine; no trigger/app code. Matches NormalizeProjectSearchCode() in code.
------------------------------------------------------------------------------
IF COL_LENGTH('dbo.projects', 'search_code') IS NULL
BEGIN
    ALTER TABLE dbo.projects
        ADD search_code AS
            LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL([project_no], ''), '-', ''), '_', ''), '/', ''), '.', ''), ' ', ''))
        PERSISTED;
END
GO

------------------------------------------------------------------------------
-- 2. Index on the normalized column.
------------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_projects_search_code' AND object_id = OBJECT_ID('dbo.projects'))
BEGIN
    CREATE INDEX IX_projects_search_code ON dbo.projects (search_code);
END
GO

------------------------------------------------------------------------------
-- 3. Full-text catalog.
------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = 'ft_phantom')
BEGIN
    CREATE FULLTEXT CATALOG ft_phantom;
END
GO

------------------------------------------------------------------------------
-- 4. Full-text index on the language columns, keyed on the PK.
--    Default WITH CHANGE_TRACKING AUTO starts an initial population immediately;
--    rows become searchable once that population finishes (asynchronous).
------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.projects'))
BEGIN
    CREATE FULLTEXT INDEX ON dbo.projects (project_no, description)
        KEY INDEX PK_projects ON ft_phantom WITH CHANGE_TRACKING AUTO;
END
GO

------------------------------------------------------------------------------
-- 5. Record the migration as applied so EF does NOT try to re-run it later.
--    (Keeps __EFMigrationsHistory consistent with the deployed schema.)
------------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812121248_AddProjectSearchCodeAndFullTextIndex')
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260812121248_AddProjectSearchCodeAndFullTextIndex', N'9.0.0');
END
GO

SET NOEXEC OFF;
GO

------------------------------------------------------------------------------
-- 6. (Optional) Verify population completed before relying on FREETEXT results.
--    0 = idle/done, non-zero = still populating.
------------------------------------------------------------------------------
-- SELECT OBJECTPROPERTYEX(OBJECT_ID('dbo.projects'), 'TableFulltextPopulateStatus') AS populate_status;
-- GO
