# FSD: Organization Structure (Company → Regional → Zona → Division → Department)

| | |
|---|---|
| **Status** | Draft |
| **Related PRD** | PRD.md (approved 2026-10-12) · ADR-0008 (`.claude/docs/adr/0008-organization-structure-department-anchored/`) |
| **Date** | 2026-10-12 |
| **Version** | 0.1 |
| **Bruno** | `bruno/collections/phi-phantom/Organization Structure/`, `.../SSDP/Auth/` |

## 1. System Overview

```
Retina login ──► userInformation.SUBFUNGSI ──► mapping (custom_configurations) ──► Department name
                                                                                       │
users.department / records.department_id  ◄── stored name ─────────────────────────────┘
                                                                                       │
organizations tree ──► walk up ──► Division ─► Zona ─► Regional ─► Company ──► "organisation" block
                                                                    (login, refresh, profile, choose-department)
Picked Department ──► its role ──► Retina ACL re-read ──► /users/permissions + route checks
Department ──► working area (PHSS/PEP) ──► EUR/Well data filter
```

## 2. Scope

**In:** the five-level tree on the existing organizations endpoints; the Retina department
mapping and department working-area mapping in custom configuration; login placement by
SUBFUNGSI; the `organisation` block and raw `position` in login, refresh, profile and the
department endpoints; privileges following the picked department; Senior Manager GET-only
outside the own division; working-area hiding on EUR/Well; the drifted-name cleanup; dev seed.

**Out (PRD non-goals and separate tickets):** new endpoints; tree sync from Retina; multi-company;
more than one division per Senior Manager; approval-route changes; backend enforcement for every
module (t104); dropping `user_scopes` (t98) and `users.division`/`users.zone` (t103).

## 3. User Flows

**UF-1 Staff login (US-06, US-07, US-11).** 1) User posts credentials. 2) Retina returns
`userInformation`. 3) SUBFUNGSI is looked up in the mapping → Department name. 4) `users.department`
is set. 5) The tree gives Division, Zona, Regional, Company. 6) The response carries the
`organisation` block, `position_name` and `position`. *Variation:* no mapping and no tree match →
UF-1 still succeeds with the raw department and null tree fields; a Warning is logged.

**UF-2 Senior Manager picks a department (US-12, US-13).** 1) Login as UF-1 (a Senior Manager's
department is cleared as today). 2) `GET /users/me/department/options` lists tree departments
with their division. 3) `POST /users/me/department`. 4) Department, role and division change.
5) The cached ACL is dropped and re-read for the department's role. 6) The next
`/users/permissions` returns the new privileges — no re-login.

**UF-3 Senior Manager reads another division (US-09).** GET on a record of a department outside
the own division → 200. Any other method → 403.

**UF-4 SSDP user (US-14).** Login → only EUR/Well privileges → frontend shows only those modules.
EUR/Well lists show only wells of the department's working area.

**UF-5 Admin maintains the tree and mapping (US-01–US-04).** Existing `/organizations` and
`/custom-configurations` screens; unmatched values are found in OpenObserve.

## 4. Functional Requirements

### FR-001: Five-level tree
- **Traces to:** G1 / US-01, US-02
- **Priority:** Must
- **Description:** The system shall accept organization units of type `company`, `regional`,
  `zona`, `division`, `department`, and only under a parent of the level directly above.
- **Behavior:**

  | type | allowed parent type | level |
  |---|---|---|
  | company | none (root) | 0 |
  | regional | company | 1 |
  | zona | regional | 2 |
  | division | zona | 3 |
  | department | division | 4 |

  `subdivision` is no longer accepted for new units; existing ones are left untouched.
- **Validation & Errors:** wrong parent type → 400 `"A <type> must be placed under a <parent type>"`;
  unknown type → 400 (existing message); second company root → 400.
- **Acceptance criteria:**
  - Given Zona 9 exists, When an Admin creates division "PnP" under it, Then 201 and level 3.
  - Given Zona 9 exists, When an Admin creates a department directly under it, Then 400.

