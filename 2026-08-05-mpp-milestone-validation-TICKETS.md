# Tickets: Milestone Validation for Project Task MPP Upload

Source: [FSD-mpp-milestone-validation](2026-08-05-mpp-milestone-validation-FSD.md) (v0.1) · Coverage: 12 FRs / 8 NFRs → 9 tickets, all covered

## Summary

| ID | Title | Epic | Size | Blocked by | Covers |
|---|---|---|---|---|---|
| T-01 | Define milestone rule constants and category resolution | E1 | S | — | FR-002 |
| T-02 | Implement milestone matching and result computation | E1 | M | T-01 | FR-003, FR-004, FR-005 |
| T-03 | Refuse uploads for projects without a recognised category | E1 | S | T-01 | FR-006, FR-007, NFR-004 |
| T-04 | Add the validation service method and result DTOs | E2 | M | T-02, T-03 | FR-001 (service), FR-012 |
| T-05 | Expose `POST /projects/tasks/upload/validate` | E2 | M | T-04 | FR-001 (endpoint), FR-010, FR-011, NFR-002, NFR-005 |
| T-06 | Enforce milestone validation on the import endpoint | E3 | M | T-02, T-03 | FR-008, FR-009, FR-010, NFR-003, NFR-004 |
| T-07 | Log validation outcomes and rejections | E3 | S | T-05, T-06 | NFR-006 |
| T-08 | Test suite for milestone validation | E4 | M | T-05, T-06 | NFR-001, NFR-007, NFR-008 (verifies FR-001…FR-012) |
| T-09 | Pre-release audit of projects with an empty category `[infra]` | E4 | S | — | PRD Risk 1, PRD Q2 |

**Buildable order:** T-01 → (T-02, T-03 in parallel) → (T-04 → T-05) and T-06 in parallel → T-07 → T-08. T-09 is independent and should land before the release, not before the code.

## Epics

- **E1 — Milestone rule core:** the rule itself — what is required, how names are matched, and how the result is computed. Pure logic, no HTTP surface.
- **E2 — Validation endpoint:** the dry-run that lets the modal show the result before anything is stored.
- **E3 — Import gate:** the same rule applied as a refusal on the existing import endpoint, so it cannot be bypassed.
- **E4 — Verification and release readiness:** tests, and the operational check that the release does not block existing users.

---

## T-01: Define milestone rule constants and category resolution

- **Epic:** E1 · **Size:** S · **Priority:** Must · **Blocked by:** —
- **Covers:** FR-002

**Context**

The rule "Fasprod needs `#On Stream`; NWD needs four named milestones" has to live somewhere before anything can use it. The decision from grilling is a constant in code, not a database table — see [FSD §4 FR-002](2026-08-05-mpp-milestone-validation-FSD.md) and PRD Non-Goal 2.

**Scope of work**

- Add to `ProjectTaskConstant`: the four milestone name constants, `FileStatusValid`, `FileStatusNeedRevision`, `RequiredMilestonesByCategory`, and `CategoryLabels`.
- `RequiredMilestonesByCategory` keys on the stored category value (`fasprod`, `newwelldevelopment`) with an `OrdinalIgnoreCase` comparer, and preserves the FR-002 name order.
- Add a resolver helper that takes a raw `Project.Category` value (nullable), trims it, and returns the required list plus the readable label — or signals "unrecognised" for the caller to handle.

**Acceptance criteria**

- Given a project with category `fasprod`, When the milestone rule is resolved, Then the list contains exactly one name, `#On Stream`.
- Given a project with category `newwelldevelopment`, When the milestone rule is resolved, Then the list contains four names in the order `#Perizinan`, `#Land Acquisition`, `#Site Preparation`, `#On Stream`.
- Given a category value of `"FASPROD"` or `" fasprod "`, When the rule is resolved, Then it resolves to the Fasprod list.
- Given a category value of `"maintenance"`, When the rule is resolved, Then the resolver reports it as unrecognised rather than returning an empty list.

**Out of scope**

Rejecting the request — that is T-03. Matching names against tasks — that is T-02.

**Test notes**

Casing and surrounding whitespace on the category value. The distinction between "unrecognised category" and "recognised category with an empty list" matters: an empty list would silently pass every file.

---

## T-02: Implement milestone matching and result computation

- **Epic:** E1 · **Size:** M · **Priority:** Must · **Blocked by:** T-01
- **Covers:** FR-003, FR-004, FR-005

**Context**

The heart of the feature: given a parsed task list and a required milestone list, decide which milestones are satisfied and produce the Required / Valid / Not Found / File Status figures. Matching rules are in [FSD §4 FR-003](2026-08-05-mpp-milestone-validation-FSD.md), with a full match/no-match table.

**Scope of work**

