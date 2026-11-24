# FSD: BOQ Details Export v2, keyed by contract

| | |
|---|---|
| **Type** | Feature specification (no PRD — see §1) |
| **Status** | Specified, not implemented |
| **Date** | 2026-09-02 |
| **Version** | 0.1 |
| **Branch** | `feat/shortenflow` |
| **Scope** | One additive read-only endpoint. No v1 route changes, no schema changes. |

## 1. Why there is no PRD

The "why" is one sentence: the round-trip BOQ spreadsheet can only be fetched by `boq_id`, but every caller in the shorten-flow wizard holds a `contract_id`, so the FE has to resolve the contract's active BOQ itself before it can download anything. There is no product decision to argue and no competing option worth a goals section, so this document carries the requirements directly.

An import counterpart was discussed and **explicitly deferred** — see §7.

## 2. Today

Two export routes exist, and they do not produce the same file:

| | `GET /api/v1/contracts/boqs/details/export/{boqId}` | `GET /api/v1/contracts/boqs/details/export?contract_id=` |
|---|---|---|
| Handler | `ExportBoqDetailsByBoqId` (`BoqsEndpoint.cs:455`) | `ExportBoqDetails` (`BoqsEndpoint.cs:460`) |
| Service | `ExportBoqDetailsByBoqIdAsync` (`BoqsService.cs:361`) | `ExportBoqDetailsAsync` (`BoqsService.cs:329`) |
| Columns | 13 — carries `ID`, plus blank `Start Date`/`End Date`/`Volume`/`Remarks` | 9 — read-only reporting layout |
| Keyed by | BOQ | contract |
| Purpose | fill in offline, re-import | report |

So the fill-in template is reachable only by `boq_id`, and the contract-keyed route emits the wrong layout. `BoqsEndpoint.cs:27` records the current position explicitly: *"the export routes stay v1-only."* This FSD changes that.

`/api/v2/contracts` already exists as a route group (`BoqsEndpoint.cs:29`) carrying the same tags and the same `R3ComponentFilter`, and v2 reuses v1 paths verbatim rather than renaming them.

## 2.1 Verified against a real export

`BoQ_2026-09-02 11.38.18 - PT Delta Force .xlsx`, supplied by the requester, unpacked and read directly. It contains exactly the five zip entries `SimpleXlsxWriter` produces — no `sharedStrings.xml`, no `styles.xml` — confirming it came from `ExportBoqDetailsByBoqIdAsync`. Sheet name `BOQ Details`, 1 header row, 4 data rows:

| ID | Type | Origin | Breakdown | Description | Kind | Unit Price | Unit |
|---|---|---|---|---|---|---|---|
| `02c58264…` | item | 1 | `TRBL.1.` | A. PEKERJAAN PERSIAPAN DAN ADMINISTRASI | Upah | 4166666.67 | Doc |
| `cadb0c34…` | item | 1 | `TRBL.1.` | A. PEKERJAAN PERSIAPAN DAN ADMINISTRASI | Material | 4166666.67 | Doc |
| `ebcc099f…` | item | 1 | `TRBL.1.` | A. PEKERJAAN PERSIAPAN DAN ADMINISTRASI | Sewa Alat | 4166666.67 | Doc |
| `00ded1fd…` | item | 1 | `TRBL.1.` | A. PEKERJAAN PERSIAPAN DAN ADMINISTRASI | Transport | 4166666.67 | Doc |

Three facts this pins down, each of which changes a requirement below:

1. **`breakdown` is not unique.** All four rows share `TRBL.1.` and the same `description`, differing only in `kind`. Any rule that identifies a row by code alone is wrong. This is why the existing upsert key is `(project_task_id, code, description, kind)` and not `(project_task_id, code)`.
2. **A flat BOQ is normal, not an anomaly.** This one has no `data_type = header` row at all, and the upload rule explains why. `BuildBoqTypeNDetails` (`BoqsService.cs:1976`) emits a header only for a source row with **no unit and zero quantity**; any other row fans out into one `item` per non-zero money field via `AddMoneyFieldDetails`. The sample's source row carried a unit (`Doc`) and a quantity, so it produced four `item` rows — one per kind — and no header.

   Consequences: a BOQ whose every source row has a unit is entirely header-less, `parent_id` is `""` on all of its rows, and FR-004's inclusion of headers changes nothing for it. FR-004 still stands, because hierarchical BOQs do exist (`TBL.1.` → `TBL.1.1.` → `TBL.1.1.1.` in `BoqParentAndDraftContractTests`) — it is simply not exercised by this sample. Both shapes must be tested.
