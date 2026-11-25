# Work Order: what changes on `projects` / `project_tasks`

20 Nov 2026. Question: when a WO creates a **Project** and its **Project Tasks**, what must change? The schedule still needs tasks, and the tasks must still connect to **Contract, BOQ and SPK**.

**Updated 24 Nov:** the department sets the schedule type (simple: WLI, Field PHSS, Field PEP RAM, Field PEP PE, PO Zona, Drilling; detail: Project, OSF). Level 2 = the assigned department (after a Transfer). The project approver comes from a permission in the PIC's department. See `00-Decision-Log.md` (TD4, TD5, TD10, TD11, TD16).

**Decision, 20 Nov:** a WO project needs **no `.mpp`**. Both kinds, `detail` (PRJ / OSF) and `simple`, build their schedule in the app (grid or Excel upload). They write the same `project_tasks` rows. `.mpp` / Aspose stays only for projects made outside a WO.

**Short answer:** almost nothing on `project_tasks` itself.
- The table already has every link that Contract, BOQ and SPK need.
- The work is in **how the in-app schedule (grid / Excel) writes the rows**, so they look exactly like `.mpp` rows. It is not in new columns.
- The only schema changes are on `projects`:
  - the WO link,
  - the schedule kind,
  - possibly the K6 Action Plan link.

---

## 1. How a task connects today (verified in code)
- **Task → Project:** `project_tasks.project_id`. It is **required**, so a task cannot exist without a project. All links are logical, with no DB FK.
- **Task → Contract:** `project_tasks.contract_id`. It is set when a BOQ is connected (`ProjectTaskBoqsService.cs:685`) or an SPK BOQ is assigned (`SpksService.cs:2804`), and cleared on unassign.
- **Task → SPK:**
  - **legacy:** one SPK per task, in `project_tasks.spk_id`, `spk_cost`, `spk_type`.
  - **current:** `project_task_spks` (task ↔ SPK, `is_primary`, `spk_cost`, unassign audit, `source`), which supports several SPKs per task (multi-source SPK).
  - **Create SPK:** the request carries `ProjectTaskIds` (`SpksDto.cs:244`).
- **Task → BOQ:**
  - `project_task_boqs`: BOQ lines per task (unit, volume, price, `spk_boq_id`, `spk_id`, progress).
  - `project_task_boq_drafts`: per task + contract (+ SPK).
  - `spk_boqs` → `project_task_boqs`.
- **Task → plan / S-curve:** `project_task_schedules` holds one row per day with plan / actual weight, cost and progress.
- **Rules the SPK / BOQ / weight code relies on:**
  - `data_type` is `header` (summary row) or `item` (leaf).
    - Weight and cost totals count **items only** (`ProjectTaskSpkMirror.cs:184`).
    - SPK / BOQ attach to **items**.
  - `weight` = `estimated_cost / Σ item estimated_cost`. If the total cost is 0, the import weights stay unchanged.
  - `breakdown` is the WBS code (`1`, `1.2`). Roll-ups match by prefix (`'1.2' + '.%'`), so it must be trimmed.
  - `unique_id` / `parent_unique_id` give the tree. `predecessor` / `successor` are JSON `[{id, uniqueID, type, lag}]`, the MS Project shape.
  - **On Stream** is found by `description = "On Stream"`. Plan On Stream = that task's `end_date`, and Expected = its `etc` (`ProjectsService.cs:4430`, PHI-2267).
- **Two ways a task is made today:**
  - **`.mpp` import** (Aspose parse → `ProjectTasksService.cs:844`): full fields, predecessor JSON, calendar, critical path.
  - **Manual add task** (`ProjectTasksService.cs:652`): one row, with header / item from the breakdown, `duration = end − start + 1`, daily schedules built evenly (`BuildDailySchedules`), and `predecessor = "[]"`.

The **simple schedule** can reuse the manual path, with some fixes (§3).

---

