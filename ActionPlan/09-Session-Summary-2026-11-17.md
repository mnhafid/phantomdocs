# Action Plan Approval — Artificial Lift & Well Test: session summary (2026-11-16 → 17)

PR: **[oceaninov/phantom#1476](https://github.com/oceaninov/phantom/pull/1476)**, `feat/action-plan-al-wt` → `phi-dev`, 11 commits, mergeable.
Worktree: `.worktrees/action-plan-al-wt` (one branch with everything: approval engine PHI-2243, visibility PHI-2442, WHC rules PHI-2297, reject-round flow).
Overlaps #1432 (approval) and #1436 (WHC): merge #1476 **or** those, not both.

## Tickets

**Artificial Lift**
| Ticket | Status | Summary |
|---|---|---|
| [PHI-2242](https://digiitphi.atlassian.net/browse/PHI-2242) | Dev In Progress | SSDP Request Artificial Lift |
| [PHI-2297](https://digiitphi.atlassian.net/browse/PHI-2297) | Dev In Progress | [BE] SSDP Request Artificial Lift (WHC rules) |
| [PHI-2243](https://digiitphi.atlassian.net/browse/PHI-2243) | Dev In Progress | Approve — PO gets notification and approves |
| [PHI-2245](https://digiitphi.atlassian.net/browse/PHI-2245) | Dev In Progress | Modify — PO gets notification and modifies |
| [PHI-2246](https://digiitphi.atlassian.net/browse/PHI-2246) | Dev In Progress | Modify — approve, PO Manager |
| [PHI-2247](https://digiitphi.atlassian.net/browse/PHI-2247) | Dev In Progress | Modify — approve, SSDP |
| [PHI-2251](https://digiitphi.atlassian.net/browse/PHI-2251) | Dev In Progress | Modify — reject, PO Manager |
| [PHI-2256](https://digiitphi.atlassian.net/browse/PHI-2256) | Dev In Progress | Modify — reject, SSDP |
| [PHI-2259](https://digiitphi.atlassian.net/browse/PHI-2259) | Dev In Progress | Reject — PO gets notification and rejects |
| [PHI-2260](https://digiitphi.atlassian.net/browse/PHI-2260) | Dev In Progress | Approval route in Data Config |

**Well Test**
| Ticket | Status | Summary |
|---|---|---|
| [PHI-2354](https://digiitphi.atlassian.net/browse/PHI-2354) | Dev In Progress | SSDP Request Well Test |
| [PHI-2355](https://digiitphi.atlassian.net/browse/PHI-2355) | Dev In Progress | Approve — PO gets notification and approves |
| [PHI-2363](https://digiitphi.atlassian.net/browse/PHI-2363) | Dev In Progress | Modify — PO gets notification and modifies |
| [PHI-2364](https://digiitphi.atlassian.net/browse/PHI-2364) | Dev In Progress | Modify — approve, PO Manager |
| [PHI-2365](https://digiitphi.atlassian.net/browse/PHI-2365) | Dev In Progress | Modify — approve, SSDP |
| [PHI-2384](https://digiitphi.atlassian.net/browse/PHI-2384) | Dev In Progress | Modify — reject, PO Manager |
| [PHI-2401](https://digiitphi.atlassian.net/browse/PHI-2401) | Dev In Progress | Modify — reject, SSDP |
| [PHI-2419](https://digiitphi.atlassian.net/browse/PHI-2419) | Dev In Progress | Reject — PO gets notification and rejects |
| [PHI-2420](https://digiitphi.atlassian.net/browse/PHI-2420) | Dev In Progress | Approval route in Data Config |

**Shared**
| Ticket | Status | Summary |
|---|---|---|
| [PHI-2442](https://digiitphi.atlassian.net/browse/PHI-2442) | **To Do** (work is in #1476) | Status and detail table of the well's action plans (visibility) |

Statuses as of 2026-11-17. Only PHI-2297 has an assignee (BackEnd Ocean).

## Decisions made this session

| # | Decision | Where |
|---|---|---|
| 1 | Reject round: level answers with `approval/reject` = **continue the rejection**, new `approval/modify` = **ask PO to modify** (back to PO). `approval/approve` → 400 in a reject round. Modify round unchanged. | `ActionPlanApprovalService.cs`, endpoint |
| 2 | Flow 3: after the **last** level continues the rejection the plan goes **back to the PO** (`modify_returned`), cycle outcome `rejected`; **PO pool + SSDP creator** get "Action Plan Rejected by Manager". No plan ends as `rejected`. | service + `ActionPlanApprovalNotifier.StageRejectedAsync` |
| 3 | `can_approve` false in a reject round; `can_reject` covers both `approval/reject` and `approval/modify` (both permission 163). | `ActionPlanApprovalAccess.cs` |
| 4 | Detail `wo_number` / nested `assigned_department` (mirror of submit body) — **rolled back** on request; detail keeps `work_order_number` + top-level `assigned_department`. | — |

## Testing done

| Test | Result |
|---|---|
| Every step of `08-ScenarioTest` (Well Test + Artificial Lift, PEP + PHSS, tests #1–#7, auto-approved types, visibility / view-only), 2026-11-16, dev DB, local API from #1476 | **262 curls, all as expected**; 5 failures are the expected 400s. 3 `GET /notifications/mine` timed out (~30 s) on dev, passed on rerun. Screenshots embedded in `08-ScenarioTestWellTest-curl.md` (PNG files in `docs/`). |
| WO number concurrency, 2026-11-17, SDA1 | 5 parallel submits → `0044`–`0048`, distinct; 3 parallel with same `0049` → 1 saved, 2 rejected; no duplicates; counter SDA1/2026 = 49. |
| next-wo-number report re-check | SDA1 `0044`, SDA2 `0009`; PO / Project → 400 no short name (by design); `phi.generalmanager` is SDA2; `phi.po` session OK (report's "403 Session Invalid" wrong). |

## Files in this folder

| File | What |
|---|---|
| `08-ScenarioTest.md` | Scenario list (your doc). Test #3 expect text still says "reject rejected"; code sends "Action Plan Rejected by Manager" to PO pool + SSDP. |
| `08-ScenarioTestWellTest-curl.md` | Full curl per step, bodies per Bruno PR #176, **live dev tokens** (local only, `.git/info/exclude`), screenshot per curl. |
| `08-ScenarioTest-curl-artificial-lift.md` | Artificial lift only, PEP + PHSS tests #1–#7 (tokens, local only). Not run. |
| PR #1476 comments | Same curl doc with tokens replaced by `$TOKEN_*` and the result of every call. |

## Open items

1. **`878c5aba` (db branch) drops `work_order_sequences`** — #1476 needs that table (migration `20261109080000_AddWorkOrderSequences`). Keep the drop out of `phi-dev`.
2. **Bruno PR #176** (`bruno/.worktrees/action-plan-approval`, unstaged): `Approve`/`Reject Action Plan Level.yml` updated, new `Ask PO to Modify Action Plan Level.yml`; `Review Action Plan.yml` + `folder.yml` wording not updated (edit was stopped).
3. **Bruno PR `proposed` gap:** PR examples leave out `ownership` (and `notes` for AL) in `proposed` → final approve writes them empty. Decide: add to the examples, or backend keeps omitted fields.
4. **next-wo-number:** fallback scan (`EndsWith`, max in C#) runs only before a department's first submit of the year — low priority; FE should re-fetch the number on 422 code 42.
5. **Jira:** PHI-2442 still To Do; 19 of 20 tickets unassigned.
6. **Old worktrees** `phi-2243-ap-approval` and `phi-2242-ap-al-whc` still hold staged copies of the same changes — clean up once #1476 is settled.
7. **Dev data left:** ~30 scenario plans (WO `0033`+ SDA1, SDA2 `0005`+) and 6 plans with note "WO concurrency test" (`0044`–`0049`).
8. Commit `060f6967` message is `[PHI22243] approval artificil lift and welltest` (missing dash, typo) — PR title is correct; fine if squash-merged.
