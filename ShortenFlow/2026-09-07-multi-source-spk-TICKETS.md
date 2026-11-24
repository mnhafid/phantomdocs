# Tickets: [SHORTENFLOW] Multi Source SPK

Source: grilling session 2026-09-07 (decisions Q1–Q18) · Glossary: [/CONTEXT.md](../../CONTEXT.md) · QA plan: "Multi Source SPK" sheet (tests 001–019) · Prior state: [FSD.md](FSD.md)

Vocabulary used below is the glossary's: **row** = task BoQ line (`project_task_boqs`), **contract BoQ line** = `boq_details` row, **link** = `spk_boqs` row, **Open SPK** = draft / on hold / canceled, **Locked SPK** = approved / released / finished / finished with note, **open row** = row with no live link or linked only to Open SPKs, **frozen row** = row with a live link to a Locked SPK.

## Summary

| ID | Title | Size | Blocked by | Covers |
|---|---|---|---|---|
| T-01 | [SHORTENFLOW] Recalculation accepts several live links per row | M | — | prerequisite for T-03 |
| T-02 | [SHORTENFLOW] Submit matches rows by contract BoQ line and freezes rows under a Locked SPK | M | — | Q1, Q6, Q7 · tests 001, 002, 011 |
| T-03 | [SHORTENFLOW] Submit refuses inactive contracts and insufficient estimated cost | S | T-02 | Q11, Q12, Q13 · tests 004, 006–009 |
| T-04 | [SHORTENFLOW] Create SPK links only its contract's rows and applies the Open/Locked rules | L | T-01 | Q4, Q5, Q9 · tests 012, 013 |
| T-05 | [SHORTENFLOW] Create SPK task picker is contract-aware | S | — | Q8 · tests 012, 013 |
| T-06 | [SHORTENFLOW] Reset SPK BoQ per contract | M | T-04 | Q10 · test 003 |
| T-07 | [SHORTENFLOW] Cancel SPK keeps rows another SPK still holds | S | — | Q17 |
| T-08 | [SHORTENFLOW] v2 task BoQ list carries the contract per row | S | — | Q15, Q16 |

Decisions with no ticket because they change nothing: Q14/Q15 (`project_tasks.contract_id` keeps meaning "last submitted contract"; no column on `project_task_spks`), Q18 (Modify BoQ unchanged).

Rules for every ticket: no new dependencies, no new tables, additive only. No commit and no build in this pass; the worktree is handed over as-is.

---

## T-01: [SHORTENFLOW] Recalculation accepts several live links per row

- **Size:** M · **Blocked by:** —

**Context**
`SpkBoqRecalculationService.RecalculateTaskBoqWeightsAndPlanAsync` builds `ToDictionary(sb => sb.ProjectTaskBoqId)` over live links (`SpkBoqRecalculationService.cs:99`). Two live links on one row (the Locked-SPK case of T-04) throw a duplicate-key exception. `SpksService.RecalculateProjectTaskWeightsAsync` (`:4307`) joins links to rows and sums `TotalPrice` once per link, so the same row counts twice.

**Scope of work**
- In `RecalculateTaskBoqWeightsAndPlanAsync`, group live links by `ProjectTaskBoqId` and apply the per-row weight and schedule maths to every link of the row. `WeightedProjectTask` is a property of the row's share of the task, so every link of a row gets the same value.
- In `RecalculateProjectTaskWeightsAsync`, sum `TotalPrice` over distinct rows per task (a row with two links counts once).

**Acceptance criteria**
- Given a task whose row R has live links to SPK A and SPK B, when the task's weights are recalculated, no exception is thrown and both links carry the same `WeightedProjectTask`.
- Given the same task, when project task weights are recalculated, R's `TotalPrice` contributes once to the task's basis.

**Out of scope**
- `SpkBoq.WeightedSpk`; that is per SPK and already correct.

**Test notes**
- In-memory `PhantomDbContext`, one task, one row, two live links, call both methods, assert no throw and the sums.

---

## T-02: [SHORTENFLOW] Submit matches rows by contract BoQ line and freezes rows under a Locked SPK

