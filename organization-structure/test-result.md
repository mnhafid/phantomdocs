# Test result — organization structure

| | |
|---|---|
| **Date** | 2026-10-12 |
| **Code** | worktree `.worktrees/org-structure`, branch `feat/org-structure` (from `phi-dev` @ `d9ed24be`), uncommitted |
| **Spec** | PRD.md (approved), FSD.md (§12 as-built notes), ADR-0008 |
| **Evidence** | `proof/` in the worktree: screenshots, HTML reports, masked JSON responses, `2026-10-12-full-suite.trx` |

## 1. Summary

| Check | Result |
|---|---|
| Build (`Tests/Tests.csproj`, all projects) | ✅ 0 errors |
| Full suite | 3251 tests — **3227 passed**, 21 failed, 3 skipped |
| Regressions vs clean base `d9ed24be` | ✅ **0** — the same 21 tests fail on the untouched base (verified in a clean worktree) |
| New tests | ✅ **46 / 46 passed** |
| Existing suites touched by the change | ✅ all passed (table §3) |
| Live API on dev DB | ✅ all checks in §4 returned the expected status and data, including after the drop migrations (§4.6) |
| Not tested | see §5 |

## 2. New tests (46)

| Class | Covers | Passed |
|---|---|---|
| `OrganizationStructureTests` | FR-001, FR-002, FR-003, FR-005, FR-008, FR-010 | 20/20 |
| `DepartmentPrivilegeTests` | FR-009 (t108), t100 | 4/4 |
| `WorkingAreaScopeTests` | FR-011 (t110) | 11/11 |
| `IntrospectCacheTests` | t102 | 6/6 |
| `ModuleAccessFilterTests` | t104 | 5/5 |

<details><summary>OrganizationStructureTests</summary>

- ✅ `Department_options_come_from_the_tree_with_their_division`
- ✅ `Department_outside_the_tree_keeps_only_the_department`
- ✅ `Department_resolves_to_its_full_path`
- ✅ `Division_under_zona_is_level_3`
- ✅ `Moving_a_department_under_a_zona_is_refused`
- ✅ `Only_one_company_root`
- ✅ `Picking_a_department_moves_the_division_with_it`
- ✅ `Renaming_a_department_with_users_is_refused`
- ✅ `Renaming_an_unused_department_is_allowed`
- ✅ `Retina_subfungsi_maps_to_master_department(subfungsi: "  projects ", expected: "Project")`
- ✅ `Retina_subfungsi_maps_to_master_department(subfungsi: "OSF", expected: "Operation & Surface Facilities")`
- ✅ `Retina_subfungsi_maps_to_master_department(subfungsi: "SUBSURFACE DEVELOPMENT AREA 1", expected: "Subsurface Development Area 1")`
- ✅ `Retina_subfungsi_maps_to_master_department(subfungsi: "Unknown Unit", expected: null)`
- ✅ `Senior_manager_changes_only_the_own_division`
- ✅ `Senior_manager_keeps_existing_departments_outside_the_tree`
- ✅ `Senior_manager_reads_every_division`
- ✅ `Subdivision_is_no_longer_accepted`
- ✅ `Unit_under_the_wrong_level_is_refused(type: "company")`
- ✅ `Unit_under_the_wrong_level_is_refused(type: "department")`
- ✅ `Unit_under_the_wrong_level_is_refused(type: "regional")`

</details>

<details><summary>DepartmentPrivilegeTests</summary>

- ✅ `After_a_pick_the_ACL_is_read_for_the_picked_department_role`
- ✅ `Picking_a_department_drops_the_cached_ACL`
- ✅ `Retina_without_an_ACL_for_the_picked_role_falls_back_to_discovery`
- ✅ `Without_a_picked_department_the_default_discovery_is_used`

</details>

<details><summary>WorkingAreaScopeTests</summary>

