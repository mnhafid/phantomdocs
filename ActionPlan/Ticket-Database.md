# [Well Surveillance] Action Plan Approval — Database Schema

_Jira: **PHI-XXXX** (to be created) · Worktree `.worktrees/phi-XXXX-ap-db` · Branch `feat/phi-XXXX-action-plan-db` · Base `phi-dev`_

## Purpose

Create all tables and columns for Action Plan approval (Well Test + Artificial Lift WHC), PEP and PHSS. **Schema and seeds only, no logic.** This is the base branch: approval (PHI-2243), AL (PHI-2242) and WT (PHI-2354) stack on it. Only this branch adds migrations.

Related: PHI-2242, 2243, 2245–2247, 2251, 2256, 2259, 2260 (AL) · PHI-2354, 2355, 2363–2365, 2384, 2401, 2419, 2420 (WT) · PHI-2442.
Design: `Approval.md` §ERD / §Kamus data. Gaps: `PRD-Gaps.md`.

## New tables (5)

### 1. `action_plan_approval_cycles`: approval journey

One row per PO decision (including auto-approve). Each Modify/Reject cycle gets its own `approval_process`.

| Column | Type | Null | Note |
|---|---|---|---|
| `id` | uniqueidentifier | no | PK, default `newid()` |
| `action_plan_source` | nvarchar(10) | no | `pep` / `phss` |
| `action_plan_id` | uniqueidentifier | no | Plan id (polymorphic, no physical FK) |
| `cycle_no` | int | no | 1..n per plan. **Unique** `(action_plan_source, action_plan_id, cycle_no)` |
| `path` | nvarchar(20) | no | `auto_approve` / `approve` / `modify` / `reject` |
| `previous_cycle_id` | uniqueidentifier | yes | FK → self. The cycle that returned the plan |
| `approval_process_id` | uniqueidentifier | yes | FK → `approval_processes`. Null for auto_approve / approve |
| `decided_by` / `decided_at` | uniqueidentifier / datetime | no | PO (or system for auto) |
| `remarks` | nvarchar(max) | yes | |
| `outcome` | nvarchar(20) | yes | `approved` / `rejected` / `returned`. Null while running |
| `closed_at` / `closed_by` | datetime / uniqueidentifier | yes | |
| `created_at` / `created_by` | datetime / uniqueidentifier | no | audit |

### 2. `action_plan_modifications`: Modify snapshots

1:1 with a `modify` cycle. Live data is not touched until the final approval.

| Column | Type | Null | Note |
|---|---|---|---|
| `id` | uniqueidentifier | no | PK |
| `cycle_id` | uniqueidentifier | no | FK → `action_plan_approval_cycles`, **unique** |
| `original_snapshot` | nvarchar(max) | no | JSON, live data at modify time |
| `proposed_snapshot` | nvarchar(max) | no | JSON, PO proposal (same schema as the submit body) |
| `changed_fields` | nvarchar(max) | no | JSON array of dot paths |
| `applied_at` / `applied_by` | datetime / uniqueidentifier | yes | Set at final approve |
| `created_at` / `created_by` | datetime / uniqueidentifier | no | audit |

### 3. `action_plan_approvers`: approvers per cycle

| Column | Type | Null | Note |
|---|---|---|---|
| `id` | uniqueidentifier | no | PK |
| `cycle_id` | uniqueidentifier | no | FK → cycles |
| `level` | int | no | 1..n |
| `user_id` | uniqueidentifier | no | FK → `users`. Many per level (any-of) |

Index `(cycle_id, level)`. Unique `(cycle_id, user_id)`: one user can't be on two levels.

### 4. `action_plan_approver_slas`: SLA per cycle per level

| Column | Type | Null | Note |
|---|---|---|---|
| `id` | uniqueidentifier | no | PK |
| `cycle_id` | uniqueidentifier | no | FK → cycles. **Unique** `(cycle_id, level)` |
| `level` | int | no | |
| `sla_days` | int | no | Working days. Fallback chain: payload → route template → `approval_sla_default_days` |

### 5. `work_order_sequences`: WO counter

> **Dropped 2026-11-05.** WO numbers follow the SPK pattern instead (next = highest used `NNNN/WO/{short}/{year}` on the plans + 1, `GET …/action-plans/next-wo-number`, submit `wo_number`, filtered unique index on `work_order_number`). The table is not in the migration.

