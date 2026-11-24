# Action Plan Approval — Current Plan (2026-11-06)

_This section is the live plan. Everything under "Original plan (2026-11-02)" is history: its Q tags are decided (`PRD-Gaps.md`), its 161 / casbin / counter-table details are superseded._

## Where it stands

Phases 1 and 2 done 2026-11-06. Stack #1433, all draft, on `phi-dev` 969e2d96:

| Branch | PR | Tickets |
|---|---|---|
| `feat/phi-2242-action-plan-db` | #1409 | no ticket yet (D1) |
| `feat/phi-2243-action-plan-approval` | #1432 | BE: 2300, 2306, 2309, 2312, 2325, 2340, 2349, 2352, 2357, 2360, 2371, 2374, 2377, 2393, 2413, 2425, 2428, 2446 |
| `feat/phi-2242-action-plan-al-whc` | #1436 | BE: 2297 |
| Bruno `feat/action-plan-approval` | phi-phantom-collections #176 | pushed; 1 file staged (AL WHC submit) |

Tests: 28 baseline failures on #1409 and at the stack top, none new (`Import_RowsOfAWellWaitingForApproval_Fail` also fails on clean `phi-dev`). EF pending-model diff = only the known `permission_groups / TempId` drift.

No separate Well Test branch: PHI-2354's contract_number, type options and Assign to are already in the db branch / #1432.

## Phases (in order)

### 1. Lock the work in
1. Commit the PHI-2243 staged work; commit the WHC work.
2. `gh stack add` the WHC branch; `gh stack rebase --no-trunk` (WHC onto the new PHI-2243 commit).
3. Build, full suite. **Done when:** only the 27 baseline failures.

### 2. Sync with phi-dev
1. `gh stack rebase` onto `origin/phi-dev`; resolve alert / well-panel conflicts if any.
2. Check the snapshot merge: `dotnet ef migrations has-pending-model-changes` must report none. Our migration keeps its earlier timestamp unless this check says otherwise.
3. Build, full suite (re-baseline first: phi-dev may change the 27). `gh stack submit`.
**Done when:** #1409, #1432 and the new PHI-2242 PR are pushed, stacked, no new failures.

### 3. Align the contract and scenarios
**Bruno:**
- Review / Approve / Reject: response keys (`action_plan_id`, `current_level`, `total_levels`), error `code` "01", `execution_*` on approve and modify, remarks rules, WO issued at submit.
- `folder.yml`: not "PROPOSED"; trigger with "installation"; permissions 161 / 162 / 163; PO pool = PO department.
- List: `progress`, every plan shown. Detail: `can_review`, `can_approve`, `can_reject`, `approval`, WHC fields. My Task: `well_test_action`, `activity_type`, `assigned_department`. Approval route prefill: new request.
- Need-action: per D2.

**`ApprovalManualTest.md`:** S3.5 is stale (list now shows all plans); add My Task, `progress`, `can_*`, widgets, WHC scenarios; remove them from "Not in this build".

**Done when:** every Bruno example matches a real response.

