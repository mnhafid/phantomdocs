# Commit plan — organization structure (all tickets)

Recorded 2026-10-12, revised after all tickets. **Not committed, nothing staged** — worktree
`.worktrees/org-structure`, branch `feat/org-structure` (from `phi-dev` @ `d9ed24be`).
Commits are ordered so each one builds on its own (verified as a whole, not commit by commit).
Some files carry several tickets; each commit lists all of them. Not committable (gitignored):
`docs/` (PRD, FSD, this plan, proof) and `.claude/` (ADR-0008, CONTEXT.md).

Verified on the full set: build 0 errors; full suite 3251 tests — 3227 passed, 21 failed, identical to
clean `d9ed24be` (0 regressions); live proof in `proof/` (2026-10-12-*.jpg/html/json, full-suite.trx).
Retest 2026-10-13 after the restore: curl `proof/retest.sh` 38/38 (login, profile, refresh, working area,
department pick, `/users/permissions` 136 → 6 → 136 for indana) — `retest-curl-2026-10-12.md`.

All paths below are relative to `src-be/`.

| #   | Commit message                                                                                                       | Files                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | Tickets                                            |
| --- | -------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| 1   | `feat(organizations): ensure organizations table migration`                                                          | `DataAccess/Migrations/Phantom/20261012064740_EnsureOrganizationsTable.cs` + `.Designer.cs`, `DataAccess/Database/20261012064740_EnsureOrganizationsTable.sql`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | t106                                               |
| 2   | `feat(organizations): five-level tree rules and used-department rename lock`                                         | `Logics/Services/Organizations/OrganizationsService.cs`, `…/OrganizationDtos.cs`, `WebApi/Services/Organizations/OrganizationsEndpoint.cs`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | t106                                               |
| 3   | `feat(organizations): org path lookup, Retina mapping and division scope helpers`                                    | `Logics/Services/Organizations/OrganisationPathExtensions.cs`, `Logics/Services/Users/UserDtos.cs`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | t107, t109                                         |
| 4   | `feat(auth): cache R3 introspect in Redis; fail fast when Redis is down`                                             | `Logics/Services/Caching/IntrospectCache.cs`, `…/RedisConfig.cs`, `…/RedisSetup.cs`, `…/RedisConnectionProvider.cs`, `WebApi/Services/Auth/AuthEndpoint.cs`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | t102                                               |
| 5   | `feat(auth): department from users.department; senior-manager division scope; working-area guard`                    | `Logics/Services/DepartmentContext/IDepartmentContext.cs`, `…/DepartmentContext.cs`, `Logics/R3Components/EndpointFilter/R3ComponentFilter.cs`, `Logics/Services/Wells/WellsService.cs`, `Logics/Services/WellSurveillance/WellSurveillanceService.cs`, `Logics/Services/WellEurMonitoring/WellEurMonitoringService.cs`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | t109, t110, t102, t98                              |
| 6   | `feat(auth): place users by SUBFUNGSI; organisation block and raw position; privileges follow the picked department` | `Logics/Services/Auth/AuthService.cs`, `…/AuthDtos.cs`, `…/ManagerDepartmentService.cs`, `…/R3UserSyncService.cs`, `WebApi/Services/Users/ManagerDepartmentEndpoint.cs`, `Logics/Services/Users/UsersService.cs`, `Logics/Services/Permissions/RetinaAclCacheService.cs`, `Logics/Services/Roles/RolesService.cs`, `Logics/R3Components/R3DataManagement/MockR3DataManagementService.cs`, `Logics/Services/Auth/DepartmentPickerWhitelist.cs` (new), `Logics/Services/Auth/R3PositionHelper.cs`, `Logics/Services/Auth/RegulatorRoleHelper.cs`                                                                                                                                                                                                                                                                                                                                                                                                     | t107, t94, t100, t108, t98, t103, picker whitelist |
| 7   | `feat(permissions): coarse module gate behind Permissions:ModuleGate:Enabled`                                        | `Logics/R3Components/EndpointFilter/ModuleAccessFilter.cs`, `WebApi/Services/{Contracts/ContractsEndpoint,Spks/SpksEndpoint,Projects/ProjectsEndpoint,Tenders/TendersEndpoint,ServiceAcceptances/ServiceAcceptancesEndpoint,Invoices/InvoicesEndPoint}.cs`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | t104                                               |
| 8   | `refactor: remove user_scopes, users.division and the dead casbin enforcer/RBAC middleware`                          | deleted: `DataAccess/Entities/UserScope.cs`, `DataAccess/DbContext/PhantomDb.UserScope.cs`, `Logics/Services/UserScopes/*`, `WebApi/Services/UserScopes/*`, `Logics/Services/Auth/{RbacService,IRbacService}.cs`, `WebApi/Middleware/RbacMiddleware.cs`; added `Logics/Services/Auth/CasbinSubjectHelper.cs`; changed `DataAccess/DbContext/{PhantomDbContext,PhantomDb.User}.cs`, `DataAccess/Entities/{User,ContractShare}.cs`, `DataAccess/Migrations/Phantom/PhantomDbContextModelSnapshot.cs`, migrations `20261012085555_DropUserScopes` + `20261012085834_DropUsersDivision` (+ Designers), `Logics/Services/AppServiceSetup.cs`, `Logics/Services/ContractShares/ContractSharesService.cs`, `Logics/Services/UserRoles/IUserRolesService.cs`, `WebApi/Program.cs`, `WebApi/Services/EndpointServiceInstaller.cs`, `Tests/ContractSharesServiceTests.cs`, `Tests/RoleIsRegulatorTests.cs`, `Tests/ContractsSpkSelectableTests.cs` (comment) | t98, t101, t103 — ⚠ ships the two drop migrations; dev was restored (A + C), decide before merging                                    |
| 9   | `test: organization structure, privileges, working area, introspect cache, module gate`                              | `Tests/OrganizationStructureTests.cs`, `Tests/DepartmentPrivilegeTests.cs`, `Tests/WorkingAreaScopeTests.cs`, `Tests/IntrospectCacheTests.cs`, `Tests/ModuleAccessFilterTests.cs`, `Tests/DepartmentPickerWhitelistTests.cs`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | all                                                |
| 10  | `chore(db): org seed, SDA/PO test users, cleanup, user_scopes restore and PHSS/PEP privilege scripts`                                            | `DataAccess/Database/seed_org_structure.sql`, `…/seed_org_test_users.sql`, `…/cleanup_department_names_report.sql`, `…/cleanup_department_names_apply.sql` (no longer touch the dropped `user_scopes`), `…/restore_user_scopes.sql`, `…/seed_rbac_phss_pep_privileges.sql`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | t105, t111, t98                                         |

