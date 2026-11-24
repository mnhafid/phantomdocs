# PRD: SPK BoQ Shorten Flow

| | |
|---|---|
| **Status** | As-built — documents what shipped on `feat/shortenflow` |
| **Author** | Claude (grilled with mnhafid) |
| **Date** | 2026-09-03 |
| **Version** | 1.0 |
| **Branch** | `feat/shortenflow` |
| **Related** | [FSD.md](FSD.md) · [data.sql](data.sql) · original spec [../2026-08-26-spk-boq-improvement-PRD.md](../2026-08-26-spk-boq-improvement-PRD.md) |

## 1. Overview

An SPK (Surat Perintah Kerja) is a work order issued against a contract. Before one can be issued, a planner has to say **which contract BOQ lines a given project task will consume, at what volume, over what dates**. That selection is the SPK BoQ.

Before this work, making that selection was a single submit-and-pray step. Close the modal mid-edit and the whole selection was gone. The picker did not say which lines another task had already taken. The contract's remaining budget was displayed but enforced nowhere.

The shorten flow turns that one step into a resumable wizard: **open → pick → autosave → submit**, with the draft surviving a closed modal, the picker marking lines the task has already taken (submitted *or* merely drafted), and the contract's remaining balance shown on every draft read. It serves one role, the SPK planner.

This document records the shipped shape. Where it differs from the original 2026-08-26 spec, §7 says so plainly.

## 2. Problem

| # | Problem | Evidence |
|---|---|---|
| P1 | **No mid-edit recovery.** The submit was a full-replace atomic step with no in-progress state. A closed modal, a network blip, or an interruption cost the entire selection. | Confirmed by the FE team: planners regularly rebuilt selections from scratch. |
| P2 | **Planners double-picked the same line.** The picker returned the contract's lines without saying which were already taken. Two picks, one winner at submit, no signal at the point of choice. | Corrupts SPK value at the aggregation level. |
| P3 | **Contract budget could be exceeded silently.** Remaining balance was a display value with nothing behind it. | Flagged by the FE team as a hard requirement. **Still open — see §7.** |
| P4 | **A flat picker for a hierarchical BOQ.** Large BOQs came back as an unnavigable flat list with no parent/child relationship the FE could render as a tree. | |

## 3. Users

| Persona | What they do | What they need |
|---|---|---|
| **SPK planner** | Builds and revises the BoQ selection for a project task, then submits it so an SPK can be issued against it. The only role in scope. | Not to lose work mid-edit; to see what is already taken before picking; to know the contract's remaining balance; to navigate a large BOQ as a tree. |

## 4. Goals

| ID | Goal | Metric | Target | Status |
|---|---|---|---|---|
| G1 | Planners stop losing mid-edit selections | % of wizards opened that reach a successful submit | ≥ 85% within 30 days | **Shipped** — draft save/read/delete |
| G2 | The wizard gets meaningfully faster to complete | median open → submit | ≤ 70% of the pre-rollout baseline | **Shipped** — resume + tree picker |
| G3 | Double-picking the same line stops | duplicate `project_task_boq_details` per task, monthly | 0 | **Shipped** — `is_selected` spans submitted **and** draft |
| G4 | Negative-balance submits stop | overruns caught at submit | ≥ 1/month that would have shipped before | **NOT MET** — the gate was never built (§7) |
| G5 | A task's full SPK exposure is visible | tasks whose second SPK is invisible to the API | 0 | **Shipped** — v2 `spks[]` + `spk_type` |

## 5. User stories

| ID | Story | Priority | Shipped |
|---|---|---|---|
| US-01 | As a planner, I want my in-progress selection autosaved as I work, so closing the modal does not lose it. | Must | Yes |
| US-02 | As a planner, I want the wizard to resume from my saved draft when I re-open the task. | Must | Yes |
| US-03 | As a planner, I want to see which contract lines this task already took — submitted or still drafted — so I do not pick one twice. | Must | Yes |
| US-04 | As a planner, I want the picker to render as a tree of headers containing items, so a large BOQ is navigable. | Must | Yes — `parent_id` |
| US-05 | As a planner, I want to discard an in-progress selection and start over ("Revise"). | Must | Yes |
| US-06 | As a planner, I want to see the contract's remaining balance while I build the selection. | Must | Yes — `spk_remaining` on every draft read |
| US-07 | As a planner, I want to be **stopped** at submit when the selection drives the contract negative. | Must | **No — §7** |
| US-08 | As a planner, I want to see every SPK a task and each of its lines belong to, not just one. | Should | Yes — v2 |

