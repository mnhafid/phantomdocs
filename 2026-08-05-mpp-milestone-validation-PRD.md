# PRD: Milestone Validation for Project Task MPP Upload

| | |
|---|---|
| **Status** | Draft |
| **Author** | Claude (from grilling session with mnhafid) |
| **Date** | 2026-08-05 |
| **Version** | 0.1 |
| **Related docs** | [FSD-mpp-milestone-validation](2026-08-05-mpp-milestone-validation-FSD.md) |

## 1. Overview

Project Managers add Project Tasks by uploading a Microsoft Project file (`.mpp`) through a modal dialog. The modal has three sections: **Download Template**, **Upload Template**, and **Validation Results**. This feature adds the **Validation Results** stage: before any data reaches the database, the system checks whether the MPP file contains the milestone tasks required for the project's **category** — Fasprod requires `#On Stream`; New Well Development (NWD) requires `#Perizinan`, `#Land Acquisition`, `#Site Preparation`, and `#On Stream`. The result is shown as a summary (Required / Valid / Not Found / File Status), and a file that is missing milestones cannot be imported until it is fixed.

## 2. Problem Statement

Milestone tasks such as `#On Stream` mark the key stages of a project and underpin progress reporting and schedule monitoring. Today the MPP upload (`POST /api/v1/projects/tasks/upload`) validates only structural concerns — the project exists and is in draft status, WBS values are not duplicated — and then inserts every task in a single transaction. Nothing checks that the required milestones are actually present.

The consequences:

1. **Incomplete project data goes unnoticed.** An MPP file missing `#On Stream` imports cleanly and the gap only surfaces much later, during reporting.
2. **Fixing it is expensive.** Because upload is replace-all, restoring one missing milestone means repeating the entire upload cycle — and any progress or BoQ data already built on those tasks is affected.
3. **No feedback loop.** Users have no way to see whether their file is correct before pressing Import; failure arrives as a single error message after the process has already run.

## 3. Goals & Success Metrics

| ID | Goal | Metric | Target |
|---|---|---|---|
| G1 | No project tasks are imported without their required milestones | Number of Fasprod/NWD projects that have tasks but lack one or more required milestones (monthly audit query) | 0 for every project uploaded after release, counting from release day |
| G2 | Users learn their file is wrong before any data is stored | Share of failing uploads caught at the dry-run stage rather than at import | ≥ 95% within the first month after release |
| G3 | The rule cannot be bypassed through the API | Number of successful imports that violate the milestone rule (from import endpoint logs) | 0 |
| G4 | Validation feedback is fast enough for the modal to feel responsive | Validation endpoint response time for MPP files of ≤ 500 tasks | < 5 seconds p95 |

## 4. Non-Goals

This iteration explicitly does **not** cover:

1. **A new milestone column or flag on `project_tasks`.** The "topmost duplicate wins" rule only affects how `Valid` is counted, not how data is marked — so there is no schema change. Cut because no downstream consumer has asked for it.
2. **Admin CRUD for the milestone list.** The list lives as a constant in code; changing the rule means a deploy. Cut because the list is fixed by the specification, and adding a table or configuration surface would buy nothing today.
3. **Changes to the On Stream card or downstream reporting.** This feature stops at the import gate. Cut to keep the change to a single layer and easy to review.
4. **Changes to existing validation rules** (project must exist and be in draft, WBS must not be duplicated). Cut because those rules already work and no change was requested.
5. **Changes to the `project-task-template.mpp` file itself.** The template is not updated to include sample milestone rows. Cut because it is not yet confirmed whether the template should carry them; see Open Questions.
6. **Backfill or audit of existing projects.** Projects that already had tasks before release are neither re-validated nor flagged. Cut because the rule is forward-looking.
7. **Frontend implementation.** This repository is backend-only; the modal and the Validation Results display are built by the frontend team against the API contract in the FSD.

## 5. Users & Personas

