# Handoff — task BOQ submit 400 / shorten flow

**Written:** 2026-09-03 · session `phidev-4a`
**Continues:** `task-boq-submit-400-FINDINGS.md` (same folder)
**Branch:** `feat/projecttaskboq` · HEAD `418cbd13` at time of writing
**Status:** analysis + ticket draft only. **No code was written or committed by this session.**

> The working tree changed *during* this session (another session or the user was editing).
> Two findings below were invalidated by those edits and are marked as such. Re-verify against
> the tree before acting — do not trust this file over the code.

---

## 1. The original problem

`POST /api/v1/projects/tasks/boqs` returns 400 for the payload the FE sends.

```
spk_boqs[0].boq_detail_id is required and must be a valid UUID
```

**Root cause (verified).** The FE nests the draw:

```json
"spk_boqs": [{ "type": "inline", "boq_details": [{ "boq_detail_id": "...", "unit_price": 4166666.67 }] }]
```

On `origin/phi-dev`, `SetSpkBoqRequest` has **no `boq_details` property**. `System.Text.Json`
discards the array silently, `BoqDetailId` binds to `Guid.Empty`, and validation throws.
The deployed `phantom-api.inproms.com` runs this version.

**Route map:** `ProjectTaskBoqsEndpoint.cs:154` (`POST /projects/tasks/boqs`) and `:162`
(`/submit` alias) share one handler → `SetProjectTaskBoqAsync`.

---

## 2. Current working tree (uncommitted)

5 files modified. `NormalizeLegacyRow` (`ProjectTaskBoqsService.cs:322`) fixes the 400 by:

1. `type: "item"` → `"inline"`
2. lifting a single `boq_details[0]` onto the row
3. rejecting >1 draw (never truncates — the persistence step soft-deletes non-matching details as orphans)
4. rejecting row `total_price` ≠ draw `total_price` (0.01 tolerance)

`NormalizeDraftPayload` (`:363`) applies 1 and 2 to draft payloads on save, at `:636`.

Also changed in-session, apparently as a separate decision:

- `boq_details` **removed** from `ProjectTaskBoqDraftResponse` / `...V2Response`. The doc comment
  now points the FE at `GET /api/v1/contracts/boqs/details`.
- `IBoqDetailRow.DataType` deleted (`BoqsDto.cs:331`).
- `ProjectTaskBoqsService` constructor dropped its `IBoqsService` dependency.

---

## 3. The main unresolved objection

**The user's position: shorten-flow changes must go on a NEW endpoint and NEW function, not by
editing the existing ones.** The current tree does the opposite.

**Why this matters (verified).** `SetSpkBoqRequest` is not private to this endpoint:

```csharp
// src-be/Logics/Services/Spks/SpksDto.cs:807
[Required(ErrorMessage = "SPK BoQ is required")]
[JsonPropertyName("spk_boqs")]
public List<SetSpkBoqRequest> SpkBoqs { get; set; } = new();
```

Adding `boq_details` to it silently widens the **SPK create/update contract** too. And because
v1 submit and `/submit` share one method, the normalization changes v1's accepted contract for
every existing client.

**The file already establishes the wanted pattern** — `ProjectTaskBoqsEndpoint.cs:71`:

> `// v2 carries the same tags/auth filter as v1 (pattern: TendersEndpoint). Only the routes`
> `// whose contract actually changed are registered here — everything else stays on v1.`

The v2 group exists at `:73` and already hosts `MapGetProjectTaskBoqsV2` and
`MapGetProjectTaskBoqDraftV2`.

**Proposed shape — DTO + mapper, zero change to existing logic.** The persistence loop
(`:486-571`) reads: `Code, Description, Kind, UnitId, Volume, TotalPrice, StartDate, EndDate,
Remarks, Type, BoqDetailId, UnitPrice`. The v2 payload supplies all of them; two just live one
level down. So v2 needs only:

1. `SetSpkBoqV2Request` / `SetProjectTaskBoqV2Request` — `boq_details[]` **native**, not "legacy"
2. a mapper V2 → existing `SetProjectTaskBoqRequest` (this is `NormalizeLegacyRow`, relocated)
3. `SetProjectTaskBoqV2Async` that maps, then calls the **unchanged** `SetProjectTaskBoqAsync`
4. `POST /api/v2/projects/tasks/boqs` (+ `/submit`) on the existing v2 group

`SetSpkBoqRequest` and `SetProjectTaskBoqAsync` revert to their `phi-dev` state. SPKs untouched.
Nothing needs extracting from the shared method — v2 sits on top of it, not inside it.

---

## 4. Headers — resolved, but confirm it was deliberate

