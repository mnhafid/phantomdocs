# Work Order: decision log and knowledge

This file records:
- each decision (with date and source),
- each change to the WO docs,
- each fact we found in the code or the database.

**All links:** see `02-Knowledge.md` §11.

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
| X2 | 19 Nov | ~~(replaced by TD23)~~ A Level 0 approver edits the WO and approves it in one step. The requestor gets a notification only. This step does not stop the flow. | User = MoM + Figma | – |
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
| TD17 | 25 Nov | WO notifications are **in-app only**. This includes a project made from a WO (N16 / N17): it sends no project approval email. List in `03-Endpoint-Plan.md` §6.2. | User | I5 (email open) |
| TD18 | 25 Nov | The WO uses the approval route. The requestor picks the route from the approval route list (`GET /approval-routes`, same rule: category `work_order`, active, route department in my departments). The approval steps are kept in the shared approval process tables (`approval_processes`, `approval_logs`, `approval_process_levels`), the same as the Action Plan. **Not now:** the approval route module is not changed (WO-T03 stays skipped) and Create stays as WO-T05. | User | – |
| TD19 | 25 Nov | No Action Plan cycle table for the WO. `work_order_approvers.stage` (with `level`) is enough to group the steps of one approval round. Do not copy the Action Plan cycle behavior (PO review first, one reject request per plan, return to PO). | User | – |
| TD20 | 25 Nov | Submit uses the approval route: the requestor picks the approval flow on the Create form, so Submit copies the route steps and opens the Level 0 `approval_processes` row (Layer 1) at once. Build with the approval tickets; the WO-T05 code stays as it is until then. | User | WO-T05 "no approval logic" (later) |
| TD21 | 25 Nov | Reject at Level 0 has its own approval route, category `wo_reject_level_0`. The Level 0 reject goes through that route (its own `approval_processes` row) before the WO is Rejected. | User | 03 #18 "Level 0: final" |
| TD22 | 25 Nov | Approval flow names: `Work Order Level 0` (requestor department), `Work Order Level 1` (target department, Request To), `Work Order Level 2` (Transfer or Disposition department). A WO needs **3 approval routes, one from each of these 3 departments**. Each route layer needs a **permission ID**, to fetch the users who can review (`GET /users/by-permission/{id}?department=`, TD11 / TD13). | User | Flow name proposal (TD21 text) |
| TD23 | 25 Nov | Level 0 Modify follows Jira / the PRD ([PHI-2998](https://digiitphi.atlassian.net/browse/PHI-2998), [PHI-2999](https://digiitphi.atlassian.net/browse/PHI-2999), [PHI-3000](https://digiitphi.atlassian.net/browse/PHI-3000), [PHI-3001](https://digiitphi.atlassian.net/browse/PHI-3001), [PHI-3002](https://digiitphi.atlassian.net/browse/PHI-3002), [PHI-3003](https://digiitphi.atlassian.net/browse/PHI-3003)): a Layer 1 Modify goes to **review by Level 0 Layer 2** (Manager). The Manager sees the banner "Work Order modified by [name]" + View Changes (Modification Comparison: Export, Reject, Modify, Approve). Approve → the flow goes on; Reject → the modify is refused; Modify → the Manager changes it again (Self Modify). | User (G34) | X2 (Level 0 Modify = approve in one step) |
| TD24 | 25 Nov | G36 is accepted as it is: no new Jira Stories for now. | User | – |
| TD25 | 25 Nov | `work_order_histories.level` / `layer` on a decision row = the **actor's step** (level and layer before the move). A `modified` row stores the proposer's level (2 = Level 2 proposal). Only `created` / `submitted` store the new position. | PR #1544 author (user delegated) | – |
| TD26 | 25 Nov | History visibility: (1) a Level 0 `modified` event is hidden from readers outside the requestor side (creator, requestor department, Level 0 approver), from Bruno #235; (2) a Level 2 proposal is hidden from Level 1 readers outside the Level 2 side (WO-9.2, AC-17). Hidden steps keep their row with blank remarks. Open for the PO: a reader on both the requestor side and Level 1 (request_to = own department) does not see Level 2 proposals today. | PR #1544 (2c1c5185) | – |
| TD27 | 26 Nov | **TD21 is kept.** The Level 0 reject goes through the `wo_reject_level_0` route; it is not final at once. The Layer 1 Senior and the Layer 2 Manager can both start it (WO-2.3). The reject built in `5a2ae8a4` (PHI-2997: Layer 2 only, final) is refused and must be reworked before the PR. | User | The "Reject by Lv 0 Layer 2, final" reading of PHI-2997 (25 Nov code) |
| TD34 | 26 Nov | Approval route categories, one route per department of the Level: `wo_approve_level_0` (requestor), `wo_approve_level_1` (target / Request To), `wo_approve_level_2` (transfer); `wo_reject_level_0` / `_1` / `_2` the same. The route's `department_id` must be the department of that Level. Replaces the single `work_order` category. **Confirmed / changed 26 Nov (user, G38):** the user picks the Level 0 route on Create; **Level 1 / 2 pick their route automatically** (the newest active `wo_approve_level_1 / 2` route of the Level's department, when the WO arrives); a Level 1 / 2 reject works like Level 0 (confirmed) (a round on that Level's reject route; all confirm → Rejected, one cancel → back to the layer that asked), so the two-Manager reject and `no_reject` are no longer set. | User | TD2 two-step Level 1 reject, the `work_order` category |
| TD28 | 26 Nov | WO detail F1: add `actual_start_date` / `actual_end_date` columns on `work_orders`. When a value is null, the detail response sends the plan date (`start_date` / `end_date`) of the linked project. No project = `null`. | User (FE feedback, `03` §2.4.1) | – |
| TD29 | 26 Nov | WO detail F2: new column `impact_type` (`production_gain` / `loss_avoidance`). The form sends it. Values of the not-selected type are saved and returned as `null`, not `0`. | User (FE feedback, `03` §2.4.1) | – |
| TD30 | 26 Nov | WO detail F4: the `action_plan` block has all the Action Plan fields. Modify of a simple schedule WO can change all of them. | User (FE feedback, `03` §2.4.1) | – |
| TD31 | 26 Nov | WO detail F1: no actual-date columns on `work_orders`; no action writes them. `actual_start_date` / `actual_end_date` = the project actual date if available, else the project plan date. More than one project: earliest start, latest end. No project = `null`. | User | TD28 (columns part) |
| TD32 | 26 Nov | One Action Plan per WO (Q15). The link is `work_orders.action_plan_source` + `action_plan_id` only (PR #1523 schema). No `work_order_id` on `pep_action_plan` / `phss_action_plan`, no new migration. Unblocks WO-T21. | User | – |
| TD33 | 26 Nov | An AP without a WO is still allowed (Well Surveillance). It makes its own WO number, as today. The ~50 dev APs that already have a WO number stay as they are (no migration, no clean-up). Closes the Q15 sub-questions and G8. | User | – |

---

## 2. Changes to the WO docs
| Date | File | Change |
|---|---|---|
| 19 Nov | `02-Knowledge.md` §2 | Knowledge Documents draft in the team format. It does not yet show the decisions from 19–20 Nov. |
| 19 Nov | `02-Knowledge.md` §4 | Comparison of the MoM and the Knowledge Documents: M1–M15, G1–G11, X1–X14. |
| 19 Nov | `02-Knowledge.md` §6 | Category tables per Request To. Open points K1–K12. |
| 20 Nov | `02-Knowledge.md` §6 | Tables changed to lists. Added "Approval flow by category". Added K13–K15. |
| 20 Nov | `02-Knowledge.md` §7 | New. A configurable route: stages, bindings, layer rules. Uses Level / Layer names. R1–R9. |
| 20 Nov | `02-Knowledge.md` §10 | New. Changes on `projects` and `project_tasks`. Project lifecycle. NOT NULL check. P1–P15. |
| 20 Nov | `02-Knowledge.md` §1 | Rewritten. It now has questions only, in short, simple English. Answered questions moved to this log. |
| 20 Nov | `02-Knowledge.md` §1 | Removed section I "For the Ocean team". Its two questions are now business questions in section E (new Q41 draft schedule, Q42 schedule change after approval). Questions renumbered in order: Q43–Q46 are now F, G and H. |
| 20 Nov | `02-Knowledge.md` §1 | Added section "Reference": source documents, MoM meetings, MoM topic codes (M002, M009, M014), ID prefixes, decision codes. |
| 20 Nov | `01-Decision-Log.md` | New (this file). |
| 20 Nov | Google Doc "PRD — Work Order (PHANTOM)" (title to rename: Knowledge Documents — Work Order) | Category breakdown added before FLOW 1 (table version). |
| 20 Nov | Google Doc "Work Order" (questions) | Replaced with the 20 Nov version of `02` §1. The rewrite of `02` §1 is **not** synced yet. |
| 20 Nov | Google Doc "Work Order Question" (questions) | Added a new tab "Open Questions (20 Nov)" with the rewritten `02` §1 (Q01–Q46 + Reference). Tab 1 is not changed. |
| 20 Nov | `02-Knowledge.md` §1 | Removed section H and Q46 [F12] (wrong finding, see F12x). Removed F12 from Reference. |
| 20 Nov | `02-Knowledge.md` §2 | AL table: "Prime Mover not required (F12)" changed to cite MoM M002. |
| 20 Nov | All WO docs | The word "PRD" removed. Our collected WO knowledge is now called **Knowledge Documents**. Files renamed: `02-Knowledge.md` §5, `02-Knowledge.md` §2, `02-Knowledge.md` §4. The first draft (artifact "Work Order Module (PHANTOM)") = "first draft of the Knowledge Documents". The team doc "Phantom Fase 2" is named without "PRD". Not changed: the Google Doc title "PRD — Work Order (PHANTOM)" (needs your OK). |
| 20 Nov | Google Doc "Work Order Question", tab "Open Questions (20 Nov)" | Content replaced with the current `02` §1 (Q01–Q45, no "PRD", no Q46). Only this tab was changed. Note: at this time "Tab 1" was no longer in the doc; we did not delete it. |
| 23 Nov | `02-Knowledge.md` §6, `02-Knowledge.md` §1 | Added "Project class list (Figma)". Q14, Q35, Q37 updated with Figma facts. Q46 (Prime Mover) added again. |
| 24 Nov | `02-Knowledge.md` §9 | New. Plan for Layer permissions (Q16 / R3): options A–C, proposed groups 31–32 and privileges 273–277, open points P1–P5. |
| 24 Nov | `archive/archive/10-PR-1523-Review.md` | New. Review of PR #1523 (WO schema) against the decisions: conflicts A1–A5 (one project per WO vs K15/F1, P1, D3b/R8, X5, approver copy per stage), checks B1–B7, code points C1–C5. Posted 24 Nov as a review comment (plain words, no codes) on PR #1523. |
| 24 Nov | `02-Knowledge.md` §3 | New. Decisions from the team doc (approval flow selection, Set Approval Flow window, route setup, schedule type per department, Request To / Category list, overview, disposition). 7 questions for the team. Part of PR #1523 problem 5 is now out of date. |
| 24 Nov | PR #1523 (GitHub comment) | Follow-up comment posted: https://github.com/oceaninov/phantom/pull/1523#issuecomment-7127114186. It corrects problem 5 (each department sets its own flow; approvers by permission ID, filtered by the department of the Level; backend lists users only, no permission check; unique index must include the step) and adds the Transfer rules, Level names, schedule type by department, Request To list, Disposition Work Type and spelling. |
| 24 Nov | `02-Knowledge.md` §8 | New. Mermaid charts: WO status flow (all Levels, modify / reject loops, transfer, disposition, project), approval route flow (who selects the flow and when the approvers are listed), and the status of one approval step. |
| 24 Nov | `02-Knowledge.md` §11 | New. All links: Google Docs, the RBAC sheet, Figma frames, Claude artifacts, PR #1523 (review + follow-up), PR #1476, code paths and database tables. |
| 24 Nov | All WO docs (review) | Reviewed all docs and updated them to the decisions of 19–24 Nov. `02` §1: answered questions removed (with an "Answered" list in each section), the word list updated. `02` §2: now v0.2, all flows, data and status updated (Set Approval Flow story, permission approvers, Transfer rules, schedule type by department, Request To lists). `02` §6: Request To table, spelling, approval-flow section rewritten, K points closed. `02` §7: rewritten for manual flow selection and permission approvers; the old automatic route search is marked "Replaced 24 Nov". `02` §10: schedule type by department, project approvers by permission, Disposition Work Type. `02` §9: rewritten (list-only permissions, department scope, new Set Approval Flow and Transfer permissions). `02` §5, `02` §4: a "Status 24 Nov" note lists the old points that are replaced; the old text is not changed. |
| 24 Nov | `03-Endpoint-Plan.md` | New. Endpoint plan: 26 new `/work-orders` endpoints (overview, list, form data, draft / submit, details, history, attachments, approve / modify / reject, decisions, Set Approval Flow, approvers, transfer, disposition, project prefill) and changes to existing endpoints (users by permission + department filter, approval routes with Level / Layer / permission ID, WO number format, Action Plan, projects, approval list, config keys, permissions). Build order in 6 phases. 5 open points. |
| 24 Nov | PR #1533 (GitHub review) | Review posted: https://github.com/oceaninov/phantom/pull/1533#pullrequestreview-6039043183. WO list endpoint `GET /work-order/{working_area}`. Must fix: Incoming shows WOs before Level 0 is done (also Level 0 rejects); no filter / sort (team doc: filter Description, Status, Recipient, Category, Field; sort the 4 dates). Check: title vs description, Request To names vs `users.department` (field targets match nobody), approver / PIC outside the department. Code: log the exception, cap `page_size`, date time zone, WOs with no field. |
| 24 Nov | PR #1533 (recheck of `d6149aca`) | Must-fix points fixed (Incoming after Level 0, filters, sort, title, approver / PIC rows, log, page_size cap). Open points found but **accepted for now by the user, no comment posted**: (1) `field_id` is `Guid?`, so an empty value gives a 500; (2) Incoming hides a WO when the requestor department is also my department (same-department request or transfer back). Moved to the create-WO PR: department names in `request_to`, time zone of the dates. |
| 24 Nov | `06-Test-Cases-and-Users.md` | New (plan only, nothing seeded). 13 test users `phi.wo.*` for the FE test (PO → OSF → Projects, plus SDA 1, a guest and a GM), SYSROLEs per department, and the seed list. 4 decisions needed (new SYSROLE `{Dept} - Approval - Leader` for the Manager, privilege numbers, field departments, prefix). |
| 24 Nov | `04-Endpoint-Figma-Screens.md` + `img/endpoints/` | New. 8 Figma screenshots mapped to the endpoints of `03`. Found: no "Set Approval Flow" window in the Figma; the Figma Transfer window has a mandatory PIC and no sub-unit; the Figma History shows a resubmit after a Level 0 reject; the list's first column is the WO title; no "Add file" on the Attachment tab; no Function field on the Create form. |
| 24 Nov | `05-Production-Checklist.md` | New. Checklist to go to production: branches / PRs (status), alter tables, seeds, permissions and Retina, data clean-up, release steps, 8 decisions needed. |
| 24 Nov | Bruno repo `phi-phantom-collections`, worktree `bruno/.worktrees/work-order`, branch `feat/work-order` (off `origin/main`) | New folder `collections/phi-phantom/Work Order`: `Get Work Order Overview` (phi-dev, PR #1530; 4 examples) and `Get Work Order List` (`feat/work-order-list`, PR #1533; 5 examples). The examples are the curl results in the PR texts, not a new run. Committed `5165ab4` and opened PR https://github.com/oceaninov/phi-phantom-collections/pull/235 (base `main`) on 24 Nov, on the user's request. |
| 24 Nov | Bruno PR #235 | Commit `572e575`: added all planned endpoints of `03` as Bruno requests: `Work Order/Planned - New Endpoints` (#3–#26, 23 requests) and `Work Order/Planned - Changed Endpoints` (7 requests). Each has a proposed body, example responses and docs marked **Planned**. PR title and description updated. |
| 24 Nov | `04` §2, `03` #5 | Create WO form: the Approval Flow field needs "get approval route". It reuses `GET /approval-routes?category=work_order&department_id=&search=` (search; the filters exist) and `GET /approval-routes/{id}` (progress after selection: steps, Layer, permission, SLA, approvers by permission + department). No new WO endpoint. |
| 24 Nov | `04-Endpoint-Figma-Screens.md` | Added §9 Approve confirmation, §10 Modification Comparison (Approve / Reject of a change; Manager Requestor and Manager Target), §11 Project Approval (Project Monitoring), and a table of where each approve / reject happens. Not in the Figma: the two-step rejection decision (#20) and Set Approval Flow (#21). |
| 24 Nov | `04` §12 + `img/input-parameter/` | Figma "Input Parameter" (node 18806-110894): the Action Plan window inside Create WO (simple schedule). 5 forms captured: Well Test Update, AL Update, AL Installation, Sonolog, Choke Adjustment; WLI is empty ("On progress"). Prime Mover: required for AL Update (Gas Lift), optional for AL Installation (TT/ESP); Power required in both (supports the Q46 proposal). |
| 25 Nov | `06-Test-Cases-and-Users.md` §2 | Rewritten in the scenario style of `../ActionPlan/08-ScenarioTest.md`: Tests #1–#8 (happy flow, Senior requestor, bulk approve, Action Plan WO, Level 0 Modify TD23, Level 0 Reject route TD21, Level 1 Set Approval Flow + Modify, Level 1 Reject two confirmations, Transfer / Level 2, Disposition Work Types, permission negatives), each step with WO status · Level · Layer, process, notification (N-codes) and task. New §2.9 "Check on every step". The old F1–F14 table kept as §2.10 with notes on F2 / F5 / F6. |

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

- 24 Nov, docs rearranged (user request): only 6 numbered files. `01-Decision-Log.md`, `02-Knowledge.md` (PRD Knowledge Documents, team doc decisions, MoM, Figma / prototype review, categories, approval route, status flow, permissions plan, project changes, links, and §1 Gaps, which must be updated with every new knowledge), `03-Endpoint-Plan.md`, `04-Endpoint-Figma-Screens.md`, `05-Production-Checklist.md`, `06-Test-Cases-and-Users.md`. No PR review files from now on. The old files 00–16 are in `archive/` (not deleted). References inside the docs point to the new names.

- 25 Nov, knowledge: read the FE API Spec (Notion). Overview and list match the merged BE and the Bruno examples (BE also sends `title`). Create / draft, approvers, codes, attachments and verbs do not match: gaps G19–G31 in `02-Knowledge.md` §1.

- 25 Nov, decisions (user, answers to the FE API Spec gaps):
  1. Keep **both** Save As Draft (`POST /work-order/draft`, `/draft/{id}`) and Create = submit (`POST /work-order/{working_area}`). All three take the FE multipart form.
  2. `request_to` stores the FE **code**; `custom_configurations` `work_order.request_to` maps code → `users.department`. The list / overview Incoming match through it (old rows with a department name still match).
  3. Use the FE values: `urgency_level` as the FE sends it; `budget_type` codes `abibd`, `abinbd`, `abo_routine`, `abo_non_routine`, sent as an **array** with one value for now.
  4. Approvers: accept **both** `approval_route_id` and `approvers[{level, sla_days, user_id[]}]`. `approvers` wins (the user can edit the route); a draft keeps them, so Update Draft can change the route.
  5. Attachments: max **5** files per WO (not 1).
- 25 Nov, code (`feat/work-order-draft`, staged, not built): `WorkOrderFormService` (draft, update draft, create), `WorkOrderForm` (multipart parser), `WorkOrderConfig`, list / overview code matching, seed `seed_work_order_config.sql` (`work_order.request_to`, `work_order.categories_without_approval` from D4). Tests `WorkOrderFormTests.cs`. Bruno: Save / Update Work Order Draft (multipart) and Create Work Order.
- 25 Nov, plan: Create WO implementation plan added as `03-Endpoint-Plan.md` §7 (rebase `feat/work-order-draft` on `phi-dev`, add next-number, form-options, delete draft, tests, build, seed, Bruno, PR). Waits for OK and 4 decisions.

- 25 Nov, decisions (user, WO test users):
  1. Manager (Layer 2) SYSROLE = `{Dept} - Approval Manager`, a 2-part "Department - Action" name (not `- Approval - Leader`). `SysRolePattern` on phi-dev accepts 2 parts; "Manager" is not a regulator keyword.
  2. WO privileges = **273–279** (groups 31 "Work Order", 32 "Work Order Approval"). Closes G2 / P1.
  3. 13 `phi.wo.*` users are enough (no field-department users).
  4. Prefix `phi.wo.*` OK.
- 25 Nov, dev DB (seeded): privileges 273–279 + groups 31 / 32; 13 users `phi.wo.*` (`users.id` `0b000000-…-000000000601`–`613`; `…5xx` is taken by `phirbac.role.*`), each with token / session / introspect rows in `mock_auth_sessions`. File: `sql/seed_wo_test_users.sql` (generated by `sql/gen_wo_seed.py`, re-runnable, not in the repo). Checked after the run: no duplicate permission ids; 3 stages per user; SYSROLE and WO SEQs as in `06` §4.5.
- 25 Nov, open for the FE test: WO approval routes (wait for G3), `IsRetinaOnlyPermissionAsync` must include 273–279 or the approver lists stay empty, WO config keys.
- 25 Nov, docs: new file `07-Ticket.md` (user request). One ticket per endpoint of `03` (WO-T00–T23), business logic only. Jira keys and status are kept there.
- 25 Nov, code (`feat/work-order-draft`, staged, not built): branch moved onto `origin/phi-dev` (8c6775f7, includes #1539); the staged patch applied clean. Added WO-T01 `GET /work-order/next-number`, WO-T02 `GET /work-order/form-options`, WO-T06 `POST /work-order/{id}/delete` (history action `deleted`), 5 tests. Bruno: the 3 requests moved out of "Planned". `07-Ticket.md` has a Test result block (user, date, curl, response) on T01, T02, T04, T05, T06; not run yet (the build needs your OK).
- 25 Nov, decisions (user): WO-T03 (approval route layers) skipped for now. WO-T05 Create does nothing on approval: no approvers / route read, no approver rows, no no-approval skip; status always waiting_approval Level 0 / Layer 1. Next-number reads `work_order_sequences` (dev: SDA1 96, SDA2 13).
- 25 Nov, code: T05 changed as above; fixed missing usings (the staged code did not build before). Build OK, 29 WO unit tests pass. Curl tests wait: a local WebApi writes to the shared Quartz store (no guard on phi-dev), and `work_order.request_to` is missing on dev.
- 25 Nov, test (curl, local WebApi on dev DB, Quartz in RAM by a local change that was reverted after): seed `seed_work_order_config.sql` run on dev (request_to, categories_without_approval, short names PO / OSF / PROJECTS / DRILLING / WLI). 17 cases for WO-T01, T02, T04, T05, T06 all pass; results in `07-Ticket.md`. Users `phi.wo.po.pic`, `phi.wo.po.senior`. Test rows left on dev: 0001/WO/PO/2026 and 0002/WO/PO/2026 (waiting_approval, no approvers), 0003/WO/PO/2026 (deleted draft); PO counter = 3.
- 25 Nov, decisions (user): Jira PHI-2993 for WO-T01, T02, T04, T05, T06 (recorded in `07`). Keep the curl test rows on dev (do not remove). Bruno: examples replaced with the real curl responses (16 examples; the extra "save draft to delete" case is not an example); planned 06 / 07 / 08 deleted (Save draft, Update draft, Submit are now built requests). Staged on `feat/work-order`.
- 25 Nov, decision (user, TD18): WO uses the approval route + the approval process tables (Action Plan pattern). Not now: no change to the approval route module or to Create (WO-T05). Design in `03` §2.5 and `07` WO-T10.
- 25 Nov, decisions (user, TD19–TD21): no cycle table (stage is enough, no AP cycle behavior); Submit opens the Level 0 process from the chosen route; Level 0 reject uses route category `wo_reject_level_0`. Design in `03` §2.5, tickets WO-T05 / T10 / T12.
- 25 Nov, decision (user, TD22): flows Level 0 / 1 / 2 = requestor / target / Transfer-or-Disposition department; 3 routes from 3 departments; each layer has a permission ID to fetch users.
- 25 Nov, test (user: "run test first", then "add curl test to create wo"): 29 WO unit tests pass. Create scenarios in `06` §1.2; curl run 2 in `07` WO-T05 (39 calls, Quartz in RAM by a local change, reverted). All pass except B4: `yyyy-MM-dd` date accepted by the shared parser (open). Draft approver rows stay on Create (open). 422 text says "action plan". Test rows 0004–0015/WO/PO/2026 kept on dev. Code: stale `WorkOrderFormService` class comment fixed (staged).
- 25 Nov, PRs: user committed (phiDev c7cc887f, Bruno 5de37bf). Opened oceaninov/phantom#1545 to phi-dev with the 56 curl calls in the description. Bruno pushed to PR #235 (synced first with 3 commits from a teammate: Histories, List / Overview; seq moved to 4–9) and its description updated. Rule added to CLAUDE.md and AGENTS.md: use `gh` to make or update a PR.
- 25 Nov, docs: Jira Stories of epic [PHI-2465](https://digiitphi.atlassian.net/browse/PHI-2465) mapped to the WO tickets (`07` §3, mapped by title). Jira links added to `07` (ticket list + new WO-T24 Export), `03` §2.0 (Jira column), `02` (NID headers, §11 Jira, gaps G34–G36) and `05` §1.
- 25 Nov, code (user: "fix B4, accept only dd-MM-yyyy for work order and fix conflict"): `ParseWoDate` (dd-MM-yyyy only) for draft / update / create, 5 unit test cases added; commit 4c0a5580 (test run denied, not run). Conflict with #1544: merged `feat/work-order-histories` into `feat/work-order-draft` (b94fc125): endpoint keeps both route blocks, `VisibleTo` takes `targets` (Request To codes). Build OK. #1545 base moved to `feat/work-order-histories` (stacked); merge #1544 first.
- 25 Nov, decisions (user): G34 → TD23 (Level 0 Modify has a Layer 2 review, as Jira). G35 → Export details read from the PRD (team doc): Export button on Details Work Order at every level + Modification Comparison; the PRD section "Work Order - All Levels - Export" is empty; plan #27 `GET /work-order/{id}/export`, format open. G36 → kept as is (TD24).
- 25 Nov, code (user: "analyze and work ticket PHI-2996, PHI-2997"; the user gave no answer to the 3 questions, so the recommended answers were used): new branch `feat/work-order-approval-l0` on `feat/work-order-draft`, staged only. PHI-2996: Create does TD20 (copies the flow, opens `Work Order Level 0`, no flow = 400, route category `work_order`); `POST /work-order/{id}/approve` for Level 0. PHI-2997: `POST /work-order/{id}/reject` by the Level 0 Layer 2 Manager only, final; **TD21 reject route not used (to confirm)**. Build OK; 7 new / changed unit tests, not run (test run was denied). Jira PHI-2996 / PHI-2997 have no description.
- 25 Nov, test (user: "yes agree"): 45 WO unit tests pass. Curl 21 calls for PHI-2996 / PHI-2997 all pass (results in `07` after WO-T12). Made a `work_order` route on dev ("WO PO Level 0 (curl test 25 Nov)", PO, senior / manager); test rows 0016–0018/WO/PO/2026 kept. Fix after the run: Create from a draft with no flow in the request keeps the draft route (SLA template). Quartz local change reverted.
- 25 Nov, PR #1544 review: author fixed CC (walker), allow-list incl. `action_plan.<key>`, Level 2 hiding, `waiting_approval` (2c1c5185, Bruno 86f7727). TD25 / TD26 recorded. G34 was decided in parallel (TD23, Level 0 Modify has a Layer 2 review): told the author. Integration: `request_to` codes need `TargetKeysAsync` in `VisibleTo` / Level1Side when `feat/work-order-draft` rebases.
- 25 Nov, FE feedback on `GET /work-orders/{id}` (user: "add on Endpoint Plan"): 4 points F1–F4 recorded in `03` §2.4.1: actual start / end dates (no columns yet), loss avoidance + null instead of 0 in `production_impact`, `position` in `pics`, `action_plan` block for Modify of a simple schedule WO. Open: who sets the actual dates, `impact_type` column or derived, which Action Plan fields Modify can change.
- 26 Nov, code (user: "keep TD21", then "yes" to the rework with the proposed answers): Level 0 reject reworked on `feat/work-order-approval-l0`, staged only (not built, tests not run). Reject by Layer 1 or 2 opens the `wo_reject_level_0` round (route of the requestor department, users copied as a new stage); new `POST /work-order/{id}/rejection/decision` (confirm / cancel). Details in `07` WO-T12. Open: concurrency guard for two approvers at the same time (no row version on `work_orders`).
- 26 Nov, code (user: "do all ticket now"; the 4 questions got no answer in 60 s, so the recommended answers were used, **to confirm**): (1) scope: T03 (skipped), T08 (#1544), T09 (#1547) and T21 (blocked) left out; (2) Transfer body takes department + optional sub_unit + optional pic_ids; (3) Level 0 Manager rejects a Level 0 modify → back to Layer 1 with the old values (G34); (4) Export (T24) not built (G35). Built on `feat/work-order-approval-l0`, staged only, not built, tests not run: T07 details + actions, T10 Level 1 / 2 + bulk, T11 Modify (all Levels), T12 / T14 Level 1 / 2 reject + two confirmations, T13 modification decision, T15 Set Approval Flow, T16 approvers + `/users/by-permission?department=` + `permissions.retina_only_ids`, T17 Transfer (+ options), T18 Disposition, T19 project prefill, T23 `work_order_approval` in my-approval-list. Not done: T20 (shared AP number code on prod), T22 (project flows on prod, Q36). Also: the Incoming / visibility rule now also counts a WO with Level 1 / 2 steps (the requestor Manager step sits at Level 0). New config keys: `work_order.transfer_departments`, `work_order.transfer_sub_units`, `work_order.disposition_work_types`, `permissions.retina_only_ids`.
- 26 Nov, test (user: "yes"): build OK after 2 fixes (missing `using Microsoft.Extensions.Logging` in the new partial files; a type name in the test). 155 WO / my-approval-list / users-by-permission / my-task tests pass. Full suite: 5,877 pass, 4 fail, none from this change: `AuditModulesTests` (every `/work-order` route has no AuditModules rule, also the merged list / overview, plus the production-report routes), 2 `RolePermissionCacheInvalidationTests` (`retinaRolesService` not registered), `ActionPlanApprovalTests.List_ShowsEveryPlanWithProgress…` (passes alone: test order). No curl run yet.
- 26 Nov, code (user: "remove it use like existing"): `permissions.retina_only_ids` config removed. The WO privileges 273–279 are Retina-only in code, the same as the Action Plan ids: new `WorkOrderPermissions` constants, used by `UsersService.IsRetinaOnlyPermissionAsync`. Build OK, 83 related tests pass.

- 26 Nov, decisions (user: "F1: if null get from plan date project / F2: new column / F3: / F4: all field from action plan"): TD28–TD30 recorded; `03` §2.4.1 updated. F3 kept as planned (no answer needed).
- 26 Nov, decisions (user: "use plan date it will use project actual if available" / "yes use your propose"): TD31 replaces the column part of TD28; `03` §2.4.1 F1 updated. Fact: `projects` has no actual-date column today (only `start_date` / `end_date`), so the response gives the project plan dates for now.
- 26 Nov, review + fixes (independent code review; user: "8. No Reject yes", "9. No use same treatment for all approval level"): (1) overview `in_review` = newest stage of the **current Level** (was: of the whole WO, so the Senior was not counted after a refused Level 1 reject); (2) the requestor Manager step opens its own SLA timer on the Level process; (3) Set Approval Flow refuses a flow with no Layer 1 user; (4) `GET …/approvers` and `…/transfer-options` return 404 for a WO the caller cannot see; (5) details `actions` use the same department fallback as the actions (`users.department` when no active department) and show Level 0 Reject only when the requestor department has an active `wo_reject_level_0` route with users; `export` removed from the description; (6) bulk approve also catches `DbUpdateException`; (7) the Level 0 timer closes as `canceled` (a pause) when the reject round opens; Self Modify writes `approved` one tick after `modified`; (8) **Transfer clears `no_reject`** (user); (9) **same rule on every Level** (user): the next reviewer is the next real layer after the one that acted, and the requestor Manager step keeps the real layer number of the last Level 0 layer (no forced Layer 2); the decisions check the current layer. Build OK; 159 related tests pass (4 new); full suite 5,882 pass, 3 known failures not from this branch (audit rules for `/work-order`, 2 role-cache DI).
- 26 Nov, PR (user: "commit and on PR request add module that create and new … table impacted"): commit `45ca02aa` on `feat/work-order-approval-l0` (after `5a2ae8a4`), pushed. PR https://github.com/oceaninov/phantom/pull/1548, base `feat/work-order-draft` (#1545). The PR text has one section per module (Notification, Approval Flow Process, Work Order, Project, Project Task, Approval Route, User and Permission) with what is new and the tables impacted. No migration.
- 26 Nov, code (user: approval route must have wo_reject_level_1 / _2 and wo_approve_level_0 / _1 / _2, per department of requestor, target and transfer; Project: new routine / non-routine column + new category; users/by-permission?department=): TD34 built, staged on `feat/work-order-approval-l0` (not committed). Reject round generalised (`WorkOrderApprovalService.Reject.cs`): `Work Order Reject Level N` process, the Level's steps copied again on cancel; the details `actions` show Reject only when the Level's reject route exists. Create / Draft accept only a `wo_approve_level_0` route of the requestor's department. Tests updated; WO tests pass, full suite 4 known failures. **Project not built:** the column name / values and the new category are not decided (dev `projects.category`: newwelldevelopment 749, fasprod 596, flowline 4; the backend has no category list), and it needs a migration on a prod table. `users/by-permission?department=` was already in PR #1548.
- 26 Nov, `07` status check (user: "updated ticket Status check on WO-T08 WO-T09 ..."): WO-T08 = PR #1544 open, mergeable, 1 comment review, no approval. WO-T09 = PR #1547 open, no review, adds edit-description endpoint. WO-T21 blocker written out: Q15, link column (`05` §2 item 5), AP without WO / ~50 dev APs (G8).
- 26 Nov, decision (user: "yes use one AP per WO"): TD32. `02` Q15 main question answered; `05` §2 item 5 decided; `07` WO-T21 unblocked (To do). Still open, not blocking: AP without a WO, ~50 dev APs with a WO number (G8).
- 26 Nov, code + PR (user: "Project: yes use that; new category add other for now"; PR text: modules, endpoints, user setup / SYSROLE, tables, business decisions, status cycle): `projects.work_type` (`routine` / `non_routine`, from the disposition ABO Routine / Non Routine) + category `other` (like Fasprod) built; migration `20261125200717_AddProjectWorkType` (column only, drift removed by hand, CRLF kept). WO prefill returns category `other` + `work_type`. Commit `872e64e8` pushed; PR #1548 title and text updated with the 6 sections. My approval-route decision renumbered TD28 → **TD34** (TD28 = the WO detail columns, TD33 = AP without a WO, both from another session). Note for the PO: the user's example "1 WO 1 action plan 1 project" — the recorded decision is 1 WO : 1 Action Plan (TD32) but 1 WO : **many** projects (K15); the PR states that. Not applied: the migration on the dev DB (7 dev-DB integration tests fail with "Invalid column name 'work_type'" until it runs).
- 26 Nov, decision (user: "yes, it create wo number to. For current data leave as is."): TD33. `02` Q15 fully answered, G8 closed; `07` WO-T21 has no open points.
- 26 Nov, docs recheck (user: "recheck knowledge and ticket again"): my approval-route decision renumbered again **TD33 → TD34** (another session added TD33 = AP without a WO at the same time; its 5 references kept). `02`: status chart and table 1a now show the reject round on every Level (two-Manager reject crossed out); TD34 notes in §2 (data / status / AC), §6, §7, §9; §10 gets `projects.work_type`; new gaps G38 (TD34 parts to confirm) and G39 (WO project category `other` for now). `07`: status of T03, T05, T07, T10–T19, T22, T23 updated to PR #1548 (commits `45ca02aa` + `872e64e8`); T03 / T12 / T14 / T15 / T19 / T22 texts updated; dev curl route must change to `wo_approve_level_0`; a PR #1548 summary under the table. PR #1548 text: TD33 → TD34.
- 26 Nov, PR #1545 review check (user: "check this comment PR if still update to our knowledge or need to comment if comment invalid"): 5 inline findings by AgieAja (25 Nov) all checked against `4c0a5580` and valid (2 High upload: client Content-Type stored, upload result dropped; 3 Medium: orphan files, no RequestSizeLimit + ReadFormAsync outside RunAsync, wrong Swagger text). No comment is invalid. The reviewer's question (doc 03 vs WO-T05) is answered by TD20 + the 25 Nov 'no category skip': the flow is required, no skip, result always waiting_approval L0. `03` #8 fixed; findings listed in `07` WO-T05. Reply posted 26 Nov (user: "answer it with link of our decision"): https://github.com/oceaninov/phantom/pull/1545#discussion_r4700784086, with permalinks to TD20 (`01` L72) and the 25 Nov no-skip decision (`01` L218) at phantomdocs `ef8b6fd`.
- 26 Nov, code (user: "G38 yes user need pick when create WO but for level 1 and level 2 automate choose from approval route. G39: yes use it. It was varchar, dont add validation"): commit `71930aea` pushed to PR #1548. Level 1 / 2 flow picked automatically on arrival (`AutoFlowAsync`: after the last Level 0 approve, an accepted Level 0 change / Self Modify, and a Transfer); Set Approval Flow with an empty body does the same pick; `approval_flow_set` history row 2 ticks after the moving action. `projects.work_type` free text, nvarchar(255) (migration not applied anywhere yet, so changed in place). 3 new tests; related tests pass except the 7 dev-DB tests that need the migration.