### 4. Test on dev
1. Apply the migration + seeds on dev (shared DB, needs the user's go).
2. Add 161–163 to the mock sessions (`ApprovalManualTest.md` §0.2), check `GET /users/permissions`.
3. Run every scenario; fix what fails.
4. Paste the DDL / DML entry into the "Approval Route Action Plan" tab of the DDL doc (`approval-route-action-plan.md`): no connector can write to a tab.

**Done when:** all scenarios pass on dev.

### 5. Release
1. Jira: database ticket (D1), move BE tickets to Dev In Progress, link PRs.
2. User: add 161–163 (and 159, 160) to the RBAC sheet.
3. R3 team: run `retina_action_plan_approval.oracle.sql` before the feature is used; until then review / approve / reject return 403.
4. `gh pr ready`, review, merge bottom-up: #1409 → #1432 → PHI-2242.

## Open decisions

| # | Decision | Owner | Recommendation | Blocks |
|---|---|---|---|---|
| D1 | Ticket for the db work (#1409); PHI-XXXX does not exist in Jira | User | New ticket from `Ticket-Database.md` | Phase 5 |
| D2 | Need-action `routing` block (in Bruno, not built, not in the PRD) | User | Remove from Bruno; `current_level_*` stays | Phase 3 |
| D3 | `assigned_department` allowed values (PRD: P&O Zona 9; Project Zona 9 out of sprint 2) | User | No backend list; the FE dropdown owns it | — |
| D4 | Card "PIC Assignment" says a PIC SSDP assigned, but SSDP picks only a department | PM | Show the department until clarified | — |
| D5 | In-approval label: "Modified" / "On Process Approval – TBC" / "Routing" | PM | "Routing" (PHI-2442); API value `routing` | — |
| D6 | PO options Field Tanjung, Field PHSS, WI have no users, so an empty PIC list | PM / data | Add the users, or hide the options | Dev test of those options |
| D7 | MoM 26 Okt "end state success di halaman detail well" | PM | Clarify scope; likely FE | — |

---

# Original plan (2026-11-02)

# Action Plan Approval — Worktree Plan

_Created 2026-11-02. Context: `Approval.md` (design), `PRD-Gaps.md` (gaps + Q1–Q8), `ApprovalFlow.md`._

Q1–Q8 in `PRD-Gaps.md` are still open. This plan uses the **recommended answers** (➡️). Each place that depends on one is tagged `[Qn]`. If an answer changes, only the tagged items move.

## Worktrees & stacking

| # | Worktree (`.worktrees/…`) | Branch | Base | Owns |
|---|---|---|---|---|
| 2 | `phi-XXXX-ap-db` | `feat/phi-XXXX-action-plan-db` | `phi-dev` | **All** schema: entities, EF config, the single migration, seeds |
| 1 | `phi-2243-ap-approval` | `feat/phi-2243-action-plan-approval` | `feat/phi-XXXX-action-plan-db` | Approval engine, WO number, notifications, inbox / my-task, list/detail approval fields |
| 3 | `phi-2242-ap-al-whc` | `feat/phi-2242-action-plan-al-whc` | `feat/phi-2243-action-plan-approval` | AL WHC form, rules, validation, modify payload |
| 4 | `phi-2354-ap-well-test` | `feat/phi-2354-action-plan-well-test` | `feat/phi-2243-action-plan-approval` | WT form changes, validation, modify payload |

```
phi-dev
  └─ feat/phi-XXXX-action-plan-db              (2 · database)
       └─ feat/phi-2243-action-plan-approval   (1 · approval)
            ├─ feat/phi-2242-action-plan-al-whc     (3 · artificial lift)
            └─ feat/phi-2354-action-plan-well-test  (4 · well test)
```

### Ticket coverage

The prefix is the **lead ticket** of each worktree. The PR description lists every ticket it covers. The database worktree gets its own ticket (draft in `Ticket-Database.md`; number pending).

| Worktree | Prefix | Tickets covered (NID 131 = AL, NID 239 = WT) |
|---|---|---|
| Database | PHI-XXXX (own ticket, pending) | Schema for all tickets below. Spec: `Ticket-Database.md` |
| Approval | PHI-2243 | AL: 2243 approve · 2245 modify · 2246 modify-approve PO Mgr · 2247 modify-approve SSDP · 2251 modify-reject PO Mgr · 2256 modify-reject SSDP · 2259 reject · 2260 route config. WT: 2355 approve · 2363 modify · 2364 · 2365 · 2384 · 2401 · 2419 reject · 2420 route config. Plus PHI-2442 (status/detail table) |
| AL WHC | PHI-2242 | 2242 SSDP request AL (WHC form). The AL hook for 2245 (modify fields) |
| Well Test | PHI-2354 | 2354 SSDP request WT. The WT hook for 2363 (modify fields) |

**Why the database branch is the base:**
- Every EF migration rewrites `PhantomDbModelSnapshot.cs`. Two worktrees adding migrations always conflict there, and every migration also sweeps the known `permission_groups/TempId` drift. So **only `phi-XXXX-ap-db` adds migrations.**
- Worktrees 3 and 4 are siblings. They touch different child tables and validators, so they can run in parallel once approval is ready.
- If AL or WT needs another column later: add it in `phi-XXXX-ap-db`, then rebase the stack. Don't add a migration in 3 or 4.

**Rules for all four worktrees:**
- Create them under `.worktrees/`.
- Build with `--configfile` mapping the NuGet feed to the main checkout.
- Copy `src-be/WebApi/appsettings.json` in (it's gitignored).
- Stage only; the user commits.
- No `dotnet build/test` unless the user asks.

---

## 2 · Database (`phi-XXXX-ap-db`) · PHI-XXXX (own ticket, see `Ticket-Database.md`): start here

**Goal:** all tables and columns exist, and seeds are ready. No business logic.

### 2.1 Approval tables (from `Approval.md` §Kamus data)

New tables:
- `action_plan_approval_cycles`
- `action_plan_modifications`
- `action_plan_approvers`
- `action_plan_approver_slas`
- `work_order_sequences`

New columns on `pep_action_plans` and `phss_action_plans`:
- `department_id`, `requires_approval`, `approval_status`, `current_cycle_id`
- `approved_at/by`, `rejected_at/by`
- `work_order_number` (filtered unique)
- Index `(approval_status, department_id) WHERE deleted_at IS NULL`

### 2.2 Gap columns (from `PRD-Gaps.md` §B)

| Table | Columns | Tag |
|---|---|---|
| `pep_/phss_action_plans` | `review_department_id` nvarchar(50), `review_pic_id` uniqueidentifier null | [Q5] |
| `pep_/phss_action_plans` | `execution_department_id` nvarchar(50), `execution_pic_id` uniqueidentifier null | [Q6] |
| `pep_/phss_action_plan_artificial_lift` | `whc_type` nvarchar(20), `compression_type` decimal(18,6), `owned_by` nvarchar(20), `contract_number` nvarchar(100), `asset_number` nvarchar(100), `cost_allocation` nvarchar(100) | G1 |
| `pep_/phss_action_plan_well_test` | `contract_number` nvarchar(100) (free text; keep `contract_id` for old data) | PHI-2354 |
| `approval_routes.category` → nvarchar(100), `approval_processes.approval_flow` → nvarchar(100) | widen | [Q2] |

### 2.3 Seeds (SQL scripts, DBeaver-safe: literal GUIDs, no `DECLARE`/`GO`)

- `custom_configurations`:
  - `work_order_department_short_names` (`{SDA1 id: "SDA1", SDA2 id: "SDA2"}`)
  - `action_plan_review_permission_id` = 160
  - `action_plan_review_sla_days` = 3
- `custom_configurations` well test type options: Regular / Optimization (PHI-2354).
- `permissions`: insert **161 "Approve Action Plan"** in group 29 (160 and group 29 already exist on dev). Add casbin `p` grants for the PO Manager / SSDP approver roles [Q9].
- `notification_templates`: 7 rows (copy per `PRD-Gaps.md` Q8) [Q8].
- Backfill: submitted plans → `approval_status = approved`, `requires_approval = 0`, `approved_at = submitted_at`, `department_id` from `created_by` (best effort).

### 2.4 Steps

1. Check the dev DB before writing anything: `sys.columns` for `approval_routes.category` / `approval_processes.approval_flow` lengths, `sys.foreign_keys` on `approval_processes.reference_id`.
2. Add the entities and `PhantomDb.*.cs` configs. Set `HasColumnType` explicitly for decimals.
3. Run `dotnet ef migrations add AddActionPlanApproval`, then **strip the drift** (permission_groups / TempId) by hand.
4. Write the seed + backfill SQL in `src-be/DataAccess/Database/`.

**Done when:** the migration only contains the changes above, applies on dev with no errors, and the seeds run cleanly.

---

## 1 · Approval (`phi-2243-ap-approval`) · PHI-2243: after 2

**Goal:** the type-agnostic approval engine, the full state machine from `ApprovalFlow.md`.

| Area | Work | Tag |
|---|---|---|
| Scope rule | `RequiresApproval(plan)`: WT always. AL when method `well_head_compressor` **and** activity `installation` (PHSS: any active row). Frozen at submit | [Q1] |
| WO number | `WorkOrderNumberService`: `UPDLOCK, HOLDLOCK` counter, `{seq:D4}/WO/{short}/{year}`, inside the submit transaction | [Q3][Q4] |
| Submit (PEP + PHSS) | Set `department_id`, `requires_approval`, `approval_status`, WO, `review_department_id/pic` from body. Notify the review pool | [Q5] |
| Review endpoint | `POST /{source}/:id/review` approve / modify / reject. Approve takes `execution_department_id` + `execution_pic_id` (mandatory). Modify stores the snapshots. Reject opens the process | [Q6] |
| Level approve/reject | `POST …/approval/approve`, `…/approval/reject`. Guard `latest_approval_level + 1`. Final modify applies `proposed` to live tables | — |
| Apply proposed | Generic apply plus a **per-type hook**: `IActionPlanTypeHandler` { `ValidateProposed`, `Apply`, `Snapshot` } — AL and WT implement it in 3 and 4. Approval ships with a pass-through for the base fields | — |
| History & diff | `approval-history`, `modification-diff` (diff is generic over the snapshot JSON) | — |
| Inbox / my-task | `approvals/need-action`, `my-task-list`, `my-approval-list`, badge sections `action_plan_review` / `action_plan_approval`. Items include `activity_type` + review PIC name | G11 G12 |
| Notifications | `ApprovalNotifier` branch for `PEP/PHSS Action Plan Modify/Reject` flows. Approved → SSDP. Rejected → SSDP + the deciding PO | [Q8] |
| Existing features | "Active" = `submitted AND approved` in list tabs, overdue/upcoming, uniqueness, overlap, alert/highlight/dashboard | `Approval.md` §Dampak |
| Route category | Category constants per type × path | [Q2] |
| Bruno | Update PR #176 (D4 WO, assign fields, `activity_type` in items) | — |

### 1.1 Permission numbers

Sources:
- RBAC sheet "RBAC IPMS" → tab **Phantom PHI** (https://docs.google.com/spreadsheets/d/1tS4jrHUTiMcIoAoNN-GABhYb0Cy0eLBQLQ9iBY19jcQ). The "New Privilige" column holds the per-area IDs.
- The dev DB `permissions` / `permission_groups` tables (checked 2026-11-02).

**Already in use:**

| ID | Name | Group | Where |
|---|---|---|---|
| 119 / 120 / 121 / 122 | Read / Update / Delete / Create Approval Route | 15 Approval Route | sheet + DB |
| 153 / 154 | Read / Modify PHSS Wells (PHSS action plan read / draft / submit) | 19 | sheet + DB |
| 155 / 156 | Read / Modify PEP Wells (PEP action plan read / draft / submit) | 19 | sheet + DB |
| 157 / 158 | Read / Modify Unit Conversion | 26 | sheet + DB (last row in the sheet) |
| 159 | Read Data Config | 28 Data Config | **DB only**, not in the sheet |
| 160 | Process Action Plan Request | **29 Action Plan** | **DB only**, not in the sheet |

`Approval.md` says "permission group 29 tidak dipakai", but group 29 "Action Plan" already exists and holds 160. Fix that line.

**Proposed mapping for the approval endpoints** (FE-guarded via `/users/permissions`, same as 153–158; backend route enforcement is still deferred):

| Endpoint | Who | Privilege |
|---|---|---|
| `GET approvals/need-action?stage=review`, `POST /{source}/:id/review` | PO reviewer pool | **160** Process Action Plan Request (exists). Also the `action_plan_review_permission_id` config value |
| `GET approvals/need-action?stage=approval`, `POST …/approval/approve`, `POST …/approval/reject` | PO Mgr levels + SSDP approver | **161 Approve Action Plan, group 29** (NEW). Who can act is still limited by `action_plan_approvers` at `latest_approval_level + 1` |
| `GET /{source}/:id/approval-history`, `GET …/modification-diff` | anyone who can read the plan | 153 (PHSS) / 155 (PEP) |
| `POST /{source}/submit` (now issues WO, sets approval status) | SSDP | 154 / 156 (unchanged) |
| Approval routes, categories `Action Plan … Modify/Reject` | Data Config admin | 119–122 (unchanged) |
| `my-task-list`, `my-approval-list`, `my-task-badge` | everyone | existing (no new privilege) |

Why 160 and 161 are not split per area: PO reviews both PEP and PHSS, and approvers are chosen per cycle. So the `:source` route doesn't need `{type}` substitution, which the owner rejected for 153–158 (memory `phss-pep-privileges-fe-guard-decision`).

**To do in this worktree:**
- Seed SQL (in `phi-XXXX-ap-db`): insert 161 into group 29, plus the role grants (PO Manager, SSDP approver roles) in casbin `p` rules.
- If roles come from R3TINA: add the ROLEACL/ACL rows.
- Add rows for 160 and 161 (and 159) to the RBAC sheet. **The user updates the sheet**; I won't write to it.

**Done when:** the full state machine works with a plain plan (no type-specific fields), and tests cover the guard, WO concurrency, and returned → modify/reject loops.

**Risk:** apply-proposed is the riskiest part. Live data must change only at the final approval, in one `SaveChanges` together with the cycle close and the notification staging.

---

## 3 · Artificial Lift WHC (`phi-2242-ap-al-whc`) · PHI-2242: after 1

**Goal:** the PHI-2242 form and the AL hook for approval.

| Work | Source | Tag |
|---|---|---|
| Method `well_head_compressor` accepted in submit/draft (PEP + PHSS), detail + list DTOs | 2242 | open question in `Approval.md` |
| WHC fields in request/detail DTOs: `whc_type` (mobile/permanent), `compression_type` (1 / 0.5), `owned_by` (rental/owned), `contract_number` (rental), `asset_number` (owned), `cost_allocation` | 2242 | G1 |
| Pressure not accepted / hidden for WHC | 2242 | G2 |
| `production ≤ compression_type` → 400 | 2242 | G3 |
| `IActionPlanTypeHandler` for AL: snapshot, validate proposed (activity_type + method locked), apply to the AL row (PHSS: latest row) | 2245 | G4 [Q7] |
| Bruno: AL WHC submit, modify, diff examples. Remove `pressure` from the WHC examples | — | G13 |

**Done when:** a WHC installation submits, goes through review, a modify with new fields shows correctly in the diff, and the final approve writes the AL row.

---

## 4 · Well Test (`phi-2354-ap-well-test`) · PHI-2354: after 1, parallel with 3

**Goal:** the PHI-2354 / PHI-2363 form changes and the WT hook for approval.

| Work | Source |
|---|---|
| `contract_number` free text (optional) replaces the required contract dropdown for SSDP. `contract_id` is still read for old rows | 2354 |
| Well test type = Regular / Optimization (custom config options) | 2354 |
| Assign to (P&O Zona 9) at submit, shared with approval [Q5] | 2354 |
| `IActionPlanTypeHandler` for WT: modifiable = Contract, Well Test Type, Start/End, Assign Dept, Assign PIC, Notes. Locked = WO, Action Type | 2363 |
| Bruno: WT submit, modify, diff examples updated | — |

**Done when:** a WT submits with the new fields, and a modify of type/contract/assignment shows in the diff and is applied at final approve.

---

## Not in this plan

- **PHI-2442 visibility** (PIC well / WO / action plan / approvers can view; non-approvers view-only): needs its own grill round. It probably sits in approval (detail `can_review` / `can_approve`) plus a list filter.
- **Project Zona 9** as an Assign to option: the PRD says it's out of scope for sprint 2.
- **FE work.**

## Luvus tracking

| Luvus task | Ticket | Worktree | Depends on |
|---|---|---|---|
| t203 | PHI-XXXX (database, ticket pending) | `phi-XXXX-ap-db` | — |
| t204 | PHI-2243 (approval) | `phi-2243-ap-approval` | t203 |
| t205 | PHI-2242 (AL WHC) | `phi-2242-ap-al-whc` | t204 |
| t206 | PHI-2354 (well test) | `phi-2354-ap-well-test` | t204 |

Use `luvus task list` to check status. t205 and t206 lease the same `ActionPlanPep/**` and `ActionPlanPhss/**` paths. That's fine across separate worktrees, but a single-checkout lease will serialize them.
