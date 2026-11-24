
## Decision 18 November 2026 (latest): SSDP is the last route level (Design A)

Supersedes the "SSDP final review" parts below (`waiting_ssdp_review`, creator-only SSDP, `ssdp/approve`, `ssdp/modify`).

- **Modify round:** Manager 1 → Manager 2 → SSDP. SSDP approves (`approval/approve`, last level: proposal applied →
  `approved`) or rejects (`approval/reject` → `waiting_review`, proposal dropped). **SSDP = the plan's creator only**, appended
  by the backend as the last level when the PO submits the Modify (refined 18 Nov, see below).
- **Reject round:** managers only. Last level agrees → `rejected` (terminal).
- **Kept from below:** `modify_returned` removed (every return = `waiting_review`), Reject round ends `rejected`.
- **Removed from code:** `waiting_ssdp_review`, `ActionPlanApprovalService.Ssdp.cs`, `POST …/ssdp/approve`, `POST …/ssdp/modify`,
  the creator `can_review` rule. Bruno PR #176: the two SSDP requests removed, docs updated.
- **Why:** matches the Bruno route templates, Data Config tickets (PHI-2260 / PHI-2420, PHI-2247 / PHI-2256), the whiteboard
  ("Send to SSDP" like "Send to Manager"), and avoids SSDP approving twice.
- Current flow: `10-StatusFlow.md`.

### Also applied 18 Nov (staged, not built or tested)

- `is_can_review` on every list row (PEP + PHSS) and list query `is_can_review=true|false` (renamed from `can_review` on 18 Nov; the detail keeps `can_review`) (decisions 1–3 below). Same rule as
  the detail: review permission (config, else 161) + `waiting_review`.
- List `progress`: `need_review` (waiting_review), `routing` (in a round), `rejected`, else `on_schedule` / `overdue`.
  `upcoming` is no longer derived (a later start shows `on_schedule`); still accepted as a `status` filter value.
- `08-ScenarioTest` Test 3.2 restored to the original Reject-round case ("PO will reject").

### Answers 18 Nov (applied, staged, not built or tested)

- **PO options after a return:** keep approve / modify / reject. Race-safe: `ReviewAsync` claims the plan with a conditional
  UPDATE (`waiting_review` + same round) inside its transaction (`IActionPlanApprovalSource.ClaimForReviewAsync`); the loser
  gets 400 "decided by someone else, please reload".
- **SSDP level:** only the plan's creator. The route holds managers only; on a Modify the backend appends the creator as the
  last level (creator in `approvers` → 400; inactive creator → 400). The creator decides that level without 162 / 163, and the
  detail's `can_approve` / `can_reject` follow. Data Config: remove any SSDP level from the 4 routes; FE: stop dropping it.
- **PO notification on the final Modify approval:** ocean-email-template has no "modify approved" copy, so the PO pool and the
  SSDP submitter both get the existing "[action_type] In Progress" (`StageModifyApprovedAsync`). PO direct approve unchanged.

## Changes 17 November 2026

### Decisions

1. Field name is `can_review` (not `is_can_review`). Same name as the existing detail field.
2. The list action plan endpoint gets a `can_review` parameter.
3. `can_review` follows the Request List: a plan is `can_review = true` for a caller only when that plan appears in the caller's own review request list (`GET /well-surveilence/action-plans/approvals/need-action?stage=review`, or `my-task-list`) for that same caller.
4. SSDP gets a final review step. When all approval levels have approved, SSDP can review and approve the plan. This also applies when PO modifies the Action Plan (the Modify round).

### Rule for `can_review`

| Point of view | Plan state | `can_review` |
|---|---|---|
| PO (review pool, permission 161) | `waiting_review` or `modify_returned` | `true` |
| Manager at a level (approval step) | `modify_in_approval` / `reject_in_approval` | `false` (uses `can_approve` / `can_reject`) |
| SSDP creator of the plan | final SSDP step (new, see below) | `true` |
| Anyone else | any | `false` |

The list row is one row per action mode. `can_review` is computed per plan, so it is the same for every mode row of that plan.

### Flow: SSDP final review (new)

Current code (`ActionPlanApprovalService.cs`, approve path, `next is null`): the last level approves, then the proposal is applied and the plan goes straight to `approved`. There is no SSDP step.

Target flow:

```
PO modify (Modify round)
  Level 1 approve -> Level 2 approve (if 2 levels) -> last level approve
    -> plan status: waiting_ssdp_review (new)
    -> SSDP can_review = true, can_approve = true
    -> SSDP approve -> approved
```

- The PO proposal is applied when SSDP approves (not when the last level approves), so SSDP reviews exactly what will be saved.
- Notify SSDP when the plan reaches `waiting_ssdp_review`. Notify PO on `approved`.
- A plan that the PO approves directly (no Modify, no levels) is not changed: it still goes to `approved` at once.

### Decided

- SSDP reviewer = the plan creator (SSDP submitter). No permission pool.
- SSDP final step is approve only. No modify, no reject back to PO.
- SSDP is the last review in the Modify flow.
- Direct PO approve (no levels) still goes straight to `approved`.
- Remove `modify_returned`. When a level sends the plan back to PO, approval status becomes `waiting_review` (scenario label `need_review`) and the proposal is dropped, so PO works from the original data again. Each round stays in approval history with its outcome (`returned` / `rejected`).
- Test #2.1, #2.2, #3.1 expect `need_review` / `waiting_review` (not `modify_returned`). See `10-StatusFlow.md` section 5 for the code impact.

