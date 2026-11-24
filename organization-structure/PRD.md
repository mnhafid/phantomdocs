# PRD: Organization Structure (Company → Regional → Zona → Division → Department)

| | |
|---|---|
| **Status** | Approved 2026-10-12 |
| **Author** | mnhafid / Claude |
| **Date** | 2026-10-12 |
| **Version** | 1.0 |
| **Related docs** | FSD.md (written after sign-off) · ADR-0008 (recorded at sign-off) |

## 1. Overview

Phantom gets one master organization structure — Company → Regional → Zona → Division →
Department — that admins maintain in the app. R3tina (Retina) values that arrive at login are
matched to that structure through a configurable mapping, so a renamed or differently spelled
Retina value still lands on the right unit. Senior managers get rights by division: they can
change data of departments inside their own division and only view the departments of other
divisions. Permissions reuse the existing role and permission implementation; nothing new is
invented for access control.

## 2. Problem Statement

- **There is no master list of departments or divisions.** `department_id` on 13 tables
  (projects, contracts, SPKs, invoices, …) is free text copied from Retina or typed by a manager.
- **The text has drifted.** Dev DB today: "OSF", "Operation & Surface Facilities" and
  "Operation & Surfaces Facilities" are one department split three ways; "Project" vs
  "Projects" is another split. Records under the wrong spelling are invisible to the users who
  own them (ADR-0005 also notes 126 of 156 production contracts with no department).
- **The levels are wrong.** Retina FUNGSI ("ZONA 9") is stored in `users.division`, but in the
  real hierarchy "Zona 9" is a zona. Real divisions and regionals exist nowhere in Phantom.
- **Retina naming does not match Phantom naming,** and the only translation today is a
  hard-wired display-name list for departments.
- **Senior managers cannot be scoped by division.** Rights are per department only, so a
  division head either sees one department or must pick one at every login.

## 3. Goals & Success Metrics

| ID | Goal | Metric | Target |
|---|---|---|---|
| G1 | One master organization structure | Active `department_id` values on projects, contracts, SPKs, invoices, service acceptances that match a master department | 100% after the cleanup, 0 free-text variants |
| G2 | Retina values land on the right unit automatically | Logins whose Retina values resolve through the mapping, without manual choice | ≥ 95% of logins in the first month |
| G3 | Mapping is fixable without a deployment | Time from an admin's mapping change to effect | Next login of the affected user, no deploy |
| G4 | Senior managers act per division | Writes by a senior manager on another division's department data | 0 successful (enforced and tested); reads allowed |
| G5 | Unmatched Retina values are visible | Unmatched values shown to admins | 100% listed, same day |

## 4. Non-Goals

- **No new permission engine.** Access uses the existing roles, casbin rules and department
  filter — the user decided this.
