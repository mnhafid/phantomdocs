# Work Order: test cases and test users

Test cases first, then the users for the test. Update the "Result" column after each test run.
Source of the rules: `01-Decision-Log.md` and `02-Knowledge.md`. Endpoints: `03-Endpoint-Plan.md`.

---

## 1. Test cases: built endpoints

| # | Endpoint | Given | When | Then | Result |
|---|---|---|---|---|---|
| T1 | Overview #1 | 6 seed WOs (PR #1530 seed), login `r3test.tiar` (Production Operations) | `GET /work-order/zone9/overview` | `total_wo` 6, `received_wo` 4, `in_review` 2, `submit_wo` 1, `rejected_wo` 1, `draft_wo` 1 | Pass (PR #1533 curl) |
| T2 | Overview #1 | – | `GET /work-order/bogus/overview` | 400, code `02` §11, "Invalid working area" | Pass (PR #1530 curl) |
| T3 | List #2 | WO `0007` OSF → PO still at Level 0 | `GET /work-order/zone9?flow_type=incoming` | `0007` is not in the list; count 4 | Pass (PR #1533 curl) |
| T4 | List #2 | – | `flow_type=incoming&status=approved` | only `0005`; `approve_date` set | Pass (PR #1533 curl) |
| T5 | List #2 | – | `recipient=Production Operations&sort_column=approve_date&sort_order=asc&page_size=2` | 2 rows, count 4 | Pass (PR #1533 curl) |
| T6 | List #2 | – | `flow_type=both` | 400, code `02` §11 | Pass |
| T7 | List #2 | – | `field_id=` (empty) | Today 500. After fix G16: no filter, 200 | Open |
| T8 | List #2 | – | `page_size=500` | max 100 rows | To test |
| T9 | Draft #6 | user with a department and a short name | `POST /work-order/draft` with `{}` | 200, `status` `draft`, next WO number, Level 0 / Layer 0, no approvers, one `created` history row | Unit test only |
| T10 | Draft #6 | – | `wo_number` already used (Action Plan or WO) | 422 | To test |
| T11 | Draft #6 | – | `urgency_level` "Urgent"; end date before start date; date "31-31-2026"; unknown field / route / PIC | 400, code `02` §11, nothing saved | Unit test only |
| T12 | Draft #6 | user with no department | save draft | 400 "no department" | Unit test only |
| T13 | Draft + list | my draft | list Outgoing (me), Incoming (me), Outgoing (other user, same department) | 1 row, 0 rows, 0 rows; `draft_wo` = 1 | Unit test only |
| T14 | Draft + list | draft with no field | list `phss` / `pep` | not shown; shown in `zone9` | To test |
| T15 | Update draft #7 | my draft | update with a new title and no PICs | title changed, PICs removed, WO number unchanged | Unit test only |
| T16 | Update draft #7 | – | unknown id; another user's draft; a submitted WO | 404; 403; 400 | Unit test only |

### 1.1 Create Work Order form (built 25 Nov, `WorkOrderFormTests.cs`, 29 WO unit tests pass)

| # | Given | When | Then | Result |
|---|---|---|---|---|
| T17 | FE multipart form | parse | `wbs`, `pic_ids`, `budget_type` array (1 value), numbers and action plan key read; 2 budget types or a bad id = 400 | Unit test |
| T18 | route with Layer 1 + Layer 2 users | Save As Draft with 2 files | number taken, draft Level 0 / 0, 2 approver rows (stage 1), 2 files uploaded, `created` history | Unit test |
| T19 | a draft | Update with edited `approvers` and 1 file | route replaced by the edited step (SLA 2 days = 48 h), 2 files total, number unchanged | Unit test |
| T20 | a draft, `request_to` = `po` | Create with `id` | `waiting_approval`, Level 0 / Layer 1, `schedule_kind` simple, snapshot has the action plan key; PO user sees it in Incoming only after Level 0 | Unit test |
| T21 | category `choke_adjustment` | Create with no approvers | `waiting_approval` at Level 0 / Layer 1, no approver rows (25 Nov: Create does nothing on approval) | Unit test |
| T22 | – | Create with no title / `request_to` = a name / `budget_type` = "ABI BD" / field outside the path working area | 400, nothing saved (no approvers is not an error since 25 Nov) | Unit test |
| T23 | draft with 4 files | add 2 more; add an `.exe` | "at most 5 files"; type refused | Unit test |
| T24 | requestor department without a short name (for example a Field department) | Save As Draft | 400 "no work order short name" (G32) | To test |
| T25 | requestor from Project / OSF / PO / Drilling / WLI | Save As Draft | 200, wo_number `NNNN/WO/{PROJECTS\|OSF\|PO\|DRILLING\|WLI}/{year}` | To test |

