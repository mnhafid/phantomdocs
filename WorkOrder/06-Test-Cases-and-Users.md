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

### 1.1 Create Work Order form (built 25 Nov, `WorkOrderFormTests.cs`, not run yet)

| # | Given | When | Then | Result |
|---|---|---|---|---|
| T17 | FE multipart form | parse | `wbs`, `pic_ids`, `budget_type` array (1 value), numbers and action plan key read; 2 budget types or a bad id = 400 | Unit test |
| T18 | route with Layer 1 + Layer 2 users | Save As Draft with 2 files | number taken, draft Level 0 / 0, 2 approver rows (stage 1), 2 files uploaded, `created` history | Unit test |
| T19 | a draft | Update with edited `approvers` and 1 file | route replaced by the edited step (SLA 2 days = 48 h), 2 files total, number unchanged | Unit test |
| T20 | a draft, `request_to` = `po` | Create with `id` | `waiting_approval`, Level 0 / Layer 1, `schedule_kind` simple, snapshot has the action plan key; PO user sees it in Incoming only after Level 0 | Unit test |
| T21 | category `choke_adjustment` | Create with no approvers | `approved` at Level 1, no approver rows | Unit test |
| T22 | – | Create with no title / no approvers / `request_to` = a name / `budget_type` = "ABI BD" / field outside the path working area | 400, nothing saved | Unit test |
| T23 | draft with 4 files | add 2 more; add an `.exe` | "at most 5 files"; type refused | Unit test |
| T24 | requestor department without a short name (for example a Field department) | Save As Draft | 400 "no work order short name" (G32) | To test |
| T25 | requestor from Project / OSF / PO / Drilling / WLI | Save As Draft | 200, wo_number `NNNN/WO/{PROJECTS\|OSF\|PO\|DRILLING\|WLI}/{year}` | To test |

## 2. Test cases: flows to build (from the decisions)

| # | Flow | Given | When | Then |
|---|---|---|---|---|
| F1 | Submit #8 | draft with all mandatory fields and a Level 0 route | submit | Waiting Approval, Level 0 / Layer 1, approvers copied from the route (stage 1) |
| F2 | Submit #8 | category with no approval | submit | Approved at Level 1, no steps (R1) |
| F3 | Level 0 approve #15 | Senior of the requestor department | approve, then the Manager approves | Layer 1 → Layer 2 → Level 1 Waiting Approval |
| F4 | Senior requestor | the requestor is a Senior | Level 0 Layer 1 | **another** Senior reviews; no skip |
| F5 | Level 0 modify #17 | Level 0 approver | modify | change saved and approved in one step; requestor gets a notification (X2) |
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

### 4.2 Planned WO test set
Status: **plan only**. Nothing is seeded. Made on 24 Nov from the dev database (`users`, `mock_auth_sessions`, read-only).

---

### 4.3 What dev has today

- **`phi.*` (9 users):** each has one old-style SYSROLE (the department name). `phi.po`, `phi.approver` and `phi.superadmin` have 161–163.
- **`phirbac.role.*` (41 users):** PHI-2119 SYSROLE pattern `{Dept} - {Modify|Read|Approval} - {Leader|Member|Guest}`. These are the test cases for the department picker. **Do not change them**, or the PHI-2119 tests break.
- **`r3test.*`:** mixed data. Many users have "Team Member General" only, and some have no department.
- **No user has a WO privilege**, because the WO privileges do not exist yet (`02` §9, numbers still open).
- **No SYSROLE can tell a Senior from a Manager.** The PHI-2119 pattern has only one approval role (`- Approval - Member`), but a WO needs Layer 1 (Senior) and Layer 2 (Manager).

**Proposal:** make a new, separate set `phi.wo.*`, for the WO test only.

---

### 4.4 SYSROLEs for each department (proposal)

| SYSROLE | Who | WO privileges (from `02` §9) |
|---|---|---|
| `{Dept} - Modify - Member` | Requestor / PIC (Layer 0) | Read WO, Create / Submit WO, Process WO (disposition PIC, finish) |
| `{Dept} - Approval - Member` | Senior / Asst. Manager (Layer 1) | Read WO, Approve Layer 1, Set Approval Flow, Transfer WO |
| `{Dept} - Approval - Leader` | Manager (Layer 2) | Read WO, Approve Layer 2 |
| `{Dept} - Read - Guest` | View only (negative test) | Read WO |

- `{Dept} - Approval - Leader` is **new**. It is not in the PHI-2119 minimum set of 4. Decide: add this SYSROLE, or give the Manager the Layer 2 privilege in another way.
- Each department uses the department name in the pattern: `Production Operations`, `Operations & Surface Facilities`, `Projects`, `Subsurface Development Area 1`.

---

### 4.5 Users (proposal)

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

### 4.6 What each user needs (seed list, after your OK)

For each `phi.wo.*` user:
1. A `users` row: `username`, `department`, `pos_name` / `position_name`, active. A literal GUID in the `0b000000-…-0000000005xx` range (next to the `phi.*` users at `…401–409`).
2. `mock_auth_sessions` rows (`stage = token` and `stage = session`). The session payload holds:
   - `SUBFUNGSI` = the department;
   - the SYSROLE;
   - the ACL `SEQ` list (the WO privilege ids, plus 159 Read Data Config, plus the department's normal read privileges).
   - Copy the shape from a `phirbac.role.*` row.
3. After the WO privileges get their numbers (`02` §9, P1), put those SEQs in the payloads. Until then the users can log in, but they get no WO access.

Also:
- **Approval routes** in Data Config, for each department: "Work Order - Production Operations", "… - Operation & Surface Facilities", "… - Project". Each has Level 0 / 1 / 2, Layer 1 / 2, and the permission ID of each layer.
- **`custom_configurations`:** the WO config keys (Request To list, categories, schedule type, transfer list, Work Types). See `05` §3.
- **A seed file:** `src-be/DataAccess/Database/seed_wo_test_users.sql`. Self-contained INSERTs with literal GUIDs and `WHERE NOT EXISTS`, so it can run more than once.

---

### 4.7 Decisions needed before the seed
1. Add the SYSROLE `{Dept} - Approval - Leader` for the Manager (Layer 2)? Or another way?
2. The WO privilege numbers (273+ or 164+). The payloads need them.
3. Is the set of 13 users enough, or do you also want field departments (PHSS Field, Sangasanga, …)? These have no `users.department` value today.
4. The username prefix `phi.wo.*`: OK?