- Add a helper (in `ProjectTasksHelper`) that matches task names to required milestones: `Trim()` on the task name, `OrdinalIgnoreCase` comparison, no internal whitespace collapsing, skip null/empty/whitespace-only names.
- Keep the topmost matching task per milestone (lowest index in the parsed list) and count occurrences.
- Compute `required_count`, `valid_count`, `not_found_count`, and `file_status` per the FR-005 formula table.
- Keep each helper's cognitive complexity ≤ 15 (`CLAUDE.md`); prefer several small functions over one loop with nested conditionals.

**Acceptance criteria**

- Given a task named `  #on stream `, When matched for a Fasprod project, Then `#On Stream` counts as valid.
- Given a task named `# On Stream`, When matched for a Fasprod project, Then `#On Stream` appears in `not_found`.
- Given three tasks named `#On Stream` at rows 3, 9, and 20, When matched, Then `valid_count = 1`, `occurrence = 3`, and the selected task is the row-3 one.
- Given an NWD project and a file containing only `#Perizinan`, When the result is computed, Then `required_count = 4`, `valid_count = 1`, `not_found_count = 3`, `file_status = "need revision"`.
- Given an NWD project and a file containing all four milestones, When the result is computed, Then `file_status = "valid"` and `not_found` is empty.
- Given a file with zero tasks, When the result is computed, Then `valid_count = 0` and `file_status = "need revision"`.

**Out of scope**

The response DTO shape (T-04) and any HTTP concern.

**Test notes**

Every row of the FR-003 match table, including `#On  Stream` (double internal space), `#OnStream`, `On Stream`, `#On Stream - Well A`, an empty name, and a null name. Also: `valid_count` must never exceed `required_count` even with many duplicates.

---

## T-03: Refuse uploads for projects without a recognised category

- **Epic:** E1 · **Size:** S · **Priority:** Must · **Blocked by:** T-01
- **Covers:** FR-006, FR-007, NFR-004

**Context**

A project whose `Category` is null or unrecognised has no milestone rule to check against, and the decision from grilling is to refuse rather than skip. The check belongs in the shared precondition path so both endpoints inherit it, and it must run before the file is parsed so a large upload is not processed in vain — see [FSD §4 FR-006](2026-08-05-mpp-milestone-validation-FSD.md) and the stage order in FR-010.

**Scope of work**

- Extend the existing precondition path (`ValidateUploadPreconditionsAsync`) with a category check, placed after the project-exists and draft-status checks.
- Return the two distinct messages from FR-006: one for a missing category, one for an unrecognised one (the latter naming the offending value and the supported categories).
- Make the dry-run path reuse the same precondition code, so both endpoints answer identically (FR-007).

**Acceptance criteria**

- Given a draft project with a null `Category`, When either endpoint is called with a well-formed MPP file, Then the response is `400` stating the category is required, and the file is never parsed.
- Given a draft project with `Category` = `"maintenance"`, When the import endpoint is called, Then the response is `400` naming `maintenance` and listing the supported categories, and no tasks are stored.
- Given a project in `in progress` status, When the validation endpoint is called, Then the response is `400` with the same precondition message the import endpoint returns for that condition.

**Out of scope**

Milestone checking itself (T-02/T-06). Retrofitting category validation onto any other endpoint.

**Test notes**

`Category` values of `null`, `""`, `"   "`, and an unrecognised non-empty string are four distinct cases. Verify the file is genuinely not parsed — assert the parser mock is never called.

---

## T-04: Add the validation service method and result DTOs

- **Epic:** E2 · **Size:** M · **Priority:** Must · **Blocked by:** T-02, T-03
- **Covers:** FR-001 (service layer), FR-012

**Context**

The service-layer entry point for the dry-run: run every validation stage, return a result object, and store nothing. The response must carry names as well as counts so the frontend never re-implements the rule ([FSD §4 FR-012](2026-08-05-mpp-milestone-validation-FSD.md), PRD Assumption A2).

**Scope of work**

- Add `ProjectTaskValidationResultDto` and `ProjectTaskMilestoneCheckDto` to `ProjectTasksDto.cs` with `snake_case` `[JsonPropertyName]` attributes, per the FSD §5 field tables.
- Add a `ValidateProjectTaskFileAsync(Guid projectId, string filePath, ...)` method to `IProjectTasksService` / `ProjectTasksService` that runs stages 2–6 and returns the DTO.
- The method must not call `PersistTasksAsync`, `RecordUploadHistoryAsync`, `ApplyTaskWeights`, `BuildSchedulesFromWorkingDays`, or `SendInvalidProjectTaskEmailAsync`, and must not invalidate any cache.
- `milestones` carries one entry per required name in FR-002 order; `matched_task_name` is the file's verbatim name (untrimmed, original casing); `wbs` may be null.

**Acceptance criteria**