### 1.2 Create WO scenarios (WO-T05, curl run 25 Nov)

`POST /api/v1/work-order/{working_area}`, multipart. Users: `phi.wo.po.pic` (creator), `phi.wo.po.senior` (another PO user). PHSS field `8248bb0c-…`, PEP field `a3988f9d-…`.
Required to submit: title, description, urgency_level, request_to, field_id, start_date, end_date.
The draft checks (404 / 403 / 400) run before the field checks.
Full curl and responses: `07-Ticket.md` WO-T05, run 2.

**A. Pass (200).** After each one: `waiting_approval`, Level 0 / Layer 1, `submitted_at` set, one `submitted` history row, no new approver rows.

| # | Scenario | Expected | Result |
|---|---|---|---|
| A1 | New WO on `phss`, `request_to=osf` | Next number, counter +1, `schedule_kind` project | Pass |
| A2 | Create from my draft that has approvers | Same id and number; counter not moved; the draft approver rows stay | Pass (approver rows: open decision) |
| A4 | `request_to=po` | `schedule_kind` simple | Pass |
| A5 | Category with no approval (`choke_adjustment`) | Still `waiting_approval`, no skip | Pass |
| A6 | `zone9` with a PEP field | 200 (zone9 takes every field) | Pass |
| A7 | `pep` with a PEP field | 200 | Pass |
| A8 | `wo_number` = the number from `/next-number` | That number | Pass |
| A9 | 2 files (PDF + PNG) | `attachment_count` 2 | Pass |
| A10 | Draft with 2 files + 3 new files on Create | `attachment_count` 5 | Pass |
| A11 | All optional fields (wbs, budget_type, rkap_id, area_id, location, function, type_service, pic_ids, 6 numbers) | All stored, 2 PIC rows | Pass |

**B. Validation (400).**

| # | Scenario | Expected message | Result |
|---|---|---|---|
| B1 | No description | `Required to submit: description` | Pass |
| B2 | Only title | All 6 missing names in one message | Pass |
| B3 | end_date before start_date | `end_date must be on or after start_date` | Pass |
| B4 | start_date `2026-12-01` | 400 not DD-MM-YYYY | Was 200 in the run. **Fixed 25 Nov (4c0a5580):** WO dates take only dd-MM-yyyy; unit tests added (not run yet) |
| B5 | `request_to=xyz` | not a Request To code | Pass |
| B6 | `budget_type=["other"]` | must be one of … | Pass |
| B7 | Title of 256 characters | at most 255 | Pass |
| B8 | Unknown field_id / rkap_id | was not found | Pass |
| B9 | Unknown user in pic_ids | pic_ids not found | Pass |
| B10 | PHSS field on `pep` | not in working area pep | Pass |
| B11 | `working_area=abc` | Invalid working area | Pass |
| B12 | 6 files | at most 5 files | Pass |
| B13 | `.exe` file / empty file | type refused / larger than 0 | Pass |
| B14 | `wo_number` of another department | must be NNNN/WO/PO/2026 | Pass |
| B15 | `wo_number` ahead of the next number | is ahead of the next number | Pass |
| B16 | User with no department | `Your account has no department` | Unit test only (no such WO test user) |
| B17 | Department with no short name | no work order short name | Unit test only (T24) |
| B18 | JSON body | must be multipart/form-data | Pass |

**C. Draft owner and state.**

