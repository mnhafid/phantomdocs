-- Removes the phirbac.role.* mock test users created by 07-seed-test-users.sql. Dev only. Review before running.
-- Deletes only rows for ids 0b000000-0000-0000-0000-000000000501 to 0b000000-0000-0000-0000-000000000541 and usernames starting with phirbac.role.
DELETE FROM dbo.casbin_rule WHERE ptype = 'g' AND v0 IN (SELECT 'user' + LOWER(CAST(id AS varchar(36))) FROM dbo.users WHERE retina_id LIKE N'PHIRBAC.ROLE.%');
DELETE FROM dbo.mock_auth_sessions WHERE username LIKE N'phirbac.role.%';
DELETE FROM dbo.users WHERE retina_id LIKE N'PHIRBAC.ROLE.%' AND id BETWEEN '0b000000-0000-0000-0000-000000000501' AND '0b000000-0000-0000-0000-000000000541';
