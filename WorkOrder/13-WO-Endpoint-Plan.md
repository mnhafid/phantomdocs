# Work Order: endpoint plan (new and changed)

Status: **plan only**. Nothing is built. Made on 24 Nov from the current decisions (`00-Decision-Log.md`, `11-TeamDoc-Decisions-24Nov.md`, `12-WO-Status-Flow.md`) and a check of the code (`phi-dev`) and the dev database.

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
   - **Update 24 Nov:** reuse the existing endpoints instead of a new one. Search = `GET /approval-routes?category=work_order&department_id=&search=&status=active` (the filters exist today). The selected route's progress (steps, Layer, permission, SLA, the approvers listed by permission + department) = `GET /approval-routes/{id}`. See §3.2 for the change and `14` §2 for the screen.

### 2.3 Create, draft and submit (Level 0)
6. `POST /work-order/draft` (JSON body): saves a Draft. Takes the WO number. Saves the WO PICs. **Built 24 Nov** (branch `feat/work-order-draft`, staged, not built). Files are not in this call: the FE sends them with #12 after the draft has an id.
7. `POST /work-order/draft/{id}` (JSON body): updates my own Draft. Replaces every field and the requestor PICs; the WO number stays. 404 / 403 (not the creator) / 400 (not a draft). **Built 24 Nov** (same branch).
8. `POST /work-orders/submit` (multipart; with `id` for a saved draft, or a new WO):
   - Checks the mandatory fields.
   - Sets `schedule_kind` from the department (the user does not send it).
   - If the category needs no approval: skips all steps. Status = Approved at Level 1.
   - Else: copies the steps of the selected Level 0 flow into `work_order_approvers`. Status = Waiting Approval, Level 0 / Layer 1.
9. `POST /work-orders/{id}/delete`: deletes a Draft (soft delete). Only the creator, only in Draft.

**Draft rules (checked on `phi-dev`, 24 Nov; #6 and #7 built on `feat/work-order-draft`, #8 and #9 not built yet):**
- Status `draft`, `current_level` 0, `current_layer` 0. No `work_order_approvers` rows until Submit.
- `wo_number` is NOT NULL and unique among rows with `deleted_at IS NULL`. So #6 must take a real number: two drafts with `""` would break the index. A deleted draft leaves a gap in the sequence.
- List (merged #1533): a draft shows only in **Outgoing**, only to its creator. It never shows in Incoming, and other users of the department do not see it.
- Overview (merged #1530): `draft_wo` counts my drafts. `total_wo` includes them. `received_wo` and `submit_wo` do not.
- Working area: `phss` / `pep` match through `fields.working_area`. A draft with no field shows only under `zone9`. The draft needs a field, or the FE uses `zone9`.
- Body of #6 / #7 (all optional; sent values are checked): `wo_number` (create only), `title`, `description`, `urgency_level` (`Regular` | `High Priority`), `request_to`, `function`, `category`, `type_service`, `field_id`, `area_id`, `location`, `start_date` / `end_date` (`dd-MM-yyyy`, end >= start), `wbs[]`, `rkap_id`, `budget_type`, the 6 production values, `approval_route_id` (active route), `pic_ids[]`. Response `{ id, wo_number, status, created_date }`. A used number = 422.
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
    - Level 0: final. Status = Rejected.
    - Level 1 / 2: needs the approval flow first, and `no_reject` must be false. Status = Rejection Review (Manager of that department).
19. `POST /work-orders/{id}/modification/decision` { decision: approve | reject, remarks }
    - Manager of the target (or assigned) department: approve → goes to the Manager of the requestor department. Reject → the proposal is dropped, and the WO goes back to Waiting Approval (Senior).
    - Manager of the requestor department: approve → copies the proposal into the WO, status Approved. Reject → drops the proposal, status Approved with the old values.
20. `POST /work-orders/{id}/rejection/decision` { decision: confirm | cancel, remarks }
    - Manager of the target (or assigned) department: "Yes, Reject" → goes to the Manager of the requestor department. "No, Cancel" → back to Waiting Approval (Senior).
    - Manager of the requestor department: accept → Rejected (final). Refuse → back to the Senior, with `no_reject = true` (only Approve or Modify).

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
- `POST /projects/{id}/tasks/simple-schedule`: no change in the API. Check that the rows look like `.mpp` rows (see `08`).
- `POST /projects/approval`: when a WO project is approved → WO status On Going. When it is rejected → WO status Project Preparation.
- Project Finish: when the project has a `work_order_id`, show the WO parameter update (required). When all schedules of the WO are finished → WO status Completed.
- Project approvers for a WO project: the users with the Layer 2 permission in the PIC's department (open question Q36).

### 3.6 Task and approval lists
- `GET /my-approval-list`: add the WO steps where the user is a copied approver of the current step.
- Notifications: new templates for submit, approve, modify, reject, transfer, disposition and finish. Use `IMailerService`.

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
- Seed the new privileges (Read, Create / Submit, Process, Approve Layer 1, Approve Layer 2, Set Approval Flow, Transfer). See `09-WO-Permission-Level-Plan.md` for the numbers.
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