## Commands (when you decide to commit)

```bash
cd .worktrees/org-structure/src-be
c() { git add -A -- "${@:2}" && git commit -m "$1" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"; }
c "feat(organizations): ensure organizations table migration" DataAccess/Migrations/Phantom/20261012064740_EnsureOrganizationsTable.cs DataAccess/Migrations/Phantom/20261012064740_EnsureOrganizationsTable.Designer.cs DataAccess/Database/20261012064740_EnsureOrganizationsTable.sql
c "feat(organizations): five-level tree rules and used-department rename lock" Logics/Services/Organizations/OrganizationsService.cs Logics/Services/Organizations/OrganizationDtos.cs WebApi/Services/Organizations/OrganizationsEndpoint.cs
c "feat(organizations): org path lookup, Retina mapping and division scope helpers" Logics/Services/Organizations/OrganisationPathExtensions.cs Logics/Services/Users/UserDtos.cs
c "feat(auth): cache R3 introspect in Redis; fail fast when Redis is down" Logics/Services/Caching/IntrospectCache.cs Logics/Services/Caching/RedisConfig.cs Logics/Services/Caching/RedisSetup.cs Logics/Services/Caching/RedisConnectionProvider.cs WebApi/Services/Auth/AuthEndpoint.cs
c "feat(auth): department from users.department; senior-manager division scope; working-area guard" Logics/Services/DepartmentContext Logics/R3Components/EndpointFilter/R3ComponentFilter.cs Logics/Services/Wells/WellsService.cs Logics/Services/WellSurveillance/WellSurveillanceService.cs Logics/Services/WellEurMonitoring/WellEurMonitoringService.cs
c "feat(auth): place users by SUBFUNGSI; organisation block and raw position; privileges follow the picked department" Logics/Services/Auth/AuthService.cs Logics/Services/Auth/AuthDtos.cs Logics/Services/Auth/ManagerDepartmentService.cs Logics/Services/Auth/R3UserSyncService.cs WebApi/Services/Users/ManagerDepartmentEndpoint.cs Logics/Services/Users/UsersService.cs Logics/Services/Permissions/RetinaAclCacheService.cs Logics/Services/Roles/RolesService.cs Logics/R3Components/R3DataManagement/MockR3DataManagementService.cs Logics/Services/Auth/DepartmentPickerWhitelist.cs Logics/Services/Auth/R3PositionHelper.cs Logics/Services/Auth/RegulatorRoleHelper.cs
c "feat(permissions): coarse module gate behind Permissions:ModuleGate:Enabled" Logics/R3Components/EndpointFilter/ModuleAccessFilter.cs WebApi/Services/Contracts/ContractsEndpoint.cs WebApi/Services/Spks/SpksEndpoint.cs WebApi/Services/Projects/ProjectsEndpoint.cs WebApi/Services/Tenders/TendersEndpoint.cs WebApi/Services/ServiceAcceptances/ServiceAcceptancesEndpoint.cs WebApi/Services/Invoices/InvoicesEndPoint.cs
c "refactor: remove user_scopes, users.division and the dead casbin enforcer/RBAC middleware" DataAccess Logics/Services/UserScopes WebApi/Services/UserScopes Logics/Services/Auth/RbacService.cs Logics/Services/Auth/IRbacService.cs Logics/Services/Auth/CasbinSubjectHelper.cs WebApi/Middleware/RbacMiddleware.cs Logics/Services/AppServiceSetup.cs Logics/Services/ContractShares/ContractSharesService.cs Logics/Services/UserRoles/IUserRolesService.cs WebApi/Program.cs WebApi/Services/EndpointServiceInstaller.cs Tests/ContractSharesServiceTests.cs Tests/RoleIsRegulatorTests.cs Tests/ContractsSpkSelectableTests.cs
c "test: organization structure, privileges, working area, introspect cache, module gate" Tests/OrganizationStructureTests.cs Tests/DepartmentPrivilegeTests.cs Tests/WorkingAreaScopeTests.cs Tests/IntrospectCacheTests.cs Tests/ModuleAccessFilterTests.cs Tests/DepartmentPickerWhitelistTests.cs
c "chore(db): org seed, SDA/PO test users, cleanup, user_scopes restore and PHSS/PEP privilege scripts" DataAccess/Database/seed_org_structure.sql DataAccess/Database/seed_org_test_users.sql DataAccess/Database/cleanup_department_names_report.sql DataAccess/Database/cleanup_department_names_apply.sql DataAccess/Database/restore_user_scopes.sql DataAccess/Database/seed_rbac_phss_pep_privileges.sql
```

