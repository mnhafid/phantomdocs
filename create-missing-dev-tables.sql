/* =============================================================================
   create-missing-dev-tables.sql
   Purpose : Create the 3 EF-mapped tables that are MISSING on the shared dev DB
             (phantomdb @ 185.250.38.82) and cause runtime "Invalid object name"
             errors. Confirmed 2026-06-22 via read-only INFORMATION_SCHEMA audit
             + usage trace (entity + DbSet + active query all exist; table absent
             even case-insensitively).

   Source of truth : runtime EF model = Entities + PhantomDb.*.cs fluent mappings
                     (NOT PhantomDbContextModelSnapshot.cs, which is stale here).
       - tenants       : src-be/DataAccess/DbContext/PhantomDb.Tenant.cs  (exact)
       - notifications : src-be/DataAccess/DbContext/PhantomDb.Notification.cs (exact)
       - areas         : NO OnModelCreatingArea in source -> see WARNING below

   Impact if not applied:
       - tenants       : TenantsService (CRUD) + R3 TenantService -> all fail
       - areas         : AreasService (CRUD) + PlantsService area-exists check
                         on Plant create/update -> fail
       - notifications : NotificationsService (CRUD) + background inserts from
                         ProjectRemindersService / ProjectTaskNotificationsService
                         (Quartz jobs; QRTZ_* exist on dev) -> silently throw

   DESIGN NOTES (please review before applying):
   1. FOREIGN KEYS are intentionally OMITTED. None of the three fluent mappings
      declares a relational FK; adding them risks the shadow-FK / cascade-path
      issues already seen on this DB. Add FKs separately if desired
      (e.g. notifications.user_id -> users.id, notifications.tenant_id -> tenants.id).
   2. id DEFAULT (newid()) is added on all three per the project's universal
      "Id default (newid())" convention (CLAUDE.md). The app may also supply Id
      client-side; the default is harmless either way.
   3. Column TYPES are reproduced verbatim from the fluent mapping. Tenant uses
      legacy TEXT for size/status/address/rejection_reason and NVARCHAR(MAX) for
      the *_by audit columns -- faithful to PhantomDb.Tenant.cs. If your standards
      prefer VARCHAR(MAX) over deprecated TEXT, that is a safe substitute (EF reads
      both into string).
   4. Idempotent: each CREATE is guarded by IF NOT EXISTS, safe to re-run.

   *** WARNING - areas ***
   The runtime DbContext has NO explicit OnModelCreatingArea mapping and there is
   NO global snake_case naming convention in the codebase. The column definitions
   below are taken from the (possibly stale) ModelSnapshot, which lists snake_case
   names + datetime2. They are consistent with every other table in this DB, BUT
   without runtime fluent config EF could instead fall back to CONVENTION names
   (PascalCase: "IsActive", "CreatedAt", ...) -- a real risk because is_active vs
   IsActive differ by more than case. RECOMMENDED real fix: add an explicit
   OnModelCreatingArea partial in src-be/DataAccess/DbContext/PhantomDb.Area.cs to
   lock the mapping, THEN create the table to match. Confirm against the running
   app before applying the areas block.
   ============================================================================= */

SET NOCOUNT ON;
GO

