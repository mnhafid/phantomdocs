# Plan — enforce Well / EUR / Unit Conversion endpoints by privilege (Go-style RBAC)

> **DECISION 2026-10-15 (owner): DEFERRED.** Backend route enforcement is NOT implemented now. The PHSS / PEP
> privileges (153–156) are guarded on the **frontend**: the FE reads `GET /api/v1/users/permissions` and
> hides / disables PHSS and PEP screens and actions by privilege id. The backend keeps today's protection:
> authentication + the department working-area guard (`R3ComponentFilter.RequestsOtherWorkingArea`, 404 on
> the other area's URL). This plan stays as the reference for a later implementation.
> - Rejected for the later implementation: (a) substituting `{type}` / `{workingarea}` inside the check,
>   (b) letting `{type}` routes fall back to the shared 137 / 139. If enforced later, the ~15 `{type}` routes
>   are split in code into separate `/phss/` and `/pep/` routes, so the existing route table finds 153–156.

| | |
|---|---|
| **Date** | 2026-10-15 |
| **Branch** | `feat/rbac-phss-pep-privileges` (`.worktrees/rbac-phss-pep`, from phi-dev 8a5da086) |
| **Builds on** | migration `20261014090000_SeedPhssPepPrivileges`, `seed_rbac_phss_pep_privileges.sql`, `retina_phss_pep_roles.oracle.sql` (staged) |
| **Source of truth** | Google Sheet "Phantom PHI Mapping" rows 185–274 (Well / EUR) + 326–327 (Unit Conversion) |

## Goal

Every Well / EUR / Unit Conversion request is allowed only when the caller's Retina ACL holds the
privilege the sheet assigns — exactly like the Go evaluator: View = GET, Modify = POST.

| Area | View (GET) | Modify (POST) |
|---|---|---|
| PHSS (`phss` in the path) | 153 | 154 |
| PEP (`pep` in the path) | 155 | 156 |
| Shared well routes | 137 | 139 |
| EUR | 140 | 138 |
| Unit Conversion | 157 | 158 |

## What already exists (reuse, do not rebuild)

| Piece | Behaviour |
|---|---|
| `RbacRouteMaps.Map` | POST/PUT/DELETE/PATCH: exact `(method, RoutePattern.RawText)` → `(obj, act)` |
| `RbacRouteMaps.ReadRoots` | GET/HEAD: nearest ancestor path → act (longest prefix wins) |
| `RbacRouteMaps.PublicRoutes` | Pass-through routes |
| `RbacLegacyRouteFilter` + `.RequirePermissionLegacyFromMap()` | Per request: no session 401 → unclassified 403 → act ∉ Retina ACL 403 → Retina down 503 |
| `RbacRouteMapValidator` | Boot check: CONFLICT / ORPHAN / UNCLASSIFIED → app fails to start |
| `IRetinaAclCacheService` | The ACL seq set (same source as `/users/permissions`) |

Only Custom Configurations is opted in today (3 Map entries, 1 read root).

## Gaps to close

1. **`{type}` / `{workingarea}` routes** — keys are templates (`/wells/{type}/histories/chart`), but the
   act depends on the request value (`phss` → 153, `pep` → 155). A static key cannot express it.
2. **Validator** — literal `…/phss/…` keys would be ORPHAN (no endpoint has that RawText) and the
   `{type}` POST endpoints UNCLASSIFIED.
3. **No kill switch** — opting in is code; a wrong grant means 403s until a redeploy.
4. **Code ≠ sheet** — routes in code but not in the sheet, plus debug/job routes inside the same groups.
5. **Lockout** — enforcement checks Retina; roles that use wells today hold 137/139 but not 153–156.

## Tasks (dependency order)

### T1 — Working-area substitution (filter)  · S
`RbacLegacyRouteFilter`: before the lookup, if the RawText has a `{type…}`, `{workingarea…}` or
`{workingArea…}` segment AND the request's route value for it is `phss` / `pep` (case-insensitive),
replace that segment with the lowercase value. Otherwise leave the RawText as is (e.g.
`/well-surveillance/dropdowns/{type}` where `type` is a dropdown category → stays shared).
Extract as `RbacRouteMaps.ExpandWorkingArea(rawText, routeValues)` so filter, validator and tests share it.
- Tests: `phss` → 153 path, `pep` → 155 path, `PHSS` upper-case, unknown value unchanged, dropdown unchanged.

### T2 — Validator understands expansion  · S
For an opted-in endpoint whose RawText has a working-area segment, check BOTH expansions (`phss`,
`pep`) for classification, and count both as "used" for ORPHAN detection.
- Tests: a `{type}` POST with only the phss Map entry → UNCLASSIFIED (pep missing); both present → OK.

### T3 — Feature flag with shadow mode  · S
`Permissions:RouteRbac:Mode` = `Off` | `Shadow` | `Enforce` (default **Off**), read by the filter for
registrations opted in with a scope name: `.RequirePermissionLegacyFromMap("wells")`.
- `Off` → pass through. `Shadow` → evaluate, log `would-deny` (user, route, act, ACL count) at Warning,
  pass through. `Enforce` → current behaviour.
- Custom Configurations keeps calling the overload without a scope = always enforced (no behaviour change).
- Tests: three modes; shadow never returns 403.

### T4 — Route table entries  · M
Add to `RbacRouteMaps` (`Obj` = group id, `Act` = privilege):

**ReadRoots (GET)**
| Root | Act |
|---|---|
| `/api/v1/wells/phss`, `/api/v1/well-surveillance/wells/phss`, `/api/v1/well-surveilence/action-plans/phss`, `/api/v1/well-surveilence/{wellId:guid}/action-plans/phss` | 153 |
| same four with `pep` | 155 |
| `/api/v1/wells`, `/api/v1/well-surveillance`, `/api/v1/well-zone-assignments`, `/api/v1/well-zones` | 137 |
| `/api/v1/eur`, `/api/v1/eur-cumprod`, `/api/v1/alert-notification-setting` | 140 |
| `/api/v1/unit-conversions` | 157 |

Longest prefix wins, so `/api/v1/wells/phss/...` → 153 and `/api/v1/wells/all` → 137. After T1,
`/wells/{type}/histories/chart/rtws`, `/wells/{workingarea}/{id}/alert`, `/choke-update-info`,
`/validate-id`, `/well-surveillance/wells/{type}/…/decline|panel|schematic|tubing-casing` resolve
through the phss / pep roots.

**Map (POST)**
| Act | Routes (`/api/v1` +) |
|---|---|
| 154 | `/wells/phss`, `/wells/phss/update`, `/wells/phss/status`, `/wells/phss/{well_id:guid}/gas-lift-inputs`, `/wells/phss/{well_id:guid}/zones/{well_zone_id:guid}/import`, `/well-surveilence/action-plans/phss/draft`, `…/phss/draft/{id:guid}`, `…/phss/submit`, `/well-surveillance/wells/phss/eur-monitoring/{well_id:guid}/tubing-casing` (expanded) |
| 156 | the same with `pep` (no gas-lift-inputs route for PEP) |
| 139 | `/well-zone-assignments`, `/well-zone-assignments/well/{well_id:guid}`, remarks add / `{remark_id:guid}/update` / `{remark_id:guid}` (delete) |
| 138 | `/eur/well-zone-assignment/import`, `/eur/well-zone-assignment/import/{well_field}`, `/eur/well-zone-assignment/decline-rate/import`, `/alert-notification-setting` |
| 158 | `/unit-conversions` |

- Test: one table-driven test per row (method + RawText + route values → expected act).

### T5 — Opt the groups in  · S
Chain `.RequirePermissionLegacyFromMap("wells")` after `.AddEndpointFilter<R3ComponentFilter>()` in:
WellPhss, WellPep, WellHistoriesPhss, WellHistoriesPep, WellHistoriesChart, WellsValidation, Wells,
WellSurveillance, WellEurMonitoring, ActionPlanPhss, ActionPlanPep, ActionPlanWell, WellZoneAssignments,
WellZoneAssignmentRemarks, WellZones, WellDeclineRateImport, Alert, UnitConversions.
Compressor endpoints stay out (141/144 are not split by working area).
- Boot must pass the validator (T2) — it lists any route T4 missed.

### T6 — Sheet ↔ code alignment  · S
Add sheet rows (and T4 entries) for routes that exist in code but not in the sheet:
`POST /wells/phss/update` / `pep/update` (154 / 156), `GET /wells/highlight` (137),
`GET /wells/{type}/histories/export/rtws|mtu` (153 / 155),
`POST /well-surveillance/wells/{well_id:guid}/delete` (**decision D2**).

### T7 — Tests end-to-end  · M
In-memory host with a fake `IRetinaAclCacheService`:
SDA1 ACL → PHSS GET/POST 200, PEP GET/POST 403; SDA2 the reverse; PO → all GET 200, every POST 403;
shared GET with 137 only → 200, PHSS GET with 137 only → 403; Shadow mode → 200 + warning logged.

### T8 — Data before enforcement (ops, no code)  · S
1. Migration `20261014090000` (or its SQL twin) → privileges 153–158, group 26.
2. `seed_rbac_phss_pep_privileges.sql` → Phantom role grants.
3. Retina: `retina_phss_pep_roles.oracle.sql` (3 new roles) **and a backfill for every existing role
   that uses wells**: holds 137 → add 153 + 155; holds 139 → add 154 + 156; holds 140 / 138 already fine;
   Unit Conversion users → 157 / 158. Generate it from `GET /api/v1/roles/{id}/permissions/insert-query`
   or a query over R3TINA.ACL (decision D3 — who owns the Retina change).
4. Verify `/users/permissions` returns the new ids for one user per role.

## Rollout

| Step | Mode | Exit criteria |
|---|---|---|
| Deploy T1–T7 | `Off` | Boot passes the validator; existing tests green |
| Run T8 on dev | `Off` | `/users/permissions` shows 153–158 where expected |
| Dev | `Shadow` ≥ 2 working days | No `would-deny` warnings for legitimate users in OpenObserve |
| Dev / staging | `Enforce` | curl suite (extend `proof/retest.sh`): SDA1/SDA2/PO matrix as T7 |
| Production | `Shadow` → `Enforce` | Same, with T8 done in prod Retina first |

Rollback at any time: set the mode to `Off` (config only, no deploy).

## Decisions needed

| # | Question | Proposal |
|---|---|---|
| D1 | Debug / job routes inside opted-in groups: `POST /debug/trigger-quartz-*` (Alert), `POST /api/v1/api/well-zone-assignments/history-sync/run` | Move them to their own registration (not opted in); they are ops tools, not user features |
| D2 | `POST /well-surveillance/wells/{well_id}/delete` has no working area in the path | Require 139 + keep the existing working-area data guard; or split into phss / pep routes |
| D3 | Who generates and runs the Retina backfill for existing roles | R3 team, from a list we generate (insert-query endpoint) |
| D4 | Senior Managers before picking a department get their default Retina role ACL | Ensure the default role has 153–156 (else they see 403 until they pick) |

## Out of scope

Compressor (141/144), all non-well modules, ModuleAccessFilter (stays as is), frontend menu hiding.

## Estimate

T1–T3 ≈ 1 day, T4–T6 ≈ 1 day, T7 ≈ 1 day; T8 depends on the R3 team.