| # | Scenario | Expected | Result |
|---|---|---|---|
| C1 | Draft of another user | 403 | Pass |
| C2 | Unknown id | 404 | Pass |
| C3 | Create the same draft two times | Second call 400 (not a draft) | Pass |

**D. Number conflict.**

| # | Scenario | Expected | Result |
|---|---|---|---|
| D1 | `wo_number` already used (`0001/WO/PO/2026`) | 422 | Pass (text says "another action plan") |

## 2. Test cases: flows to build (from the decisions)

| # | Flow | Given | When | Then |
|---|---|---|---|---|
| F1 | Submit #8 | draft with all mandatory fields and a Level 0 route | submit | Waiting Approval, Level 0 / Layer 1, approvers copied from the route (stage 1) |
| F2 | Submit #8 | category with no approval | submit | Approved at Level 1, no steps (R1) |
| F3 | Level 0 approve #15 | Senior of the requestor department | approve, then the Manager approves | Layer 1 → Layer 2 → Level 1 Waiting Approval |
| F4 | Senior requestor | the requestor is a Senior | Level 0 Layer 1 | **another** Senior reviews; no skip |
| F5 | Level 0 modify #17 | Level 0 approver | Layer 1 modify | status Modification Review at Level 0 Layer 2; Manager approves → Level 1, rejects → proposal dropped (TD23) |
| F6 | Level 0 reject #18 | Level 0 approver | reject with remarks | Rejected, final (X3) |
| F7 | Set Approval Flow #21 | Level 1, Waiting Approval | select a route of "Work Order - {target department}" | steps copied; page shows only Modify and Reject; Approve still works without a flow |
| F8 | Level 1 modify #17/#19 | flow set | Senior modifies → target Manager approves → requestor Manager refuses | proposal dropped; WO Approved with the old values (X5) |
| F9 | Level 1 reject #18/#20 | flow set | Senior → target Manager "Yes, Reject" → requestor Manager refuses | back to the Senior with `no_reject`; Reject button hidden (D3b) |
| F10 | Transfer #24 | Level 1 Approved, user with the transfer permission | transfer to a department (+ sub-unit for a Field) | Waiting Approval at Level 2; the assigned department sets its flow |
| F11 | Transfer #24 | Level 2 | transfer | 400; no second transfer |
| F12 | Disposition #25 | Approved | ABI/BD from OSF | 400 (ABI/BD only Projects and PO) |
| F13 | Project | disposition done | create the project, approve it, finish all schedules | WO On Going → Completed |
| F14 | Permission listing | a layer with permission X | `GET /users/by-permission/X?department=` | only users of the department of that Level; no action is blocked by permission |

## 3. Negative cases from the first review (check them against the new decisions before use)

| # | Given | When | Then |
|---|---|---|---|
| N1 | A WO in `l1`, user = Requestor | POST approve via the API | 403; status unchanged; no log row |
| N2 | A WO in `r1` with the "rejection not approved" block | The Senior Officer calls reject via the API (the button is hidden) | 400/409; Reject is also blocked server-side (BR-7) |
| N3 | Reject dialog | Reason = 3 spaces, or 501 characters | Submit is disabled / 400 "reason is required" / "max 500" |
| N4 | Upload | 6th file; an 11 MB PDF; an `.exe` renamed to `.pdf` | "Maximum 5 files"; "file is larger than 10 MB"; rejected by content type, not only the extension |
| N5 | WBS input | "12a", "12 3", duplicate "123", paste "123,456" | Only digits accepted; duplicate ignored; paste behaviour defined |
| N6 | WO form | End Date < Start Date | Submit blocked (BR-3). Today the design does **not** block it (M4) |
| N7 | (removed by D7: finish may skip result params) | | |
| N8 | Schedule | Predecessors "1" on task 1; "2FS+3d" where 2 is the parent; a cycle 2→3→2; "9" (missing); "2XX" | The exact errors from FR-9, one per case; Submit disabled |
| N9 | Transfer at `dis2` (Lvl 2 Approved) | API call to transfer | 400 "Lvl 2 cannot transfer" (BR-9) |
| N10 | Request To changed from PO Z9 to Drilling after picking Well Test | | Category cleared; Action Plan step removed; Submit (not Next) shown |
| N11 | Target Well from another Field/Area (tampered payload) | Submit | 400 (BR-4 enforced server-side) |
| N12 | A WO number already issued | A second create in the same counter scope at the same time | Distinct numbers; no duplicates (counter lock) |
| N13 | Manager Lvl 1 user | Opens a WO modified at Lvl 2 via a direct URL to View Changes | 403, or the Lvl 2 diff is hidden |
| N14 | Disposition with no PIC, or Transfer with no Department | Submit | Field error; button disabled (BR-10) |
| N15 | A deactivated user is the pending approver | Notification sent | Defined fallback (G5); the WO is not stuck |

