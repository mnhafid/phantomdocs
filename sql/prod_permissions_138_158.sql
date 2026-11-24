-- Production: permission_groups 19, 20, 21, 26 and permissions 138, 140, 141, 142, 144, 153-158.
-- Idempotent: neither table has a primary key, so every INSERT skips an id that already exists
-- (a duplicate id crashes the permission lookups). Safe to run more than once.
-- No DECLARE / GO: runs as separate statements in DBeaver.

-- 1. permission_groups --------------------------------------------------------------------------
INSERT INTO permission_groups (id, name, description, created_at, updated_at)
SELECT v.id, v.name, v.description, GETDATE(), GETDATE()
FROM (VALUES
    (19, N'Well Monitoring',       NULL),
    (20, N'Well Monitoring EUR',   NULL),
    (21, N'Compressor Monitoring', NULL),
    (26, N'Unit Conversion',       N'Unit conversion master data')
) v (id, name, description)
WHERE NOT EXISTS (SELECT 1 FROM permission_groups g WHERE g.id = v.id);

-- 2. permissions ----------------------------------------------------------------------------------
-- 138-144 names = the Retina ACL PAGE of the same SEQ (dev has them NULL).
INSERT INTO permissions (id, permission_group_id, name, description, created_at, updated_at)
SELECT v.id, v.group_id, v.name, v.description, GETDATE(), GETDATE()
FROM (VALUES
    (138, 20, 'Upload Well Data',          NULL),
    (140, 20, 'Read Well Monitoring EUR',  NULL),
    (141, 21, 'Read Unit Monitoring',      NULL),
    (142, 21, 'schematic',                 NULL),
    (144, 21, 'Modify Unit Data',          NULL),
    (153, 19, 'Read PHSS Wells',           'View PHSS wells, EUR monitoring, charts and action plans'),
    (154, 19, 'Modify PHSS Wells',         'Create / update / import PHSS wells and PHSS action plans'),
    (155, 19, 'Read PEP Wells',            'View PEP wells, EUR monitoring, charts and action plans'),
    (156, 19, 'Modify PEP Wells',          'Create / update / import PEP wells and PEP action plans'),
    (157, 26, 'Read Unit Conversion',      'View unit conversions'),
    (158, 26, 'Modify Unit Conversion',    'Update unit conversions')
) v (id, group_id, name, description)
WHERE NOT EXISTS (SELECT 1 FROM permissions p WHERE p.id = v.id);

-- 3. Check: 4 groups and 11 permissions, each id once, group as listed above ------------------------
SELECT g.id, g.name, COUNT(*) AS copies
FROM permission_groups g
WHERE g.id IN (19, 20, 21, 26)
GROUP BY g.id, g.name
ORDER BY g.id;

SELECT p.id, p.permission_group_id, p.name, COUNT(*) AS copies
FROM permissions p
WHERE p.id IN (138, 140, 141, 142, 144, 153, 154, 155, 156, 157, 158)
GROUP BY p.id, p.permission_group_id, p.name
ORDER BY p.id;
