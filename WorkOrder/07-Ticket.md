# Work Order: tickets (business logic only)

Made on 25 Nov from `03-Endpoint-Plan.md` (§2 and §3).
Scope:
- Only the business logic of each endpoint: rules, checks, status changes, and results.
- Not here: FE, infra, seeds, permissions setup, notifications, and release steps. See `05-Production-Checklist.md` and `03` §6.

How to use this file:
- One ticket = one endpoint or one small group of endpoints.
- Each ticket has a **Test result** block: the test user, the date, the curl request, and the response. Fill it after a curl run on a local WebApi with the dev DB. A ticket is not "Done" without it.
- Put the Jira key in the "Jira" column when the ticket exists. Epic: [PHI-2465 SSDP3](https://digiitphi.atlassian.net/browse/PHI-2465). The Story ↔ ticket map is in §3.
- Update the "Status" column when work moves.
- **[PHI-2993](https://digiitphi.atlassian.net/browse/PHI-2993)** (25 Nov): the Jira ticket for WO-T01, T02, T04, T05 and T06 (branch `feat/work-order-draft`, commit c7cc887f, PR oceaninov/phantom#1545). Bruno: commit 5de37bf on PR oceaninov/phi-phantom-collections#235.
- The curl test rows stay on dev (user, 25 Nov): 0001/WO/PO/2026 and 0002/WO/PO/2026 (waiting_approval), 0003/WO/PO/2026 (deleted draft). Do not remove them.

Status words: **Done** (merged on `phi-dev`), **PR #nnnn** (committed, PR open), **Staged** (code written and staged, not committed), **Tested, staged** (curl test passed, not committed), **To do**, **Blocked** (needs a decision or another ticket first).

Common rules for all tickets (from `03` and the decisions):
- The backend uses the permission ID **only to list users**. It never allows or blocks an action by permission ID.
- An action is allowed by the **WO state**: the status, the current Level / Layer, and the user in the copied approvers of that step.
- Each action writes one row in `work_order_histories`.
- Levels: 0 = requestor department, 1 = target department, 2 = assigned department (after a Transfer).
- Layers: 1 = Senior / Asst. Manager, 2 = Manager.

---

## 1. Ticket list

| ID     | Title                                                  | Endpoint (`03` #) | Depends on      | Jira                                                                                                                                                                                                                                                                                                            | Status                                                                                                                                                                                                                                 |
| ------ | ------------------------------------------------------ | ----------------- | --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| WO-T00 | Overview cards and list                                | #1, #2            | –               | [PHI-2992](https://digiitphi.atlassian.net/browse/PHI-2992), [PHI-3107](https://digiitphi.atlassian.net/browse/PHI-3107)                                                                                                                                                                                        | Done (#1530, #1533, #1539)                                                                                                                                                                                                             |
| WO-T01 | Next WO number (preview)                               | #3                | WO-T20 (format) | [PHI-2993](https://digiitphi.atlassian.net/browse/PHI-2993)                                                                                                                                                                                                                                                     | Tested, PR #1545 (open, stacked on #1544)                                                                                                                                                                                              |
| WO-T02 | Form options                                           | #4                | –               | [PHI-2993](https://digiitphi.atlassian.net/browse/PHI-2993)                                                                                                                                                                                                                                                     | Tested, PR #1545 (open, stacked on #1544)                                                                                                                                                                                              |
| WO-T03 | Approval route for WO (layers + permission)            | #5, §3.2          | –               | –                                                                                                                                                                                                                                                                                                               | Skipped for now (25 Nov; TD18). Route categories are data since 26 Nov (TD34): `wo_approve_level_0 / 1 / 2`, `wo_reject_level_0 / 1 / 2`, one per department of the Level |
| WO-T04 | Save draft and update draft                            | #6, #7            | –               | [PHI-2993](https://digiitphi.atlassian.net/browse/PHI-2993)                                                                                                                                                                                                                                                     | Tested, PR #1545 (open, stacked on #1544)                                                                                                                                                                                              |
| WO-T05 | Create (submit) WO, no approval logic                  | #8                | WO-T04          | [PHI-2993](https://digiitphi.atlassian.net/browse/PHI-2993)                                                                                                                                                                                                                                                     | Tested; B4 fixed (4c0a5580); PR #1545 (open, stacked on #1544). Changed in PR #1548: the route must be `wo_approve_level_0` of the requestor department (TD34) |
| WO-T06 | Delete draft                                           | #9                | WO-T04          | [PHI-2993](https://digiitphi.atlassian.net/browse/PHI-2993)                                                                                                                                                                                                                                                     | Tested, PR #1545 (open, stacked on #1544)                                                                                                                                                                                              |
| WO-T07 | WO details and allowed actions                         | #10               | WO-T05          | [PHI-2994](https://digiitphi.atlassian.net/browse/PHI-2994)                                                                                                                                                                                                                                                     | Done (PR #1548, merged 26 Nov at `c3de24ac`; curl `archive/12-CurlTest.md`): `GET /work-order/{id}` + `actions` (Reject only when the Level has its reject route; `create_project` for a disposition PIC or a user of the Level department) |
| WO-T08 | Approval history and modification comparison           | #11               | WO-T05          | [PHI-3106](https://digiitphi.atlassian.net/browse/PHI-3106)                                                                                                                                                                                                                                                     | PR #1544 open (26 Nov): mergeable, base `phi-dev`, no CI checks, 1 review (comment, no approval); review fixes in (CC, allow-list, Level 2 hiding); last commit `b6631bfa` merges `phi-dev`. Waits for approval + merge. #1545 is stacked on it |
| WO-T09 | Attachments: add and delete                            | #12, #13          | WO-T04          | [PHI-2995](https://digiitphi.atlassian.net/browse/PHI-2995)                                                                                                                                                                                                                                                     | PR #1547 open (26 Nov): no review yet, mergeable not computed, base `phi-dev`. 7 unit tests pass, curl done (dev). Adds an extra edit-description endpoint (`POST .../attachments/{attachment_id}`). Only the WO creator can change files (Modify flow later); no history rows |
| WO-T10 | Approve and bulk approve                               | #15, #16          | WO-T05          | [PHI-2996](https://digiitphi.atlassian.net/browse/PHI-2996), [PHI-3055](https://digiitphi.atlassian.net/browse/PHI-3055)                                                                                                                                                                                        | Done (PR #1548, merged 26 Nov at `c3de24ac`; curl `archive/12-CurlTest.md`): Level 0 + Level 1 / 2 approve, bulk |
| WO-T11 | Modify                                                 | #17               | WO-T10, WO-T15  | [PHI-2998](https://digiitphi.atlassian.net/browse/PHI-2998), [PHI-2999](https://digiitphi.atlassian.net/browse/PHI-2999), [PHI-3002](https://digiitphi.atlassian.net/browse/PHI-3002), [PHI-3049](https://digiitphi.atlassian.net/browse/PHI-3049), [PHI-3056](https://digiitphi.atlassian.net/browse/PHI-3056) | Done (PR #1548, merged 26 Nov at `c3de24ac`; curl `archive/12-CurlTest.md`): Level 0 (TD23 + Self Modify) and Level 1 / 2 (two-Manager review) |
| WO-T12 | Reject                                                 | #18               | WO-T10, WO-T15  | [PHI-2997](https://digiitphi.atlassian.net/browse/PHI-2997), [PHI-3004](https://digiitphi.atlassian.net/browse/PHI-3004), [PHI-3051](https://digiitphi.atlassian.net/browse/PHI-3051), [PHI-3058](https://digiitphi.atlassian.net/browse/PHI-3058)                                                              | Done (PR #1548, merged 26 Nov at `c3de24ac`; curl `archive/12-CurlTest.md`): every Level through its own `wo_reject_level_0 / 1 / 2` route (TD21, TD34) |
| WO-T13 | Modification decision                                  | #19               | WO-T11          | [PHI-3000](https://digiitphi.atlassian.net/browse/PHI-3000), [PHI-3001](https://digiitphi.atlassian.net/browse/PHI-3001), [PHI-3003](https://digiitphi.atlassian.net/browse/PHI-3003), [PHI-3050](https://digiitphi.atlassian.net/browse/PHI-3050), [PHI-3057](https://digiitphi.atlassian.net/browse/PHI-3057) | Done (PR #1548, merged 26 Nov at `c3de24ac`; curl `archive/12-CurlTest.md`) (Level 0 reject = back to Layer 1, to confirm) |
| WO-T14 | Rejection decision                                     | #20               | WO-T12          | [PHI-3052](https://digiitphi.atlassian.net/browse/PHI-3052), [PHI-3059](https://digiitphi.atlassian.net/browse/PHI-3059)                                                                                                                                                                                        | Done (PR #1548, merged 26 Nov at `c3de24ac`; curl `archive/12-CurlTest.md`): the reject route round on every Level (TD34); the Level 1 / 2 two-Manager reject is removed |
| WO-T15 | Set Approval Flow (Level 1 / 2)                        | #21               | WO-T03          | [PHI-3005](https://digiitphi.atlassian.net/browse/PHI-3005), [PHI-3054](https://digiitphi.atlassian.net/browse/PHI-3054)                                                                                                                                                                                        | Done (PR #1548, merged 26 Nov at `c3de24ac`; curl `archive/12-CurlTest.md`): route = `wo_approve_level_1 / 2` of the Level's department (TD34) |
| WO-T16 | Approvers of a step (users by permission + department) | #22, §3.1         | WO-T03          | [PHI-3005](https://digiitphi.atlassian.net/browse/PHI-3005), [PHI-3054](https://digiitphi.atlassian.net/browse/PHI-3054)                                                                                                                                                                                        | Done (PR #1548, merged 26 Nov at `c3de24ac`; curl `archive/12-CurlTest.md`): `GET /work-order/{id}/approvers`, `/users/by-permission?department=`, WO ids 273–279 Retina-only in code (`WorkOrderPermissions`) |
| WO-T17 | Transfer options and Transfer                          | #23, #24          | WO-T10          | [PHI-3048](https://digiitphi.atlassian.net/browse/PHI-3048)                                                                                                                                                                                                                                                     | Done (PR #1548, merged 26 Nov at `c3de24ac`; curl `archive/12-CurlTest.md`) (sub_unit + pic_ids both optional, to confirm) |
| WO-T18 | Disposition                                            | #25               | WO-T10          | [PHI-3006](https://digiitphi.atlassian.net/browse/PHI-3006)                                                                                                                                                                                                                                                     | Done (PR #1548, merged 26 Nov at `c3de24ac`; curl `archive/12-CurlTest.md`) |
| WO-T19 | Project prefill                                        | #26               | WO-T18          | [PHI-3060](https://digiitphi.atlassian.net/browse/PHI-3060)                                                                                                                                                                                                                                                     | Done (PR #1548, merged 26 Nov at `c3de24ac`; curl `archive/12-CurlTest.md`): category `other`, `work_type` from the disposition; 403 unless a disposition PIC or a user of the Level department (`c3de24ac`) |
| WO-T20 | WO number format from config                           | §3.3              | –               | –                                                                                                                                                                                                                                                                                                               | Done (PR #1548, `f901caf4`): `work_order.number_format` (detail `format`; `{seq:Dn}`, `{short}`, `{year}`); no row / invalid = `{seq:D4}/WO/{short}/{year}` (today). Unit tests pass |
| WO-T21 | Action Plan link to the WO                             | §3.4              | WO-T05          | –                                                                                                                                                                                                                                                                                                               | To do (unblocked 26 Nov, TD32): one AP per WO, link = `work_orders.action_plan_id` only, no migration |
| WO-T22 | Project changes for a WO project                       | §3.5              | WO-T19          | [PHI-3060](https://digiitphi.atlassian.net/browse/PHI-3060)                                                                                                                                                                                                                                                     | Done (PR #1548, `872e64e8`, `cdb86241`, `c3de24ac`): `projects.work_type` + category `other`; create takes `work_order_id`; WBS optional on submit; the WO follows its projects (project_approval / on_going / project_preparation / completed); `POST /projects` with `work_order_id` = 403 unless a disposition PIC or a user of the Level department. **PR #1552 (open, `feat/PHI-2996-wo-notifications`, `a38c8923`):** N18 project returned, N19 WO completed, no approval email for a WO project. Not done: the AP WO skip of the project approval (needs WO-T21), project approvers (Q36) |
| WO-T23 | My approval list: WO steps                             | §3.6              | WO-T10          | –                                                                                                                                                                                                                                                                                                               | Done (PR #1548, merged 26 Nov at `c3de24ac`; curl `archive/12-CurlTest.md`): `work_order_approval` group, type `work_order` |
| WO-T24 | Export (all levels)                                    | #27               | WO-T00          | [PHI-3053](https://digiitphi.atlassian.net/browse/PHI-3053)                                                                                                                                                                                                                                                     | Skipped 26 Nov: no format or content yet (G35)                                                                                                                                                                                         |


**PR #1548** (merged into `phi-dev` 26 Nov 04:33 at `c3de24ac`): WO-T07, T10–T20, T23 and most of T22. Migrations `AddProjectWorkType` + `AddWorkOrderRowVersion` and the notification seed (15 templates) are applied on dev. Curl 26 Nov: 65 / 69 pass on the full run (section F timed out on the dev DB; F alone passed 3 / 3), `archive/12-CurlTest.md`. Review fixes in the last commits: 409 on a parallel approve (`3bab64db`), project access by disposition PIC or Level department, active users only in every flow (`c3de24ac`). Not built: Bruno requests, the AuditModules rule for `/work-order`.

**PR #1552** (open 26 Nov, `feat/PHI-2996-wo-notifications` on `phi-dev`, `a38c8923`): N18 `phantom_iac_wo_project_returned`, N19 `phantom_iac_wo_completed`, and no project approval email for a WO project (TD17). The 2 templates are seeded on dev (17 `phantom_iac_wo_*` rows). 82 WO + notifier unit tests pass.
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
- ~~A WO route has the category "Work Order - {Department}".~~ **26 Nov (TD34):** one route per Level and per department of that Level: `wo_approve_level_0` (requestor), `wo_approve_level_1` (target / Request To), `wo_approve_level_2` (transfer); the same for `wo_reject_level_0 / 1 / 2`. The route's `department_id` = the Level's department. The single `work_order` category is no longer accepted. No code change in the approval route module (the category is free text); the layers + permission part below is still skipped.
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
- **Changed by PR #1548 (TD20, TD34):** Create now copies the Level 0 flow and opens `Work Order Level 0`; no flow = 400; the route must be an active `wo_approve_level_0` route of the requestor department. Still no skip for any category.

**PR #1545 review (AgieAja, 25 Nov), all checked 26 Nov against `4c0a5580`: valid, to fix in #1545** (WO-T04 / WO-T05 upload and form code; #1548 has the same code):
1. [High] `UploadAsync` sends the client `Content-Type` to the bucket. Store `application/octet-stream` (as `ContractDocumentsService` and #1547); keep the client type only in `file_type`.
2. [High] The `UploadStreamAsync` result is dropped; it catches every error and returns `UploadStatus = false`, so a failed upload still saves an attachment row. Check the result and throw.
3. [Medium] Files stay in MinIO when anything fails between the upload and `SaveAsync` (number 422 / 400, flow 400, failed 3rd file, cancel), in Save Draft, Update Draft and Create. Upload last, inside one try with the save; remove the uploaded files on any error.
4. [Medium] No `RequestSizeLimit` on the 3 form endpoints (Kestrel default ~28.6 MB < 5 × 10 MB), and `ReadFormAsync` runs outside `RunAsync` (413 / bad multipart not in `ApiResponse`). Same fix as #1547 `WorkOrderAttachmentsEndpoint`. Also check the proxy `client_max_body_size`.
5. [Medium] The Swagger text of `CreateWorkOrder` says "unless the category is in categories_without_approval" and "approved at Level 1 when no approval". Both are wrong: no category skip (25 Nov), result always `waiting_approval` · L0. Answer to the reviewer's question: the flow is required (TD20, in #1548), with no category skip. Fix the text in #1545 and #1548; `03` #8 fixed 26 Nov.

**Fixed 26 Nov, staged on `feat/work-order-draft` (not committed):** 1 bucket gets `application/octet-stream`, `file_type` keeps the client type (max 100); 2 a failed upload = 400; 3 new `UploadAndSaveAsync`: upload runs last (after the checks and the number), in one try with the save, and any failure removes the files already uploaded; 4 `RequestSizeLimit` 5 × 10 MB + 1 MB on Save Draft / Update Draft / Create, `ReadFormAsync` inside `RunAsync`, 413 → 400 "A work order takes at most 5 files of 10 MB each", a broken body → 400; 5 Create Swagger text fixed. Build OK, all WO tests pass (3 new); full suite fails only on the 4 known tests. **#1548 still has the old code:** merge `feat/work-order-draft` into it after the #1545 commit (Modify also reads the form outside `RunAsync`).
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

**Run 2: Create scenarios (25 Nov 2026, user request "add curl test to create wo")**

- Status: **Pass, 1 case differs** (B4). 39 calls: 33 Create cases + 6 setup / counter calls.
- Users: `phi.wo.po.pic` (creator), `phi.wo.po.senior` (not the creator, C1).
- Env: local WebApi (`feat/work-order-draft`) on the dev DB. Quartz in RAM by a local change, reverted after the run. Files go to dev MinIO.
- Scenarios: `06-Test-Cases-and-Users.md` §1.2. Error responses below show only status, code and message; `error_data.description` = `message`.
- DB check after the run: every 200 WO is `waiting_approval`, Level 0 / Layer 1, `submitted_at` set, one `submitted` history row (plus `created` when it came from a draft). No approver rows except A2 (note 1). PO counter = 15. A1 / A4: `schedule_kind` project for osf, simple for po. A11 stored all optional values (wbs `["101","102"]`, abo_routine, rkap, area, location, function, type_service, the 6 numbers), 2 PIC rows. A9 = 2 and A10 = 5 attachment rows.
- Notes:
  1. A2: the draft saved 2 approver rows (Level 0, Layer 1 and 2). Create keeps them. This matches the code, but the decision is open.
  2. B4: `start_date=2026-12-01` was accepted (stored 2026-12-01). The shared `ActionPlanCommon.ParseDate` also takes `yyyy-MM-dd` and `MM-dd-yyyy`; the error text says DD-MM-YYYY. Not changed; needs a decision. Test row 0014/WO/PO/2026.
  3. D1: the 422 text says "already used by another action plan" (shared `WorkOrderNumberUsedException`), also for a WO number.
- Test rows left on dev (keep): 0004–0015/WO/PO/2026, all `waiting_approval`.

| # | Case | User | HTTP | Result |
|---|---|---|---|---|
| A1 | new WO on phss, request_to osf | `phi.wo.po.pic` | 200 | Pass |
| A2a | save draft with approvers (setup) | `phi.wo.po.pic` | 200 | Pass |
| A2b | next number before create (counter check) | `phi.wo.po.pic` | 200 | Pass |
| A2c | create from the draft | `phi.wo.po.pic` | 200 | Pass |
| A2d | next number after create (counter not moved) | `phi.wo.po.pic` | 200 | Pass |
| A4 | request_to po (simple schedule) | `phi.wo.po.pic` | 200 | Pass |
| A5 | category without approval | `phi.wo.po.pic` | 200 | Pass |
| A6 | zone9 with a PEP field | `phi.wo.po.pic` | 200 | Pass |
| A7 | pep with a PEP field | `phi.wo.po.pic` | 200 | Pass |
| A8a | next number (setup) | `phi.wo.po.pic` | 200 | Pass |
| A8b | wo_number = the next number | `phi.wo.po.pic` | 200 | Pass |
| A9 | two files | `phi.wo.po.pic` | 200 | Pass |
| A10a | draft with 2 files (setup) | `phi.wo.po.pic` | 200 | Pass |
| A10b | create from the draft with 3 new files (5 in total) | `phi.wo.po.pic` | 200 | Pass |
| A11 | all optional fields | `phi.wo.po.pic` | 200 | Pass |
| B1 | missing description | `phi.wo.po.pic` | 400 | Pass |
| B2 | only title (all others missing) | `phi.wo.po.pic` | 400 | Pass |
| B3 | end_date before start_date | `phi.wo.po.pic` | 400 | Pass |
| B4 | date not DD-MM-YYYY | `phi.wo.po.pic` | 200 | Differs |
| B5 | request_to not in config | `phi.wo.po.pic` | 400 | Pass |
| B6 | budget_type not in list | `phi.wo.po.pic` | 400 | Pass |
| B7 | title longer than 255 | `phi.wo.po.pic` | 400 | Pass |
| B8a | unknown field_id | `phi.wo.po.pic` | 400 | Pass |
| B8b | unknown rkap_id | `phi.wo.po.pic` | 400 | Pass |
| B9 | unknown user in pic_ids | `phi.wo.po.pic` | 400 | Pass |
| B10 | PHSS field on pep | `phi.wo.po.pic` | 400 | Pass |
| B11 | working_area abc | `phi.wo.po.pic` | 400 | Pass |
| B12 | six files | `phi.wo.po.pic` | 400 | Pass |
| B13a | exe file | `phi.wo.po.pic` | 400 | Pass |
| B13b | empty file | `phi.wo.po.pic` | 400 | Pass |
| B14 | wo_number wrong department | `phi.wo.po.pic` | 400 | Pass |
| B15 | wo_number ahead of the next number | `phi.wo.po.pic` | 400 | Pass |
| B18 | JSON body, not multipart | `phi.wo.po.pic` | 400 | Pass |
| C0 | save draft (setup) | `phi.wo.po.pic` | 200 | Pass |
| C1 | create from another user's draft | `phi.wo.po.senior` | 403 | Pass |
| C2 | create with unknown id | `phi.wo.po.pic` | 404 | Pass |
| C3a | create from the draft (first time) | `phi.wo.po.pic` | 200 | Pass |
| C3b | create from the same draft again | `phi.wo.po.pic` | 400 | Pass |
| D1 | wo_number already used | `phi.wo.po.pic` | 422 | Pass |

Cases:

**A1 new WO on phss, request_to osf**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=CT\ A1\ new\ osf -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906
```

```json
{
  "data": {
    "id": "55c04cc5-d92a-4472-9772-19227b8c16f1",
    "wo_number": "0004/WO/PO/2026",
    "status": "waiting_approval",
    "current_level": 0,
    "current_layer": 1,
    "created_date": "25-11-2026",
    "attachment_count": 0
  },
  "status": "success",
  "code": "00",
  "message": "Create work order succeed"
}
```

**A2a save draft with approvers (setup)**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/draft" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=CT\ A2\ draft -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F approvers=\[\{\"level\":1,\"sla_days\":2,\"user_id\":\[\"0b000000-0000-0000-0000-000000000602\"\]\},\{\"level\":2,\"sla_days\":2,\"user_id\":\[\"0b000000-0000-0000-0000-000000000604\"\]\}\]
```

```json
{
  "data": {
    "id": "e24e74e5-2933-4527-b7a3-4f8aa28dbfd5",
    "wo_number": "0005/WO/PO/2026",
    "status": "draft",
    "current_level": 0,
    "current_layer": 0,
    "created_date": "25-11-2026",
    "attachment_count": 0
  },
  "status": "success",
  "code": "00",
  "message": "Save work order draft succeed"
}
```

**A2b next number before create (counter check)**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X GET "{{base_url}}/api/v1/work-order/next-number" -H "Authorization: Bearer <token of phi.wo.po.pic>"
```

```json
{
  "data": {
    "sequence_number": "0006",
    "wo_number": "0006/WO/PO/2026",
    "department": "Production Operations"
  },
  "status": "success",
  "code": "00",
  "message": "Get next work order number succeed"
}
```

**A2c create from the draft**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F id=e24e74e5-2933-4527-b7a3-4f8aa28dbfd5 -F title=CT\ A2\ from\ draft -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906
```

```json
{
  "data": {
    "id": "e24e74e5-2933-4527-b7a3-4f8aa28dbfd5",
    "wo_number": "0005/WO/PO/2026",
    "status": "waiting_approval",
    "current_level": 0,
    "current_layer": 1,
    "created_date": "25-11-2026",
    "attachment_count": 0
  },
  "status": "success",
  "code": "00",
  "message": "Create work order succeed"
}
```

**A2d next number after create (counter not moved)**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X GET "{{base_url}}/api/v1/work-order/next-number" -H "Authorization: Bearer <token of phi.wo.po.pic>"
```

```json
{
  "data": {
    "sequence_number": "0006",
    "wo_number": "0006/WO/PO/2026",
    "department": "Production Operations"
  },
  "status": "success",
  "code": "00",
  "message": "Get next work order number succeed"
}
```

**A4 request_to po (simple schedule)**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=CT\ A4\ po -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=po -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906
```

```json
{
  "data": {
    "id": "79aaef58-59c1-4974-a6ce-31f508e7b186",
    "wo_number": "0006/WO/PO/2026",
    "status": "waiting_approval",
    "current_level": 0,
    "current_layer": 1,
    "created_date": "25-11-2026",
    "attachment_count": 0
  },
  "status": "success",
  "code": "00",
  "message": "Create work order succeed"
}
```

**A5 category without approval**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=CT\ A5\ choke -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F category=choke_adjustment
```

```json
{
  "data": {
    "id": "89d2607e-408a-4126-b88f-03be831f2809",
    "wo_number": "0007/WO/PO/2026",
    "status": "waiting_approval",
    "current_level": 0,
    "current_layer": 1,
    "created_date": "25-11-2026",
    "attachment_count": 0
  },
  "status": "success",
  "code": "00",
  "message": "Create work order succeed"
}
```

**A6 zone9 with a PEP field**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/zone9" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=CT\ A6\ zone9 -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=a3988f9d-b43a-490c-9d36-22a7ea8083ce
```

```json
{
  "data": {
    "id": "c300756f-3f1d-4a3e-a191-f677f12fb38d",
    "wo_number": "0008/WO/PO/2026",
    "status": "waiting_approval",
    "current_level": 0,
    "current_layer": 1,
    "created_date": "25-11-2026",
    "attachment_count": 0
  },
  "status": "success",
  "code": "00",
  "message": "Create work order succeed"
}
```

**A7 pep with a PEP field**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/pep" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=CT\ A7\ pep -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=a3988f9d-b43a-490c-9d36-22a7ea8083ce
```

```json
{
  "data": {
    "id": "35fb46b5-d8e7-41e7-8a99-7afd8bb71185",
    "wo_number": "0009/WO/PO/2026",
    "status": "waiting_approval",
    "current_level": 0,
    "current_layer": 1,
    "created_date": "25-11-2026",
    "attachment_count": 0
  },
  "status": "success",
  "code": "00",
  "message": "Create work order succeed"
}
```

**A8a next number (setup)**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X GET "{{base_url}}/api/v1/work-order/next-number" -H "Authorization: Bearer <token of phi.wo.po.pic>"
```

```json
{
  "data": {
    "sequence_number": "0010",
    "wo_number": "0010/WO/PO/2026",
    "department": "Production Operations"
  },
  "status": "success",
  "code": "00",
  "message": "Get next work order number succeed"
}
```

**A8b wo_number = the next number**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=CT\ A8\ own\ number -F wo_number=0010/WO/PO/2026 -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906
```

```json
{
  "data": {
    "id": "481db909-34d8-4751-ba64-4e95132d500f",
    "wo_number": "0010/WO/PO/2026",
    "status": "waiting_approval",
    "current_level": 0,
    "current_layer": 1,
    "created_date": "25-11-2026",
    "attachment_count": 0
  },
  "status": "success",
  "code": "00",
  "message": "Create work order succeed"
}
```

**A9 two files**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=CT\ A9\ files -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F files=@/private/tmp/claude-501/-Users-hafidhidayatullah-Stuffs-Grounds-OceanInovasi-phi-phiDev/fa08d967-8bce-4eb2-ac30-368a7f240259/scratchpad/files/a.pdf -F files=@/private/tmp/claude-501/-Users-hafidhidayatullah-Stuffs-Grounds-OceanInovasi-phi-phiDev/fa08d967-8bce-4eb2-ac30-368a7f240259/scratchpad/files/g.png
```

```json
{
  "data": {
    "id": "88282fd9-991e-4dd4-a8b8-bb72ceed494d",
    "wo_number": "0011/WO/PO/2026",
    "status": "waiting_approval",
    "current_level": 0,
    "current_layer": 1,
    "created_date": "25-11-2026",
    "attachment_count": 2
  },
  "status": "success",
  "code": "00",
  "message": "Create work order succeed"
}
```

**A10a draft with 2 files (setup)**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/draft" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=CT\ A10\ draft -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F files=@/private/tmp/claude-501/-Users-hafidhidayatullah-Stuffs-Grounds-OceanInovasi-phi-phiDev/fa08d967-8bce-4eb2-ac30-368a7f240259/scratchpad/files/a.pdf -F files=@/private/tmp/claude-501/-Users-hafidhidayatullah-Stuffs-Grounds-OceanInovasi-phi-phiDev/fa08d967-8bce-4eb2-ac30-368a7f240259/scratchpad/files/b.pdf
```

```json
{
  "data": {
    "id": "fb6f7c62-5da7-4dcb-bfbd-47116e32155d",
    "wo_number": "0012/WO/PO/2026",
    "status": "draft",
    "current_level": 0,
    "current_layer": 0,
    "created_date": "25-11-2026",
    "attachment_count": 2
  },
  "status": "success",
  "code": "00",
  "message": "Save work order draft succeed"
}
```

**A10b create from the draft with 3 new files (5 in total)**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F id=fb6f7c62-5da7-4dcb-bfbd-47116e32155d -F title=CT\ A10\ from\ draft -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F files=@/private/tmp/claude-501/-Users-hafidhidayatullah-Stuffs-Grounds-OceanInovasi-phi-phiDev/fa08d967-8bce-4eb2-ac30-368a7f240259/scratchpad/files/c.pdf -F files=@/private/tmp/claude-501/-Users-hafidhidayatullah-Stuffs-Grounds-OceanInovasi-phi-phiDev/fa08d967-8bce-4eb2-ac30-368a7f240259/scratchpad/files/d.pdf -F files=@/private/tmp/claude-501/-Users-hafidhidayatullah-Stuffs-Grounds-OceanInovasi-phi-phiDev/fa08d967-8bce-4eb2-ac30-368a7f240259/scratchpad/files/e.pdf
```

```json
{
  "data": {
    "id": "fb6f7c62-5da7-4dcb-bfbd-47116e32155d",
    "wo_number": "0012/WO/PO/2026",
    "status": "waiting_approval",
    "current_level": 0,
    "current_layer": 1,
    "created_date": "25-11-2026",
    "attachment_count": 5
  },
  "status": "success",
  "code": "00",
  "message": "Create work order succeed"
}
```

**A11 all optional fields**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=CT\ A11\ optional -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F wbs=\[\"101\",\"102\"\] -F budget_type=\[\"abo_routine\"\] -F rkap_id=7e6608da-d068-43d7-a0e5-03bd6299f51f -F area_id=79cbb997-1b75-4b82-8288-056890bd7a93 -F location=Well\ pad\ 12 -F pic_ids=\[\"0b000000-0000-0000-0000-000000000601\",\"0b000000-0000-0000-0000-000000000602\"\] -F function=production -F type_service=routine -F production_gain_gas=1.5 -F production_gain_oil=20 -F loss_avoidance_gas=0.5 -F loss_avoidance_oil=3 -F lpo_potential_gas=0.2 -F lpo_potential_oil=1
```

```json
{
  "data": {
    "id": "c1aed93a-2031-458f-88ef-35892aacc75e",
    "wo_number": "0013/WO/PO/2026",
    "status": "waiting_approval",
    "current_level": 0,
    "current_layer": 1,
    "created_date": "25-11-2026",
    "attachment_count": 0
  },
  "status": "success",
  "code": "00",
  "message": "Create work order succeed"
}
```

**B1 missing description**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x -F urgency_level=important -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F start_date=01-12-2026 -F end_date=15-12-2026
```

```json
{"status": "failed", "code": "01", "message": "Required to submit: description"}
```

**B2 only title (all others missing)**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x
```

```json
{"status": "failed", "code": "01", "message": "Required to submit: description, urgency_level, request_to, field_id, start_date, end_date"}
```

**B3 end_date before start_date**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x -F description=d -F urgency_level=important -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F start_date=15-12-2026 -F end_date=01-12-2026
```

```json
{"status": "failed", "code": "01", "message": "end_date must be on or after start_date"}
```

**B4 date not DD-MM-YYYY**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x -F description=d -F urgency_level=important -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F start_date=2026-12-01 -F end_date=15-12-2026
```

```json
{
  "data": {
    "id": "a9346658-e807-49b6-96ab-05d9f720344b",
    "wo_number": "0014/WO/PO/2026",
    "status": "waiting_approval",
    "current_level": 0,
    "current_layer": 1,
    "created_date": "25-11-2026",
    "attachment_count": 0
  },
  "status": "success",
  "code": "00",
  "message": "Create work order succeed"
}
```

**B5 request_to not in config**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=xyz -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906
```

```json
{"status": "failed", "code": "01", "message": "request_to 'xyz' is not a Request To code of work_order.request_to"}
```

**B6 budget_type not in list**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F budget_type=\[\"other\"\]
```

```json
{"status": "failed", "code": "01", "message": "budget_type must be one of abibd, abinbd, abo_routine, abo_non_routine"}
```

**B7 title longer than 255**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906
```

```json
{"status": "failed", "code": "01", "message": "title must be at most 255 characters"}
```

**B8a unknown field_id**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=00000000-0000-0000-0000-0000000000f1
```

```json
{"status": "failed", "code": "01", "message": "field_id '00000000-0000-0000-0000-0000000000f1' was not found"}
```

**B8b unknown rkap_id**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F rkap_id=00000000-0000-0000-0000-0000000000f2
```

```json
{"status": "failed", "code": "01", "message": "rkap_id '00000000-0000-0000-0000-0000000000f2' was not found"}
```

**B9 unknown user in pic_ids**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F pic_ids=\[\"00000000-0000-0000-0000-0000000000f3\"\]
```

```json
{"status": "failed", "code": "01", "message": "pic_ids not found: 00000000-0000-0000-0000-0000000000f3"}
```

**B10 PHSS field on pep**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/pep" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906
```

```json
{"status": "failed", "code": "01", "message": "field_id '8248bb0c-a37c-423c-9ce6-36c592f79906' is not in working area pep"}
```

**B11 working_area abc**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/abc" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906
```

```json
{"status": "failed", "code": "01", "message": "Invalid working area, must be 'zone9', 'phss' or 'pep'"}
```

**B12 six files**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F files=@/private/tmp/claude-501/-Users-hafidhidayatullah-Stuffs-Grounds-OceanInovasi-phi-phiDev/fa08d967-8bce-4eb2-ac30-368a7f240259/scratchpad/files/a.pdf -F files=@/private/tmp/claude-501/-Users-hafidhidayatullah-Stuffs-Grounds-OceanInovasi-phi-phiDev/fa08d967-8bce-4eb2-ac30-368a7f240259/scratchpad/files/b.pdf -F files=@/private/tmp/claude-501/-Users-hafidhidayatullah-Stuffs-Grounds-OceanInovasi-phi-phiDev/fa08d967-8bce-4eb2-ac30-368a7f240259/scratchpad/files/c.pdf -F files=@/private/tmp/claude-501/-Users-hafidhidayatullah-Stuffs-Grounds-OceanInovasi-phi-phiDev/fa08d967-8bce-4eb2-ac30-368a7f240259/scratchpad/files/d.pdf -F files=@/private/tmp/claude-501/-Users-hafidhidayatullah-Stuffs-Grounds-OceanInovasi-phi-phiDev/fa08d967-8bce-4eb2-ac30-368a7f240259/scratchpad/files/e.pdf -F files=@/private/tmp/claude-501/-Users-hafidhidayatullah-Stuffs-Grounds-OceanInovasi-phi-phiDev/fa08d967-8bce-4eb2-ac30-368a7f240259/scratchpad/files/f.pdf
```

```json
{"status": "failed", "code": "01", "message": "A work order takes at most 5 files (0 already attached)"}
```

**B13a exe file**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F files=@/private/tmp/claude-501/-Users-hafidhidayatullah-Stuffs-Grounds-OceanInovasi-phi-phiDev/fa08d967-8bce-4eb2-ac30-368a7f240259/scratchpad/files/bad.exe
```

```json
{"status": "failed", "code": "01", "message": "File 'bad.exe': only PDF, DOC, DOCX, XLS, XLSX, JPG and PNG are accepted"}
```

**B13b empty file**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F files=@/private/tmp/claude-501/-Users-hafidhidayatullah-Stuffs-Grounds-OceanInovasi-phi-phiDev/fa08d967-8bce-4eb2-ac30-368a7f240259/scratchpad/files/empty.pdf
```

```json
{"status": "failed", "code": "01", "message": "File 'empty.pdf' must be larger than 0 and at most 10 MB"}
```

**B14 wo_number wrong department**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x -F wo_number=0099/WO/OSF/2026 -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906
```

```json
{"status": "failed", "code": "01", "message": "wo_number must be NNNN/WO/PO/2026"}
```

**B15 wo_number ahead of the next number**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x -F wo_number=0999/WO/PO/2026 -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906
```

```json
{"status": "failed", "code": "01", "message": "wo_number 0999/WO/PO/2026 is ahead of the next work order number 0015/WO/PO/2026"}
```

**B18 JSON body, not multipart**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -H Content-Type:\ application/json -d \{\"title\":\"x\"\}
```

```json
{"status": "failed", "code": "01", "message": "The body must be multipart/form-data"}
```

**C0 save draft (setup)**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/draft" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=CT\ C\ draft -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906
```

```json
{
  "data": {
    "id": "0359da97-91f2-409e-b710-6748b60f7dc5",
    "wo_number": "0015/WO/PO/2026",
    "status": "draft",
    "current_level": 0,
    "current_layer": 0,
    "created_date": "25-11-2026",
    "attachment_count": 0
  },
  "status": "success",
  "code": "00",
  "message": "Save work order draft succeed"
}
```

**C1 create from another user's draft**: user `phi.wo.po.senior`, HTTP 403

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.senior>" -F id=0359da97-91f2-409e-b710-6748b60f7dc5 -F title=x -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906
```

```json
{"status": "failed", "code": "01", "message": "Only the creator can change this work order draft"}
```

**C2 create with unknown id**: user `phi.wo.po.pic`, HTTP 404

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F id=00000000-0000-0000-0000-0000000000f4 -F title=x -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906
```

```json
{"status": "failed", "code": "01", "message": "Work order not found"}
```

**C3a create from the draft (first time)**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F id=0359da97-91f2-409e-b710-6748b60f7dc5 -F title=CT\ C\ from\ draft -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906
```

```json
{
  "data": {
    "id": "0359da97-91f2-409e-b710-6748b60f7dc5",
    "wo_number": "0015/WO/PO/2026",
    "status": "waiting_approval",
    "current_level": 0,
    "current_layer": 1,
    "created_date": "25-11-2026",
    "attachment_count": 0
  },
  "status": "success",
  "code": "00",
  "message": "Create work order succeed"
}
```

**C3b create from the same draft again**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F id=0359da97-91f2-409e-b710-6748b60f7dc5 -F title=x -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906
```

```json
{"status": "failed", "code": "01", "message": "Only a draft can be changed; this work order is waiting_approval"}
```

**D1 wo_number already used**: user `phi.wo.po.pic`, HTTP 422

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=x -F wo_number=0001/WO/PO/2026 -F description=Scope\ of\ works\ -\ create\ test -F urgency_level=important -F category=well_test -F start_date=01-12-2026 -F end_date=15-12-2026 -F request_to=osf -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906
```

```json
{"status": "failed", "code": "01", "message": "wo_number 0001/WO/PO/2026 is already used by another action plan, please get the next work order number again"}
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
  - **26 Nov (PR #1548 review):** `create_project` in `project_preparation`, `project_approval` and `on_going` (one WO can have many projects), only for a disposition PIC of the WO or a user of the department of the WO's current Level. `no_reject` stays in the response but is always false.

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

**Built 25 Nov (PHI-2996, branch `feat/work-order-approval-l0` on `feat/work-order-draft`, staged; 45 WO unit tests pass; curl pass, see WO-T12):**
- Create now does TD20: it copies the flow (`approvers[]` wins, else `approval_route_id`, else the steps the draft saved) to `work_order_approvers` (Level 0, stage 1) and opens `approval_processes` `Work Order Level 0` (`latest_approval_level` = first layer), an `initiate` log and the Layer 1 timer. No flow = 400. A route must be category `work_order`. This replaces the WO-T05 "no approval logic" rule.
- `POST /work-order/{id}/approve` { remarks? ≤ 500 }: caller in the copied approvers of the current step (Level 0, current layer, newest stage), else 403. Layer 1 → Layer 2; last layer → Level 1 Layer 1, `waiting_approval`, process `approved`. Each step: close the open timer (`approved`), `approve` log, `approved` history row (Level 0, that layer, notes = remarks), open the next timer.
- 400: not `waiting_approval`, not Level 0 (Level 1 / 2 are later), no active Level 0 process (WOs made before this change).
- Not built: bulk approve, Level 1 / 2 approve, notifications, my-approval list (WO-T23).

### WO-T11: Modify
`POST /work-order/{id}/modify` { changed fields, remarks }
- Level 0 (TD23, as Jira): Layer 1 modifies → status Modification Review at Level 0 Layer 2 (the change is a proposal). Layer 2 can also modify by itself (Self Modify: change applied and approved).
- Level 1 / 2: needs the approval flow of that Level first. Save the change as a proposal (history snapshot). Status = Modification Review (Manager of that department).

### WO-T12: Reject
`POST /work-order/{id}/reject` { remarks }
- Remarks are required, max 500 characters.
- Level 0: goes through the approval route category `wo_reject_level_0` (TD21): open a reject process with its users; after its last level → Rejected; a "no" → back to the Level 0 approval. Open: route members, one route for each department?
- ~~Level 1 / 2: needs the approval flow first, and `no_reject` must be false. Status = Rejection Review (Manager of that department).~~
- **26 Nov (TD34), built in PR #1548 (`872e64e8`):** every Level works like Level 0. Level 1 / 2: the Layer 1 Senior of the flow asks (the flow is required); the round runs on the `wo_reject_level_1` / `_2` route of that Level's department (target / transfer); process `Work Order Reject Level N`; all route levels confirm → `rejected` (final); one cancel → back to `waiting_approval` at the layer that asked. No route (or no active user) → 400, and the details page hides Reject.

**Built 25 Nov (PHI-2997, same branch, staged; tested, results below). Decision taken without an answer from the user, to confirm:** the ticket title "Reject by Lv 0 Layer 2" is read as: only the Level 0 **Layer 2 Manager** (an approver of that step) can reject, and the reject is **final**. This does **not** use the TD21 reject route (`wo_reject_level_0`).

> **26 Nov, user: keep TD21.** The reading above is refused. The Level 0 reject must go through the `wo_reject_level_0` route: Reject → `rejection_review` · L0 + a `Work Order Reject Level 0` process; the last reject level confirms → `rejected`; a refusal → back to `waiting_approval` · L0, same layer (`02` §8.1a). Who can start the reject: the Level 0 approver of the current step (Layer 1 Senior or Layer 2 Manager, WO-2.3). Rework this before the PR. The confirm / refuse step is WO-T14.

**Reworked 26 Nov (staged on `feat/work-order-approval-l0`, on top of `5a2ae8a4`; not built, tests not run):**
- `POST /work-order/{id}/reject` { remarks (required, ≤ 500) }: by a copied approver of the current Level 0 step (Layer 1 **or** 2). Finds the active `wo_reject_level_0` route with `department_id` = the WO `requestor_department` (none, or no active user → 400). Copies its users to `work_order_approvers` as a new stage (Level 0, layer = route level, `sla_hours` from the route template or the global default). Opens `approval_processes` "Work Order Reject Level 0" (initiate log + level 1 timer). The Level 0 process stays active; its open timer closes `rejected` and gets a `reject` log. WO → `rejection_review`, Level 0, `current_layer` = first reject level. History `reject_requested` (layer = the asking layer, TD25).
- `POST /work-order/{id}/rejection/decision` { decision: confirm | cancel, remarks? }: by a user of the current reject level (newest stage), else 403. Only `rejection_review` at Level 0, else 400.
  - confirm: next reject level (history `reject_confirmed`), or after the last one → `rejected`, reject process `approved`, Level 0 process `rejected`, history `rejected`.
  - cancel: reject process `rejected`; the Level 0 approvers are copied again as a new stage; WO → `waiting_approval` at the layer that asked (from `reject_requested`); its timer opens again; history `reject_refused`.
- Code: `WorkOrderApprovalService.Reject.cs` (new, partial class). Tests: `Reject_ByLayer1_OpensTheRejectRound_NotFinal`, `RejectionConfirm_ByEveryRejectLevel_RejectsTheWorkOrder`, `RejectionCancel_GoesBackToTheLayerThatAsked_WithAFreshCopyOfItsApprovers`, `Reject_Rules` (replace the two old Layer 2 tests).
- Curl rows J1 / J4 above show the old behavior; run them again after the build.
- Before the test on dev: make a `wo_reject_level_0` route for Production Operations (Data Config). The route `department_id` must be the same text as `work_orders.requestor_department`.
- Not built: notifications (N6 / N12), Level 1 / 2 reject (WO-T12 Level 1, WO-T14 target Managers).
- `POST /work-order/{id}/reject` { remarks (required, ≤ 500) } → `rejected`, Level 0 process `rejected`, timer closed `rejected`, `reject` log, `rejected` history row.
- Layer 1 reject → 400 ("only the Layer 2 Manager can reject"). Not an approver of the step → 403.

Test result (PHI-2996 + PHI-2997, curl, 25 Nov 2026):

- Status: **Pass** (21 calls, all expected). Unit tests: 45 WO tests pass.
- Users: `phi.wo.po.pic` (creator), `phi.wo.po.senior` (Layer 1), `phi.wo.po.manager` (Layer 2). Production Operations, from `mock_auth_sessions`.
- Env: local WebApi (`feat/work-order-approval-l0`) on the dev DB; Quartz in RAM by a local change, reverted after.
- Setup on dev (kept): approval route "WO PO Level 0 (curl test 25 Nov)", category `work_order` (**change it to `wo_approve_level_0`**, TD34), department Production Operations, Layer 1 = senior (2 days), Layer 2 = manager (1 day).
- DB check: 0016 (route) Level 0 Layer 1 → Layer 2 → Level 1 Layer 1, process `approved`, logs initiate / approve "OK from Senior" / approve "OK from Manager", timers 2 d and 1 d closed `approved`, history submitted / approved@0.1 / approved@0.2. 0017 (approvers[]) → `rejected`, process `rejected`, reject log "Out of budget this year", Layer 2 timer `rejected`. 0018 (from draft) got the draft steps; C1 / C2 saved no WO.
- Found and fixed after the run: C5 (draft, no flow in the request) cleared the draft route, so the Layer 1 timer took the global 3 days, not the route 2 days. Create now keeps the draft route; unit test added. Not re-run with curl.
- Test rows on dev (keep): 0016–0018/WO/PO/2026.

| # | Case | User | HTTP | Result |
|---|---|---|---|---|
| S1 | create work_order approval route (setup) | `phi.wo.po.pic` | 200 | Pass |
| C1 | create without a flow (400) | `phi.wo.po.pic` | 400 | Pass |
| C2 | create with a non work_order route (400) | `phi.wo.po.pic` | 400 | Pass |
| C3 | create with the work_order route | `phi.wo.po.pic` | 200 | Pass |
| P1 | approve by a user not on the route (403) | `phi.wo.po.pic` | 403 | Pass |
| P2 | approve by the Layer 2 Manager at Layer 1 (403) | `phi.wo.po.manager` | 403 | Pass |
| P3 | approve, unknown id (404) | `phi.wo.po.senior` | 404 | Pass |
| P4 | approve, remarks over 500 (400) | `phi.wo.po.senior` | 400 | Pass |
| J1 | reject by Layer 1 Senior (400) | `phi.wo.po.senior` | 400 | Pass |
| P5 | Layer 1 Senior approves (to Layer 2) | `phi.wo.po.senior` | 200 | Pass |
| J2 | reject by Layer 2 Manager without remarks (400) | `phi.wo.po.manager` | 400 | Pass |
| P6 | Layer 2 Manager approves (to Level 1) | `phi.wo.po.manager` | 200 | Pass |
| P7 | approve at Level 1 (400, later ticket) | `phi.wo.po.senior` | 400 | Pass |
| C4 | create with approvers[] (Senior L1, Manager L2) | `phi.wo.po.pic` | 200 | Pass |
| P8 | Layer 1 Senior approves (to Layer 2) | `phi.wo.po.senior` | 200 | Pass |
| J3 | reject by a user not on the step (403) | `phi.wo.po.senior` | 403 | Pass |
| J4 | Layer 2 Manager rejects (final) | `phi.wo.po.manager` | 200 | Pass |
| P9 | approve a rejected WO (400) | `phi.wo.po.manager` | 400 | Pass |
| D1 | save draft with the route (setup) | `phi.wo.po.pic` | 200 | Pass |
| C5 | create from the draft, no flow in the request (uses the saved steps) | `phi.wo.po.pic` | 200 | Pass |
| P10 | approve an old WO with no Level 0 process (403: no copied approvers) | `phi.wo.po.senior` | 403 | Pass |

Cases (error responses show status, code and message only):

**S1 create work_order approval route (setup)**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/approval-routes" -H "Authorization: Bearer <token of phi.wo.po.pic>" -H Content-Type:\ application/json -d \{\"title\":\"WO\ PO\ Level\ 0\ \(curl\ test\ 25\ Nov\)\",\"description\":\"Work\ Order\ Level\ 0\ test\ route,\ PO\",\"category\":\"work_order\",\"approvers\":\[\{\"level\":1,\"sla_days\":2,\"users\":\[\{\"id\":\"0b000000-0000-0000-0000-000000000602\"\}\]\},\{\"level\":2,\"sla_days\":1,\"users\":\[\{\"id\":\"0b000000-0000-0000-0000-000000000604\"\}\]\}\]\}
```

```json
{"status": "success", "code": "00", "message": "Create approval route succeed"}
```

**C1 create without a flow (400)**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=AP\ C1\ no\ flow -F description=Scope\ -\ approval\ test -F urgency_level=important -F request_to=osf -F category=well_test -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F start_date=01-12-2026 -F end_date=15-12-2026
```

```json
{"status": "failed", "code": "01", "message": "approvers or approval_route_id is required: the Level 0 approval flow has no approver"}
```

**C2 create with a non work_order route (400)**: user `phi.wo.po.pic`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=AP\ C2\ spk\ route -F approval_route_id=aa39ca0b-bf7e-45c7-aeda-076f4d549e71 -F description=Scope\ -\ approval\ test -F urgency_level=important -F request_to=osf -F category=well_test -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F start_date=01-12-2026 -F end_date=15-12-2026
```

```json
{"status": "failed", "code": "01", "message": "approval_route_id 'aa39ca0b-bf7e-45c7-aeda-076f4d549e71' was not found, is not active, or is not a work_order route"}
```

**C3 create with the work_order route**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=AP\ C3\ route -F approval_route_id=fdd227a4-7bdc-4f41-be94-3602614b039d -F description=Scope\ -\ approval\ test -F urgency_level=important -F request_to=osf -F category=well_test -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F start_date=01-12-2026 -F end_date=15-12-2026
```

```json
{
  "data": {
    "id": "8a7bb428-e2fb-46dc-b6e9-a958ca4524a7",
    "wo_number": "0016/WO/PO/2026",
    "status": "waiting_approval",
    "current_level": 0,
    "current_layer": 1,
    "created_date": "25-11-2026",
    "attachment_count": 0
  },
  "status": "success",
  "code": "00",
  "message": "Create work order succeed"
}
```

**P1 approve by a user not on the route (403)**: user `phi.wo.po.pic`, HTTP 403

```bash
curl -X POST "{{base_url}}/api/v1/work-order/8a7bb428-e2fb-46dc-b6e9-a958ca4524a7/approve" -H "Authorization: Bearer <token of phi.wo.po.pic>" -H Content-Type:\ application/json -d \{\"remarks\":\"x\"\}
```

```json
{"status": "failed", "code": "01", "message": "You are not an approver of the current step of this work order"}
```

**P2 approve by the Layer 2 Manager at Layer 1 (403)**: user `phi.wo.po.manager`, HTTP 403

```bash
curl -X POST "{{base_url}}/api/v1/work-order/8a7bb428-e2fb-46dc-b6e9-a958ca4524a7/approve" -H "Authorization: Bearer <token of phi.wo.po.manager>" -H Content-Type:\ application/json -d \{\}
```

```json
{"status": "failed", "code": "01", "message": "You are not an approver of the current step of this work order"}
```

**P3 approve, unknown id (404)**: user `phi.wo.po.senior`, HTTP 404

```bash
curl -X POST "{{base_url}}/api/v1/work-order/00000000-0000-0000-0000-0000000000a1/approve" -H "Authorization: Bearer <token of phi.wo.po.senior>" -H Content-Type:\ application/json -d \{\}
```

```json
{"status": "failed", "code": "01", "message": "Work order not found"}
```

**P4 approve, remarks over 500 (400)**: user `phi.wo.po.senior`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/8a7bb428-e2fb-46dc-b6e9-a958ca4524a7/approve" -H "Authorization: Bearer <token of phi.wo.po.senior>" -H Content-Type:\ application/json -d \{"remarks":"<501 x>"\}
```

```json
{"status": "failed", "code": "01", "message": "remarks must be at most 500 characters"}
```

**J1 reject by Layer 1 Senior (400)**: user `phi.wo.po.senior`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/8a7bb428-e2fb-46dc-b6e9-a958ca4524a7/reject" -H "Authorization: Bearer <token of phi.wo.po.senior>" -H Content-Type:\ application/json -d \{\"remarks\":\"no\ budget\"\}
```

```json
{"status": "failed", "code": "01", "message": "At Level 0 only the Layer 2 Manager can reject; this work order is at Layer 1"}
```

**P5 Layer 1 Senior approves (to Layer 2)**: user `phi.wo.po.senior`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/8a7bb428-e2fb-46dc-b6e9-a958ca4524a7/approve" -H "Authorization: Bearer <token of phi.wo.po.senior>" -H Content-Type:\ application/json -d \{\"remarks\":\"OK\ from\ Senior\"\}
```

```json
{
  "data": {
    "id": "8a7bb428-e2fb-46dc-b6e9-a958ca4524a7",
    "wo_number": "0016/WO/PO/2026",
    "status": "waiting_approval",
    "current_level": 0,
    "current_layer": 2
  },
  "status": "success",
  "code": "00",
  "message": "Approve work order succeed"
}
```

**J2 reject by Layer 2 Manager without remarks (400)**: user `phi.wo.po.manager`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/8a7bb428-e2fb-46dc-b6e9-a958ca4524a7/reject" -H "Authorization: Bearer <token of phi.wo.po.manager>" -H Content-Type:\ application/json -d \{\"remarks\":\"\ \ \"\}
```

```json
{"status": "failed", "code": "01", "message": "remarks is required"}
```

**P6 Layer 2 Manager approves (to Level 1)**: user `phi.wo.po.manager`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/8a7bb428-e2fb-46dc-b6e9-a958ca4524a7/approve" -H "Authorization: Bearer <token of phi.wo.po.manager>" -H Content-Type:\ application/json -d \{\"remarks\":\"OK\ from\ Manager\"\}
```

```json
{
  "data": {
    "id": "8a7bb428-e2fb-46dc-b6e9-a958ca4524a7",
    "wo_number": "0016/WO/PO/2026",
    "status": "waiting_approval",
    "current_level": 1,
    "current_layer": 1
  },
  "status": "success",
  "code": "00",
  "message": "Approve work order succeed"
}
```

**P7 approve at Level 1 (400, later ticket)**: user `phi.wo.po.senior`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/8a7bb428-e2fb-46dc-b6e9-a958ca4524a7/approve" -H "Authorization: Bearer <token of phi.wo.po.senior>" -H Content-Type:\ application/json -d \{\}
```

```json
{"status": "failed", "code": "01", "message": "This work order is at Level 1; only Level 0 approval is available"}
```

**C4 create with approvers[] (Senior L1, Manager L2)**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=AP\ C4\ approvers -F approvers=\[\{\"level\":1,\"sla_days\":2,\"user_id\":\[\"0b000000-0000-0000-0000-000000000602\"\]\},\{\"level\":2,\"sla_days\":1,\"user_id\":\[\"0b000000-0000-0000-0000-000000000604\"\]\}\] -F description=Scope\ -\ approval\ test -F urgency_level=important -F request_to=osf -F category=well_test -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F start_date=01-12-2026 -F end_date=15-12-2026
```

```json
{
  "data": {
    "id": "1f55cb34-e53f-4598-a7be-324c9543f8ab",
    "wo_number": "0017/WO/PO/2026",
    "status": "waiting_approval",
    "current_level": 0,
    "current_layer": 1,
    "created_date": "25-11-2026",
    "attachment_count": 0
  },
  "status": "success",
  "code": "00",
  "message": "Create work order succeed"
}
```

**P8 Layer 1 Senior approves (to Layer 2)**: user `phi.wo.po.senior`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/1f55cb34-e53f-4598-a7be-324c9543f8ab/approve" -H "Authorization: Bearer <token of phi.wo.po.senior>" -H Content-Type:\ application/json -d \{\}
```

```json
{
  "data": {
    "id": "1f55cb34-e53f-4598-a7be-324c9543f8ab",
    "wo_number": "0017/WO/PO/2026",
    "status": "waiting_approval",
    "current_level": 0,
    "current_layer": 2
  },
  "status": "success",
  "code": "00",
  "message": "Approve work order succeed"
}
```

**J3 reject by a user not on the step (403)**: user `phi.wo.po.senior`, HTTP 403

```bash
curl -X POST "{{base_url}}/api/v1/work-order/1f55cb34-e53f-4598-a7be-324c9543f8ab/reject" -H "Authorization: Bearer <token of phi.wo.po.senior>" -H Content-Type:\ application/json -d \{\"remarks\":\"no\"\}
```

```json
{"status": "failed", "code": "01", "message": "You are not an approver of the current step of this work order"}
```

**J4 Layer 2 Manager rejects (final)**: user `phi.wo.po.manager`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/1f55cb34-e53f-4598-a7be-324c9543f8ab/reject" -H "Authorization: Bearer <token of phi.wo.po.manager>" -H Content-Type:\ application/json -d \{\"remarks\":\"Out\ of\ budget\ this\ year\"\}
```

```json
{
  "data": {
    "id": "1f55cb34-e53f-4598-a7be-324c9543f8ab",
    "wo_number": "0017/WO/PO/2026",
    "status": "rejected",
    "current_level": 0,
    "current_layer": 2
  },
  "status": "success",
  "code": "00",
  "message": "Reject work order succeed"
}
```

**P9 approve a rejected WO (400)**: user `phi.wo.po.manager`, HTTP 400

```bash
curl -X POST "{{base_url}}/api/v1/work-order/1f55cb34-e53f-4598-a7be-324c9543f8ab/approve" -H "Authorization: Bearer <token of phi.wo.po.manager>" -H Content-Type:\ application/json -d \{\}
```

```json
{"status": "failed", "code": "01", "message": "Only a work order in waiting_approval can be approved or rejected; this work order is rejected"}
```

**D1 save draft with the route (setup)**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/draft" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F title=AP\ D1\ draft -F approval_route_id=fdd227a4-7bdc-4f41-be94-3602614b039d -F description=Scope\ -\ approval\ test -F urgency_level=important -F request_to=osf -F category=well_test -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F start_date=01-12-2026 -F end_date=15-12-2026
```

```json
{
  "data": {
    "id": "f12b04c7-2761-4017-a507-4ea78828841e",
    "wo_number": "0018/WO/PO/2026",
    "status": "draft",
    "current_level": 0,
    "current_layer": 0,
    "created_date": "25-11-2026",
    "attachment_count": 0
  },
  "status": "success",
  "code": "00",
  "message": "Save work order draft succeed"
}
```

**C5 create from the draft, no flow in the request (uses the saved steps)**: user `phi.wo.po.pic`, HTTP 200

```bash
curl -X POST "{{base_url}}/api/v1/work-order/phss" -H "Authorization: Bearer <token of phi.wo.po.pic>" -F id=f12b04c7-2761-4017-a507-4ea78828841e -F title=AP\ D1\ from\ draft -F description=Scope\ -\ approval\ test -F urgency_level=important -F request_to=osf -F category=well_test -F field_id=8248bb0c-a37c-423c-9ce6-36c592f79906 -F start_date=01-12-2026 -F end_date=15-12-2026
```

```json
{
  "data": {
    "id": "f12b04c7-2761-4017-a507-4ea78828841e",
    "wo_number": "0018/WO/PO/2026",
    "status": "waiting_approval",
    "current_level": 0,
    "current_layer": 1,
    "created_date": "25-11-2026",
    "attachment_count": 0
  },
  "status": "success",
  "code": "00",
  "message": "Create work order succeed"
}
```

**P10 approve an old WO with no Level 0 process (403: no copied approvers)**: user `phi.wo.po.senior`, HTTP 403

```bash
curl -X POST "{{base_url}}/api/v1/work-order/e0fcfec9-6c8e-4e2e-9b64-2704363738c3/approve" -H "Authorization: Bearer <token of phi.wo.po.senior>" -H Content-Type:\ application/json -d \{\}
```

```json
{"status": "failed", "code": "01", "message": "You are not an approver of the current step of this work order"}
```

### WO-T13: Modification decision
- Level 0 (TD23): the Level 0 Layer 2 Manager approves (apply the change, WO goes to Level 1) or rejects (drop the proposal; back to which layer is open, G34).
`POST /work-order/{id}/modification/decision` { decision: approve | reject, remarks }
- Manager of the target (or assigned) department:
  - Approve → go to the Manager of the requestor department.
  - Reject → drop the proposal. Back to Waiting Approval (Senior).
- Manager of the requestor department:
  - Approve → copy the proposal into the WO. Status = Approved.
  - Reject → drop the proposal. Status = Approved with the old values.

### WO-T14: Rejection decision
`POST /work-order/{id}/rejection/decision` { decision: confirm | cancel, remarks }
- **26 Nov (TD34), built in PR #1548:** the decision is made by the users of the current level of the Level's reject route (copied as the newest stage of that Level). `confirm` → the next reject level, or after the last one → `rejected`; `cancel` → back to `waiting_approval` at the layer that asked. Same on Level 0, 1 and 2.
- ~~Manager of the target (or assigned) department: "Yes, Reject" → the Manager of the requestor department; "No, Cancel" → back to the Senior. Manager of the requestor department: Accept → Rejected; Refuse → back to the Senior with `no_reject` = true.~~ Replaced by the route round (TD34, to confirm). `no_reject` is no longer set by any action; a Transfer still clears it.

### WO-T15: Set Approval Flow (Level 1 / 2)
`POST /work-order/{id}/approval-flow` { approval_route_id }
- Allowed only in Waiting Approval, at Level 1 or Level 2, for a user of the department of that Level.
- Copy the steps of the selected route into `work_order_approvers` for that Level.
- **26 Nov (TD34):** the route must be an active `wo_approve_level_1` (Level 1) / `wo_approve_level_2` (Level 2) route of that Level's department, with at least one Layer 1 user. Or `approvers[]` (wins).
- **26 Nov (G38, user): automatic.** When the WO arrives at Level 1 (Level 0 done) or Level 2 (Transfer), the newest active route of that category + department is copied at once (process `Work Order Level N`, Layer 1 timer, `approval_flow_set`). No route = no flow; this endpoint with an empty body then picks it (400 when there is still no route). Built in `71930aea`.
- After this, the Senior can use Modify and Reject (Reject also needs the Level's reject route).
- **26 Nov (PR #1548 review): active users only.** A deleted or `inactive` user is never copied into a flow (automatic pick, this endpoint, the Level 0 route, `approvers[]`). A route with no active Layer 1 user counts as no flow, so the department can still approve or set a flow. A Level 0 route with no active Layer 1 user is refused at submit (400).
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
  - category / class from the project class mapping; **26 Nov: category = `other` for now; `work_type` = `routine` / `non_routine` from the disposition (ABO Routine / ABO Non Routine; ABI = null)**;
  - field, RKAP, WBS, department, schedule type.
- The project is made by the changed project endpoint (WO-T22).
- **26 Nov (PR #1548 review):** allowed in `project_preparation`, `project_approval` and `on_going` (the same as Create Project). Only a disposition PIC of the WO or a user of the department of the WO's current Level; anyone else gets 403.

### WO-T20: WO number format from config
- `WorkOrderNumbers` reads the format from `custom_configurations`, not from code.
- The WO and the Action Plan use the same counter.

### WO-T21: Action Plan link to the WO
`POST /well-surveilence/action-plans/{pep|phss}/submit` accepts `work_order_id`
- The AP takes the WO number. It does not make a new number.
- The AP uses the approval route of the WO.
- Decided 26 Nov (TD32): **one AP per WO**. The link is `work_orders.action_plan_source` + `action_plan_id` only (PR #1523). No `work_order_id` on the AP tables, no new migration.
- `work_order_id` in the AP submit body is optional. When it is set: check that the WO exists and has no other AP (else 400), then write `action_plan_source` / `action_plan_id` on the WO.
- Decided 26 Nov (TD33): Well Surveillance can still make an AP without a WO. Then the AP makes its own WO number, as today (shared counter with the WO). The ~50 dev APs that already have a WO number stay as they are (no clean-up).
- Risk: the AP submit is live on prod. Without `work_order_id` the submit must work as today.
- TD30 (WO detail `action_plan` block, Modify of all AP fields) reads the same link.

### WO-T22: Project changes for a WO project
`POST /projects/{projectId}`, `POST /projects/submit`, `POST /projects/approval`, Project Finish
- Accept `work_order_id` and set the origin = work order.
- WBS is optional when `work_order_id` is set.
- An Action Plan WO skips the project approval. The project goes to In Progress.
- Schedule type from the WO department: detailed (Projects, OSF) or simple (others). No `.mpp`.
- Project approved → WO On Going. Project rejected → WO Project Preparation.
- Finish: the WO parameter update is required. All schedules of the WO finished → WO Completed.
- Open: project approvers for a WO project (Q36).
- **26 Nov (PR #1548 review): who can make the project.** `POST /projects` with `work_order_id`: the WO must be in `project_preparation`, `project_approval` or `on_going`, and the caller must be a disposition PIC of the WO or a user of the department of its current Level (department context, else `users.department`). Else 403. Reason: the WO status follows its projects, so a project of another department must not move it.
- **26 Nov (PR #1552, open): notifications of a WO project (TD17, in-app only).**
  - N18 `phantom_iac_wo_project_returned`: an approver returns (revise) the project → the project PICs and the project creator, with the project number and the reason. Not the approver.
  - N19 `phantom_iac_wo_completed`: the WO moves to `completed` → the requestor and the Senior Officer (Layer 1 of Level 0).
  - Both are saved in the same save as the action, so a failed action sends nothing.
  - The project approval request (`ApprovalNotifier`) sends no email when the project has a `work_order_id`; the in-app notification stays.
- **Done 26 Nov (PR #1548, `872e64e8`):** new column `projects.work_type` (`routine` / `non_routine`, nvarchar(20) null, migration `20261125200717_AddProjectWorkType`); new category `other` (like Fasprod: no sub category, no rig); project create / update accept `work_type`, detail and list return it. The migration is not applied on the dev DB yet (7 dev-DB integration tests fail with "Invalid column name 'work_type'" until it runs).

### WO-T23: My approval list: WO steps
`GET /my-approval-list`
- Add the WO steps where the user is a copied approver of the current step.

### WO-T24: Export (all levels)
`GET /work-order/{id}/export?format=` ([PHI-3053](https://digiitphi.atlassian.net/browse/PHI-3053))
- From the PRD: the "Export" button is on Details Work Order on **every level**, for every user who can open the WO. After the user approved, Export is the only button. It is also in the Modification Comparison modal.
- The PRD section "Work Order - All Levels - Export" is empty: no format and no content yet.
- Open (G35): format (PDF as the FE asked in G28, or CSV "Section, Field, Value" as Knowledge Documents WO-9.1), and the content (fields, approval history, attachment list?). Level 2 changes must stay hidden from Level 1 users (G9).

---

## 3. Jira Story map (25 Nov)

Source: Jira search `summary ~ "work order"` (114 issues: 30 Stories + 84 FE / BE / QA subtasks). Epic [PHI-2465](https://digiitphi.atlassian.net/browse/PHI-2465) "SSDP3", except PHI-3106 and PHI-3107 (no epic). **Mapped by title only**; read the Story text to confirm.

| Jira Story | Title | Jira status | WO ticket |
|---|---|---|---|
| [PHI-2992](https://digiitphi.atlassian.net/browse/PHI-2992) | Lv 0 - Overview Work Order | Dev In Progress (BE PHI-3010 Ready for QA) | WO-T00 |
| [PHI-3107](https://digiitphi.atlassian.net/browse/PHI-3107) | List Work Order (no epic) | To Do | WO-T00 |
| [PHI-2993](https://digiitphi.atlassian.net/browse/PHI-2993) | Lv 0 - Creating Work Order & Notification | Dev In Progress | WO-T01, T02, T04, T05, T06 |
| [PHI-2994](https://digiitphi.atlassian.net/browse/PHI-2994) | Lv 0 - Details Work Order - Overview & Notification (On Progress) | To Do | WO-T07 |
| [PHI-3106](https://digiitphi.atlassian.net/browse/PHI-3106) | Details Work Order - History (no epic) | To Do | WO-T08 |
| [PHI-2995](https://digiitphi.atlassian.net/browse/PHI-2995) | Lv 0 - Details Work Order - Attachment | To Do | WO-T09 |
| [PHI-2996](https://digiitphi.atlassian.net/browse/PHI-2996) | Lv 0 - Approve Flow | To Do | WO-T10 |
| [PHI-2997](https://digiitphi.atlassian.net/browse/PHI-2997) | Lv 0 - Approve - Reject by Lv 0 Layer 2 | To Do | WO-T12 |
| [PHI-2998](https://digiitphi.atlassian.net/browse/PHI-2998) | Lv 0 - Modify - Modify Work Order | To Do | WO-T11 |
| [PHI-2999](https://digiitphi.atlassian.net/browse/PHI-2999) | Lv 0 - Modify - Preview Lv 0 Layer 1 & Notification | To Do | WO-T11 |
| [PHI-3000](https://digiitphi.atlassian.net/browse/PHI-3000) | Lv 0 - Modify - Waiting for Review Lv 0 Layer 2 | To Do | WO-T13 (see G34) |
| [PHI-3001](https://digiitphi.atlassian.net/browse/PHI-3001) | Lv 0 - Modify - Approve Modify by Lv 0 Layer 2 | To Do | WO-T13 (see G34) |
| [PHI-3002](https://digiitphi.atlassian.net/browse/PHI-3002) | Lv 0 - Modify - Self Modify by Lv 0 Layer 2 | To Do | WO-T11 |
| [PHI-3003](https://digiitphi.atlassian.net/browse/PHI-3003) | Lv 0 - Modify - Reject Modify by Lv 0 Layer 2 | To Do | WO-T13 (see G34) |
| [PHI-3004](https://digiitphi.atlassian.net/browse/PHI-3004) | Lv 0 - Modify - Reject | To Do | WO-T12 |
| [PHI-3005](https://digiitphi.atlassian.net/browse/PHI-3005) | Lv 1 - Modal Set Approval Flow | To Do | WO-T15, WO-T16 |
| [PHI-3006](https://digiitphi.atlassian.net/browse/PHI-3006) | Lv 1 - Approve & Create Disposition | To Do | WO-T18 (+ Level 1 approve of WO-T10) |
| [PHI-3048](https://digiitphi.atlassian.net/browse/PHI-3048) | Lv 1 - Approve & Transfer Work Order | To Do | WO-T17 (+ Level 1 approve of WO-T10) |
| [PHI-3049](https://digiitphi.atlassian.net/browse/PHI-3049) | Lv 1 - Modify - Confirm Modify | To Do | WO-T11 |
| [PHI-3050](https://digiitphi.atlassian.net/browse/PHI-3050) | Lv 1 - Modify - Cancel Modify | To Do | WO-T13 |
| [PHI-3051](https://digiitphi.atlassian.net/browse/PHI-3051) | Lv 1 - Reject - Confirm Reject | To Do | WO-T12, WO-T14 |
| [PHI-3052](https://digiitphi.atlassian.net/browse/PHI-3052) | Lv 1 - Reject - Cancel Reject | To Do | WO-T14 |
| [PHI-3060](https://digiitphi.atlassian.net/browse/PHI-3060) | Lv 1 - Create Project - Project-Based (Detailed Project) | To Do | WO-T19, WO-T22 |
| [PHI-3054](https://digiitphi.atlassian.net/browse/PHI-3054) | Lv 2 - Set Approval Flow | To Do | WO-T15, WO-T16 |
| [PHI-3055](https://digiitphi.atlassian.net/browse/PHI-3055) | Lv 2 - Approve Flow | To Do | WO-T10 |
| [PHI-3056](https://digiitphi.atlassian.net/browse/PHI-3056) | Lv 2 - Modify - Confirm Modify | To Do | WO-T11 |
| [PHI-3057](https://digiitphi.atlassian.net/browse/PHI-3057) | Lv 2 - Modify - Cancel Modify | To Do | WO-T13 |
| [PHI-3058](https://digiitphi.atlassian.net/browse/PHI-3058) | Lv 2 - Reject - Confirm Reject | To Do | WO-T12, WO-T14 |
| [PHI-3059](https://digiitphi.atlassian.net/browse/PHI-3059) | Lv 2 - Reject - Cancel Reject | To Do | WO-T14 |
| [PHI-3053](https://digiitphi.atlassian.net/browse/PHI-3053) | All Levels - Export | To Do | WO-T24 (new) |

**WO tickets with no Jira Story:** WO-T03 (route layers), WO-T20 (number format), WO-T21 (Action Plan link), WO-T23 (my approval list), the Level 0 reject route `wo_reject_level_0` (TD21), bulk approve (part of WO-T10), and the Project simple schedule / Finish (02 WO-7.2, 7.3, 8.x).

**Differences (gaps in `02` §1):** G34 closed (TD23, use Jira); G35 partly closed (Export #27, format open); G36 kept as is (TD24).

