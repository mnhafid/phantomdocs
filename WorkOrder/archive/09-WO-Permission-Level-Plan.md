# Work Order: plan for permissions

Status: **plan only**. Nothing is built. First checked on 24 Nov in the dev database (read-only), the code (`phi-dev`) and the RBAC sheet ("Phantom PHI Mapping" and "Phantom PHI - NEW" tabs). **Updated 24 Nov** with the user's decisions (TD11, TD13, TD16 in `00-Decision-Log.md`; `11-TeamDoc-Decisions-24Nov.md` §9–§12).

**Decisions that set this plan**
- Each layer of an approval route holds a **permission ID**. Every user with that permission can act on that layer.
- The permission counts **only in the department of its Level**. Example: a PO Senior with the permission does not review an OSF WO.
- **Backend rule:** the permission ID is used **only to list users** (`GET /api/v1/users/by-permission/{permissionId}`). The backend does **not** check it to allow or block an action.
- There is **no position check** and **no skip** when the requestor is a Senior. Another user with the Layer 1 permission reviews the WO.
- The route has Layer 1 and Layer 2 only. There is **no Layer 3**.

Words: see `00-Decision-Log.md` (Level, Layer).

---

## 1. What we have today

**Database (dev, 24 Nov)**
- `permissions`: the highest id is **163**. `permission_groups`: the highest id is **30**.
  - Group 29 "Action Plan": 160 Process Action Plan Request.
  - Group 30 "Action Plan Approval": 161 Review, 162 Approve, 163 Reject.
- The privileges 160–163 have **no casbin rows**. Only Retina gives them. Projects (54), SPK (58) and Contract (63) approval have casbin rows.
- **The system can list the holders** of 161–163. `GetUsersByPermissionAsync` (`UsersService.cs:510`) asks Retina (`RetinaUsersByAclQueryId`) for these ids, and it reads casbin for the other ids. (Correction: an earlier version of this file said that the system cannot list them.)
  - Limit 1: the Retina ids are a fixed list (`IsRetinaOnlyPermissionAsync`, `UsersService.cs:560`). A new WO permission that exists only in Retina must be added to that list.
  - Limit 2: the endpoint has **no department filter**. The WO flow must filter the list by the department of the Level.
- `users.pos_name` / `position_name` are not clean data (55 users have no position, mixed values, no "Senior / Asst. Manager" value). This does not matter now, because the system does not check the position.
- `users.department`: 65 users have no department. The data has duplicate names ("OSF" and "Operation & Surface Facilities"; "Project" and "Projects"). The department filter must handle these names.
- `approval_tierings` + `role_approval_tierings`: an old "approval level 1–3 for each role" table for Project, Contract, SPK and SPK BoQ Progress. Only the user profile shows it (`UsersService.cs:300`). The WO does not use it.
- `custom_configurations` has `action_plan_review_permission_id` (= 161) and `work_order_department_short_names`.

**RBAC sheet**
- "Phantom PHI Mapping" stops at **158**. It has no rows for 159 (Data Config), 160–163 (Action Plan) or any Work Order privilege.
- "Phantom PHI - NEW" uses the numbers **137–272** with other meanings (example: 161 = "Read Compressor Engine Type"). These numbers clash with the database. Each new WO privilege needs a number that is free in the database **and** in the NEW tab.
- The Retina roles are one SYSROLE for each department (`retina_department_roles.oracle.sql`). The permissions of a user = the SYSROLEs of the selected department.

---

## 2. Options (decided 24 Nov)

- **Option A: one permission for each layer, in the department of the Level.** **Chosen.** Retina gives the permission through the SYSROLE of the department. The route layer holds the permission ID.
- **Option B: reuse `approval_tierings`.** Not used. It is for each role, not for each department, and no flow reads it.
- **Option C: use the position (`pos_name`).** Rejected. The data is not clean, and the team does not want a position check.

---

## 3. Proposed permissions

New groups after 30. Number the new privileges from **273**, so that they do not clash with the NEW tab (see P1).

**Group 31 "Work Order"**
- 273 Read Work Order (View)
- 274 Create / Submit Work Order (Modify). The requestor.
- 275 Process Work Order (Modify). The PIC of Level 1 / Level 2: Disposition, Create Project, Finish.
- 278 Set Approval Flow (Modify). A user of the target or the assigned department selects the route of that department ("Set Approval Flow" window).
- 279 Transfer Work Order (Modify). A user of the target department transfers the WO to the assigned department.

**Group 32 "Work Order Approval"** (the layers)
- 276 Approve Work Order Layer 1 (SOP: Senior / Asst. Manager)
  - At Level 0: approve the submitted WO (Modify + Approve in one step is allowed).
  - At Level 1 / 2: Approve, or Modify / Reject after the route is set.
- 277 Approve Work Order Layer 2 (SOP: Manager)
  - At Level 0: approve the submitted WO. Check a Level 1 modification. Accept or refuse a rejection.
  - At Level 1 / 2: approve a Modify. Confirm a Reject ("Yes, Reject" / "No, Cancel").

**Rules**
- The route layer holds 276 or 277 (or another permission that the admin selects). The approvers = the users with that permission **in the department of the Level**.
- The backend uses the permission only to **list** the users. It does not check the permission on actions. The same rule applies to 278 and 279: they fill the list of who can act; they are not an access check.
- Layer 0 never approves.
- The Action Plan review pool (161) stays for the Action Plan. When the Action Plan uses the route of its WO, 161 becomes the Layer 1 Level 1 permission for PO.
- The project approval keeps the Project Approval privilege (54). An Action Plan WO skips the project approval.

---

## 4. Work to do (after the team agrees)
1. Add groups 31–32 and privileges 273–279 to `permissions` / `permission_groups` (seed SQL, one INSERT for each row, literal ids).
2. Add rows to the sheet:
   - "Phantom PHI Mapping": rows for 159–163 (missing now) and 273–279.
   - "PHI-NEW by Method": the View / Modify category.
3. Add the new privileges to the Retina SYSROLEs of each department that is a WO Level.
4. Add the new Retina-only ids to `IsRetinaOnlyPermissionAsync`, or make that list come from config.
5. Add a department filter to the user list (a new optional `department` query parameter on `/users/by-permission/{id}`, or a filter in the WO service).

---

## 5. Open questions
- **P1:** Which numbers? 273+ (no clash), or 164+ and renumber the NEW tab? **Open.**
- **P2:** Do we need "Approval Layer 3"? **Answered 24 Nov: no.** The route has Layer 1 and Layer 2 only.
- **P3:** How does the system list the holders of a layer? **Answered 24 Nov:** with `/users/by-permission/{id}` (casbin, or Retina for the listed ids), filtered by the department of the Level.
- **P4:** What if a layer has no user with the permission in that department? **Open.** Proposal: the system blocks the step and shows an error, so that the admin fixes the route or the Retina roles.
- **P5:** One user in two departments (GM / SM picker): does the permission count only in the selected department? **Partly answered (TD16):** it counts only in the department of the Level. Open: a GM / SM who holds the role in two departments is listed in both.