- ✅ `Bound_filter_naming_the_other_working_area_is_refused`
- ✅ `Department_without_a_working_area_sees_both`
- ✅ `Empty_working_area_on_a_bound_filter_is_narrowed_to_the_users_own`
- ✅ `PHSS_user_cannot_reach_PEP(path: "/api/v1/eur/highlight", query: "?type=eur_exceeded&working_area=PEP")`
- ✅ `PHSS_user_cannot_reach_PEP(path: "/api/v1/well-surveillance/wells/PEP/eur-monitoring"···, query: "")`
- ✅ `PHSS_user_cannot_reach_PEP(path: "/api/v1/wells/pep", query: "")`
- ✅ `PHSS_user_cannot_reach_PEP(path: "/api/v1/wells/pep/0a/alert", query: "")`
- ✅ `PHSS_user_reaches_PHSS_and_shared_routes(path: "/api/v1/eur/highlight", query: "?type=eur_exceeded&working_area=PHSS")`
- ✅ `PHSS_user_reaches_PHSS_and_shared_routes(path: "/api/v1/well-surveillance/wells/overview/card", query: "?time_range=1m")`
- ✅ `PHSS_user_reaches_PHSS_and_shared_routes(path: "/api/v1/wells/phss", query: "")`
- ✅ `Well_list_shows_only_the_users_working_area`

</details>

<details><summary>IntrospectCacheTests</summary>

- ✅ `Cached_answer_is_served_and_the_token_is_not_stored_in_clear`
- ✅ `Expired_token_is_not_cached`
- ✅ `Logout_removes_the_cached_answer`
- ✅ `Redis_down_is_a_miss_not_an_error`
- ✅ `Ttl_never_outlives_the_token`
- ✅ `Zero_ttl_turns_the_cache_off`

</details>

<details><summary>ModuleAccessFilterTests</summary>

- ✅ `Anonymous_cron_endpoint_is_never_gated`
- ✅ `Gate_is_off_by_default_flag`
- ✅ `SSDP_user_without_contract_privileges_gets_403`
- ✅ `Unavailable_ACL_fails_closed_with_503`
- ✅ `User_with_any_contract_privilege_passes`

</details>

## 3. Existing suites touched by the change

| Class | Why it matters | Passed |
|---|---|---|
| `RetinaAclCacheServiceTests` | ACL cache re-fetch (t108) | 23/23 |
| `UserRoleCacheInvalidationTests` | role assign/unassign invalidation (t100) | 7/7 |
| `RolePermissionCacheInvalidationTests` | role permission fan-out (t100) | 2/2 |
| `RoleIsRegulatorTests` | choose-department without user_scopes (t98) | 37/37 |
| `ContractSharesServiceTests` | known departments from users (t98) | 36/36 |
| `ContractsSpkSelectableTests` | department scope (t98) | 14/14 |
| `RbacLegacyRouteFilterTests` | legacy gate unchanged (t101) | 21/21 |
| `RbacRouteMapValidatorTests` | route-map boot validation (t101) | 9/9 |
| `AuthEndpointTests` | login/refresh/logout endpoint (t94, t102) | 20/20 |
| `AuthEndpointIntegrationTests` | auth endpoints end-to-end in test host | 19/19 |
| `CalendarsCacheTests` | shared Redis provider fail-fast (t102) | 24/24 |
| `MyTaskBadgeCacheTests` | shared Redis provider fail-fast (t102) | 13/13 |
| `WellSurveillanceServiceTests` | overview card working-area filter (t110) | 40/40 |

### Pre-existing failures (21, unchanged)

`ProjectRebaselineVersionSequenceTests` (8), `ContractSummaryValueMultiCurrencyTests` (3), `AlertDigestSourceTests` (2), `RksExportDocxTests` (2), `EmailTemplateTesterTests` (2), `ActionPlanOwnershipTests` (1), `ProjectTaskDetailEstimatedCostUsdTests` (1), `RunningHoursSmokeTest` (1), `WellHistoriesChartWellResolutionTests` (1) — all also fail on clean `d9ed24be`; none touch auth, users, organizations, permissions or wells scoping.

## 4. Live API on the shared dev DB

API from the worktree on `127.0.0.1:5072`, `Quartz__Enabled=false`, mock auth (`R3tinaConfig:UseMockAuthSessions`). Dev DB had migration `20261012064740_EnsureOrganizationsTable`, `seed_org_structure.sql` and `seed_org_test_users.sql` applied. Tokens redacted. indana restored to *Operation & Surface Facilities* (role 1108) after every run.

### 4.1 Login, profile, department (t94, t106, t107)