### FR-002: Used Department names are locked
- **Traces to:** G1 / US-01, Q8
- **Priority:** Must
- **Description:** The system shall refuse to rename a department while any user or any record
  (projects, contracts, SPKs, invoices, service acceptances, tenders, approval routes, material
  monitoring, contract shares) refers to its name.
- **Validation & Errors:** 409 `"Department '<name>' is in use and cannot be renamed; create a new department and move the records"`.
- **Edge cases:** an unused department can be renamed; moving a department to another division
  is allowed (records reference the name, not the parent).
- **Acceptance criteria:**
  - Given "Project" is on 179 projects, When an Admin renames it, Then 409 and nothing changes.
  - Given a new department with no users or records, When renamed, Then 200.

### FR-003: Retina department mapping
- **Traces to:** G2, G3 / US-03
- **Priority:** Must
- **Description:** The system shall read custom configuration `organization.retina_department_mapping`
  (`detail` = `[{key, value, note}]`), where `key` is a Retina SUBFUNGSI value and `value` the
  master Department name. Matching is case-insensitive and ignores surrounding spaces.
- **Behavior:** changes take effect at the user's next login; no deployment.
- **Seed:** `Project`←"Project","Projects"; `Production Operations`←"Production Operations","PO";
  `Operation & Surface Facilities`←"Operation & Surface Facilities","Operation & Surfaces Facilities","OSF";
  `Subsurface Development Area 1`←"SUBSURFACE DEVELOPMENT AREA 1"; `Subsurface Development Area 2`←"SUBSURFACE DEVELOPMENT AREA 2".
- **Acceptance criteria:**
  - Given the seed, When SUBFUNGSI is "projects", Then the department is "Project".

### FR-004: Login placement by SUBFUNGSI
- **Traces to:** G2, G5 / US-06, US-07
- **Priority:** Must
- **Description:** At login the system shall set `users.department` from
  `userInformation.SUBFUNGSI` through FR-003 and shall not use FUNGSI for placement.
- **Behavior:** source order `userInformation.SUBFUNGSI` → top-level `subfunc` → session
  `userInformation.SubFungsi`. Mapping hit → master name. Miss → today's behavior (display-name
  config, else raw value) and a Warning `"Org mapping: unmatched SUBFUNGSI {Subfungsi} for {Username}"`.
  FUNGSI is logged; if it names a tree unit that is not an ancestor of the placed department, a
  Warning `"Org mapping: FUNGSI {Fungsi} disagrees with tree for {Username}"`. Existing rules
  stay: invalid characters keep existing values; Senior Managers' department is cleared.
- **Acceptance criteria:**
  - Given SUBFUNGSI "SUBSURFACE DEVELOPMENT AREA 1", When the user logs in, Then
    `users.department` = "Subsurface Development Area 1".
  - Given SUBFUNGSI "Unknown Unit", When the user logs in, Then login succeeds, department =
    "Unknown Unit", and one Warning is logged.

### FR-005: Organisation path lookup
- **Traces to:** G1 / US-06, US-11, Q5
- **Priority:** Must
- **Description:** The system shall derive `{department, division, zona, regional, company,
  subdivision:""}` by finding the active `department` unit whose name equals the user's
  department (case-insensitive) and walking up its parents.
- **Edge cases:** no matching unit → only `department` filled, the rest `null` (never the old
  Zona value); two units with the same name → the first by path, Warning logged.

### FR-006: Login and refresh responses
- **Traces to:** US-11, Q9
- **Priority:** Must
- **Description:** `POST /api/v1/auth/login` and `POST /api/v1/auth/refresh` shall add
  `position_name` (normalized: MANAGER/STAFF), `position` (raw Retina POSNAME) and
  `organisation` (FR-005); all existing fields stay.

### FR-007: Profile response
- **Traces to:** US-11, Q5
- **Priority:** Must
- **Description:** `GET /api/v1/users/profile` shall return `organisation` from FR-005
  (`division` = tree Division, e.g. "PnP"), add `position` (raw POSNAME), keep `position_name`
  (normalized), fill top-level `zone` with the tree Zona and `working_area` with the department's
  working area (FR-011).