3. **Numeric cells already work.** `Origin` and `Unit Price` are written as bare `<v>` cells, not inline strings. See NFR-001, which this corrects.

The last four columns — `Start Date`, `End Date`, `Volume`, `Remarks` — are empty on all four rows, as expected for an export taken with no task in context.

## 3. Functional requirements

### FR-001 — Route

The system must expose `GET /api/v2/contracts/boqs/details/export`, registered inside the existing `groupV2` in `MapBoqs`, so it inherits the group's tags and `R3ComponentFilter` authorization with no per-route auth code.

The v1 export routes are untouched: same paths, same handlers, same output, same 13- and 9-column layouts.

### FR-002 — `contract_id` is required

`contract_id` is a required query parameter. A request that omits it, or sends it empty or unparseable as a GUID, is rejected with `400` and the message `contract_id is required`. Nothing is generated.

### FR-003 — Contract resolves to one BOQ

The contract's BOQ is resolved by the rule `BuildBoqDetailQuery` already implements (`BoqsService.cs:994`): among `boqs` rows for that contract where `is_active = 1` and `deleted_at is null`, take the highest `version`. One BOQ, never several.

This rule is reused, not reimplemented. A second implementation is a defect — v2 list and v2 export must never disagree about which BOQ a contract means.

### FR-004 — Row set: headers and items, in `Order`

Every `boq_detail` of the resolved BOQ appears in the sheet, both `data_type = header` and `data_type = item` rows, ordered by `Order` ascending.

Headers are included specifically so `parent_id` (FR-007) always names a row that is present in the same file, letting the reader rebuild the tree without a second call.

### FR-005 — Columns

The sheet carries exactly these 14 columns, in this order:

| # | Column | Source |
|---|---|---|
| 1 | `id` | `boq_details.id` |
| 2 | `boq_id` | `boq_details.boq_id` |
| 3 | `data_type` | `boq_details.data_type` |
| 4 | `breakdown` | `boq_details.code` |
| 5 | `description` | `boq_details.description` |
| 6 | `kind` | `boq_details.kind` |
| 7 | `start_date` | task selection (FR-008) |
| 8 | `end_date` | task selection (FR-008) |
| 9 | `volume` | task selection (FR-008) |
| 10 | `unit_price` | `boq_details.unit_price`, item rows only (FR-006) |
| 11 | `unit_id` | `units.id` via the existing `GroupJoin`, item rows only |
| 12 | `unit_name` | `units.name` |
| 13 | `remark` | `boq_details.remark` |
| 14 | `parent_id` | computed (FR-007) |

`quantity`, `total` and `is_selected` are deliberately **not** columns, even though `BoqDetailV2Dto` carries them.

`origin_number` is also **not** a column, which is a deliberate departure from the v1 template: the sample in §2.1 carries an `Origin` column and the requester's field list does not. v2 drops it because `parent_id` supersedes it for reconstructing the tree. Flagged as the one place where v2 removes something v1 emitted — if `Origin` is load-bearing for a consumer, this is the requirement to reopen.

The worksheet is named `BOQ Details`, matching v1.

### FR-006 — Header rows leave the price columns blank

On a row where `data_type` is not `item`, `unit_price` and `unit_id` are written as empty strings rather than as values. This follows the convention already in `ExportBoqDetailsByBoqIdAsync`, which gates both behind `isItem`.

`unit_name` is not gated — it is written whenever the join produced one, matching the v1 template.

### FR-007 — `parent_id`

`parent_id` is the id of the header exactly one breakdown segment up, and the empty string when the row has no parent. It is produced by the existing `ApplyParentIdsAsync` (`BoqsService.cs:1045`), reached through the shared `IBoqDetailRow` interface.

This rule is reused, not reimplemented — `IBoqDetailRow`'s own doc comment states that a second implementation of the `parent_id` rule is a defect, because v1 and v2 must agree.

### FR-008 — `project_task_id` fills the three planning columns

`project_task_id` is an optional query parameter.