| Request | HTTP | department | division | zona / regional / company | position_name → position |
|---|---|---|---|---|---|
| `POST /api/v1/auth/login  (r3test.indana)` | 200 | — | **—** | — / — / — | MANAGER → SENIOR MANAGER |
| `POST /api/v1/auth/login  (r3test.sda1)` | 200 | Subsurface Development Area 1 | **SSDP** | Zona 9 / Regional 3 / PHE | STAFF → STAFF |
| `POST /api/v1/auth/login  (r3test.sda2)` | 200 | Subsurface Development Area 2 | **SSDP** | Zona 9 / Regional 3 / PHE | STAFF → STAFF |
| `POST /api/v1/auth/login  (r3test.po)` | 200 | Production Operations | **PnP** | Zona 9 / Regional 3 / PHE | STAFF → PROJECT OFFICER |
| `GET /api/v1/users/profile  (r3test.indana)` | 200 | — | **—** | — / — / — | MANAGER → SENIOR MANAGER |
| `GET /api/v1/users/profile  (r3test.sda1)` | 200 | Subsurface Development Area 1 | **SSDP** | Zona 9 / Regional 3 / PHE | STAFF → STAFF |
| `GET /api/v1/users/profile  (r3test.sda2)` | 200 | Subsurface Development Area 2 | **SSDP** | Zona 9 / Regional 3 / PHE | STAFF → STAFF |
| `GET /api/v1/users/profile  (r3test.po)` | 200 | Production Operations | **PnP** | Zona 9 / Regional 3 / PHE | STAFF → PROJECT OFFICER |
| `GET /api/v1/users/me/department/options  (r3test.indana)` | 200 | Operation & Surface Facilities→PnP, Production Operations→PnP, Project→PnP, Subsurface Development Area 1→SSDP, Subsurface Development Area 2→SSDP | | | |
| `POST /api/v1/users/me/department  (indana picks SDA 1)` | 200 | Subsurface Development Area 1 | **SSDP** | Zona 9 / Regional 3 / PHE | — |
| `POST /api/v1/users/me/department  (restore indana to OSF)` | 200 | Operation & Surface Facilities | **PnP** | Zona 9 / Regional 3 / PHE | — |

indana is a Senior Manager: login clears the department until one is picked (existing rule), so the tree fields are empty right after login. `r3test.po`'s mock rows pre-existed (raw POSNAME "PROJECT OFFICER").

### 4.2 Working area (t110)

| User | Request | HTTP | Result |
|---|---|---|---|
| r3test.sda1 | `GET /api/v1/wells/phss?page=1&page_size=1` | 200 | 1 |
| r3test.sda1 | `GET /api/v1/wells/pep?page=1&page_size=1` | 404 | None |
| r3test.sda2 | `GET /api/v1/wells/phss?page=1&page_size=1` | 404 | None |
| r3test.sda2 | `GET /api/v1/wells/pep?page=1&page_size=1` | 200 | 1 |
| r3test.po | `GET /api/v1/wells/phss?page=1&page_size=1` | 200 | 1 |
| r3test.po | `GET /api/v1/wells/pep?page=1&page_size=1` | 200 | 1 |
| r3test.sda1 | `GET /api/v1/wells/all` | 200 | 10320 |
| r3test.sda2 | `GET /api/v1/wells/all` | 200 | 21 |
| r3test.po | `GET /api/v1/wells/all` | 200 | 10344 |
| r3test.sda1 | `GET /api/v1/well-surveillance/wells/overview/card?time_range=1m` | 200 | active_wells=10067, anomalies=2, oil_production_gain=750000, oil_production_loss=0 |
| r3test.po | `GET /api/v1/well-surveillance/wells/overview/card?time_range=1m` | 200 | active_wells=10077, anomalies=2, oil_production_gain=750000, oil_production_loss=0 |

SDA 1 → PHSS only, SDA 2 → PEP only, PO → both. `/wells/all`: 10320 = PHSS wells, 21 = PEP wells, 10344 = all (3 have no working area) — matches the DB.

### 4.3 Privileges follow the picked department (t108, t100)

| Pick | Role | Division | Privileges | Groups |
|---|---|---|---|---|
| Production Operations | regulator of production operations | PnP | 136 | 21 groups |
| Subsurface Development Area 1 | regulator of Subsurface Development Area 1 | SSDP | **6** | 19, 20, 21 (EUR/Well/Compressor) |

