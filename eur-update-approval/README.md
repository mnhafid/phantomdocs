# EUR Update Approval Route (t131) — change summary

PR: https://github.com/oceaninov/phantom/pull/1291 · branch `feat/eur-update-approval` · worktree `.worktrees/eur-update-approval`
Date: 2026-10-20

## Final scope

The PR adds two approval-route categories, one per well type. Nothing else.

| Category | Well type | Approver permission (existing) |
|---|---|---|
| `eur_update_phss` | PHSS | 154 Modify PHSS Wells |
| `eur_update_pep` | PEP | 156 Modify PEP Wells |

Final diff vs branch base — one file:

```csharp
// src-be/Logics/Services/EurUpdateApprovals/EurUpdateApprovalConstants.cs
public static class EurUpdateApprovalConstants
{
    public const string RouteCategoryPhss = "eur_update_phss";
    public const string RouteCategoryPep = "eur_update_pep";
}
```

No other backend change is needed: `POST /v1/approval-routes` and `POST /v1/approval-routes/{id}/update` only check
that `category` is not blank (`ApprovalRoutesService.cs` `ValidateCreateRequest` / `ValidateUpdateRequest`).

## Commits / staging

| Ref | What |
|---|---|
| `24d04bfb` | original: hold EUR edits for the `eur_update` route (t131) — +20 485 lines |
| `61628fc8` | rollback update eur (user commit): removed migration, snapshot, Designer, hold hook, DTO field, tests |
| staged (not committed) | removed everything else except the constants file — see below |

## What was removed and why

| Removed | Reason |
|---|---|
| Migration `20261015122814_AddWellEurUpdateRequests` (.cs + 19k-line .Designer.cs) + snapshot hunk | user: drop the whole migration. Snapshot itself was clean (only the 2 EUR tables, Designer == snapshot) |
| Entities `WellEurUpdateRequest`, `WellEurUpdateApprover`, `PhantomDb.WellEurUpdateRequest.cs`, DbSets, `OnModelCreating` call | no migration and no service left to use them |
| Hold-EUR hook in `WellZoneAssignmentService.cs` (`heldEur`, `LoadEurUpdateRouteAsync`, `SubmitHeldEurAsync`) | not part of the approval route; EUR edits write directly again |
| `WellZoneAssignmentService.EurApproval.cs` + `partial` keyword | helpers only served the hook / approval service |
| `pending_eur_update_request_ids` on `UpdateWellZoneAssignmentsResponse` + BOM added to `WellZoneAssignmentDto.cs` | belonged to the hook; BOM was unrelated noise |
| `EurUpdateApprovalsService`, `IEurUpdateApprovalsService`, `EurUpdateApprovalsDto`, `AddScoped` in `AppServiceSetup.cs` | nothing created requests to approve |
| `EurUpdateApprovalsEndpoint.cs` + `MapEurUpdateApprovals()` in `EndpointServiceInstaller.cs` | user: endpoint not needed |
| `EurUpdateApprovalTests.cs` | tested the removed hold flow |
| Constants `RouteCategory = "eur_update"`, `ApprovalFlow`, `PermissionIdPhss/Pep` | replaced by the 2 categories; permission ids live in the FE map |

## Frontend changes (separate FE repo)

Captured from https://phantom-web.inproms.com/ipms/approval-route → **Add New Route** (see [api-capture.md](api-capture.md)).

1. `approval-route` store `getApprovalCategoryList` — add
   `{ id: "eur_update_phss", name: "Update EUR PHSS" }`, `{ id: "eur_update_pep", name: "Update EUR PEP" }`.
2. Category registry (`le` in `Index.*.js`) — map both to the Default handler `T` (same as `project_rebaseline`).
3. `mapApprovalRouteCategoryPermission` (Default form) — `eur_update_phss → "154"`, `eur_update_pep → "156"`.
   The approver dropdown then calls `GET /api/v1/users/by-permission/154|156`.

Routes with these categories already exist on dev (created through the FE), so this looks in progress.

## Permission finding — approver list is empty today

- `GET /users/by-permission/{id}` (`UsersService.GetUsersByPermissionAsync`) reads **casbin** (`p` role→perm, `g` user→role).
- 153–156 (PHSS/PEP Read/Modify) are granted via the **Retina ACL** per SYSROLE (`PHI:RETINA:<user>` in Redis),
  which `/users/permissions` uses. No casbin `p` rule exists for 154/156 → both return `[]`.
- No phiDev table/API lists "all users holding Retina privilege X".
- To populate the dropdown: grant 154/156 to roles via casbin (role admin or a seed). Candidate roles on dev:
  1116 Subsurface Development Area 1, 1117 Subsurface Development Area 2 (+ regulators 1114/1115, OSF 1101, Super Admin 1).
  **Open:** SDA 1 = PHSS per PRD Q11 + code, but the RBAC sheet headers say the opposite — confirm before seeding.

## Test results (dev API `phantom-api.inproms.com`, mock token `r3test.agil`)

| Call | Result |
|---|---|
| `GET /users/by-permission/154` | 200, `[]` |
| `GET /users/by-permission/156` | 200, `[]` |
| `GET /users/by-permission/139` (control) | 200, users returned |
| `POST /approval-routes` `eur_update_phss` | 200 "Create approval route succeed" → `f73ec2f0-c89b-4f88-9bf2-361af7cf8622` |
| `POST /approval-routes` `eur_update_pep` | 200 "Create approval route succeed" → `b207837e-fd7c-4ceb-b420-9094c6bb7195` |
| `GET /approval-routes/{id}` | 200, category `eur_update_phss`, status `active` |
| `GET /approval-routes?category=eur_update_phss,eur_update_pep` | 200, count 5 |

Script: [eur-route-curl.sh](eur-route-curl.sh). The two `CURL TEST - …` routes are still on dev (not deleted).

## Open items

- [ ] Commit the staged cleanup; update PR #1291 title/description (still says "hold EUR edits").
- [ ] Grant 154/156 to roles in casbin (confirm SDA 1/2 ↔ PHSS/PEP first).
- [ ] FE: categories + registry + permission map (above).
- [ ] Delete the 2 `CURL TEST` routes on dev when done.
- [ ] Rebase on `origin/phi-dev` (branch is ~10 commits behind, incl. PHI-1864 tank migration).
- [ ] Dev DB: if migration `20261015122814` was ever applied, tables `well_eur_update_requests` /
      `well_eur_update_approvers` and its `__EFMigrationsHistory` row remain — drop them manually.