The read path is **not versioned**. `GetProjectTaskBoqCoreAsync` (`:125`) is the single query
behind both v1 and v2 GET — its own comment: *"Shared implementation for both versions so they
cannot drift."* It filters only on `DeletedAt == null` + project task id, with no `type` filter,
and projects `Type = b.Type` (`:221`). So **anything v2 writes, v1 GET returns.** A
"v2 has headers, v1 doesn't" split cannot hold on the write side alone.

**The current tree already resolves this the clean way:** nothing persists headers. They are a
contract-BOQ concept (`BoqDataType.Header`, `BoqsDto.cs:125`) served by
`GET /api/v1|v2/contracts/boqs/details` (`BoqsEndpoint.cs:445, 450, 484, 490`), whose rows carry
`data_type` (`:376`/`:483`) and `parent_id` (`:405`/`:490`). The v2 route also returns every
row's ancestors, so a client can nest without a second call.

⚠️ **Open:** removing `boq_details` from the draft response is a **breaking change to v1**. Any FE
reading `draft.boq_details` now gets nothing. Confirm this was intended and that the FE has moved
to the contracts endpoint.

---

## 5. Findings from this session that are now MOOT

Recorded so nobody re-reports them:

- **`type: "header"` → 500 via `ParseExact`.** An earlier version of the tree added an
  `IsHeader(b.Type)` early return to `ValidateRow` while the persistence loop still called
  `DateTime.ParseExact` on every row, and `ProjectTaskBoq.UnitId/StartDate/EndDate` are
  non-nullable. **Gone** — the header branch was removed; headers now get a clean 400.
- **Task-BOQ draft returns header rows with `parent_id`.** True earlier; that response no longer
  carries `boq_details` at all.

---

## 6. Decisions already made by the user

| Question | Answer |
|---|---|
| Accept nested shape in BE, or make FE flatten? | **BE normalizes.** FE unchanged, old drafts keep working. |
| One draw per row, or several? | **One, permanent.** Reject >1, never truncate. |
| Batch all payload errors into one 400? | **Yes**, its own ticket. |
| Test coverage approach | **Validation-level tests now**, relational harness as a follow-up. |

Superseded in part by §3: the user later required this to land on a **new endpoint + new
function**, which the ticket table below reflects.

---

## 7. Draft tickets — NOT yet created in Luvus

Awaiting go-ahead. `luvus` is installed; nothing was written to it.

| ID | Title | Size | Blocked by |
|----|-------|------|------------|
| B1 | Revert `SetSpkBoqRequest` + `SetProjectTaskBoqAsync` to their `phi-dev` contract | S | — |
| B2 | Add `SetProjectTaskBoqV2Request` / `SetSpkBoqV2Request` with native `boq_details[]` | S | B1 |
| B3 | Add `SetProjectTaskBoqV2Async` + `POST /api/v2/projects/tasks/boqs` and `/submit` | M | B2 |
| B4 | Decide + implement draft: does v2 get its own save-draft, or does v1 draft save stay as on `phi-dev`? | M | B3 |
| B5 | Report every payload violation in one 400 instead of throwing on the first | M | B3 |
| B6 | Relational test harness; enable the 3 `[Fact(Skip=...)]` persistence tests | L | B3 |

An earlier draft had a "extract shared persistence body" ticket. **Dropped** — with the mapper
approach there is nothing to extract.

---

## 8. Test state

`src-be/Tests/ProjectTaskBoqSubmitTests.cs` — 5 tests, **3 are `[Fact(Skip=...)]`**: the in-memory
provider cannot run `ExecuteUpdateAsync`/`ExecuteDeleteAsync`, and the full `PhantomDbContext`
schema will not build under Sqlite (AUTOINCREMENT on a non-INTEGER key).

**There is no test covering the normalization at all.** A runnable pattern that needs no harness:
submit a nested row whose `boq_detail_id` does not exist, and assert the error is
`"BoQ Detail ID Not Found"` rather than `"...boq_detail_id is required..."`. The different message
proves the lift happened, and the call stops before the DB write.

⚠️ Do not run `dotnet test --no-build` — a failed build plus `--no-build` yields a confident green
from a stale `Tests.dll`. Check the build exit code first.

---

## 9. Open questions for whoever picks this up

1. Does the shorten flow land on `/api/v2` (§3), or did the user change their mind?
2. Was removing `boq_details` from the draft response intended, and has the FE migrated? (§4)
3. Does v2 need its own save-draft endpoint, or does v1 draft save revert? (B4)
4. Nothing verified against the dev DB this session. The claim that live `project_task_boqs.type`
   holds only `inline`/`custom` is a code comment, not a checked fact.
