# Decisions

Part of [PHI-2119](README.md). Agreed on 2026-11-09. IDs match the `Rule` tags in [06-e2e-scenarios.feature](06-e2e-scenarios.feature).

## Reading a SYSROLE

| ID | Decision | Why |
|---|---|---|
| **D1** | The format is `Department - name - level`, split on ` - `. A name with fewer than 3 segments does not follow the pattern. | Matches the new Retina naming. |
| **D2** | The pattern lives in one code helper first, holding the separator, department segment and regulator keywords. It moves to a custom config row, `organization.sysrole_pattern`, later. | Fastest to ship. Keeping the same settings makes the later move a small change. A broken config must never push users into merge-all. |
| **D3** | `Projects` maps to stored `Project`, and `Operations & Surface Facilities` maps to stored `Operation & Surface Facilities`. The other three names are unchanged. | Stored names are in about 15 tables, so mapping avoids a data migration for now. |
| **D4** | The full rename of stored department names is a separate later ticket. | It is a risky migration that should not hold up the picker. |
| **D5** | Old-style SYSROLEs are ignored when the user also holds a patterned one. | One leftover role must not undo the narrowing. |

## Department at login

| ID | Decision | Why |
|---|---|---|
| **D6** | Patterned SYSROLEs decide the department. SUBFUNGSI is only used when the user holds none. | Keeps department and permissions consistent. |
| **D7** | A user with one department gets it automatically and sees no picker. | There is nothing to choose. |
| **D8** | A user with 2 or more departments is cleared at every login and must pick. | Reuses the existing GM and SM mechanism, so it is the fastest option. Remembering the last pick can be added later. |
| **D9** | GM, SM and Super Admin keep picking from today's list. | They choose across departments they may not hold a SYSROLE for. |

## Permissions

| ID | Decision | Why |
|---|---|---|
| **D10** | A department gives the union of every SYSROLE under it, and nothing from other departments. | Modify and Approval are complementary. |
| **D11** | Merge-all applies whenever no SYSROLE follows the pattern, before and after a pick, including GM and SM. | Old-style users keep working, so Retina does not need converting before the backend ships. |
| **D12** | 159-only applies to a user with patterned SYSROLEs who has not picked yet, and to a pick where they hold no SYSROLE for that department. | Stays strict once a user is on the new naming. |
| **D13** | Super Admin stays merged. A Super Admin from another system does not count. | Existing behaviour from PHI-2119. |

## Regulator

| ID | Decision | Why |
|---|---|---|
| **D14** | A SYSROLE containing `super admin` or `leader`, anywhere and in any case, in **any** department makes the user regulator of their current department. | Chosen explicitly: a Leader in one department is regulator of whichever they pick. |
| **D15** | This applies to everyone, on every login and pick, and is removed when the SYSROLE is gone. It replaces the `pos_name` Manager/Staff check. | One rule with no position exceptions. |
| **D23** | GM and SM are Leaders: they are assigned `{Dept} - Modify - Leader` in Retina, which makes them regulators. | Confirmed 2026-11-09. Today they are not regulators. |

## SYSROLE set

| ID | Decision | Why |
|---|---|---|
| **D16** | Each department has at least 4 SYSROLEs: Leader, Member, Guest and Approval. Names are `{Dept} - Modify - Leader`, `{Dept} - Modify - Member`, `{Dept} - Read - Guest` and `{Dept} - Approval - Member`. | Requested minimum. The names follow the examples given, such as `Operations & Surface Facilities - Approval - Member`. |

## Frontend and API

| ID | Decision | Why |
|---|---|---|
| **D17** | `/users/profile`, login and POST responses do not change. The existing `GET /api/v1/users/me/department/options` becomes per-user with the same response shape. | No response changes that are not needed. |
| **D18** | BE returns options only for users who can choose, otherwise `[]`. A non-empty list shows Switch Workspace, and with an empty department it forces the pick. This replaces the MANAGER check. | One simple FE rule. |
| **D19** | The list is built on the BE and FE renders it, with a lookup for title, logo and group. | The pattern and mapping stay in one place. |
| **D20** | A department outside the known five is offered with the Phantom logo under "Other". | A user holding that SYSROLE should be able to choose it. |
| **D21** | BE rejects a pick the user does not hold, except for GM, SM and Super Admin. | Filtering options on the FE alone would not stop a direct POST. |

## Ticket requirement

| ID | Decision | Why |
|---|---|---|
| **D22** | The logo keeps the existing FE fallback to the general Phantom logo, with a null guard added on `organisation`. | Required by PHI-2119 and already almost complete. |