Commit 8's `DataAccess` path also picks up anything left under `DataAccess` — the earlier commits already
took the EnsureOrganizationsTable files and commit 10 the seeds, so run them in order.

## Still to do outside git

- Dev DB: migrations `DropUserScopes` and `DropUsersDivision` — applied 2026-10-12, then **reverted with `restore_user_scopes.sql` (A + C)**: table, indexes and `users.division` back, history rows removed, 24 approximate scope rows. Old code works on dev again.
- Dev DB: **run** `seed_rbac_phss_pep_privileges.sql` (permissions 139, 145–156 + casbin rules for roles 1/1105/1114/1115), then sync the ACL rows to Retina.
- Dev DB: **apply** `cleanup_department_names_apply.sql` after reviewing the report (14 groups after the drop; `user_scopes` no longer included).
- Before enabling `Permissions:ModuleGate:Enabled`: confirm every role's privilege groups (an SPK-only role
  that calls contract lookups would get 403).
- Decide `users.zone` (admin-editable, kept).
- `POST /auth/logout` is a no-op (commented out) — re-enabling full logout is a separate decision.

## Revision 2026-10-12 — user_scopes usage check

No module (Projects, Contracts, SPKs, …) nor any dev-DB view/proc/function/trigger, nor any sibling
service, still uses `user_scopes`. Fixed in this pass: cleanup report/apply scripts (commit 10) dropped
their `user_scopes` part; stale comments in `ContractSharesService.cs` (commit 8) and
`Tests/ContractsSpkSelectableTests.cs` (added to commit 8).

