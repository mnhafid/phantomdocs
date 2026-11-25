# Work Order: endpoint plan (new and changed)

Status: **plan only**. Nothing is built. Made on 24 Nov from the current decisions (`01-Decision-Log.md`, `02-Knowledge.md` §3, `02-Knowledge.md` §8) and a check of the code (`phi-dev`) and the dev database.

Rules for all endpoints:
- Use the Carter Services pattern (Endpoint + Service in `Logics/Services/WorkOrders`). Register the service in `AppServiceSetup.cs`.
- Use the repo style: `GET` to read, `POST` to create, update and delete (no `PUT` / `DELETE`).
- Optional query filters are `string?`, not `Guid?` / `int?`.
- The permission ID is used **only to list users**. The backend does not check the permission ID to allow or block an action. The backend checks the **WO state**: the status, the current Level / Layer, and that the user is in the copied approver list of that step.
- Each action writes one row in `work_order_histories`.
- Base path: `/api/v1/work-orders`.

---

## 1. What exists today (checked 24 Nov)

| Area | What exists | Gap for the WO |
|---|---|---|
| Users by permission | `GET /users/by-permission/{permissionId}` (`UsersService.GetUsersByPermissionAsync`). It reads casbin, or Retina for a fixed id list (161, 162, 163). | No department filter. The Retina id list is fixed in the code. |
| Approval routes | `GET/POST /approval-routes`, `/approval-routes/{id}`, `/approval-routes/all`. Table `approval_routes` has `category`, `department_id`, `is_active`. Approvers are **users** per level (`approval_route_users.user_id`, `level`). | No layer, no permission ID per layer, no "Work Order - {Department}" category. |
| WO number | `WorkOrderNumbers` (`Logics/Services/ActionPlanApproval/WorkOrderNumbers.cs`): `{seq:D4}/WO/{department short name}/{year}`, preview and lock on `work_order_sequences`. Only the Action Plan uses it. | Format is fixed in the code (the decision: from `custom_configurations`). The WO module does not use it yet. |
| Action Plan | `POST /well-surveilence/action-plans/{pep|phss}/draft`, `/submit`. The AP makes its own `work_order_number`. | The AP must take the number and the route of the WO. |
| Projects | `POST /projects/{projectId}` (save), `POST /projects/submit`, `POST /projects/approval`, `POST /projects/{id}/tasks/simple-schedule`, Finish. | No `work_order_id`, no origin flag. WBS is required. Finish does not close a WO. |
| Approval lists | `GET /my-approval-list`, `need-approval` lists for each module. | No WO items. |
| Schema | PR #1523 adds `work_orders` and 4 child tables. | See our review on the PR. |

---

## 2. New endpoints

