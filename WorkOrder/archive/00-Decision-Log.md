# Work Order: decision log and knowledge

This file records:
- each decision (with date and source),
- each change to the WO docs,
- each fact we found in the code or the database.

**All links:** see `01-Links.md`.

Write a new entry at the bottom of each section. Do not change old entries. If a decision changes, write a new entry that names the old one.

**Words used in this file:**
- **WO:** Work Order.
- **AP:** Action Plan (a well action from Well Surveillance).
- **Level:** a department in the WO flow.
  - Level 0 = the requestor department.
  - Level 1 = the target department (Request To).
  - Level 2 = the department that receives a transferred WO.
- **Layer:** a position in one Level.
  - Layer 0 = PIC or requestor.
  - Layer 1 = Senior or Asst. Manager.
  - Layer 2 = Manager.
- **Route:** the approval chain in Data Config (`approval_routes`).

---

## 1. Decisions
| ID | Date | Decision | Source | Replaces |
|---|---|---|---|---|
| D1 | 18 Nov | The WO is the parent. The AP is the child. The route is on the WO. | User | – |
| D2 | 18 Nov | Routes set the approval layers for submit, Modify and Reject. | User | – |
| D3 | 18 Nov | A return goes back to the reviewer. A rejected WO is final. | User | – |
| D4 | 18 Nov | Only Well Test and AL WHC Installation need target approval. | User | – |
| D5 | 18 Nov | WO number = `<seq>/WO/PROJECT/<year>`. | User | – |
| D7 | 18 Nov | Finish can skip the result parameters. | User | – |
| D8 | 18 Nov | Bulk approve works as the Knowledge Documents say. | User | – |
| C6 | 19 Nov | PRJ and OSF use the detail schedule. All other departments use the simple schedule. | Figma | – |
| D3b | 19 Nov | A declined rejection goes back to Layer 1 Level 1. That reviewer can only Approve or Modify. The Reject button is hidden. | User = MoM | D3 (part) |
| D5b | 19 Nov | `custom_configurations` sets the WO number format. | User | D5 |
| D7b | 19 Nov | The Finish parameters are required. | User = MoM + Figma | D7 |
| X2 | 19 Nov | A Level 0 approver edits the WO and approves it in one step. The requestor gets a notification only. This step does not stop the flow. | User = MoM + Figma | – |
| X4 | 19 Nov | Layer 2 Level 0 (Manager Requestor) checks a Level 1 modification. A permission number finds this manager. The same step applies after a Transfer. | User = Figma | – |
| X5 | 19 Nov | If Level 0 declines a modification, the system drops the proposal. The WO goes to Approved with the old parameters. | User | – |
| X3 | 19 Nov | A reject at Level 0 is final. The requestor makes a new WO with a new number. | MoM | – |
| X12 | 19 Nov | The AP uses the route of the WO (MoM option 1). | D1 | – |
| R1 | 20 Nov | A category with no approval skips all approval steps (Level 0 and Level 1). The WO goes to Disposition or Transfer. | User | – |
| P0 | 20 Nov | A WO project does not use `.mpp`. The PIC makes the detail and the simple schedule in the app (grid or Excel). | User | – |
| P1 | 20 Nov | A well-category WO also makes a simple Project, because SPK and contract need a project. An AP WO skips the project approval. | User | – |
| F1 | 20 Nov | A new flag marks each project: from a WO or from outside a WO. | User | – |