## Revision 2026-10-12 — department-picker whitelist and 7 test users

- `DepartmentPickerWhitelist` (constant): only Senior Manager / General Manager (POSNAME) and SuperAdmin
  (SysRole) pick their department; their login returns `department: ""`. Regulator SysRoles no longer
  pick. In commit 6; tests in 9 (`DepartmentPickerWhitelistTests`) and 8 (`RoleIsRegulatorTests`
  expectations updated: `""` instead of null, "SKK Regulator" no longer picks, General Manager picks).
- Test users r3test.sm.ssdp, r3test.sm.pnp, r3test.superadmin, r3test.gm appended to
  `seed_org_test_users.sql` (commit 10) and applied on dev.
- RBAC proposal for PHSS/PEP privileges 153–156: `docs/organization-structure/rbac-phss-pep-privileges.md` (not applied).

## Revision 2026-10-12 — user_scopes restored on dev (A + C), RBAC seed

- `DataAccess/Database/restore_user_scopes.sql` (add to commit 10): recreates `user_scopes` (+4 indexes)
  and `users.division`, deletes the two Drop* rows from `__EFMigrationsHistory`, rebuilds one primary
  scope per user from `users.department`. **Applied on dev 2026-10-12: 24 rows.**
- ⚠ Commit 8 still ships migrations `DropUserScopes` / `DropUsersDivision`. Any `database update` from
  this branch (or a deploy that migrates) drops both again. Keep commit 8 as is only if the drop is still
  wanted after old code is retired; otherwise move the two migrations out of commit 8.
- `DataAccess/Database/seed_rbac_phss_pep_privileges.sql` (add to commit 10): permissions 139, 145–156 and
  casbin p-rules for roles 1, 1105, 1114, 1115. **Not run.**

## Stacked PRs (GitHub native, `gh stack`) — 2026-10-13

Docs: https://docs.github.com/en/pull-requests/how-tos/stacked-pull-requests. Needs gh ≥ 2.90 (local is
2.68.1 → `brew upgrade gh`) and `gh extension install github/gh-stack`. No repo/org setting needed;
branch protection and CI run on every PR in the stack.

| Layer | Branch | Commits | Tests moved in (commit 9 is split up) |
|---|---|---|---|
| 1 (→ phi-dev) | `org/1-tree` | 1, 2, 3 + `seed_org_structure.sql` | — (see layer 2) |
| 2 | `org/2-auth` | 4, 5, 6 + `seed_org_test_users.sql` | `OrganizationStructureTests` (calls ManagerDepartmentService options/choose + SeniorManagerDepartmentsAsync, so it cannot build in layer 1), `IntrospectCacheTests`, `DepartmentPrivilegeTests`, `WorkingAreaScopeTests`, `DepartmentPickerWhitelistTests`, `RoleIsRegulatorTests` (from commit 8: expects the whitelist `""` and no user_scopes row) |
| 3 | `org/3-module-gate` | 7 | `ModuleAccessFilterTests` |
| 4 (top, hold) | `org/4-cleanup` | 8 + cleanup / restore / RBAC SQL | `ContractSharesServiceTests`, `ContractsSpkSelectableTests` (in 8) |

