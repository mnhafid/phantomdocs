# PHI-2119: department picker and permissions from SYSROLE names

Enhancement to [PHI-2119 "[RBAC] For Other Roles Login Cross Department"](https://digiitphi.atlassian.net/browse/PHI-2119). Agreed on 2026-11-09. **Implemented and staged in `.worktrees/phi-2119-sysrole-picker` in both repos, not committed.**

Retina SYSROLEs are moving to the name format `Department - name - level`, for example `Projects - Read - Guest`. Phantom will use those names to work out each user's department, which departments they can choose, what they can do, and whether they are a regulator.

| Document | Contents |
|---|---|
| [01-DECISIONS.md](01-DECISIONS.md) | Every decision made, with its reason |
| [02-PRD.md](02-PRD.md) | Goals, scope and requirements |
| [03-FSD.md](03-FSD.md) | Backend and frontend design |
| [04-SYSROLES-TO-CREATE.md](04-SYSROLES-TO-CREATE.md) | The 20 SYSROLEs to create in Retina |
| [04-sysrole-acl.csv](04-sysrole-acl.csv) | Every permission for each new SYSROLE |
| [05-USER-MAPPING.md](05-USER-MAPPING.md) | Which dev users need which SYSROLE |
| [05-user-mapping.csv](05-user-mapping.csv) | The same list for all 101 dev users |
| [06-e2e-scenarios.feature](06-e2e-scenarios.feature) | End-to-end scenarios in Gherkin, one `Rule` per decision |
| [07-TEST-USERS.md](07-TEST-USERS.md) | The `phirbac.role.*` test users and expected results |
| [07-seed-test-users.sql](07-seed-test-users.sql) | Creates them on dev. Review before running |
| [07-cleanup-test-users.sql](07-cleanup-test-users.sql) | Removes them again |
| [08-TEST-RESULTS.md](08-TEST-RESULTS.md) | Results of the build, tests and scenario runs |

## Items still open

| # | Item | Why it matters |
|---|---|---|
| O1 | **Resolved 2026-11-09.** Retina does not need converting first. Users with no patterned SYSROLE get merge-all, including GM and SM after picking | D11 |
| O2 | SYSROLE spelling on dev and prod | The parser reads the text before the first ` - `, so names must be consistent |
| O3 | **Resolved 2026-11-09.** GM and SM are Leaders, so they become regulators | D23 |
| O4 | What do SDA 1 and SDA 2 approve? | The existing roles have no approval privileges, so `Approval - Member` would be read-only |
| O5 | Review the Read, Modify and Approval split | It is derived from privilege names, and five seqs with blank names are excluded |
| O6 | Prod user mapping | The list here is dev data only |
| O7 | Who converts Team Member General users | 16 dev users have proposals that need confirming |
