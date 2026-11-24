# PRD: department picker and permissions from SYSROLE names

| | |
|---|---|
| **Ticket** | [PHI-2119](https://digiitphi.atlassian.net/browse/PHI-2119), BE subtask PHI-2121, QA subtask PHI-2122 |
| **Epic** | PHI-1852 SSDP1 |
| **Status** | Agreed 2026-11-09, not implemented |
| **Decisions** | [01-DECISIONS.md](01-DECISIONS.md) |

## 1. Problem

Only Senior Managers, General Managers and Super Admins can choose a department today, and they all see the same fixed list. Everyone else is locked to the department Retina sends in SUBFUNGSI, even when their roles cover several departments.

Permissions need the SYSROLE name to equal the department exactly. Retina's new names, such as `Projects - Read - Guest`, would never match. A user with no match drops to Data Config (159) only, which is too little during the move to the new names.

## 2. Goals

1. A user's SYSROLEs decide their department, what they can choose and what they can do.
2. A user with 2 or more departments can choose between them, at login and from the profile menu.
3. Picking a department gives only that department's permissions.
4. Regulator access follows the SYSROLE, not `pos_name`.
5. Each department has a standard set of 4 SYSROLEs: Leader, Member, Guest and Approval.
6. No response is changed unless the feature needs it.

## 3. Out of scope

- Renaming stored department names. This is a later ticket (D4).
- Moving the pattern to custom config. This comes later (D2).
- Remembering the last pick between logins (D8).
- Creating the SYSROLEs in Retina, which the R3 team does from [04-SYSROLES-TO-CREATE.md](04-SYSROLES-TO-CREATE.md).

## 4. Users

| User | What happens |
|---|---|
| One-department user | Goes straight in with that department and its permissions |
| Multi-department user | Picks at every login, and can switch from the profile menu |
| Old-style user, no patterned SYSROLE | Keeps the SUBFUNGSI department, with all SYSROLEs merged |
| GM / SM | Picks from today's list, and gets the permissions of the picked department's SYSROLEs |
| Super Admin | Picks from today's list and keeps merged permissions |
| Leader | Becomes regulator of their current department |

## 5. Functional requirements

| ID | Requirement | Decision |
|---|---|---|
| FR-01 | Parse SYSROLEs as `Department - name - level`; fewer than 3 segments is not patterned | D1 |
| FR-02 | Only count SYSROLEs of the Phantom system | D13 |
| FR-03 | Map `Projects` and `Operations & Surface Facilities` to the stored names | D3 |
| FR-04 | Ignore old-style SYSROLEs when a patterned one is held | D5 |
| FR-05 | With no patterned SYSROLE, department = SUBFUNGSI | D6 |
| FR-06 | With one department, set it automatically, even if SUBFUNGSI differs | D6, D7 |
| FR-07 | With 2 or more departments, clear the department at every login and require a pick | D8 |
| FR-08 | GM, SM and Super Admin keep today's picker list | D9 |
| FR-09 | Permissions = the union of the SYSROLEs under the current department | D10 |
| FR-10 | With no patterned SYSROLE, permissions = all SYSROLEs merged, minimum 159, including GM and SM before and after a pick | D11 |
| FR-11 | With patterned SYSROLEs, before a pick or after a pick with no matching SYSROLE, permissions = 159 only | D12 |
| FR-12 | Super Admin keeps merged permissions | D13 |
| FR-13 | A SYSROLE containing `leader` or `super admin` in any department gives regulator of the current department | D14 |
| FR-14 | Regulator is re-evaluated on every login and pick, and removed when no longer earned | D15 |
| FR-21 | GM and SM are assigned Leader SYSROLEs in Retina | D23 |
| FR-15 | `GET /users/me/department/options` returns the user's options, or `[]` if they cannot choose | D17, D18 |
| FR-16 | FE shows Switch Workspace when options exist, and forces the pick when department is also empty | D18 |
| FR-17 | Cards are built from the options list, with unknown departments under "Other" | D19, D20 |
| FR-18 | Reject a pick the user does not hold, except GM, SM and Super Admin | D21 |
| FR-19 | Logo falls back to the general Phantom logo, including when `organisation` is null | D22 |
| FR-20 | `/users/profile`, login and POST response shapes do not change | D17 |

## 6. Acceptance

Every scenario in [06-e2e-scenarios.feature](06-e2e-scenarios.feature) passes on dev with the test users it defines.

## 7. Risks

| Risk | Effect | Mitigation |
|---|---|---|
| Backend ships before Retina is converted | Old-style users, including GM and SM, hold every SYSROLE merged, so a pick does not narrow their permissions | Accepted (D11). Ends as each user is converted |
| Half-converted users | A user with one new role loses their old role's permissions (D5) | Convert each user fully at once |
| Regulator check moves to SYSROLE | Manager or Staff regulators without a Leader SYSROLE lose write gates | Assign Leader using [05-USER-MAPPING.md](05-USER-MAPPING.md) first |
| GM / SM become regulators once mapped to Leader | Regulator write gates they do not have today | Accepted (D23) |
| Merge-all for old-style users | Wider than strict matching | Only while they hold no patterned SYSROLE |
| Department changes for SUBFUNGSI mismatches | Data scope and sidebar shift at first login | Compare the user mapping before release |
| Name spelling varies | A department is not recognised | Open item O2 |

## 8. Rollout

1. Deploy backend and frontend together. Old-style users keep working through merge-all.
2. Review and create the 20 SYSROLEs in Retina on dev.
3. Assign them using the user mapping, converting each user fully at once.
4. Run the end-to-end scenarios.
5. Repeat for prod, with a prod user mapping.