```bash
cd .worktrees/org-structure/src-be          # uncommitted changes ride along to the new branch
gh stack init -b phi-dev org/1-tree
#   commits 1-3 (c "..." from the table above), then:
c "chore(db): seed the PHE organization tree and Retina department mapping" DataAccess/Database/seed_org_structure.sql
gh stack add org/2-auth
#   commits 4-6, then:
c "test(auth): introspect cache, department privileges, working area, picker whitelist" Tests/OrganizationStructureTests.cs Tests/IntrospectCacheTests.cs Tests/DepartmentPrivilegeTests.cs Tests/WorkingAreaScopeTests.cs Tests/DepartmentPickerWhitelistTests.cs Tests/RoleIsRegulatorTests.cs DataAccess/Database/seed_org_test_users.sql
gh stack add org/3-module-gate
#   commit 7, then:
c "test(permissions): module gate" Tests/ModuleAccessFilterTests.cs
gh stack add org/4-cleanup
#   commit 8, then:
c "chore(db): cleanup, user_scopes restore and PHSS/PEP privilege scripts" DataAccess/Database/cleanup_department_names_report.sql DataAccess/Database/cleanup_department_names_apply.sql DataAccess/Database/restore_user_scopes.sql DataAccess/Database/seed_rbac_phss_pep_privileges.sql
git status --short                          # must be empty (docs/ is ignored)
gh stack view                               # 4 layers, bottom = org/1-tree
gh stack submit                             # pushes + opens 4 linked PRs as DRAFTS; add --open for ready
```

Review fixes: `gh stack checkout <pr>` (or `gh stack down`/`up`), commit the fix on that layer, then
`gh stack rebase --upstack` and `gh stack push` (force-with-lease per branch). `gh stack sync` does
fetch + cascade rebase + push in one go, e.g. after phi-dev moves.

Merge: bottom-up only. `gh stack merge <PR-of-layer-3> --merge` merges layers 1–3 together (all or
nothing) and re-targets layer 4 to phi-dev; layer 4 stays open until the drop-migration decision.
Squash/rebase also work (merge-queue aware). Afterwards `gh stack sync --prune` removes merged local branches.


Status 2026-10-13: layer 1 committed by the owner (a0237947) → PR #1270. Layer 2 committed by the owner (c971d080) → PR #1271. Layer 3: branch `org/3-module-gate`, 8 files **staged only**.

## Revision 2026-10-13 — layer 4: no drop, code removal only (owner decision)

PR #1274 (a70f4d6a) shipped the drop migrations. Owner: "for clean up dont drop table or database only
remove code that insert or select to that table". Staged on `org/4-cleanup` (not committed):
- deleted `20261012085555_DropUserScopes` + `20261012085834_DropUsersDivision` (+ Designers); backup in
  the session scratchpad `drop-migrations-backup/`;
- restored from f1dbb687 the EF mapping so the model keeps the table/column and no future migration
  drops them: `Entities/{User,UserScope,ContractShare}.cs`, `DbContext/{PhantomDb.User,PhantomDb.UserScope,PhantomDbContext}.cs`,
  `PhantomDbContextModelSnapshot.cs`; `User.Division` and `UserScope` carry a "kept only so it is not
  dropped" comment;
- unchanged: UserScopes service/endpoint/DTOs deleted, ContractShares reads users.department, RBAC
  middleware/RbacService/casbin enforcer removed — no code inserts or selects `user_scopes` / `users.division`.
Dev DB already matches (A + C restore); `restore_user_scopes.sql` stays as the dev fix record.
Suggested commit: `fix(cleanup): keep user_scopes and users.division in the schema; remove the drop migrations`.

## Merged 2026-10-13

Stack merged into `phi-dev` 07:42–07:43: #1270 ecb62390, #1271 40bca7ff (includes e73b2f7d — whitelisted
users skip the Retina department check), #1273 34b2d032, #1274 af7c92c9 (no drop migrations; UserScope /
users.division stay mapped). Verified against origin/phi-dev 5d47cec3.
Still open outside git: run `seed_rbac_phss_pep_privileges.sql` + Retina ACL rows; review then run
`cleanup_department_names_apply.sql`; deploy (dev API was build 20261009.001 → still old login).
