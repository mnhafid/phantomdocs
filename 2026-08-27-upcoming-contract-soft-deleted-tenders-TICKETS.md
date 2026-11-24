# Tickets: Upcoming Contract Lists Contracts of Deleted Tenders

Source: `2026-08-27-upcoming-contract-soft-deleted-tenders-FSD.md` (v0.1)
Coverage: 2 FRs / 2 NFRs → 2 tickets, all covered (FR-001, FR-002, NFR-001, NFR-002)

## Summary

| ID | Title | Epic | Size | Blocked by | Covers |
|---|---|---|---|---|---|
| T-01 | Exclude contracts of soft-deleted tenders from the Upcoming Contract list | E1 | S | — | FR-001, FR-002, NFR-001, NFR-002 |
| T-02 | Add a regression test for tender visibility in the Upcoming Contract list | E1 | S | F-4 (Tests project must compile) | FR-001, FR-002 |

## Epics

- **E1 — Upcoming Contract correctness:** the Upcoming Contract panel draws from the same tender population as Tender Monitoring.

---

## T-01: Exclude contracts of soft-deleted tenders from the Upcoming Contract list

- **Epic:** E1 · **Size:** S · **Priority:** Must · **Blocked by:** —
- **Covers:** FR-001, FR-002, NFR-001, NFR-002
- **Status:** Done — implemented on `feat/shortenflow`

**Context**

`GET /api/v1/contracts/upcoming` resolved a contract's owning tender by joining `tenders` directly and filtering only on department. Because `DeleteTenderAsync` soft-deletes just the parent row, `tender_contracts` has no `deleted_at` of its own, and neither entity has an EF global query filter, contracts of deleted tenders survived into the list — while Tender Monitoring, which routes through `TendersService.VisibleTenders()`, correctly hid them. See FSD §2.

**Scope of work**

- Add a private `VisibleTenders()` helper to `ContractsService`, mirroring `TendersService.VisibleTenders()`: `deleted_at IS NULL` then `WhereInDepartment(deptContext)`.
- Compose `GetUpcomingContractAsync`'s query against that helper instead of joining `phantomDbContext.Tenders` inline.
- Hoist the helper's result into a local before the lambda so EF composes it as a subquery rather than trying to translate a method call.
- Do not alter ordering, the six-row cap, the `contract_start_date >= today` filter, or the response DTO.

**Acceptance criteria**

- Given a tender contract with a future start date whose owning tender has `deleted_at` set, When a user in that tender's department requests the Upcoming Contract list, Then the contract is absent from the response.
- Given the equivalent contract whose owning tender is live, When the same user requests the list, Then the contract is present.
- Given a caller with no active department, When they request the list, Then the response contains zero rows.
- Given a caller scoped only to department A, When tender contracts exist under department B, Then none of B's contracts appear.
- Given the endpoint is called, When the SQL is inspected, Then both predicates appear in a single server-side `EXISTS` subquery.

**Out of scope**

- The summary card's `UpcomingContract` count and `GetAverageTenderDurationMonthsByTypeAsync` — same bug, deferred as FSD F-1 and F-2.
- Any change to the six-row cap or per-contract granularity (FSD §3, Q-1).

**Test notes**

- The row that exposes this in dev is `(material) Descc Contract 2`, start `2026-08-28`, tender `e4e559b4-faa9-442d-b476-a919d92843c9`, deleted `2026-08-20`. It is in department `Project`.
- **`R3TEST.indana` cannot reproduce this.** That account is scoped only to `Production Operations`, which has zero tenders, so both lists render empty. Verify with a `Project`-scoped account — `R3TEST.agil`, `R3TEST.rinaldy`, or `mk.super_admin`.
- Confirm the widget still fills to six rows where data allows: excluding a row should promote the next-earliest contract, not leave a gap.

---

## T-02: Add a regression test for tender visibility in the Upcoming Contract list

- **Epic:** E1 · **Size:** S · **Priority:** Should · **Blocked by:** F-4
- **Covers:** FR-001, FR-002

**Context**

T-01 was verified against the dev database with a throwaway harness because the `Tests` project does not compile (FSD F-4: 57 pre-existing errors from stale constructor and method signatures). Once that is unblocked, the behavior deserves a permanent test so the guard cannot silently regress.

**Scope of work**

- Seed two tenders in the same department, one soft-deleted, each with one future-dated tender contract.
- Assert `GetUpcomingContractAsync` returns only the live tender's contract.
- Assert a caller with no active department receives zero rows.
- Prefer a relational provider (SQLite, as in `AccessGrantScopeTests`) over the in-memory provider — the in-memory provider does not exercise SQL translation and would not catch a composition that falls back to client evaluation.

**Acceptance criteria**

- Given the seeded fixture, When `GetUpcomingContractAsync` runs, Then exactly one row returns and it belongs to the live tender.
- Given the caller has no active department, When the method runs, Then zero rows return.
- Given the test suite runs, When the guard is removed from `VisibleTenders()`, Then the test fails.

**Out of scope**

- Repairing the other ~12 broken test files. T-02 depends on that work but does not own it.

**Test notes**

- Do not use `dotnet test --no-build` to check this: a failed build combined with `--no-build` reports green from a stale `Tests.dll`. Check the build exit code first.

---

## Follow-ups (not in this delivery — raise separately)

| # | Title | Size | Rationale |
|---|---|---|---|
| F-1 | Apply the soft-delete guard to the monitoring summary's `UpcomingContract` count | S | Same defect, same screen: the count stays inflated after T-01, so the card and the list disagree. |
| F-2 | Apply the soft-delete guard to `GetAverageTenderDurationMonthsByTypeAsync` | S | Deleted tenders skew the averages that drive critical-contract detection. |
| F-3 | Consolidate `Project` vs `Projects` department values | M | 9 and 24 tenders respectively; a user scoped to one sees nothing from the other. Needs a data migration and a decision on the canonical value. |
| F-4 | Repair the `Tests` project build | M | 57 errors across ~12 files block all automated testing on this branch, including T-02. |

Once F-1 and F-2 land, all three call sites route through `VisibleTenders()` and the duplicated predicate is gone. A follow-on option, if the pattern keeps recurring, is an EF global query filter on `Tender` — deliberately not taken here because it silently changes every other call site at once.
