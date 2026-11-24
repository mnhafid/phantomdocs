# Draft BoQ: SPK-scoped draws + draft search

**Date:** 2026-09-03
**Status:** Raw findings, pre-grilling. Nothing implemented.

Two requests against the Shorten Flow draft/submit path.

---

## F1 — Submit from an SPK-linked task must scope draws to that SPK

**Ask:** when the task BOQ is created from an existing SPK, check each `boq_detail_id` is connected to that SPK, and set the row `type` from the SPK rather than from the request.

### What the code does today

`SetProjectTaskBoqAsync` validates a draw against the **contract** only:

```csharp
// step 2 — the only scope check that exists
if (v.ContractId != request.ContractId)
    throw new InvalidOperationException($"BoQ Detail ID Invalid : {v.Id}");
```

Nothing consults `project_tasks.spk_id`, `project_task_spks`, or `spk_boqs`. A task already tied to an SPK can therefore draw from any line on the whole contract, including lines that SPK does not cover.

### The join that would be needed

`spk_boqs` carries **no `boq_detail_id`**. Confirmed columns: `id, spk_id, project_task_boq_id, weighted_project_task, weighted_spk, physical_progress, physical_progress_weighted, actual_volume, actual_progress_cost` + audit. So "connected with the SPK" can only be resolved through the chain:

```
spk_boqs.spk_id
  -> spk_boqs.project_task_boq_id
  -> project_task_boqs.id
  -> project_task_boq_details.boq_detail_id
  -> boq_details.id
```

Note `project_task_boqs.project_task_id` is **nullable** — this is the various-WBS case flagged in ADR 0007, and the reason the chain must go through `project_task_boq_id` rather than a task id.

### Open — for grilling

- Which SPK? `project_tasks.spk_id` is only the PRIMARY mirror; ADR 0007 says a task may hold several `project_task_spks`. Scope to the primary, or to the union of all active assignments?
- "created from an existing SPK" is not a state the schema records. What distinguishes it from a task that merely has an SPK?
- "insert type boq from spk" — `project_task_boqs.type` is `inline` | `custom` today (346 / 4 live). `spk_boqs` has no type column, so there is nothing named "type" on the SPK side to copy.
- Is this a hard reject, or a warning?

---

## F2 — `search` on GET draft, matching BOQ description / title

**Ask:** add a query param to `GET /projects/tasks/boqs/draft` that filters rows by description / BOQ title.

### What the code does today

The handler binds exactly one parameter:

```csharp
group.MapGet("/projects/tasks/boqs/draft",
    async (string? project_task_id, IProjectTaskBoqsService svc, ...) => ...)
```

Draft rows are not stored — they are fetched live from the contract via `boqsService.GetAllBoqDetailsAsync(ctx.RowFilter)` and then trimmed by `SelectDraftRows`.

### Three facts that shape the design

1. **`BoqDetailFilter` already has the fields.** It exposes `Breakdown` and `Description`. So the filter may need no new plumbing at all — just populate `ctx.RowFilter`.
2. **`GetProjectTaskFilter.Search` already exists and is dead.** It carries `[FromQuery(Name = "search")]`, and `filter.Search` is referenced **zero** times in the service. The list endpoint advertises a search that does nothing.
3. **`SelectDraftRows` trims by reference, not by text.** It keeps every header row plus any row the draft payload references. A text filter composed with that rule can drop rows the draft actually uses, leaving a payload the FE cannot rehydrate.

### Open — for grilling

- Search the contract rows offered for picking, or the rows already in the draft?
- What happens to a referenced row that does not match the search term?
- Headers: keep all (current behaviour), keep only those with a surviving child, or drop?
- Does the dead `search` on the list endpoint get fixed in the same change, or stay dead?


---

## F0 — ROOT CAUSE: the FE sends a `boqs.id` in the `boq_detail_id` field

Found while checking the two tasks named for F1. This outranks both findings below and probably explains the original submit 400.

### Evidence

Two live drafts, two different tasks, two different contracts — same mistake in both:

| Draft's task | Draft `contract_id` | Value sent as `boq_detail_id` | What that GUID actually is |
|---|---|---|---|
| `e0f07aa9-e0ce-40a7-871a-e0bbfa1f94e5` | `ebb4aa20-…` | `a3a6d80f-74e9-4179-8d25-a73cdb594737` | **`boqs.id`** — the active v1 BOQ of contract `ebb4aa20` |
| `3fd853a9-7591-44d0-8c59-4bee1d980d8e` | `7512aa02-…` | `c47cf761-fb95-4340-b2f8-8f4ad383a4fa` | **`boqs.id`** — the active v1 BOQ of contract `7512aa02` |

Neither GUID exists in `boq_details` — `select count(*) from boq_details where id = …` returns **0** for both. They are BOQ *version* rows, one level up from the line the row is supposed to draw from.

The pairing is exact: each draft carries the `boqs.id` belonging to its own `contract_id`. This is a systematic field mix-up in the client, not a stale id or a race.

Confirmation from the other direction: the real `boq_details` rows under BOQ `a3a6d80f` carry `code = "TRBL.1."` and `description = "A. PEKERJAAN PERSIAPAN DAN ADMINISTRASI"` — **exactly** the `code`/`description` in the payload from the original 400 report. The row is drawing from one of those lines; it just names the parent BOQ instead of the line.

It is not a v1/v2 divergence: `GetAllBoqDetailsV2Async` reads the same `BoqDetail` entity, so both versions expose `boq_details.id`.

### What it means

- The BE already rejects this, at step 2: `validated.Count != boqDetailIds.Count` → `BoQ Detail ID Not Found` → 400. Correct outcome, unhelpful message — it does not say the caller sent an id of the wrong class.
- **F1 cannot be built on top of this.** "Is this `boq_detail_id` connected to the SPK?" is unanswerable while the value is not a `boq_detail_id` at all. Fix F0 first.
- Under BOQ `a3a6d80f` there are at least 4 `boq_details` rows sharing the identical `code` + `description` (`TRBL.1.` / `A. PEKERJAAN…`), all `data_type = item`. So the FE cannot resolve the intended line from code+description alone — it must carry the real detail id.

### Open

- Is the FE reading `id` off the BOQ envelope instead of off each row, or is the draft-restore path re-writing the field?
- Should the BE detect this specific case and say so (`"… is a BOQ id, not a BOQ detail id"`)? Cheap, and it would have turned this investigation into a single glance at the response.

---

## F1 addendum — neither named task has an SPK

Both tasks offered as the "submit using existing spk_id" example have:

```
contract_id NULL   spk_id NULL   spk_type NULL   spk_cost 0
project_task_spks rows  0
project_task_boqs rows  0
```

`e0f07aa9`'s draft points at contract `ebb4aa20`; `3fd853a9`'s at `7512aa02` (20 SPKs on it). In both cases the task itself is linked to no contract and no SPK, so there is nothing server-side for an SPK-scoped check to key on. "Created from an existing SPK" is therefore not a persisted state — see the grilling thread.

## F2 addendum — the search is already implemented, one level down

`BuildBoqDetailQuery` (`BoqsService.cs:1089-1095`) already does exactly what F2 asks:

```csharp
if (!string.IsNullOrWhiteSpace(filter.Search))
{
    var searchKeyword = filter.Search.ToLower();
    query = query.Where(d =>
        d.Code.ToLower().Contains(searchKeyword) ||
        d.Description.ToLower().Contains(searchKeyword));
}
```

Code **or** description, case-insensitive. `BoqDetailFilter.Search` is inherited by `BoqDetailV2Filter`, and `LoadMissingAncestorsAsync` re-attaches headers the filter dropped — which answers the "what happens to headers" question I raised.

So F2 is plumbing: accept `search` on the draft GET handler and set `ctx.RowFilter.Search`. The one real design question survives: `SelectDraftRows` keeps headers + rows the draft payload references, and a narrowing search can remove a referenced row from the result set entirely, so the planner's own selections disappear from the picker.
