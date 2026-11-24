# `contracts.usd_rate` — plan

**Goal:** a contract stores the USD→IDR rate it was created with, instead of every money
calculation reading one global `custom_configurations.usd_rate` row at the moment it happens to run.

**Why now:** today the rate is a single global value with no history. Change it and every past
number silently re-values — SPK weights, approval thresholds, contract cards. A contract signed at
15,000 and one signed at 18,000 are the same contract to the code. `weighted_project_task` on a
mixed-currency task is the first place this became visibly wrong.

**Source of the value:** `custom_configurations.usd_rate` stays. It stops being the value used in
calculations and becomes the **default offered at contract creation** and the **fallback for rows
that have no rate of their own**.

---

## Decisions

| # | Question | Decision | Why |
|---|---|---|---|
| D1 | Column type | `float NULL` on `contracts` | Matches `contract_value` (double). NULL is load-bearing — see D2. |
| D2 | Old contracts | Leave `usd_rate` NULL, read as `contract.UsdRate ?? globalRate` | Ships without a backfill and without changing a single stored number on day one. A backfill becomes optional, not a prerequisite. |
| D3 | IDR contracts | Snapshot the rate anyway | One less branch on write, and an IDR→USD currency edit later already has the signing-date rate. An unused number costs nothing. |
| D4 | Can it be edited? | Yes, on update, same guard as `currency` | Import typos exist. Changing it must trigger a recalculation — see Phase 3. |
| D5 | Who supplies it | Client may send it; if absent, the server snapshots the global config | Import files will not have the column at first, and the endpoint should not force callers to look the rate up themselves. |
| D6 | Where it appears in responses | Next to `currency`, **only where that `currency` came from `contracts.Currency`** | `invoices` and the service-acceptance staging tables have their own `currency` column with its own meaning. Shipping a contract rate beside them would be wrong. |

**D2 is the one that keeps this shippable.** Every read site becomes
`contract.UsdRate ?? globalRate`, so Phase 1 and 2 are pure additions and nothing moves until a
contract actually gets its own rate.

---

## Phase 1 — the column and the write paths

### 1.1 Schema

- `src-be/DataAccess/Entities/Contract.cs` — `public double? UsdRate { get; set; }` next to `Currency`.
- `src-be/DataAccess/DbContext/PhantomDb.Contract.cs` — **must** be mapped explicitly:

  ```csharp
  _ = entity.Property(e => e.UsdRate).HasColumnName("usd_rate");
  ```

  `Currency` gets away with no mapping only because SQL Server compares identifiers
  case-insensitively and `Currency` ≈ `currency`. `UsdRate` ≠ `usd_rate` — without the mapping EF
  looks for a column called `UsdRate` and the query fails at runtime, not at build.

- New EF migration `AddUsdRateToContracts`. Expect the usual spurious `permission_groups`/`TempId`
  diff in the snapshot — strip it from the migration body before committing.

### 1.2 Create — endpoint