---

## 4. Test users

### 4.1 Users given by the user (24 Nov)
- mk.agung.sedayu - drilling dan projects
- mk.agung.ekawahyu - existing dan tambah sysrole
- mk.melinda - manager
- mk.dany.pradana
- mk.arief.feryanto
- tester1.zona9
- tester2.zona9
- tester3.zona9

### 4.2 WO test set (seeded on dev, 25 Nov)
Status: **seeded on the dev database** (25 Nov). Login is mock auth (`mock_auth_sessions`); the password is ignored.
- Seed file: `sql/seed_wo_test_users.sql` (in this folder, gitignored). It is generated by `sql/gen_wo_seed.py` from the `phirbac.role.*` mock rows. Re-runnable (`WHERE NOT EXISTS`).
- The same file adds the WO privileges **273–279** (groups 31 "Work Order", 32 "Work Order Approval") to `permissions` / `permission_groups`.
- Not in the repo yet. Move it to `src-be/DataAccess/Database/` in a WO PR when you want it there.

**Decisions (user, 25 Nov)**
1. The Manager SYSROLE is `{Dept} - Approval Manager`: 2 parts ("Department - Action"), not `- Approval - Leader`. `SysRolePattern` (phi-dev) accepts 2 parts. "Manager" is not a regulator keyword, so a Manager is not a regulator.
2. WO privileges: 273–279 (no clash with the NEW tab). Added on dev.
3. The 13 users are enough. No field-department users.
4. The prefix `phi.wo.*` is OK.

---

### 4.3 What dev had before the seed (24 Nov)

- **`phi.*` (9 users):** each has one old-style SYSROLE (the department name). `phi.po`, `phi.approver` and `phi.superadmin` have 161–163.
- **`phirbac.role.*` (41 users, GUID `…501–541`):** PHI-2119 SYSROLE pattern. These are the test cases for the department picker. **Do not change them.**
- **No SYSROLE could tell a Senior from a Manager.** Now the Manager has `{Dept} - Approval Manager`.

---

### 4.4 SYSROLEs for each department

| SYSROLE | Who | WO privileges (SEQ) |
|---|---|---|
| `{Dept} - Modify - Member` | Requestor / PIC | 273 Read, 274 Create / Submit, 275 Process (disposition PIC, finish) |
| `{Dept} - Approval - Member` | Senior / Asst. Manager (Layer 1) | 273 Read, 276 Approve Layer 1, 278 Set Approval Flow, 279 Transfer |
| `{Dept} - Approval Manager` | Manager (Layer 2) | 273 Read, 277 Approve Layer 2 |
| `{Dept} - Read - Guest` | View only (negative test) | 273 Read |

- Every user also has 159 (Read Data Config) and the normal read ACL of the matching `phirbac.role.*` user of that department.
- SYSROLE department names: `Production Operations`, `Operations & Surface Facilities`, `Projects`, `Subsurface Development Area 1`. `SysRolePattern` maps `Projects` → `Project` and `Operations & Surface Facilities` → `Operation & Surface Facilities` (the `users.department` values).

---

### 4.5 Users (seeded)

Test path: **PO (requestor, Level 0) → OSF (target, Level 1) → Projects (assigned after a Transfer, Level 2)**. SDA 1 is a second requestor, for the Action Plan entry point. Log in with the username (any password).