| Persona | Description | Key need |
|---|---|---|
| **Project Manager (PM)** | Owns the project, builds the schedule in Microsoft Project, then uploads the `.mpp` to Phantom. Comfortable with MS Project, not with APIs. | Learn immediately whether the file meets the requirements, and see exactly which names are missing so they can fix them directly in MS Project. |
| **Project Control / Admin** | Checks project data completeness across projects for reporting. | Confidence that every Fasprod/NWD project carries its required milestones, without checking each one by hand. |
| **Frontend Developer** | Builds the three-section modal. | A clear API contract: one validation call that returns both the summary numbers and the underlying names, so the client never has to compute them itself. |

## 6. User Stories

| ID | Story | Priority (MoSCoW) |
|---|---|---|
| US-01 | As a PM, I want to download the MPP template from the modal, so that my file matches the structure the system expects. | Must |
| US-02 | As a PM, I want to upload an MPP file and see the milestone validation result before anything is stored, so that I never import a wrong file by accident. | Must |
| US-03 | As a PM, I want to see how many milestones are required, how many are valid, and how many are not found, so that I know how far my file is from correct. | Must |
| US-04 | As a PM, I want to see **which** milestone names were not found, so that I can fix them in MS Project without guessing. | Must |
| US-05 | As a PM, I want a file marked Need Revision to be refused for import, so that project data is never stored in an incomplete state. | Must |
| US-06 | As Project Control, I want the rule enforced server-side on the import endpoint, so that no client can bypass it. | Must |
| US-07 | As a PM whose project has no category set, I want to be told to complete the project data first, so that I know what to do. | Must |
| US-08 | As a PM, I want milestone names to still be recognised despite stray leading/trailing spaces or different letter casing, so that a trivial typo does not fail my upload. | Should |

## 7. Requirements (high level)

Detailed behavior, rules, and errors live in the [FSD](2026-08-05-mpp-milestone-validation-FSD.md). Capability summary:

1. **Download the MPP template** from the modal — uses the existing capability, unchanged. *(US-01)*
2. **Validate an MPP file without storing anything (dry-run).** The user uploads a file, the system parses it and returns the milestone validation result; not a single task is stored at this stage. *(US-02)*
3. **Milestone rules per project category.** Fasprod requires 1 name (`#On Stream`); NWD requires 4 (`#Perizinan`, `#Land Acquisition`, `#Site Preparation`, `#On Stream`). Matching ignores leading/trailing whitespace and letter casing, but the hashtag and the internal spacing must match exactly. *(US-03, US-08)*
4. **A validation summary** containing Required Description Data, Valid, Not Found, and File Status (Valid / Need Revision), plus the names behind each figure. A milestone appearing more than once counts only once — the topmost occurrence is taken. *(US-03, US-04)*
5. **Import blocked for Need Revision files.** No partial import; the whole file is refused until fixed. *(US-05)*
6. **Re-enforcement on the import endpoint.** Import runs the same milestone validation, so the dry-run result cannot be skipped by calling import directly. *(US-06)*
7. **Projects without a recognised category are refused** with a message directing the user to complete the project data. *(US-07)*

## 8. Constraints & Dependencies

**Constraints**

- C1. **Backend-only.** This repository (`src-be`) contains no frontend. The three-section modal is built by the frontend team against the API contract in the FSD.
- C2. **The milestone list is hardcoded** as a constant in code (user decision during grilling). Changing the list requires a deploy.
- C3. **No database schema change.** No migration, no new columns (user decision during grilling).
- C4. **The cognitive complexity ≤ 15 per method policy applies** (see `CLAUDE.md`); validation is implemented as focused helpers rather than bolted onto the already-long upload method.
- C5. **Replace-all upload behavior is unchanged.** Import still replaces the project's tasks rather than appending to them.

**Dependencies**

- D1. **The MPP parser (Aspose).** Task names come from the Aspose parse result (`IMppService.ReadFileAsposeAsync`) via the `ParseMppFileAsync` path the upload already uses. If the parser fails or the external service is unavailable, validation cannot run.
- D2. **The `Category` field on the `Project` entity** — nullable, populated with `fasprod` or `newwelldevelopment` (see `ProjectConstant`).
- D3. **The existing template download endpoint** `GET /api/v1/projects/tasks/template`.
- D4. **The frontend team** for the modal; the backend release can ship first.