| F12x | 20 Nov | F12 was a wrong finding. The first draft of the Knowledge Documents only **lists** Prime Mover as a field of AL Installation / Update. It does not mark it as required. The prototype shows it as optional. MoM M002 says Prime Mover is optional (SRP free text; only stroke length and SPM are required). The code has no rule that requires it. Q46 is removed. | Recheck of Knowledge Documents, prototype, MoM M002, code | F12 |
| F12y | 23 Nov | F12x was not complete. The Figma AL Update form (Gas Lift) marks Prime Mover and Power as required. The question is open again as Q46. | Figma check 23 Nov | F12x |
| TD1 | 24 Nov | The requestor selects the approval flow in Create WO, for the requestor department only (Senior, then Manager). The step "Senior of the target department" is removed from that flow. | Team doc "Phantom Fase 2" | Automatic route search (07) |
| TD2 | 24 Nov | The target department selects its own flow in a "Set Approval Flow" window (WO status Waiting Approval). It is used for Modify and Reject approval. Who: users of the Request To department with the "set approval level 1" permission. | Team doc | – |
| TD3 | 24 Nov | Approval Route category = "Work Order - {Department}", with Level 0/1/2 and Layer 1/2 for each. The system lets the admin select any position and any department. Senior = Layer 1 and Manager = Layer 2 is an SOP only. | Team doc + comments 20 Nov | Layer permission plan (09) |
| TD4 | 24 Nov | Schedule type for each department: simple = WLI, Field PHSS, Field PEP RAM, Field PEP PE, PO Zona, Drilling; detailed = Project, OSF. Fixed in code first, configurable later. | Team doc | Confirms C6 |
| TD5 | 24 Nov | Disposition Work Type: ABI/BD only Projects and PO; ABI/NBD only OSF; ABO Routine / Non Routine for all. | Team doc | – |
| TD6 | 24 Nov | "Set Approval Flow" is available from both tabs (Incoming and Outgoing). After it, the page shows only Modify and Reject (no Approve). | User | – |
| TD7 | 24 Nov | Level 2 = "Target Department", as in Data Config. | User | MoM meaning of Level 2 (transfer department) |
| TD8 | 24 Nov | No skip when the requestor is a Senior. Another Senior reviews. Approvers are found by permission ID: every user with the permission can review. | User | Proposal "no skip, admin makes a route without Layer 1" |
| TD9 | 24 Nov | "Inception" = Inspection (OSF). "Gas List" = Gas Lift (Project). Typos in the team doc. | User | – |
| TD10 | 24 Nov | Level 0 = requestor department, Level 1 = target department (Request To), Level 2 = assigned department (only if needed, after a Transfer). | User | TD7 |
| TD11 | 24 Nov | The route layer holds a permission ID. Every user with that permission can review. | User | Names in the route (TD3, part) |
| TD12 | 24 Nov | Transfer: needs a permission (as approval). Departments come from a list for each department. The user also selects a sub-unit. Notes are optional. The assigned department uses "Set Approval Flow". No second transfer. | User | – |
| TD13 | 24 Nov | Backend: the permission ID is used **only** to list users (`GET /users/by-permission/{id}`), for example to show who can review. The backend does **not** check the permission ID to allow or block an action. | User | Permission check on actions (09 §3) |
| TD14 | 24 Nov | Delete the second "Approve & Create Disposition" section in the team doc (it is a copy). | User | – |
| TD15 | 24 Nov | After a Transfer, the WO status is "Waiting Approval" (the status that shows "Set Approval Flow"). | User | – |
| TD16 | 24 Nov | A permission counts only in the department of its Level. Example: a PO Senior with the permission does not review an OSF WO. The user list (`/users/by-permission`) must be filtered by that department. | User | – |

---