**When supplied and parseable**, `start_date`, `end_date` and `volume` are filled for every row that the task already draws on, and left blank for every row it does not. The values come from the join `project_task_boq_details` → `project_task_boqs` on `project_task_boq_id`, filtered to `project_task_id` with `deleted_at is null` on both sides, keyed by `boq_detail_id`:

- `start_date` ← `project_task_boqs.start_date`
- `end_date` ← `project_task_boqs.end_date`
- `volume` ← `project_task_boq_details.volume`

`BuildTaskSelectionAsync` (`BoqsService.cs:1120`) already performs this join for the two date fields; it is extended to carry `volume` alongside them rather than a second join being written.

**When absent, empty, or unparseable**, all three columns are blank on every row and no selection query runs. The result is a fresh fill-in template.

### FR-009 — `project_task_id` binds as a string

`project_task_id` is bound as `string?`, never as `Guid?`. The FE sends `project_task_id=` with an empty value when no task is in context, and minimal-API binding turns an empty value for a `Guid?` into a `BadHttpRequestException` surfacing as a 500. `BoqDetailFilter.ProjectTaskId` already carries this decision and its explanatory comment; the v2 export inherits it.

An unparseable value is treated as absent (FR-008), not as an error.

### FR-010 — Contract with no active BOQ

A `contract_id` that resolves to no active BOQ returns `200` with a header-only sheet: the 14 column headers and zero data rows. It is not a `404`.

This matches the list endpoints, which return an empty page rather than an error for the same condition.

> **Known ambiguity, accepted.** A contract with no BOQ and a contract whose BOQ has no rows produce byte-identical files, so the caller cannot distinguish them. Accepted because no caller currently needs to. If one does, `404` on unresolved contract is the smaller change than adding a status envelope to a file download.

### FR-011 — Filename

The response is an xlsx attachment named `BOQ-{contract_id}.xlsx`, mirroring the v1 `BOQ-{boqId}.xlsx`. Content type and the attachment header come from the existing `ExecuteExportAsync` helper.

### FR-012 — Unrecognized query parameters are ignored

The endpoint reads `contract_id` and `project_task_id` and ignores everything else, including `sort_column` and `sort_order`.

It does **not** reuse `RejectSortParameters`. That 400 exists on the two v2 *list* routes because sorting was a meaningful v1 list parameter that v2 dropped; export has never sorted by anything but `Order`, so there is no expectation to correct and nothing for a caller to be surprised by.

## 4. Non-functional requirements

### NFR-001 — Cell typing is the writer's, and is left alone

`SimpleXlsxWriter.Generate` takes `IEnumerable<string[]>`, but it does **not** write every cell as text. `BuildSheet` (`src-base/Shared/Helpers/SimpleXlsxWriter.cs:92`) tests each value with `long.TryParse || double.TryParse` and emits a bare numeric `<v>` cell when either succeeds, falling back to `t="inlineStr"` otherwise.

Verified against the sample in §2.1: `unit_price` lands as `<c r="G2"><v>4166666.67</v></c>` — a real number in Excel, with no work required. So `unit_price` and `volume` are numeric for free, and no change to the writer is needed or wanted.

Dates are unaffected: `13-08-2026` fails both parses and stays an inline string.

> **Hazard, inherited not introduced.** The same auto-detection applies to `breakdown`. A code that happens to be numeric — `1`, or `1.10` — becomes a numeric cell, and `1.10` renders as `1.1`. Every code seen in practice carries a alpha prefix and a trailing dot (`TRBL.1.`), so none are affected today, and this FSD does not change the behaviour. Flagged because the deferred importer matches rows on `breakdown`, where a silently reformatted code would fail to match. Two further notes on the same line: `double.TryParse` is called without `CultureInfo.InvariantCulture`, so its behaviour is server-locale dependent, and `EscapeXml` is applied to values already committed to a numeric cell.

### NFR-002 — Date format

Dates are formatted with the existing `BoqDetailDateFormat` constant, `dd-MM-yyyy` (`BoqsService.cs:38`) — the same constant the v1 and v2 JSON list endpoints use for these two fields.

The v1 template's `Start Date (DD/MM/YYYY)` header disagrees with the format the rest of the system parses and writes; v2 does not carry that inconsistency forward.

### NFR-003 — One pass over the data