## 2. Changes on `projects`
| Column | Type | Why |
|---|---|---|
| `work_order_id` | uniqueidentifier, null | Already in the Knowledge Documents (MoM 6 Nov). **Not unique**: K15 / MoM 19 Nov allows several schedules (projects) per WO, and "Finish WO finishes all schedules under it" |
| `schedule_kind` | nvarchar(10): `detail` / `simple` | Both kinds use the in-app grid (no `.mpp`). The kind decides the grid's rules (levels / fields, P10). Copy it from the WO **department** (Request To): detail = Project, OSF; simple = all other departments (24 Nov) |
| `source` | nvarchar(20): `manual` / `work_order` (optional) | Reporting and filters ("projects from WO"). Can be derived from `work_order_id`; add it only if a list needs it |

- Unchanged:
  - RKAP (`rkap_projects`), WBS, budget type, approval and PICs: the WO fills them as today's project form does.
  - Project Approval (`approval_processes`): this is the second approval for the project path.

---

## 3. Changes in how in-app schedule rows (simple **and** detail) are written to `project_tasks`
No new column is needed. These rules make a grid / Excel row equal to an `.mpp` row, so Contract / BOQ / SPK, the S-curve, Gantt and On Stream all work unchanged.

| Field | Rule for the simple schedule | Today's gap |
|---|---|---|
| `breakdown` | `1`, `1.1`, `1.2`, `2`… from the grid's No column; trimmed | – |
| `unique_id` / `parent_unique_id` | The backend assigns 1..n in row order. A sub-task points to its parent | The manual path takes `UniqueId` from the request and does not set `parent_unique_id` |
| `data_type` | A row with sub-tasks = `header`; a row without = `item`. Only items can get an SPK / BOQ | Same rule as today ✔ |
| `predecessor` / `successor` | Parse the grid text (`2`, `2FS+3d`, `3SS`, `4FF-1d`) into the JSON `[{id, uniqueID, type, lag}]` that `.mpp` writes. Build `successor` as the inverse. Keep the typed text in `other.predecessor_text` for editing | The manual path writes `"[]"`, so the Gantt shows no links |
| `start_date` / `end_date` / `duration` | Manual dates (Knowledge Documents). Duration in **working days, Mon–Fri** + holidays (`custom_configurations` "calendars.holiday") | `BuildDailySchedules` spreads over **every calendar day** (weekends included). Decide which (P2) |
| `start_etc` / `etc` | = planned dates at create (as today) | ✔ |
| `estimated_cost` | Grid Cost (Rp). Percentage is shown and derived from the WO budget, and **not stored** (MoM 19 Nov: cost ↔ % auto-fill). Σ item cost ≤ WO estimation cost (K14) | – |
| `weight` | Recompute with the existing rule (`estimated_cost / Σ item cost`) after all rows are inserted | Manual path takes weight from the request; call the existing `RecalculateProjectTaskWeightsAsync` instead |
| `project_task_schedules` | Build per item from duration, weight and cost (existing `BuildDailySchedules`), after the weight recompute | Schedules use the request weight; rebuild after the recompute |
| `milestone` | `1` for the **On Stream** row (0 duration, last row, required) | – |
| `description` | Grid Task name. The last row must be exactly **"On Stream"**, so Plan / Expected On Stream work (PHI-2267) | – |
| `contract_id`, `spk_id`, SPK / BOQ tables | **Empty at create.** They are filled later by the existing Add SPK / connect BOQ flows, the same as an `.mpp` project | ✔ no change |
| `project_calendar`, `critical_path`, `constraint_*` | `"{}"` / empty (no Aspose); `is_critical_path = false` | ✔ (no critical path from Aspose for any WO project; see P4) |
| `tenant_id`, `status` | As today (`not_started`) | ✔ |

**Where to build it:** one service method, "create tasks from rows". The grid and the Excel upload both call it. It inserts everything in **one transaction**, then recomputes the weights, then builds the schedules. Re-use the manual-add logic; don't add a new path for each source.

---

