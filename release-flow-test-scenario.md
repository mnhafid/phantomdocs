# Release flow — test scenario

What this proves, before any of it is pointed at `oceaninov/phantom`: that the weekly cut
ships **only** QA-approved work, that it fails loudly rather than silently when it cannot,
and that the branch handed to GitLab is always a fast-forward.

Run against **`mnhafid/phantom`** (private, yours). Nothing here touches the org repo.

## Preconditions

The test repo already holds a partial run from an earlier session and must be reset:

```
phi-dev              36dc0d20
release/20260918     9547bcfb      release/20260925  0e910a31
v0.1.0 + released/v0.1.0/{1,2}     PRs #1, #2 (merged)
```

**Reset step:** delete all branches except a fresh `phi-dev`, delete every tag, close any
open PRs. Merged PRs #1/#2 cannot be deleted — the scenario numbers new PRs from #3, so
they do not collide.

GitLab is unreachable from here, so a **local bare repo stands in for it** (`/tmp/fake-gitlab.git`
added as remote `gitlab`). That makes the fast-forward property something we actually test
rather than assume.

## Fixture

Eight PRs, built so each exercises one behaviour. `A→B` means B's commit touches the same
file as A.

| PR | Merge style | Touches | QA? | Purpose |
|---|---|---|---|---|
| #3 | squash | `alpha.txt` | ✅ | the plain case |
| #4 | merge commit | `beta.txt` | ✅ | the `-m 1` case (8 of 21 real units are these) |
| #5 | squash | `gamma.txt` | ❌ | **must not ship** — the core promise |
| #6 | squash | `shared.txt` line 1 | ❌ | sets up the conflict |
| #7 | squash | `shared.txt` line 1 | ✅ | conflicts with the unapproved #6 |
| #8 | squash | `delta.txt` (new fn) | ❌ | sets up the dependency gap |
| #9 | squash | `epsilon.txt` (calls #8's fn) | ✅ | **picks cleanly but is broken** |
| #10 | squash | `zeta.txt` | ✅ *(late)* | approved only after week 1's cut |

## Cases

Each is a separate assertion. "Cut" = `scripts/cut-release.sh`, "bot" = `scripts/release_bot.py`.

### Week 1

| # | Action | Expected |
|---|---|---|
| 1 | `/tested 3` | tag `qa/3` at #3's landing commit, label applied, reply names the PR |
| 2 | `/tested 4` | tag `qa/4` at the **merge commit** `36dc…`-style sha |
| 3 | `/tested 9`, `/tested 7` | tags created; #5, #6, #8 deliberately left untagged |
| 4 | `/tested 3` again | **no change** — idempotent, no second tag |
| 5 | `/tested 999` | "PR #999 does not exist" — not a crash |
| 6 | `/tested PHI-1455` | refuses, tells the operator to use a PR number (only ~3% of PRs carry a ticket) |
| 7 | Tag `qa/8888` on a commit not on `phi-dev` | cut reports it as an **orphan**, never picks it |
| 8 | **Cut (dry-run)** | reports 4 picks (#3, #4, #7, #9); pushes nothing |
| 9 | **Cut (real)** | `release/<date>` created from `release/20260918`; #3, #4, #9 picked; **#7 conflicts** on `shared.txt` and is reported with the filename; run continues; exit code **1** |
| 10 | Inspect the branch | `alpha/beta/epsilon` present; `gamma` (#5), `shared` (#6/#7), `delta` (#8) **absent** |
| 11 | Provenance | every picked commit carries `(cherry picked from commit <sha>)` |
| 12 | **Cut again** | picks **0**, all four reported "already applied" — idempotent |
| 13 | `/untested 3` | **refused** — already cut onto the branch; message says revert instead |
| 14 | `/untested 5` | allowed — never tagged, nothing to undo (reports that) |
| 15 | `/tag v0.2.0` | annotated tag at the branch tip, message lists #3 #4 #9; `qa/*` → `released/v0.2.0/*` |
| 16 | `/tag v0.2.0` again | **refused** — versions never move |
| 17 | `/untested 4` | **refused** — shipped in v0.2.0 |
| 18 | Push to `gitlab` | fast-forward succeeds; `git log gitlab/main ^release/<date>` is **empty** |

### Week 2 — the lineage test

| # | Action | Expected |
|---|---|---|
| 19 | `/tested 10` (the late approval) | tag created even though week 1 already shipped |
| 20 | Merge one more PR #11, `/tested 11` | tag created |
| 21 | **Cut** with a later date | parent is **week 1's branch**, not `phi-dev`; picks #10 and #11 |
| 22 | #7's conflict, still unapproved-dependency | reported again — it does not silently vanish |
| 23 | Lineage | `git merge-base --is-ancestor release/week1 release/week2` → **true** |
| 24 | Push to `gitlab` | **still a fast-forward** — this is the property the whole design exists to protect |
| 25 | Backdated cut (`RELEASE_DATE` older than the last) | parent is the newest branch *older than that date* — regression test for the bug found earlier |

### Failure-mode cases

| # | Action | Expected |
|---|---|---|
| 26 | Cut with no previous `release/*` | **hard fails**, never branches from `phi-dev` |
| 27 | Cut locally without `ALLOW_PUSH` | reports "no (local run…)", pushes nothing |
| 28 | `check-migrations.sh` made to fail | branch still pushed, report shows the failure, exit code 1 |
| 29 | Label a PR but delete its `qa/` tag | cut's **drift check** reports "labelled but has no qa/ tag — will NOT ship" |
| 30 | Bot with a bad `GH_TOKEN` | fails loudly on the auth precheck, not 20 confusing "PR not found" replies |
| 31 | Bot command from a non-allowlisted user | rejected with a reply; no tag created |

## The one case that must fail visibly

**Case 9 (#9 without #8)** is the design's known blind spot: it cherry-picks cleanly and
produces a branch that would not compile. The cut cannot catch it — there is no working CI,
and `nuget.config`'s relative feed breaks clean checkouts. What the scenario verifies is
that the **report warns about it**: #9 touches files also changed by unapproved #8, and the
"this branch has never been compiled" banner is present. If a human reading that report
would not notice, the reporting needs work — that is the real finding of this test.

## Pass criteria

- No unapproved PR's code reaches the release branch (cases 10, 22).
- Conflicts are named with their files and never auto-resolved (case 9).
- Re-running changes nothing (case 12).
- GitLab push is a fast-forward in both weeks (cases 18, 24).
- Every guard refuses rather than guesses (cases 13, 16, 17, 25, 26, 27, 30, 31).
- Exit code is non-zero whenever anything needs a human (cases 9, 28).

## Teardown

Reset `mnhafid/phantom` to an empty `phi-dev`, delete `/tmp/fake-gitlab.git`. The real repo
is untouched throughout — the only thing that changes there is committing the two scripts
and two workflows, which is a separate decision.