Same session, no re-login. Retina here is the dev mock, which now serves a `"{user}|{role}"` session row for a named role.

### 4.4 Module gate (t104), flag `Permissions__ModuleGate__Enabled=true` for this run only

| State | Request | HTTP | Message |
|---|---|---|---|
| indana picked SDA 1 (EUR/Well only) | `/api/v1/contracts?page=1&page_size=1` | 403 | You do not have access to this module |
| indana picked SDA 1 (EUR/Well only) | `/api/v1/projects?page=1&page_size=1` | 403 | You do not have access to this module |
| indana picked SDA 1 (EUR/Well only) | `/api/v1/spks?page=1&page_size=1` | 403 | You do not have access to this module |
| indana picked SDA 1 (EUR/Well only) | `/api/v1/wells/phss?page=1&page_size=1` | 200 | Get well PHSS list succeed |
| indana back on OSF (full role) | `/api/v1/contracts?page=1&page_size=1` | 200 | Get contracts succeed |
| indana back on OSF (full role) | `/api/v1/projects?page=1&page_size=1` | 200 | Get projects succeed |

### 4.5 Department-name cleanup report (t111, read-only)

17 groups / 131 rows would be rewritten, e.g. projects "Operation & Surfaces Facilities" → "Operation & Surface Facilities" (68), tenders "Projects" → "Project" (25). Apply script: no-execute dry run only.

### 4.6 After the drop migrations (t98, t103)

Applied by the owner on the dev DB: `20261012085555_DropUserScopes`, `20261012085834_DropUsersDivision` (verified: both in `__EFMigrationsHistory`, `user_scopes` and `users.division` gone; cleanup apply still not run). Worktree API re-run against the migrated DB:

| Check | User | HTTP | Result |
|---|---|---|---|
| login | r3test.indana | 200 | dept=None div=None |
| login | r3test.sda1 | 200 | dept=Subsurface Development Area 1 div=SSDP |
| login | r3test.sda2 | 200 | dept=Subsurface Development Area 2 div=SSDP |
| login | r3test.po | 200 | dept=Production Operations div=PnP |
| profile | r3test.sda1 | 200 | dept=Subsurface Development Area 1 div=SSDP zona=Zona 9 |
| profile | r3test.po | 200 | dept=Production Operations div=PnP zona=Zona 9 |
| sda1 -> PEP wells | r3test.sda1 | 404 | expect 404 |
| sda1 -> PHSS wells | r3test.sda1 | 200 | expect 200 |
| po -> contracts (dept scope, no user_scopes) | r3test.po | 200 | Get contracts succeed |
| indana pick SDA 1 | r3test.indana | 200 | SSDP |
| indana permissions after pick | r3test.indana | 200 | 6 |
| restore indana | r3test.indana | 200 | PnP |

API log: **0** `Invalid object name 'user_scopes'` / `Invalid column name 'division'` errors. Proof: `proof/live5-post-migration.json`.

## 5. Not tested

| Item                                                  | Status                                                                                              |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| t109 write/approval on another division's record      | not tried live; only the read scope (helper unit tests + GET live)                                  |
| t102 introspect cache with Redis reachable            | local Redis was unreachable — only the fallback path (live Introspect) ran; cache logic unit-tested |
| t100 invalidation on logout and on role update/delete | no test; logout endpoint is a no-op in the API                                                      |
| cleanup apply script (t111)                           | no-execute dry run only                                                                             |
| 10-commit split                                       | each commit not built on its own — only the full set                                                |
| Frontend                                              | not tested against the web app                                                                      |

---

## Scenario run 2026-10-13 (rebased stack)

**Code:** `org/4-cleanup` @ `b55fb750` (stack PRs #1270 → #1271 → #1273 → #1274, rebased on `phi-dev`
@ `980e0874`). **Scenarios:** `test-scenarios.md` (written before this run).
**API:** worktree API on `127.0.0.1:5072`, Quartz off, shared dev DB, mock Retina —
`proof/retest.sh` → `retest-curl-2026-10-13.md` (full request + response per call, case `#` below).
**Unit:** 7 classes → `proof/scenario-unit-2026-10-13.trx`. **Full suite:** `proof/full-suite-2026-10-13.trx`.

