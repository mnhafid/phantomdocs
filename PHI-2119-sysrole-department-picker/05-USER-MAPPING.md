# User to SYSROLE mapping

Part of [PHI-2119](README.md). Taken from the dev database on 2026-11-09: 101 active users, with current SYSROLEs read from `mock_auth_sessions`.

**Status: proposal for dev only.** Dev SYSROLEs are not production assignments, and prod needs its own export from Retina. The full list is in [05-user-mapping.csv](05-user-mapping.csv).

## Summary

| Group | Meaning | Users |
|---|---|---|
| A | Keep Super Admin | 6 |
| B | GM / SM | 7 |
| C | Current regulator | 0 |
| D | Department member | 15 |
| F | Old-style SYSROLE, proposal needs confirming | 16 |
| G | Old-style SYSROLE, no proposal | 1 |
| E | No SYSROLE on record | 56 |

**Regulator impact under this proposal:** 6 keep, 9 gain, 0 lose.

This only covers `users.role_id`. Regulator access granted through a casbin g-rule alone is not counted.

## A. Keep Super Admin

| Retina ID | Position | Department today | Current SYSROLEs | Proposed SYSROLEs | At login | Regulator | Note |
|---|---|---|---|---|---|---|---|
| MK.RIDHA.DANJANNY | GENERAL MANAGER |  | SuperAdmin | Super Admin | Super Admin picker | Gains | Normalize spelling to one value |
| R3TEST.SUPERADMIN | STAFF |  | SuperAdmin | Super Admin | Super Admin picker | Gains | Normalize spelling to one value |
| MK.JOHANARIFIANTO | Manager | Production Operations | SuperAdmin<br>Team Member General | Super Admin | Super Admin picker | Keeps | Normalize spelling to one value |
| MK.SUPER_ADMIN | Manager | Project | SuperAdmin<br>Team Member General | Super Admin | Super Admin picker | Gains | Normalize spelling to one value |
| PHI.SUPERADMIN | STAFF | Project | SuperAdmin | Super Admin | Super Admin picker | Keeps | Normalize spelling to one value |
| MK.SENIORMANAGER | SENIOR MANAGER | Projects | Operation & Surface Facilities<br>Production Operations<br>Project<br>SUper Admin<br>Subsurface Development Area 1<br>Subsurface Development Area 2 | Super Admin | Super Admin picker | Keeps | Normalize spelling to one value |

## B. GM / SM

| Retina ID | Position | Department today | Current SYSROLEs | Proposed SYSROLEs | At login | Regulator | Note |
|---|---|---|---|---|---|---|---|
| PHI.SENIORMANAGERSSDP | SENIOR MANAGER |  | Subsurface Development Area 1<br>Subsurface Development Area 2 | Subsurface Development Area 1 - Modify - Leader<br>Subsurface Development Area 2 - Modify - Leader | GM/SM picker | Gains | Leader confirmed (D23). Becomes a regulator, which GM/SM are not today |
| R3TEST.GM | GENERAL MANAGER | Operation & Surface Facilities | Operation & Surface Facilities<br>Production Operations<br>Project<br>Subsurface Development Area 1<br>Subsurface Development Area 2<br>Team Member General | Operations & Surface Facilities - Modify - Leader<br>Production Operations - Modify - Leader<br>Projects - Modify - Leader<br>Subsurface Development Area 1 - Modify - Leader<br>Subsurface Development Area 2 - Modify - Leader | GM/SM picker | Gains | Leader confirmed (D23). Becomes a regulator, which GM/SM are not today |
| PHI.GENERALMANAGER | GENERAL MANAGER | Project | Operation & Surface Facilities<br>Production Operations<br>Project<br>Subsurface Development Area 1<br>Subsurface Development Area 2 | Operations & Surface Facilities - Modify - Leader<br>Production Operations - Modify - Leader<br>Projects - Modify - Leader<br>Subsurface Development Area 1 - Modify - Leader<br>Subsurface Development Area 2 - Modify - Leader | GM/SM picker | Keeps | Leader confirmed (D23). Becomes a regulator, which GM/SM are not today |
| PHI.SENIORMANAGERPNP | SENIOR MANAGER | Project | Operation & Surface Facilities<br>Production Operations<br>Project | Operations & Surface Facilities - Modify - Leader<br>Production Operations - Modify - Leader<br>Projects - Modify - Leader | GM/SM picker | Keeps | Leader confirmed (D23). Becomes a regulator, which GM/SM are not today |
| R3TEST.INDANA | SENIOR MANAGER | Project | Subsurface Development Area 1<br>Subsurface Development Area 2<br>Team Member General | Subsurface Development Area 1 - Modify - Leader<br>Subsurface Development Area 2 - Modify - Leader | GM/SM picker | Gains | Leader confirmed (D23). Becomes a regulator, which GM/SM are not today |
| RETEST.FARUQI | SENIOR MANAGER | Subsurface Development Area 1 | Operation & Surface Facilities<br>Production Operations<br>Project<br>Subsurface Development Area 1<br>Subsurface Development Area 2<br>Team Member General | Operations & Surface Facilities - Modify - Leader<br>Production Operations - Modify - Leader<br>Projects - Modify - Leader<br>Subsurface Development Area 1 - Modify - Leader<br>Subsurface Development Area 2 - Modify - Leader | GM/SM picker | Gains | Leader confirmed (D23). Becomes a regulator, which GM/SM are not today |
| R3TEST.SM.PNP | SENIOR MANAGER | Subsurface Development Area 2 | OSF<br>Operation & Surface Facilities<br>PO<br>Production Operations<br>Project<br>Subsurface Development Area 1<br>Subsurface Development Area 2 | Operations & Surface Facilities - Modify - Leader<br>Production Operations - Modify - Leader<br>Projects - Modify - Leader<br>Subsurface Development Area 1 - Modify - Leader<br>Subsurface Development Area 2 - Modify - Leader | GM/SM picker | Gains | Leader confirmed (D23). Becomes a regulator, which GM/SM are not today |

