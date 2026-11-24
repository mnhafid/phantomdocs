# Test scenarios — organization structure

| | |
|---|---|
| **Feature** | Organization structure (Company → Regional → Zona → Division → Department), ADR-0008 |
| **Source** | PRD.md (US-01..US-14), FSD.md |
| **Code** | gh stack `org/1-tree` … `org/4-cleanup` (PRs #1270, #1271, #1273, #1274) |
| **Written** | 2026-10-13, before the run. Results: `test-result.md` → "Scenario run 2026-10-13" |

**How:** *API* scenarios run with curl (`proof/retest.sh`) against the stack's API on the shared dev DB
(mock Retina login, any password). *Unit* scenarios run the named xUnit classes (in-memory EF).

**Test users (dev):** `r3test.sda1` (SDA 1, STAFF), `r3test.sda2` (SDA 2, STAFF), `r3test.po`
(Production Operations), `r3test.sm.ssdp` / `r3test.sm.pnp` / `r3test.indana` (SENIOR MANAGER),
`r3test.gm` (GENERAL MANAGER), `r3test.superadmin` (SysRole SuperAdmin).

## A. Login, profile, refresh — US-06, US-11

| ID | Given | When | Then | How |
|---|---|---|---|---|
| TS-01 | SDA 1 staff (SUBFUNGSI = SDA 1) | `POST /auth/login` | 200; `department` = "Subsurface Development Area 1"; organisation = SSDP / Zona 9 / Regional 3 / PHE; `position` = STAFF | API |
| TS-02 | SDA 2 staff | login | 200; `department` = "Subsurface Development Area 2"; division SSDP | API |
| TS-03 | PO staff | login | 200; `department` = "Production Operations"; division PnP | API |
| TS-04 | SDA 1 logged in | `GET /users/profile` | 200; organisation block = SSDP / Zona 9 / Regional 3 / PHE | API |
| TS-05 | SDA 1 logged in | `POST /auth/refresh` | 200; same department and organisation as login | API |

## B. Department picker whitelist — US-12

| ID | Given | When | Then | How |
|---|---|---|---|---|
| TS-06 | Senior Manager PnP (POSNAME "SENIOR MANAGER") | login | `department` = `""`, organisation empty → frontend shows the picker | API |
| TS-07 | Senior Manager SSDP | login | `department` = `""` | API |
| TS-08 | General Manager | login | `department` = `""` | API |
| TS-09 | SuperAdmin (SysRole) with POSNAME STAFF | login | `department` = `""` | API |
| TS-10 | Whitelist rules | POSNAME / SysRole variants (plain MANAGER, regulator SysRole, null) | only Senior Manager, General Manager, SuperAdmin pick; everyone else keeps SUBFUNGSI | Unit: `DepartmentPickerWhitelistTests`, `RoleIsRegulatorTests` |

## C. Choosing a department — US-12, US-13

| ID | Given | When | Then | How |
|---|---|---|---|---|
| TS-11 | Senior Manager SSDP logged in | `GET /users/me/department/options` | 200; the 5 tree departments with their division | API |
| TS-12 | Senior Manager SSDP | `POST /users/me/department` "Subsurface Development Area 1" | 200; role 1114 "regulator of Subsurface Development Area 1"; organisation division SSDP; profile shows SDA 1 | API |
| TS-13 | indana (Senior Manager) with 136 privileges | picks SDA 1, then `GET /users/permissions` | fewer privileges, only groups 19/20/21 (Well, EUR, Compressor), without logging in again | API |
| TS-14 | indana picked SDA 1 | picks Operation & Surface Facilities, then `GET /users/permissions` | back to the full set (136) | API |

## D. Working area — US-14

| ID | Given | When | Then | How |
|---|---|---|---|---|
| TS-15 | SDA 1 | `GET /wells/phss`, `/well-surveillance/wells/phss/eur-monitoring` | 200 | API |
| TS-16 | SDA 1 | `GET /wells/pep`, `/well-surveillance/wells/pep/eur-monitoring` | 404 (PEP hidden) | API |
| TS-17 | SDA 2 | `GET /wells/pep` / `/wells/phss` | 200 / 404 | API |
| TS-18 | PO | `GET /wells/phss` and `/wells/pep` | 200 and 200 | API |
| TS-19 | Senior Manager picked SDA 1, then SDA 2 | `GET /wells/phss`, `/wells/pep` | after SDA 1: PHSS 200, PEP 404; after SDA 2: PEP 200 | API |
| TS-20 | Working-area guard and filters | request for the other working area; bound filters | refused / narrowed | Unit: `WorkingAreaScopeTests` |
| TS-21 | Module gate ON, user without a module's privilege group | call Contracts / SPK / Projects … | 403; module gate OFF → no change | Unit: `ModuleAccessFilterTests` |

## E. Privileges endpoint — US-13

| ID | Given | When | Then | How |
|---|---|---|---|---|
| TS-22 | Each of the 7 test users | `GET /users/permissions` | 200; non-empty `{privilege id: [group id]}` map | API |
| TS-23 | No token | `GET /users/permissions` | 401 | API |
| TS-24 | Picked department role | ACL read for "regulator of {dept}", cache cleared on pick / logout / role edit | privileges come from the picked role | Unit: `DepartmentPrivilegeTests` |

## F. Organization tree and Retina mapping — US-01, US-03, US-07, US-08, US-09

| ID | Given | When | Then | How |
|---|---|---|---|---|
| TS-25 | Admin edits the tree | add Division under Zona; unit under the wrong level; 2nd company root; Subdivision | accepted; refused; refused; refused | Unit: `OrganizationStructureTests` |
| TS-26 | Department with users | rename it | refused (409, `OrganizationInUseException`); unused department → rename allowed | Unit: `OrganizationStructureTests` |
| TS-27 | Retina SUBFUNGSI variants ("PROJECTS", unmapped) | map at login | mapped to the master department; unmapped keeps the raw value (login still works) | Unit: `OrganizationStructureTests` |
| TS-28 | Senior Manager of a division | read vs write department set | read = every department; write = only own division's departments | Unit: `OrganizationStructureTests` |

## G. Platform — NFR

| ID | Given | When | Then | How |
|---|---|---|---|---|
| TS-29 | Introspect answer cached | repeat calls; Redis down | served from cache; Redis down → no wait, falls back to Retina | Unit: `IntrospectCacheTests` |
| TS-30 | Layer 4 cleanup | build + full suite | no code reads/writes `user_scopes` / `users.division`; table and column stay (no drop migration) | Review + grep (see `COMMIT-PLAN.md`) |

## Not covered here

- US-02 tree screen, US-04 OpenObserve warning lines (manual check in OpenObserve), US-05 department-name
  cleanup (report script only; apply script not run), US-10 moving a department between divisions.
- PHSS/PEP privileges 153–156: seed script not run, Retina rows not created — privileges cannot tell SDA 1
  and SDA 2 apart yet (TS-15..19 are enforced by department, not by privilege).

## H. New PHSS / PEP privileges (153–158) — FE guard, added 2026-10-15

Decision 2026-10-15: the frontend guards PHSS / PEP from `GET /api/v1/users/permissions`; backend route
enforcement is deferred. So these scenarios check the **privilege ids each role receives**, not 403s.
Expected sets (Retina SYSROLE = Phantom role name, `retina_phss_pep_roles.oracle.sql`):

| Role | Must contain | Must NOT contain |
|---|---|---|
| SDA 1 (`regulator of Subsurface Development Area 1`) | 137 140 153 139 138 154 | 155 156 |
| SDA 2 (`regulator of Subsurface Development Area 2`) | 137 140 155 139 138 156 | 153 154 |
| PO (`regulator of production operations`) | 137 140 153 155 | 138 139 154 156 |

| ID | Given | When | Then | How |
|---|---|---|---|---|
| TS-31 | Migration `20261014090000_SeedPhssPepPrivileges` applied | read `permissions` / `permission_groups` | 153–156 in group 19, 157/158 in group 26 "Unit Conversion"; re-running inserts nothing | DB |
| TS-32 | SDA 1 user (Retina role SDA 1) | `GET /users/permissions` | exactly the SDA 1 set; each id mapped to its group (153/154 → "19", 138/140 → "20") | API |
| TS-33 | SDA 2 user | `GET /users/permissions` | exactly the SDA 2 set | API |
| TS-34 | PO user | `GET /users/permissions` | exactly the PO set — no Modify id | API |
| TS-35 | Senior Manager (indana) | picks SDA 1, then SDA 2, then PO, then OSF | privileges switch to the SDA 1 / SDA 2 / PO set on each pick, without login; OSF → back to the default role | API |
| TS-36 | SuperAdmin | `GET /users/permissions` | contains 153–158; 157/158 mapped to group "26" | API |
| TS-37 | Regression | TS-01..TS-29 | still PASS (working-area guard unchanged: SDA 1 → 404 on PEP URLs) | API + unit |

Test data on dev (mock Retina, `mock_auth_sessions` stage `session`): r3test.sda1 / sda2 / po get the
role ACL above; rows `r3test.indana|<role>` exist for the three roles; superadmin's ACL gains 153–158.
