# FSD: Upcoming Contract Lists Contracts of Deleted Tenders

| | |
|---|---|
| **Type** | Defect specification (no PRD — see §1) |
| **Status** | Implemented, pending QA verification |
| **Date** | 2026-08-27 |
| **Version** | 0.1 |
| **Branch** | `feat/shortenflow` |
| **Severity** | Medium — stale rows in a monitoring widget; no data loss |
| **Source ticket** | `[Medium] [BE] [Hafid] [Upcoming Contract] - List pada upcoming contract belum sesuai` |

## 1. Why there is no PRD

The "why" is one sentence: the Upcoming Contract panel shows contracts belonging to tenders that were deleted, so it disagrees with the Tender Monitoring list. There is no product decision to make and no non-goal worth arguing, so this document carries the requirements directly.

## 2. Defect

**Observed.** `GET /api/v1/contracts/upcoming` returns tender contracts whose owning tender has been soft-deleted. Those same tenders are absent from the Tender Monitoring list, so the two screens disagree.

**Expected.** The Upcoming Contract list draws from the same population of tenders as the Tender menu: live tenders inside the caller's active departments.

**Root cause.** `GetUpcomingContractAsync` resolved contract ownership by joining `tenders` directly, filtering on department but never on `deleted_at`:

```csharp
.Where(tc => deptContext.HasAnyDepartment && phantomDbContext.Tenders
    .Any(t => t.Id == tc.TenderId && deptContext.ActiveDepartments.Contains(t.DepartmentId)));
```

Three facts make this leak:

1. `DeleteTenderAsync` soft-deletes **only the parent tender row** — it stamps `tenders.deleted_at` and touches no child.
2. `tender_contracts` has **no `deleted_at` column of its own**, so the parent's flag is the only thing that can hide a child.
3. Neither `Tender` nor `TenderContract` has an EF **global query filter**, so nothing supplies the guard implicitly.

The Tender Monitoring list does not leak because it routes through `TendersService.VisibleTenders()`, which applies `t.DeletedAt == null` before the department filter.

**Evidence (dev DB, 2026-08-27).** For a caller scoped to department `Project`:

| Query | Rows |
|---|---|
| As shipped | 3 |
| With the soft-delete guard | 2 |

The extra row is `(material) Descc Contract 2` (start `2026-08-28`), owned by tender `e4e559b4-faa9-442d-b476-a919d92843c9`, soft-deleted `2026-08-20 09:04:30`. It sorts second by start date, so it lands well inside the widget's six-row window.

## 3. Scope

**In scope.** The Upcoming Contract **list** endpoint only: `GET /api/v1/contracts/upcoming` → `ContractsService.GetUpcomingContractAsync`.

**Out of scope** (deliberate — see §8 for follow-ups):

- The `UpcomingContract` **count** on the monitoring summary card, which carries the same defect.
- `GetAverageTenderDurationMonthsByTypeAsync`, which carries the same defect.
- Adding a `deleted_at` column to `tender_contracts`.
- The widget's six-row cap, its future-start-date filter, and its one-row-per-contract granularity. These are intended behavior and are **not** defects, even though they also make the two lists non-identical (§11).
- Consolidating the `Project` / `Projects` department values in dev data.

## 4. Functional Requirements

### FR-001: Exclude contracts of soft-deleted tenders

- **Traces to:** §2
- **Priority:** Must
- **Description:** The system shall omit a tender contract from the Upcoming Contract list when its owning tender has a non-null `deleted_at`.
- **Trigger / Input:** `GET /api/v1/contracts/upcoming`, optional `search` query parameter.
- **Behavior:** Ownership resolves through the caller's visible-tender set — tenders that are both not soft-deleted and inside the caller's active departments. Ordering (`contract_start_date` ascending), the six-row cap, and the `contract_start_date >= today` filter are unchanged.
- **Validation & Errors:** No new error paths. The endpoint's status codes and payload shape are unchanged.
- **Edge cases:**
  - Owning tender soft-deleted → the contract is omitted.
  - Owning tender deleted *after* the contract's start date passed → already excluded by the date filter; no interaction.
  - A tender contract whose `tender_id` matches no tender row → omitted (`EXISTS` fails), as before.
  - Excluding a row promotes the next-earliest contract into the six-row window, so the widget stays full where data allows.
- **Acceptance criteria:**
  - Given a tender contract with a future start date whose owning tender has `deleted_at` set, When a user in that tender's department requests the Upcoming Contract list, Then the contract is absent from the response.
  - Given the equivalent contract whose owning tender is live, When the same user requests the list, Then the contract is present.
  - Given both rows exist, When the user compares the Upcoming Contract list against Tender Monitoring, Then every tender represented in the Upcoming Contract list also appears in the Tender list.

