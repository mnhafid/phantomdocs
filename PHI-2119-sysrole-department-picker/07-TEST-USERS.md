# Test users

Part of [PHI-2119](README.md). All 41 users start with `phirbac.role.`.

**Created on dev on 2026-11-09.** [07-seed-test-users.sql](07-seed-test-users.sql) creates them and [07-cleanup-test-users.sql](07-cleanup-test-users.sql) removes them.

They are mock logins, so the API needs `R3tinaConfig:UseMockAuthSessions` = true. Any password works.

## Scenario users

| Username                    | Position        | SUBFUNGSI                      | SYSROLEs                                                                                                                          | Expected                                        |
| --------------------------- | --------------- | ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| `phirbac.role.multi`        | STAFF           | Subsurface Development Area 1  | - Projects - Read - Guest<br>Subsurface Development Area 1 - Modify - Member<br>Subsurface Development Area 1 - Approval - Member | Picker: Projects or SDA 1; 159 until picked     |
| `phirbac.role.single`       | STAFF           | Project                        | Projects - Modify - Member                                                                                                        | Project, automatic                              |
| `phirbac.role.guest`        | STAFF           | Project                        | Projects - Read - Guest                                                                                                           | Project, read only                              |
| `phirbac.role.mismatch`     | STAFF           | Operation & Surface Facilities | Projects - Read - Guest                                                                                                           | Project, SYSROLE beats SUBFUNGSI                |
| `phirbac.role.oldstyle`     | TEAM MEMBER     | Production Operations          | Team Member General<br>Read Only                                                                                                  | SUBFUNGSI + merge all                           |
| `phirbac.role.mixed`        | STAFF           | Project                        | Projects - Read - Guest<br>Team Member General                                                                                    | Project, old-style role ignored                 |
| `phirbac.role.malformed`    | STAFF           | Production Operations          | Projects - Read                                                                                                                   | SUBFUNGSI + merge all, under 3 segments         |
| `phirbac.role.leader`       | STAFF           | Project                        | Projects - Modify - Leader                                                                                                        | Project, regulator at login                     |
| `phirbac.role.leader.cross` | STAFF           | Project                        | Projects - Modify - Leader<br>Operations & Surface Facilities - Modify - Member                                                   | Picker; regulator of whichever is picked        |
| `phirbac.role.approver`     | STAFF           | Production Operations          | Production Operations - Approval - Member                                                                                         | PO, read + approve                              |
| `phirbac.role.manager`      | MANAGER         | Project                        | Projects - Modify - Member                                                                                                        | Project; starts as regulator, removed at login  |
| `phirbac.role.unknown`      | STAFF           | Project                        | Projects - Read - Guest<br>Finance - Read - Guest                                                                                 | Picker with Projects and Other: Finance         |
| `phirbac.role.gm`           | GENERAL MANAGER | Operation & Surface Facilities | Projects - Modify - Member<br>Operations & Surface Facilities - Read - Guest                                                      | Picker, full list; 159 on unheld pick           |
| `phirbac.role.gm.oldstyle`  | GENERAL MANAGER | Operation & Surface Facilities | Project<br>Operation & Surface Facilities                                                                                         | Picker; merged before and after pick            |
| `phirbac.role.gm.leader`    | GENERAL MANAGER | Operation & Surface Facilities | Projects - Modify - Leader<br>Production Operations - Modify - Leader                                                             | Picker; regulator of whichever is picked        |
| `phirbac.role.sm`           | SENIOR MANAGER  | Subsurface Development Area 1  | Subsurface Development Area 1 - Modify - Leader                                                                                   | Picker; regulator after pick                    |
| `phirbac.role.superadmin`   | STAFF           | Project                        | Super Admin                                                                                                                       | Picker; merged; regulator after pick            |
| `phirbac.role.foreignadmin` | STAFF           | Project                        | Projects - Read - Guest                                                                                                           | Project; other-system Super Admin ignored       |
| `phirbac.role.none`         | STAFF           | Production Operations          | (none)                                                                                                                            | Login rejected by the existing application gate |
| `phirbac.role.alias`        | STAFF           | Project                        | Project - Modify - Member                                                                                                         | Project, prefix alias                           |
| `phirbac.role.uppercase`    | STAFF           | Project                        | Projects - Modify - LEADER                                                                                                        | Project, regulator, keyword ignores case        |