## C. Current regulator

| Retina ID | Position | Department today | Current SYSROLEs | Proposed SYSROLEs | At login | Regulator | Note |
|---|---|---|---|---|---|---|---|

## D. Department member

| Retina ID | Position | Department today | Current SYSROLEs | Proposed SYSROLEs | At login | Regulator | Note |
|---|---|---|---|---|---|---|---|
| PHI.OSF | STAFF | Operation & Surface Facilities | Operation & Surface Facilities | Operations & Surface Facilities - Modify - Member | Automatic | - |  |
| PHI.PO | STAFF | Production Operations | Production Operations | Production Operations - Modify - Member | Automatic | - |  |
| R3TEST.AMIN | TEAM MEMBER | Production Operations | Production Operations<br>Team Member General | Production Operations - Modify - Member | Automatic | - |  |
| R3TEST.DRILLING | STAFF | Production Operations | Production Operations | Production Operations - Modify - Member | Automatic | - |  |
| R3TEST.PO | PROJECT OFFICER | Production Operations | PO | Production Operations - Modify - Member | Automatic | - |  |
| PHI.PROJECTS | STAFF | Project | Project | Projects - Modify - Member | Automatic | - |  |
| MK.AGUNG.EKAWAHYU | STAFF | Subsurface Development Area 1 | Subsurface Development Area 1 | Subsurface Development Area 1 - Modify - Member | Automatic | - |  |
| PHI.APPROVER | STAFF | Subsurface Development Area 1 | Subsurface Development Area 1 | Subsurface Development Area 1 - Modify - Member | Automatic | - |  |
| PHI.SDA1 | STAFF | Subsurface Development Area 1 | Subsurface Development Area 1 | Subsurface Development Area 1 - Modify - Member | Automatic | - |  |
| R3TEST.SDA1 | STAFF | Subsurface Development Area 1 | Subsurface Development Area 1 | Subsurface Development Area 1 - Modify - Member | Automatic | - |  |
| R3TEST.YOSEVYN | STAFF | Subsurface Development Area 1 | Subsurface Development Area 1 | Subsurface Development Area 1 - Modify - Member | Automatic | - |  |
| MK.AGUNG.SEDAYU | STAFF | Subsurface Development Area 2 | Subsurface Development Area 2 | Subsurface Development Area 2 - Modify - Member | Automatic | - |  |
| PHI.SDA2 | STAFF | Subsurface Development Area 2 | Subsurface Development Area 2 | Subsurface Development Area 2 - Modify - Member | Automatic | - |  |
| R3TEST.SDA2 | STAFF | Subsurface Development Area 2 | Subsurface Development Area 2 | Subsurface Development Area 2 - Modify - Member | Automatic | - |  |
| RETEST.EKA | STAFF | Subsurface Development Area 2 | Subsurface Development Area 2 | Subsurface Development Area 2 - Modify - Member | Automatic | - |  |