- Given a draft NWD project and a file with all four milestones, When the service method runs, Then it returns `file_status = "valid"` and the `project_tasks` row count for that project is unchanged.
- Given the same file validated twice, When the method runs twice, Then both results are identical and no upload history row is written.
- Given three of four milestones found, When the method runs, Then `milestones` has exactly 4 entries and `not_found` exactly 1 name.
- Given a task named `#on stream `, When it matches `#On Stream`, Then `matched_task_name` is `#on stream ` and `name` is `#On Stream`.

**Out of scope**

The HTTP route, file handling, and temp-file cleanup — all T-05.

**Test notes**

The "stores nothing" guarantee deserves an explicit assertion, not just an absence of failures: count rows before and after, and assert the persistence collaborators are never invoked.

---

## T-05: Expose `POST /projects/tasks/upload/validate`

- **Epic:** E2 · **Size:** M · **Priority:** Must · **Blocked by:** T-04
- **Covers:** FR-001 (endpoint), FR-010, FR-011, NFR-002, NFR-005

**Context**

The route the modal calls. It mirrors the existing upload endpoint's request shape so the frontend can send the same form to both — see [FSD §6.1](2026-08-05-mpp-milestone-validation-FSD.md).

**Scope of work**

- Register `POST /projects/tasks/upload/validate` on the existing `ProjectTasks` route group (so it inherits `R3ComponentFilter`), with `DisableAntiforgery()` and route name `ValidateProjectTasksUpload Service`.
- Accept `file` (IFormFile) and `project_id` (form field), and apply the stage-1 request checks: file present and non-empty, `.mpp` extension, `project_id` not the empty Guid.
- Write the temp file under a collision-proof name (Guid-prefixed) and delete it in a `finally` block on every path (NFR-005, FR-011).
- Answer `200` for both `valid` and `need revision`; reserve `400` for the conditions in the FR-001 error table and `500` for unexpected failures.
- Follow the endpoint-mapper split convention in `CLAUDE.md` (`MapValidateProjectTasksUpload` + handler), keeping each method small.

**Acceptance criteria**

- Given a draft NWD project and a complete MPP file, When the endpoint is called, Then the response is `200` with `file_status = "valid"`.
- Given a file missing `#On Stream`, When the endpoint is called, Then the response is `200` with `file_status = "need revision"` and `not_found = ["#On Stream"]` — not a `400`.
- Given a request with no `file` field, When the endpoint is called, Then the response is `400` with `No file uploaded.`
- Given a `.xlsx` file, When the endpoint is called, Then the response is `400` with `Invalid file extension.` and no temp file is written.
- Given no `Authorization` header, When the endpoint is called, Then the response is `401` and the handler never runs.
- Given any call, When the response has returned, Then no leftover temp file for that request remains.

**Out of scope**

Changing the existing upload endpoint's temp-file naming — the old endpoint has the same collision weakness, and fixing it is deliberately not in this scope (FSD NFR-005 note).

**Test notes**

Two concurrent requests carrying identically named files must not interfere. Verify the temp file is deleted on the failure path too (for example a parse failure), not only on success.

---

## T-06: Enforce milestone validation on the import endpoint

- **Epic:** E3 · **Size:** M · **Priority:** Must · **Blocked by:** T-02, T-03
- **Covers:** FR-008, FR-009, FR-010, NFR-003, NFR-004

**Context**

The dry-run is advisory; this ticket is the actual gate. Without it, any client that skips the modal can import an incomplete file ([FSD §4 FR-008](2026-08-05-mpp-milestone-validation-FSD.md), PRD G3).

**Scope of work**

- Insert milestone validation into `CreateProjectTaskFromFileAsync`, after the duplicate-WBS check and before mapping/persistence (stage 6 of FR-010).
- On failure, refuse the whole file through the existing `FailUploadAsync` path with the message `Required milestone task not found: {comma-separated names}. Upload rejected.` — no partial import, no transaction started.
- Add no override: no request parameter, header, config flag, or role may skip the check (NFR-003).
- Keep `CreateProjectTaskFromFileAsync`'s cognitive complexity within budget by delegating to the T-02 helpers rather than inlining logic.

**Acceptance criteria**

- Given an NWD project and an MPP file without `#On Stream`, When the import endpoint is called directly, Then the response is `400` naming `#On Stream` and the project's `project_tasks` row count is unchanged.
- Given an NWD project that already has 50 tasks, When a file without `#On Stream` is imported, Then the response is `400` and the project still has the same 50 tasks.
- Given an NWD project and a complete file, When import is called, Then the import proceeds as before and `total_success` is greater than 0.
- Given a file with duplicate WBS and missing milestones, When import is called, Then the response reports the duplicate-WBS failure, because stage 5 precedes stage 6.

**Out of scope**

