# Test results

Part of [PHI-2119](README.md). Run on 2026-11-09 and 2026-11-10 against backend base `4c84ec37` and frontend base `c81ac26a`, with the changes uncommitted.

| Check | Result |
|---|---|
| Backend build | 0 errors |
| Backend tests | 4,826 passed, 28 failed, 3 skipped of 4,857 |
| Frontend lint and format, changed files | Clean |
| Frontend production build | Succeeded |
| API scenario checks | 80 of 80 passed: [08-api-results.csv](08-api-results.csv) |
| Browser scenario checks | 11 of 11 passed: [08-ui-results.csv](08-ui-results.csv) |

The 28 backend failures are the same 28 tests that fail on the untouched base branch, compared by test name. The final run also included the 6 `ProjectRebaselineApplyIntegrationTests`, which run on the dev database when `appsettings.json` is present and delete the rows they create.

## How it ran

- API on `127.0.0.1:5199`, using mock Retina sessions and the shared dev database, with the 41 `phirbac.role.*` users.
- Quartz was held out of the shared `QRTZ_*` store with a temporary one-line guard, removed afterwards and not staged. Redis Streams consumers were off.
- Browser checks used headless Chrome against the production build, with web security off so a local port could call the local API.

## Bug found by the run

A non-manager user with 2 or more departments got 401 "User has no active department scope" on every call after login, including the picker. `R3ComponentFilter` only let managers through with no department. Fixed in the same change.

## Corrected expectation

A user with no Phantom SYSROLE cannot log in, because the existing application gate rejects them. The scenarios now say so. The 159 minimum in D11 only applies if such a user already holds a session.

## Scenarios not fully run

| Scenario | Why |
|---|---|
| D4 contracts stay visible | Checked that the stored name is unchanged, did not open the contract list |
| D16 SYSROLEs exist in Retina | The SYSROLEs are not created in Retina yet. All 20 were exercised through mock sessions |
| D18 user with no department and no options | Needs a user with an empty SUBFUNGSI; not seeded. The 401 path is unchanged from before for them |
| D22 no organisation, empty department | The guard is in the code, but the profile response was not forced into those states |
| Real Retina | Everything ran on mock sessions, including scoped role reads |