## 2. Changes to the WO docs
| Date | File | Change |
|---|---|---|
| 19 Nov | `04-KnowledgeDocuments-WorkOrder.md` | Knowledge Documents draft in the team format. It does not yet show the decisions from 19–20 Nov. |
| 19 Nov | `05-MoM-vs-KnowledgeDocuments.md` | Comparison of the MoM and the Knowledge Documents: M1–M15, G1–G11, X1–X14. |
| 19 Nov | `06-WO-Category-Breakdown.md` | Category tables per Request To. Open points K1–K12. |
| 20 Nov | `06-WO-Category-Breakdown.md` | Tables changed to lists. Added "Approval flow by category". Added K13–K15. |
| 20 Nov | `07-WO-Approval-Route-Enhancement.md` | New. A configurable route: stages, bindings, layer rules. Uses Level / Layer names. R1–R9. |
| 20 Nov | `08-WO-Project-Task-Changes.md` | New. Changes on `projects` and `project_tasks`. Project lifecycle. NOT NULL check. P1–P15. |
| 20 Nov | `03-Major-Questions.md` | Rewritten. It now has questions only, in short, simple English. Answered questions moved to this log. |
| 20 Nov | `03-Major-Questions.md` | Removed section I "For the Ocean team". Its two questions are now business questions in section E (new Q41 draft schedule, Q42 schedule change after approval). Questions renumbered in order: Q43–Q46 are now F, G and H. |
| 20 Nov | `03-Major-Questions.md` | Added section "Reference": source documents, MoM meetings, MoM topic codes (M002, M009, M014), ID prefixes, decision codes. |
| 20 Nov | `00-Decision-Log.md` | New (this file). |
| 20 Nov | Google Doc "PRD — Work Order (PHANTOM)" (title to rename: Knowledge Documents — Work Order) | Category breakdown added before FLOW 1 (table version). |
| 20 Nov | Google Doc "Work Order" (questions) | Replaced with the 20 Nov version of `03`. The rewrite of `03` is **not** synced yet. |
| 20 Nov | Google Doc "Work Order Question" (questions) | Added a new tab "Open Questions (20 Nov)" with the rewritten `03` (Q01–Q46 + Reference). Tab 1 is not changed. |
| 20 Nov | `03-Major-Questions.md` | Removed section H and Q46 [F12] (wrong finding, see F12x). Removed F12 from Reference. |
| 20 Nov | `04-KnowledgeDocuments-WorkOrder.md` | AL table: "Prime Mover not required (F12)" changed to cite MoM M002. |
| 20 Nov | All WO docs | The word "PRD" removed. Our collected WO knowledge is now called **Knowledge Documents**. Files renamed: `02-KnowledgeDocuments-Review.md`, `04-KnowledgeDocuments-WorkOrder.md`, `05-MoM-vs-KnowledgeDocuments.md`. The first draft (artifact "Work Order Module (PHANTOM)") = "first draft of the Knowledge Documents". The team doc "Phantom Fase 2" is named without "PRD". Not changed: the Google Doc title "PRD — Work Order (PHANTOM)" (needs your OK). |
| 20 Nov | Google Doc "Work Order Question", tab "Open Questions (20 Nov)" | Content replaced with the current `03` (Q01–Q45, no "PRD", no Q46). Only this tab was changed. Note: at this time "Tab 1" was no longer in the doc; we did not delete it. |
| 23 Nov | `06-WO-Category-Breakdown.md`, `03-Major-Questions.md` | Added "Project class list (Figma)". Q14, Q35, Q37 updated with Figma facts. Q46 (Prime Mover) added again. |
| 24 Nov | `09-WO-Permission-Level-Plan.md` | New. Plan for Layer permissions (Q16 / R3): options A–C, proposed groups 31–32 and privileges 273–277, open points P1–P5. |
| 24 Nov | `10-PR-1523-Review.md` | New. Review of PR #1523 (WO schema) against the decisions: conflicts A1–A5 (one project per WO vs K15/F1, P1, D3b/R8, X5, approver copy per stage), checks B1–B7, code points C1–C5. Posted 24 Nov as a review comment (plain words, no codes) on PR #1523. |
| 24 Nov | `11-TeamDoc-Decisions-24Nov.md` | New. Decisions from the team doc (approval flow selection, Set Approval Flow window, route setup, schedule type per department, Request To / Category list, overview, disposition). 7 questions for the team. Part of PR #1523 problem 5 is now out of date. |
| 24 Nov | PR #1523 (GitHub comment) | Follow-up comment posted: https://github.com/oceaninov/phantom/pull/1523#issuecomment-7127114186. It corrects problem 5 (each department sets its own flow; approvers by permission ID, filtered by the department of the Level; backend lists users only, no permission check; unique index must include the step) and adds the Transfer rules, Level names, schedule type by department, Request To list, Disposition Work Type and spelling. |
| 24 Nov | `12-WO-Status-Flow.md` | New. Mermaid charts: WO status flow (all Levels, modify / reject loops, transfer, disposition, project), approval route flow (who selects the flow and when the approvers are listed), and the status of one approval step. |
| 24 Nov | `01-Links.md` | New. All links: Google Docs, the RBAC sheet, Figma frames, Claude artifacts, PR #1523 (review + follow-up), PR #1476, code paths and database tables. |
| 24 Nov | All WO docs (review) | Reviewed all docs and updated them to the decisions of 19–24 Nov. `03`: answered questions removed (with an "Answered" list in each section), the word list updated. `04`: now v0.2, all flows, data and status updated (Set Approval Flow story, permission approvers, Transfer rules, schedule type by department, Request To lists). `06`: Request To table, spelling, approval-flow section rewritten, K points closed. `07`: rewritten for manual flow selection and permission approvers; the old automatic route search is marked "Replaced 24 Nov". `08`: schedule type by department, project approvers by permission, Disposition Work Type. `09`: rewritten (list-only permissions, department scope, new Set Approval Flow and Transfer permissions). `02`, `05`: a "Status 24 Nov" note lists the old points that are replaced; the old text is not changed. |
| 24 Nov | `13-WO-Endpoint-Plan.md` | New. Endpoint plan: 26 new `/work-orders` endpoints (overview, list, form data, draft / submit, details, history, attachments, approve / modify / reject, decisions, Set Approval Flow, approvers, transfer, disposition, project prefill) and changes to existing endpoints (users by permission + department filter, approval routes with Level / Layer / permission ID, WO number format, Action Plan, projects, approval list, config keys, permissions). Build order in 6 phases. 5 open points. |
| 24 Nov | PR #1533 (GitHub review) | Review posted: https://github.com/oceaninov/phantom/pull/1533#pullrequestreview-6039043183. WO list endpoint `GET /work-order/{working_area}`. Must fix: Incoming shows WOs before Level 0 is done (also Level 0 rejects); no filter / sort (team doc: filter Description, Status, Recipient, Category, Field; sort the 4 dates). Check: title vs description, Request To names vs `users.department` (field targets match nobody), approver / PIC outside the department. Code: log the exception, cap `page_size`, date time zone, WOs with no field. |
| 24 Nov | PR #1533 (recheck of `d6149aca`) | Must-fix points fixed (Incoming after Level 0, filters, sort, title, approver / PIC rows, log, page_size cap). Open points found but **accepted for now by the user, no comment posted**: (1) `field_id` is `Guid?`, so an empty value gives a 500; (2) Incoming hides a WO when the requestor department is also my department (same-department request or transfer back). Moved to the create-WO PR: department names in `request_to`, time zone of the dates. |
| 24 Nov | `16-WO-FE-Test-Users.md` | New (plan only, nothing seeded). 13 test users `phi.wo.*` for the FE test (PO → OSF → Projects, plus SDA 1, a guest and a GM), SYSROLEs per department, and the seed list. 4 decisions needed (new SYSROLE `{Dept} - Approval - Leader` for the Manager, privilege numbers, field departments, prefix). |
| 24 Nov | `14-WO-Endpoint-Figma-Screens.md` + `img/endpoints/` | New. 8 Figma screenshots mapped to the endpoints of `13`. Found: no "Set Approval Flow" window in the Figma; the Figma Transfer window has a mandatory PIC and no sub-unit; the Figma History shows a resubmit after a Level 0 reject; the list's first column is the WO title; no "Add file" on the Attachment tab; no Function field on the Create form. |
| 24 Nov | `15-WO-Production-Checklist.md` | New. Checklist to go to production: branches / PRs (status), alter tables, seeds, permissions and Retina, data clean-up, release steps, 8 decisions needed. |
| 24 Nov | Bruno repo `phi-phantom-collections`, worktree `bruno/.worktrees/work-order`, branch `feat/work-order` (off `origin/main`) | New folder `collections/phi-phantom/Work Order`: `Get Work Order Overview` (phi-dev, PR #1530; 4 examples) and `Get Work Order List` (`feat/work-order-list`, PR #1533; 5 examples). The examples are the curl results in the PR texts, not a new run. Committed `5165ab4` and opened PR https://github.com/oceaninov/phi-phantom-collections/pull/235 (base `main`) on 24 Nov, on the user's request. |
| 24 Nov | Bruno PR #235 | Commit `572e575`: added all planned endpoints of `13` as Bruno requests: `Work Order/Planned - New Endpoints` (#3–#26, 23 requests) and `Work Order/Planned - Changed Endpoints` (7 requests). Each has a proposed body, example responses and docs marked **Planned**. PR title and description updated. |
| 24 Nov | `14` §2, `13` #5 | Create WO form: the Approval Flow field needs "get approval route". It reuses `GET /approval-routes?category=work_order&department_id=&search=` (search; the filters exist) and `GET /approval-routes/{id}` (progress after selection: steps, Layer, permission, SLA, approvers by permission + department). No new WO endpoint. |
| 24 Nov | `14-WO-Endpoint-Figma-Screens.md` | Added §9 Approve confirmation, §10 Modification Comparison (Approve / Reject of a change; Manager Requestor and Manager Target), §11 Project Approval (Project Monitoring), and a table of where each approve / reject happens. Not in the Figma: the two-step rejection decision (#20) and Set Approval Flow (#21). |
| 24 Nov | `14` §12 + `img/input-parameter/` | Figma "Input Parameter" (node 18806-110894): the Action Plan window inside Create WO (simple schedule). 5 forms captured: Well Test Update, AL Update, AL Installation, Sonolog, Choke Adjustment; WLI is empty ("On progress"). Prime Mover: required for AL Update (Gas Lift), optional for AL Installation (TT/ESP); Power required in both (supports the Q46 proposal). |

---

## 3. Knowledge from the code and the database
Checked 20 Nov in the `phi-dev` code and in the dev database (read-only).

**Approval route**
- `FindRouteAsync` gets one active route for one `category` text. The newest route wins (`ActionPlanApprovalService.cs:704`).
- `ActionPlanApprovalRules.RequiresApproval` has the rule "only Well Test and AL WHC Installation need approval" in the code.
- The PO review pool uses permission 161 (config `action_plan_review_permission_id`).
- The code adds the SSDP creator as the last Modify level.

**Project tasks**
- Each task needs a project: `project_tasks.project_id` is NOT NULL.
- A task links to a contract (`contract_id`), to SPKs (`project_task_spks`, more than one SPK per task) and to BOQ (`project_task_boqs`, `project_task_boq_drafts`).
- SPK, BOQ and weight use only `item` rows. They do not use `header` rows.
- `weight` = task cost ÷ total item cost. If the total cost is 0, the weights do not change.
- The `.mpp` import writes the predecessors as JSON: `[{id, uniqueID, type, lag}]`.
- The manual "add task" path writes `"[]"`.
- The system finds the On Stream task by its name, "On Stream" (`ProjectsService.cs:4430`).
- `BuildDailySchedules` puts a plan row on every calendar day, including Saturday and Sunday.

**Projects**
- Project status values: `draft` → `on hold` → `in progress` → `finished` / `canceled`.
- The user selects the project approvers manually (`project_approvers`).
- To submit a project, it needs: description, category, field, start and end dates, project number, **WBS**, RKAP, working area, and one task or more.
- `projects.category` on dev has only `fasprod`, `newwelldevelopment`, `flowline` and the duplicate "New Well Development".
- `projects.rkap_type` on dev has `CO`, `UB` and `CF`. These are not the WO budget types.

**NOT NULL (database)**
- `projects`: only `id` and `created_at`.
- `project_tasks`: `id`, `project_id`, `weight`, `start_date`, `end_date`, `created_at`, `created_by`, `unique_id`, `milestone`, `duration`, `is_critical_path`.
- EF also requires `projects.status`, `projects.created_by`, `project_tasks.predecessor` and `project_tasks.successor`. The database lets these be null.
- On dev, 2,110 tasks have no predecessor value. 5 projects have no status.

**MoM 19 Nov (new facts)**
- Level and Layer names (see the word list above).
- A Level 1 rejection has two confirmations: first Layer 2 Level 1 ("Yes, Reject / No, Cancel"), then Level 0.
- An urgent WO has a 2×24 h limit per layer. After the limit, the WO goes to the next layer, and the system records this.
- "When Finishing Work Order, all schedules under the same Work Order will be Finished too." So one WO can have more than one schedule.
- The simple schedule needs cost or percentage. The total must not be more than the WO budget.
- "Locking the categories which work is RTWS": a category can set the schedule type.

**Prime Mover (checked 20 Nov)**
- First draft of the Knowledge Documents, lines 210 and 214: Prime Mover is in the field list of AL Update and AL Installation. The Knowledge Documents have no "required" mark.
- Prototype: the field "Prime Mover" has `required="{{no}}"`.
- MoM M002: for SRP, type, brand, prime mover and power are not required. Only stroke length and SPM are required. Prime mover = the pump driver (electric motor or engine).
- Code (`phi-dev`): `prime_mover` is a nullable decimal on `pep_/phss_action_plan_artificial_lift`. No validator requires it.
- Branch `feat/phi-2494-ap-srp-esp`: adds `prime_mover_name` (free text, SRP only, optional). ESP clears it.

**Figma, checked 23 Nov (page "Work Order")**
- 35 "Project Class" flow nodes. Format: Budget Type → Project Category → Class.
- New since 19 Nov: ABI BD → NWD → **Flowline**; ABO → Fasprod → **Others**; ABI BD → **Drilling** (Drilling New Well, simple schedule).
- OSF: the budget type (ABI NBD or ABO) sets the class of HE, AFA, Maintenance and Inspection.
- The Figma now writes **PCTGL** (not PCTOL).
- Project Details sample: Project Category = Fasprod; Project Number / AFE = WO number "5422/WO/PROJECT/2026".
- New frames: "Level 0/1/2 Project Based", "Level 0/1 Simple Schedule", "WO category Study", Level/Layer tables.
- AL Update form (Gas Lift): Prime Mover* and Power* are required.

**Permissions, checked 24 Nov**
- `permissions` max id = 163, `permission_groups` max id = 30. 160–163 = Action Plan (groups 29, 30).
- 160–163 have no casbin rows (Retina ACL only). The system cannot list the holders of 161. 54, 58 and 63 have casbin rows.
- `users.pos_name` / `position_name` are not clean: 55 are empty, the values are mixed, and there is no Senior / Asst. Manager value.
- `approval_tierings` (Project, Contract, SPK, SPK BoQ Progress; level 1–3 per role): only shown in the user profile. No flow reads it.
- RBAC sheet: "Phantom PHI Mapping" stops at 158 (no 159–163). "Phantom PHI - NEW" uses 137–272 with other meanings, so these numbers clash with the database.
- Correction (24 Nov): the system **can** list the users who hold an Action Plan privilege. `UsersService.GetUsersByPermissionAsync` (`UsersService.cs:510`) asks Retina (`RetinaUsersByAclQueryId`) for 161, 162 and 163, because casbin has no rows for them. Other ids use casbin. A new Retina-only WO privilege must be added to `IsRetinaOnlyPermissionAsync` (`UsersService.cs:560`), which is a fixed list today.
- Approval routes (checked 24 Nov): `approval_routes` has `category`, `department_id`, `is_active`, `tenant_id`, `spk_value_threshold`. Approvers are users per level (`approval_route_users.user_id`, `level`; `approval_route_level_users` for the v2 e-sign routes). There is no layer and no permission ID per level.
- `WorkOrderNumbers` (`Logics/Services/ActionPlanApproval/WorkOrderNumbers.cs`): `{seq:D4}/WO/{department short name}/{year}`, preview + lock on `work_order_sequences`. The format is fixed in the code.
- Merged on `phi-dev` (checked 24 Nov): PR #1523 (WO schema) and PR #1530 (overview). The merged schema took most of our review: NOT NULL columns, `work_order_approvers.stage` / `permission_id` / `sla_hours`, `transferred_sub_department`, no `work_orders.project_id`, and `projects.work_order_id` (nullable, many projects per WO). PR #1533 (list) is open.
- Dev test users (checked 24 Nov): `phi.*` = old-style SYSROLE (department name); `phi.po`, `phi.approver`, `phi.superadmin` hold 161–163. `phirbac.role.*` = the PHI-2119 SYSROLE pattern test cases (do not change). No user holds a WO privilege. The PHI-2119 pattern has one approval role only (`- Approval - Member`), so it cannot tell Layer 1 from Layer 2.


- 24 Nov, code: Save As Draft built in worktree `.worktrees/wo-draft`, branch `feat/work-order-draft` off `phi-dev` (staged, not committed, not built). `POST /api/v1/work-order/draft` and `/draft/{id}`, JSON body (not multipart: files go through the attachment endpoint #12 after the draft has an id). Draft = status `draft`, Level 0 / Layer 0, no approvers, "created" history row, requestor PICs, WO number taken at save. Update: only the creator (403), only a draft (400), replaces every field and the PICs, number unchanged. `WorkOrderNumbers` now also reads `work_orders` (next number + "already used"), so WO and Action Plan never share a number. Tests: `Tests/WorkOrderDraftTests.cs`. Bruno: "Save / Update Work Order Draft" (body only, no response example yet).
