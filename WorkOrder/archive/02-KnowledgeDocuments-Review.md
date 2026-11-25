# Review: Knowledge Documents — Work Order Module (PHANTOM)

Reviewed 2026-11-18 · Knowledge Documents rev 11 (claude.ai/artifact/3A8M7RGwuGg1RnGYuyedah) · Design version 1795000848-2b2b
Updated 2026-11-19 with the Figma "PHI - Latest Design" › Work Order page and the newer prototype it links to (claude.ai/artifact/S4gBiqBpHasmfJnZKQQZMu, version 1795050409-bd7a). See § "Figma flow + newer prototype".

> **Status 24 Nov.** This file records the review of 18–19 Nov. Do not change the findings. Many decisions in the table below were changed later:
> - **D3:** changed (a declined rejection goes back to the target Senior without the Reject button).
> - **D5:** changed (the format comes from `custom_configurations`).
> - **D7:** changed (the Finish parameters are required).
> - **D2:** changed. The approval flow is not found by rules. The requestor selects the Level 0 flow, and the target and assigned departments select theirs in "Set Approval Flow". Each layer holds a permission ID. The backend uses it only to list users, in the department of the Level.
> - **The position skip rule:** removed. Another Senior reviews the WO.
> - **F12 (Prime Mover):** open again as Q46. The Figma Gas Lift form marks it as required.
>
> For the current rules, read `00-Decision-Log.md`, `04-KnowledgeDocuments-WorkOrder.md`, `11-TeamDoc-Decisions-24Nov.md` and `12-WO-Status-Flow.md`.

