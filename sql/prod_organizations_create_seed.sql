-- Production: create dbo.organizations (same DDL as migration 20261012064740_EnsureOrganizationsTable)
-- and seed the ADR-0008 tree: PHE > Regional 3 > Zona 9 > PnP / SSDP > 5 departments.
-- Idempotent: every statement skips what already exists. Safe to run more than once.
-- No DECLARE / GO, no ';' inside a statement: runs as separate statements in DBeaver.
-- Ids are the same fixed GUIDs as dev, so data is the same across environments.
-- created_by / updated_by = the oldest active user (column is NOT NULL); empty GUID if there is none.

-- 1. Table --------------------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.organizations', N'U') IS NULL
EXEC (N'CREATE TABLE dbo.organizations (
    id uniqueidentifier NOT NULL CONSTRAINT DF_organizations_id DEFAULT (newid()),
    code nvarchar(50) NULL,
    name nvarchar(255) NULL,
    type nvarchar(50) NULL,
    parent_id uniqueidentifier NULL,
    company_id uniqueidentifier NULL,
    path nvarchar(500) NULL,
    level int NOT NULL,
    is_active int NOT NULL CONSTRAINT DF_organizations_is_active DEFAULT (1),
    created_at datetime2 NOT NULL,
    created_by uniqueidentifier NOT NULL,
    updated_at datetime2 NOT NULL,
    updated_by uniqueidentifier NOT NULL,
    deleted_at datetime2 NULL,
    deleted_by uniqueidentifier NULL,
    CONSTRAINT PK_organizations PRIMARY KEY (id),
    CONSTRAINT FK_organizations_parent FOREIGN KEY (parent_id) REFERENCES dbo.organizations (id)
)');

-- 2. Indexes ------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.organizations') AND name = N'UX_organizations_code')
EXEC (N'CREATE UNIQUE INDEX UX_organizations_code ON dbo.organizations (code) WHERE code IS NOT NULL');

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.organizations') AND name = N'IX_organizations_parent_id')
EXEC (N'CREATE INDEX IX_organizations_parent_id ON dbo.organizations (parent_id)');

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.organizations') AND name = N'IX_organizations_path')
EXEC (N'CREATE INDEX IX_organizations_path ON dbo.organizations (path)');

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.organizations') AND name = N'IX_organizations_company_id')
EXEC (N'CREATE INDEX IX_organizations_company_id ON dbo.organizations (company_id)');

-- 3. Seed: one statement for the whole tree. Rows are ordered parent-first, so the self-FK holds.
--    A code that already exists is skipped (unique index on code).
INSERT INTO dbo.organizations
    (id, code, name, type, parent_id, company_id, path, level, is_active, created_at, created_by, updated_at, updated_by)
SELECT v.id, v.code, v.name, v.type, v.parent_id, '0A000000-0000-0000-0000-000000000001', v.path, v.level, 1,
       GETDATE(),
       COALESCE((SELECT TOP 1 u.id FROM dbo.users u WHERE u.deleted_at IS NULL ORDER BY u.created_at), '00000000-0000-0000-0000-000000000000'),
       GETDATE(),
       COALESCE((SELECT TOP 1 u.id FROM dbo.users u WHERE u.deleted_at IS NULL ORDER BY u.created_at), '00000000-0000-0000-0000-000000000000')
FROM (VALUES
    ('0A000000-0000-0000-0000-000000000001', N'PHE',     N'PHE',                            N'company',    NULL,                                   N'/PHE',                     0),
    ('0A000000-0000-0000-0000-000000000002', N'REG3',    N'Regional 3',                     N'regional',   '0A000000-0000-0000-0000-000000000001', N'/PHE/REG3',                1),
    ('0A000000-0000-0000-0000-000000000003', N'Z9',      N'Zona 9',                         N'zona',       '0A000000-0000-0000-0000-000000000002', N'/PHE/REG3/Z9',             2),
    ('0A000000-0000-0000-0000-000000000004', N'PNP',     N'PnP',                            N'division',   '0A000000-0000-0000-0000-000000000003', N'/PHE/REG3/Z9/PNP',         3),
    ('0A000000-0000-0000-0000-000000000005', N'SSDP',    N'SSDP',                           N'division',   '0A000000-0000-0000-0000-000000000003', N'/PHE/REG3/Z9/SSDP',        3),
    ('0A000000-0000-0000-0000-000000000006', N'PROJECT', N'Project',                        N'department', '0A000000-0000-0000-0000-000000000004', N'/PHE/REG3/Z9/PNP/PROJECT', 4),
    ('0A000000-0000-0000-0000-000000000007', N'PO',      N'Production Operations',          N'department', '0A000000-0000-0000-0000-000000000004', N'/PHE/REG3/Z9/PNP/PO',      4),
    ('0A000000-0000-0000-0000-000000000008', N'OSF',     N'Operation & Surface Facilities', N'department', '0A000000-0000-0000-0000-000000000004', N'/PHE/REG3/Z9/PNP/OSF',     4),
    ('0A000000-0000-0000-0000-000000000009', N'SDA1',    N'Subsurface Development Area 1',  N'department', '0A000000-0000-0000-0000-000000000005', N'/PHE/REG3/Z9/SSDP/SDA1',   4),
    ('0A000000-0000-0000-0000-000000000010', N'SDA2',    N'Subsurface Development Area 2',  N'department', '0A000000-0000-0000-0000-000000000005', N'/PHE/REG3/Z9/SSDP/SDA2',   4)
) v (id, code, name, type, parent_id, path, level)
WHERE NOT EXISTS (SELECT 1 FROM dbo.organizations o WHERE o.code = v.code OR o.id = v.id);

-- 4. Check: 10 rows, departments under the right division -----------------------------------------
SELECT o.code, o.name, o.type, p.code AS parent_code, o.path, o.level, o.is_active
FROM dbo.organizations o
LEFT JOIN dbo.organizations p ON p.id = o.parent_id
WHERE o.deleted_at IS NULL
ORDER BY o.level, o.path;
