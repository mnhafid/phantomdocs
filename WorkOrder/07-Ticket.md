# Work Order: tickets (business logic only)

Made on 25 Nov from `03-Endpoint-Plan.md` (§2 and §3).
Scope:
- Only the business logic of each endpoint: rules, checks, status changes, and results.
- Not here: FE, infra, seeds, permissions setup, notifications, and release steps. See `05-Production-Checklist.md` and `03` §6.

How to use this file:
- One ticket = one endpoint or one small group of endpoints.
- Each ticket has a **Test result** block: the test user, the date, the curl request, and the response. Fill it after a curl run on a local WebApi with the dev DB. A ticket is not "Done" without it.
- Put the Jira key in the "Jira" column when the ticket exists.
- Update the "Status" column when work moves.
- **PHI-2993** (25 Nov): the Jira ticket for WO-T01, T02, T04, T05 and T06 (branch `feat/work-order-draft`). Commit: `[PHI-2993] feat(work-order): …`.
- The curl test rows stay on dev (user, 25 Nov): 0001/WO/PO/2026 and 0002/WO/PO/2026 (waiting_approval), 0003/WO/PO/2026 (deleted draft). Do not remove them.

Status words: **Done** (merged on `phi-dev`), **Staged** (code written and staged, not committed), **Tested, staged** (curl test passed, not committed), **To do**, **Blocked** (needs a decision or another ticket first).

Common rules for all tickets (from `03` and the decisions):
- The backend uses the permission ID **only to list users**. It never allows or blocks an action by permission ID.
- An action is allowed by the **WO state**: the status, the current Level / Layer, and the user in the copied approvers of that step.
- Each action writes one row in `work_order_histories`.
- Levels: 0 = requestor department, 1 = target department, 2 = assigned department (after a Transfer).
- Layers: 1 = Senior / Asst. Manager, 2 = Manager.

---

## 1. Ticket list