**Result: 30/30 scenarios PASS** — API 38/38 calls, unit 94/94 tests, build 0 errors, full suite
3287 tests: 3263 passed, 21 failed, 3 skipped. The 21 failures are the same tests, by name, as the
pre-feature baseline (`testresults/full.trx`, `testresults2/full.trx`): **0 regressions**.

| ID | Scenario | Evidence | Actual | Result |
|---|---|---|---|---|
| TS-01 | SDA 1 login → own department + tree | curl #1 | SDA 1 / SSDP / Zona 9 / Regional 3 / PHE, STAFF | PASS |
| TS-02 | SDA 2 login | curl #2 | Subsurface Development Area 2 / SSDP | PASS |
| TS-03 | PO login | curl #3 | Production Operations / PnP | PASS |
| TS-04 | Profile has organisation block | curl #8 | SSDP / Zona 9 / Regional 3 / PHE | PASS |
| TS-05 | Refresh keeps department + organisation | curl #38 | SDA 1 / SSDP | PASS |
| TS-06 | Senior Manager PnP login → `""` | curl #5 | `department: ""`, organisation empty | PASS |
| TS-07 | Senior Manager SSDP login → `""` | curl #4 | `""` | PASS |
| TS-08 | General Manager login → `""` | curl #7 | `""` | PASS |
| TS-09 | SuperAdmin (SysRole) login → `""` | curl #6 | `""` (POSNAME STAFF) | PASS |
| TS-10 | Whitelist rules | `DepartmentPickerWhitelistTests` 10, `RoleIsRegulatorTests` 38 | 48/48 | PASS |
| TS-11 | Department options from the tree | curl #25 | 5 departments with division | PASS |
| TS-12 | Pick SDA 1 → role + division + profile | curl #26, #27 | role 1114, SSDP; profile SDA 1 | PASS |
| TS-13 | Privileges follow pick (no re-login) | curl #33 → #35 | 136 → 6 (groups 19/20/21 only) | PASS |
| TS-14 | Pick back OSF → full set | curl #36 → #37 | 136 | PASS |
| TS-15 | SDA 1 PHSS wells + EUR | curl #17, #23 | 200, 200 | PASS |
| TS-16 | SDA 1 PEP hidden | curl #18, #24 | 404, 404 | PASS |
| TS-17 | SDA 2 PEP only | curl #19, #20 | PEP 200, PHSS 404 | PASS |
| TS-18 | PO sees both | curl #21, #22 | 200, 200 | PASS |
| TS-19 | Senior Manager working area follows pick | curl #28, #29, #30, #31 | SDA 1: PHSS 200 / PEP 404; SDA 2: PEP 200 | PASS |
| TS-20 | Working-area guard + filters | `WorkingAreaScopeTests` | 11/11 | PASS |
| TS-21 | Module gate | `ModuleAccessFilterTests` | 5/5 | PASS |
| TS-22 | Permissions for every test user | curl #9–#15 | 200, non-empty (PO: 3, others: 136) | PASS |
| TS-23 | Permissions without token | curl #16 | 401 | PASS |
| TS-24 | Picked-role ACL + cache invalidation | `DepartmentPrivilegeTests` | 4/4 | PASS |
| TS-25 | Tree level rules | `OrganizationStructureTests` | 20/20 (whole class) | PASS |
| TS-26 | Rename lock | `OrganizationStructureTests` | incl. above | PASS |
| TS-27 | Retina SUBFUNGSI mapping / unmapped | `OrganizationStructureTests` | incl. above | PASS |
| TS-28 | Senior Manager read-all / write-own | `OrganizationStructureTests` | incl. above | PASS |
| TS-29 | Introspect cache + Redis down | `IntrospectCacheTests` | 6/6 | PASS |
| TS-30 | Cleanup without drop | build + full suite + grep | build OK; 0 regressions; no code reads/writes `user_scopes` / `users.division`; no drop migration in the stack | PASS |

**Notes**
- State left on dev: `r3test.sm.ssdp` back on SDA 2; `r3test.indana` back on Operation & Surface
  Facilities (role 1108) — same as before the run.
- TS-22: SDA 1 and SDA 2 get the same 136 privileges from the mock Retina; PO gets 3 (no Well privilege).
  The PHSS/PEP split is enforced by department (TS-15..19), not by privilege — privileges 153–156 need
  `seed_rbac_phss_pep_privileges.sql` + Retina rows (not done).