## F. Old-style SYSROLE, proposal needs confirming

| Retina ID | Position | Department today | Current SYSROLEs | Proposed SYSROLEs | At login | Regulator | Note |
|---|---|---|---|---|---|---|---|
| R3TEST.OSF |  | OSF | Read Only | Operations & Surface Facilities - Read - Guest | Automatic | - | From Read Only + users.department |
| R3TEST.AGUNGEKA | TEAM MEMBER | Operation & Surface Facilities | Team Member General | Operations & Surface Facilities - Modify - Member | Automatic | - | From Team Member General + users.department |
| R3TEST.VICEP | PROJECT OFFICER | Operation & Surface Facilities | Team Member General | Operations & Surface Facilities - Modify - Member | Automatic | - | From Team Member General + users.department |
| R3TEST.ALIF | TEAM MEMBER | Production Operations | Team Member General | Production Operations - Modify - Member | Automatic | - | From Team Member General + users.department |
| R3TEST.ARYA | TEAM MEMBER | Production Operations | Team Member General | Production Operations - Modify - Member | Automatic | - | From Team Member General + users.department |
| R3TEST.FADILA | TEAM MEMBER | Production Operations | Team Member General | Production Operations - Modify - Member | Automatic | - | From Team Member General + users.department |
| R3TEST.SM.SSDP | SENIOR MANAGER | Production Operations | Team Member General | Production Operations - Modify - Leader | Automatic | Keeps | Currently regulator with an old-style SYSROLE |
| R3TEST.TIAR | TEAM MEMBER | Production Operations | Team Member General | Production Operations - Modify - Member | Automatic | - | From Team Member General + users.department |
| R3TEST.AGIL | TEAM MEMBER | Project | Team Member General | Projects - Modify - Member | Automatic | - | From Team Member General + users.department |
| R3TEST.ALIEF | TEAM MEMBER | Project | Team Member General | Projects - Modify - Member | Automatic | - | From Team Member General + users.department |
| R3TEST.FADHILA | TEAM MEMBER | Project | Team Member General | Projects - Modify - Member | Automatic | - | From Team Member General + users.department |
| R3TEST.FADIL | TEAM MEMBER | Project | Team Member General | Projects - Modify - Member | Automatic | - | From Team Member General + users.department |
| R3TEST.FADILARDHI | TEAM MEMBER | Project | Team Member General | Projects - Modify - Member | Automatic | - | From Team Member General + users.department |
| R3TEST.JORDI | TEAM MEMBER | Project | Team Member General | Projects - Modify - Member | Automatic | - | From Team Member General + users.department |
| R3TEST.PROJECT | PROJECT MANAGER | Project | Project Manager | Projects - Modify - Leader | Automatic | Gains | Project Manager assumed to be Leader |
| R3TEST.RINALDY | TEAM MEMBER | Project | Team Member General | Projects - Modify - Member | Automatic | - | From Team Member General + users.department |

## G. Old-style SYSROLE, no proposal

| Retina ID | Position | Department today | Current SYSROLEs | Proposed SYSROLEs | At login | Regulator | Note |
|---|---|---|---|---|---|---|---|
| R3TEST.FIELDINSPECTOR | STAFF | Field Inspector | Field Inspector |  | SUBFUNGSI + merge | - | Stays old-style and gets merged permissions, or assign a department |

## E. No SYSROLE on record

These 56 users have no SYSROLE in dev session data, so nothing can be proposed. They are listed in the CSV.

| App role | Users |
|---|---|
| Vendor | 35 |
| Super Admin | 13 |
| Field Inspector | 3 |
| Coordinator | 2 |
| AEContract | 1 |
| Production Operations | 1 |
| Project | 1 |

## Stored department values to clean up

Dev has stored values outside the five departments: `OSF` and `Projects` (1 user each), and `Field Inspector` (1 user). The mapping needs to accept them or the data needs correcting.