- **Size:** M · **Blocked by:** —

**Context**
`SetProjectTaskBoqAsync` matches an existing row by `(code, description, kind)` (`ProjectTaskBoqsService.cs:471`), overwrites it in place, and when the request carries `spk_id` it links rows to that SPK at once (`:564`). Decisions: the identity of a row is (task, contract BoQ line); a row under a Locked SPK is frozen and a re-submit of its contract BoQ line creates a new row; the submit never creates links.

**Scope of work**
- Load the task's live rows with their live detail, plus the set of row ids that have a live link to a Locked SPK (join `spk_boqs` → `spks`, `DeletedAt == null`, status in the Locked set). Put the Locked status set in one place (`SpkStatusConstants.LockedStatuses`) and the Open set beside it.
- For each submitted item row, find the task's **open** row whose live detail has the same `boq_detail_id`. If found, update it in place (values, dates, remarks, type, undelete). If not found, create a new row, whether or not a frozen row exists for the same contract BoQ line.
- Remove the `spk_id` link block (`LinkSubmittedLinesToSpkAsync`, `EnsureTaskAssignedToSpkAsync`, `RecalculateSpkValueAndWeightsAsync`, the `RecalculateProjectTaskWeightsAsync` call) and the step 1b SPK validation. Keep `spk_id` on the DTO; it is context for the draft only.
- Keep: header skipping, per-row validation, contract-ownership check of `boq_detail_id`, append semantics, the `contract_id` stamp (Q15 option A), draft consumption, and the task-weight recalculation call.

**Acceptance criteria**
- Given a task with open row R for contract BoQ line C, when the same C is submitted with a different description and volume, then R is updated in place and no second row exists.
- Given R has a live link to a released SPK, when C is submitted with volume 20, then a new row R2 (volume 20) exists, R is unchanged, and R2 has no link.
- Given a submit with `spk_id`, when it completes, then no `spk_boqs` or `project_task_spks` row was written by the submit.

**Out of scope**
- Any SPK value change; SPKs are only touched by Create SPK (T-04).

**Test notes**
- Extend `Tests/ProjectTaskBoqSubmitTests.cs`. The in-memory provider cannot run `ExecuteUpdateAsync`; follow the existing skip pattern where the assertion sits after that call.

---

## T-03: [SHORTENFLOW] Submit refuses inactive contracts and insufficient estimated cost

- **Size:** S · **Blocked by:** T-02

**Context**
The submit checks only that the BOQ version is active. Decisions: an active contract is status approved with `contract_end_date` today or later; the task's `estimated_cost` (IDR) must cover the IDR sum of every live row plus the submit.

**Scope of work**
- After the task/project check, load the contract. Refuse with `Contract Invalid : status is {status}` when status is not `ContractConstant.StatusApproved`, and `Contract Invalid : contract ended on {dd-MM-yyyy}` when `ContractEndDate` is before today's date.
- Compute the projected total: sum of `TotalPrice` over the task's live rows that are **not** replaced by this submit, plus `TotalPrice` of every submitted item row. Rows from a USD contract are multiplied by the `usd_rate` custom configuration (reuse the parsing in `ProjectTasksService.GetUsdRateAsync`; extract it to a shared static helper rather than duplicating). A row's contract currency is read through `project_task_boq_details` → `boq_details` → `boqs` → `contracts.currency`.
- Refuse with `Estimated cost insufficient : remaining {remaining:0.##}` when the projected total is greater than `estimated_cost`. Treat a null `estimated_cost` as 0.
- The draft save stays unvalidated.

**Acceptance criteria**
- Given a contract with status on hold, when a submit names it, then 400 with the status message and nothing is written.
- Given an approved contract whose `contract_end_date` is yesterday, when a submit names it, then 400 with the ended message.
- Given a task with `estimated_cost` 10,000,000, an existing live row of 8,000,000, and a submit adding a 3,000,000 row, then 400 naming remaining 2,000,000.
- Given the same task and a submit that updates the existing row to 9,000,000, then it succeeds.