- **No automatic org-tree sync from Retina.** The tree is maintained by admins; the unused
  `OrganizationSyncService` stays out of scope (Retina's cascader has no regional/zona levels).
- **No org-path visibility on records.** That axis was built and removed (migration
  `DropOrganizationLinkFromRoots`); records keep their department reference.
- **No multi-company support.** One company root.
- **No Senior Manager over more than one Division.** One Senior Manager, one Division (acting heads are rare; supporting them needs per-user division lists, the `user_scopes` problem this work removes).
- **No change to approval routes.** They keep department as metadata (ADR-0005).
- **No HR data** (positions, reporting lines) beyond what identifies a senior manager today.

## 5. Users & Personas

| Persona | Description | Key need |
|---|---|---|
| **Admin** | Phantom system administrator | Keep the structure and the Retina mapping correct |
| **Senior Manager** | Head of a division, e.g. *PnP Division* (identified today by Retina POSNAME "senior manager") | Run every department in the own division, see the others |
| **Staff** | Regular user in one department | Land in the right department at login, see own department's work |

## 6. User Stories

### Admin — maintains the structure

| ID | Story | Priority |
|---|---|---|
| US-01 | As an **Admin**, I want to create, rename, move and deactivate units on each of the five levels (Company, Regional, Zona, Division, Department), so that Phantom matches the real organization. A Department that already has records keeps its name for good; to change it I create a new Department and move the records (Q8). | Must |
| US-02 | As an **Admin**, I want to see the whole structure as a tree, so that I can check it at a glance. | Must |
| US-03 | As an **Admin**, I want to map each Retina value (FUNGSI, SUBFUNGSI and similar) to a unit, with a different Phantom name where needed (e.g. "PROJECTS" → "Project"), so that users land on the right unit even when Retina spells it differently. | Must |
| US-04 | As an **Admin**, I want to see Retina values that matched no unit (as warning lines in the log viewer, OpenObserve), so that I can add the missing mapping. | Must |
| US-05 | As an **Admin**, I want existing records with drifted department names (e.g. "OSF", "Operation & Surfaces Facilities") moved to the one master department, so that nobody loses sight of their records. | Should |

### Staff — just works

| ID | Story | Priority |
|---|---|---|
| US-06 | As **Staff**, I want my department set automatically from Retina when I log in, and my division, zona, regional and company to follow from it, so that I see my department's work without asking anyone. | Must |
| US-07 | As **Staff**, I want login to keep working when my Retina value is unmapped, so that a mapping gap never locks me out. | Must |
| US-11 | As **Staff**, I want to see my division and my position right after login and on my profile, so that I know which unit and role Phantom has me under. | Must |

### Senior Manager — runs a division

| ID | Story | Priority |
|---|---|---|
| US-08 | As a **Senior Manager of PnP Division**, I want to read and modify the data of every department under PnP Division, so that I can run my whole division without switching departments. | Must |
| US-09 | As a **Senior Manager of PnP Division**, I want to read — but never change — the data of departments in other divisions (I can open, list and export; I cannot create, edit, submit or approve, even when I am named as an approver), so that I have context without changing what is not mine. | Must |
| US-12 | As a **Senior Manager**, I want to set my department myself (when Retina sends none, or I need another one) and have my division follow automatically, so that my rights are right without asking an Admin. | Must |
| US-13 | As a **Senior Manager**, I want my privileges to follow the department I pick — e.g. picking **PO** lets me only **view** EUR and Well, picking a **SSDP** department (SDA 1 or SDA 2) lets me **view and modify** EUR and Well — right after I pick it, without logging in again, so that I work with exactly the rights of the department I act for. | Must |
| US-14 | As an **SSDP user** (SDA 1 or SDA 2), I want to see only the EUR and Well modules, and inside them only the wells of my working area (SDA 1: PHSS, SDA 2: PEP), so that my screens hold only my work. Other modules and the other working area's wells are hidden. | Must |
| US-10 | As a **Senior Manager**, I want my rights to follow the structure, so that a department moved into my division is covered without a manual role change. | Should |

## 7. Requirements (high level)

1. One organization structure with exactly five levels; each unit sits under a unit of the
   level above. — US-01, US-02
2. A Retina mapping stored as custom configuration (the existing `custom_configurations` store),
   editable by admins, translating a Retina value to a unit and a Phantom name. — US-03, US-06
3. Login places the user by Retina SUBFUNGSI only (through the mapping), derives Division, Zona,
   Regional and Company from the tree, and falls back to the current behavior when no mapping
   matches. FUNGSI is only logged. — US-06, US-07
4. Unmatched Retina values are logged as warnings that admins can find in OpenObserve. — US-04
5. A one-time, reviewable cleanup that maps existing drifted `department_id` values to master
   departments. — US-05
6. Division-scoped access for senior managers built on the existing roles and casbin rules,
   with the senior manager's departments derived from the organization structure: modify
   inside the own division, view-only outside it. — US-08, US-09, US-10
7. **No new endpoints** (Q9): the mapping is edited through the existing custom-configuration endpoints and the tree through the existing organization endpoints; only their rules and the user responses change.
8. Picking a department switches the user's privileges to that department's role at once: the role is edited in Phantom, synced to Retina, and Phantom re-reads the user's privileges from Retina for that role (Q10). — US-13

Details: FSD.md (after sign-off).

## 8. Constraints & Dependencies

- **Existing `organizations` table** (Guid id, code, name, type, parent, path, level) and its
  admin CRUD at `/api/v1/organizations` — today it allows only company/division/subdivision/
  department; Regional and Zona types are missing. The table is not yet on the dev DB.
- **`department_id` is a string on 13 tables** and is the only live visibility axis
  (`IDepartmentContext.ActiveDepartments`). Changing what it stores touches every list query.
- **Existing access model:** casbin p-rules (object/action), g-rules with department in `V2`
  (written inconsistently today — code by role-assign, raw name by login), the
  manager "choose a department" flow and the regulator roles.
- **Retina** supplies FUNGSI/SUBFUNGSI (plus CoyCode, Area, Unit, … unused today). Its outages
  must not block login.
- **Senior manager detection** is `R3PositionHelper` (POSNAME contains "senior manager").
- **Org source at login** is the Retina login response's `userInformation.SUBFUNGSI` (Department). FUNGSI is inconsistent across users (a Zona for some, a Division for others) and is only logged.
- **Privilege category:** every legacy privilege is tagged View or Modify in the RBAC sheet ("PHI-NEW by Method"). US-09's view-only access maps onto granting only the View privileges outside the own division.
- **`user_scopes` is being removed** in a separate ticket (Luvus `t98`): a user's department
  comes from `users.department` only. So the several departments a senior manager acts on must
  come from the organization structure (division → its departments), never from `user_scopes`.
- **Role caches** (see the cache review of 2026-10-12): the Retina ACL is cached in Redis per
  user and is not cleared by the login department-role write or the choose-department flow;
  division rights must not depend on that cache being fresh.

## 9. Assumptions

- **A1:** ~~"4 levels" means one Company root with 4 levels under it~~ — confirmed (Q1).
- **A2:** Zona 9 has two known divisions: PnP (Project, Production Operations, Operation & Surface Facilities — Q2) and SSDP (SDA 1, SDA 2); admins create others later — impact if wrong:
  a seed list must be added to the rollout.
- **A3:** ~~"Modify department" means modifying records~~ — confirmed (Q2); structure changes are Admin-only.
- **A4:** ~~A senior manager belongs to exactly one division~~ — confirmed as a non-goal (Q3).
- **A5:** Records keep referencing a department by its **name** (Q4), not a code, division or path — impact if wrong:
  every list query and the 13 tables change.
- **A8:** ~~SDA users can read the other working area~~ — decided the other way: it is **hidden** (Q11).
- **A7:** SSDP sits under Zona 9 like PnP — impact if wrong: a second Zona or Regional in the seed.
- **A6:** The mapping lives in `custom_configurations` (one row per category, options in the
  detail JSON), the same way other lookups are stored — impact if wrong: a new table.

## 10. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Cleanup maps a record to the wrong department and hides it from its owners | Medium | High | Reviewable mapping report before apply; reversible (old value kept) |
| A wrong mapping row sends many users to the wrong unit at their next login | Medium | High | Fallback to current behavior on no match; admin sees resolution per user |
| g-rule `V2` holds codes in one path and names in another; division rights inherit the mess | High | Medium | Normalize `V2` to one form as part of this feature |
| "Hidden" modules are hidden only in the frontend: today the backend checks privileges on **Custom Configurations routes only**, so an SSDP user calling e.g. `/api/v1/contracts` directly still gets data | High | High | Opt every module's routes into the existing legacy privilege check (RbacRouteMaps) as part of this feature, starting with the modules SSDP must not reach |
| Hiding the other working area misses a screen: every EUR/Well list, detail, dashboard card (PHSS and PEP overviews side by side today), count and alert must filter by working area, or PEP wells leak to SDA 1 | High | Medium | One shared working-area filter applied by every EUR/Well query; a test per route listed in Sheet4 |
| Senior manager loses access during rollout | Low | High | Feature flag; keep the existing choose-department flow until the division scope is on |
| A document's approver list names a Senior Manager from another division, so the approval can never complete (Q7 blocks it) | Medium | High | Warn when an approver is set from outside the document's division; list stuck approvals for the admin |

## 11. Release & Rollout

1. Structure + admin tree (US-01, US-02) behind a flag, seeded with the known tree (Q2):

   ```
   PHE (Company)
   └ Regional 3
     └ Zona 9
       └ PnP — Project and Production (Division)
         ├ Project                        ← "Project", "Projects"
         ├ Production Operations          ← "Production Operations", "PO"
         └ Operation & Surface Facilities ← "Operation & Surface Facilities",
                                             "Operation & Surfaces Facilities", "OSF"
       └ SSDP — Subsurface Development & Planning (Division)
                                          ← Retina FUNGSI "SUBSURSFACE DEVELOPMENT & PLANNING"
         ├ SDA 1 — Subsurface Development Area 1  ← SUBFUNGSI "SUBSURFACE DEVELOPMENT AREA 1"
         └ SDA 2 — Subsurface Development Area 2  ← SUBFUNGSI "SUBSURFACE DEVELOPMENT AREA 2"
   ```

   SSDP sits under Zona 9 (assumed — A7).

   The right-hand spellings are the starting rows of the Retina mapping and the cleanup (US-05).
2. Retina mapping + login resolution + unmatched list (US-03, US-04, US-06, US-07).
3. Department cleanup report → apply (US-05).
4. Division-scoped senior-manager access (US-08–US-10), flag on per environment.

## 12. Open Questions

| # | Question | Owner | Status |
|---|---|---|---|
| Q1 | Tree depth and the meaning of Division. | mnhafid | **Resolved 2026-10-12:** Company root + 4 levels, each strictly under the level above. "Division" means only the level under Zona; what the code calls `division` today (Retina FUNGSI "ZONA 9") is the **Zona**. Division is filled through the mapping (Retina does not send it). Known division: **PnP** = Project and Production, in Zona 9. |
| Q2 | In US-08, does "modify department" mean the department's records or its master entry? | mnhafid | **Resolved 2026-10-12:** the **records** (projects, contracts, SPKs, invoices, service acceptances) with the actions the role already grants. Changing the structure (rename, move, deactivate a unit) stays **Admin-only**. |
| Q3 | How is a Senior Manager's division known, and can it be more than one? | mnhafid | **Resolved 2026-10-12:** the Division always follows the Senior Manager's **Department** through the tree. The Department comes from `userInformation.SUBFUNGSI` at login, or from **`POST /api/v1/users/me/department`**, which sets the Department **and thereby the Division** (also covers an empty SUBFUNGSI). One Division per Senior Manager; more than one is a non-goal. |
| Q4 | Should `department_id` on records store the master code or keep the name? | mnhafid | **Resolved 2026-10-12: keep the existing form** — records go on storing the Department **name**. The master Department's name is the one canonical spelling; the cleanup (US-05) rewrites every variant ("OSF", "Operation & Surfaces Facilities", "Projects", "PO", …) to it. No codes on records. |
| Q8 | What happens when an Admin renames a Department? | mnhafid | **Resolved 2026-10-12: renaming is not allowed once the Department has records** (or users). To change a name the Admin creates a new Department and moves the records with a reviewed cleanup (same mechanism as US-05). A Department with no records yet may still be renamed. |
| Q9 | Do the mapping, the tree and the unmatched list need new endpoints? | mnhafid | **Resolved 2026-10-12: no.** Mapping via existing `/custom-configurations`, tree via existing `/organizations` (validation extended: Regional and Zona types, no rename of a Department with records), unmatched Retina values as Warning logs in OpenObserve. Response changes only: login, refresh, profile, `POST /users/me/department`, `GET /users/me/department/options`. |
| Q10 | After a department is picked, where do the user's privileges come from? | mnhafid | **Resolved 2026-10-12: Retina, for the chosen department's role (option A).** Department roles ("regulator of <department>") and their privileges are owned and edited in **Phantom** and synced to Retina; on `POST /users/me/department` Phantom drops the user's cached privileges and re-reads them from Retina for that role. `/users/permissions` and every route check follow immediately. The Retina ACL stays the single source the checks read (ADR-0001 holds). |
| Q11 | Which working area does each SSDP department work on, and what may it see? | mnhafid | **Resolved 2026-10-12:** **SDA 1 → PHSS, SDA 2 → PEP** (Sheet4 headers "SDA 1 - Update PEP / SDA 2 - Update PHSS" are swapped — fix the sheet). SSDP departments see **only the EUR and Well modules**; all other modules are hidden — their roles carry only the EUR/Well privilege groups, so `/users/permissions` returns nothing else. Both SDA roles hold the same EUR/Well privileges; what differs is the working area they may change (routes carry `{type}`/`{workingarea}` = phss/pep). Wells of the other working area are **hidden** (A8, confirmed): an SDA 1 user does not see PEP wells anywhere — lists, details, dashboards, counts, alerts — and SDA 2 does not see PHSS wells. PO and other departments without a working area see both. |
| Q5 | `users.division` holds the Zona today. What do the user's org fields become? | mnhafid | **Resolved 2026-10-12:** a user stores only their **Department** (by name, like records). Division, Zona, Regional and Company shown in login/profile are **looked up from the tree** at that moment (indana: Production Operations → PnP → Zona 9 → Regional 3 → PHE). `users.division` and `users.zone` stop being written and are dropped in a separate ticket. `projects.zone` (a project attribute with its own filter) is out of scope. |
| Q6 | Which Retina fields feed which level? | mnhafid | **Resolved 2026-10-12 (revised):** users are placed by **`userInformation.SUBFUNGSI` only** → mapping → Department → walk up the tree for Division, Zona, Regional and Company. **FUNGSI is not used for placement**: it names a Zona for some users ("ZONA 9") and a Division for others ("SUBSURSFACE DEVELOPMENT & PLANNING"), so it is only logged, and a FUNGSI that disagrees with the tree is logged as a Warning. Company/Regional never come from Retina (`COYNAME` "PERTAMINA EP" is the legal employer). |
| Q7 | Outside the own division, which actions may a Senior Manager take? | mnhafid | **Resolved 2026-10-12:** **read only — GET requests** (the sheet's View category). Every other method is refused, **including approving a record the Senior Manager is named on** as approver. |



## Sign-off

| Role | Name | Decision | Date |
|---|---|---|---|
| Product owner | mnhafid | ☑ Approved | 2026-10-12 |

On approval: the decision is recorded as **ADR-0008** in `.claude/docs/adr/`, then the FSD and
Luvus tickets are written.
