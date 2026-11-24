# Contract Currency (IDR/USD) Audit — Findings

**Date:** 2026-09-02
**Author:** digi.it.phi@gmail.com
**Scope:** Read-only investigation. No code changed by this audit.

Answers two questions:

1. Do contracts use IDR or USD, and what code is impacted?
2. If we add an explicit "is this contract USD?" check, how does that ripple into SA, SPK, BOQ, and Invoice — and which endpoints are affected?

---

## 1. Ground truth (queried live, dev DB `phantomdb`)

Connection string lives in `src-be/WebApi/appsettings.json` → `ConnectionStrings:PhantomDbConnection`. Read it from there; credentials are deliberately not reproduced in this document.

```
contracts.Currency   nvarchar(max), NULL-able, NO check constraint, free text
  IDR   208 rows   Σ 1.2496e14
  NULL    4 rows   Σ 4.0e9      -- "Contract Upload Bulk" drafts
  USD     1 row    Σ 150,000    -- contract_id 3fd6358a-2f66-4abf-9894-c00cfb7a8ea8
                                -- "USD13481745817325 / TEST CONTRACT USD", status approved
```

The one USD contract has **12 SPK rows** (Σ 158,333.46 USD), **0 SAs**, **0 invoices**. USD is therefore exercised *only* on the SPK / approval-route path today. SA + Invoice USD breakage is real but latent.

Facts that shape the fix — each verified, do not re-derive:

- `service_acceptances`: 46 rows, `cost_usd = 0` on **every** one.
- `invoices.currency` is a **`text`** column — cannot `GROUP BY`/compare without `CAST`. All 16 rows are `"idr"` **lowercase**, while `contracts.Currency` is `"IDR"` **uppercase**. Any equality check must be case-insensitive or it flags every historical row.
- `custom_configurations` name=`usd_rate` → `[{"key":"rate","value":"18000"}]`. Single global mutable value, **no effective date** — editing it retroactively changes which approval routes a past SPK qualified for.
- `custom_configurations` name=`contract_boq_tolerance` → `[{"Key":"tolerance","Value":1000}]`. **Absolute and unitless.**
- `contracts.sa_value` and `contracts.invoice_value` are `0` on all 213 rows. Nothing in this codebase writes them and there are **no DB triggers** on `contracts`/`spks`/`service_acceptances`/`invoices`. `spk_value` is populated on 40 rows. Treat sa_value/invoice_value as dead columns — an earlier draft of this analysis wrongly flagged their aggregation as a currency bug.
- 9 `approval_routes` rows have a non-null `spk_value_threshold`, so the USD conversion path is live.
- `stg_contract_pep` and `stg_contract_phss` are **empty**; `stg_service_acceptances` has 2 IDR rows.

---

## 2. The predicate

```csharp
static bool IsUsd(string? c) => string.Equals(c?.Trim(), "USD", StringComparison.OrdinalIgnoreCase);
```

Already exists inline, duplicated, at `ApprovalRoutesService.cs:760` and `SpkEsignService.cs:1038`. The duplication is deliberate — there is a code comment saying so. Don't "fix" it as part of this work.

---

## 3. Findings by module

Paths relative to `src-be/`.

### 3.1 Already correct — do not touch

| Location | Why it's fine |
|---|---|
| `Logics/Services/Spks/SpksService.cs:335`, `:2108` | SPK cumulative value vs contract value — both sides same currency |
| `SpksService.cs:825`, `:2696`, `:2973` | Remaining contract value — same |
| `SpksService.cs:355`, `:2029` | Passes `contract.Currency` into `ISpkEsignService.ValidateAndGetEsignRouteAsync`, which converts ×`usd_rate` for the threshold gate |
| `Logics/Services/ContractShares/ContractSharesService.cs:311,340` | Carries currency through, all values in it |
| Contract depletion-warning ratios | Same-currency percentages |

### 3.2 Wrong on production data *today*

- `Logics/Services/Contracts/ContractsService.cs:4918` — `MapContractCritical` hardcodes `Currency = "IDR"`. The USD contract renders 150,000 labelled IDR.
- `ContractsService.cs:3501-3531` — `Sum(ContractValue)` / `Sum(SpkValue)` with no currency grouping; USD 150,000 lands in a 1.25e14 IDR total.
- `ContractsService.cs:1497` — bulk xlsx import hardcodes `currency: "IDR"`. Template has no currency column (`TotalColumn = 18`, schema in `BuildImportColumnSchema()`).
- `ImportEngine/Feeding/FeedContracts.cs` — no currency mapping at all → fed contracts land NULL.
- **No validation anywhere** on `contracts.Currency`. `ContractsService.cs:2107` and `:2543` take `request.Currency` verbatim. `"Dollar"`, `"US$"`, `"Rp"` all silently fall through to IDR → 18,000× error on approval thresholds.

### 3.3 SA — the hard blocker

