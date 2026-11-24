-- Phantom side of SEQ 10000 'SUPER ADMIN' (Retina file: PhantomRoles_6Roles.oracle.sql).
-- Without a dbo.permissions row, GET /api/v1/users/permissions silently drops SEQ 10000.
-- Group 27 'Super Admin' is new. Idempotent; DBeaver-safe (no DECLARE / GO). NOT run yet.

SET XACT_ABORT ON;
BEGIN TRANSACTION;

INSERT INTO dbo.permission_groups (id, name, description, created_at, updated_at)
SELECT 27, 'Super Admin', 'Super admin marker privilege', GETDATE(), GETDATE()
WHERE NOT EXISTS (SELECT 1 FROM dbo.permission_groups WHERE id = 27);

INSERT INTO dbo.permissions (id, permission_group_id, name, description, created_at, updated_at)
SELECT 10000, 27, 'SUPER ADMIN', 'Full access marker for the Super Admin role', GETDATE(), GETDATE()
WHERE NOT EXISTS (SELECT 1 FROM dbo.permissions WHERE id = 10000);

-- Phantom role grant (casbin p-rule) for the Super Admin role, looked up by name.
INSERT INTO dbo.casbin_rule (ptype, v0, v1, v2)
SELECT 'p', CONCAT('role', r.id), '27', '10000'
FROM dbo.roles r
WHERE r.name = 'Super Admin' AND r.deleted_at IS NULL
  AND NOT EXISTS (SELECT 1 FROM dbo.casbin_rule c WHERE c.ptype = 'p' AND c.v0 = CONCAT('role', r.id) AND c.v2 = '10000');

COMMIT TRANSACTION;
