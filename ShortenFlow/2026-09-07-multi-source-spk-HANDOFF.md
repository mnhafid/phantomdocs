# Handoff: [SHORTENFLOW] Multi Source SPK

Worktree `shortenflow-multi-source-spk`, 2026-09-07. **Not committed. Not built.** Both were
excluded on request; the first thing to do is `dotnet build` then `dotnet test` from `src-be`
(see "Verification still owed").

Tickets: [2026-09-07-multi-source-spk-TICKETS.md](2026-09-07-multi-source-spk-TICKETS.md) ·
Glossary: [/CONTEXT.md](../../CONTEXT.md)

## What changed

| Ticket | Files | Done |
|---|---|---|
| T-01 | `Logics/Services/SpkBoqs/SpkBoqRecalculationService.cs`, `Logics/Services/Spks/SpksService.cs` (`RecalculateProjectTaskWeightsAsync`) | links grouped per row instead of keyed; task weight basis counts a row once |
| T-02 | `Logics/Services/ProjectTaskBoqs/ProjectTaskBoqsService.cs`, `ProjectTaskBoqsDto.cs` | rows matched by `(task, boq_detail_id)`; frozen rows (under a Locked SPK) never updated, re-draw creates a new row; submit-time linking removed (`spk_id` is context only); `SpksService` dependency dropped from the ctor |
| T-03 | same, plus new `Logics/Services/CustomConfigurations/UsdRateReader.cs` | active-contract guard (`approved` + `contract_end_date >= today`); estimated-cost guard with USD → IDR through `usd_rate`; `ProjectTasksService.GetUsdRateAsync` now delegates to the shared reader |
| T-04 | `SpksService.CreateSpkAsync` + new `Logics/Services/Spks/ProjectTaskSpkMirror.cs` | only the SPK's contract's rows are linked; Open-SPK links are soft-deleted and the row moves; Locked-SPK rows get a second link; Open SPKs are closed out (value, weights, assignment with reason `"moved"`) before the new assignment, so the new SPK becomes primary when the draft was |
| T-05 | `ProjectTasksService.ApplyEligibleForSpkFilter` (used by list + export filters) | with `contract_id`, eligible = has an open row drawn from that contract; the mirror `contract_id` predicate is skipped when `eligible_for_spk=true` |
| T-06 | `ProjectTasksService.ResetBoqAsync`, `IProjectTasksService`, `WebApi/Services/ProjectTasks/ProjectTasksEndPoint.cs` | `GET /projects/tasks/{id}/reset-boq?contract_id=` required; per-contract, open rows only; Open SPKs closed out with reason `"reset"`; `contract_id`/`spk_cost` cleared only when no row is left |
| T-07 | `SpksService.SoftDeleteSpkBoqLinesAsync` | rows another live non-canceled SPK still holds survive cancel |
| T-08 | `ProjectTaskBoqsService.GetProjectTaskBoqV2Async`, `ProjectTaskBoqsDto.GetProjectTaskBoqResponse.Contract` | per-row `contract` on v2 only (null and omitted on v1) |

Two shared status sets were added on `SpkStatusConstants`: `LockedStatuses`, `OpenStatuses`, `IsLocked()`.

## Deliberate choices worth knowing

- `SpksService.RefreshSpkTypeAsync` / `RecalculateProjectTaskWeightsAsync` now delegate to static `ProjectTaskSpkMirror`, so `ProjectTasksService` (reset) reaches the same code without taking `SpksService` as a dependency (its ctor is built in 9 test files).
- The submit's `contract_id` stamp and draft delete are now tracked writes, not `ExecuteUpdateAsync` / `ExecuteDeleteAsync`. Same effect, and the whole submit now runs under the in-memory provider. The three `[Fact(Skip=…)]` tests in `ProjectTaskBoqSubmitTests` still carry the old skip reason; one of them (`Resubmit_PointingTheRowAtAnotherLine_SoftDeletesTheOldDetail`) also encodes the OLD code/description match and contradicts T-02, so it should be rewritten, not just un-skipped.
- `ContractsService` already has an `isActive` that also checks `start_date`. T-03 checks status and `contract_end_date` only, as decided (Q12/Q13).
- Missing `usd_rate` configuration skips the conversion rather than failing the submit, matching every read path.

## Tests

- New: `Tests/MultiSourceSpkTests.cs` — 20 facts across T-01 … T-07 on the in-memory provider.
- New: `ProjectTaskFilterTests.EligibleForSpkWithContract_OnTheRealPipeline_TranslatesToSqlServer` — compiles the three-level correlated predicate against the SQL Server model.
- Fixtures updated because the guards are stricter now: `ProjectTaskBoqSubmitTests` (contract approved + end date, task budget, ctor), `BoqParentAndDraftContractTests` (ctor), `SpkCreateFieldInspectorTests.SeedCreatable` (line now has a draw → BOQ → contract chain, otherwise Create SPK finds no row), `ProjectTaskFilterTests` (reflection on an instance method).

## Verification still owed

1. `dotnet build` — nothing here has been compiled. Watch for: `ProjectTasksService` unused usings after the USD-rate extraction; the `Spks.ProjectTaskSpkMirror` qualified name inside `ProjectTasksService` (namespace `Phantom.BackEnd.Logics.Services.ProjectTasks` → sibling `Spks`).
2. `dotnet test --filter FullyQualifiedName~MultiSourceSpkTests`, then `~ProjectTaskBoqSubmitTests`, `~SpkCreateFieldInspectorTests`, `~ProjectTaskFilterTests`, `~ProjectTaskSpkAssignmentTests`, `~SpkModifyBoqTests`, `~SpkBoqVisibleAfterCancelTests`.
3. Run the picker query once against dev SQL Server (`GET /projects/tasks?eligible_for_spk=true&contract_id=…`) — the translation test proves it compiles, not that it is fast.
4. Not written: the ADR for "a new SPK takes rows from an Open SPK on the same contract" (offered, not confirmed).

## Out of scope, unchanged

Modify BoQ (Q18), `project_tasks.contract_id` meaning (Q14/Q15), the various-WBS create path, the FSD's GAP-1 contract balance gate, the FE contract picker filter.