`ContractsService.AddContractAsync` (`ContractsDto.cs:358` is the request's `currency`):

- `AddContractRequest.UsdRate` — `double?`, `[JsonPropertyName("usd_rate")]`.
- At the insert (`ContractsService.cs:2165`, beside `Currency = NormalizeCurrency(request.Currency)`):

  ```csharp
  UsdRate = request.UsdRate ?? await GetGlobalUsdRateAsync(cancellationToken),
  ```

- Validate with the same shape as `NormalizeCurrency`: a supplied rate must be `> 0`, otherwise
  reject. A zero or negative rate silently disables every conversion downstream.

### 1.3 Create — import

`ContractsService.cs:1375` already ends the template with the optional `Currency` column, and the
comment there says why: a file that stops earlier still imports. Do exactly the same thing again.

- Append `new() { ExcelColumnName = "USD Rate", DataType = "Number", DataFormat = "", IsMandatory = false }`
  **after** `Currency`.
- Parse it beside `strCurrency` (`ContractsService.cs:1496`–`1540`).
- Set it in `BuildImportedContract` (`ContractsService.cs:1630`, beside `Currency = currency`):
  blank cell → the global config value.
- Validate per row like `TryNormalizeCurrency` does (`ContractsService.cs:1747`): a bad rate fails
  **that row** in the report, never the whole file.

### 1.4 Update

`ContractsService.cs:2554`/`2602` — `ExecuteUpdate` chain, add `.SetProperty(c => c.UsdRate, usdRate)`
using the same `?? contract.UsdRate` keep-existing pattern `currency` uses.

### 1.5 One reader, not eleven

There are currently **ten** independent ways to read the rate: `UsdRateReader` plus private
`GetUsdRateAsync` copies in `ProjectsService`, `ProjectTasksService`, `ProjectSpendingPlansService`,
`DashboardService`, `ContractsService`, `ApprovalRoutesService`, `SpkEsignService`. They disagree on
type (`double` vs `decimal`), on JSON shape, and on failure — some return null and skip the
conversion, some throw. Adding a per-contract rate to ten call sites is where this goes wrong.

Consolidate first, on `UsdRateReader`:

```csharp
// unchanged - the global default and the fallback
static Task<double?> ReadAsync(PhantomDbContext db, CancellationToken ct);

// new - per contract, falling back to the global value (D2)
static Task<double?> ReadForContractAsync(PhantomDbContext db, Guid contractId, CancellationToken ct);

// new - the batch form. The hot paths already resolve a contract PER ROW; without this they
// would issue one query per line.
static Task<IReadOnlyDictionary<Guid, double?>> ReadByContractAsync(
    PhantomDbContext db, IReadOnlyCollection<Guid> contractIds, CancellationToken ct);
```

Delete the seven private copies in the same change. The two that deliberately **throw** when the
rate is missing (`ContractsService`, `ApprovalRoutesService`, `SpkEsignService`) keep that behaviour
at the call site, not inside the reader.

---

## Phase 2 — expose it beside `currency`

Rule from D6: ship `usd_rate` only where `currency` is read from `contracts.Currency`.

**Gets `usd_rate`** (the currency here *is* the contract's):

| Service | Site |
|---|---|
| Contracts | `ContractsService.cs:225`, `:736`, `:3461`, `:4318` |
| ContractShares | `ContractSharesService.cs:354` |
| ServiceAcceptances | `:116`, `:160`, `:244` (via `ServiceAcceptanceRowValidator.ExpectedCurrency`) |
| Spks | `SpksService.cs:1611`, `:2315`, `:3210`, `:3946` |
| SpkBoqProgress | `:998`, `:1133` |
| ProjectTasks | `ProjectTasksService.cs:2005` |
| ProjectTaskBoqs | `:131`, `:1381` |
| Boqs, SpkBoqs, RksGenerator, VendorAnalysis, SpkModifications | the `currency` fields in their DTOs, each traced back to its contract first |

**Does not get it:** `Invoices`, `InvoiceRetentions`, and the `Stg*` staging DTOs. Those rows carry
their own `currency` column; it is not the contract's field and a contract rate beside it would
invite exactly the wrong join.

`ImportRowValidationResult` (`ContractsDto.cs:1669`) echoes back what the file contained, so it
reports the rate **as supplied**, not the resolved fallback.

---

## Phase 3 — make the calculations use it

This is where behaviour actually changes, and it is the phase to hold back until Phases 1–2 are
live and contracts have real rates.

### 3.1 The one that is already wrong: SPK BoQ weights

`SpkBoqRecalculationService.RecalculateTaskBoqWeightsAndPlanAsync` reads **one** rate and applies it
to every USD line of the task:

```csharp
var usdRate = await UsdRateReader.ReadAsync(phantomDbContext, cancellationToken);
```

A task can draw from several contracts. Once rates are per contract, two USD lines from two
contracts must convert at two different rates. The query at `:134`–`:141` already joins
`boqs → contracts` and has `c.Currency` in hand — add `c.UsdRate` to the same projection and turn
`currencyMap` into a rate-and-currency map. No extra query.

```csharp
double ToBase(ProjectTaskBoq row) =>
    UsdRateReader.IsUsd(currencyOf(row)) && rateOf(row) is > 0
        ? row.TotalPrice * rateOf(row)!.Value
        : row.TotalPrice;
```

`POST /api/v1/spks/boqs/recalculate-weights` (already built) is the tool that re-writes stored
weights after a rate is set or corrected — that is also the answer to D4.

### 3.2 Everything else, in risk order

| Site | Per contract? | Note |
|---|---|---|
| `ApprovalRoutesService:765` | **Yes** | SPK approval threshold. Wrong rate = wrong approver. Highest blast radius of the lot. |
| `SpkEsignService:1723` | Yes | Printed on the signed document. |
| `ProjectTaskBoqsService:1006` | Yes | Submit guard vs `estimated_cost`. |
| `ProjectTasksService:1382` etc. | Yes | Task's contract. |
| `ContractsService:3601`/`:3667` | Yes | Summary cards — sum each contract at its own rate instead of bucketing then multiplying once. Bucket-then-multiply stops working the moment rates differ. |
| `VendorAnalysisService:654` | Yes | Per contract inside the vendor's year. |
| `ProjectsService:784`, `ProjectSpendingPlansService:496`, `DashboardService:14` | **No** | Project- and tenant-level totals spanning many contracts. Keep the global rate; there is no single contract to ask. Say so in a comment or someone will "fix" it later. |

---

## Old data

No backfill is required (D2). If you want one anyway, it is a single statement, and it is **not**
reversible in any meaningful sense:

```sql
UPDATE contracts SET usd_rate = <the rate those contracts were signed at>
WHERE usd_rate IS NULL AND created_at < '<cutoff>';
```

The honest position: nobody recorded the historical rate, so any backfill is a guess. Leaving NULL
says "we don't know, use today's rate" — which is what the code does today anyway. Prefer that.

---

## Tests

1. `AddContract` with no `usd_rate` → row stores the global config value.
2. `AddContract` with `usd_rate: 16500` → stores 16500, not the config value.
3. `AddContract` with `usd_rate: 0` / negative → rejected.
4. Import: file **without** the USD Rate column still imports (the D5/1.3 compatibility case).
5. Import: one bad rate cell fails that row only; the other rows import.
6. Read: a contract with `usd_rate = NULL` converts at the global rate — the D2 fallback, and the
   test that proves nothing moved on day one.
7. Weights: one task, two USD contracts, **different** rates → each line converts at its own rate.
   Extends `MultiSourceSpkTests.Weights_MixedCurrencyTask_ConvertsBeforeTakingTheShare`.
8. Approval route: the threshold is picked from the contract's rate, not the config.

---

## Out of scope

- Historical rate table (`usd_rate_history`, rate valid-from/valid-to). If per-contract turns out to
  be too coarse — a 3-year contract really does span rates — that is the next design, not this one.
- Currencies other than USD/IDR. `TryNormalizeCurrency` still admits exactly two.
- Re-valuing anything already stored. Existing `spk_value`, `contract_value`, `weighted_*` numbers
  stay as written until something recalculates them on its own terms.
