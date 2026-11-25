# Work Order: test users for the FE (plan)

Status: **plan only**. Nothing is seeded. Made on 24 Nov from the dev database (`users`, `mock_auth_sessions`, read-only).

---

## 1. What dev has today

- **`phi.*` (9 users):** each has one old-style SYSROLE (the department name). `phi.po`, `phi.approver` and `phi.superadmin` have 161–163.
- **`phirbac.role.*` (41 users):** PHI-2119 SYSROLE pattern `{Dept} - {Modify|Read|Approval} - {Leader|Member|Guest}`. These are the test cases for the department picker. **Do not change them**, or the PHI-2119 tests break.
- **`r3test.*`:** mixed data. Many users have "Team Member General" only, and some have no department.
- **No user has a WO privilege**, because the WO privileges do not exist yet (`09`, numbers still open).
- **No SYSROLE can tell a Senior from a Manager.** The PHI-2119 pattern has only one approval role (`- Approval - Member`), but a WO needs Layer 1 (Senior) and Layer 2 (Manager).

**Proposal:** make a new, separate set `phi.wo.*`, for the WO test only.

---

## 2. SYSROLEs for each department (proposal)

| SYSROLE | Who | WO privileges (from `09`) |
|---|---|---|
| `{Dept} - Modify - Member` | Requestor / PIC (Layer 0) | Read WO, Create / Submit WO, Process WO (disposition PIC, finish) |
| `{Dept} - Approval - Member` | Senior / Asst. Manager (Layer 1) | Read WO, Approve Layer 1, Set Approval Flow, Transfer WO |
| `{Dept} - Approval - Leader` | Manager (Layer 2) | Read WO, Approve Layer 2 |
| `{Dept} - Read - Guest` | View only (negative test) | Read WO |

- `{Dept} - Approval - Leader` is **new**. It is not in the PHI-2119 minimum set of 4. Decide: add this SYSROLE, or give the Manager the Layer 2 privilege in another way.
- Each department uses the department name in the pattern: `Production Operations`, `Operations & Surface Facilities`, `Projects`, `Subsurface Development Area 1`.

---

## 3. Users (proposal)

Test path: **PO (requestor, Level 0) → OSF (target, Level 1) → Projects (assigned after a Transfer, Level 2)**. SDA 1 is a second requestor, for the Action Plan entry point.

| # | Username | `users.department` | Position | SYSROLE | Test role |
|---|---|---|---|---|---|
| 1 | `phi.wo.po.pic` | Production Operations | STAFF | Production Operations - Modify - Member | Level 0 requestor: create, draft, submit, attachments |
| 2 | `phi.wo.po.senior` | Production Operations | SENIOR | Production Operations - Approval - Member | Level 0 Layer 1: approve / modify / reject |
| 3 | `phi.wo.po.senior2` | Production Operations | SENIOR | Production Operations - Approval - Member | Second Senior. A Senior who is the requestor is reviewed by **another** Senior (no skip). Also checks the "any user with the permission" list. |
| 4 | `phi.wo.po.manager` | Production Operations | MANAGER | Production Operations - Approval - Leader | Level 0 Layer 2: approve; check a target change ("Modification OK?"); accept / refuse a rejection |
| 5 | `phi.wo.osf.pic` | Operation & Surface Facilities | STAFF | Operations & Surface Facilities - Modify - Member | Disposition PIC (internal): Create Project, Finish |
| 6 | `phi.wo.osf.senior` | Operation & Surface Facilities | SENIOR | Operations & Surface Facilities - Approval - Member | Level 1 Layer 1: Approve, Set Approval Flow, Modify, Reject, Transfer, Create Disposition |
| 7 | `phi.wo.osf.manager` | Operation & Surface Facilities | MANAGER | Operations & Surface Facilities - Approval - Leader | Level 1 Layer 2: approve a Modify; confirm a Reject ("Yes, Reject / No, Cancel") |
| 8 | `phi.wo.prj.pic` | Project | STAFF | Projects - Modify - Member | Level 2 disposition PIC |
| 9 | `phi.wo.prj.senior` | Project | SENIOR | Projects - Approval - Member | Level 2 Layer 1: Set Approval Flow, Approve / Modify / Reject, Disposition (no Transfer) |
| 10 | `phi.wo.prj.manager` | Project | MANAGER | Projects - Approval - Leader | Level 2 Layer 2 |
| 11 | `phi.wo.sda1.pic` | Subsurface Development Area 1 | STAFF | Subsurface Development Area 1 - Modify - Member | Second requestor (SSDP → PO), for the Action Plan link |
| 12 | `phi.wo.osf.guest` | Operation & Surface Facilities | STAFF | Operations & Surface Facilities - Read - Guest | Negative: sees the WO, no buttons |
| 13 | `phi.wo.gm` | (picks) | GENERAL MANAGER | the 3 departments' `- Approval - Leader` | Department picker: permissions change with the selected department only |

**Existing users to reuse (no change):**
- `phi.superadmin`: Super Admin (sees all, Data Config approval routes).
- `phirbac.role.po.guest`: another read-only check.

---

## 4. What each user needs (seed list, after your OK)

For each `phi.wo.*` user:
1. A `users` row: `username`, `department`, `pos_name` / `position_name`, active. A literal GUID in the `0b000000-…-0000000005xx` range (next to the `phi.*` users at `…401–409`).
2. `mock_auth_sessions` rows (`stage = token` and `stage = session`). The session payload holds:
   - `SUBFUNGSI` = the department;
   - the SYSROLE;
   - the ACL `SEQ` list (the WO privilege ids, plus 159 Read Data Config, plus the department's normal read privileges).
   - Copy the shape from a `phirbac.role.*` row.
3. After the WO privileges get their numbers (`09`, P1), put those SEQs in the payloads. Until then the users can log in, but they get no WO access.

Also:
- **Approval routes** in Data Config, for each department: "Work Order - Production Operations", "… - Operation & Surface Facilities", "… - Project". Each has Level 0 / 1 / 2, Layer 1 / 2, and the permission ID of each layer.
- **`custom_configurations`:** the WO config keys (Request To list, categories, schedule type, transfer list, Work Types). See `15` §3.
- **A seed file:** `src-be/DataAccess/Database/seed_wo_test_users.sql`. Self-contained INSERTs with literal GUIDs and `WHERE NOT EXISTS`, so it can run more than once.

---

## 5. Decisions needed before the seed
1. Add the SYSROLE `{Dept} - Approval - Leader` for the Manager (Layer 2)? Or another way?
2. The WO privilege numbers (273+ or 164+). The payloads need them.
3. Is the set of 13 users enough, or do you also want field departments (PHSS Field, Sangasanga, …)? These have no `users.department` value today.
4. The username prefix `phi.wo.*`: OK?
