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

| #   | Scenario                                                                                                       | Expected                                                            | Result                              |
| --- | -------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- | ----------------------------------- |
| A1  | New WO on `phss`, `request_to=osf`                                                                             | Next number, counter +1, `schedule_kind` project                    | Pass                                |
| A2  | Create from my draft that has approvers                                                                        | Same id and number; counter not moved; the draft approver rows stay | Pass (approver rows: open decision) |
| A4  | `request_to=po`                                                                                                | `schedule_kind` simple                                              | Pass                                |
| A5  | Category with no approval (`choke_adjustment`)                                                                 | Still `waiting_approval`, no skip                                   | Pass                                |
| A6  | `zone9` with a PEP field                                                                                       | 200 (zone9 takes every field)                                       | Pass                                |
| A7  | `pep` with a PEP field                                                                                         | 200                                                                 | Pass                                |
| A8  | `wo_number` = the number from `/next-number`                                                                   | That number                                                         | Pass                                |
| A9  | 2 files (PDF + PNG)                                                                                            | `attachment_count` 2                                                | Pass                                |
| A10 | Draft with 2 files + 3 new files on Create                                                                     | `attachment_count` 5                                                | Pass                                |
| A11 | All optional fields (wbs, budget_type, rkap_id, area_id, location, function, type_service, pic_ids, 6 numbers) | All stored, 2 PIC rows                                              | Pass                                |

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

Scenario style, as in `../ActionPlan/08-ScenarioTest.md`: each test is a list of steps. After each step, check the WO state and who gets a notification.

**How to read a state line**
- `Status WO` = `work_orders.status`, then `L` = `current_level`, `Layer` = `current_layer`. Source: `02` §8.1a.
- `Process` = the `approval_processes` row of the Level (`Work Order Level 0 / 1 / 2`, `Work Order Reject Level 0`, TD21–TD22).
- `Notif` = the notification code of `03` §6.2 (all in-app, TD17).
- `Task` = the WO shows in "Waiting for my action" (`my-approval-list`) for these users only.

**Users** (§4.5): PO = requestor (Level 0), OSF = target (Level 1), Projects = assigned after a Transfer (Level 2).

| Short name | Username |
|---|---|
| PO PIC | `phi.wo.po.pic` |
| PO Senior / PO Senior 2 | `phi.wo.po.senior` / `phi.wo.po.senior2` |
| PO Manager | `phi.wo.po.manager` |
| OSF PIC / OSF Senior / OSF Manager / OSF Guest | `phi.wo.osf.pic` / `phi.wo.osf.senior` / `phi.wo.osf.manager` / `phi.wo.osf.guest` |
| PRJ PIC / PRJ Senior / PRJ Manager | `phi.wo.prj.pic` / `phi.wo.prj.senior` / `phi.wo.prj.manager` |

**Before every test**
- The 3 approval routes exist: "Work Order - Production Operations" (Level 0), "… - Operation & Surface Facilities" (Level 1), "… - Project" (Level 2). Layer 1 = permission 276, Layer 2 = 277 (§4.6 item 1).
- The reject route `wo_reject_level_0` exists for the PO department (TD21).
- `/users/by-permission/276?department=…` and `/277` return the users of §4.5 (§4.6 item 2).

Result words: **Pass**, **Fail**, **Blocked** (an endpoint is not built), **To test**.

---

### 2.1 Happy flow (Level 0 → Level 1 → Disposition → Project → Completed)

**Test #1. Case: Happy flow, target approves without a flow** · Result: Unit (to Level 1 approve): `Level1_ApproveWithoutFlow_ByAUserOfTheTargetDepartment` pass; disposition in `Transfer_ThenLevel2Approve_ThenDisposition`; project steps blocked (WO-T22); curl to test
- PO PIC creates a WO: `request_to=osf`, picks the Level 0 route, submits.
	- Status WO = `waiting_approval` · L0 · Layer 1
	- Process = `Work Order Level 0` open, level 1, `initiate` log
	- History = `submitted`
	- Notif N1 → PO Senior, PO Senior 2
	- Task = PO Senior, PO Senior 2. Not PO Manager, not OSF users.
	- List: PO PIC sees it in Outgoing. OSF users do **not** see it in Incoming yet.
