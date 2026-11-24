# Action Plan Approval — PRD Gaps & Open Decisions

_Created 2026-11-02. Compares the PRD with the design and the Bruno contract._

| Source | Where |
|---|---|
| PRD | Google Doc "PRD Phantom Fase 2", section **Artificial Lift** (PHI-2242, 2243, 2245, 2246, 2247, 2251, 2256, 2259, 2260) + PHI-2442 (status/detail table). Well Test section (PHI-2354…) follows the same rules. https://docs.google.com/document/d/1g_vkah0cJ9ftP4zgRZmNIi14nBtegGcacsy6LBxOeVk |
| Design | `Approval.md` (this folder), updated 30 Oct 2026 |
| Bruno contract | oceaninov/phi-phantom-collections PR #176, branch `feat/action-plan-approval`, folder `Action Plan Approval` (PROPOSED, not implemented) |
| Flow | `ApprovalFlow.md` / `ApprovalFlow.png` |

Status: phiDev has **no** approval/WO/WHC code yet. `Pep/PhssActionPlanArtificialLift` hold only the old fields.

## Matches the PRD

- Approval scope: AL with method `well_head_compressor` (+ well test). Other types are auto-approved.
- PO review: approve / modify / reject. Modify goes PO Mgr levels → SSDP. Reject goes through PO Mgr levels only.
- Manager rejects a modify (PHI-2251) or SSDP rejects it (PHI-2256) → `modify_returned`, PO pool notified.
- Reject path (PHI-2259): "Yes Reject" = approve endpoint. "No, Don't Reject" = reject endpoint → back to PO to modify.
- `modification-diff` always returns both sides (before/after).
- Approval route is only a template from Data Config. The payload sends the final approvers.
- Submit notification copy matches "Artificial Lift Request / WO Number [No] Artificial Lift Need Approval".

## Gaps

| # | Gap | PRD | Design / PR #176 | Type |
|---|---|---|---|---|
| G1 | WHC form fields | 2242: Type (Mobile/Permanent), Compression Type (1 mm / 0.5 mm), Owned by (Rental/Owned), Contract No / Asset No, Cost Allocation (WBS) | Not in any request, diff or entity | Not covered |
| G2 | Pressure hidden for WHC | 2242: "Hide kolom Pressure" | Modify example sends `"pressure": 140.0` | Not covered |
| G3 | Production ≤ Compression Type | 2242 | No check | Not covered |
| G4 | Locked fields in Modify | 2245: WO No, Action Type, Activity Type, Method cannot change | Only `action_plan_type` / `well_id` blocked. Diff example changes `activity_type` | Partly covered |
| G5 | WO number format | 2242 + WT: 4 digits `XXXX/WO/Dept/YYYY` | `D3` "sama seperti SPK", SDA1/SDA2 short names from config | Conflicts |
| G6 | SSDP Assign to at submit | 2242: Assign to "Production & Operation Zona 9". Task card: "PIC Assignment: Nama PIC (User PO) yang di Assign oleh SSDP" | Submit body unchanged. Whole PO pool (perm 160) notified | Not covered |
| G7 | PO Assign to + PIC on approve | 2243: PO picks dept (Projects, P&O, OSF, WI, Field Tanjung, Field PHSS) + PIC. AL "dapat mengisi", WT "mandatory" | Approve body = `decision` + `remarks` only | Not covered |
| G8 | Route category | 2260: "Action Plan Artificial Lift" (WT: "Action Plan Well Test") | Generic `Action Plan Modify` / `Action Plan Reject` per SSDP dept | Conflicts |
| G9 | Approval trigger | 2242: AL + **Activity Type Installation** | WHC "semua mode" | Conflicts |
| G10 | Final notifications | 2243/2247: SSDP gets "Artificial lift in progress". 2259: **SSDP and PO** get "Action Plan Rejected by Manager" | Approved/Rejected marked "draft, belum diminta", SSDP submitter only | Design stale |
| G11 | Task card has no assigned PIC | 2243/2246 | Items only have `requested_by` (SSDP) | Follows from G6 |
| G12 | Task card has no `activity_type` | Card copy shows "Installation" | Items only have `action_plan_type` | Not covered |
| G13 | No AL submit example in Bruno | — | Only a PEP well test submit example | Not covered |
| G14 | PHI-2442 visibility | View for PIC well, PIC WO, PIC action plan, SSDP requester, approvers. Non-approvers view-only. "Routing" progress state | Not covered | Not covered |