## One user per SYSROLE

| Username                        | Position | SUBFUNGSI                      | SYSROLEs                                            | Expected                                                         |
| ------------------------------- | -------- | ------------------------------ | --------------------------------------------------- | ---------------------------------------------------------------- |
| `phirbac.role.project.leader`   | STAFF    | Project                        | Projects - Modify - Leader                          | Project, read, modify, approve; regulator                        |
| `phirbac.role.project.member`   | STAFF    | Project                        | Projects - Modify - Member                          | Project, read, modify                                            |
| `phirbac.role.project.guest`    | STAFF    | Project                        | Projects - Read - Guest                             | Project, read                                                    |
| `phirbac.role.project.approval` | STAFF    | Project                        | Projects - Approval - Member                        | Project, read, approve                                           |
| `phirbac.role.osf.leader`       | STAFF    | Operation & Surface Facilities | Operations & Surface Facilities - Modify - Leader   | Operation & Surface Facilities, read, modify, approve; regulator |
| `phirbac.role.osf.member`       | STAFF    | Operation & Surface Facilities | Operations & Surface Facilities - Modify - Member   | Operation & Surface Facilities, read, modify                     |
| `phirbac.role.osf.guest`        | STAFF    | Operation & Surface Facilities | Operations & Surface Facilities - Read - Guest      | Operation & Surface Facilities, read                             |
| `phirbac.role.osf.approval`     | STAFF    | Operation & Surface Facilities | Operations & Surface Facilities - Approval - Member | Operation & Surface Facilities, read, approve                    |
| `phirbac.role.po.leader`        | STAFF    | Production Operations          | Production Operations - Modify - Leader             | Production Operations, read, modify, approve; regulator          |
| `phirbac.role.po.member`        | STAFF    | Production Operations          | Production Operations - Modify - Member             | Production Operations, read, modify                              |
| `phirbac.role.po.guest`         | STAFF    | Production Operations          | Production Operations - Read - Guest                | Production Operations, read                                      |
| `phirbac.role.po.approval`      | STAFF    | Production Operations          | Production Operations - Approval - Member           | Production Operations, read, approve                             |
| `phirbac.role.sda1.leader`      | STAFF    | Subsurface Development Area 1  | Subsurface Development Area 1 - Modify - Leader     | Subsurface Development Area 1, read, modify, approve; regulator  |
| `phirbac.role.sda1.member`      | STAFF    | Subsurface Development Area 1  | Subsurface Development Area 1 - Modify - Member     | Subsurface Development Area 1, read, modify                      |
| `phirbac.role.sda1.guest`       | STAFF    | Subsurface Development Area 1  | Subsurface Development Area 1 - Read - Guest        | Subsurface Development Area 1, read                              |
| `phirbac.role.sda1.approval`    | STAFF    | Subsurface Development Area 1  | Subsurface Development Area 1 - Approval - Member   | Subsurface Development Area 1, read, approve                     |
| `phirbac.role.sda2.leader`      | STAFF    | Subsurface Development Area 2  | Subsurface Development Area 2 - Modify - Leader     | Subsurface Development Area 2, read, modify, approve; regulator  |
| `phirbac.role.sda2.member`      | STAFF    | Subsurface Development Area 2  | Subsurface Development Area 2 - Modify - Member     | Subsurface Development Area 2, read, modify                      |
| `phirbac.role.sda2.guest`       | STAFF    | Subsurface Development Area 2  | Subsurface Development Area 2 - Read - Guest        | Subsurface Development Area 2, read                              |
| `phirbac.role.sda2.approval`    | STAFF    | Subsurface Development Area 2  | Subsurface Development Area 2 - Approval - Member   | Subsurface Development Area 2, read, approve                     |

## Notes

- `phirbac.role.manager` starts with the `regulator of project` role and its casbin g-rule, for the "removed at login" scenario.
- `phirbac.role.foreignadmin` also holds Super Admin on a system named `OTHERSYSTEM`.
- Old-style `Team Member General` and `Read Only` copy their permissions from existing dev sessions.
- Before the code ships, these users follow today's login rules, so they will not match the expected results.