### FR-008: Department options and choice
- **Traces to:** US-12, Q3
- **Priority:** Must
- **Description:** `GET /api/v1/users/me/department/options` shall return the tree's active
  departments as `[{department, division}]`. `POST /api/v1/users/me/department` shall keep its
  request and errors and return `data = {department, role:{id,name}, organisation}`.
- **Behavior:** the Senior Manager's division becomes the picked department's division.
- **Acceptance criteria:**
  - Given indana (PnP), When she picks "Subsurface Development Area 1", Then the response
    `organisation.division` = "SSDP".

### FR-009: Privileges follow the picked department
- **Traces to:** US-13, Q10
- **Priority:** Must
- **Description:** After a successful department pick the system shall delete the user's ACL
  cache entry and, on the next read, re-read the ACL from Retina naming the picked department's
  role.
- **Validation & Errors:** Retina unreachable → existing fail-closed 503 on reads that need the ACL.
- **Acceptance criteria:**
  - Given indana picked PO, When she picks SDA 1, Then the next `/users/permissions` returns SDA 1's
    privileges without re-login.

### FR-010: Senior Manager outside the own division
- **Traces to:** G4 / US-08, US-09, Q7
- **Priority:** Must
- **Description:** For a Senior Manager, a request on a record whose department belongs to a
  different division than the Senior Manager's shall be allowed only for GET; every other method
  returns 403 `"Read-only outside your division"`, including approvals.
- **Edge cases:** record with no department → treated as outside; Senior Manager with no
  department → no Modify anywhere.

### FR-011: Working area per department
- **Traces to:** US-14, Q11
- **Priority:** Must
- **Description:** Custom configuration `organization.department_working_area` (`key` =
  department name, `value` = `PHSS` or `PEP`) ties a department to one working area. For such a
  user, every EUR/Well list, detail, dashboard, count and alert shall include only wells of that
  working area; requests naming the other working area (`{type}`/`{workingarea}`) return 404.
- **Seed:** SDA 1 → PHSS, SDA 2 → PEP.

### FR-012: SSDP sees only EUR and Well
- **Traces to:** US-14
- **Priority:** Must
- **Description:** The SDA 1 and SDA 2 roles shall hold only the EUR and Well privilege groups.

### FR-013: Drifted-name cleanup
- **Traces to:** G1 / US-05
- **Priority:** Should
- **Description:** A one-time script shall report, then (on approval) rewrite, every
  `department_id` and `users.department` variant to its master name using FR-003's mapping.

### FR-014: Dev seed
- **Traces to:** US-13, US-14 (t105)
- **Priority:** Must
- **Description:** An idempotent SQL seed shall create the tree, both mappings and three test
  users (`r3test.sda1`, `r3test.sda2`, `r3test.po`) with mock-auth rows.

## 5. Data Model

- **`organizations`** (exists in code, missing on dev): a new migration with a Designer file
  creates it; `type` gains `regional` and `zona`. No new columns.
- **`custom_configurations`**: two new rows, `organization.retina_department_mapping` and
  `organization.department_working_area`.
- **Unchanged:** `users.department`, every `department_id` (names). Dropped later: `user_scopes`
  (t98), `users.division`/`users.zone` (t103).

## 6. Interfaces

No new endpoints. Changed responses — examples in the Bruno folders:

| Endpoint | Change |
|---|---|
| `POST /api/v1/auth/login` | + `position_name`, `position`, `organisation` |
| `POST /api/v1/auth/refresh` | same as login |
| `GET /api/v1/users/profile` | `organisation` from tree, + `position`, `zone`/`working_area` filled |
| `POST /api/v1/users/me/department` | `data = {department, role, organisation}` |
| `GET /api/v1/users/me/department/options` | `[{department, division}]` |
| `GET /api/v1/users/permissions` | unchanged shape; content follows the picked department (FR-009) |
| `POST /api/v1/organizations`, `/{id}/update` | FR-001 parent rules, FR-002 rename lock |

## 7. Non-Functional Requirements

### NFR-001: Login never blocked by the tree
- **Requirement:** a missing tree, mapping or table never fails a login; it degrades to FR-004's
  fallback.