- PO Senior approves.
	- Status WO = `waiting_approval` · L0 · Layer 2
	- Process = `approve` log, level 2
	- Notif N2 → PO Manager + PO PIC
	- Task = PO Manager only. It is gone from PO Senior 2 also.
- PO Manager approves.
	- Status WO = `waiting_approval` · **L1** · Layer 1
	- Process = `Work Order Level 0` `approved`
	- Notif N3 → OSF Senior. Notif N4 → PO PIC.
	- List: OSF users now see it in Incoming.
	- Detail (OSF Senior): buttons Approve, Set Approval Flow, Transfer. No Modify, no Reject (no flow yet).
- OSF Senior approves (no flow needed, TD2).
	- Status WO = `approved` · L1
	- Notif N8 → PO PIC
	- Detail (OSF Senior): buttons Transfer, Create Disposition.
- OSF Senior creates a disposition: Work Type `ABO Routine`, PIC = OSF PIC, notes.
	- Status WO = `project_preparation`
	- Notif N15 → OSF PIC + PO PIC
- OSF PIC creates a project from the WO (OSF = detail schedule).
	- Status WO = `project_approval`
	- `projects.work_order_id` = this WO
	- Notif N16 (in-app only, **no email**, TD17)
- The project approvers approve the project.
	- Status WO = `on_going`
	- Notif N17 → OSF PIC (in-app only)
- OSF PIC finishes all schedules.
	- Status WO = `completed`
	- Notif N19 → PO PIC + OSF Senior
- Expected: the overview cards and the list counts move on each step. History has one row per step, with the actor's level and layer (TD25).

**Test #1.1. Case: Senior requestor is reviewed by another Senior** · Result: To test
- PO Senior creates and submits a WO.
	- Status WO = `waiting_approval` · L0 · Layer 1
	- Task = PO Senior 2. PO Senior also sees it (has 276); check that the system does not skip Layer 1.
- PO Senior 2 approves, then PO Manager approves.
- Expected: same as Test #1 from Level 1. No layer is skipped (decision: no Senior skip).

**Test #1.2. Case: Bulk approve** · Result: Unit: `ApproveBulk_ApprovesWhatPasses_ListsTheRest` pass; curl to test
- PO PIC submits 3 WOs. PO Senior selects all 3 and clicks Approve Selected.
- Expected: each WO goes to `waiting_approval` · L0 · Layer 2. One N2 for each WO. A WO that is not at the user's step is skipped and listed in the response.

**Test #1.3. Case: Project from an Action Plan WO** · Result: To test
- SDA 1 PIC (`phi.wo.sda1.pic`) makes a well Action Plan that needs a WO (`request_to=po`).
- Follow Test #1 to the disposition. PO is a simple schedule.
- Expected: Create Project → Status WO = `on_going` at once (project approval skipped). `pep/phss_action_plan` has the WO link.

---

### 2.2 Level 0 Modify (TD23)

**Test #2. Case: Senior modifies, Manager approves the change** · Result: Unit: `Level0Modify_ManagerApproves_AppliedAndLevel1_ManagerRejects_BackToLayer1` pass; curl to test
- PO PIC submits a WO.
- PO Senior clicks Modify, changes the end date and the description.
	- Status WO = `modification_review` · L0 · Layer 2
	- History = `modified` (proposal snapshot). The WO itself keeps the old values.
	- Notif N5 → PO Manager + PO PIC
	- Detail (PO Manager): banner "Work Order modified by [PO Senior]" + View Changes.
- PO Manager opens View Changes: old and new values side by side. Buttons Export, Reject, Modify, Approve.
- PO Manager clicks Approve.
	- Status WO = `waiting_approval` · **L1** · Layer 1
	- The new end date and description are in the WO.
	- Notif N3 → OSF Senior
- Expected: OSF users see the new values. A reader outside the requestor side does not see the Level 0 `modified` row text (TD26).