### 2.0 Path table (proposal 24 Nov, waits for OK)
Rule: base `/api/v1/work-order` (singular, like the merged #1530 / #1533). A WO id is always `{id:guid}`. A fixed word (`draft`, `next-number`, `form-options`, `approve`) is a literal segment. ASP.NET picks a literal segment before a parameter, and `{id:guid}` matches only a GUID, so no path collides with `/work-order/{working_area}`. The sections below still show the old `/work-orders` names; this table is the target.

| # | Method | New path | Old plan path | Body / query | Status | Jira |
|---|---|---|---|---|---|---|
| 1 | GET | `/work-order/{working_area}/overview` | `/work-orders/overview?tab=` | – | Merged (#1530) | [PHI-2992](https://digiitphi.atlassian.net/browse/PHI-2992) |
| 2 | GET | `/work-order/{working_area}` | `/work-orders?tab=…` | `flow_type`, `search`, `status`, `recipient`, `category`, `field_id`, `sort_column`, `sort_order`, `page`, `page_size` | Merged (#1533) | [PHI-3107](https://digiitphi.atlassian.net/browse/PHI-3107) |
| 3 | GET | `/work-order/next-number` | `/work-orders/next-number` | – | Built, staged (`feat/work-order-draft`), WO-T01 | [PHI-2993](https://digiitphi.atlassian.net/browse/PHI-2993) |
| 4 | GET | `/work-order/form-options` | `/work-orders/form-options` | – | Built, staged (`feat/work-order-draft`), WO-T02 | [PHI-2993](https://digiitphi.atlassian.net/browse/PHI-2993) |
| 5 | GET | `/approval-routes?category=…&department_id=…` and `/approval-routes/{id}` | `/work-orders/approval-flows` | existing endpoints, changed (§3.2) | To do (change) | [PHI-2993](https://digiitphi.atlassian.net/browse/PHI-2993), [PHI-3005](https://digiitphi.atlassian.net/browse/PHI-3005), [PHI-3054](https://digiitphi.atlassian.net/browse/PHI-3054) |
| 6 | POST | `/work-order/draft` | `/work-orders/draft` | multipart FE form | Built, staged (`feat/work-order-draft`) | [PHI-2993](https://digiitphi.atlassian.net/browse/PHI-2993) |
| 7 | POST | `/work-order/draft/{id:guid}` | `/work-orders/draft/{id}` | multipart FE form | Built, staged (`feat/work-order-draft`) | [PHI-2993](https://digiitphi.atlassian.net/browse/PHI-2993) |
| 8 | POST | `/work-order/{working_area}` | `/work-orders/submit` | multipart FE form + optional `id` of a draft | Built, staged (`feat/work-order-draft`) | [PHI-2993](https://digiitphi.atlassian.net/browse/PHI-2993) |
| 9 | POST | `/work-order/{id:guid}/delete` | `/work-orders/{id}/delete` | – | Built, staged (`feat/work-order-draft`), WO-T06 | [PHI-2993](https://digiitphi.atlassian.net/browse/PHI-2993) |
| 10 | GET | `/work-order/{id:guid}` | `/work-orders/{id}` | – | To do | [PHI-2994](https://digiitphi.atlassian.net/browse/PHI-2994) |
| 11 | GET | `/work-order/{id:guid}/histories` | `/work-orders/{id}/histories` | – | To do | [PHI-3106](https://digiitphi.atlassian.net/browse/PHI-3106) |
| 12 | POST | `/work-order/{id:guid}/attachments` | `/work-orders/{id}/attachments` | multipart files | To do | [PHI-2995](https://digiitphi.atlassian.net/browse/PHI-2995) |
| 13 | POST | `/work-order/{id:guid}/attachments/{attachmentId:guid}/delete` | `/work-orders/{id}/attachments/{attachmentId}/delete` | – | To do | [PHI-2995](https://digiitphi.atlassian.net/browse/PHI-2995) |
| 15 | POST | `/work-order/{id:guid}/approve` | `/work-orders/{id}/approve` | `{ remarks }` | To do | [PHI-2996](https://digiitphi.atlassian.net/browse/PHI-2996), [PHI-3055](https://digiitphi.atlassian.net/browse/PHI-3055), [PHI-3006](https://digiitphi.atlassian.net/browse/PHI-3006), [PHI-3048](https://digiitphi.atlassian.net/browse/PHI-3048) |
| 16 | POST | `/work-order/approve/bulk` | `/work-orders/approve/bulk` | `{ ids[] }` | To do | [PHI-2996](https://digiitphi.atlassian.net/browse/PHI-2996) |
| 17 | POST | `/work-order/{id:guid}/modify` | `/work-orders/{id}/modify` | `{ changed fields, remarks }` | To do | [PHI-2998](https://digiitphi.atlassian.net/browse/PHI-2998), [PHI-2999](https://digiitphi.atlassian.net/browse/PHI-2999), [PHI-3002](https://digiitphi.atlassian.net/browse/PHI-3002), [PHI-3049](https://digiitphi.atlassian.net/browse/PHI-3049), [PHI-3056](https://digiitphi.atlassian.net/browse/PHI-3056) |
| 18 | POST | `/work-order/{id:guid}/reject` | `/work-orders/{id}/reject` | `{ remarks }` | To do | [PHI-2997](https://digiitphi.atlassian.net/browse/PHI-2997), [PHI-3004](https://digiitphi.atlassian.net/browse/PHI-3004), [PHI-3051](https://digiitphi.atlassian.net/browse/PHI-3051), [PHI-3058](https://digiitphi.atlassian.net/browse/PHI-3058) |
| 19 | POST | `/work-order/{id:guid}/modification/decision` | `/work-orders/{id}/modification/decision` | `{ decision, remarks }` | To do | [PHI-3000](https://digiitphi.atlassian.net/browse/PHI-3000), [PHI-3001](https://digiitphi.atlassian.net/browse/PHI-3001), [PHI-3003](https://digiitphi.atlassian.net/browse/PHI-3003), [PHI-3050](https://digiitphi.atlassian.net/browse/PHI-3050), [PHI-3057](https://digiitphi.atlassian.net/browse/PHI-3057) |
| 20 | POST | `/work-order/{id:guid}/rejection/decision` | `/work-orders/{id}/rejection/decision` | `{ decision, remarks }` | To do | [PHI-3051](https://digiitphi.atlassian.net/browse/PHI-3051), [PHI-3052](https://digiitphi.atlassian.net/browse/PHI-3052), [PHI-3058](https://digiitphi.atlassian.net/browse/PHI-3058), [PHI-3059](https://digiitphi.atlassian.net/browse/PHI-3059) |
| 21 | POST | `/work-order/{id:guid}/approval-flow` | `/work-orders/{id}/approval-flow` | `{ approval_route_id }` | To do | [PHI-3005](https://digiitphi.atlassian.net/browse/PHI-3005), [PHI-3054](https://digiitphi.atlassian.net/browse/PHI-3054) |
| 22 | GET | `/work-order/{id:guid}/approvers` | `/work-orders/{id}/approvers` | `level`, `layer` (`string?`) | To do | [PHI-3005](https://digiitphi.atlassian.net/browse/PHI-3005), [PHI-3054](https://digiitphi.atlassian.net/browse/PHI-3054) |
| 23 | GET | `/work-order/{id:guid}/transfer-options` | `/work-orders/{id}/transfer-options` | – | To do | [PHI-3048](https://digiitphi.atlassian.net/browse/PHI-3048) |
| 24 | POST | `/work-order/{id:guid}/transfer` | `/work-orders/{id}/transfer` | `{ department, sub_unit?, pic_id?, notes? }` (PIC open) | To do | [PHI-3048](https://digiitphi.atlassian.net/browse/PHI-3048) |
| 25 | POST | `/work-order/{id:guid}/disposition` | `/work-orders/{id}/disposition` | `{ work_type, pic_ids[], notes? }` | To do | [PHI-3006](https://digiitphi.atlassian.net/browse/PHI-3006) |
| 26 | GET | `/work-order/{id:guid}/project-prefill` | `/work-orders/{id}/project-prefill` | – | To do | [PHI-3060](https://digiitphi.atlassian.net/browse/PHI-3060) |

Notes:
- Jira column: the Stories of epic [PHI-2465](https://digiitphi.atlassian.net/browse/PHI-2465), mapped by title (25 Nov). Full map: `07-Ticket.md` §3. Export ([PHI-3053](https://digiitphi.atlassian.net/browse/PHI-3053)) has no path yet (G35).
- #14 is not used (a gap in the old numbering).
- The working area is only on #1 and #2 (the page tab). A WO id already fixes its working area, so the id paths do not take it.
- `{working_area}` has no constraint today. A wrong word (for example a typo of `next-number`) falls into #2 and gets "Invalid working area" (400). That is acceptable; a route constraint is optional.

### 2.1 Overview and list (WO Lv 0 / Lv 1 / Lv 2 overview)
1. `GET /work-orders/overview?tab=incoming|outgoing`
   - Returns 6 counts: Total WO, Received WO, In Review, Submit WO, Rejected WO, Draft WO.
   - Outgoing = the WOs of my department (requestor). Incoming = the WOs whose target or assigned department is my department.
2. `GET /work-orders?tab=&search=&status=&recipient=&category=&field=&sort=&order=&page=&page_size=`
   - Returns the 11 table columns: Description, Status, Action, Recipient, Category, Field, Start Date, End Date, Created Date, Approve Date, Remarks.
   - Search runs on the number, the title and the description.

### 2.2 Form data (Create Work Order)
3. `GET /work-orders/next-number`: a preview of the next WO number. It does not take the number. It uses `WorkOrderNumbers` with the format from `custom_configurations`.
4. `GET /work-orders/form-options`: one call for the form lists:
   - Request To (11 departments).
   - Function and Category for each Request To.
   - Urgency.
   - Schedule type for each department.
   - Source: `custom_configurations` (see §4).
5. `GET /work-orders/approval-flows?level=0|1|2&department=`: the active routes of category "Work Order - {Department}" that a user can select, with their steps and approvers (see 2.6).
   - **Update 24 Nov:** reuse the existing endpoints instead of a new one. Search = `GET /approval-routes?category=work_order&department_id=&search=&status=active` (the filters exist today). The selected route's progress (steps, Layer, permission, SLA, the approvers listed by permission + department) = `GET /approval-routes/{id}`. See §3.2 for the change and `04` §2 for the screen.

### 2.3 Create, draft and submit (Level 0)
6. `POST /work-order/draft` (multipart FE form, decided 25 Nov; was JSON): saves a Draft. Takes the WO number. Saves the WO PICs. **Built 24 Nov** (branch `feat/work-order-draft`, staged, not built). Files are not in this call: the FE sends them with #12 after the draft has an id.
7. `POST /work-order/draft/{id}` (multipart FE form): updates my own Draft. Replaces every field and the requestor PICs; the WO number stays. 404 / 403 (not the creator) / 400 (not a draft). **Built 24 Nov** (same branch).
8. `POST /work-order/{working_area}` (multipart FE form; with `id` for a saved draft, or a new WO). **Built 25 Nov** (`feat/work-order-draft`, staged):
   - Checks the mandatory fields.
   - Sets `schedule_kind` from the department (the user does not send it).
   - **25 Nov: no approval logic in Create** (WO-T05). It copies no steps and skips nothing. Status = Waiting Approval, Level 0 / Layer 1.
9. `POST /work-orders/{id}/delete`: deletes a Draft (soft delete). Only the creator, only in Draft.

**Form rules (25 Nov, user decisions; #6, #7, #8 built on `feat/work-order-draft`, #9 not built):**
- One FE multipart form for #6 / #7 / #8: arrays and objects as JSON strings, numbers as strings. Files in the same call: max 5 per WO, 10 MB, PDF / DOC / DOCX / XLS / XLSX / JPG / PNG.
- `request_to` = FE code, checked against `work_order.request_to`. `budget_type` = array, one value (`abibd`, `abinbd`, `abo_routine`, `abo_non_routine`). `urgency_level` = FE value.
- Approvers: `approvers[{level, sla_days, user_id[]}]` wins over `approval_route_id` (route level = Layer). Level 0, stage 1. A draft keeps them (not active); Update replaces them.
- #8 required: title, description, urgency_level, request_to, field_id (in the path working area), dates, and a step unless the category is in `work_order.categories_without_approval`. `schedule_kind` = project for `osf` / `projects`, else simple. The Action Plan key is kept in the `submitted` history snapshot only (§3.4 not built).

**Draft rules (checked on `phi-dev`, 24 Nov):**
- Status `draft`, `current_level` 0, `current_layer` 0. No `work_order_approvers` rows until Submit.
- `wo_number` is NOT NULL and unique among rows with `deleted_at IS NULL`. So #6 must take a real number: two drafts with `""` would break the index. A deleted draft leaves a gap in the sequence.
- List (merged #1533): a draft shows only in **Outgoing**, only to its creator. It never shows in Incoming, and other users of the department do not see it.
- Overview (merged #1530): `draft_wo` counts my drafts. `total_wo` includes them. `received_wo` and `submit_wo` do not.
- Working area: `phss` / `pep` match through `fields.working_area`. A draft with no field shows only under `zone9`. The draft needs a field, or the FE uses `zone9`.
- (24 Nov, replaced by the form rules above) Body of #6 / #7: `wo_number` (create only), `title`, `description`, `urgency_level`, `request_to`, `function`, `category`, `type_service`, `field_id`, `area_id`, `location`, `start_date` / `end_date` (`dd-MM-yyyy`, end >= start), `wbs[]`, `rkap_id`, `budget_type`, the 6 production values, `approval_route_id` (active route), `pic_ids[]`. Response `{ id, wo_number, status, created_date }`. A used number = 422.
- `WorkOrderNumbers` now also reads `work_orders`, so a WO and an Action Plan never share a number.

### 2.4 Details, history and attachments
10. `GET /work-orders/{id}`: the header, the PICs, the attachments, the current Level / Layer, the copied steps, and the list of **actions this user can do now** (for the buttons).
11. `GET /work-orders/{id}/histories`: the approval history for each cycle (Received Date, Action Date, Duration, Remarks), and the Modification Comparison (before / after for each field).
12. `POST /work-orders/{id}/attachments` (multipart): adds files (max 5 for each WO, 10 MB each; PDF, DOC, DOCX, XLS, XLSX, JPG, PNG).
x`z`x
13. `POST /work-orders/{id}/attachments/{attachmentId}/delete`: soft delete.

### 2.5 Approval actions
All actions check: the status, `current_level` / `current_layer`, and that the user is in the copied approvers of that step. Remarks are mandatory for Reject (max 500 characters).

15. `POST /work-orders/{id}/approve` { remarks }
    - Level 0: Layer 1 → Layer 2, then Layer 2 → Level 1 (Waiting Approval).
    - Level 1 / 2: the Senior approves. Status = Approved. This works without an approval flow.
16. `POST /work-orders/approve/bulk` { ids[] }: approves each WO that passes the checks. It returns the failed ids with the reason.
17. `POST /work-orders/{id}/modify` { changed fields, remarks }
    - Level 0: writes the change into the WO and approves it in one step. The requestor gets a notification only.
    - Level 1 / 2: needs the approval flow of that Level first. Saves the change as a **proposal** (history snapshot). Status = Modification Review (Manager of that department).
18. `POST /work-orders/{id}/reject` { remarks }
    - Level 0: goes through the route `wo_reject_level_0` first (TD21). After its last level → Rejected.
    - Level 1 / 2: needs the approval flow first, and `no_reject` must be false. Status = Rejection Review (Manager of that department).
19. `POST /work-orders/{id}/modification/decision` { decision: approve | reject, remarks }
    - Manager of the target (or assigned) department: approve → goes to the Manager of the requestor department. Reject → the proposal is dropped, and the WO goes back to Waiting Approval (Senior).
    - Manager of the requestor department: approve → copies the proposal into the WO, status Approved. Reject → drops the proposal, status Approved with the old values.
20. `POST /work-orders/{id}/rejection/decision` { decision: confirm | cancel, remarks }
    - Manager of the target (or assigned) department: "Yes, Reject" → goes to the Manager of the requestor department. "No, Cancel" → back to Waiting Approval (Senior).
    - Manager of the requestor department: accept → Rejected (final). Refuse → back to the Senior, with `no_reject = true` (only Approve or Modify).

**Approval route and approval process tables (TD18, 25 Nov; design only, not built):**
- **Route:** the requestor picks a route from the approval route list (`GET /approval-routes?category=work_order`). The backend checks the same rule as the list: category `work_order`, `is_active`, not deleted, and the route department is in the user's active departments (`IDepartmentContext`). Today Create accepts any active route (WO-T05 does not read it).
- **Approvers:** the route users (`approval_route_users`, level = Layer) are copied to `work_order_approvers` at submit. `approvers[]` on the form wins over the route (decision 4).
- **SLA:** for each layer: `approvers[].sla_days`, else the route template (`approval_route_level_slas`), else the global default (`ApprovalSlaService.ResolveSlaDays`).
- **Approval process tables** (same as `ActionPlanApprovalService.OpenProcessAsync`):

| Table | When | What |
|---|---|---|
| `approval_processes` | Submit (a WO with steps) | `reference_id` = WO id, `approval_flow` = `Work Order` (proposal), `latest_approval_level` = the pending layer, `status` = `active`. One process for each WO Level (0, 1, 2). |
| `approval_logs` | Submit, then each action | `initiate` at level 0 on submit; `approve` / `reject` with the layer, `remarks` and `reference_status` (the WO status after the action). |
| `approval_process_levels` | Each layer that opens | `ApprovalSlaService.OpenProcessLevelAsync` (started, due date in working days). Closed with the outcome on approve / reject (`CloseOpenProcessLevelsAsync`). |

- **On approve:** close the open level, write the `approve` log, move `latest_approval_level` to the next layer and open its level. After the last layer: `status` = `approved`, and the WO goes to the next Level.
- **Lists:** `MyTaskList` filters `approval_processes` by `approval_flow`. Add the `Work Order` flow there (WO-T23).
- **Round = stage (TD19):** no cycle table. One approval round = the `work_order_approvers` rows of one `level` + `stage`; one `approval_processes` row for each round. Do not copy the Action Plan cycle rules (PO review first, reject once per plan, return to PO).
- **Submit opens Level 0 (TD20):** the requestor picks the flow on the Create form. Submit copies the route steps (or `approvers[]`) to `work_order_approvers` (Level 0, stage 1), opens `approval_processes` (`latest_approval_level` = 1), writes the `initiate` log and opens the Layer 1 timer, in the submit transaction. A category with no approval (R1) opens no process.
- **Reject at Level 0 (TD21):** its own approval route, category `wo_reject_level_0`. A Level 0 reject opens a second process (flow proposal `Work Order Reject Level 0`) with the users of that route. After its last level → Rejected. A "no" at any level → back to the Level 0 approval. Open: who sits on this route, and is it one route for each department (like `work_order`)?
- **Flow names (TD22, decided):**

| `approval_flow` | Department that owns the route | Route picked by | When the process opens |
|---|---|---|---|
| `Work Order Level 0` | Requestor department | Requestor, on the Create form | Submit |
| `Work Order Level 1` | Target department (Request To) | Target department, Set Approval Flow (#21) | Level 0 approved |
| `Work Order Level 2` | Transfer or Disposition department | That department, Set Approval Flow (#21) | After Transfer / Disposition |
| `Work Order Reject Level 0` | Requestor department (`wo_reject_level_0`) | Backend (TD21) | Level 0 reject |

- **3 routes from 3 departments (TD22):** each Level uses a route of its own department. The route list rule (my departments) gives each department only its own routes.
- **Permission ID per layer (TD22):** each route layer holds a permission ID. The FE fetches the users who can review with `GET /users/by-permission/{id}?department=` (TD11, TD13, §3.1). This needs the route layer change of §3.2 (WO-T03, not now).
- **Not now:** no change to the approval route module (WO-T03 skipped; the new categories `work_order` and `wo_reject_level_0` need it) and no change to the Create code (WO-T05). Build this with WO-T10 / WO-T12.

### 2.6 Set Approval Flow (Level 1 and Level 2)
21. `POST /work-orders/{id}/approval-flow` { approval_route_id }
    - Allowed when the status is Waiting Approval, at Level 1 or Level 2, for a user of the department of that Level.
    - Copies the steps of the selected route into `work_order_approvers` for that Level.
    - Then the Senior can use Modify and Reject. The success message is "Set work order approval flow succeed".
22. `GET /work-orders/{id}/approvers?level=&layer=`: the users who can act on a step. It is made from the permission ID of the layer and filtered by the department of the Level (it calls `/users/by-permission` logic with the department filter).

### 2.7 Transfer and disposition
23. `GET /work-orders/{id}/transfer-options`: the department list for the target department, and the sub-units (PE / PO / RAM / WO-WS).
24. `POST /work-orders/{id}/transfer` { department, sub_unit, notes? }
    - Only at Level 1, only in Approved. Notes are optional.
    - Status = Waiting Approval at Level 2 (the assigned department). The assigned department then uses Set Approval Flow.
    - Level 2 cannot transfer.
25. `POST /work-orders/{id}/disposition` { work_type, pic_ids[], notes? }
    - Only in Approved (Level 1 or Level 2).
    - Work Type rules: ABI/BD only for Projects and PO; ABI/NBD only for OSF; ABO Routine and ABO Non Routine for all departments.
    - Status = Project Preparation.

### 2.8 Project link
26. `GET /work-orders/{id}/project-prefill`: the values for the "Create Project" form: description = WO title, project number = WO number, category / class from the project class mapping, field, RKAP, WBS, department, schedule type.
    - The project is made by the changed project endpoint (§3.5), not by a new WO endpoint.

---

## 3. Endpoints to change

### 3.1 Users by permission
- `GET /users/by-permission/{permissionId}?department=`: add an optional department filter (`users.department`).
- `IsRetinaOnlyPermissionAsync` (`UsersService.cs:560`): replace the fixed list (161, 162, 163) with a list from `custom_configurations`, so a new Retina-only WO permission works without a code change.

### 3.2 Approval routes
- `POST /approval-routes`, `POST /approval-routes/{id}/update`, `GET /approval-routes`, `GET /approval-routes/{id}`:
  - Accept the category "Work Order - {Department}" (one constant, for example `work_order`, plus `department_id`).
  - For each step, store the **Level (0/1/2), the Layer (1/2) and the permission ID** (and the SLA days). Today a level holds users only. Proposal: a new table `approval_route_wo_layers` (`approval_route_id`, `wo_level`, `layer`, `permission_id`, `sla_days`), or new columns on `approval_route_users` (`layer`, `permission_id`, with `user_id` nullable).
  - The admin can select any permission and any department (no position check).
- Add `CategoryWorkOrder` to `ApprovalRouteV2Constants`, or to the route category list that `ApprovalRoutesService` checks.

### 3.3 WO number
- `WorkOrderNumbers`: read the format from `custom_configurations` (not fixed in the code). The WO module and the Action Plan use the same counter.
- The existing preview logic is reused by `GET /work-orders/next-number`.

### 3.4 Action Plan
- `POST /well-surveilence/action-plans/{pep|phss}/submit`: accept `work_order_id`. When it is set:
  - The AP takes the WO number. It does not make a new number.
  - The AP uses the approval route of the WO.
- The AP Finish (parameter update) is required. When the WO has a project too, Finish of the WO closes all its schedules.

### 3.5 Projects
- `POST /projects/{projectId}` (save) and `POST /projects/submit`:
  - Accept `work_order_id` and set the origin flag (`work_order`).
  - Skip the WBS rule when `work_order_id` is set (WBS is optional for a WO).
  - An Action Plan WO skips the project approval. The project goes to "in progress".
  - The schedule type comes from the WO department: detailed (Project, OSF) or simple (all others). No `.mpp`.
- `POST /projects/{id}/tasks/simple-schedule`: no change in the API. Check that the rows look like `.mpp` rows (see `02` §10).
- `POST /projects/approval`: when a WO project is approved → WO status On Going. When it is rejected → WO status Project Preparation.
- Project Finish: when the project has a `work_order_id`, show the WO parameter update (required). When all schedules of the WO are finished → WO status Completed.
- Project approvers for a WO project: the users with the Layer 2 permission in the PIC's department (open question Q36).

### 3.6 Task and approval lists
- `GET /my-approval-list`: add the WO steps where the user is a copied approver of the current step.
- Notifications: in-app, one `notification_templates` row per event. See §6.

### 3.7 Configuration (`custom_configurations`, no new endpoint)
- `work_order.request_to`: the 11 departments, and which ones show Category and Function.
- `work_order.categories`: Category and Function for each Request To.
- `work_order.schedule_type`: simple / detailed for each department.
- `work_order.transfer_departments`: the department list and sub-units for each department.
- `work_order.disposition_work_types`: the Work Types for each department.
- `work_order.number_format`.
- `permissions.retina_only_ids`.
- Existing: `work_order_department_short_names`.

### 3.8 Permissions and route gate
- Seed the new privileges (Read, Create / Submit, Process, Approve Layer 1, Approve Layer 2, Set Approval Flow, Transfer). See `02-Knowledge.md` §9 for the numbers.
- Add the new routes to the RBAC sheet ("Phantom PHI Mapping") and to `RbacRouteMaps`.
- **Open:** the decision says the backend does not check the permission ID on actions. Does the **route gate** (`RbacRouteMaps`, the menu and page access) still apply to the WO routes? Proposal: yes for page access (read / create), no for the approval actions.

---

## 4. Build order (proposal)

| Phase | What | Why first |
|---|---|---|
| 1 | Schema (PR #1523 with our fixes), config keys, `WorkOrderNumbers` format, `/users/by-permission` department filter, approval route layers with permission ID | Every other endpoint needs these. |
| 2 | Form options, next number, draft, submit, details, list, overview, attachments | The requestor can make and see a WO. |
| 3 | Level 0 approve / modify / reject, bulk approve, histories | The requestor department can finish its steps. |
| 4 | Set Approval Flow, Level 1 approve / modify / reject, the two decision endpoints, approvers list | The target department can finish its steps. |
| 5 | Transfer, disposition, project prefill, project and AP changes, finish | Execution and close. |
| 6 | My approval list, notifications, the urgent 2 × 24 h job (if the team keeps it) | Support work. |

## 5. Open points for this plan
1. **Route gate:** does `RbacRouteMaps` still guard the WO pages? See §3.8.
2. **Route steps:** store them in a new table or as new columns on `approval_route_users`? See §3.2.
3. **Urgent WO:** keep the 2 × 24 h bypass job? Only the MoM has it.
4. **Transfer PIC:** does the Transfer window still take a PIC (MoM 19 Nov), or only the department and the sub-unit?
5. **Study category:** the study review and study approval endpoints are not in this plan. The team doc has no text for them yet.

## 6. Notifications

### 6.1 How a notification is sent (code, 25 Nov)

- The notifier calls `INotificationDispatcher.StageFromTemplateAsync(templateName, recipients, placeholders, webLink)`. The Action Plan uses `ActionPlanApprovalNotifier` this way.
- The dispatcher reads the template from `notification_templates` (`type = 'notification'`, by `name`). It writes one `notifications` row per recipient, with `title`, `message`, `web_link`, `user_id`, `notification_template_id` and `notification_category_id`.
- If the template row is missing, nothing is sent. The log shows "Notification template '…' not found".
- Placeholders: `{{wo_number}}`, `{{department}}`, `{{fullname}}` (added per recipient), and `{{reason}}` for reject events.
- Web link: `/work-order/{id}` ("Go to Work Order"). Project events use the project page ("Go to Project").
- Email: the team doc says in-app only (I5). Project approval also sends an email, but that email body is in the code, not in a table. So email needs no table rows. Decided 25 Nov (TD17): a project made from a WO sends no email, in-app only.

### 6.2 List of WO notifications

Proposed template names use the `phantom_iac_wo_` prefix. Source: the notification table in the team doc (Knowledge Documents, its own §6) and the WO-x acceptance criteria in `02-Knowledge.md`.

`Type` = how the notification reaches the user: **In-app** (Notification Center, one `notifications` row) or **Email** (`IMailerService`). The team doc says in-app only for every WO event. Decided 25 Nov (TD17): **every** WO notification is in-app only, also N16 / N17. The project approval flow (`ApprovalNotifier`) sends an email today; for a project made from a WO (it has a WO number), do not send that email.

| # | Event (endpoint) | Title (team doc) | Recipients | Type | Category | Color | Template name (proposed) |
|---|---|---|---|---|---|---|---|
| N1 | Submit (#8 Create) | Work Order Approval Request | Users of Layer 1 Level 0 (requestor dept) | In-app | Request | info | `phantom_iac_wo_approval_request` |
| N2 | Approve Layer 1 Level 0 | Work Order Approved at Level 1 | Manager Requestor (Layer 2) + Requestor | In-app | Approval | info | `phantom_iac_wo_approved_level_1` |
| N3 | Approve Layer 2 Level 0 | Incoming Work Order Request | Users of Layer 1 Level 1 (target dept, `request_to`) | In-app | Request | info | `phantom_iac_wo_incoming_request` |
| N4 | Approve Layer 2 Level 0 | Work Order Approved at Level 2 | Requestor | In-app | Approval | info | `phantom_iac_wo_approved_level_2` |
| N5 | Modify at Level 0 (X2) | Work Order Modified by Manager | Requestor (+ Senior, M10) | In-app | Approval | warning | `phantom_iac_wo_modified` |
| N6 | Reject at Level 0 | Work Order Rejected | Requestor (with fields to revise) | In-app | Approval | danger | `phantom_iac_wo_rejected` |
| N7 | Re-submit after reject (D3, open) | Work Order Revised by Requestor | Senior + Manager Requestor (M9) | In-app | Request | info | `phantom_iac_wo_revised` |
| N8 | Approve Level 1 (target) | Work Order Approved by Target Department | Requestor | In-app | Approval | success | `phantom_iac_wo_approved_target` |
| N9 | Modify request at Level 1 / 2 | Modification Verification | Manager Requestor (Layer 2 Level 0, X4) | In-app | Request | warning | `phantom_iac_wo_modification_verification` |
| N10 | Modification OK = Yes | Modification Approved | Requestor + Level 1 (+ Level 2 if transferred) | In-app | Approval | success | `phantom_iac_wo_modification_approved` |
| N11 | Reject at Level 1 (needs approval) | Rejection Approval | Manager of the target dept | In-app | Request | warning | `phantom_iac_wo_rejection_approval` |
| N12 | Rejection = Yes, Reject | Work Order Rejected | Requestor + all levels | In-app | Approval | danger | same as N6 (`phantom_iac_wo_rejected`) |
| N13 | Transfer | Transferred Work Order | Users of the assigned dept (Level 2) | In-app | Request | info | `phantom_iac_wo_transferred_in` |
| N14 | Transfer | Work Order Transferred | Requestor | In-app | Approval | info | `phantom_iac_wo_transferred` |
| N15 | Create Disposition | Disposition Created | PIC + Requestor | In-app | Approval | info | `phantom_iac_wo_disposition_created` |
| N16 | Submit project (from WO) | New Project Approval | Project approvers (Q36, open) | In-app (no email, TD17) | Request | info | existing project approval template (check) |
| N17 | Project approved | Project Approved | PIC | In-app (no email, TD17) | Approval | success | existing project template (check) |
| N18 | Project returned | Project Returned | PIC (with reason) | In-app | Approval | warning | `phantom_iac_wo_project_returned` |
| N19 | Finish project | Work Order Completed | Requestor + Senior Officer | In-app | Approval | success | `phantom_iac_wo_completed` |
| N20 | SLA escalation (if kept, §8) | Work Order Escalated | Next approver + skipped approver | In-app | Request | warning | `phantom_iac_wo_escalated` |

- Bulk Approve sends the same notification as a single Approve (N2 / N3 / N4 / N8) for each WO.
- A category with no approval (R1): open Q24, proposal = still send N3 to the target dept.
- A well WO (Action Plan) keeps the 12 `phantom_iac_*` Action Plan templates (`seed_action_plan_notification_templates.sql`). Map or replace them (I5, open).

### 6.3 Tables to insert for each template

| Table | What to insert | Notes |
|---|---|---|
| `notification_categories` | Nothing new, if `Request` and `Approval` exist | The Action Plan seed already uses these two names. The template takes the category id with `(SELECT TOP 1 id FROM notification_categories WHERE name = '…')`. A new tab name needs a new row (`id`, `name`, `sort_order`, `created_at`). |
| `notification_templates` | One row per template name in the list above (N16 / N17 only if no project template exists) | Columns: `id` (literal GUID, proposed range `22222222-2222-2222-2222-2222222250xx`), `name`, `title`, `message` (HTML), `notification_category_id`, `color_code` (`info` / `warning` / `success` / `danger`), `type` = `notification`, `created_at`, `created_by`. Same pattern as the Action Plan seed: `INSERT … WHERE NOT EXISTS`, then `UPDATE` of the title and the message, so the script can run again. |
| `notifications` | Nothing (seed) | The dispatcher writes these rows at run time. |
| Email | Nothing | Email bodies are in the code (`ApprovalNotifier`). |

- **Source of the HTML:** the FE team makes one file per template in `ocean-email-template/phantom/notification_inapp_content/<name>.html`. The Action Plan templates came from that repo (PR #23)[https://github.com/rinaldyocean/ocean-email-template]. Ask the FE team for the WO files first.
- **New seed file (to do):** `DataAccess/Database/seed_work_order_notification_templates.sql`. Run it after `seed_work_order_config.sql`.

### 6.4 Open points

- N16 / N17: check if the project module already has approval templates before adding new ones.
- No-approval category (R1): does the target dept still get N3? Open Q24, proposal = yes.
- Well WO: keep the 12 Action Plan `phantom_iac_*` templates, or map to the WO templates (I5).
- ~~Email~~ Decided 25 Nov (TD17): in-app only. Code to do: `ApprovalNotifier` must skip the email when the project has a WO number.
- N7 depends on the re-submit decision (D3).

---

## 7. Create WO: implementation plan (25 Nov, waits for OK)

Goal: one PR to `phi-dev` that lets the requestor fill the Create Work Order form, save a draft, and submit it.

### 7.1 State today
- Built and **staged** in `.worktrees/wo-draft` (branch `feat/work-order-draft`): #6 save draft, #7 update draft, #8 create (submit), multipart parser, config reader, seed `seed_work_order_config.sql`, 9 tests in `WorkOrderFormTests.cs`, Bruno requests.
- Not built, tests not run.
- The branch base is old (`d6149aca`, the #1533 branch). `phi-dev` now has #1539 (`field_id` as text). Both change `WorkOrdersService.cs`, so one conflict is expected.

### 7.2 Steps
| # | Step | Detail |
|---|---|---|
| 1 | Update the base | Make a patch of the staged changes. Reset the branch to `origin/phi-dev`. Apply the patch with `--3way`. Fix the conflict in `WorkOrdersService.cs` by hand (keep the #1539 `field_id` text rule). |
| 2 | Add #3 `GET /work-order/next-number` | Preview only. `WorkOrderNumbers` preview with the requestor department short name. No number is taken. |
| 3 | Add #4 `GET /work-order/form-options` | One call: Request To (code + label, Category / Function on or off), categories per Request To, urgency levels, budget types, `categories_without_approval`. Source: `custom_configurations` (`WorkOrderConfig`). Schedule kind is not in the form (the BE sets it). |
| 4 | Add #9 `POST /work-order/{id:guid}/delete` | Soft delete. Only the creator (403), only a draft (400), 404 if not found. One history row. The number is not given back (gap in the sequence). |
| 5 | Tests | Add: next number, form options, delete draft (owner / not owner / not draft), submit with a no-approval category, the 5-file limit, the code → department match. |
| 6 | Build and test | `make build`, `dotnet test` (check the build exit code first), `make check-migrations` (no new migration expected). Only after your OK. |
| 7 | Seed on dev | Run `seed_work_order_config.sql` on dev. Only after your OK. |
| 8 | Bruno | Add Next Number, Form Options, Delete Draft, with example responses. Stage only. |
| 9 | Stage and PR | Stage only. You commit: `[PHI-xxxx] feat(work-order): create work order (draft, submit, form options)`. PR to `phi-dev` with the endpoint table and the test result. |

### 7.3 Not in this PR (later PRs)
- Approval route layers with a permission ID (§3.2). Until then the approver steps come from the `approvers` field, or from the route users (route level = Layer). `work_order_approvers.permission_id` stays empty.
- `/users/by-permission` department filter (§3.1).
- Action Plan link (§3.4). The Action Plan key stays in the `submitted` history snapshot.
- Notifications on submit (§6).
- Attachments after create (#12, #13) and details (#10).

### 7.4 Decisions needed
1. Put #3, #4 and #9 in this PR? Proposal: yes. The form needs #3 and #4, and all three are small.
2. The Jira ticket number for the commit.
3. Until §3.2 is built, keep the route users as the Layer 1 / Layer 2 approvers? Proposal: yes.
4. Times (`created_at`, `submitted_at`): UTC or WIB? Proposal: UTC, like the other modules; the FE shows WIB.