- **Traces to:** US-07
### NFR-002: Lookup cost
- **Requirement:** FR-005 adds at most one database round trip per login/profile call.
- **Traces to:** G2
### NFR-003: Observability
- **Requirement:** unmatched SUBFUNGSI and FUNGSI disagreements are Warning logs with
  `log_type=http_in` and the user's `journey_id`.
- **Traces to:** G5

## 8. Permissions & Roles

| Actor | Tree / mapping | Records in own division | Records in other division | Other working area |
|---|---|---|---|---|
| Admin | change | role privileges | role privileges | — |
| Senior Manager | read | role privileges (Modify ok) | GET only | — |
| Staff | read | role privileges | department scope (today) | — |
| SDA 1 / SDA 2 | read | EUR/Well only | — | hidden |

## 9. Analytics & Telemetry

| Event (log) | When | Measures |
|---|---|---|
| `Organisation resolved for {Username}: department=…, division=…` | every login | G2 (share resolved via mapping) |
| `Org mapping: unmatched SUBFUNGSI …` | mapping miss | G2, G5 |
| `Department '<name>' is in use` (409) | blocked rename | G1 |

## 10. Traceability Matrix

| PRD Goal/Story | FRs | NFRs |
|---|---|---|
| G1 / US-01, US-02, US-05 | FR-001, FR-002, FR-005, FR-013 | — |
| G2, G3 / US-03, US-06, US-07 | FR-003, FR-004 | NFR-001, NFR-002 |
| G4 / US-08, US-09 | FR-010 | — |
| G5 / US-04 | FR-004 | NFR-003 |
| US-11 | FR-005, FR-006, FR-007 | — |
| US-12 | FR-008 | — |
| US-13 | FR-009, FR-014 | — |
| US-14 | FR-011, FR-012, FR-014 | — |
| US-10 | FR-008, FR-010 | — |

## 11. Open Questions

- Applying the `organizations` migration to the shared dev DB needs the owner's go-ahead.
- Confirm Retina's real POSNAME for indana ("MANAGER" seen live vs "SENIOR MANAGER" in mock).

## 12. As-built notes (2026-10-12, worktree `feat/org-structure`)

| FR / ticket | Built as | Differs from spec |
|---|---|---|
| FR-010 (t109) | `R3ComponentFilter` widens a Senior Manager's `ActiveDepartments`: GET/HEAD = every tree department, other methods = own Division's departments | A write or approval on another Division's record is **not found (404)** through the department filter, not the spec's 403 message |
| FR-011 (t110) | `R3ComponentFilter` returns 404 when the path/query names the other working area and narrows bound filters' `WorkingArea`; overview card, EUR cardview and `/wells/all` filter at the source query | — |
| FR-009 (t108) | Pick → ACL cache dropped → re-fetch asks Retina for the picked "regulator of …" role; falls back to discovery when Retina has no ACL for it | Dev mock answers per role via a `"{user}\|{role}"` session row |
| t104 | **Coarse module gate** `RequireModuleAccess(groupId)` on Contract/SPK/Project/Tender/SA/Invoice groups, flag `Permissions:ModuleGate:Enabled` (off by default) | Per-route `RbacRouteMaps` classification of every route is still future work. Before enabling: confirm every role holding SPK/Project rights also holds the Contract privileges its screens call |
| t103 | `users.division` dropped (migration `DropUsersDivision`) | **`users.zone` kept** — it is admin-editable through the user API and listed in user responses; decide separately |
| t98 | `user_scopes` removed (migration `DropUserScopes`); department = `users.department` | — |
| t102 | `IntrospectCache` (Redis, SHA-256 key, `RedisConfig:IntrospectTtlSeconds`, capped by token exp) + Redis fail-fast provider | `POST /auth/logout` is a no-op today (commented out) — logout only drops the introspect entry; full logout is not re-enabled |
| FR-013 (t111) | `cleanup_department_names_report.sql` (read-only, run on dev: 131 rows / 17 groups) + `…_apply.sql` (backup table first) | Apply **not run** — awaits PO review |

Not applied to the dev DB: migrations `DropUserScopes`, `DropUsersDivision`, and the cleanup apply.
