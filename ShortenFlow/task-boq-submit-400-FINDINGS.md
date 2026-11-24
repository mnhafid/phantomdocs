# POST /projects/tasks/boqs/submit → 400 — FE/BE contract mismatch

**Date:** 2026-09-03
**Env:** `https://phantom-api.inproms.com`
**Endpoint:** `POST /api/v1/projects/tasks/boqs/submit?project_task_id=e0f07aa9-e0ce-40a7-871a-e0bbfa1f94e5`
**Response:** `400` — `"spk_boqs[0].type must be 'inline' or 'custom'"` (18.00ms — rejected in payload validation, never reached the DB)

---

## 1. Where it fails

`src-be/Logics/Services/ProjectTaskBoqs/ProjectTaskBoqsService.cs:292-293`, inside `SetProjectTaskBoqAsync` step 0 ("Payload validation, mirrors Go's ozzo-validation rules"):

```csharp
if (b.Type != "inline" && b.Type != "custom")
    throw new InvalidOperationException($"spk_boqs[{i}].type must be 'inline' or 'custom'");
if (b.BoqDetailId == Guid.Empty)
    throw new InvalidOperationException($"spk_boqs[{i}].boq_detail_id is required and must be a valid UUID");
```

---

## 2. Three mismatches, not one

The reported error is only the first guard the payload trips. Fixing `type` alone moves the 400 one line down.

### M1 — `type` vocabulary collision *(the reported error)*

FE sends `"type": "item"`. That is the **contract BOQ** vocabulary (`boqs.data_type` — `item` / header / etc., cf. `BoqDataType.Item` in `BoqsService.cs`). The endpoint expects the **task BOQ** vocabulary, `inline` | `custom`.

Two different enums, same JSON key. Decide which side is wrong:

- If the row genuinely draws from a contract BOQ line → FE should send `inline`.
- If `item` is meant to survive as a separate concept → BE needs a distinct field, not an overload of `type`.

### M2 — `boq_detail_id` and `unit_price` are nested, BE reads them flat

DTO `SetSpkBoqRequest` (`ProjectTaskBoqsDto.cs:16-61`) is **flat**: one `boq_detail_id` + `unit_price` per `spk_boqs[]` row, documented as "One per row: unit_id, volume, unit_price and total_price above describe both the row and its draw from that line."

FE sends a nested array instead:

```json
"boq_details": [
  { "boq_detail_id": "a3a6d80f-…", "unit_id": "7e51efee-…",
    "volume": 10, "unit_price": 4166666.67, "total_price": 41666666.7 }
]
```

`boq_details` is not bound by any property → dropped silently. `boq_detail_id` and `unit_price` deserialize to `Guid.Empty` / `0` → the very next guard (`:294`) throws.

**Decide:** does a task BOQ row draw from exactly one contract BOQ line (keep flat, FE flattens), or from several (BE grows a `boq_details` collection + a sum check)? The nested shape the FE sends implies several — but it sent exactly one, so this may just be FE shape drift.

### M3 — row total vs detail total differ by 10×

| Field | Value |
|---|---|
| `spk_boqs[0].total_price` | `416,666,667` |
| `boq_details[0].total_price` | `41,666,666.7` |

The detail is self-consistent (`10 × 4,166,666.67 = 41,666,666.7`). The row total is 10× that. Not a BE bug — nothing validates the two against each other today — but whichever shape wins in M2, **add a guard** that the row total equals the sum of its draws, or this ships as silent money drift.

---

## 3. Note

`ProjectTaskBoqsDto.cs` / `ProjectTaskBoqsService.cs` / `IProjectTaskBoqsService.cs` all have **uncommitted local changes** on this branch (~178 insertions). Confirm the deployed `phantom-api.inproms.com` build against local `HEAD` before assuming the flat DTO above is what production is running.

---

## 4. Fix + tests

1. Settle M1 and M2 with the FE — this is a contract decision, not a BE-only fix.
2. Whichever shape wins, the guard for M3 ships with it.
3. Return **all** payload violations at once instead of throwing on the first. The current loop throws inside the `for`, so the FE round-trips once per bad field — three round-trips for this one payload.
4. Tests: valid payload; each guard tripped individually; row-total ≠ Σ details rejected; multi-violation payload reports every violation.

