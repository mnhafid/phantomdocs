# FSD: department picker and permissions from SYSROLE names

Part of [PHI-2119](README.md). Requirements are in [02-PRD.md](02-PRD.md). Code references are to `phi-dev` and `phantom-fe` as of 2026-11-09.

## 1. Current behaviour

| Area | Today | Where |
|---|---|---|
| Who picks | POSNAME contains senior or general manager, or a Super Admin SYSROLE | `DepartmentPickerWhitelist` |
| Login | Pickers are cleared and everyone else gets SUBFUNGSI | `AuthService.ApplyLoginDepartmentAsync` |
| Options | Every `regulator of {dept}` role, the same for all users | `ManagerDepartmentService.GetDepartmentOptionsAsync` |
| Permissions | SYSROLE name must equal the department, else 159 | `DepartmentSysRoleAcl.Narrow` |
| Regulator | `pos_name` Manager or Staff | `DepartmentPickerWhitelist.UsesRegulatorCopy` |
| FE picker | `position_name` = MANAGER, with hard-coded cards | `stores/user.ts:69`, `MainLayout.vue:177` |

## 2. SYSROLE parser (new)

New static class `SysRolePattern` in `Logics/Services/Permissions`. It holds the only copy of these settings, so they can move to custom config later.

```csharp
Separator = " - "; DepartmentSegment = 0; MinSegments = 3;
RegulatorKeywords = ["super admin", "leader"];
DepartmentAliases = { "Projects" → "Project", "Project" → "Project",
                      "Operations & Surface Facilities" → "Operation & Surface Facilities" };
```

| Member | Result |
|---|---|
| `TryGetDepartment(sysRole, out stored)` | False under 3 segments. Otherwise the first segment, trimmed and passed through the aliases |
| `Departments(roles, appName)` | Distinct stored departments from this app's patterned SYSROLEs |
| `RolesFor(department, roles, appName)` | This app's SYSROLEs under that department |
| `IsRegulator(roles, appName)` | Any of this app's SYSROLEs contains a keyword, ignoring case |

All matching ignores case and only uses roles whose `SysName` equals the app name.

## 3. Login

`ApplyLoginDepartmentAsync` becomes:

| Order | Condition | Department | Returns picker |
|---|---|---|---|
| 1 | Existing `ChoosesOwnDepartment` (GM, SM, Super Admin) | Cleared | Yes |
| 2 | 2 or more patterned departments | Cleared | Yes |
| 3 | Exactly 1 patterned department | That department | No |
| 4 | None | SUBFUNGSI, as today | No |

Case 3 replaces the SUBFUNGSI department and keeps the subdivision update.

Every authenticated request passes `R3ComponentFilter`, which returns 401 for a user with no department. That check also lets through a user whose SYSROLEs span 2 or more departments, otherwise a picker could not load the app before picking. Retina is only asked on this no-department path.

A user with no Phantom SYSROLE at all is rejected earlier, by the existing application gate at login.

## 4. Permissions

`DepartmentSysRoleAcl` works out the set in this order:

| Order | Condition | Result |
|---|---|---|
| 1 | Holds a Super Admin SYSROLE for this app | Normal merge |
| 2 | No patterned SYSROLE, including GM and SM before or after a pick | Merge all, minimum 159 |
| 3 | Current department has SYSROLEs under it | Union of those SYSROLEs |
| 4 | Anything else (not picked yet, or no match) | 159 only |

The decision uses the SYSROLEs in the Retina response, and the DB read only supplies the current department.

`NarrowForDepartmentAsync` makes one scoped `GetUserAppData` call per SYSROLE under the department, because the default call may not return every role's ACL for a multi-role user. A failed call stays non-fatal.

`PopulateAsync` drops the cache for every user whose set depends on the department, or `/users/permissions` would briefly return too much.

The old path that read Retina for the "regulator of {dept}" role is removed. A regulator role no longer decides where permissions come from.

## 5. Regulator

A new private step runs after `AssignDepartmentRoleAsync` at login, so that step cannot overwrite it, and again in `ChooseDepartmentAsync`.