| ID | Title | Endpoint (`03` #) | Depends on | Jira | Status |
|---|---|---|---|---|---|
| WO-T00 | Overview cards and list | #1, #2 | – | – | Done (#1530, #1533, #1539) |
| WO-T01 | Next WO number (preview) | #3 | WO-T20 (format) | PHI-2993 | Tested, staged |
| WO-T02 | Form options | #4 | – | PHI-2993 | Tested, staged |
| WO-T03 | Approval route for WO (layers + permission) | #5, §3.2 | – | | Skipped for now (25 Nov); WO uses the route as it is (TD18) |
| WO-T04 | Save draft and update draft | #6, #7 | – | PHI-2993 | Tested, staged |
| WO-T05 | Create (submit) WO, no approval logic | #8 | WO-T04 | PHI-2993 | Tested, staged |
| WO-T06 | Delete draft | #9 | WO-T04 | PHI-2993 | Tested, staged |
| WO-T07 | WO details and allowed actions | #10 | WO-T05 | | To do |
| WO-T08 | Approval history and modification comparison | #11 | WO-T05 | | To do |
| WO-T09 | Attachments: add and delete | #12, #13 | WO-T04 | | To do |
| WO-T10 | Approve and bulk approve | #15, #16 | WO-T05 | | To do |
| WO-T11 | Modify | #17 | WO-T10, WO-T15 | | To do |
| WO-T12 | Reject | #18 | WO-T10, WO-T15 | | To do |
| WO-T13 | Modification decision | #19 | WO-T11 | | To do |
| WO-T14 | Rejection decision | #20 | WO-T12 | | To do |
| WO-T15 | Set Approval Flow (Level 1 / 2) | #21 | WO-T03 | | To do |
| WO-T16 | Approvers of a step (users by permission + department) | #22, §3.1 | WO-T03 | | To do |
| WO-T17 | Transfer options and Transfer | #23, #24 | WO-T10 | | To do |
| WO-T18 | Disposition | #25 | WO-T10 | | To do |
| WO-T19 | Project prefill | #26 | WO-T18 | | To do |
| WO-T20 | WO number format from config | §3.3 | – | | To do |
| WO-T21 | Action Plan link to the WO | §3.4 | WO-T05 | | Blocked (Q15) |
| WO-T22 | Project changes for a WO project | §3.5 | WO-T19 | | To do |
| WO-T23 | My approval list: WO steps | §3.6 | WO-T10 | | To do |

---

## 2. Tickets

### WO-T01: Next WO number (preview)
`GET /work-order/next-number`
- Show the next WO number for the department of the user.
- Do not take the number. Only Save Draft and Create take it.
- Use the same counter as the Action Plan (`WorkOrderNumbers`). A WO and an Action Plan never share a number.
- Format comes from WO-T20.

Acceptance:
- Given a user of PO, when the user opens the form, then the result is the next PO number, and the counter does not change.

Code (25 Nov, `feat/work-order-draft`, staged): `WorkOrderFormService.GetNextNumberAsync`. Source: `work_order_sequences` (`last_seq` + 1 for the short name and year). Only when the year has no row yet, it counts the numbers already used by action plans and work orders. Dev, 25 Nov: SDA1/2026 `last_seq` 96 → next `0097/WO/SDA1/2026`; SDA2/2026 = 13. Only SDA1 / SDA2 have a short name on dev. Result `{ sequence_number, wo_number, department }`. A department with no short name gives 400.

Test result:
- Status: **Pass** (all cases give the expected result).
- User: phi.wo.po.pic. Both are Production Operations users from `mock_auth_sessions` on dev.
- Date: 25 Nov 2026. Local WebApi (`feat/work-order-draft`) on the dev DB, after `seed_work_order_config.sql`. Quartz kept in RAM for the run (local change, not staged).
- Cases:

**next number**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X GET "{{base_url}}/api/v1/work-order/next-number" -H "Authorization: Bearer <token of phi.wo.po.pic>"
```

```json
{
    "data": {
        "sequence_number": "0001",
        "wo_number": "0001/WO/PO/2026",
        "department": "Production Operations"
    },
    "process_time": "512.42ms",
    "status": "success",
    "code": "00",
    "message": "Get next work order number succeed"
}
```

**next number after a save (counter moved)**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X GET "{{base_url}}/api/v1/work-order/next-number" -H "Authorization: Bearer <token of phi.wo.po.pic>"
```

```json
{
    "data": {
        "sequence_number": "0002",
        "wo_number": "0002/WO/PO/2026",
        "department": "Production Operations"
    },
    "process_time": "338.63ms",
    "status": "success",
    "code": "00",
    "message": "Get next work order number succeed"
}
```


### WO-T02: Form options
`GET /work-order/form-options`
- Return in one call:
  - Request To (code + label). For each code, show if Category and Function are on.
  - Categories (and Functions) for each Request To.
  - Urgency levels.
  - Budget types: `abibd`, `abinbd`, `abo_routine`, `abo_non_routine`.
  - The categories that need no approval.
- Source: `custom_configurations`. The schedule kind is not in the result (the BE sets it on Create).

Acceptance:
- Given a Request To with Category off, then the result has no categories for it.

Code (25 Nov, staged): `WorkOrderFormService.GetFormOptionsAsync`. Result `{ request_to: [{ code, department }], budget_types, categories_without_approval }`.
- Gap: config has no urgency list and no categories for each Request To yet. The FE keeps them for now. The Category on / off rule is also not in config yet.

Test result:
- Status: **Pass** (all cases give the expected result).
- User: phi.wo.po.pic. Both are Production Operations users from `mock_auth_sessions` on dev.
- Date: 25 Nov 2026. Local WebApi (`feat/work-order-draft`) on the dev DB, after `seed_work_order_config.sql`. Quartz kept in RAM for the run (local change, not staged).
- Cases:

**form options**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X GET "{{base_url}}/api/v1/work-order/form-options" -H "Authorization: Bearer <token of phi.wo.po.pic>"
```

```json
{
    "data": {
        "request_to": [
            {
                "code": "osf",
                "department": "Operation & Surface Facilities"
            },
            {
                "code": "projects",
                "department": "Project"
            },
            {
                "code": "po",
                "department": "Production Operations"
            },
            {
                "code": "wli",
                "department": "WLI"
            },
            {
                "code": "phss_field",
                "department": "PHSS Field"
            },
            {
                "code": "sangatta_field",
                "department": "Sangatta Field"
            }
        ],
        "budget_types": [
            "abibd",
            "abinbd",
            "abo_routine",
            "abo_non_routine"
        ],
        "categories_without_approval": [
            "choke_adjustment",
            "sonolog_bjp_update",
            "artificial_lift_update",
            "maintenance_field",
            "modification"
        ]
    },
    "process_time": "83.74ms",
    "status": "success",
    "code": "00",
    "message": "Get work order form options succeed"
}
```


### WO-T03: Approval route for WO (layers + permission)
`GET /approval-routes?category=work_order&department_id=&search=&status=active`, `GET /approval-routes/{id}`, and the create / update of a route.
- A WO route has the category "Work Order - {Department}".
- Each step holds: Level (0 / 1 / 2), Layer (1 / 2), permission ID, SLA days.
- The admin can select any permission and any department. No position check.
- `GET /approval-routes/{id}` returns the steps and, for each layer, the users who hold the permission in the department of that Level (WO-T16 logic).
- Open: a new table or new columns on `approval_route_users` (`05` §7 item 2).

Acceptance:
- Given a route with Layer 1 = permission X, when PO has 2 users with X, then the route detail lists both users for Layer 1.

### WO-T04: Save draft and update draft
`POST /work-order/draft`, `POST /work-order/draft/{id}` (multipart form)
- Save Draft:
  - Status = Draft, Level 0, Layer 0.
  - Takes a real WO number (the number index is unique).
  - Saves the requestor PICs and the selected approvers. The approvers are not active in a draft.
  - Files in the same call: max 5 for each WO, 10 MB each, PDF / DOC / DOCX / XLS / XLSX / JPG / PNG.
  - Writes a "created" history row.
- Update Draft:
  - Only the creator (else 403). Only a Draft (else 400). Not found = 404.
  - Replaces every field, the PICs and the approvers. The WO number does not change.
- A draft shows only to its creator, only in Outgoing.

Acceptance:
- Given a draft of user A, when user B updates it, then the result is 403.

Test result:
- Status: **Pass** (all cases give the expected result).
- User: phi.wo.po.pic (creator), phi.wo.po.senior (not the creator). Both are Production Operations users from `mock_auth_sessions` on dev.
- Date: 25 Nov 2026. Local WebApi (`feat/work-order-draft`) on the dev DB, after `seed_work_order_config.sql`. Quartz kept in RAM for the run (local change, not staged).
- Cases:

**save draft**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/draft" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=WO\ curl\ test\ T04 -F description=Scope\ of\ works\ -\ curl\ test -F urgency_level=important -F request_to=osf -F category=well_test -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F start_date=01-12-2026 -F end_date=15-12-2026 -F budget_type=\[\"abo_routine\"\] -F wbs=\[\"101\"\] -F pic_ids=\[\"0b000000-0000-0000-0000-000000000601\"\]
```

```json
{
    "data": {
        "id": "e0fcfec9-6c8e-4e2e-9b64-2704363738c3",
        "wo_number": "0001/WO/PO/2026",
        "status": "draft",
        "current_level": 0,
        "current_layer": 0,
        "created_date": "25-11-2026",
        "attachment_count": 0
    },
    "process_time": "1432.12ms",
    "status": "success",
    "code": "00",
    "message": "Save work order draft succeed"
}
```

**update draft (owner)**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/draft/e0fcfec9-6c8e-4e2e-9b64-2704363738c3" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=WO\ curl\ test\ T04\ \(updated\) -F description=Scope\ of\ works\ -\ curl\ test -F urgency_level=important -F request_to=osf -F category=well_test -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F start_date=01-12-2026 -F end_date=15-12-2026 -F budget_type=\[\"abo_routine\"\] -F wbs=\[\"101\"\] -F pic_ids=\[\"0b000000-0000-0000-0000-000000000601\"\]
```

```json
{
    "data": {
        "id": "e0fcfec9-6c8e-4e2e-9b64-2704363738c3",
        "wo_number": "0001/WO/PO/2026",
        "status": "draft",
        "current_level": 0,
        "current_layer": 0,
        "created_date": "25-11-2026",
        "attachment_count": 0
    },
    "process_time": "1077.75ms",
    "status": "success",
    "code": "00",
    "message": "Update work order draft succeed"
}
```

**update draft (not the creator, 403)**: user `phi.wo.po.senior`, HTTP 403

```bash
curl -X POST "{{base_url}}/api/v1/work-order/draft/e0fcfec9-6c8e-4e2e-9b64-2704363738c3" -H "Authorization: Bearer <token of phi.wo.po.senior>" -F title=x -F description=Scope\ of\ works\ -\ curl\ test -F urgency_level=important -F request_to=osf -F category=well_test -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F start_date=01-12-2026 -F end_date=15-12-2026 -F budget_type=\[\"abo_routine\"\] -F wbs=\[\"101\"\] -F pic_ids=\[\"0b000000-0000-0000-0000-000000000601\"\]
```

```json
{
    "error_data": {
        "title": "Failed",
        "description": "Only the creator can change this work order draft",
        "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
        "primary_text": "OK",
        "secondary_text": "",
        "primary_link": "",
        "secondary_link": "",
        "dismissed_link": ""
    },
    "process_time": "166.20ms",
    "status": "failed",
    "code": "01",
    "message": "Only the creator can change this work order draft"
}
```

**update draft (not found, 404)**: user `phi.wo.po.pic`, HTTP 404

```bash
curl -X POST "{{base_url}}/api/v1/work-order/draft/00000000-0000-0000-0000-000000000001" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x -F description=Scope\ of\ works\ -\ curl\ test -F urgency_level=important -F request_to=osf -F category=well_test -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F start_date=01-12-2026 -F end_date=15-12-2026 -F budget_type=\[\"abo_routine\"\] -F wbs=\[\"101\"\] -F pic_ids=\[\"0b000000-0000-0000-0000-000000000601\"\]
```

```json
{
    "error_data": {
        "title": "Failed",
        "description": "Work order not found",
        "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
        "primary_text": "OK",
        "secondary_text": "",
        "primary_link": "",
        "secondary_link": "",
        "dismissed_link": ""
    },
    "process_time": "178.97ms",
    "status": "failed",
    "code": "01",
    "message": "Work order not found"
}
```

**update a submitted WO (400)**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/draft/e0fcfec9-6c8e-4e2e-9b64-2704363738c3" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x -F description=Scope\ of\ works\ -\ curl\ test -F urgency_level=important -F request_to=osf -F category=well_test -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F start_date=01-12-2026 -F end_date=15-12-2026 -F budget_type=\[\"abo_routine\"\] -F wbs=\[\"101\"\] -F pic_ids=\[\"0b000000-0000-0000-0000-000000000601\"\]
```

```json
{
    "error_data": {
        "title": "Failed",
        "description": "Only a draft can be changed; this work order is waiting_approval",
        "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
        "primary_text": "OK",
        "secondary_text": "",
        "primary_link": "",
        "secondary_link": "",
        "dismissed_link": ""
    },
    "process_time": "135.71ms",
    "status": "failed",
    "code": "01",
    "message": "Only a draft can be changed; this work order is waiting_approval"
}
```


### WO-T05: Create (submit) WO
`POST /work-order/{working_area}` (multipart form, with `id` of a draft or without it)
- Required: title, description, urgency level, Request To, field (in the working area of the path), start date, end date (end ≥ start).
- `request_to` stores the FE code. The code maps to a `users.department` value through config.
- `schedule_kind` = project for OSF and Projects, else simple. The user does not send it.
- **No approval logic (decision 25 Nov).** Create does not read `approvers` or `approval_route_id`, does not copy approver rows, and does not skip approval for any category.
- Result: status = Waiting Approval, Level 0, Layer 1. The approval tickets (WO-T10 and later) handle the next steps.
- A submitted draft keeps the approver rows that Save Draft stored. Create does not change them.
- Writes a "submitted" history row with a snapshot.
- **Later (TD20, with WO-T10):** Submit uses the chosen approval route: copy the steps to `work_order_approvers` and open the Level 0 `approval_processes` row (Layer 1). The code above stays until then.

Acceptance:
- Given any category (also one in `work_order.categories_without_approval`), when the user submits, then the status is Waiting Approval at Level 0 / Layer 1 and no approver rows are made.
- Given a missing title, when the user submits, then the result is 400 and no WO is saved.

Code (25 Nov, `feat/work-order-draft`, staged): `WorkOrderFormService.SubmitAsync` / `Promote`. Unit tests pass (29 WO tests).

Test result:
- Status: **Pass** (all cases give the expected result).
- User: phi.wo.po.pic. Both are Production Operations users from `mock_auth_sessions` on dev.
- Date: 25 Nov 2026. Local WebApi (`feat/work-order-draft`) on the dev DB, after `seed_work_order_config.sql`. Quartz kept in RAM for the run (local change, not staged).
- Cases:

**create from draft**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F id=e0fcfec9-6c8e-4e2e-9b64-2704363738c3 -F title=WO\ curl\ test\ T05\ \(from\ draft\) -F description=Scope\ of\ works\ -\ curl\ test -F urgency_level=important -F request_to=osf -F category=well_test -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F start_date=01-12-2026 -F end_date=15-12-2026 -F budget_type=\[\"abo_routine\"\] -F wbs=\[\"101\"\] -F pic_ids=\[\"0b000000-0000-0000-0000-000000000601\"\]
```

```json
{
    "data": {
        "id": "e0fcfec9-6c8e-4e2e-9b64-2704363738c3",
        "wo_number": "0001/WO/PO/2026",
        "status": "waiting_approval",
        "current_level": 0,
        "current_layer": 1,
        "created_date": "25-11-2026",
        "attachment_count": 0
    },
    "process_time": "953.50ms",
    "status": "success",
    "code": "00",
    "message": "Create work order succeed"
}
```

**create new, category without approval**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=WO\ curl\ test\ T05\ \(choke\) -F description=Scope -F urgency_level=important -F request_to=osf -F category=choke_adjustment -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F start_date=01-12-2026 -F end_date=15-12-2026
```

```json
{
    "data": {
        "id": "1eb03a01-670d-495a-ae4e-82fc6ab6723d",
        "wo_number": "0002/WO/PO/2026",
        "status": "waiting_approval",
        "current_level": 0,
        "current_layer": 1,
        "created_date": "25-11-2026",
        "attachment_count": 0
    },
    "process_time": "887.58ms",
    "status": "success",
    "code": "00",
    "message": "Create work order succeed"
}
```

**create without title (400)**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F description=Scope\ of\ works\ -\ curl\ test -F urgency_level=important -F request_to=osf -F category=well_test -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F start_date=01-12-2026 -F end_date=15-12-2026 -F budget_type=\[\"abo_routine\"\] -F wbs=\[\"101\"\] -F pic_ids=\[\"0b000000-0000-0000-0000-000000000601\"\]
```

```json
{
    "error_data": {
        "title": "Failed",
        "description": "Required to submit: title",
        "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
        "primary_text": "OK",
        "secondary_text": "",
        "primary_link": "",
        "secondary_link": "",
        "dismissed_link": ""
    },
    "process_time": "452.44ms",
    "status": "failed",
    "code": "01",
    "message": "Required to submit: title"
}
```

**create, field not in working area (400)**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/pep" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x -F description=Scope\ of\ works\ -\ curl\ test -F urgency_level=important -F request_to=osf -F category=well_test -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F start_date=01-12-2026 -F end_date=15-12-2026 -F budget_type=\[\"abo_routine\"\] -F wbs=\[\"101\"\] -F pic_ids=\[\"0b000000-0000-0000-0000-000000000601\"\]
```

```json
{
    "error_data": {
        "title": "Failed",
        "description": "field_id '8248bb0c-a37c-423c-9ce6-36c592f79906' is not in working area pep",
        "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
        "primary_text": "OK",
        "secondary_text": "",
        "primary_link": "",
        "secondary_link": "",
        "dismissed_link": ""
    },
    "process_time": "700.88ms",
    "status": "failed",
    "code": "01",
    "message": "field_id '8248bb0c-a37c-423c-9ce6-36c592f79906' is not in working area pep"
}
```


### WO-T06: Delete draft
`POST /work-order/{id}/delete`
- Soft delete.
- Only the creator (403). Only a Draft (400). Not found = 404.
- The WO number is not given back (a gap in the sequence is OK).
- Writes a "deleted" history row.

Code (25 Nov, staged): `WorkOrderFormService.DeleteDraftAsync`, history action `deleted`. A second delete gives 404.

Test result:
- Status: **Pass** (all cases give the expected result).
- User: phi.wo.po.pic (creator), phi.wo.po.senior (not the creator). Both are Production Operations users from `mock_auth_sessions` on dev.
- Date: 25 Nov 2026. Local WebApi (`feat/work-order-draft`) on the dev DB, after `seed_work_order_config.sql`. Quartz kept in RAM for the run (local change, not staged).
- Cases:

**save draft to delete**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/draft" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=WO\ curl\ test\ T06 -F description=Scope\ of\ works\ -\ curl\ test -F urgency_level=important -F request_to=osf -F category=well_test -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F start_date=01-12-2026 -F end_date=15-12-2026 -F budget_type=\[\"abo_routine\"\] -F wbs=\[\"101\"\] -F pic_ids=\[\"0b000000-0000-0000-0000-000000000601\"\]
```

```json
{
    "data": {
        "id": "ddf4b884-8d0e-4eea-9b92-9463a2cea4f4",
        "wo_number": "0003/WO/PO/2026",
        "status": "draft",
        "current_level": 0,
        "current_layer": 0,
        "created_date": "25-11-2026",
        "attachment_count": 0
    },
    "process_time": "3483.98ms",
    "status": "success",
    "code": "00",
    "message": "Save work order draft succeed"
}
```

**delete (not the creator, 403)**: user `phi.wo.po.senior`, HTTP 403

```bash
curl -X POST "{{base_url}}/api/v1/work-order/ddf4b884-8d0e-4eea-9b92-9463a2cea4f4/delete" -H "Authorization: Bearer <token of phi.wo.po.senior>"
```

```json
{
    "error_data": {
        "title": "Failed",
        "description": "Only the creator can change this work order draft",
        "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
        "primary_text": "OK",
        "secondary_text": "",
        "primary_link": "",
        "secondary_link": "",
        "dismissed_link": ""
    },
    "process_time": "1723.74ms",
    "status": "failed",
    "code": "01",
    "message": "Only the creator can change this work order draft"
}
```

**delete (owner)**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/ddf4b884-8d0e-4eea-9b92-9463a2cea4f4/delete" -H "Authorization: Bearer <token of phi.wo.po.pic>"
```

```json
{
    "data": {
        "id": "ddf4b884-8d0e-4eea-9b92-9463a2cea4f4",
        "wo_number": "0003/WO/PO/2026",
        "status": "draft",
        "current_level": 0,
        "current_layer": 0,
        "created_date": "25-11-2026",
        "attachment_count": 0
    },
    "process_time": "1071.24ms",
    "status": "success",
    "code": "00",
    "message": "Delete work order draft succeed"
}
```

**delete again (404)**: user `phi.wo.po.pic`, HTTP 404

```bash
curl -X POST "{{base_url}}/api/v1/work-order/ddf4b884-8d0e-4eea-9b92-9463a2cea4f4/delete" -H "Authorization: Bearer <token of phi.wo.po.pic>"
```

```json
{
    "error_data": {
        "title": "Failed",
        "description": "Work order not found",
        "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
        "primary_text": "OK",
        "secondary_text": "",
        "primary_link": "",
        "secondary_link": "",
        "dismissed_link": ""
    },
    "process_time": "555.77ms",
    "status": "failed",
    "code": "01",
    "message": "Work order not found"
}
```

**delete a submitted WO (400)**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/e0fcfec9-6c8e-4e2e-9b64-2704363738c3/delete" -H "Authorization: Bearer <token of phi.wo.po.pic>"
```

```json
{
    "error_data": {
        "title": "Failed",
        "description": "Only a draft can be changed; this work order is waiting_approval",
        "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
        "primary_text": "OK",
        "secondary_text": "",
        "primary_link": "",
        "secondary_link": "",
        "dismissed_link": ""
    },
    "process_time": "547.83ms",
    "status": "failed",
    "code": "01",
    "message": "Only a draft can be changed; this work order is waiting_approval"
}
```


### WO-T07: WO details and allowed actions
`GET /work-order/{id}`
- Return the header, the PICs, the attachments, the current Level / Layer, and the copied steps.
- Return the list of actions that this user can do now. Use the WO state only (status, Level / Layer, user in the copied approvers):
  - Level 0 Layer 1 / 2: Approve, Modify, Reject.
  - Level 1 / 2 with no approval flow: Approve, Set Approval Flow.
  - Level 1 / 2 with an approval flow: Approve, Modify, Reject (Reject hidden when `no_reject` = true).
  - Level 1 Approved: Transfer, Disposition. Level 2 Approved: Disposition only.
  - Modification Review / Rejection Review: the decision buttons, for the Manager of that step.

### WO-T08: Approval history and modification comparison
`GET /work-order/{id}/histories`
- Return each cycle: Received Date, Action Date, Duration, Remarks, actor.
- Return the Modification Comparison: the before and after value of each changed field.

### WO-T09: Attachments: add and delete
`POST /work-order/{id}/attachments`, `POST /work-order/{id}/attachments/{attachmentId}/delete`
- Max 5 files for each WO, 10 MB each, PDF / DOC / DOCX / XLS / XLSX / JPG / PNG.
- Delete = soft delete.
- Open: who can add or delete, and in which status (only the creator in Draft is the proposal).

### WO-T10: Approve and bulk approve
`POST /work-order/{id}/approve` { remarks }, `POST /work-order/approve/bulk` { ids[] }
- The user must be in the copied approvers of the current step.
- Level 0: Layer 1 → Layer 2. Layer 2 → Level 1, Waiting Approval.
- Level 1 / 2: the Senior approves. Status = Approved. This works without an approval flow.
- Bulk: approve each WO that passes the checks. Return the failed ids with the reason.
- Approval process (TD18): use the shared tables like the Action Plan: `approval_processes` (`reference_id` = WO id, flow `Work Order`), `approval_logs` (`initiate` / `approve` / `reject`), `approval_process_levels` (SLA per layer). The route must come from the approval route list rule (category `work_order`, my department). Details: `03` §2.5.

Acceptance:
- Given a WO at Level 0 Layer 1, when a user not in the step approves, then the result is 403 and nothing changes.

### WO-T11: Modify
`POST /work-order/{id}/modify` { changed fields, remarks }
- Level 0: write the change into the WO and approve it in one step. The requestor gets information only.
- Level 1 / 2: needs the approval flow of that Level first. Save the change as a proposal (history snapshot). Status = Modification Review (Manager of that department).

### WO-T12: Reject
`POST /work-order/{id}/reject` { remarks }
- Remarks are required, max 500 characters.
- Level 0: goes through the approval route category `wo_reject_level_0` (TD21): open a reject process with its users; after its last level → Rejected; a "no" → back to the Level 0 approval. Open: route members, one route for each department?
- Level 1 / 2: needs the approval flow first, and `no_reject` must be false. Status = Rejection Review (Manager of that department).

### WO-T13: Modification decision
`POST /work-order/{id}/modification/decision` { decision: approve | reject, remarks }
- Manager of the target (or assigned) department:
  - Approve → go to the Manager of the requestor department.
  - Reject → drop the proposal. Back to Waiting Approval (Senior).
- Manager of the requestor department:
  - Approve → copy the proposal into the WO. Status = Approved.
  - Reject → drop the proposal. Status = Approved with the old values.

### WO-T14: Rejection decision
`POST /work-order/{id}/rejection/decision` { decision: confirm | cancel, remarks }
- Manager of the target (or assigned) department:
  - "Yes, Reject" → go to the Manager of the requestor department.
  - "No, Cancel" → back to Waiting Approval (Senior).
- Manager of the requestor department:
  - Accept → Rejected (final).
  - Refuse → back to the Senior with `no_reject` = true (only Approve or Modify).

### WO-T15: Set Approval Flow (Level 1 / 2)
`POST /work-order/{id}/approval-flow` { approval_route_id }
- Allowed only in Waiting Approval, at Level 1 or Level 2, for a user of the department of that Level.
- Copy the steps of the selected route into `work_order_approvers` for that Level.
- After this, the Senior can use Modify and Reject.
- Success message: "Set work order approval flow succeed".

### WO-T16: Approvers of a step (users by permission + department)
`GET /work-order/{id}/approvers?level=&layer=`, and `GET /users/by-permission/{permissionId}?department=`
- List the users who hold the permission of the layer, in the department of that Level.
- Add the optional `department` filter to `/users/by-permission`.
- The Retina-only permission list comes from config, not from code.
- Every user in the list can review. No position check.

### WO-T17: Transfer options and Transfer
`GET /work-order/{id}/transfer-options`, `POST /work-order/{id}/transfer` { department, sub_unit, notes? }
- Options: the department list for the target department, and the sub-units (PE / PO / RAM / WO-WS).
- Transfer only at Level 1, only in Approved. Notes are optional.
- Status = Waiting Approval at Level 2. The assigned department then uses Set Approval Flow.
- Level 2 cannot transfer. Only one transfer.
- Open: does Transfer also take a PIC (Figma) (`03` §5 item 4)?

### WO-T18: Disposition
`POST /work-order/{id}/disposition` { work_type, pic_ids[], notes? }
- Only in Approved (Level 1 or Level 2).
- Work Type rules:
  - ABI/BD: only Projects and PO.
  - ABI/NBD: only OSF.
  - ABO Routine and ABO Non Routine: all departments.
- Status = Project Preparation.

### WO-T19: Project prefill
`GET /work-order/{id}/project-prefill`
- Return the values for the "Create Project" form:
  - description = WO title;
  - project number = WO number;
  - category / class from the project class mapping;
  - field, RKAP, WBS, department, schedule type.
- The project is made by the changed project endpoint (WO-T22).

### WO-T20: WO number format from config
- `WorkOrderNumbers` reads the format from `custom_configurations`, not from code.
- The WO and the Action Plan use the same counter.

### WO-T21: Action Plan link to the WO
`POST /well-surveilence/action-plans/{pep|phss}/submit` accepts `work_order_id`
- The AP takes the WO number. It does not make a new number.
- The AP uses the approval route of the WO.
- Blocked: Q15 (old Action Plans with a WO number) and the link column (`05` §2 item 5).

### WO-T22: Project changes for a WO project
`POST /projects/{projectId}`, `POST /projects/submit`, `POST /projects/approval`, Project Finish
- Accept `work_order_id` and set the origin = work order.
- WBS is optional when `work_order_id` is set.
- An Action Plan WO skips the project approval. The project goes to In Progress.
- Schedule type from the WO department: detailed (Projects, OSF) or simple (others). No `.mpp`.
- Project approved → WO On Going. Project rejected → WO Project Preparation.
- Finish: the WO parameter update is required. All schedules of the WO finished → WO Completed.
- Open: project approvers for a WO project (Q36).

### WO-T23: My approval list: WO steps
`GET /my-approval-list`
- Add the WO steps where the user is a copied approver of the current step.
