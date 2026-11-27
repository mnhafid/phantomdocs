-- DEV ONLY. Casbin g rows for the phi.wo.* test users (06 §4.5), so GET /users/by-permission/{id} lists them
-- after PR #1558 (casbin for every permission). Run AFTER src-be/DataAccess/Database/seed_work_order_casbin.sql.
-- Role = the Phantom role with the same name as the user's SYSROLE. The "Approval Manager" SYSROLEs have no Phantom role,
-- so the Managers and the GM get "... - Approval - Member" (273, 277, 278, 279). Idempotent, DBeaver-safe.

SET XACT_ABORT ON;
BEGIN TRANSACTION;

INSERT INTO casbin_rule (ptype, v0, v1, v2)
SELECT 'g', 'user' + LOWER(CONVERT(nvarchar(36), u.id)), 'role' + CAST(r.id AS nvarchar(20)), ''
FROM (VALUES
    ('PHI.WO.PO.PIC',      'Production Operations - Modify - Member'),
    ('PHI.WO.PO.SENIOR',   'Production Operations - Approval - Member'),
    ('PHI.WO.PO.SENIOR2',  'Production Operations - Approval - Member'),
    ('PHI.WO.PO.MANAGER',  'Production Operations - Approval - Member'),
    ('PHI.WO.OSF.PIC',     'Operations & Surface Facilities - Modify - Member'),
    ('PHI.WO.OSF.SENIOR',  'Operations & Surface Facilities - Approval - Member'),
    ('PHI.WO.OSF.MANAGER', 'Operations & Surface Facilities - Approval - Member'),
    ('PHI.WO.OSF.GUEST',   'Operations & Surface Facilities - Read - Guest'),
    ('PHI.WO.PRJ.PIC',     'Projects - Modify - Member'),
    ('PHI.WO.PRJ.SENIOR',  'Projects - Approval - Member'),
    ('PHI.WO.PRJ.MANAGER', 'Projects - Approval - Member'),
    ('PHI.WO.SDA1.PIC',    'Subsurface Development Area 1 - Modify - Member'),
    ('PHI.WO.GM',          'Production Operations - Approval - Member'),
    ('PHI.WO.GM',          'Operations & Surface Facilities - Approval - Member'),
    ('PHI.WO.GM',          'Projects - Approval - Member')
) m (username, role_name)
JOIN users u ON u.username = m.username AND u.deleted_at IS NULL
JOIN roles r ON r.name = m.role_name AND r.deleted_at IS NULL
WHERE NOT EXISTS (
    SELECT 1 FROM casbin_rule c
    WHERE c.ptype = 'g' AND c.v0 = 'user' + LOWER(CONVERT(nvarchar(36), u.id)) AND c.v1 = 'role' + CAST(r.id AS nvarchar(20)));

COMMIT TRANSACTION;