- `Logics/Services/ServiceAcceptances/ServiceAcceptanceRowValidator.cs:110-111` — `if (input.Currency != "IDR")` rejects the row. SA bulk import fails **100% of rows** for a USD contract. Note `!=` is case-sensitive.
- `ServiceAcceptancesService.cs:231-232`, `:289-297` — SA currency comes from `request.Currency`, never from the contract. Deriving it from the contract is the fix that makes the validator issue moot.
- `ServiceAcceptancesService.cs:75-76`, `:157-158` — `Cost = sa.CostIdr` while `Currency = CostUsd > 0 ? "USD" : "IDR"` → a USD SA displays **`0` labelled USD**.
- `:85` computes SA remaining from `CostIdr` alone; `:169` from `CostIdr + CostUsd`. Two formulas, one service.
- `:518` `TotalAmount = Sum(CostIdr)`; `:533` template hardcodes `"IDR"`.

### 3.4 BOQ — guard silently degrades

`Logics/Services/Boqs/BoqsService.cs:863-882` `ValidateBoqAmountAsync` compares BOQ item total against `contract.ContractValue ± 1000` (absolute).

| Contract | Effective tolerance |
|---|---|
| IDR 1e9 | ±0.0001% |
| USD 150,000 | ±0.67% — **~6,700× looser** |

Not a crash. A validation that stops validating.

**Fix needs no rate lookup** — BOQ total is already in contract currency, so making the tolerance a *percentage* of `ContractValue` fixes both currencies with the smallest diff.

### 3.5 Invoice — no link to the contract at all

- `Logics/Services/Invoices/InvoicesService.cs:375`, `:1351` — currency free-text from request, never derived from or checked against the contract.
- `InvoicesService.cs:1508` — `costForComparison = sa.CostIdr > 0 ? sa.CostIdr : sa.CostUsd`, then Paid/Partially-Paid from `invoicedTotal >= costForComparison`. No currency check on either side → an IDR invoice against a USD SA marks it **Paid** immediately.
- `Logics/Services/InvoiceRetentions/InvoiceRetentionsService.cs:101-102`, `:153` — hardcode `Currency = "IDR"` and read `sa.CostIdr` only → USD SA yields a retention row of 0.
- `InvoicesService.cs:1754-1756` — IDR fallback label; surrounding number format forces Indonesian separators unconditionally.

### 3.6 Export / presentation

- `SpksService.cs:2674` — `idrFormat = "\"Rp\" #,##0.00"` applied unconditionally to SPK Excel money cells.
- `SpksService.cs:2563` — header literal `"Physical Progress(IDR)"`.
- `Logics/Services/Spks/SpksDto.cs:896` — SPK responses expose `ContractValue` as a bare string with **no currency field**; FE has nothing to label with. Same gap in BOQ DTOs and `SpkBoqProgressService.cs:911`.

### 3.7 Currency-blind downstream (out of scope, worth a ticket)

`Logics/Services/Projects/ProjectsService.cs:716-738` sums `CostIdr` only then divides by `usd_rate`; `DashboardService.cs:83`; `ProjectSpendingPlansService.cs:485`. A USD SA's amount disappears from project cost entirely.

---

## 4. Endpoints impacted

Prefixes confirmed from `WebApi/Services/{Contracts,Spks,SpkBoqs,Boqs,ServiceAcceptances,Invoices,InvoiceRetentions,ApprovalRoutes}/*Endpoint*.cs`.

### Contracts — group `/api/v1`

| Endpoint | Impact |
|---|---|
| `POST /contracts`, `POST /contracts/{contractId}/update` | No currency validation |
| `GET /contracts/critical` | Hardcoded IDR — **wrong today** |
| `GET /contracts/summary-value`, `GET /contracts/total-contract` | Mixed-currency sums — **wrong today** |
| `GET /contracts/template` + bulk xlsx import | No currency column, hardcoded IDR |
| `GET /contracts`, `/contracts/all`, `/contracts/{id}`, `/contracts/{id}/detail`, `/contracts/export` | Currency already exposed |
| Depletion-warning routes | Safe, no change |

### SPK — group `/api/v1/spks`

| Endpoint | Impact |
|---|---|
| `GET /`, `/all`, `/{spkId}` | No `currency` in response |
| `POST /`, `POST /{spkId}`, `POST /various-wbs`, `POST /various-wbs/{spkId}` | Value check OK; echo currency back |
| `GET /export`, `GET /export/{spkId}` | `Rp` format + IDR header |
| `GET /total-spk`, `GET /monthly-summary` | Cross-currency aggregates |
| `POST /submit`, `/release`, `/approval` | Threshold conversion **already correct** |

### BOQ — groups `/api/v1/contracts` and `/api/v2/contracts`