- Not covered: US-02, US-04, US-05, US-10 (see `test-scenarios.md`).

---

## Dev staging run 2026-10-13

**Target:** deployed dev API `https://phantom-api.inproms.com`, build `v1.4.0+20261013.001` (includes the merged stack
#1270–#1274), mock Retina, shared dev DB. Same curl scenarios as above (`proof/retest.sh`) →
`retest-curl-dev-2026-10-13.md` (full request + response per call).

**Result: 38/38 calls PASS** — API scenarios TS-01..TS-09, TS-11..TS-19, TS-22, TS-23 all PASS on dev
(same case numbers as the local run). Highlights: Senior Manager / General Manager / SuperAdmin login
→ `department: ""`; SDA 1 PHSS 200 / PEP 404, SDA 2 the reverse, PO both; indana privileges 136 → 6
→ 136 on department pick. Test users restored (`r3test.sm.ssdp` SDA 2, indana OSF).
Unit scenarios (TS-10, TS-20, TS-21, TS-24..TS-29) are code-level and were run locally (94/94).

### `/users/permissions` vs mock ACL (2026-10-13)

Compared every dev `/users/permissions` response with the ACL in `mock_auth_sessions` (stage `session`):
all 10 matched "ACL Seqs that have a `permissions` row", with the right group id. But Seqs **139,
145–152** were dropped — the endpoint maps Seq → group through `dbo.permissions`, and those rows were
missing. **Fixed on dev 2026-10-13:** inserted the 9 rows (names/groups from the RBAC sheet; same values as
`seed_rbac_phss_pep_privileges.sql`). Re-check: SDA 1 now gets 145/145 ACL privileges (was 136).
Not yet applied from that seed: privileges 153–156 and the casbin role rules.

---

## New-permission run 2026-10-15 (TS-31..TS-37, FE-guard decision)

**Decision recorded:** PHSS / PEP privileges are guarded on the frontend from `/users/permissions`;
backend route enforcement deferred (`rbac-route-enforcement-plan.md`). So these tests check the ids
each role gets, not 403s.

**Data applied on dev (shared phantomdb):**
- Migration twin `20261014090000_SeedPhssPepPrivileges.sql` → group 26, privileges 153–158, history row.
- Mock Retina (`mock_auth_sessions`, stage `session`, dev test users only): r3test.sda1 / sda2 / po ACL =
  the SDA 1 / SDA 2 / PO role sets; superadmin ACL + 153–158; `r3test.indana|regulator of …` rows for
  SDA 1 (updated), SDA 2 and PO (new). SYSROLE of sda1/sda2/po kept "Team Member General" so login does not
  re-assign their Phantom role. Backups: session scratchpad `mock_backup_20261015/` (rollback = UPDATE back).
- Not applied: `seed_rbac_phss_pep_privileges.sql` (Phantom casbin grants — not read by `/users/permissions`).

**Target:** deployed dev API `v1.4.0+20261014.001`, `proof/retest.sh` → `retest-curl-dev-2026-10-15.md`.

**Result: 46/46 API calls PASS + TS-31 DB checks PASS.**

| ID | Check | Result |
|---|---|---|
| TS-31 | 153–156 in group 19, 157/158 in group 26; second run of the migration SQL inserts 0 rows; no duplicate ids; one history row | PASS |
| TS-32 | SDA 1 `/users/permissions` = exactly 137 138 139 140 153 154; 153/154 → "19", 138/140 → "20" | PASS |
| TS-33 | SDA 2 = exactly 137 138 139 140 155 156 | PASS |
| TS-34 | PO = exactly 137 140 153 155 (no Modify id) | PASS |
| TS-35 | indana picks SDA 1 → SDA 1 set; SDA 2 → SDA 2 set; PO → PO set; OSF → back to the full default set | PASS |
| TS-36 | SuperAdmin contains 153–158; 157/158 → "26" | PASS |
| TS-37 | Regression TS-01..TS-29 API cases (login `""` whitelist, org block, working-area guard 404, picks, refresh) | PASS |

Notes: the dev DB also holds migration `20261014024902_AddWaterFloodInjectionWells` from an unmerged branch —
whichever of the two branches merges second must regenerate its Designer if the model changed.