| # | Username | `users.id` | `users.department` | Position | SYSROLE | WO SEQ | Test role |
|---|---|---|---|---|---|---|---|
| 1 | `phi.wo.po.pic` | `…601` | Production Operations | STAFF | Production Operations - Modify - Member | 273, 274, 275 | Level 0 requestor: create, draft, submit, attachments |
| 2 | `phi.wo.po.senior` | `…602` | Production Operations | SENIOR | Production Operations - Approval - Member | 273, 276, 278, 279 | Level 0 Layer 1: approve / modify / reject |
| 3 | `phi.wo.po.senior2` | `…603` | Production Operations | SENIOR | Production Operations - Approval - Member | 273, 276, 278, 279 | Second Senior. A Senior who is the requestor is reviewed by **another** Senior (no skip). Also checks the "any user with the permission" list. |
| 4 | `phi.wo.po.manager` | `…604` | Production Operations | MANAGER | Production Operations - Approval Manager | 273, 277 | Level 0 Layer 2: approve; check a target change ("Modification OK?"); accept / refuse a rejection |
| 5 | `phi.wo.osf.pic` | `…605` | Operation & Surface Facilities | STAFF | Operations & Surface Facilities - Modify - Member | 273, 274, 275 | Disposition PIC (internal): Create Project, Finish |
| 6 | `phi.wo.osf.senior` | `…606` | Operation & Surface Facilities | SENIOR | Operations & Surface Facilities - Approval - Member | 273, 276, 278, 279 | Level 1 Layer 1: Approve, Set Approval Flow, Modify, Reject, Transfer, Create Disposition |
| 7 | `phi.wo.osf.manager` | `…607` | Operation & Surface Facilities | MANAGER | Operations & Surface Facilities - Approval Manager | 273, 277 | Level 1 Layer 2: approve a Modify; confirm a Reject ("Yes, Reject / No, Cancel") |
| 8 | `phi.wo.prj.pic` | `…608` | Project | STAFF | Projects - Modify - Member | 273, 274, 275 | Level 2 disposition PIC |
| 9 | `phi.wo.prj.senior` | `…609` | Project | SENIOR | Projects - Approval - Member | 273, 276, 278, 279 | Level 2 Layer 1: Set Approval Flow, Approve / Modify / Reject, Disposition (no Transfer) |
| 10 | `phi.wo.prj.manager` | `…610` | Project | MANAGER | Projects - Approval Manager | 273, 277 | Level 2 Layer 2 |
| 11 | `phi.wo.sda1.pic` | `…611` | Subsurface Development Area 1 | STAFF | Subsurface Development Area 1 - Modify - Member | 273, 274, 275 | Second requestor (SSDP → PO), for the Action Plan link |
| 12 | `phi.wo.osf.guest` | `…612` | Operation & Surface Facilities | STAFF | Operations & Surface Facilities - Read - Guest | 273 | Negative: sees the WO, no buttons |
| 13 | `phi.wo.gm` | `…613` | Production Operations | GENERAL MANAGER | PO / OSF / Projects `- Approval Manager` (3 roles) | 273, 277 (each role) | Department picker: permissions change with the selected department only |

`users.id` = `0b000000-0000-0000-0000-000000000NNN`; the token `sub` = `00000000-0000-0000-0000-000000000NNN`.

**Existing users to reuse (no change):**
- `phi.superadmin`: Super Admin (sees all, Data Config approval routes).
- `phirbac.role.po.guest`: another read-only check.

---

### 4.6 Still to do for a full FE test
1. **Approval routes** in Data Config, for each department: "Work Order - Production Operations", "… - Operation & Surface Facilities", "… - Project". Each has Level 0 / 1 / 2, Layer 1 (276) / Layer 2 (277). Waits for the route-layer schema (`02` §1 G3).
2. **`/users/by-permission/{id}`** lists Retina-only ids only for 161–163 (`IsRetinaOnlyPermissionAsync`, fixed list). Add 273–279 (or read the list from config), or the approver lists stay empty.
3. **`custom_configurations`:** the WO config keys (`seed_work_order_config.sql` on `feat/work-order-draft`, plus schedule type, transfer list, Work Types). See `05` §3.
4. Users log in again after any ACL change (the session payload is read at login).
