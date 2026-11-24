# RBAC privileges to separate SDA 1 (PHSS) and SDA 2 (PEP)

| | |
|---|---|
| **Date** | 2026-10-12 |
| **Source** | Google Sheet "Phantom PHI Mapping" (`1HHv1QMmyZ917KGBdW6iMKMSJ9n9fvL_IS6D7ldhGSD8`) |
| **Status** | **In the sheet**, `:type` routes split (2026-10-12, see `rbac-sheet-change-log.md`); not yet in the dev DB `permissions` table or Retina |

## Why

Today PHSS and PEP wells share one set of privileges in group **19 Well Monitoring** (137 read, 139
modify) and group **20 Well Monitoring EUR** (138 upload, 140 read/export). A role can therefore not say
"modify PHSS but not PEP". SDA 1 must work on PHSS only and SDA 2 on PEP only (PRD Q11).

The highest ID in the sheet is **152** (RKS Master Clause), so the new IDs start at **153**.

## New privileges

| ID | Group | Name | Category |
|---|---|---|---|
| **153** | 19 Well Monitoring | Read PHSS Wells | View |
| **154** | 19 Well Monitoring | Modify PHSS Wells | Modify |
| **155** | 19 Well Monitoring | Read PEP Wells | View |
| **156** | 19 Well Monitoring | Modify PEP Wells | Modify |

137 / 139 stay for the routes that are shared by both working areas.

## Route mapping (sheet rows that change)

| Method | URL | Today | New |
|---|---|---|---|
| GET | /well-surveillance/wells/phss/overview | 137 | **153** |
| GET | /well-surveillance/wells/phss | 137 | **153** |
| GET | /well-surveillance/wells/phss/eur-monitoring | 137 | **153** |
| GET | /well-surveillance/wells/phss/:well_id/eur-monitoring/detail | 137 | **153** |
| GET | /well-surveilence/:wellId/action-plans/phss | 137 | **153** |
| GET | /well-surveilence/:wellId/action-plans/phss/mine | 137 | **153** |
| GET | /well-surveilence/action-plans/phss/:id | 137 | **153** |
| POST | /well-surveilence/action-plans/phss/draft | 139 | **154** |
| POST (sheet: PUT) | /well-surveilence/action-plans/phss/draft/:id | 137 ⚠ | **154** (the sheet has 137 here — a write tagged as read) |
| POST | /well-surveilence/action-plans/phss/submit | 139 | **154** |
| GET | /wells/phss, /wells/phss/:wellId, /wells/phss/histories, /wells/phss/export, /wells/phss/template | 137 | **153** |
| POST | /wells/phss | 139 | **154** |
| POST | /wells/phss/:well_id/gas-lift-inputs | 139 | **154** |
| POST | /wells/phss/:well_id/zones/:well_zone_id/import | 139 | **154** |
| GET | /well-surveillance/wells/pep/overview | 137 | **155** |
| GET | /well-surveillance/wells/pep/eur-monitoring | 137 | **155** |
| GET | /well-surveillance/wells/pep/:well_id/eur-monitoring/detail | 137 | **155** |
| GET | /well-surveilence/:wellId/action-plans/pep, …/pep/mine, /well-surveilence/action-plans/pep/:id | 137 | **155** |
| POST | /well-surveilence/action-plans/pep/draft, …/pep/draft/:id, …/pep/submit | 139 | **156** |
| GET | /wells/pep, /wells/pep/:wellId, /wells/pep/histories, /wells/pep/export, /wells/pep/template | 137 | **155** |
| POST | /wells/pep | 139 | **156** |
| POST | /wells/pep/import | 139 | **156** |

**`:type` routes split into PHSS + PEP rows (sheet, 2026-10-12)** — each old `:type` row is now
two rows with a literal `phss` / `pep` segment, so a static route map can express them:

| Route (`phss` row / `pep` row) | GET | POST |
|---|---|---|
| /well-surveillance/wells/{phss\|pep}/eur-monitoring/:well_id/tubing-casing | 153 / 155 | 154 / 156 |
| /well-surveillance/wells/{phss\|pep}/eur-monitoring/:well_id (update) | | 154 / 156 |
| /well-surveillance/wells/{phss\|pep}/:well_id/decline, /panel, /schematic | 153 / 155 | |
| /wells/{phss\|pep}/histories/chart, /wells/{phss\|pep}/validate-id | 153 / 155 | |

Not in the sheet but in code (still need rows): `/wells/{type}/histories/chart/mtu`, `/rtws`,
`/sonolog`; `/wells/{workingarea}/{well_detail_id}/alert`; `/wells/{workingarea}/{well_id}/choke-update-info`.