## 6. Non-goals

| Not doing | Why |
|---|---|
| Per-user draft locking | Two planners on one task overwrite each other silently. Accepted v1 trade-off; revisit if the workflow demands it. |
| An approval step between draft and submit | v1 is planner-only. Add later if project control needs sign-off. |
| Editing the BOQ tree from the wizard | `parent_id` is read-only. The FE renders the tree; planners cannot restructure the contract BOQ. |
| Migrating pre-existing in-progress selections into drafts | Greenfield — there was nothing to migrate. The legacy `POST /projects/tasks/boqs` stays open. |
| Overloading `project_tasks.status` | It belongs to the `not started → in progress → finished` machine. Reusing it would break that. |
| Status flags on `project_task_boqs` | That table is read at ~13 sites across 6 services. Miss one and a draft line inflates SPK value or progress cost — silently, and it is money. Hence a separate `project_task_boq_drafts` table. |
| Changing contract / SPK value aggregation | Out of scope. The wizard consumes existing aggregates. |
| The Input Progress screen | Specced in the original PRD, not built. Out of scope here. |

## 7. What shipped short of the spec

**The budget gate does not exist.** The original PRD required a 400 at submit when applying the selection drives `contract_value - spk_value` negative. The read path reports that number on every draft response, but `SetProjectTaskBoqAsync` never reads it and never refuses a write. **G4 and US-07 are unmet.**

This was verified in the source, not assumed: the only place either column is read in the whole service is the draft-response builder. FSD §7 GAP-1 has the citation.

The consequence is worth stating plainly: **a planner can see `spk_remaining: "-30000000"` on screen and submit anyway, and it commits.** The number is advisory. Anyone relying on it as a control is relying on something that is not there.

Four smaller gaps — header rows are not submittable, draft concurrency is last-write-wins, `spk_type` is maintained rather than derived (so it can drift), and draws are not scoped to a task's SPK — are recorded as GAP-2 through GAP-5 in the FSD. Three are deliberate; `spk_type` drift is a real defect with a repair script (`audit-project-task-spk-drift.sql`) but no prevention.

## 8. Constraints

- **Stack.** phiDev (.NET 8, EF Core, Carter-style endpoints). No new dependencies.
- **Schema.** Additive only. One new table (`project_task_boq_drafts`); no rewrites.
- **v1 compatibility.** The v1 response body must stay byte-identical. This is why the v2 extras live on a subclass rather than on the shared base, and why the draft's "no draft" answer changed from `data: []` to `data: null` only on a route the FE was already migrating.
- **Concurrency.** Draft upsert is last-write-wins by decision, not by accident.
- **Auth.** Inherited from the route group's `R3ComponentFilter` and bearer auth. No new role gates.

## 9. Demo and verification data

`data.sql` in this folder builds a self-contained scenario — its own contractor, two contracts, two BOQs, one project, five tasks — covering the four states worth demonstrating:

| Scenario | Shows |
|---|---|
| **S-A** happy path | A clean single-SPK task with two submitted lines and recorded progress. |
| **S-B** multi-SPK | A task holding two live SPK assignments, with one line on **both** — the case v1 reports as one SPK and v2 reports in full. |
| **S-C** over-budget | A contract reporting `spk_remaining: "-30000000"` whose lines committed anyway. This is §7 made concrete, not a hypothetical. |
| **S-D** saved draft | A task with no submitted lines and one saved draft, so resume works and the picker marks a line taken on the strength of the draft alone. |

Fixture rows all sit in a reserved GUID range and the script deletes exactly those before inserting, so it is re-runnable and self-cleaning. It has been compile-checked against the dev schema and **not** loaded into any shared database. Loading instructions and smoke curls are in FSD §8.

## 10. Open questions

| # | Question | Owner |
|---|---|---|
| Q1 | Is US-07 (block the submit) still wanted, or has the displayed balance turned out to be enough in practice? | Product + FE |
| Q2 | If blocked: hard 400, or a soft warning the planner can override with a reason? A hard block on a denormalized `spk_value` that nothing recomputes will produce false positives. | Product |
| Q3 | Should `spk_type` be derived at read time instead of maintained, retiring GAP-4 and the repair script? | Backend |
| Q4 | Should `POST /projects/tasks/boqs/draft` and `/draft/delete` also be registered on `/api/v2`? Today only the two GETs are. | FE |