**Test #2.1. Case: Manager rejects the change** · Result: Unit: same test (back to Layer 1, G34 to confirm) pass; curl to test
- Same as Test #2 to View Changes. PO Manager clicks Reject (with remarks).
	- Proposal dropped. The WO keeps the old values.
	- Status WO = `waiting_approval` · L0 (layer: open point G34)
	- Task = back to the step that G34 decides.
- Expected: no change in the WO fields. History has a `reject` row for the proposal.

**Test #2.2. Case: Manager modifies again (Self Modify)** · Result: To test
- Same as Test #2 to View Changes. PO Manager clicks Modify, changes the title, saves.
	- Status WO = `waiting_approval` · **L1** · Layer 1
	- The WO has the Senior change **and** the Manager change.
	- Notif N3 → OSF Senior
- Expected: one modify step + one approve step in the history.

**Test #2.3. Case: Manager modifies with no Senior change** · Result: Unit: `Level0SelfModify_ByTheManager_AppliesAndGoesToLevel1` pass; curl to test
- PO PIC submits. PO Senior approves. PO Manager clicks Modify at `waiting_approval` · L0 · Layer 2.
- Expected: Status WO = `waiting_approval` · L1 · Layer 1, the change applied (Self Modify = modify + approve).

---

### 2.3 Level 0 Reject (TD21, reject route)

**Test #3. Case: Senior rejects, the reject route confirms** · Result: Unit: `Reject_ByLayer1_OpensTheRejectRound_NotFinal`, `RejectionConfirm_ByEveryRejectLevel_RejectsTheWorkOrder` pass; curl to test
- PO PIC submits a WO.
- PO Senior clicks Reject: reason (required, max 500), fields to revise (optional).
	- Status WO = `rejection_review` · L0
	- Process = `Work Order Reject Level 0` open (route `wo_reject_level_0`)
	- Task = the users of the reject route
- The reject route user(s) approve the rejection (all levels).
	- Status WO = `rejected` (final)
	- Process: reject process `approved`, `Work Order Level 0` `rejected`
	- Notif N6 → PO PIC, with the fields to revise
- Expected: no button on the WO. Requestor makes a new WO with a new number (G6 open: Figma shows "Revision").

**Test #3.1. Case: the reject route refuses** · Result: Unit: `RejectionCancel_GoesBackToTheLayerThatAsked_WithAFreshCopyOfItsApprovers` pass; curl to test
- Same as Test #3 to `rejection_review`. The reject route user refuses.
	- Status WO = `waiting_approval` · L0 · same layer
	- Process: reject process `rejected`; `Work Order Level 0` goes on
- Expected: PO Senior can approve or modify again.

**Test #3.2. Case: Manager rejects at Layer 2** · Result: Unit: same test (Manager rejects at Layer 2) pass; curl to test
- PO PIC submits. PO Senior approves. PO Manager clicks Reject.
- Expected: same as Test #3 from `rejection_review`.

---

### 2.4 Level 1 Set Approval Flow and Modify

**Test #4. Case: target Senior modifies, both Managers agree** · Result: Unit: `SetApprovalFlow_CopiesTheTargetRoute_OnlyOnce`, `Level1Modify_BothManagersApprove_TheProposalIsApplied` pass; curl to test
- Follow Test #1 to `waiting_approval` · L1 · Layer 1.
- OSF Senior clicks Set Approval Flow, picks "Work Order - Operation & Surface Facilities".
	- Status WO = `waiting_approval` · L1 (no change)
	- Process = `Work Order Level 1` open
	- Detail (OSF Senior): only Modify and Reject show. **Check:** Approve still works by the API without a flow (TD2).
	- Approver list shows OSF users only (TD16). No PO user.
- OSF Senior clicks Modify, changes the schedule dates.
	- Status WO = `modification_review` · L1 · Layer 2
	- Proposal kept; the WO keeps the old values
	- Task = OSF Manager
- OSF Manager approves the change.
	- Status WO = `modification_review` · **L0** · Layer 2
	- Notif N9 → PO Manager ("Modification Verification")
	- Task = PO Manager
