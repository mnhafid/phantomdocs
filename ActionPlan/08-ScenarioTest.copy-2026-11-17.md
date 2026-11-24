
## Happy flow 
#### PROCESS
Test #1 
Case: Happy Flow
Given:
- SSDP make action plan and submit to PIC on PO department
	- Status ACTION PLAN = need_review
	- Status Approval = Waiting Review From PO
- PO will get notif on task list and notif center
- PO  approve ACTION PLAN
	- Status ACTION PLAN = on_schedule
	- Status Approval = approved
- Action plan change status show on list of action plan
- Expected: `approved`; SSDP gets "Well Test In Progress" / "Artificial Lift In Progress"

#### Approve with Modify
Case: Happy Flow
Test #2
Given:
- SSDP make action plan and submit
- PO will get notif on task and notif center
- PO will modify and add approval route
	- Status ACTION PLAN = modify_in_approval
	- Status Approval = waiting_approval_level_1
- Manager 1 get notif on task and notif center
- Manager level 1 will approve
	- Status ACTION PLAN = routing
	- Status Approval = waiting_approval_level_2
- Manager 2 get notif on task and notif center
- Manager level 2 will approve
	- Status ACTION PLAN = routing
	- Status Approval = waiting_approval_level_ssdp
- SSDP 1 get notif on task and notif center
- SSDP will approve 
	- Status ACTION PLAN = on_schedule
	- Status Approval = approve
- Proceed and status action plan
- PO get notif center


Test #2.1 
Case: Manager Rejected and Back to PO 
Given:
- SSDP make action plan and submit
- PO will get notif on task and notif center
- PO will modify and add approval route
- Manager 1 get notif on task and notif center
- Manager level 1  Reject
	- Status ACTION PLAN = need_review  
	- Status Approval = waiting_review  
	- Drop data Propose
- PO will get notif on task and notif center
	- Need to check that user has awareness this AC already reviewed and rejected

Test #2.2
Case:
Given
- SSDP make action plan and submit
- PO will get notif on task and notif center
- PO will modify and add approval route
- Manager 1 get notif on task and notif center
- Manager level 1 approve
- Manager 2 get notif on task and notif center
- Manager level 2 reject
	- Status ACTION PLAN = need_review  
	- Status Approval = waiting_review  
	- Drop data Propose

#### Reject
Test #3
Case: Manager 1 and 2 Approve to Reject
Given
- SSDP make action plan and submit
- PO will get notif on task and notif center
- PO will reject and add approval route
- Manager 1 get notif on task and notif center
- Manager level 1 approved to reject
	- Status ACTION PLAN = rejected and routing
	- Status Approval = waiting_approval_level_2  
- Manager 2 get notif on task and notif center
- Manager level 2 approved to reject
	- Status ACTION PLAN = rejected
	- Status Approval = approved  

Test #3.1
Given
- SSDP make action plan and submit
- PO will get notif on task and notif center
- PO will reject and add approval route
- Manager 1 get notif on task and notif center
- Manager level 1 ask PO to modify
	- Status ACTION PLAN = need_review
	- Status Approval = waiting_review  

Test #3.2
Given
- SSDP make action plan and submit
- PO will get notif on task and notif center
- PO will modify and add approval route
- Manager 1 get notif on task and notif center
- Manager level 1 will approve to Reject
- Manager 2 get notif on task and notif center
- Manager level 2 ask PO to modify
	- Status ACTION PLAN = need_review
	- Status Approval = waiting_review  


Given
- SSDP make action plan without approval (choke, sonolog, others, artificial lift that is not WHC installation) and submit
- Expected: `approved` at once, no WO number, no notification, no task for PO

Given
- SSDP make artificial lift WHC installation and submit
- PO will get "Artificial Lift Request" on task and notif center
- PO will approve (execution department / PIC optional, required only for well test)
- Expected: `approved`; SSDP gets "Artificial Lift In Progress"
- Same with PO modify: last (SSDP) level gets "Artificial Lift Installation has been modified by <department>"

Given
- Repeat flow 1 and flow 2 on PHSS (`/action-plans/phss`)
- Expected: same status and notifications as PEP

## Check on every step

- Notification: PO pool on submit and on every "back to PO"; the approvers of the level that is due; SSDP submitter on `approved`
- Task: PO sees the plan in `need-action?stage=review` / `my-task-list` only while `waiting_review` / `modify_returned`; each level only on its turn
- Visibility (PHI-2442): plan with WO visible only to its PICs with view permission (153 / 155); others do not see it in the list, detail = 400 "Action plan not found"
- View only (PHI-2442): `can_review` / `can_approve` / `can_reject` false for anyone not on the pending level
