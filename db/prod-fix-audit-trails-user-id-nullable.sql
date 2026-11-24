/*  Fix: audit_trails.user_id must allow NULL (Luvus t82)

    WHY
    The EF migration 20260314000000_AddAuditTrails declares user_id nullable, but dev AND prod
    carry the column as NOT NULL (the table predates the migration). AuditTrailMiddleware audits
    every request, and for Login / RefreshToken / GetUserProfile there is no resolved user yet,
    so the INSERT fails: 558 "Failed to create audit trail" errors per day on production
    (phantom-20260924.log). Making the column match the migration keeps those rows.

    HOW TO RUN (DBeaver / sqlcmd, one batch, idempotent)
    The column sits in IX_audit_trails_user_id, and SQL Server refuses ALTER COLUMN on an indexed
    column, so the index is dropped and recreated around the change.
*/
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.audit_trails') AND name = 'user_id' AND is_nullable = 0)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.audit_trails') AND name = 'IX_audit_trails_user_id')
        DROP INDEX IX_audit_trails_user_id ON dbo.audit_trails;

    ALTER TABLE dbo.audit_trails ALTER COLUMN user_id uniqueidentifier NULL;

    CREATE NONCLUSTERED INDEX IX_audit_trails_user_id ON dbo.audit_trails (user_id);
    PRINT 'audit_trails.user_id is now nullable';
END
ELSE
    PRINT 'audit_trails.user_id already nullable - nothing to do';

-- verify: expect IS_NULLABLE = YES
SELECT COLUMN_NAME, IS_NULLABLE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'audit_trails' AND COLUMN_NAME = 'user_id';
