# Water flood write permission (154 / 156): dev findings and prod runbook

| | |
|---|---|
| **Written** | 2026-10-20 |
| **Endpoints** | `/api/v1/water-flood/wells/{phss\|pep}` (+ `/update`, `/{id}`, `/overview`, `/tanks`), `/api/v1/users/by-permission/{id}` |
| **Related** | `rbac-phss-pep-privileges.md` (privileges 153–158, FE-guard decision), `seed_rbac_phss_pep_privileges.sql` |

## 1. Which permission each endpoint checks

| Endpoint | Check | Source |
|---|---|---|
| `GET /water-flood/wells/{wa}`, `/overview`, `/tanks` | Login + working-area guard only (SDA 1 → 404 on `pep`, SDA 2 → 404 on `phss`) | `R3ComponentFilter` |
| `POST /water-flood/wells/{wa}` (create), `/{wa}/update`, `/{wa}/{id}` (delete) | **154 "Modify PHSS Wells"** for `phss`, **156 "Modify PEP Wells"** for `pep`; else 403 *"You don't have permission to modify injection wells under '…'"* | `WaterFloodService.EnsureCanWriteWorkingAreaAsync` → `PermissionService.HasPermissionByNameAsync` → **Phantom Casbin** |
| `GET /users/by-permission/{id}` | Lists active users whose Casbin role(s) hold the permission | `UsersService.GetUsersByPermissionAsync` → **Phantom Casbin** |
| `GET /users/permissions` (FE guard) | Privileges the user holds | **Retina ACL** (cached) |

The write check runs **before** any lookup, so a delete of a non-existent id is a safe probe:
404 *"Injection well not found."* = allowed, 403 = refused, 404 with no message = working-area guard.

**Two sources.** The FE shows the modify button from the Retina ACL (`/users/permissions`); the backend
allows the write from Casbin. If they disagree the user sees the button and gets 403.

## 2. Dev findings (2026-10-20)

Before: every write returned 403, Super Admin included. `casbin_rule` held no grant for 153–156.

1. Ran `seed_rbac_phss_pep_privileges.sql` (owner). It grants by role **name** to
   `regulator of production operations` / `regulator of Subsurface Development Area 1|2` / `Super Admin`.
   **Writes stayed 403**: the test users hold differently named roles:

   | User | Casbin role they hold | Seed granted to |
   |---|---|---|
   | r3test.sda1 | 1116 `Subsurface Development Area 1` | 1114 `regulator of Subsurface Development Area 1` |
   | r3test.sda2 | 1117 `Subsurface Development Area 2` | 1115 `regulator of Subsurface Development Area 2` |
   | r3test.superadmin | 1110 `SuperAdmin` | 1 `Super Admin` |
   | r3test.po | 1102 `Production Operations` | 1105 `regulator of production operations` |

2. Granted the same sets to the roles actually held (18 p-rules): 1116 → 137 138 139 140 153 154,
   1117 → 137 138 139 140 155 156, 1110 → 153–158.

After:

| User | GET phss | GET pep | Write phss | Write pep |
|---|---|---|---|---|
| sda1 | 200 | 404 (guard) | 404 = **allowed** | 404 (guard) |
| sda2 | 404 (guard) | 200 | 404 (guard) | 404 = **allowed** |
| po | 200 | 200 | 403 (view only, correct) | 403 (correct) |
| superadmin | 200 | 200 | 404 = **allowed** | 404 = **allowed** |

`/users/by-permission/154` → 5 users, `/156` → 4 users. Caveats:
- The response's `role` is `users.role_id`, not the Casbin role that qualified the user (mk.super_admin
  shows "Project" but qualifies through a second role `Super Admin`).
- r3test.sm.pnp is listed under 154 through a leftover g-rule to `regulator of Subsurface Development Area 1`
  from an earlier department pick; its `department` is NULL. Test data, not a code bug.

## 3. Prod runbook