| Current state | Action |
|---|---|
| `IsRegulator` true and department is set | Assign `regulator of {department}`, replacing any other, using the existing path in `ChooseDepartmentAsync` |
| `IsRegulator` true and no department yet | Clear for now. It is assigned on the pick |
| `IsRegulator` false | `ClearRegulatorRoleAsync` |

`UsesRegulatorCopy` and `RegulatorCopyPosNames` are removed once nothing uses them.

The role lookup is `"regulator of " + department`, using the stored name. A missing role is auto-created with cloned permissions, as it is today.

## 6. API

`GET /api/v1/users/me/department/options`. Shape unchanged: `[{ "department": "...", "division": null }]`.

| User | Returned |
|---|---|
| GM, SM, Super Admin | Today's regulator-role list |
| 2 or more patterned departments | Their departments, as stored names |
| Anyone else | `[]` |

`GetDepartmentTreeOptionsAsync` needs the caller's Retina roles, so it uses `R3UserSession` with `GetUserAppData`.

`POST /api/v1/users/me/department`. Shape unchanged. `ChooseDepartmentAsync` adds this guard before saving:

```
if user is not GM/SM/Super Admin and department is not in SysRolePattern.Departments(...)
    → throw InvalidOperationException
```

The cache is invalidated on a successful pick, as it is today.

`/users/profile` and login responses do not change.

## 7. Frontend

| File | Change |
|---|---|
| `services/user.service.ts` | Add `getDepartmentOptions()` |
| `stores/user.ts` | Add `departmentOptions`, loaded with the profile |
| `stores/user.ts:69` | `isNeedChooseTenant` = options non-empty and `!organisation?.department` |
| `layouts/MainLayout.vue:177` | `allowSwitchWorkspace` = options non-empty |
| `layouts/MainLayout.vue:199-217` | Optional chaining on `organisation` (D22) |
| `pages/ChooseTenant/Index.vue`, `SelectTenant*` | Show only groups with options, build cards from the list, skip the group step if there is only one |
| `SwitchWorkspace/Index.vue` | Build items from the list |

Options must finish loading before `checkUserDepartment` runs, because that guard is synchronous. If they arrive late, a user who needs to pick gets through.

A lookup supplies display data:

| Stored value | Title | Logo | Group |
|---|---|---|---|
| `Project` | Projects | Zona 9 | PnP |
| `Production Operations` | Production & Operation | PO | PnP |
| `Operation & Surface Facilities` | OSF | OSF | PnP |
| `Subsurface Development Area 1` | SDA 1 | SDA 1 | SSDP |
| `Subsurface Development Area 2` | SDA 2 | SDA 2 | SSDP |
| Anything else | The department name | Phantom | Other |

A new department also needs adding to `EnumUserDepartment` for route guards and sidebar items to treat it correctly.

## 8. Worked example

User holds `Projects - Read - Guest`, `Operations & Surface Facilities - Modify - Member` and `Operations & Surface Facilities - Approval - Member`.

| Step | Result |
|---|---|
| Login | 2 departments, so `department` is cleared |
| Options | `Project`, `Operation & Surface Facilities` |
| `/users/permissions` before picking | 159 only |
| Pick OSF | Department stored, cache dropped |
| `/users/permissions` | Union of the two OSF SYSROLEs |
| Regulator | None, no Leader SYSROLE |

## 9. Transition behaviour

The backend can ship before Retina is converted (D11). A GM or SM holding only old-style names, such as `Project`, falls under order 2 in section 4: they still pick a department, but their permissions are every SYSROLE merged and the pick does not narrow them. No temporary exact-name matching is added.

This ends per user, as soon as they hold a patterned SYSROLE. From then on, orders 3 and 4 apply and old-style SYSROLEs are ignored (D5).

## 10. Testing

Unit tests extend `DepartmentSysRoleAclTests` for the parser, each row of the tables in sections 3 to 5, and the pick guard. End-to-end coverage is in [06-e2e-scenarios.feature](06-e2e-scenarios.feature).