## 4. The K6 problem: Action Plan without a Project
- The Figma's PE / PO well lanes say "New **Action** Process – Simple Schedule". In K6 we proposed that well categories create **no Project**.
- **But** `project_tasks.project_id` is required, and every Contract / BOQ / SPK flow, the S-curve, `spk_cost_allocations → projects` and service acceptance → projects all hang off a **Project**.
- Without a project, a well WO's schedule could not get an SPK or a contract. Fixing that means changing the SPK, BOQ, progress, SA and invoice services.
- **Decided 20 Nov:** a well WO **also creates a Project** with `schedule_kind = simple`, linked to both the WO and the Action Plan.
  - **Link:** add `projects.action_plan_id` + `action_plan_source` (pep / phss), or keep the link only through the WO (D1: the WO is the Action Plan's parent; the WO has the project).
  - **Approval:** the second (project) approval can be **skipped** by configuration for Action Plan WOs. That keeps "one approval only" for Action Plans.
  - **Why this is better:** the PIC still gets tasks, contract, BOQ and SPK, and the Action Plan status follows the project (On Going → Finished).
- Prefer the **WO link only**: there is no new column, the Action Plan is reached through `work_orders`, and there is a single source of truth.

---

## 5. Things that do not work for simple projects yet
- **Rebaseline:** today it is an `.mpp` re-upload + diff (`project_rebaselines`). Every WO project (simple and detail) needs "edit the grid / re-upload the Excel → the same diff engine". The reconcile works on task rows, so only the input changes.
- **Add / edit / delete task after create:** the manual endpoints exist. Check that they also rebuild the predecessor JSON and weights for simple projects.
- **Excel template:** the columns match the grid (No, Task, Start, End, Predecessor, Cost). The same validation as the grid applies (row errors, On Stream last).

---

## 6. Open questions
- **P1:** ~~a Project for well categories, with the project approval skipped for Action Plan WOs?~~ **Decided 20 Nov: yes.**
- **P2:** simple-schedule duration and the daily plan: Mon–Fri working days (Knowledge Documents) or every calendar day (today's `BuildDailySchedules`)? The S-curve differs.
- **P3:** must every **item** row have a cost, or can some be 0? This matters for the weight: if all are 0, the weights stay unchanged and the S-curve is flat.
- **P4:** WO projects have no critical path and no calendar from Aspose. Is that acceptable, or should the critical path be computed from the predecessors?
- **P5:** ~~convert simple → detail via `.mpp`~~ **Closed 20 Nov:** WO projects never use `.mpp`.

---

## 7. Changes in the Project module (lifecycle)
Today's lifecycle (verified, `ProjectsService.cs`, `ProjectsEndpoint.cs`):
- **Create:** `POST /projects` creates a `draft`.
- **Tasks:** `.mpp` validate → `POST /projects/tasks/validate/confirm`, or manual `POST /projects/tasks/create`.
- **Approvers:** `POST /projects/{id}/approver`. The user picks the approvers per level by hand (`project_approvers`).
- **Submit:** `POST /projects/submit` → `on hold` + `approval_processes` (flow "Project").
- **Approve:** `POST /projects/approval`, level by level → `in progress`.
- **Finish:** `POST /projects/finish` (note required; only from `in progress`) → `finished`. The reverse is `/projects/reopen`.
- **Cancel:** `POST /projects/cancel` → `canceled`.

### 7.1 Create from a WO
- **New entry point:** "Create Project" from the WO (Disposition PIC, WO status Project Preparation).
  - It opens the project form **pre-filled from the WO**:
    - description ← WO title / scope,
    - field / area / plant / working area ← WO location,
    - start / end ← WO dates,
    - WBS ← WO WBS,
    - RKAP ← WO RKAP,
    - budget type ← WO budget type,
    - Project Type ← Disposition Work Type. The allowed Work Types depend on the department (24 Nov): ABI/BD only Projects and PO; ABI/NBD only OSF; ABO Routine and ABO Non Routine for all departments,
    - `work_order_id`,
    - `schedule_kind` ← the WO department (Request To), 24 Nov.
  - The PIC can edit the pre-filled values.
- **Mapping to set up:**
  - WO **category** → project `category` / `sub_category` (Figma class: Budget Type → Project Category → Class, e.g. ABI BD → NWD → RTWS = `newwelldevelopment` / RTWS).
  - WO **budget type** (ABI BD / ABI NBD / ABO Routine / ABO Non Routine) → `rkap_type`.
  - Store the mapping in the category config (K12). It must not be typed by hand.
- **Project No:** the Knowledge Documents / prototype use the WO number when the PIC leaves it empty (`p.no || wo.no`). Confirm (P6).

### 7.2 Submit validation (`ValidateReadyToSubmitAsync`)
The existing rules block a WO project:
- **WBS required:** the MoM 19 Nov says **WBS is optional** for a WO. Skip this rule when `work_order_id` is set.
- **Project number required:** satisfied by the WO number fallback.
- **At least one task:** keep it. For simple, also require the **On Stream** row last, and the cost cap (K14).
- **RKAP / field / working area / dates:** keep them (RKAP is mandatory in the MoM).

### 7.3 Project approval (second approval)
- **Today:** the approvers are **picked by hand** per project.
- **WO (Knowledge Documents WO-7.3):** the approver is the **Manager of the PIC's Level**: Layer 2 Level 1 (target department), or Layer 2 Level 2 (assigned department) after a Transfer.
- **Change (24 Nov):** for a WO project, the approvers = the users who have the Layer 2 permission **in the PIC's department** (the route of that department, `07` §2). The system lists them with `/users/by-permission/{id}` and a department filter. The backend does not check the permission on Approve. Hide the manual approver edit, or keep it as an override (P7).
- **Action Plan WOs:** the project approval is skipped (decided 20 Nov). On Submit the project goes straight to `in progress`, with the log "auto-approved (Action Plan WO)".
- **Reject / Revise:** the existing "Revise" sends the project back to the PIC (prototype: "The PIC has to adjust the project and send it again"). No change, but the WO status must follow (7.5).

### 7.4 Finish (D7: parameters required)
- **Today:** Finish needs only a note.
- **Change:** when `work_order_id` is set, Finish:
  1. Opens the **WO parameter pop-up** (the category's Finish fields, K11), with the cost cards: Budget, Actual, Commitment, EAC, RKAP.
  2. **Requires** those parameters and saves them to `work_order_results`.
  3. Notifies the Requestor ("parameter updated & WO completed", MoM 6 Nov).
  4. Updates the WO:
     - **Simple / well categories:** the WO waits for the Requestor's well update. This is non-blocking if X9 = close at Finish.
     - **Several projects per WO (K15):** the WO completes when **all** its projects are finished. Or, per the MoM, "Finish WO" finishes every open schedule. Decide which side drives (P8).
- **Reopen:** reopening a WO project reopens the WO, which goes back to On Going. The saved parameters stay, as history.
- **Cancel:** cancelling the **only** project of a WO sends the WO back to Project Preparation, so the PIC can create a new one. It does not cancel the WO.

### 7.5 WO status follows the project
| Project event | WO status |
|---|---|
| created (draft) | Project Preparation |
| submitted (`on hold`, approval active) | Project Approval |
| approved (`in progress`) / auto-approved | On Going |
| revised / rejected back to PIC | Project Preparation |
| finished (+ parameters) | Completed, or waiting for the requestor update (X9) |
| reopened | On Going |
| canceled | Project Preparation |

- **How:** one place updates the WO when the project status changes, e.g. a `WorkOrderProjectSync` called from Submit / Approval / Finish / Reopen / Cancel. Don't spread it over the endpoints.
- **Notification:** project events reach the WO participants with the CTA "Go to Project" (prototype `ntp`).

### 7.6 Screens
- **Project Details:** add a **WO Number** field (link to the WO; MoM 6 Nov).
- **Project list / Approval Summary:** a filter "From Work Order", and the schedule kind.
- **Schedule tab:**
  - `detail` → the same grid editor with the detail rules (P10). No `.mpp` upload button for WO projects.
  - `simple` → the grid editor (§3).
  - Both kinds use a grid-based rebaseline (§5).
- **SPK / Contract / BOQ screens:** no change (§1). They work on the tasks as today.

### 7.7 More open questions
- **P6:** Project No for a WO project: the WO number, or still a typed number (AFE)?
- **P7:** project approvers from the route only, or can the PIC / manager still edit them?
- **P8:** several projects per WO: does the WO complete when all its projects are finished, or does "Finish WO" force-finish them (MoM 19 Nov)?
- **P10:** with no `.mpp`, what makes **detail** different from **simple**? Proposal: detail = unlimited WBS levels and manual weight; simple = 2 levels, weight from cost.
- **P9:** does the WO budget (estimation cost) cap the **sum** of all its projects' costs, or each project separately?

---

## 8. Flag "from WO" vs "outside WO", and the NOT NULL check
Checked 20 Nov:
- the **dev DB** (`sys.columns`, read-only),
- the **EF model** (`PhantomDb.Project.cs`, `PhantomDb.ProjectTask.cs`; DataAccess has `<Nullable>enable</Nullable>`, so a non-nullable C# type without `IsRequired(false)` is **required** in EF),
- the **code that assumes a value** (submit validation, weight, roll-up, On Stream).

### 8.1 The flag (new columns on `projects`)
| Column | Type | Rule |
|---|---|---|
| `origin` | nvarchar(20) **NOT NULL** default `'manual'` | `manual` = made in Project Monitoring (outside WO); `work_order` = made from a WO. Backfill: all 1,297 existing rows = `manual` |
| `work_order_id` | uniqueidentifier NULL + index | Set only when `origin = 'work_order'`. CHECK: `origin = 'work_order'` ⇔ `work_order_id IS NOT NULL`. Not unique (K15) |
| `schedule_source` | nvarchar(10) **NOT NULL** default `'mpp'` | `mpp` (Aspose import, outside WO) / `in_app` (grid / Excel). Every WO project = `in_app` (20 Nov decision) |
| `schedule_kind` | nvarchar(10) NULL | `detail` / `simple`. Only for WO projects (null for `manual`) |

- An explicit `origin` makes filters, lists and reports easy, and the CHECK keeps it consistent with `work_order_id`.
- `schedule_source` is separate from `origin` because the screens and the rebaseline branch on **how the tasks were made**, not on where the project came from.

### 8.2 `projects`: NOT NULL columns
**The DB has only 2 NOT NULL columns:** `id` (default `newid()`) and `created_at`. Everything else is nullable. The risk is in **EF** and in **code that expects a value**.

| Column | DB | EF | Can it be null from a WO? | Action |
|---|---|---|---|---|
| `id` | NOT NULL (default) | – | No | – |
| `created_at` | NOT NULL | required | No | Set at create |
| `status` | null | **required** (`string = null!`) | No if we set `draft` (5 dev rows are already null) | Always set `draft` at create |
| `created_by` | null | **required** (Guid) | **Yes**, if the project is created by the system (auto-create from Disposition) | Use the PIC's user id. Never a system create without an actor |
| `wbs` | null | – | **Yes**: the MoM 19 Nov says WBS is optional | Submit validation requires it today, so skip that rule for `origin = work_order` |
| `project_no` | null | – | **Yes**, if the PIC leaves it empty | Fall back to the WO number (P6); otherwise submit fails |
| `category` | null | – | **Yes**: dev values are only `fasprod`, `newwelldevelopment`, `flowline` ("New Well Development" also exists, a dirty duplicate). OSF / WLI / PHSS / PEP / PO categories have **no project category** | Add project categories, or map each WO category to one (K12). Submit requires it |
| `sub_category` | null | – | Yes | Optional; map from the Figma class (RTWS, Gas Lift…) |
| `rkap_type` | null | – | **Yes**: dev values are `CO` / `UB` / `CF`, **not** the WO budget type (ABI BD / ABI NBD / ABO R / ABO NR) | Different meaning. Add `budget_type` (new column) for the WO budget type; keep `rkap_type` as is |
| `field_id` | null | – | **Yes**: the WO Field is "PHSS Northern / PHSS Southern" (G11). Is that a row in `fields`? | Map the WO field to `fields.id`, or the submit rule "field is required" fails |
| `area_id`, `plant_id` | null | – | Yes ("Area follows Field"; plant may be empty) | Optional; working area is still required at submit |
| `start_date`, `end_date` | null | – | No (WO has start / end) | Pre-fill from the WO |
| `description` | null | – | No (WO title / scope) | Pre-fill |
| `department_id` | null | – | Possible | Set from the PIC's department: the target department (Level 1) or the assigned department (Level 2) |
| `rig_id`, `rig_name`, `fid`, `zone`, `potential_gain_*`, `budget_forecast` | null | – | Yes | Fine: NWD / optional fields |

### 8.3 `project_tasks`: NOT NULL columns
**DB NOT NULL:** `id`, `project_id`, `weight`, `start_date`, `end_date`, `created_at`, `created_by`, `unique_id`, `milestone`, `duration`, `is_critical_path`.

| Column | DB | EF | Can it be null from a WO (in-app grid / Excel)? | Action |
|---|---|---|---|---|
| `project_id` | NOT NULL | required | **Yes**, if a well WO saves an Action Plan schedule without a project (K6) | Always create the project first (P1). Tasks are inserted with it |
| `unique_id` | NOT NULL | required | **Yes**: no `.mpp` gives it any more | The backend assigns `MAX(unique_id)+1` per project. The manual-add endpoint today takes it from the request; don't trust the client |
| `start_date`, `end_date` | NOT NULL | required | **Yes** for **parent rows** (dates roll up from sub-tasks) and for **incomplete rows** while the PIC is still typing | Compute parent dates before insert. Keep a draft grid out of `project_tasks` (in `projects.other` or the WO), and insert only on Submit / Save with a complete row |
| `duration` | NOT NULL | required | Yes for parents / incomplete rows | Compute (working days, P2); parents = span of children; On Stream = 0 |
| `weight` | NOT NULL | required | **Yes**, if cost is empty (MoM 6 Nov: cost not required) | Insert `0`, then recompute from cost. If every cost is 0, the weights stay 0 and the S-curve is flat. Requiring cost (K14 / P3) fixes this |
| `milestone` | NOT NULL | required | No | `0`; `1` for On Stream |
| `is_critical_path` | NOT NULL | required | No | `false` (no Aspose) |
| `created_at`, `created_by` | NOT NULL | required | `created_by` yes if system-created | Use the PIC's id |
| `predecessor`, `successor` | null | **required** (non-null string, no `IsRequired(false)`) | **Yes**: no predecessor typed. 2,110 dev rows are already null | Always write `"[]"` when empty; the parsed JSON otherwise |
| `breakdown` | null | optional | Yes if the No column is empty | **Logically required**: roll-ups match by prefix. The backend generates it from the row order |
| `data_type` | null | optional | Yes if not computed | **Logically required**: weight / SPK use header vs item. Compute it (has children → header) |
| `description` | null | optional | Yes (empty task name) | Require a name; the last row must be "On Stream" |
| `status` | null | optional | Yes | Set `not_started` |
| `parent_unique_id` | null | – | Yes, for top rows (normal) | Set for sub-tasks; null only for top level (3,699 dev rows null = top rows) |
| `estimated_cost` | null | – | Yes (2,093 dev rows null) | Weight treats null as 0. Fine if K14 = optional, but the S-curve suffers |
| `contract_id`, `spk_id`, `spk_cost`, `spk_type`, `assignee` | null | – | Yes at create (normal) | Filled later by SPK / BOQ (§1) |
| `etc`, `start_etc` | null | optional | No | = planned dates at create |
| `project_calendar`, `critical_path*`, `constraint_*`, `ts` | null | optional | Yes (no Aspose) | `"{}"` / `""` as the manual path does |
| `tenant_id` | null | optional | No | Same hardcoded tenant as today |

### 8.4 Summary
- **Must handle, or the insert fails (DB NOT NULL):** `unique_id`, `start_date` / `end_date` / `duration` of parent and incomplete rows, `weight`, `created_by` and `project_id` on `project_tasks`.
- **Must handle, or EF / reads break (EF-required, DB nullable):**
  - `projects.status`, `projects.created_by`,
  - `project_tasks.predecessor` / `successor`.
- **Must handle, or the WO project can't be submitted (submit rules):** `wbs` (optional for WO), `project_no`, `category` (no project category for most WO categories), `field_id` (does the WO field map?), RKAP, working area.
- **New mapping / columns needed:**
  - `budget_type` (WO budget type ≠ `rkap_type`),
  - WO category → project category,
  - WO field → `fields.id`.