- PO Manager clicks "Modification OK".
	- Status WO = `approved` · L1, the proposal is copied into the WO
	- Notif N10 → PO PIC + OSF users
- Expected: the history shows each step. PO PIC sees the new values.

**Test #4.1. Case: target Manager refuses the change** · Result: Unit: `Level1Modify_TargetManagerRejects_BackToTheSenior` pass; curl to test
- Same as Test #4 to `modification_review` · L1 · Layer 2. OSF Manager refuses.
- Expected: Status WO = `waiting_approval` · L1 · Layer 1, proposal dropped, old values.

**Test #4.2. Case: requestor Manager refuses the change** · Result: Unit: `Level1Modify_RequestorManagerRejects_ApprovedWithTheOldValues` pass; curl to test
- Same as Test #4 to `modification_review` · L0 · Layer 2. PO Manager clicks "Not OK".
- Expected: Status WO = `approved` · L1 with the **old** values. Proposal dropped (X5). No N10.

---

### 2.5 Level 1 Reject (two confirmations)

**Test #5. Case: both Managers agree to reject** · Result: Unit: `Level1Reject_BothManagersAccept_Rejected` pass; curl to test
- Follow Test #4 to Set Approval Flow.
- OSF Senior clicks Reject (reason).
	- Status WO = `rejection_review` · L1 · Layer 2
	- Notif N11 → OSF Manager
- OSF Manager clicks "Yes, Reject".
	- Status WO = `rejection_review` · **L0** · Layer 2
	- Task = PO Manager
- PO Manager accepts the rejection.
	- Status WO = `rejected` (final)
	- Notif N12 → PO PIC + all levels
- Expected: no button on the WO.

**Test #5.1. Case: target Manager cancels** · Result: To test
- Same as Test #5 to `rejection_review` · L1. OSF Manager clicks "No, Cancel".
- Expected: Status WO = `waiting_approval` · L1 · Layer 1. OSF Senior can act again.

**Test #5.2. Case: requestor Manager refuses the rejection** · Result: Unit: `Level1Reject_RequestorManagerRefuses_NoRejectAfterwards` pass; curl to test
- Same as Test #5 to `rejection_review` · L0. PO Manager refuses.
	- Status WO = `waiting_approval` · L1 · Layer 1, `no_reject` = true
- OSF Senior opens the WO.
	- Detail: Approve and Modify only. **No Reject button.**
	- API: `POST …/reject` → 400 (the block is also on the server).
- OSF Senior approves.
- Expected: Status WO = `approved` · L1.

---

### 2.6 Transfer and Level 2

**Test #6. Case: transfer to Projects, Level 2 approves** · Result: Unit: `Transfer_ThenLevel2Approve_ThenDisposition` pass (Level 2 flow not in the test); curl to test
- Follow Test #1 to `approved` · L1.
- OSF Senior clicks Transfer: department = Projects (from the OSF list), sub-unit / PIC (open point: Figma has PIC, team doc has sub-unit), notes optional.
	- Status WO = `waiting_approval` · **L2** · Layer 1 (TD15)
	- Notif N13 → PRJ Senior. Notif N14 → PO PIC.
	- List: Projects users see it in Incoming.
- PRJ Senior: Set Approval Flow "Work Order - Project" (Level 2 process: open point 3 of `02` §8.1a), then Approve.
	- Status WO = `approved` · L2
	- Detail (PRJ Senior): Create Disposition. **No Transfer button.**
- PRJ Senior creates a disposition (Work Type `ABI/BD`, PIC = PRJ PIC).
	- Status WO = `project_preparation`
- Expected: from here as Test #1 (project, on going, completed).

**Test #6.1. Case: Level 2 modify is hidden from Level 1** · Result: To test
- Same as Test #6 to Level 2. PRJ Senior sets the flow and modifies.
- Expected: the same Modify steps as Test #4 (PRJ Manager, then PO Manager). OSF readers outside the Level 2 side do not see the Level 2 proposal text in the history (TD26).