Changing replace-all upload semantics, the parse path, weighting, or schedule building.

**Test notes**

The regression that matters most: an existing project's tasks must survive a refused upload. Assert row counts before and after, and confirm no transaction was opened. Also confirm the failure email path behaves as it does today for other whole-file rejections.

---

## T-07: Log validation outcomes and rejections

- **Epic:** E3 · **Size:** S · **Priority:** Should · **Blocked by:** T-05, T-06
- **Covers:** NFR-006

**Context**

PRD goals G1–G4 are measured from logs, not from a new analytics table. Without this ticket there is no way to tell whether the dry-run is catching failures before import ([FSD §9](2026-08-05-mpp-milestone-validation-FSD.md)).

**Scope of work**

- Log each dry-run that reaches stage 6 with `project_id`, `category`, `total_task`, `required_count`, `valid_count`, `not_found_count`, `file_status`, and duration.
- Log an import refused for missing milestones at `Warning` with `project_id`, `category`, and the missing name list.
- Log a category refusal with `project_id` and the verbatim category value (which may be null).
- Log parse failures at `Error` with the original exception.
- Use structured logging in the style already used by the surrounding service; do not log file contents.

**Acceptance criteria**

- Given an import refused for missing milestones, When the request completes, Then a `Warning` entry exists containing the project id and the missing names.
- Given a dry-run that returns `valid`, When the request completes, Then an entry exists carrying the summary counts and duration.
- Given any validation log entry, When it is inspected, Then it contains no file contents and no personal data.

**Out of scope**

Dashboards, alerting, and the monthly G1 audit query (a reporting task, not code).

**Test notes**

Verify the null-category case logs without throwing on the null value.

---

## T-08: Test suite for milestone validation

- **Epic:** E4 · **Size:** M · **Priority:** Must · **Blocked by:** T-05, T-06
- **Covers:** NFR-001, NFR-007, NFR-008 — and verifies FR-001 through FR-012

**Context**

The rule's value depends entirely on the edge cases being right; the FSD's match table and stage order exist precisely because those are the places this can silently go wrong. Tests live in `src-be/Tests` alongside `ProjectTaskUploadHistoryTests.cs`, following the existing xUnit + Moq + in-memory `PhantomDbContext` setup.

**Scope of work**

- Add a test class covering the FR-003 match table in full (exact, casing, edge whitespace, internal whitespace, missing hashtag, substring, empty, null).
- Cover duplicate handling (topmost wins, occurrence counts, `valid_count` capped at `required_count`).
- Cover the result computation for both categories, including the zero-task file.
- Cover stage order: category refusal before parse; duplicate-WBS refusal before milestone check.
- Cover the "stores nothing" guarantee of the dry-run and the "existing tasks survive" guarantee of a refused import.
- Confirm no existing test breaks — in particular the upload and upload-history tests (NFR-008).
- Review the added/changed methods against the cognitive complexity ≤ 15 gate (NFR-007) and record the check in the PR description.
- Measure dry-run duration against a file of roughly 500 tasks and record the figure (NFR-001); no automated performance gate.

**Acceptance criteria**

- Given the test suite, When it runs, Then every row of the FR-003 match table is asserted.
- Given the full solution test run, When it completes, Then all pre-existing tests still pass.
- Given a ~500-task file, When the dry-run runs, Then the measured duration is recorded in the PR and is under 5 seconds.

**Out of scope**

Load testing, and a CI performance gate.

**Test notes**

The parse step should be mocked so the suite does not depend on the external Aspose service; keep one integration-flavoured test if a fixture `.mpp` is already available in the repo.

---

## T-09: Pre-release audit of projects with an empty category `[infra]`

- **Epic:** E4 · **Size:** S · **Priority:** Must · **Blocked by:** —
- **Covers:** PRD Risk 1, PRD Open Question Q2

**Context**

FR-006 refuses uploads for projects with no category. If a meaningful number of draft projects currently have `Category` null, the release blocks those PMs on day one. This is the check that turns an unknown into a decision — see PRD §10 Risks row 1.

**Scope of work**

- Run a count of draft, non-deleted projects whose `Category` is null, empty, or unrecognised, and list them.
- Share the list with Project Control so the values can be filled in before release.
- If the count is large enough to be disruptive, raise it with Product before the release date — the mitigation is data entry, not a code change.
- Draft the user-facing release note: the exact milestone names per category, and the reminder that Category must be set.

**Acceptance criteria**

- Given the audit has run, When the release decision is made, Then the number of affected projects is known and recorded.
- Given affected projects exist, When the release ships, Then Project Control has been notified with the list.

**Out of scope**

Any code change, backfill script, or automatic category assignment. Guessing a project's category is a data-quality decision for humans.

**Test notes**

None — this is an operational task, verified by the artefacts it produces (the count, the list, the release note).