**Step 1: permission rows exist** (migration `20261014090000_SeedPhssPepPrivileges`, PR #1283):
```sql
SELECT id, permission_group_id, name FROM dbo.permissions WHERE id BETWEEN 153 AND 158;
-- expect 6 rows; missing = by-permission "Permission not found" and every write 403
```

**Step 2: find the roles prod users actually hold** (do not assume the `regulator of …` names):
```sql
SELECT u.department, r.id AS role_id, r.name AS casbin_role, COUNT(*) AS users
FROM dbo.users u
JOIN dbo.casbin_rule g ON g.ptype = 'g' AND g.v0 = CONCAT('user', u.id)
JOIN dbo.roles r       ON CONCAT('role', r.id) = g.v1 AND r.deleted_at IS NULL
WHERE u.deleted_at IS NULL
  AND (u.department IN ('Subsurface Development Area 1', 'Subsurface Development Area 2', 'Production Operations')
       OR r.name LIKE '%super%admin%' OR r.name LIKE '%Subsurface%')
GROUP BY u.department, r.id, r.name
ORDER BY u.department, users DESC;
```

**Step 3: grant those roles.** Additive and idempotent; a name with no match inserts nothing (check the row count):
```sql
SET XACT_ABORT ON;
BEGIN TRANSACTION;
INSERT INTO dbo.casbin_rule (ptype, v0, v1, v2)
SELECT 'p', CONCAT('role', r.id), CAST(p.permission_group_id AS nvarchar(20)), CAST(p.id AS nvarchar(20))
FROM (VALUES
    -- SDA 1 role(s): view + modify PHSS
    ('<prod SDA 1 role>', 137), ('<prod SDA 1 role>', 138), ('<prod SDA 1 role>', 139),
    ('<prod SDA 1 role>', 140), ('<prod SDA 1 role>', 153), ('<prod SDA 1 role>', 154),
    -- SDA 2 role(s): view + modify PEP
    ('<prod SDA 2 role>', 137), ('<prod SDA 2 role>', 138), ('<prod SDA 2 role>', 139),
    ('<prod SDA 2 role>', 140), ('<prod SDA 2 role>', 155), ('<prod SDA 2 role>', 156),
    -- Super Admin role(s): both
    ('<prod Super Admin role>', 153), ('<prod Super Admin role>', 154), ('<prod Super Admin role>', 155),
    ('<prod Super Admin role>', 156), ('<prod Super Admin role>', 157), ('<prod Super Admin role>', 158),
    -- PO role(s): view only; no 154/156, so writes stay 403
    ('<prod PO role>', 137), ('<prod PO role>', 140), ('<prod PO role>', 153), ('<prod PO role>', 155)
) v (role_name, perm_id)
JOIN dbo.roles r       ON r.name = v.role_name AND r.deleted_at IS NULL
JOIN dbo.permissions p ON p.id = v.perm_id AND p.deleted_at IS NULL
WHERE NOT EXISTS (SELECT 1 FROM dbo.casbin_rule c
                  WHERE c.ptype = 'p' AND c.v0 = CONCAT('role', r.id) AND c.v2 = CAST(p.id AS nvarchar(20)));
COMMIT TRANSACTION;
```

**Step 4: Retina holds the same privileges.** The R3 team inserts the ACL rows
(`PhantomRoles_6Roles.oracle.sql` / `retina_phss_pep_roles.oracle.sql`). Without them
`/users/permissions` lacks 154/156 and the FE hides the button although the backend allows the write.

**Step 5: verify** (nothing is written; the id does not exist):
```bash
curl -sS 'https://<prod-api>/api/v1/users/by-permission/154' -H 'Authorization: Bearer <prod admin token>'
curl -sS 'https://<prod-api>/api/v1/users/by-permission/156' -H 'Authorization: Bearer <prod admin token>'
curl -sS -X POST 'https://<prod-api>/api/v1/water-flood/wells/phss/00000000-0000-0000-0000-0000000000aa' \
  -H 'Authorization: Bearer <SDA 1 user token>'
# expect 404 "Injection well not found." (allowed). 403 = that user's role still lacks 154.
```

## 4. Dev self-check (full curls)

```bash
curl -sS 'https://phantom-api.inproms.com/api/v1/users/by-permission/154' \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer <TOKEN>.superadmin'

curl -sS 'https://phantom-api.inproms.com/api/v1/users/by-permission/156' \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer <TOKEN>.superadmin'
```

All four test users, reads + write probe:
```bash
BASE=https://phantom-api.inproms.com
RID=00000000-0000-0000-0000-0000000000aa
for u in r3test.sda1 r3test.sda2 r3test.po r3test.superadmin; do
  T=$(curl -sS -X POST "$BASE/api/v1/auth/login" -H 'Content-Type: application/json' \
      -d "{\"username\":\"$u\",\"password\":\"x\"}" | jq -r '.data.access_token')
  for wa in phss pep; do
    g=$(curl -sS -o /dev/null -w '%{http_code}' "$BASE/api/v1/water-flood/wells/$wa?page=1&page_size=1" -H "Authorization: Bearer $T")
    d=$(curl -sS -X POST "$BASE/api/v1/water-flood/wells/$wa/$RID" -H "Authorization: Bearer $T" -o /tmp/wf.json -w '%{http_code}')
    echo "$u $wa  GET=$g  WRITE=$d  $(jq -r '.message // empty' /tmp/wf.json)"
  done
done
```

## 5. Open decision

Steps 2–3 repeat per environment and drift whenever a user lands in a differently named role.
**Option 1 (recommended, not built):** make `EnsureCanWriteWorkingAreaAsync` check 154/156 in
`IRetinaAclCacheService.GetCurrentUserAclAsync()`, the source `/users/permissions` already uses. Then the
FE and the backend agree and only steps 1 and 4 remain. `/users/by-permission` would still read Casbin.