**Test #6.2. Case: no second transfer** · Result: Unit: same test pass; curl to test
- At `approved` · L2, call `POST …/transfer` by the API as PRJ Senior.
- Expected: 400. Status WO does not change.

---

### 2.7 Disposition rules

**Test #7. Case: Work Type by department** · Result: Unit: ABI/BD + ABI/NBD for Projects in `Transfer_ThenLevel2Approve_ThenDisposition` pass; other rows curl to test

| Disposition by | Work Type | Expected |
|---|---|---|
| OSF | ABO Routine / ABO Non Routine | 200 |
| OSF | ABI/NBD | 200 |
| OSF | ABI/BD | 400 (only Projects and PO) |
| Projects | ABI/BD | 200 |
| Projects | ABI/NBD | 400 (only OSF) |
| PO | ABI/BD | 200 |

- Also check: no PIC → field error, button disabled (N14).

---

### 2.8 Permission and visibility (negative)

**Test #8. Case: users who must not act** · Result: To test

| User | WO state | Try | Expected |
|---|---|---|---|
| PO PIC (requestor) | `waiting_approval` · L0 · Layer 1 | Approve by the API | 403, no change, no log row |
| PO Manager | `waiting_approval` · L0 · Layer 1 | Approve (not their layer yet) | 400 / 403 |
| PO Senior (has 276) | `waiting_approval` · L1 (OSF WO) | Approve | 403. The permission counts only in the department of the Level (TD16) |
| OSF Guest (273 only) | any | Open the detail | Sees the WO, no action buttons |
| OSF Senior | `waiting_approval` · L0 | Open the detail | View only. Not in Incoming yet |
| `phi.wo.gm` (3 roles) | OSF WO at L1 | Switch department PO → OSF | Buttons change with the selected department only |

- The backend does not check the permission ID for an action. It checks the WO status, the Level / Layer, and the copied approvers (decision 24 Nov). This table tests those checks.

---

### 2.9 Check on every step

- **Notification:** the users of the step that is due get it (`03` §6.2). The actor does not get a copy of their own action. In-app only, no email (TD17).
- **Task:** the WO is in "Waiting for my action" only for the users of the current Level and Layer. It leaves the list for all of them when one user acts.
- **List tabs:** Outgoing = requestor department. Incoming = target / assigned department, only **after** Level 0 is done.
- **Overview cards:** the counts move with the status (`02` §8.1a).
- **Buttons:** only the buttons of the current state show (Approve; Set Approval Flow; Modify / Reject after the flow; Transfer at L1 Approved; Create Disposition at Approved).
- **History:** one row per action, with the actor's level and layer (TD25). Hidden rows keep their place with blank remarks (TD26).
- **Approver list:** `GET /users/by-permission/{id}?department=` returns only users of the department of that Level (TD16).
- **Export:** always shown on the detail, on every level (G35).

---

### 2.10 Short list (first draft, 24 Nov)

Kept for reference. The scenarios above replace it. Notes on rows that later decisions changed:
- F2: 25 Nov WO-T05 has no "no approval" skip. Open whether Submit skips later (R1, Q24).
- F5: the Manager review is TD23 (Test #2).
- F6: a Level 0 reject now goes through the reject route (TD21, Test #3). It is not final at once.

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

> **Changed 27 Nov (TD35, TD36):** prod uses `{Dept} - WO - Modify` (273, 274, 275), `{Dept} - WO - Approval` (273, 277, 278, 279), `{Dept} - WO - Guest` (273), and the existing department roles get the same sets. One approval layer: no `Approval Manager` role. The approve SEQ is 277; 276 is not used (TD37). The dev test users below still use the old roles; regenerate them when the code moves to one layer.

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
2. **`/users/by-permission/{id}`:** done 26 Nov (staged). 273–279 are Retina-only in code (`WorkOrderPermissions`), and `?department=` filters by `users.department`.
3. **`custom_configurations`:** the WO config keys (`seed_work_order_config.sql` on `feat/work-order-draft`, plus schedule type, transfer list, Work Types). See `05` §3.
4. Users log in again after any ACL change (the session payload is read at login).
