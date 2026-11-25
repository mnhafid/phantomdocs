# Work Order: approval route

First written 20 Nov 2026. **Updated 24 Nov** with the decisions from the team doc and the user (`11-TeamDoc-Decisions-24Nov.md`, decisions TD1–TD16 in `00-Decision-Log.md`). The status flow is drawn in `12-WO-Status-Flow.md`.

Goal: Data Config holds the WO approval routes. The people in each department select the route by hand. A layer of the route holds a permission ID.

---

## 0. Words (MoM 19 Nov, Level names updated 24 Nov)

- **Level = which department**
  - **Level 0** = the requestor department.
  - **Level 1** = the target department (the Request To).
  - **Level 2** = the assigned department. It exists only after a Transfer.
- **Layer = which step inside that Level**
  - **Layer 0** = PIC / requestor (the person). Layer 0 never approves.
  - **Layer 1** = Senior / Asst. Manager.
  - **Layer 2** = Manager.
  - The system does **not** check the position. "Layer 1 = Senior, Layer 2 = Manager" is an SOP (a work rule) only. Reasons (team doc comments, 20 Nov): Retina data can have errors, and it keeps the system simple.
- **Writing a step:** "Layer *n* Level *m*". Example: "Layer 2 Level 1" = the Manager step of the target department.
- **In the database:** the route tables use `level` for the order of the steps inside one route. To keep one meaning for each word:
  - **WO Level (0/1/2)** is stored as `wo_level`.
  - **The order inside a route** is stored as `layer`.

### What each step may do
- **Layer 1 and Layer 2 of Level 0:** approve the submitted WO. A Modify at Level 0 changes the WO and approves it in one step. The requestor gets a notification only.
- **There is no skip** when the requestor is a Senior. Another user with the Layer 1 permission reviews the WO.
- **Layer 1 Level 1:**
  - **Approve** needs no route. After Approve: Transfer (to Level 2) or Create Disposition.
  - **Modify** and **Reject** need the Level 1 route first ("Set Approval Flow"). After the route is set, the page shows only Modify and Reject (no Approve).
- **Modify at Level 1:** the change stays a proposal.
  1. Layer 2 Level 1 approves or rejects it. A reject drops the proposal, and the WO goes back to Layer 1 Level 1 with the old values.
  2. Layer 2 Level 0 (the requestor Manager) checks it. OK = the system copies the proposal into the WO, and the WO goes to Approved. Not OK = the system drops the proposal, and the WO goes to Approved with the old values.
- **Reject at Level 1:** two confirmations.
  1. Layer 2 Level 1: "Yes, Reject" or "No, Cancel". "No, Cancel" sends the WO back to Layer 1 Level 1.
  2. Level 0 (the requestor Manager) accepts or refuses the rejection. Accept = Rejected (final). Refuse = the WO goes back to Layer 1 Level 1 with the Reject button hidden (only Approve or Modify).
- **Level 2:** the same as Level 1, except that Level 2 can only make a Disposition. It cannot transfer again.
- **Rejected at Level 0:** final. The requestor makes a new WO with a new number.
- **A category with no approval:** the WO skips all approval steps (Level 0 too) and goes to Approved.

---

## 1. Today: what limits us
- **One route for each `category` text.**
  - Example: `action_plan_pep_well_test`.
  - Lookup: `FindRouteAsync` takes the newest active route with that category (`ActionPlanApprovalService.cs:704`).
- **"Needs approval" is in the code.** `ActionPlanApprovalRules.RequiresApproval` covers only `well_test` and `artificial_lift` (WHC + installation).
- **The approver is a fixed user for each step** (`approval_route_users.level`). The WO needs a permission for each step instead.
- **Fixed steps in the code.** The SSDP creator is added as the last Modify step, and Reject uses managers only.
- **SLA for each step only.** Urgency does not change the SLA. The MoM wants urgent = 2 × 24 h, and then the WO goes to the next step, and the system records this.
- **SPK v2 levels (`approval_route_levels`, paraf / full sign) are for SPK only.** They do not fit the WO.

---

## 2. The design (24 Nov)

### 2.1 Who selects the route, and when
| WO Level | Who selects the route | Where | When the system copies the steps into the WO |
|---|---|---|---|
| Level 0 | The requestor | Create Work Order, field "Approval Flow" | At Submit |
| Level 1 | A user of the target department | "Set Approval Flow" window on WO Details (status Waiting Approval, Incoming or Outgoing tab) | When the user submits the window |
| Level 2 | A user of the assigned department | The same "Set Approval Flow" window, after a Transfer (status goes back to Waiting Approval) | When the user submits the window |