## 9. Assumptions

- **A1: The dry-run applies the same preconditions as import** — the project exists, is not deleted, and is in `draft` status. — *Impact if wrong:* users see a "valid" result for a project that cannot actually be uploaded to, then fail at import; confusing, but not data-damaging.
- **A2: The validation response carries names, not just counts** — the milestones found and not found are both listed. — *Impact if wrong:* the frontend must compute them from a client-side copy of the required list, duplicating the rule in two places.
- **A3: The Download Template section uses the existing endpoint unchanged.** — *Impact if wrong:* there is unscoped work hiding in this feature.
- **A4: The dry-run writes the uploaded file to a temp folder and deletes it after parsing**, following the existing `finally { File.Delete(...) }` pattern. — *Impact if wrong:* files accumulate on the server disk.
- **A5: The duplicate-WBS check still runs first.** If a file has both a WBS problem and missing milestones, the WBS failure is what gets reported. — *Impact if wrong:* users need two fix-and-retry rounds (fix WBS, re-upload, only then learn milestones are missing).
- **A6: Task names come from the `name` field of the Aspose parse result**, and a task at any level qualifies — header or item, at any WBS depth. — *Impact if wrong:* milestones placed as sub-tasks go undetected and users must move them to the top level.
- **A7: Category values are already normalised** (`fasprod` / `newwelldevelopment`) by the existing project create/update path. Reads are still case-insensitive as a guard against legacy data. — *Impact if wrong:* older projects with different casing are refused as "unrecognised category".
- **A8: No new file-size or task-count limits** beyond what the current upload already enforces. — *Impact if wrong:* very large files make the dry-run slow and G4 is missed.

## 10. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Legacy projects with an empty `Category` suddenly cannot upload tasks at all | Medium | High — the PM is blocked | The error message states exactly what to do ("set the project category"); before release, run a count of draft projects with a null `Category` and brief Project Control |
| Users are frustrated by exact-name matching (e.g. `# On Stream` with a space after the hashtag is refused) | High | Medium | The response carries the required names verbatim so they can be copied; the error message shows the expected name; trim + case-insensitive already forgives the most common slips |
| The file is uploaded twice (validate, then import), so large files travel twice | High | Low | Accepted as the cost of a separate dry-run; if it becomes a real problem, the staging-token option can be revisited |
| The rule changes (milestone names added or renamed) and requires a deploy | Low | Medium | The list sits in a single constant so a change is one line; if the change rate rises, moving it to `custom_configurations` is the natural next step |
| The Aspose parse service is down, so the dry-run fails | Low | Medium | The error is clearly distinguished from "invalid file" so users do not blame their own file |
| Duplicate milestones in a file (two `#On Stream` rows) pass validation even though one is misplaced | Medium | Low | The response reports each milestone's occurrence count so the modal can surface an informative note; the file is not refused, per the grilling decision |

## 11. Release & Rollout

- **MVP is this entire document.** The scope is already narrow; there is no phasing.
- **Release order:** backend first (validation endpoint + import enforcement), frontend after. During that gap the import endpoint already refuses files missing milestones with a human-readable message, so there is no dangerous half-state.
- **No feature flag.** The change tightens validation, does not touch existing data, and can be undone with a revert.
- **No data migration.** No schema change, no backfill.
- **Communication:** before release, tell PMs that from release day MPP files must carry the milestones for their category, include the exact names, and remind them that the project must have a Category set.

## 12. Open Questions

| # | Question | Owner | Impact if unresolved |
|---|---|---|---|
| Q1 | Should `project-task-template.mpp` be updated to already contain sample milestone rows? | Product / mnhafid | Not blocking. If yes, it becomes a separate ticket outside this scope (see Non-Goal 5). |
| Q2 | How many draft projects currently have an empty `Category`? | Project Control | Sizes the impact of the "refuse upload" decision in Risks row 1; should be checked before release. |
| Q3 | Will milestone tasks later need to be marked in the database for the On Stream card? | Product | Not blocking this iteration; if it materialises, it becomes a separate iteration with a migration. |