### FR-002: Preserve department scoping and fail-closed behavior

- **Traces to:** §2
- **Priority:** Must
- **Description:** The system shall continue to restrict the Upcoming Contract list to the caller's active departments, and shall return no rows when the caller holds none.
- **Behavior:** The department predicate is unchanged in meaning. It moves from an inline expression into the shared `WhereInDepartment` helper, which short-circuits to zero rows when the caller has no active department.
- **Edge cases:** A tender with a null `department_id` matches nobody, as before.
- **Acceptance criteria:**
  - Given a caller with no active department, When they request the Upcoming Contract list, Then the response contains zero rows.
  - Given a caller scoped only to department A, When tender contracts exist under department B, Then none of B's contracts appear in the response.

## 5. Data Model

No schema change. Relevant existing shape:

| Table | Column | Note |
|---|---|---|
| `tenders` | `deleted_at` (nullable) | The only soft-delete marker in this relationship. Set by `DeleteTenderAsync`. |
| `tenders` | `department_id` | Ownership axis; child tables carry no department column. |
| `tender_contracts` | `tender_id` | FK to `tenders`. No `deleted_at` column on this table. |

## 6. Interfaces

No interface change. `GET /api/v1/contracts/upcoming` keeps its route, query parameters, auth, status codes, and `UpcomingContractDto` shape. Only the set of rows returned narrows. No Bruno collection regeneration is required.

## 7. Non-Functional Requirements

### NFR-001: The filter stays server-side
- **Requirement:** The soft-delete and department predicates must translate to SQL and execute in one round trip, with no client-side evaluation.
- **Traces to:** FR-001, FR-002
- **Verified:** EF Core emits a single `EXISTS` subquery carrying both predicates — see §9.

### NFR-002: No API contract change
- **Requirement:** Response shape, status codes, and field semantics are unchanged, so no frontend change is required.
- **Traces to:** FR-001

## 8. Follow-ups deliberately excluded

Recorded here so they are not lost. Each needs its own ticket.

| # | Issue | Why deferred |
|---|---|---|
| F-1 | `ContractsService.cs` summary card: the `UpcomingContract` **count** uses the same unguarded join, so the number is inflated by deleted tenders even after this fix. | Scope was set to the list endpoint only. |
| F-2 | `GetAverageTenderDurationMonthsByTypeAsync` uses the same unguarded join, so deleted tenders skew the averages feeding critical-contract detection. | Same. |
| F-3 | Dev data holds both `Project` (9 tenders) and `Projects` (24) as department values. A user scoped to one sees nothing from the other. | Data hygiene, not caused by this code path. |
| F-4 | The `Tests` project does not compile — 57 pre-existing errors from stale constructor and method signatures across ~12 files. This blocked adding an automated regression test for FR-001. | Pre-existing on this branch and far wider than this defect. |

## 9. Verification

The `Tests` project cannot build (F-4), so the fix was verified against the dev database with a throwaway harness replicating the patched query composition verbatim.

**Translation (NFR-001).** EF Core produced a single server-side statement:

```sql
WHERE [t].[contract_start_date] IS NOT NULL AND [t].[contract_start_date] >= @__today_0 AND EXISTS (
    SELECT 1 FROM [tenders] AS [t0]
    WHERE [t0].[deleted_at] IS NULL
      AND [t0].[department_id] IN (SELECT [a].[value] FROM OPENJSON(@__activeDepts_1) ...)
      AND [t0].[id] = [t].[tender_id])
```

**Behavior.**

| Check | Result |
|---|---|
| FR-001 — deleted tender excluded | PASS — 3 rows before, 2 after; the dropped row is `(material) Descc Contract 2` |
| FR-002 — fail closed, no active department | PASS — 0 rows |
| FR-002 — cross-department isolation | PASS — `Operation & Surface Facilities` returns 5 rows, disjoint from `Project`'s 2 |

## 10. Traceability Matrix

| Defect | FRs | NFRs | Ticket |
|---|---|---|---|
| §2 — deleted tenders leak into Upcoming Contract | FR-001 | NFR-001, NFR-002 | T-01 |
| §2 — scoping must not regress | FR-002 | NFR-001 | T-01, T-02 |

## 11. Open Questions

| # | Question | Owner |
|---|---|---|
| Q-1 | After this fix the two lists still differ by design: Upcoming Contract is capped at six rows, shows only future start dates, and is one row per *contract* while Tender Monitoring is one row per *tender*. Does QA accept these, or is "sesuai dengan list tender" meant literally? | QA / PO |
| Q-2 | Should F-1 and F-2 ship in the same release, given they are the same bug on the same screen? | Hafid |