| Column | Type | Null | Note |
|---|---|---|---|
| `department_id` | nvarchar(50) | no | PK part |
| `year` | int | no | PK part |
| `last_seq` | int | no | Last issued number. Read with `UPDLOCK, HOLDLOCK` |
| `updated_at` | datetime | no | |

## Changed tables

### `pep_action_plans` and `phss_action_plans`

| Column | Type | Null | Source |
|---|---|---|---|
| `department_id` | nvarchar(50) | yes | design: submitter's department (SSDP Area) |
| `requires_approval` | bit | no, default 0 | design |
| `approval_status` | nvarchar(30) | yes | design: `waiting_review` / `modify_in_approval` / `modify_returned` / `reject_in_approval` / `approved` / `rejected` |
| `current_cycle_id` | uniqueidentifier | yes | design: FK → cycles |
| `approved_at` / `approved_by` | datetime / uniqueidentifier | yes | design |
| `rejected_at` / `rejected_by` | datetime / uniqueidentifier | yes | design |
| `work_order_number` | nvarchar(100) | yes | design. Filtered unique `WHERE work_order_number IS NOT NULL` |
| `review_department_id` | nvarchar(50) | yes | **gap G6 [Q5]**: SSDP "Assign to" (PO department) |
| `review_pic_id` | uniqueidentifier | yes | **gap G6 [Q5]** |
| `execution_department_id` | nvarchar(50) | yes | **gap G7 [Q6]**: PO assigns the executing department |
| `execution_pic_id` | uniqueidentifier | yes | **gap G7 [Q6]** |

Index `(approval_status, department_id) WHERE deleted_at IS NULL`.

### `pep_action_plan_artificial_lift` and `phss_action_plan_artificial_lift` (gap G1)

| Column | Type | Null |
|---|---|---|
| `whc_type` | nvarchar(20) | yes (`mobile` / `permanent`) |
| `compression_type` | decimal(18,6) | yes (1.0 / 0.5) |
| `owned_by` | nvarchar(20) | yes (`rental` / `owned`) |
| `contract_number` | nvarchar(100) | yes |
| `asset_number` | nvarchar(100) | yes |
| `cost_allocation` | nvarchar(100) | yes |

### `pep_action_plan_well_test` and `phss_action_plan_well_test` (PHI-2354)

| Column | Type | Null |
|---|---|---|
| `contract_number` | nvarchar(100) | yes. Free text; `contract_id` kept for old rows |

### Existing approval engine [Q2]

| Column | Now (EF) | Change |
|---|---|---|
| `approval_routes.category` | nvarchar(20) | → nvarchar(100), **or** use short codes |
| `approval_processes.approval_flow` | nvarchar(30) | → nvarchar(100), **or** use short codes |

## Seeds (SQL, DBeaver-safe: literal GUIDs, no `DECLARE` / `GO`)

- `custom_configurations`:
  - `work_order_department_short_names`
  - `action_plan_review_permission_id` = 160
  - `action_plan_review_sla_days` = 3
  - well test types Regular / Optimization
- `permissions`: **161 "Approve Action Plan"**, group 29 (160 and group 29 already exist on dev) + casbin `p` grants [Q9].
- `notification_templates`: 7 rows [Q8].
- Backfill: submitted plans → `approval_status = approved`, `requires_approval = 0`, `approved_at = submitted_at`, `department_id` from `created_by`. No cycle rows for old plans.

## Acceptance criteria

- [ ] Checked the dev DB first: `sys.columns` (category / approval_flow lengths), `sys.foreign_keys` (`approval_processes.reference_id` → projects?).
- [ ] Entities + `PhantomDb.*.cs` configs. Decimals use explicit `HasColumnType`.
- [ ] One migration `AddActionPlanApproval`; permission_groups / TempId drift stripped by hand. Up and Down both clean.
- [ ] Seed + backfill SQL in `src-be/DataAccess/Database/`, safe to re-run.
- [ ] Migration applies on dev; seeds run with no errors.
- [ ] No business logic, no endpoints.

## Blocked by decisions

Q2 (widen vs short codes), Q5 / Q6 (assign columns), Q8 (template copy), Q9 (permission 161). See `PRD-Gaps.md`. The 5 new tables and the design columns are **not** blocked.