The export issues a bounded number of queries regardless of row count: one for the details (with the existing unit `GroupJoin`), one for `parent_id`, and one for the task selection when `project_task_id` is supplied. No per-row query.

## 5. Test coverage

| Test | Asserts |
|---|---|
| `Export_ResolvesActiveBoqForContract` | contract with two BOQ versions exports only the highest active one |
| `Export_IncludesHeaderAndItemRows` | both `data_type`s present, ordered by `Order` |
| `Export_ParentIdReferencesRowInSheet` | every non-empty `parent_id` matches an `id` in the same sheet |
| `Export_HeaderRowsHaveBlankPriceColumns` | `unit_price` and `unit_id` empty on header rows |
| `Export_FlatBoqWithNoHeaders_ParentIdsAllEmpty` | the §2.1 shape: 4 items sharing one code, no header row, `parent_id` empty throughout |
| `Export_RowsSharingACodeAreAllPresent` | 4 rows with identical `breakdown`+`description` differing only by `kind` all survive to the sheet |
| `Export_UnitPriceIsANumericCell` | `unit_price` emitted as `<v>`, not `t="inlineStr"` (NFR-001) |
| `Export_WithoutProjectTaskId_LeavesPlanningColumnsBlank` | `start_date`/`end_date`/`volume` blank on all rows |
| `Export_WithProjectTaskId_FillsSelectedRowsOnly` | selected rows carry all three, unselected rows blank |
| `Export_EmptyProjectTaskId_DoesNotThrow` | `project_task_id=` binds and behaves as absent (FR-009) |
| `Export_MissingContractId_Returns400` | 400, nothing generated |
| `Export_ContractWithNoActiveBoq_ReturnsHeaderOnlySheet` | 200, headers, zero data rows |
| `Export_V1RoutesUnchanged` | v1 13-column and 9-column outputs byte-identical to before |

## 6. Traceability

All twelve FRs and three NFRs are covered by a single ticket — see §8. The feature is one endpoint and does not decompose into independently shippable slices.

## 7. Non-goals

- **No import/upload endpoint.** An xlsx importer keyed by `contract_id` was specified up to the point of the write path and then deferred by the requester. The open questions it stalled on are recorded in §9 so the next round does not re-derive them.
- **No change to any v1 route.** Both v1 export routes keep their paths, handlers, column layouts and byte output.
- **No multi-BOQ or multi-sheet output.** One contract resolves to one BOQ (FR-003) and one worksheet.
- **No typed cells** (NFR-001) and no change to `SimpleXlsxWriter`.
- **No new columns on `boq_details`** and no schema change of any kind.

## 8. Ticket

One Luvus task — see §6. Paths: `src-be/WebApi/Services/Boqs/**`, `src-be/Logics/Services/Boqs/**`, `src-be/Tests/**`.

## 9. Deferred: the import counterpart

Recorded so the deferred work restarts from here rather than from scratch. The existing write path is `SetProjectTaskBoqAsync` (`ProjectTaskBoqsService.cs:267`). Four questions were open when import was dropped:

1. **Replace or merge.** Submit is full-replace: it soft-deletes every `project_task_boq` for the task that was not in the payload (`:424-435`). An import that copies this wipes 47 lines when a 3-row file is uploaded onto a 50-line task. An import that does not means import and submit disagree about what a payload means.
2. **Side-effects.** Submit also runs `UPDATE project_tasks SET contract_id` (`:441`) and `DELETE FROM project_task_boq_drafts` (`:453`), both in the same transaction. Unclear whether an upload should carry both, one, or neither.
3. **`type` and price authority.** The write path requires `type ∈ {inline, custom}` per line (`:281`); the 14-column sheet has no `type` column, so import must hard-code it or the export must grow one. Separately: whether an edited `unit_price` cell should take effect, or the contract's price wins.
4. **Date parsing.** `SetProjectTaskBoqAsync` parses `dd-MM-yyyy` (`ProjectTaskBoqsService.cs:21`). NFR-002 makes the v2 export write the same, so a v2-exported file round-trips; a hand-made file using slashes would not.

The requester's answers before the deferral were: multipart xlsx with its own write path into `project_task_boqs` (not routed through `SetProjectTaskBoqAsync`), and all-or-nothing validation returning `400` with per-row errors and no partial write.