| Endpoint | Impact |
|---|---|
| `POST /boqs/upload` | **Tolerance guard — the main one** |
| `GET /boqs`, `/boqs/{boqId}`, `/boqs/details`, `/boqs/details/all` | No currency |
| `GET /boqs/details/export`, `/boqs/details/export/{boqId}`, `GET /boqs/template` | Formatting |
| `/api/v1/spks/boqs` and `/grouped`, `/export`, `/{id}` | Inherits the SPK gap |

### SA — group `/api/v1/service-acceptances`

| Endpoint | Impact |
|---|---|
| `POST /upload` | **Rejects non-IDR rows — top blocker** |
| `POST /`, `POST /{id}/update` | Currency from request, not contract |
| `GET /`, `GET /{id}`, `GET /staging` | Cost/currency mismatch |
| `GET /eligible-for-invoice/{contractId}` | Feeds invoice creation unchecked |
| `GET /template` | Hardcoded IDR |

### Invoice — group `/api/v1`, `EndPoint = "invoices"`

| Endpoint | Impact |
|---|---|
| `POST /invoices`, `POST /invoices/{invoiceId}/update`, `POST /invoices/{invoiceId}` (delete) | All recompute SA status through `InvoicesService.cs:1508` |
| `GET /invoices`, `/invoices/all`, `/invoices/{invoiceId}`, `/invoices/{id}/export` | Currency labelling |
| `GET /invoices/retentions`, `/invoices/retentions/eligible-for-invoice`, `/invoices/retention-summary` | Hardcoded IDR + `CostIdr` only |

### Approval routes

`/api/v1/approval-routes`, `POST /approval-routes/spk-e-sign` — **already converts**. Listed for completeness.

---

## 5. Recommended order

**Status 2026-09-08 — this list is essentially DONE.** phi-dev moved ~55 commits after this audit was
written (2026-09-02) and picked up every numbered item below except one. Verified against
`phi-dev @ c4405781`:

| # | Item | State |
|---|---|---|
| 1 | SA import rejects non-IDR rows | **was still open** — fixed on `feat/usdcontract` (Luvus t34, uncommitted) |
| 2 | Currency validation on create/update | done — `ContractsService.NormalizeCurrency` throws on anything but IDR/USD |
| 3 | SA currency from the contract | done — `ServiceAcceptancesService.EnsureRequestCurrencyMatchesContract`, plus the read side (`Cost`/`SaRemaining`/`TotalAmount` all use `CostIdr + CostUsd`) |
| 4 | BOQ tolerance as a percentage | done in code — `BoqsService.ResolveTolerance` prefers a `tolerance_percent` key. **Config residue:** the absolute `tolerance` fallback stays live until every environment's `contract_boq_tolerance` row gets `tolerance_percent` |
| 5 | `currency` on SPK / BOQ / SA DTOs | done, incl. `SpkBoqProgressService` |
| 6 | The two hardcoded `"IDR"` literals | done |
| 7 | Export formatting | done — no `idrFormat` / `"Rp"` literal left in Spks, Boqs or Invoices |

PR #1091 (still shown OPEN on GitHub) contributed the SPK `currency` field, the
`/contracts/summary-value` and `/contracts/total-contract` USD conversion, and the SPK export
columns; its commit `02bc4d3d` is already an ancestor of phi-dev.

The original recommended order, for reference:

1. `ServiceAcceptanceRowValidator.cs:110-111` — unblocks SA import for USD contracts.
2. Currency validation on contract create/update — restrict to `IDR`/`USD` using existing `ApprovalRouteV2Constants.CurrencyIdr/CurrencyUsd`. Stops bad data at the door and removes the need for `?? "IDR"` fallbacks downstream.
3. Derive SA currency from the parent contract instead of accepting it in the request.
4. BOQ tolerance → percentage of `ContractValue`.
5. Add `currency` to SPK / BOQ / SA response DTOs.
6. `ContractsService.cs:4918` and `:1497` — replace the two `"IDR"` literals with the row's real currency (two-line diff, kills both live wrong-label bugs).
7. Export formatting (`Rp` format string, IDR headers) last.

**Explicitly deferred:**

- A currency-conversion layer for invoices and retentions — zero USD SAs and zero USD invoices exist. Revisit when the first one lands.
- Adding a currency column to the contract import template / `FeedContracts` — both staging tables are empty.

---

## 6. Gotchas for whoever implements this

- `invoices.currency` is `text` — `CAST(currency AS nvarchar(50))` before any `GROUP BY`/comparison, or SQL Server errors with msg 306.
- `sqlcmd` aborts the **entire batch** on a compile error (a wrong column name in the 3rd statement kills statements 1–2 too). Run one statement per `-Q`.
- The case mismatch between `contracts."IDR"` and `invoices."idr"` is real data, not a typo. Compare case-insensitively.
- Per `CLAUDE.md`, cognitive complexity ≤ 15 is a hard merge gate. `ContractsService.cs` and `SpksService.cs` are already very large — extract private helpers rather than growing existing methods.
- Both the validator change and the tolerance change are branch logic; each needs a test.