**Sources**
- `uni` = `project/WO-Prototype-ycvm-uni.dc.html` (line numbers are given as `uni:L####`)
- `Status` = `project/WO-Status.dc.html`
- `Compare` = `project/WO-Modify-Compare.dc.html`
- `AP` = the current Action Plan approval code, worktree `.worktrees/action-plan-al-wt/src-be` (PR #1476, uncommitted working tree)
- `docs/` = `docs/ActionPlan/*`

**Verdict:** the Knowledge Documents matches the prototype well. All 28 codes, the 15 labels, the 8 personas, the button set per status, the upload rules, the WBS chips, the schedule engine and most notifications trace back to code.

It has two kinds of problem:
1. **About 20 places where it describes the design wrongly.** One is inverted: which departments get the simple schedule.
2. **It ignores the Action Plan approval that already exists for Artificial Lift (WHC Installation) and Well Test.** That flow already issues WO numbers, has different approvers and different terminal states, and runs on different roles and permissions. The Knowledge Documents cannot be built as written until it says how the two fit together.

---

## Decisions (user, 18 Nov 2026)
These decisions override the findings below. Each row lists what the Knowledge Documents must change.

| # | Decision | Knowledge Documents change it forces | Still open |
|---|---|---|---|
| D1 (C1) | **WO is the parent and the Action Plan is the child.** Routing and approval live on the WO, not on the action plan. | Add a "WO ↔ Action Plan" section. The approval state, cycles, modifications and the WO number move from `pep_/phss_action_plan` to a `work_orders` table. The action plan gets a `work_order_id` FK. The PR #1476 engine is re-hosted on the WO. | Can 1 WO have more than 1 action plan (several wells)? Do Well Surveillance users still create plans per well, or only via Create WO? What happens to plans already on dev that have a WO number? |
| D2 (C2) | **Approval levels are flexible and come from approval routes**, for all three rounds: the submit chain, Modify approval and Reject approval. | Replace the hard-coded chains in FR-2/4/5, §2 and §6: Senior Level → Manager, Manager Lvl n → Manager Requestor. Define them as **default route templates**, with route categories per Request To × round (for example `wo_{dept}_submit / _modify / _reject`). Roles become route levels. §6 recipients become "the next route level". | Is the requestor-side chain (Senior Level, Manager) a route too? Is SSDP still the last route level of Modify (latest AP index note: no creator step)? Who may edit the approvers at runtime (AP today: the PO sends `approvers[]`)? |
| D3 (C3) | **Use today's return behaviour.** Every return → back to the reviewer (`waiting_review`) and the proposal is dropped. The reviewer can approve, modify or reject again. `rejected` is terminal. | Remove: Needs Revision (mr1, mr2), "Revise Action Plan", the "rejection not approved" banner, BR-7 (Reject hidden), and Re-Submit from Rejected (AC-2, OQ3). Decide BR-16 (loop counter). The 15 statuses shrink. | Does terminal also apply to the requestor-side reject (rej1, rej2)? Today there is no such stage. Does the Requestor then create a new WO, with a new number? Keep the loop counter for reporting only? |
| D4 (C4) | **Use today's scope rule.** Only Well Test and AL WHC Installation need approval; the other action-plan categories are auto-approved. | Add a per-category table. Choke, Sonolog, AL Update, non-WHC AL: the WO goes straight to Approved, or skips approval. | Which approval do non-well WO categories get (Maintenance, Plant Upgrading, Heavy Equipment, Well Service…), when they have no action plan? Does an auto-approved WO still get a number and notifications? |
| D5 (C5) | **WO number uses the Knowledge Documents format** `<seq>/WO/PROJECT/<year>`. | Replace `{seq:D4}/WO/{SDA1\|SDA2}/{year}` and the `work_order_department_short_names` config. | Padding (5422 has none; `D4` today)? One counter per year globally? Issued at draft or at submit? Is "PROJECT" literal for every Request To? Do the existing ~50 dev numbers get migrated? |
| C6 | **Settled by the Figma (19 Nov):** Projects (PRJ) and OSF use the project-based (detail) schedule; every other department uses the simple schedule. The Knowledge Documents are inverted. | Fix FR-7/FR-9 (see C6). Add a backend item: simple-schedule rows → `project_tasks` without the `.mpp`/Aspose import. | Does PO's AL Installation get the simple schedule (Figma) or go to Projects Z9 (prototype `CAT_EXTRA`)? Add Compressor Relocation to the PRJ categories? |
| D7 (C7) | **Finish may skip** the result params and document. | FR-8, BR-12 and AC-9 change from "must" to "optional". Remove N7. | Confirm: optional everywhere, or only from the WO header? **Conflict:** the Figma Finish step pops up the parameter update and sends it to the Requestor to check (F3). |
| D8 (C8) | **Bulk approve as the Knowledge Documents say**: only a plain Approve, with Approve Selected and Approve All. | The design must add Approve All, and its eligibility must exclude ma*a, rf*a and sa. Keep AC-15 and AC-16. | Partial failure handling (G3). |

---

## Critical

### C1. The Knowledge Documents invents a WO root entity that collides with the existing Action Plan flow
- **Knowledge Documents say:** the WO is the root. The action plan is an inner step of Create WO ("Submit becomes Next", FR-1), and one 15-status lifecycle covers everything.
- **Current system:** there is no WO entity. The action plan (`pep_action_plan` / `phss_action_plan`) is the root, created per well from Well Surveillance. "WO" is only the `work_order_number` column, stamped at submit. Status lives in `approval_status` (`waiting_review`, `modify_in_approval`, `reject_in_approval`, `approved`, `rejected`).
- **Evidence:** `Logics/Services/ActionPlanApproval/ActionPlanApprovalSubmit.cs:12-40`; `docs/Approval.md` ERD; `docs/approval-route-action-plan.md` §1a.
- **Fix:** add a section "Relationship to existing Action Plan approval" that picks one of these:
  - (a) A new `work_orders` table wraps the plan. Say whether the AP engine is reused or retired, and how `approval_status` maps onto the WO status.
  - (b) The WO is a separate flow for non-well categories, and the well categories keep the AP flow.
  - (c) The WO flow replaces the AP flow. Then say what happens to PR #1476 and to the plans already on dev.

### C2. Approver chain conflicts with the AL/WT flow the user agreed on 18 Nov
- **Knowledge Documents say:**
  - Requestor side: Senior Level, then Manager Requestor.
  - Target side: the Senior Officer reviews.
  - Modify lane: Manager Lvl n, then Manager Requestor.
  - Reject lane: Manager Lvl n, then Manager Requestor.
- **Current system:**
  - There is no requestor-side approval. An SSDP submit goes straight to `waiting_review` at the PO pool (perm 161).
  - Modify lane: route managers Mgr1 → Mgr2, then the **plan creator**, whom the backend auto-appends as the last level; the creator needs no 162/163.
  - Reject lane: **managers only**; all agree → `rejected`.
- **Evidence:** `ActionPlanApprovalService.cs:643-661` (creator appended), `:332-372` (reject round); `docs/02-Changes.md:2-15`; `docs/11-WhiteboardFlow.md:39-45`.
- **Fix:** say whether "Manager Requestor" replaces the creator-as-last-level step. It is a manager in the Knowledge Documents and the creator today, and the Knowledge Documents also adds it to the Reject lane. Say whether the requestor-side L1/L2 stage is new for SSDP too.

### C3. Return and reject semantics are the opposite of today's
| Case | Knowledge Documents | Current system (AP) |
|---|---|---|
| Modification rejected | **Needs Revision** at the Senior Officer, who revises (FR-4) | Back to `waiting_review`; the **proposal is dropped**; `modify_returned` was removed on purpose |
| Rejection not approved | Back to the Senior Officer, **Reject hidden** (BR-7), loop counter +1 | Back to `waiting_review`; the PO **can reject again** (kept on purpose, 18 Nov) |
| Final reject | `Rejected`; the Requestor **Re-Submits** (AC-2) | `rejected` is **terminal and read-only**; SSDP creates a new plan |

- **Evidence:** `ActionPlanApprovalService.cs:391-420`; `docs/02-Changes.md:10,27-29,80,92`; `docs/11-WhiteboardFlow.md:49-51`.
- **Fix:** choose per row and write it into FR-4 and FR-5. If Needs Revision stays, say whether the reviewer's proposal is kept.

### C4. Approval scope: the Knowledge Documents sends every category through approval; today only two do
- **Knowledge Documents say:** every WO, including Choke Adjustment, Sonolog and Maintenance, passes the full chain.
- **Current system:** only `well_test` (all) and `artificial_lift` with `method = well_head_compressor` and `activity_type = installation` need approval. Choke, sonolog, others and non-WHC AL are auto-approved with **no WO number, no notification and no task**.
- **Evidence:** `ActionPlanApprovalRules.cs:37-43` (`RequiresApproval`); `ActionPlanApprovalSubmit.cs:42-62`.
- **Fix:** add a per-category table: does it create a WO, and does it need approval?

### C5. WO number format and timing conflict
- **Knowledge Documents say:** `<seq>/WO/PROJECT/<year>` (for example `5422/WO/PROJECT/2026`), generated "once at creation" (BR-1).
- **Current system:**
  - Format: `{seq:D4}/WO/{dept short name}/{year}`, for example `0044/WO/SDA1/2026` (`WorkOrderNumbers.cs:19-20`).
  - Counter: one per (short name, year) with a lock, in table `work_order_sequences`. That table is dropped by db commit 878c5aba, which is an open conflict.
  - Short names: the config `work_order_department_short_names` maps only SDA1/SDA2. Any other department gets **400**.
  - Timing: issued at **submit**, not at draft. The FE previews it via `GET …/next-wo-number`.
  - Volume: about 50 numbers are already issued on dev.
- **Fix:**
  - Define the middle segment: the literal "PROJECT", the Request To department, or the requestor's department.
  - Define the padding, the counter scope, and whether drafts get a number.
  - Say whether existing AP numbers stay valid.
  - Say whether the follow-up WO from a study gets a new number. The design gives it one (`uni:L2344-2348`), and BR-1 says "never changes … study follow-up".

### C6. FR-7 inverts which departments get the simple schedule
- **Where:** the PIC's **Create Project** dialog (status `pj`), after Disposition. It is not the Create WO form. The rule reads the WO's **Request To** + Category.
- **Example:**
  - A WO to **PO Z9** with Category **Well Test**: Create Project shows **Next**, then step 2, the simple schedule (task grid, On Stream last).
  - A WO to **Projects Z9** with Category **Plant Upgrading**: Create Project shows **Submit** directly, with no schedule step. Presumably those projects get a full schedule (MPP) in Project Monitoring.
- **Knowledge Documents say:** "For **Projects Z9 and OSF Z9** categories, a second step asks for a simple schedule."
- **Design says:** the opposite. Projects Z9 and OSF Z9 get `'detail'`, which has no schedule step. Every other Request To with a specific category gets `'simple'`.
- **Evidence:** `uni:L1520` `const DETAIL_DEPT = ['Projects Z9', 'OSF Z9']`; `uni:L1539` `schedKind = … DETAIL_DEPT.includes(rt) ? 'detail' : 'simple'`; `uni:L2638`.
- **Fix:** reword it: "Requests to WLI Z9, PO Z9, PHSS Field and the 3 PEP fields with a listed category get the simple schedule. Projects Z9 and OSF Z9 use the detailed schedule (define it), and Others / no-category requests get none."
- **Figma confirms the design (19 Nov).** Note "For: OSF Projects ( - RTWS Installation - Gas Lift Installation - Plant Upgrading - Facility Upgrade )" sits on the project-based rows; "For: All besides OSF Projects ( - Artificial Lift Insatallation )" sits on the simple-schedule rows. The "Detail Schedule" flowchart covers PRJ and OSF only; the "Simple Schedule" flowchart has lanes for WLI, Field PHSS, Field PEP RAM, Field PEP PE and PO Zona.
- **How each path creates the project today vs new:**
  - Detail: today's flow. `POST /projects` (draft) → `POST /projects/tasks/validate-upload` (`.mpp` only, `MppConstant.cs:12`, parsed by Aspose) → `/projects/tasks/validate/confirm` → `POST /projects/submit` → `POST /projects/approval`.
  - Simple: new. The grid rows (`num, level, desc, start, end, pred, cost`, row 0 = project, On Stream last; `uni:L2665`) must become `project_tasks` without Aspose, with weights from cost and On Stream lined up with the PHI-2267 on-stream dates. The Knowledge Documents have no such backend requirement.

### C7. Finish can bypass the required result and document (design bug the Knowledge Documents would inherit)
- **Knowledge Documents say:** Finish is blocked until result params or a study document exist (FR-8, BR-12, AC-9).
- **Design says:**
  - The check runs only from Project Details (`pdFinish`, `uni:L2721`).
  - The `px` rule is not `pdOnly` (`uni:L2022`), so **Project Finished also shows in the WO detail header**. There it opens a plain confirm dialog and calls `complete()` with no params or document.
- **Fix:** add "Finish is available only from Project Details" or "the same validation applies on every entry point". Add a negative test (N7).

### C8. Bulk approve can approve a rejection
- **Knowledge Documents say:** bulk approve is "only for WOs where they hold a plain Approve" (§5.1). FR-2 also says "Approve Selected / **Approve All**".
- **Design says:**
  - Eligibility is any rule with `kind === 'approve' && ui === 'approve'` (`uni:L2224`).
  - For the Manager Requestor that includes **ma1a/ma2a (Approve Action Plan), rf1a/rf2a (Approve Rejection) and sa (Study Approve)**.
  - The seeded bulk scenario includes an ma1a WO (`uni:L2085-2091`).
  - Approve All is computed (`askBulkAll`) but never rendered.
- **Fix:** limit bulk to `l1` and `l2` only, and drop Approve All, or add it to the design. Define what happens on a partial failure (see G3). The AP backend has no bulk endpoint today.

---

## Major

### Design traceability mismatches (Knowledge Documents vs prototype)
| # | Knowledge Documents say | Design says | Evidence |
|---|---|---|---|
| M1 | FR-2/AC-2: an L1/L2 Reject "can mark Fields to revise" | L1/L2 Reject has no fields input; only Reject Action Plan has `rj.fields` | `uni:L1948,1953,2548` |
| M2 | FR-1 form has Review By | No Review By input in Create/Edit; it is still in FIELDS and compared | `uni:L715-760`, `L1755` |
| M3 | Location is "a plant for In-Plant" | Always free text; In-Plant only pre-fills "Mutiara Central Plant" | `uni:L731,2277` |
| M4 | BR-3: End ≥ Start on the WO form and the project | Not enforced on either: the WO Submit button is never disabled, and the project checks only completion %. Enforced only in the action plan, the pp finish and the schedule. | `uni:L774,2662` vs `L2317,2301,1680` |
| M5 | FR-7: project Modify = "edit then approve" | Modify = Save Changes; the status stays pa1/pa2 and Approve is a separate click | `uni:L1934-1938,2661` |
| M6 | BR-10: Sub Department required for field departments | Dead path: `isField` tests `'Field'`, but DEPTS are all "… Zona 9" | `uni:L2559`, `L1508` |
| M7 | FR-4: the Manager "reviews the modified action plan" | Modify edits **WO fields only**; the action-plan step is skipped in modify mode | `uni:L2311` `acpNeeded = … && s.formMode !== 'modify'` |
| M8 | BR-16: loop count "shown in the approval history" | Shown as a hint banner when `loops >= 2`; it counts rejection-not-approved, **any** action-plan reject and a study reject, but **not** an L1/L2 reject | `uni:L2472,1822,1862,1897` |
| M9 | §6: Re-Submit notifies Senior Level | Also notifies the Manager Requestor: "Work Order Revised by Requestor" | `uni:L2360-2361` |
| M10 | §6: a Manager modify notifies "next approver + Requestor (+Senior Level)" | The next approver gets only "Incoming Work Order Request"; "Modified by Manager" goes to Requestor and Senior Level | `uni:L1913-1919` |
| M11 | AC-5: "all 20 fields" | Function is hidden when empty (19 rows); the Compare board shows 18 rows and the non-master value "ABI BU" | `uni:L2380`; Compare `ROWS` |
| M12 | §5.3: compares the 20 fields of FR-1 | Approval Flow, Gain type, LPO type and attachments are in FR-1 but not compared | `uni:L1755` |

### Integration with the current system
- **I1. Roles are not mapped to RBAC.**
  - The Knowledge Documents names 8 roles. None exists today as a role.
  - Today: Retina SYSROLE ACL 153–156 (area view/write; SDA1 writes PEP, SDA2 writes PHSS), 161 review, 162/163 level decisions. Perm 160 is unused. The PO pool is a department match on Production Operations.
  - "Senior Level" and "Senior Officer" exist only as R3 POSNAME text.
  - Evidence: `ActionPlanVisibility.cs:22-41`, `ActionPlanApprovalNotifier.cs:116-121`, `Auth/R3PositionHelper.cs:16`.
  - **Fix:** add a table with these columns: role · SYSROLE/department · permission ID · how resolved (POSNAME, route level, explicit pick). Rename "Lvl 1 / Lvl 2" to "Target / Receiving dept", because "level" already means approval-route level in the code.
- **I2. The target is not always PO.**
  - Request To has 11 departments, but the reviewer pool, the inbox and visibility are PO-only today.
  - Knowledge Documents-Gaps Q6 found no field-department users on dev.
  - **Fix:** say how the Senior Officer and Manager are resolved for each Request To.
- **I3. Action-plan field lists differ from what is built.**
  - Well Test Type: the Knowledge Documents have New Well / Routine / Re-test, but the PHI-2354 decision gave `production_test` / `optimization_test` (`seed_action_plan_custom_configs.sql:27-38`).
  - AL Installation: the Knowledge Documents require Pressure, but WHC dropped Pressure and requires `whc_type`, `compression_type`, `owned_by` and contract/asset number, with production ≤ compression (`ActionPlanShared/ActionPlanWhc.cs`; Knowledge Documents-Gaps G1–G3).
  - "AL Update" vs "AL Installation" is not mapped to `activity_type` / `action_mode`.
  - Choke: the compressor field and the BR-5 capacity warning are new. PEP `production_destination` is missing from the Knowledge Documents.
  - Sonolog exists for **PEP only**, but the Knowledge Documents list it under PHSS Field.
- **I4. Project creation and approval differ from the existing Projects module.**
  - Project approval today uses multi-level route approvers with **approve / revise** only, and revise returns to draft (`ProjectsService.cs:1828-1840,3018-3035`).
  - Sub-Category values are DLC/GL/FL/RTWS, not DLC/Non-DLC.
  - There is no LPO and no Project Type (ABI/ABO).
  - WBS is **one** value of up to 16 characters, unique among live projects (`:1903-1904,2014-2022`), while a WO allows several.
  - **Fix:** say whether to reuse or extend the module, and how several WO WBS values become one project WBS.
- **I5. Notifications.**
  - The Knowledge Documents say in-app only.
  - AP is in-app, but uses different titles (12 `phantom_iac_*` templates) and the CTA links to the well page (`ActionPlanApprovalNotifier.cs:24-35,107`).
  - Project approval **also sends email** (`Notifications/ApprovalNotifier.cs:204-245`).
  - **Fix:** add a template mapping. Say whether email is suppressed for projects born from a WO.
- **I6. PIC overlap.**
  - The Knowledge Documents have a Transfer PIC and a Disposition PIC.
  - AP already has `assigned_department` (set by SSDP) and `execution_department_id` + `execution_pic_id` (set by PO). The PIC must be an active user of that department. It is required for WT and optional for AL (`ActionPlanApprovalService.cs:566-596`).
  - The design's PIC is free text (`uni` transfer/dispo dialogs).
  - **Fix:** say whether Disposition PIC = execution PIC.
- **I7. Status naming.** Add a mapping column to the §3 table: Knowledge Documents code → stored value (AP `approval_status`, Project `ProjectConstant`).

### Study path (FR-10) is unreachable in the design
- The entry action `wu` ("Update Work Order") is `hidden: true` and then `delete RULES.wu` (`uni:L2023,2094`). `createDispo` always goes to `pj` (`uni:L1883`).
- With it enabled, **ABO Routine** goes PIC → Submit Study Result (document + Finished/On going flag) → `sr`, and sends a "Study Finished" notification. That notification is missing from §6.
- Other types get "Update Work Order Parameter", where Job Finished = Yes completes the WO without a project.
- Creating a follow-up WO sets the original to `done` (`uni:L2344-2348`), which the Knowledge Documents do not say.
- **Fix:** specify the `wu` step. Say whether ABO Routine skips Project Preparation and Project Approval.

---

## Minor
| # | Finding | Evidence | Fix |
|---|---|---|---|
| m1 | Budget Type form value typo "AB NBD"; the Budget Type and Disposition Work Type lists are separate fields, not two copies of one list | `uni:L2322` vs `L1705` | Reword OQ4 (see below) |
| m2 | "Waiting for approval by \<name\>" appears only in Project Details; the WO detail says "Waiting for \<role\> to take the next action" | `uni:L2470,2728` | Pick one |
| m3 | Waiting For My Action is a table plus a Review side panel with Approve/Reject, not cards | `uni:L575-650` | Correct §5.1 |
| m4 | Tile "In Review" = `tasks.length`, the same as "Waiting for me" | `uni:L2209-2214` | Define In Review |
| m5 | Working Area is hard-coded to "PHSS" in Location & Asset; Target Well sits in the Action Plan card | `uni:L2405` | Derive it from Field |
| m6 | Project Details has 8 tabs (adds Attachment) | `uni:L2808` | Correct §5.5 |
| m7 | Tile names: "Project Routing Delayed / Total Project Near Due / Total Project On Track" | `uni:L2746-2748` | Match the copy |
| m8 | Upload: the Knowledge Documents say 5 × 10 MB including JPG/PNG; the shared constant today is 25 MB, no images, no count limit | `FileUploadAttachmentConstant.cs:10-11` | Use WO-specific constants, or change the shared one |
| m9 | The "Chocke" spelling differs from the existing `choke` key and labels | | Use "Choke" |
| m10 | Missing fields: Requestor Dept (`REQ_DEPTS`), Gain type, LPO type Yes/No, RK years 2026–2030, the 13 required project fields for the % | `uni:L1702,2322,1616,2632` | Add them to FR-1 and FR-7 |
| m11 | Missing UI: "Rejection needs your review" banner with inline buttons; inline Approve in Current Cycle Progress; list CSV export (12 columns) | `uni:L2459-2465,2505-2510,2257-2261` | Add them to §5 |
| m12 | Closed: the SSDP ⇄ PO board (`wver`) has the same logic as uni; see "SSDP ⇄ PO board" below | | |

---

## Grill: ambiguities and missing edge cases
- **G1. Concurrency.** Two Managers Requestor, or two Senior Officers in a pool, act on the same WO at the same time. AP already uses a conditional-UPDATE claim (`ClaimForReviewAsync`). The Knowledge Documents must require optimistic locking on every transition; the loser gets 409 "already processed by \<name\>".
- **G2. Re-submit after rejT.** The design resets everything: `status = l1`, `transfer = null`, `l1/l2 = null` (`uni:L2358`). So a Lvl 2 rejection sends the WO back through Senior Level, Manager and **Lvl 1** again. The Knowledge Documents must say whether that is intended, whether the old transfer is kept in history, and whether the modification history survives.
- **G3. Bulk approve partial failure.** It is not defined whether bulk is atomic or per item. Recommend per item: return a result per WO and keep the failed ones selected. Also define the maximum batch size, and whether a modified or blocked WO is excluded.
- **G4. SLA.** The Knowledge Documents leaves it as an open question, but AP already has per-level SLA (`approval_route_level_slas`, PO review = 3 working days, `seed_action_plan_approval.sql:27-32`). Reuse it, and define on_track / near_due / delayed thresholds and working days (holiday calendar `calendars.holiday`).
- **G5. Permissions edge cases.**
  - A user holding two roles, for example Senior Level and Manager, or a requester who is also the target. Can they approve their own WO?
  - A deactivated approver or PIC while a WO is pending: who takes over?
  - Delegation or out-of-office.
  - Super Admin override.
- **G6. Draft lifecycle.** Who can delete a draft, whether drafts expire, and whether the WO number is reserved for a draft (see C5).
- **G7. Edits while pending.** Can the Requestor withdraw or cancel after submit? No Cancel exists in the design or the Knowledge Documents. What happens to a WO whose project is canceled in Project Monitoring?
- **G8. Data retention and audit.** Retention for attachments, modification snapshots and the activity log. Whether history is append-only and immutable, and whether exported CSV includes hidden Lvl 2 changes for Lvl 1 users. BR-15 needs "duration since previous step" defined in working or calendar time.
- **G9. Visibility leak.** AC-6 hides Lvl 2 changes from Lvl 1, but the CSV export, the History tab, the notification text and the list "Remarks" column could still show them. AC-6 must cover every channel.
- **G10. Untestable wording.**
  - "the system validates them" (FR-9)
  - "parties are notified" (FR-2)
  - "modified fields are flagged" (§5.2)
  - "simple schedule"

  Each needs an observable result: a message, a recipient list, or a style token.
- **G11. Master data drift.** Request To lists "Projects Z9" but Transfer DEPTS say "Projects Zona 9". Use one department master: `organizations` / `departments`.
- **G12. Reject reason.** Max 500 characters, but is a whitespace-only reason valid? The design trims, so the Knowledge Documents should say "non-blank". Is the reason editable later?

---

## Open questions (§8) checked against the design
| # | Knowledge Documents question | Answer from design / system | Sharpened question |
|---|---|---|---|
| 1 | Which disposition type triggers the study path? | **Settled: ABO Routine** (`uni:L2024,2575`, `DTYPES[2]`). The entry action `wu` is disabled. | "Does ABO Routine skip Project Preparation and Approval and go PIC → Submit Study Result → Study Review? Does 'Plant Performance Study' (finish document) relate to it?" |
| 2 | Is Approved terminal, or can it time out or escalate ("Raise unsolved issue to Manager")? | **Settled: terminal**, no timer. The phrase is a reject-loop display flag at `loops >= 3`, in a card the design removes (`uni:L2419-2421,2449`); the live hint is at `loops >= 2`. | "Is reject-loop escalation a real action? Threshold 2 or 3? Recipient? Does it block further rejects?" |
| 3 | Re-Submit after rejT: Senior Level or straight to the target? | **Settled: full restart at Senior Level, transfer cleared** (`uni:L2358`). Note: today AP rejected is terminal (C3). | "Confirm the full restart, including dropping the Lvl 2 transfer. Or is rejected terminal, as in the AP flow?" |
| 4 | Which Budget Type list is master? | **Premise is wrong:** these are two fields, WO Budget Type (`L2322`, typo "AB NBD") and Disposition Work Type (`L1705`, which drives Project Type and the study trigger). | "Give one code list with short and long labels. Should Work Type default from Budget Type? Is Budget Type stored on the project?" |
| 5 | Configurable approval flow later? | Not settled. A single hard-coded option each (`uni:L2322,2625`); the selection has no effect. The current system already has an `approval_routes` master with route prefill. | "Should the WO reuse `approval_routes` (category per Request To) now, so a flow is selectable without code?" |
| 6 | SLA rule for the routing chips? | Not in the design (static seed `APPR_T`, `uni:L2096-2101`). **It exists in the current system** (G4). | "Adopt the existing per-level SLA and calendar? Give the near-due threshold." |
| new | | | Which entity owns the flow (C1)? Which categories need approval (C4)? WO number format and timing (C5)? The role → permission map (I1)? |

---

## Extra acceptance criteria
- **AC-13** Given a WO in any status, when two eligible users act at the same time, then exactly one transition is applied and the other user gets "already processed".
- **AC-14** Given a Choke Adjustment WO, when it is submitted, then it follows the per-category approval rule from C4, and the WO number is assigned per C5 at the defined moment.
- **AC-15** Given the Manager Requestor with 3 WOs selected (one l2, one ma1a, one rf1a), when Approve Selected is clicked, then only the l2 WO is eligible, or the Knowledge Documents states the opposite explicitly.
- **AC-16** Given bulk approve of N WOs where one fails validation or was taken by someone else, then N−1 move forward, the failed one stays selected with its reason, and notifications go only for the successes.
- **AC-17** Given a Lvl 1 user, then Lvl 2 field changes are absent from View Changes, the History tab, notifications, the list Remarks column and the CSV export.
- **AC-18** (D7) Given a well-category project in On Going, when the PIC finishes without result params or a document, then the WO becomes Completed and the result section shows "Not provided".
- **AC-19** Given Request To = PO Z9 with Category = Well Test, then the simple-schedule step is shown; given Projects Z9, it is not (per C6).
- **AC-20** Given a WO rejected at Lvl 2 (rejT), when the Requestor re-submits, then the status is Waiting Approval (L1), the transfer is cleared, and the earlier cycles are still in Approval History.
- **AC-21** Every role in §2 maps to a permission ID. A user without it gets 403 on the API, not only a hidden button.

## Negative test cases (Given / When / Then)
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

## SSDP ⇄ PO board (`WO-Prototype-ycvm-wver.dc.html`)
**Result:** despite its title, `wver` is **not** an SSDP → PO flow. It is an older layout of the same prototype.
- Its business logic is identical to uni: the content after `ST`, `RULES`, `PERSONAS`, `FIELDS`, `CAT_DEPT`, `CAT_FUNC`, `LOC`, `REQ_TO` and `ACP_OPT` hashes the same in both files.
- A line diff finds 11 hunks, all in the WO detail Overview layout. There are no changes to statuses, buttons, owners, notifications or fields.
- The title "(SSDP ⇄ PO) copy" is inherited from the archived board `WO-Prototype-ycvm-3g8c` (page "Archive"), which was not reviewed.
- **The Knowledge Documents should not adopt wver as the well-category flow.** It conflicts with D2, D3 and D4 exactly as uni does. Write the well-category flow from D1–D8 plus today's AP engine.

**Layout differences** (wver vs uni):
| Area | uni (Knowledge Documents source) | wver |
|---|---|---|
| Overview | One collapsible "Work order overview" card (Info, Scope, Location, Schedule, Classification, Impact) | Separate flat cards; Cycle and History sit above Location and Schedule |
| Collapsing | 4 accordions: Overview, Cycle, History, PIC (`uni:L2595-2597`) | None |
| Work Order PIC | Avatars with name + role, all people | Name-only chips, first 5 + "See more" (`wver:L1033-1041,2582`) |

**How the personas map to today's AP flow:**
- `req` = SSDP (SDA1/SDA2).
- `sen` / `mgr` = an SSDP-side approval that does not exist today.
- `tsr` = the PO pool reviewer (161) when Request To = PO Z9.
- `mg1` = the route managers (162/163).
- `rsr` / `mg2` (Transfer) has no AP equivalent.
- `pic` = the execution PIC.

**New findings**
- **Major M-A. Target department for well categories is ambiguous.** Well Test, Choke and AL Update can target PO Z9, PHSS Field or a PEP field via Function PE/Production (`wver:L1513-1520`). Today every SSDP plan goes to the one PO pool. *Fix:* for the D4 approval categories, fix the target as PO, or map each target to an approval route (D2).
- **Major M-B. SDA is a Request To target.** "SDA 1 Z9 / SDA 2 Z9: no category, submitted directly" (`wver:L1499`). Today SDA only *originates* plans. *Fix:* define what a WO sent to SDA means, or remove it. State that SSDP is a requestor department.
- **Minor m-A. Action-plan wording vs D1.** Buttons say "Approve / Reject / Revise Action Plan" and "The action plan will be rejected" (`wver:L1953,1973-2001`; same in uni). *Fix:* reword them as WO modification approval/rejection.
- **Minor m-B. "Products Operation"** in `REQ_DEPTS` (`wver:L1690`). *Fix:* use the department master name, Production Operations.
- **Minor m-C. Layout choice.** The Knowledge Documents follows uni; state the accordion behaviour and the PIC cap.

**Questions**
1. Is `wver` safe to ignore? If an SSDP ⇄ PO variant was intended, export the archived `WO-Prototype-ycvm-3g8c` for review.
2. For Well Test and AL WHC Installation, is Request To always PO, or can SSDP send them to PHSS Field or a PEP field?
3. Does an SSDP-originated WO pass the requestor-side Senior / Manager (l1, l2) stage, or go straight to PO review as today?
4. Does the Modify round end with SSDP / the creator (today) or with the Manager Requestor (board)?
5. Does Transfer to a receiving department apply to well categories?
6. Which detail layout is final: uni or wver?

---

## Figma flow + newer prototype (added 19 Nov 2026)
**Sources**
- Figma file "PHI - Latest Design", page **Work Order**, read via Chrome (view-only). Sections read:
  - "Flow Work Order (V2) 3/11/2026"
  - "Detail Schedule 5/11/2026"
  - "Simple Schedule 5/11/2026"
- The "Lancar lvl 0/1/2" screen rows (happy path, no Modify, project-based vs simple schedule) were seen only at overview zoom, not checked screen by screen.
- The Figma links to the prototype `claude.ai/artifact/S4gBiqBpHasmfJnZKQQZMu` (version 1795050409-bd7a), **not** the one reviewed above (`caf7d8a9…`, 1795000848-2b2b). Diff results are under F12.

**Findings**
- **F1 (closes C6).** PRJ and OSF use the project-based schedule; all other departments use the simple schedule. See C6.
- **F2 (Minor). Categories differ between the Figma, the prototype and the Knowledge Documents.**
  - The Figma's PRJ list includes **Compressor Relocation** (ABI BD → Fasprod → Fasprod). It is not in `CAT_DEPT` or the Knowledge Documents.
  - **AL Installation** is on the PO Zona simple-schedule lane (ABO → Artificial Lift Install). The prototype instead lists it as a Projects Z9 extra (`CAT_EXTRA`, no schedule step).
  - The Figma also gives each category a project class, for example ABI BD → NWD → RTWS, ABI NBD/ABO → Fasprod → HE or AFA, ABO → Well Test. The Knowledge Documents's project-type rule doesn't mention this.
- **F3 (Major, conflicts with D7). Finish expects parameters and a requestor follow-up.** Every lane runs:
  1. "Click Finished Project. Then, pop up Parameter update for finishing the information"
  2. "Workorder Update Parameter data send to requestor to be check"
  3. For well lanes: "Requestor Updating Parameter Sumur (Choke / Sonolog / Artificial Parameter / MTU / EUR Zona) @ Well Surveillance / EUR Page", where the Requestor is linked straight to that well's page.
  4. END, "Work Order updated & cycle closed"

  The requestor follow-up is not in the Knowledge Documents. With D7 (skip allowed), say what the Requestor checks when nothing was entered.
- **F4 (Major, affects D3 / Q6b). A requestor-side reject can be re-submitted.** Both Requestor Approval lanes say, on reject: "Notification WO · masuk ke tabel outgoing dengan status 'Reject' · masih terdapat opsi Re-submit tapi perlu masuk page untuk modifikasi workorder sebelum submit". So the Figma treats a requestor-side reject as re-submittable after editing, not terminal.
- **F5 (Major, missing from Knowledge Documents). Requestor Level 1 can be skipped.** The Level 1 lane starts with "Apakah Requestor level Ast Man?". If yes, the WO goes straight to Level 2 (Manager). The Knowledge Documents always starts at Senior Level. Under D2, this is a route rule: skip a level when the requestor already holds that level.
- **F6 (affects Q4). Modify lane ends at the Manager Requestor.** It runs: Modify Action Plan → Send to Approver Manager → Decision:
  - **Approve:** "Send Verification to Manager Requestor Lvl 0", then "Modification OK?" Yes → Transfer/Disposition. No → back to the Target Lvl 1 start.
  - **Reject:** back to the "Modify?" decision.

  Notes on the lane say: "count the error rate of modifications", "count when each level keeps rejecting or loops endlessly", "raise unsolved issues to the Manager". That is a reporting requirement (BR-16 / Q6c), and an escalation the Knowledge Documents doesn't define.
- **F7 (Minor). The rejection lane shows one approver layer.** "Reject → Send to Approver Layer Level 1 → Approve Reject?":
  - **Yes:** "Action Plan Rejected", and the Requestor is notified.
  - **No:** back to the "Modify?" decision, so Reject is effectively hidden.

  The prototype has two approvers here (Manager Lvl n, then Manager Requestor). Under D2 this is just route depth, but the two designs disagree.
- **F8. Transfer and Disposition match FR-6.**
  - **Transfer:** to Projects, OSF, Well Intervention, Drilling, Field PHSS or Field PEP. A field transfer then picks a sub-department (PE / PO / RAM / WO/WS), then the PIC, with optional notes. "Workorder Number selalu terbawa" (the number always carries over).
  - **Disposition:** Assign PIC Member Internal; "WO Number masih menempel dari Requestor".
  - **Create Project:** the appointee opens the WO from the Work Order page or Task List, then clicks Create Project, which leads to the Detail or Simple flow.
- **F9 (Minor, affects D1). Well-action lanes say "New Action Process – Simple Schedule".** In the PE and PO lanes, Well Action, Well Test and AL Update create an *action*, while the other lanes say "New Project Creation Process". Confirm that under D1 a well WO's child is an Action Plan with a simple schedule, not a Project.
- **F10 (Minor). Scope note.** On the Simple Schedule board: "Untuk Case ini, asumsi new well dan existing well tidak di masukan" (for this case, new wells and existing wells are not included). Note that workover in the annual scope is seen as New Well Dev or Existing Well.
- **F11 (Minor). Each lane has an entry note.** "Review" opens a preview with approve/reject on the dashboard; a notification click opens the detail page or the work-order type page (Well Surveillance, EUR…).
- **F12. The newer prototype (S4gBiq…) differs from the one reviewed above.** Its business constants are unchanged: `DETAIL_DEPT`, `schedKind`, `CAT_*`, `DTYPES`, `NO_CAT` and `projLvl`. The changes are:
  - **Needs Revision (mr1/mr2):** the Senior Officer now gets **Reject / Modify / Approve**; before, it was only "Revise Action Plan". This moves toward D3, but the status still exists.
  - **Modify lane buttons:** at Manager Lvl 1/2 they are now "Reject / Approve" with "Reject this modification? / Approve this modification?". The Manager Requestor still sees "Reject / Approve Action Plan" (m-A partly fixed; Q4c).
  - **Modify form and View Changes:** the form now includes the Action Plan fields, and the change list covers them (`acpDiff`). The compare view is grouped into sections (Info, Scope, Location, Schedule, Classification, Impact, Action Plan / Project Parameters).
  - **Required fields:** AL Installation/Update no longer require **Prime Mover**, but Knowledge Documents lines 210 and 214 still list it.
  - **Seed data:** the AL Installation seed WO now has a filled Action Plan.