- The requestor route has only the Level 0 steps (Layer 1, then Layer 2). The old step "Senior of the target department" is removed from it.
- If the requestor needs a route that does not exist, the requestor must make it first in Data Config "Approval Route".
- The Level 1 and Level 2 routes are used for the approval of a **Modify** and of a **Reject**.

### 2.2 How a route is set up (Data Config "Approval Route")
- Route category: **"Work Order - {Department}"**.
- Each route has Level 0, Level 1 and Level 2. Each Level has **Layer 1** and **Layer 2**. There is no Layer 3.
- **Each layer holds a permission ID.** The approvers of a layer = every active user who has that permission **in the department of that Level**.
  - Example: a PO Senior with the permission does not review an OSF WO.
- The system lists the approvers with `GET /api/v1/users/by-permission/{permissionId}`.
  - That endpoint has **no department filter** today. The WO flow must filter the list by the department of the Level.
  - `GetUsersByPermissionAsync` reads casbin, or Retina for a fixed list of ids (161, 162, 163 in `IsRetinaOnlyPermissionAsync`, `UsersService.cs:560`). A new WO permission that exists only in Retina must be added to that list. If not, the endpoint returns no users.
- **Backend rule:** the permission ID is used **only to list users**. The backend does **not** check the permission ID to allow or block Approve, Modify or Reject.

### 2.3 Copy the steps into the WO
- When a department sets its route, the system copies that department's steps into `work_order_approvers`. A later change in Data Config does not change a running WO.
- The system does **not** copy all Levels at Submit. The Level 1 and Level 2 steps are not known at Submit.
- The copy must let one person appear in more than one step. Example: the requestor Manager approves at Submit and again checks a modification. So the unique key must include the step (Level, Layer, stage), not only `(work_order_id, user_id)`.
- Each copied step stores the permission ID and the department of the Level (or the user list made from them).

### 2.4 Urgent WO (check with the team)
- MoM: each layer has 2 × 24 h. After that, the WO goes to the next layer, and the system records this ("bypassed").
- Proposal: add `sla_hours_urgent` to `approval_route_level_slas`. `sla_days` stays for Regular.

---

## 3. Replaced 24 Nov: automatic route search

The 20 Nov proposal had an automatic route search: `approval_route_bindings` (the most specific match of requestor department, Request To, function, category and urgency won), and `approval_route_layer_rules` with the approver types `users`, `permission`, `position`, `level0_manager` and `requestor`, plus skip rules (`skip_if_requestor_holds`). The team chose **manual route selection** and **a permission ID for each layer** instead. So the bindings, the position type, the `level0_manager` type and the Senior skip rule are **not used**. The ideas that stay: the WO Level on each step (`wo_level`), the copy of the steps into the WO, the urgent SLA, and the two-confirmation reject.

---

## 4. Migrating today's Action Plan routes
- Under the "WO is the parent" decision, the Action Plan uses the route of its WO when the WO goes live.
- The PO review pool (config `action_plan_review_permission_id` = 161) becomes the permission of Layer 1 Level 1 for PO.
- The fixed "SSDP creator as the last Modify step" goes away. The requestor Manager (Layer 2 Level 0) checks a modification.
- An Action Plan WO skips the project approval.

---

## 5. Data Config screen (Approval Route)
- **Route list:** filter by category ("Work Order - {Department}").
- **Route form:** for Level 0, Level 1 and Level 2, one card for each layer (Layer 1, Layer 2): the permission, the SLA Regular / Urgent.
- **Validation on save:** each layer that is used needs a permission ID.

---

## 6. Open questions
| # | Question | Answer |
|---|---|---|
| R1 | Does "no approval" also skip the Level 0 steps? | **Decided 20 Nov: skip the whole chain.** |
| R2 | One approver or all approvers for each layer? | Open. Proposal: one approver (the first one decides), as today. |
| R3 | How does the system find Layer 2 Level 0 (the requestor Manager)? | **Decided 24 Nov:** by the permission ID of the layer, in the requestor department. |
| R4 | Can a reviewer change the approvers of a running WO? | Open. Proposal: no. Only the route that the department selects sets them. |
| R5 | Do Modify and Reject routes differ by WO category? | **Replaced 24 Nov:** each department selects its own route by hand. |
| R6 | Does urgency change the route, or only the SLA? | Proposal: only the SLA (2 × 24 h, then bypass). Check with the team. |
| R7 | Scope for the 4 Dec launch | Open. Proposal: manual route selection, permission per layer, department filter on the user list, copy of the steps, two-confirmation reject, modify check. Urgent bypass if there is time. |
| R8 | Reject at Level 1: one confirmation or two? | **Decided: two** (MoM). Layer 2 Level 1, then Level 0. |
| R9 | Does Layer 0 (PIC) ever approve? | **Decided: no.** Layer 0 is only the actor (requestor / PIC). |