**Out of scope**
- The contract balance gate (FSD GAP-1).

---

## T-04: [SHORTENFLOW] Create SPK links only its contract's rows and applies the Open/Locked rules

- **Size:** L · **Blocked by:** T-01

**Context**
`CreateSpkAsync` links every live row of every selected task (`SpksService.cs:311`) with no contract filter and no check for existing links. Decisions Q5, Q9, Q10: an SPK on contract Y takes only rows drawn from Y; an unlinked row is linked; a row under an Open SPK moves to the new SPK; a row under a Locked SPK gets a second link.

**Scope of work**
- Load candidate rows: live rows of the selected tasks whose live detail's `boq_details.BoqId` belongs to a `boqs` row with `ContractId == request.ContractId`. Return `Project task BOQ Not Found` when empty (message unchanged).
- Load the live links of those rows with their SPK status.
- Per row: no live link → new link. Live link to an Open SPK → soft-delete that link (`DeletedAt`/`DeletedBy`), then new link. Live link to a Locked SPK → new link beside it. Skip a row whose only live link is already to the SPK being created (cannot happen on create; keep the guard cheap).
- After links: for every Open SPK that lost a link, recalculate its `SpkValue` from its remaining live links and reset those links' `WeightedSpk` (extract the maths from the removed `RecalculateSpkValueAndWeightsAsync` in `ProjectTaskBoqsService` into `SpksService`). Do not touch `contracts.spk_value`. For each (Open SPK, task) pair with no remaining live link on that task, close the `project_task_spks` row (`UnassignedAt`, `UnassignedBy`, `UnassignmentReason = "moved"`), and clear the `spk_id` / `spk_cost` mirror when that assignment was primary.
- `spkValue`, `taskTotalByTask`, `taskCost`, and the plan schedules are built from the candidate rows only. `RefreshSpkTypeAsync` and `RecalculateProjectTaskWeightsAsync` run for every affected task, including the ones that lost an Open SPK.
- Everything stays in the existing transaction.

**Acceptance criteria**
- Given task T with row X1 from contract X and row Y1 from contract Y, when SPK N is created on Y from T, then N links Y1 only and `spk_value` equals Y1's price.
- Given Y1 is linked to draft SPK A, when N is created, then A's link is soft-deleted, N links Y1, A's `spk_value` no longer includes Y1, and A's assignment to T is closed when A has no other rows on T.
- Given Y1 is linked to released SPK A, when N is created, then A's link is untouched and Y1 has two live links.
- Given T has no Y rows, when N is created on Y from T, then `Project task BOQ Not Found`.

**Out of scope**
- Deleting an emptied draft SPK; the user does that.
- The various-WBS create path (`CreateSpkVariousWbsAsync`); it builds its own rows.

**Test notes**
- `Tests/SpksServiceTests.cs` has the create harness; seed a contract, a BOQ with `IsActive = 1`, two `boq_details` on two contracts, a task with two rows and details, and the prior SPK with status from `SpkStatusConstants`.

---

## T-05: [SHORTENFLOW] Create SPK task picker is contract-aware

- **Size:** S · **Blocked by:** —

**Context**
`EligibleForSpk` filters on `ContractId != null && SpkId == null` (`ProjectTasksService.cs:2607` and `:3439`), so a task disappears after its first SPK. Decision Q8 option 1.

**Scope of work**
- When `EligibleForSpk == true`, require `filter.ContractId`; without it, keep today's predicate for compatibility.
- With a contract: a task qualifies when it has at least one live row whose live detail belongs to that contract's BOQ and the row is open (no live link, or every live link's SPK status is in the Open set). Express it as one `Any` predicate over `ProjectTaskBoqs` so EF translates it.
- Apply in both places.

**Acceptance criteria**
- Given task T with a Y row under draft SPK A, when the picker is called with `eligible_for_spk=true&contract_id=Y`, then T is returned.
- Given T's only Y row is under a released SPK, then T is not returned for Y.
- Given T has an unlinked X row, then T is returned for X and not for Y.

---

## T-06: [SHORTENFLOW] Reset SPK BoQ per contract