PRD issues: PHI-2243 Given/copy is pasted from Well Test. PHI-2246 leaves the action plan's state on the well detail page "TBC". The `well_head_compressor` method value is still an open question in `Approval.md`.

## Schema constraints found in code

| Column | EF max | Effect |
|---|---|---|
| `approval_routes.category` | 20 (`DbContext/PhantomDb.ApprovalLog.cs`) | `Action Plan Artificial Lift` (27) / `Action Plan Well Test` (21) don't fit |
| `approval_processes.approval_flow` | 30 | `PHSS Action Plan Artificial Lift Modify` (39) doesn't fit |

- `approval_processes.reference_id` is mapped as an FK to `projects` (`PhantomDb.Project.cs:46`). EUR already stores non-project IDs there, so it should be a logical link only.
- Not checked: the dev DB itself (it's known to drift from EF). Check with `sys.columns` / `sys.foreign_keys` before writing a migration.

## Table adjustments

**A. Already in `Approval.md`:** new columns on `pep_/phss_action_plans` (`department_id`, `requires_approval`, `approval_status`, `current_cycle_id`, `approved_at/by`, `rejected_at/by`, `work_order_number`). New tables `action_plan_approval_cycles`, `action_plan_modifications`, `action_plan_approvers`, `action_plan_approver_slas`, `work_order_sequences`. Seeds for 3 `custom_configurations` rows + 7 `notification_templates`.

**B. Missing from `Approval.md` (depends on the decisions below):**

| Gap / Q | Table | Change |
|---|---|---|
| G5 / Q3 | none | Code: `D3` → `D4` |
| G6 / Q5 | `pep_/phss_action_plans` | + `review_department_id` nvarchar(50), + `review_pic_id` uniqueidentifier null |
| G7 / Q6 | `pep_/phss_action_plans` | + `execution_department_id` nvarchar(50), + `execution_pic_id` uniqueidentifier null. Kept separate from SSDP's `pic_id`. Alternative: reuse `*_action_plan_pic_assignments` with a role column |
| G8 / Q2 | `approval_routes.category`, `approval_processes.approval_flow` | Widen to nvarchar(100), or use short codes |
| G9 / Q1, G4 / Q7 | none | Rule / validation only |
| G10 / Q8 | `notification_templates` | Change the Approved/Rejected copy. Move from draft to active |
| G1 (later) | `pep_/phss_action_plan_artificial_lift` | + `whc_type`, `compression_type` (decimal), `owned_by`, `contract_number`, `asset_number`, `cost_allocation` |

## Open decisions — Round 1 (approval)

Recommendations are marked ➡️; decisions are marked ✅ (grill 2026-11-03).

- **Q1 Trigger (G9):** (a) AL + WHC + installation only / (b) any WHC activity. ➡️ (a). For PHSS 1:N, it applies if any active row matches.
  - ✅ **Decided 2026-11-03 (grill):** approval needed for every **Well Test**, and for an **Artificial Lift with `method = well_head_compressor` and `activity_type = installation`**. Everything else is auto-approved. PHSS: the one AL row in the submit body. WHC is a **new `method` value `well_head_compressor`**. Frozen in `requires_approval` at submit.
- **Q2 Route category (G8):** (a) per type × path (`… AL - Modify` / `- Reject`) / (b) one per type, the FE trims the SSDP level for reject / (c) keep generic. ➡️ (a). Also choose: widen the columns or use short codes.
  - ✅ **Decided 2026-11-03 (grill, follows the PRD):** **(b) one route per action type, per source.** PHI-2260 / PHI-2420 define "Approval Category : Action Plan Artificial Lift / Action Plan Well Test", "disiapkan untuk PHSS dan PEP", with the standard Add New Route form (Title, Description, levels with 1+ approvers, SLA days per level). 4 categories: `action_plan_pep_artificial_lift`, `action_plan_phss_artificial_lift`, `action_plan_pep_well_test`, `action_plan_phss_well_test` (FE labels them "Action Plan Artificial Lift / Well Test" + PEP/PHSS). Columns widened to nvarchar(100) anyway (db migration). *Supersedes the earlier same-day 8-category (per Modify / Reject) choice.*
  - The route holds the **full Modify chain** (Mgr 1 → Mgr 2 → SSDP). For a **Reject the FE drops the last (SSDP) level** before sending `approvers`; the PO can edit levels anyway. The SLA template applies to the levels sent.
  - **Why per source, not per submitter department:** PEP is always submitted by SSDP Area 1 and PHSS by SSDP Area 2, so the source stands for the department. Data Config creates the routes from its own department (normal `POST /approval-routes`), and the 4 categories skip the department gate on `/approval-routes/all` so the PO sees them (EUR logic untouched).
  - **Built (PHI-2243 worktree):** `POST /approval-routes` and `/{id}/update` reject an unknown `action_plan_*` category (400 listing the 4) and store it lower-case. Prefill `GET /well-surveilence/action-plans/{source}/:id/approval-route` (no `path` param) and the SLA template fallback look up by category only, newest active route wins. `approval_processes.approval_flow` stays `PEP|PHSS Action Plan Modify|Reject`.
  - **Breaks if:** an SSDP Area may submit for the other source. Then the route must be keyed by department after all.
- **Q3 WO digits (G5):** ➡️ `D4` (`0001/WO/SDA1/2026`).
  - ✅ **Decided 2026-11-03:** 4 digits, per department per year, never reused (also for rejected plans).
  - ✅ **Changed 2026-11-05 (user):** sequence works like the SPK number. `GET /well-surveilence/action-plans/next-wo-number` previews the next (highest used `NNNN/WO/{short}/{year}` on PEP + PHSS plans + 1); submit takes optional `wo_number` (must match the submitter's short name and year, unused, else 400 \"get the next number again\"); a concurrent duplicate hits the filtered unique index → same 400. Table `work_order_sequences` **dropped** from the migration.
- **Q4 WO department segment:** ➡️ keep the submitter's (SSDP) short name from config. That already matches "pemberi tugas".
  - ✅ **Decided 2026-11-03:** submitter's department short name from `work_order_department_short_names`; no mapping → submit 400 (so a user outside SDA1/SDA2, e.g. Super Admin, cannot submit until mapped).
  - ✅ **Submitter vs source:** no backend check. WO uses the submitter's department; the route is only a prefill the PO can edit; the FE guard 154/156 already limits SDA1 → PEP and SDA2 → PHSS writes.
- **Q5 SSDP Assign to (G6):** (a) only the assigned PIC is notified / (b) department only / (c) store dept + PIC, notify the dept pool, show the PIC on the card. ➡️ (c).
  - ✅ **Decided 2026-11-03 (after reading the PRD):** (b). PRD 2242 / 2354 give SSDP only "Assign to untuk Department" (Production & Operation Zona 9; Project Zona 9 out of sprint 2), **no PIC**. Submit takes `assigned_department` **inside the type object** (`well_test.assigned_department`, `artificial_lift.assigned_department` for AL WHC), **required when the plan needs approval**, stored on the parent column `assigned_department` (renamed from `review_department_id` 2026-11-05); whole PO review pool notified. `review_pic_id` column stays in the db migration but is **not exposed** in the API.
  - **PRD inconsistency (ask PM):** the PO task card (2243 / 2355) shows "PIC Assignment: Nama PIC (User PO) yang di Assign oleh SSDP", but SSDP never picks a PIC. Until clarified the card shows the assigned department.
- **Q6 PO Assign on approve (G7):** ➡️ add `assign_department_id` + `assign_pic_id`, mandatory for AL and WT. Stored as a separate `execution_pic_id` (check "dapat mengisi" vs "mandatory" with the PM).
  - ✅ **Decided 2026-11-03:** PO approve takes `execution_department_id` + `execution_pic_id`. The PIC is the **field person who does the work**, not an approver (no approval task, no notification). **WT: both required** (PHI-2355 "mandatory"). **AL: optional** (PHI-2243 "dapat mengisi"; its pasted WT "mandatory" line is a copy error). The PIC must be an **active user whose `users.department` equals the chosen department**, so a PIC needs a department. FE flow: pick department, then PIC from `GET /users/all?department=`. The Modify path has no assign step (stays empty).
  - **Data gap:** PRD options Field Tanjung / Field PHSS / WI have no users on dev, and PRD labels ("Production & Operation") differ from `users.department` values ("Production Operations"). The FE dropdown must send real `users.department` values.
- **Q7 Locked fields (G4):** ➡️ 400 if `proposed.artificial_lift.activity_type` or `method` differs from the live row.
  - ✅ **Decided 2026-11-03:** exactly the PRD list: **WO No, Action Type, Activity Type, Method** (+ `well_id`). `action_mode` and `well_test_action` stay modifiable.
- **Q8 Final notifications (G10):** ➡️ promote both from draft. Approved → SSDP submitter, title "{Action Type} In Progress". Rejected → SSDP submitter + the PO reviewer who chose Reject (`decided_by`), PRD copy.
  - ✅ **Decided 2026-11-03:** both are **sent** (live). Approved (PO approve or last Modify level) → SSDP submitter, title `[action_type] In Progress`. Rejected (last Reject level) → SSDP submitter + the PO who chose Reject, "rejected by Manager". Auto-approved → none. **No notice to the execution PIC.**
  - **Rule for all gaps:** if the PRD does not define it, don't add it.

- **Q9 Permissions:** 160 "Process Action Plan Request" (group 29, DB only) = PO review. New **161 "Approve Action Plan"** (group 29) = level approve/reject. History/diff use 153/155. Not split per area. ➡️ Accept. See `WorktreePlan.md` §1.1. Also: `Approval.md` wrongly says group 29 is unused.
  - ✅ **Decided 2026-11-03:** new **group 30 "Action Plan Approval"**: **161 Review Action Plan** (`POST …/review`; `action_plan_review_permission_id` = 161), **162 Approve Action Plan** (`POST …/approval/approve`), **163 Reject Action Plan** (`POST …/approval/reject`). A level decision needs 162/163 **and** being in `action_plan_approvers` for the pending level. Grants: 161 → PO + Super Admin; 162/163 → PO, SDA1, SDA2, Super Admin. **160 left untouched and unused.** History/diff stay 153/155. Add 161–163 to the RBAC sheet (user).

Later rounds (still open): WHC fields (G1–G3; paused at "same fields for installation_update or schedule only?"), PHI-2442 visibility (G14), task card fields (G11–G12).

## PRD comparison 2026-11-05 — conflicts resolved (all "use PRD")

1. **Level reject remarks optional** (PRD 2246 / 2364 "User dapat memasukkan remarks (optional)"). PO Reject at review keeps remarks **mandatory** (PRD 2259 / 2419).
2. **Final rejected copy** (PRD 2259 / 2419): title `Action Plan Rejected by Manager`, message `WO Number [wo_number] Action Plan rejected`. Seed template `phantom_iac_action_plan_rejected` updated.
3. **Modify carries the PO assignment** (PRD 2363 "Assign Dept, Assign PIC"): `review` modify takes `execution_department_id` / `execution_pic_id` with the Q6 rules (WT required, AL optional, PIC active in that department). Stored in the snapshots (top-level keys), shown in the diff, written at the final approval. Supersedes "Modify path has no assign step" in Q6.
4. **Well Test Type** (PRD 2354 "ada 2: Regular Well Test & Optimization Well Test"): options `production_test` → "Regular Well Test", `optimization_test` → "Optimization Well Test". Keys not renamed. `buildup_test` dropped from the list (3 PHSS rows on dev keep the key, show no label).

**New gaps found (open):** `assigned_department` has no allowed-value list; task card needs `well_test_action`; v1 approval-route create does not enforce Description (PRD mandatory); in-approval status label has 3 PRD names ("Modified" / "On Process Approval – TBC" / "Routing"); MoM 26 Okt "end state success di halaman detail well"; Bruno Review/Approve/Reject/folder out of date vs backend.

## Permissions follow-up 2026-11-05 (user: "b and c")
- **Gates read the caller's Retina ACL** (same source as `GET /users/permissions` and FR-011): review → 161 (config `action_plan_review_permission_id`), level approve → 162, level reject → 163; a level decision also needs the user on the pending level. No ACL (Retina down / no token) = 403. (a) was required by (c): without casbin grants a casbin check would deny everyone.
- **(b)** Retina inserts `retina_action_plan_approval.oracle.sql` (db worktree, also in the Google-Doc draft item 4): 161–163 → PO, Super Admin; 162–163 → SDA1, SDA2. The R3 team substitutes the existing ACLIDs.
- **(c)** casbin grants removed from `seed_action_plan_approval.sql`; group 30 + permissions 161–163 rows stay (names for `/users/permissions`).
- **PO notification pool = active users of Production Operations** (Retina cannot list who holds a privilege).
- Dev testing: the mock users need the SEQs in `mock_auth_sessions` (see `ApprovalManualTest.md` §0.2).

## PHI-2442 (G14) — decided 2026-11-06 (grill)
- **Q1 (b):** the well's action plan list shows **every submitted plan**; each item has `approval_status` and `progress` = `routing` while waiting_review / modify_in_approval / modify_returned / reject_in_approval, else the existing date status (on_schedule / upcoming / overdue / done). A rejected plan keeps its date status. `approval_status=a|b` still narrows. "Active = approved" stays in alerts, widgets, uniqueness / overlap.
- **Q2 (a):** no per-person filter: whoever holds view 153 / 155 sees the plans; the PRD list names who must be able to see.
- **Q3 separate:** detail `can_review` (161, waiting_review / modify_returned), `can_approve` (pending level + 162), `can_reject` (pending level + 163), and `approval { cycle_no, path, current_level, total_levels }`. Same rules as the endpoints.
- Built (staged, PHI-2243 worktree): my-task / my-approval / badge sections `action_plan_review` / `action_plan_approval`; alerts + well widgets + well panel count only approved (or no-status) plans.

## WHC fields G1–G3 — decided 2026-11-06 (grill), built in PHI-2242 worktree (staged)
Applies to `method = well_head_compressor` + `activity_type = installation`, **schedule and update** (`ActionPlanWhc.Normalize`, PEP + PHSS, on submit and on a PO Modify proposal):
- `whc_type` required mobile | permanent; `compression_type` required 1 | 0.5; `owned_by` required rental | owned (wrong / missing → 400).
- `contract_number` kept only with rental, `asset_number` only with owned — the other is **dropped** (no 400). `cost_allocation` optional free text.
- `pressure` **dropped** (hidden for WHC, no 400).
- `production`: 0 ≤ production ≤ compression_type, missing = 0, else 400.
- Other method / activity: WHC fields cleared, no WHC checks. Fields stored on the AL row (PHSS: live row), returned on detail, in the Modify snapshot / diff, modifiable (PRD 2245).