---

## 5. Resolved 2026-09-03

**M1 — settled as `inline`.** Live `project_task_boqs.type` holds only `inline` (346) and `custom` (4); no `item` row has ever persisted, so `item` is client drift, not a third variant. `NormalizeLegacyRow` now maps `item` → `inline` (case-insensitive) before validation.

**M2 — settled: FE is behind, BE keeps its shape.** `ReadReferencedBoqDetailIds` (`:762-768`) documents that the BE deliberately flattened and that nested `boq_details[]` is the pre-flattening form, kept only so stored drafts still parse. Rather than require an FE deploy, submit now lifts a single nested draw onto the row (`boq_detail_id` / `unit_id` / `unit_price`). More than one draw is **rejected, not truncated** — the write upserts one detail per row and soft-deletes the rest, so taking `[0]` would delete the others.

**M3 — guarded.** A row whose `total_price` disagrees with its nested draw's `total_price` is now rejected. Scoped to the nested path only, so the 346 existing flat submissions are untouched.

**Draft normalized to match.** `SaveProjectTaskBoqDraftAsync` applies the same two reshapes on the way in, on raw `JsonNode` rather than the typed DTO — a draft is a half-filled form, and round-tripping it through `SetSpkBoqRequest` would coerce absent fields to empty GUIDs and zero money and drop unmodelled fields. Reshape only: it never rejects. Already-canonical payloads are stored byte-for-byte.

**Header rows — reverted to the old behavior.** The relaxation was written and then pulled back the same day: a header that passed validation would have failed at persistence, turning a clean 400 into a 500. `ValidateRow` validates every row identically, so `type: "header"` is rejected by the type guard as before. Headers remain legal in a *draft* (stored as sent, re-derived on the draft GET) and illegal on submit.

**Bruno updated:** `bruno/collections/phi-phantom/ShortenFlowEndpoint/{Submit,Save as Draft} Project Task Boq.yml` — docs rewritten and 5 examples added: legacy nested shape, total mismatch 400, multi-draw 400, draft normalization, and a header row showing the 400 it returns.

---

## 6. KNOWN GAP — header rows validate but cannot be written

Deferred by decision on 2026-09-03, and validation was left at the OLD behavior so the gap fails loudly and cheaply: a header row is rejected with a 400 at validation rather than reaching persistence and 500-ing. Nothing in the request path accepts a header today.

When the relaxation is picked up again, it must land together with the persistence fix — not before. The three blockers are why:

Three blockers in the row-upsert loop of `SetProjectTaskBoqAsync`:

1. `DateTime.ParseExact(spkBoq.StartDate, DateFormat, …)` runs before any DB call. A header has no dates → `FormatException` → **500, not a clean 400**.
2. `project_task_boqs.unit_id` is `NOT NULL` **and** carries `FK_project_task_boqs_units_unit_id` (CASCADE) → `Guid.Empty` is an FK violation.
3. `volume`, `total_price`, `start_date`, `end_date` are all `NOT NULL`.

`boq_details.unit_id` is nullable, which is why headers work there. `project_task_boqs` never got that treatment, and the data agrees: zero rows with an empty unit or zero money.

**The two ways out, when this is picked up:**

- *Don't persist headers* — accept and drop them before the write; grouping stays a draft/client concern, and the draft GET already re-derives headers from the contract's `boq_details` via `SelectDraftRows`. No migration. Cost: a submitted task BOQ stores no grouping.
- *Migrate* — make `unit_id` / `start_date` / `end_date` / `volume` / `total_price` nullable, relax the entity to `Guid?` / `DateTime?`, guard the `ParseExact`, and make every reader of those five columns null-safe (`SpkBoqsService`, `SpkModificationsService`, `SpksService`, `ProjectTasksHelper`). Note the repo's known EF-migration snapshot drift.

**Applied interim:** validation keeps its original shape, so a header row 400s (`Unit is Required`, from the first guard it trips) instead of 500-ing on the date parse. The wording is not header-specific; if that proves confusing in practice, a named `spk_boqs[i].type must be 'inline' or 'custom'` check ahead of the unit guard would say it plainly.