- **Size:** M · **Blocked by:** T-04

**Context**
`ResetBoqAsync` (`ProjectTasksService.cs:3466`) refuses a task with `spk_id` and soft-deletes every row. Decision Q10.

**Scope of work**
- `GET /projects/tasks/{id}/reset-boq` takes a required `contract_id` query parameter (bound as `string?`, parsed by hand; missing → 400 `Contract is Required`). Drop the `spk_id` refusal.
- Soft-delete only the task's open rows drawn from that contract, and their live details. Frozen rows stay.
- For each removed row's live link to an Open SPK, soft-delete the link and apply T-04's Open SPK close-out (value recalculation, assignment close with reason `"reset"`, `spk_type` refresh). Extract the close-out from T-04 so both paths call one helper.
- Clear `project_tasks.contract_id` and `spk_cost` only when the task has no live rows left; otherwise leave `contract_id` as it is.
- Recalculate project task weights for the task's project.

**Acceptance criteria**
- Given T with open rows on X and Y and a frozen Y row, when reset is called for Y, then the open Y row is soft-deleted, the frozen Y row and the X rows stay, and `contract_id` is unchanged.
- Given the open Y row was linked to draft SPK A, then A's link is soft-deleted and A's assignment to T is closed.
- Given reset removes T's last live row, then `contract_id` is null and `spk_cost` is 0.

---

## T-07: [SHORTENFLOW] Cancel SPK keeps rows another SPK still holds

- **Size:** S · **Blocked by:** —

**Context**
`SoftDeleteSpkBoqLinesAsync` (`SpksService.cs:4193`) soft-deletes every row reached through the canceled SPK's links. With a second link from T-04, that removes a row from under a Locked SPK. Decision Q17.

**Scope of work**
- Restrict the soft-delete to rows that have no live link to any other non-canceled, non-deleted SPK. The canceled SPK's own links stay as history, as today.

**Acceptance criteria**
- Given row R linked to released SPK A and to SPK N, when N is canceled, then R and its details stay live.
- Given row S linked only to N, when N is canceled, then S and its details are soft-deleted.

---

## T-08: [SHORTENFLOW] v2 task BoQ list carries the contract per row

- **Size:** S · **Blocked by:** —

**Context**
`GET /api/v2/projects/tasks/boqs` returns one `contract` per task group from the mirror column. Rows can now come from two contracts. Decision Q16 option 1.

**Scope of work**
- Add `contract` (`ContractSimpleResponseDto`, nullable) to the v2 per-row shape only. Fill it from the row's live detail → `boq_details` → `boqs.contract_id`, reusing the contract map already built in `GetProjectTaskBoqV2Async` (extend the id set with the rows' contracts).
- The group-level `contract` stays as it is.
- v1 shape unchanged.

**Acceptance criteria**
- Given a task with rows on X and Y, when v2 is called, then each row's `contract.id` matches its own contract and the group's `contract` is the mirror column's.
- Given the same task, when v1 is called, then the body is byte-identical to before.

**Test notes**
- `Tests/ProjectTaskProgressResponseMappingTests.cs` has the v2 mapping fixtures.

---

## Coverage check

| Decision | Ticket |
|---|---|
| Q1 row identity = (task, contract BoQ line) | T-02 |
| Q2 Locked/Open by SPK status | T-02, T-04, T-05, T-06 |
| Q4 links only at Create SPK | T-02 (removal), T-04 |
| Q5 SPK takes its contract's rows only | T-04 |
| Q6 frozen row → new row | T-02 |
| Q7 remove submit-time linking | T-02 |
| Q8 picker contract-aware | T-05 |
| Q9 Open SPK close-out | T-04, T-06 |
| Q10 reset per contract | T-06 |
| Q11 estimated cost guard | T-03 |
| Q12/Q13 active contract | T-03 |
| Q14/Q15 mirror column unchanged, no new column | — |
| Q16 per-row contract in v2 | T-08 |
| Q17 cancel keeps shared rows | T-07 |
| Q18 Modify BoQ unchanged | — |