/* ----------------------------- tenants ----------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'tenants' AND SCHEMA_NAME(schema_id) = N'dbo')
BEGIN
    CREATE TABLE dbo.tenants
    (
        id                 UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_tenants_id DEFAULT (newid()),
        code               VARCHAR(20)      NULL,
        is_active          BIT              NOT NULL,
        user_name          VARCHAR(255)     NULL,
        email              VARCHAR(255)     NULL,
        phone_number       VARCHAR(15)      NULL,
        phone_iso_code     VARCHAR(5)       NULL,
        phone_country_code VARCHAR(5)       NULL,
        business_name      VARCHAR(255)     NULL,
        industry_id        UNIQUEIDENTIFIER NOT NULL,
        size               TEXT             NOT NULL,
        status             TEXT             NOT NULL,
        address            TEXT             NULL,
        npwp               VARCHAR(50)      NULL,
        siup               VARCHAR(50)      NULL,
        nib                VARCHAR(50)      NULL,
        created_at         DATETIME         NULL,
        created_by         NVARCHAR(MAX)    NULL,
        updated_at         DATETIME         NULL,
        updated_by         NVARCHAR(MAX)    NULL,
        approved_at        DATETIME         NULL,
        approved_by        NVARCHAR(MAX)    NULL,
        rejected_at        DATETIME         NULL,
        rejected_by        NVARCHAR(MAX)    NULL,
        rejection_reason   TEXT             NULL,
        deleted_at         DATETIME         NULL,
        deleted_by         UNIQUEIDENTIFIER NULL,
        CONSTRAINT PK_tenants PRIMARY KEY CLUSTERED (id)
    );
    PRINT 'Created table dbo.tenants';
END
ELSE
    PRINT 'Skipped dbo.tenants (already exists)';
GO

/* ----------------------------- notifications ----------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'notifications' AND SCHEMA_NAME(schema_id) = N'dbo')
BEGIN
    CREATE TABLE dbo.notifications
    (
        id          UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_notifications_id DEFAULT (newid()),
        title       NVARCHAR(200)    NULL,
        message     NVARCHAR(510)    NULL,
        has_read    INT              NOT NULL,
        web_link    NVARCHAR(510)    NULL,
        mobile_link NVARCHAR(510)    NULL,
        created_at  DATETIME         NOT NULL,
        updated_at  DATETIME         NULL,
        updated_by  UNIQUEIDENTIFIER NULL,
        deleted_at  DATETIME         NULL,
        deleted_by  UNIQUEIDENTIFIER NULL,
        user_id     UNIQUEIDENTIFIER NOT NULL,
        tenant_id   UNIQUEIDENTIFIER NULL,
        CONSTRAINT PK_notifications PRIMARY KEY CLUSTERED (id)
    );
    PRINT 'Created table dbo.notifications';
END
ELSE
    PRINT 'Skipped dbo.notifications (already exists)';
GO

/* ----------------------------- areas (SEE WARNING IN HEADER) ----------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'areas' AND SCHEMA_NAME(schema_id) = N'dbo')
BEGIN
    CREATE TABLE dbo.areas
    (
        id         UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_areas_id DEFAULT (newid()),
        name       NVARCHAR(100)    NOT NULL,
        is_active  INT              NOT NULL,
        created_at DATETIME2        NOT NULL,
        created_by UNIQUEIDENTIFIER NOT NULL,
        updated_at DATETIME2        NULL,
        updated_by UNIQUEIDENTIFIER NULL,
        deleted_at DATETIME2        NULL,
        deleted_by UNIQUEIDENTIFIER NULL,
        CONSTRAINT PK_areas PRIMARY KEY CLUSTERED (id)
    );
    PRINT 'Created table dbo.areas';
END
ELSE
    PRINT 'Skipped dbo.areas (already exists)';
GO

/* =============================================================================
   FOREIGN KEYS (part b)
   - areas FKs are MODEL-BACKED: PhantomDb.Area.cs maps UserCreate/UserUpdate/
     UserDelete onto created_by/updated_by/deleted_by, so these match the runtime
     model exactly.
   - notifications FKs are DB-integrity only (the Notification fluent mapping
     declares no relational navigation), but user_id/tenant_id clearly reference
     users/tenants.
   - tenants: NO FKs. Its audit columns (created_by/updated_by/approved_by/
     rejected_by) are NVARCHAR(MAX), not uniqueidentifier, so they cannot
     reference users.id; industry_id has no industries table in this schema.
   All FKs are NO ACTION (no cascade) to avoid multiple-cascade-path errors.
   New tables are empty, so WITH CHECK validates trivially.
   ============================================================================= */

/* ---- areas -> users ---- */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_areas_users_created_by')
    ALTER TABLE dbo.areas WITH CHECK
        ADD CONSTRAINT FK_areas_users_created_by FOREIGN KEY (created_by) REFERENCES dbo.users (id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_areas_users_updated_by')
    ALTER TABLE dbo.areas WITH CHECK
        ADD CONSTRAINT FK_areas_users_updated_by FOREIGN KEY (updated_by) REFERENCES dbo.users (id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_areas_users_deleted_by')
    ALTER TABLE dbo.areas WITH CHECK
        ADD CONSTRAINT FK_areas_users_deleted_by FOREIGN KEY (deleted_by) REFERENCES dbo.users (id);
GO

/* ---- notifications -> users / tenants ---- */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_notifications_users_user_id')
    ALTER TABLE dbo.notifications WITH CHECK
        ADD CONSTRAINT FK_notifications_users_user_id FOREIGN KEY (user_id) REFERENCES dbo.users (id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_notifications_tenants_tenant_id')
    ALTER TABLE dbo.notifications WITH CHECK
        ADD CONSTRAINT FK_notifications_tenants_tenant_id FOREIGN KEY (tenant_id) REFERENCES dbo.tenants (id);
GO