**Unchanged (shared):** overview card, `dropdowns/:type`, `/wells/all`,
`/well-zones/autocomplete`, well-zone-assignments, action-plan calendar (highlight / upcoming /
event) → 137 / 139; EUR upload, import by field, export, template, cardview → 138 / 140.

## Role matrix

| Privilege | SDA 1 | SDA 2 | PO (view) |
|---|---|---|---|
| 137 Read Well Monitoring (shared) | ✓ | ✓ | ✓ |
| 139 Modify shared well data | ✓ | ✓ | |
| 153 Read PHSS Wells | ✓ | | ✓ |
| 154 Modify PHSS Wells | ✓ | | |
| 155 Read PEP Wells | | ✓ | ✓ |
| 156 Modify PEP Wells | | ✓ | |
| 138 Upload EUR data | ✓ | ✓ | |
| 140 Read / export EUR | ✓ | ✓ | ✓ |

## SQL for the `permissions` table (not applied)

`permissions.id` is not an identity column, so the IDs are set explicitly. Idempotent, DBeaver-safe.

```sql
INSERT INTO dbo.permissions (id, permission_group_id, name, description, created_at, updated_at)
SELECT v.id, 19, v.name, v.description, GETDATE(), GETDATE()
FROM (VALUES
    (153, 'Read PHSS Wells',   'View PHSS wells, EUR monitoring and action plans'),
    (154, 'Modify PHSS Wells', 'Create / update / import PHSS wells and PHSS action plans'),
    (155, 'Read PEP Wells',    'View PEP wells, EUR monitoring and action plans'),
    (156, 'Modify PEP Wells',  'Create / update / import PEP wells and PEP action plans')
) v (id, name, description)
WHERE NOT EXISTS (SELECT 1 FROM dbo.permissions p WHERE p.id = v.id);
```

## Gaps found while reading

- **Re-read 2026-10-12:** the sheet now marks the update routes as **PUT** (EUR monitoring update,
  action-plan draft update, well data, gas-lift inputs, compressor/planning updates, OE recommendation,
  RKS updates) and deletes as **DELETE**. The .NET routes are **all POST** (no `MapPut` / `MapDelete` in
  these endpoints). Keep the sheet's method column matching the .NET code, or a per-route RBAC map built
  from it will not find these routes. IDs are unchanged; 153–156 are not in the sheet yet.

- The dev DB `permissions` table stops at **144** and has no **139, 143, 145–152** although the sheet uses
  them (139 = Modify well data, 145–152 = OE / RKS). Roles cannot be granted privileges that are not in
  the table.
- Sheet row "Update PHSS Action Plan Draft" (POST) carries **137**, a read privilege; the PEP twin uses 139.

## Enforcement (what is and is not wired)

- **Working area** is already enforced by department (FR-011, t110): SDA 1 cannot reach PEP at all.
- These privileges make the split visible in roles and Retina (`/users/permissions`, frontend menus).
- Backend enforcement per privilege needs the per-route RBAC map (future step of t104); the `:type`
  routes need a request-time check (`phss` → 153/154, `pep` → 155/156).

## Seed script (2026-10-12)

`src-be/DataAccess/Database/seed_rbac_phss_pep_privileges.sql` (worktree org-structure), **not yet run**:
- inserts permissions 139, 145–156 (143 skipped: no route uses it); names from the sheet;
- casbin p-rules: role1 → 153–156; role1114 (regulator SDA 1) → 139, 140, 153, 154;
  role1115 (regulator SDA 2) → 139, 140, 155, 156; role1105 (regulator PO) → 140, 153, 155;
- Retina `R3TINA.ACL` inserts as comments, for the R3 team; runtime privileges come from Retina.

Found on dev: casbin rules already reference 145–152 with no `permissions` rows; 137 is named
"Manage Subscription" and 138/140 have NULL names (left as is). Test user `R3TEST.PO` has role 1102
(Production Operations), which holds no well privileges; the department-pick role is 1105.

## Decision 2026-10-15 — FE guard now, backend enforcement later

The owner decided: privileges 153–158 are guarded on the frontend (FE reads `/users/permissions`).
Backend route enforcement (`RbacRouteMaps` + `RbacLegacyRouteFilter`) is deferred; see
`rbac-route-enforcement-plan.md`. Backend protection today: login + department working-area guard (404).
Consequence: `/users/permissions` must return the right ids per role — that is what the tests check.

## Water flood write check (2026-10-20)

The water-flood write endpoints check 154 / 156 in **Phantom Casbin**, not the Retina ACL the FE reads.
Dev findings, the grants made, and the prod runbook: [water-flood-write-permission.md](water-flood-write-permission.md).