### Decisions on conflicts with 11-WhiteboardFlow (18 Nov 2026)

- **Final reject round (Test #3):** when the last level answers OK? Y in a Reject round, the plan ends `rejected` ("Action Plan Rejected", terminal), as on the whiteboard. This replaces the earlier "back to need_review" for this one step. Still to confirm: notify PO pool and SSDP creator.
- **SSDP final step:** SSDP approve → `approved` (proposal applied). SSDP N → loop back to Modify Action Plan, i.e. the plan returns to PO to modify (`waiting_review`).
- **Approval flow scope:** only Artificial Lift and Well Test have an approval flow. Choke, sonolog and others skip approval (`approved` at once, no WO number, no notification, no PO task).
  - Open: for Artificial Lift, the code today approves only WHC installation (`RequiresApproval`). Confirm whether non-WHC Artificial Lift also goes through approval.

### Applied in code (18 Nov 2026, branch feat/action-plan-al-wt, not built or tested)

- `modify_returned` removed. Return to PO (level reject, Reject-round Ask PO to Modify, SSDP N) sets `waiting_review`; the proposal is not applied.
- Last level of a Modify round → `waiting_ssdp_review`. New `SsdpApproveAsync` (creator only) applies the proposal → `approved`. New `SsdpReturnAsync` (creator only, N) → `waiting_review`. Endpoints `POST …/ssdp/approve` and `POST …/ssdp/modify`.
- Final OK? Y of a Reject round → `rejected` (terminal).
- PO can approve from `waiting_review` after a return (whiteboard row 6), since the return state is `waiting_review`.
- `can_review`: PO pool (161) on `waiting_review`, or the SSDP creator on `waiting_ssdp_review`.
- Tests in `ActionPlanApprovalTests.cs` and `ActionPlanWhcTests.cs` updated to the new states. Not run.
- One-off data fix: `12-modify-returned-data-fix.sql` (run after deploy).

### Not applied yet

- `can_review` as a list query parameter and per-row flag on the list endpoints.
- SSDP final review in the inbox / My Task (creator's list). Only the detail and the endpoints exist.
- Route setup: the test route and the FE "drop the last SSDP level" still assume an SSDP route level (level 3). Under this flow the SSDP step is the creator's, so that route level should be removed from the master route. Confirm.
- Artificial Lift scope (open question above).
- Build and test run (not run, per project rule).

### Status mapping (approval_status vs. scenario names)

| Scenario term | Code value |
|---|---|
| `need_review` | `waiting_review` (or `modify_returned` after a return) |
| `modify_in_approval` | `modify_in_approval` |
| `reject_in_approval` / "routing" | `reject_in_approval`, progress `routing` |
| `waiting_approval_level_N` | `approval.current_level = N` (integer) |
| `waiting_approval_level_ssdp` | `waiting_ssdp_review` (new) |
| `approve` | `approved` |
| `rejected` (final reject round) | `modify_returned`, cycle outcome `rejected` |

### Required 08-ScenarioTest changes (rechecked against code)

- Test #1, #2: "Status ACTION PLAN = need_review" -> `waiting_review`. "on_schedule" is `progress`, not approval status.
- Test #2: "waiting_approval_level_1/2" -> use `approval.current_level` (1, 2). The final step "SSDP will approve" needs the new `waiting_ssdp_review` step (see flow above). "Status Approval = approve" -> `approved`.
- Test #2.1 and #2.2: a Manager reject in a Modify round returns the plan to the PO. Expected approval_status is `modify_returned`, not `waiting_review`.
- Test #3: a final reject round returns the plan to the PO as `modify_returned`, not `approved`. Expected: approval_status `modify_returned`, cycle outcome `rejected`, notify PO pool and SSDP creator "Action Plan Rejected by Manager". "Status Approval = approved" is wrong.
- Test #3.1: a Manager "ask PO to modify" in a Reject round returns the plan as `modify_returned`, not `waiting_review`.
- Test #3.2: "approve to Reject" in a Modify round is `approval/reject`, which returns the plan to the PO at once. A Modify-round level cannot "ask PO to modify" (`approval/modify` is refused outside a Reject round). Rewrite this case.
- The no-approval block ("approved at once, no WO number, no notification, no task") matches the submit rule. Keep it.
- WHC block: "Artificial Lift Installation has been modified by <department>" goes to the SSDP final-review step under the new flow, not "the last level". The notification title in code is "Modify Action Plan".
- "Check on every step": add the SSDP review step to notifications and to the my-task-list visibility rule. Add `can_review` to the list rows.

### Code changes implied by this doc (not done yet)

1. Add `can_review` to `ActionPlanPhssListItemDto` and `ActionPlanPepListItemDto`, computed from the caller's review request list (ACL 161 + review states) and the SSDP final-review rule.
2. Add the `can_review` query parameter to the list endpoints.
3. Add `waiting_ssdp_review` to `ActionPlanApprovalRules`, and change the last-level approve path in `ActionPlanApprovalService.ApproveAsync` to go to it instead of `approved`.
4. Extend `ActionPlanApprovalAccessResolver` and need-action/my-task-list for the SSDP step.
5. Add tests for SSDP review after 1 level and after 2 levels, and after a PO modify.
