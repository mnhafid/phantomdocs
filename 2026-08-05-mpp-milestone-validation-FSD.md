# FSD: Milestone Validation for Project Task MPP Upload

| | |
|---|---|
| **Status** | Draft |
| **Related PRD** | [PRD-mpp-milestone-validation](2026-08-05-mpp-milestone-validation-PRD.md) |
| **Date** | 2026-08-05 |
| **Version** | 0.1 |

## 1. System Overview

This feature inserts one new validation stage — **checking milestone task names against the project category** — into the Project Task MPP upload flow, and exposes that stage as a standalone *dry-run* endpoint so the modal can display the outcome before anything is stored.

There is one rule, applied twice: once by the dry-run endpoint (storing nothing), and again by the import endpoint (as a gate). The result the user sees in the modal is therefore identical to the decision the server makes at import, and the rule cannot be bypassed by calling import directly.

```
                    ┌──────────────────────── Modal Dialog ────────────────────────┐
                    │  1. Download Template   2. Upload Template   3. Validation    │
                    └──────┬──────────────────────┬────────────────────────┬────────┘
                           │                      │                        │
                  GET /projects/tasks/    POST /projects/tasks/    (Import button enabled
                       template            upload/validate           only when Valid)
                           │                      │                        │
                           │                      ▼                        ▼
                           │            ┌──────────────────┐    POST /projects/tasks/upload
                           │            │  DRY-RUN         │               │
                           │            │  stores nothing  │               ▼
                           ▼            └────────┬─────────┘    ┌──────────────────────┐
                  project-task-                  │              │  IMPORT              │
                  template.mpp                   │              │  re-validate,        │
                                                 │              │  then persist        │
                                                 │              └──────────┬───────────┘
                                                 │                         │
                                                 ▼                         ▼
                                    ┌───────────────────────────────────────────────┐
                                    │  Shared validation pipeline (fixed order)     │
                                    │  1. Project exists, not deleted, draft        │
                                    │  2. Category recognised (fasprod / nwd)       │
                                    │  3. Parse MPP (Aspose)                        │
                                    │  4. No duplicate WBS                          │
                                    │  5. ► MILESTONE VALIDATION (new)              │
                                    └───────────────────────────────────────────────┘
```

**Components touched**

| Component | Change |
|---|---|
| `ProjectTaskConstant` | Add the per-category milestone list and file-status constants |
| `ProjectTasksDto` | Add the validation result DTOs |
| `ProjectTasksService` / `IProjectTasksService` | Add the dry-run validation method and milestone helpers; insert the gate into `CreateProjectTaskFromFileAsync` |
| `ProjectTasksEndPoint` | Add route `POST /projects/tasks/upload/validate` |
| `ProjectTasksHelper` | Home for the name-normalisation and milestone-matching helpers |

Nothing in `DataAccess` changes (no new entity, migration, or view).

## 2. Scope

**In scope**

- A dry-run endpoint that validates an MPP file against the per-category milestone rule.
- The milestone rule definitions for categories `fasprod` and `newwelldevelopment`.
- Name-matching rules, duplicate handling, and the result summary computation.
- Refusing projects whose category is empty or unrecognised, on both endpoints.
- Enforcing the same rule on the existing import endpoint.
- A response contract that carries both the summary numbers and the underlying names.

**Out of scope**

- Any milestone column or flag on `project_tasks`, and any migration.
- Runtime CRUD or configuration for the milestone list.
- Changes to the `.mpp` template file.
- Changes to existing parse, mapping, weighting, schedule, and persistence behavior.
- Changes to the On Stream card and downstream reporting.
- Backfill or audit of projects that already had tasks before release.
- The modal UI itself (backend-only repository).

## 3. User Flows

### Flow A — Happy path: complete file (US-01, US-02, US-03)

1. The PM opens the "Add Project Task" modal on a draft project.
2. The PM presses **Download Template**; the client calls `GET /api/v1/projects/tasks/template` and the browser downloads `project-task-template.mpp`.
3. The PM builds the schedule in MS Project, making sure the tasks required by the project's category are present, and saves the `.mpp` file.
4. The PM selects the file in the **Upload Template** section.
5. The client calls `POST /api/v1/projects/tasks/upload/validate` with `file` and `project_id`.
6. The server checks the preconditions, parses the file, runs milestone validation, then deletes the temp file.
7. The server returns `200` with `file_status = "valid"`, `required_count = 4`, `valid_count = 4`, `not_found_count = 0` (NWD example).
8. The **Validation Results** section shows the summary; the **Import** button becomes enabled.
9. The PM presses **Import**; the client calls `POST /api/v1/projects/tasks/upload` with the same file and `project_id`.
10. The server repeats the full validation, then imports the tasks. The modal closes and the project task list refreshes.

### Flow B — File missing milestones (US-04, US-05)

1. Steps 1–6 as in Flow A.
2. The server returns `200` with `file_status = "need revision"`, `valid_count = 3`, `not_found_count = 1`, and `not_found = ["#On Stream"]`.
3. The **Validation Results** section shows the summary along with the names not yet found; the **Import** button stays disabled.
4. The PM fixes the file in MS Project and repeats from step 4 of Flow A.

### Flow C — Import called directly, skipping the dry-run (US-06)

1. A client (or any script) calls `POST /api/v1/projects/tasks/upload` with a file that is missing milestones.
2. The server runs the preconditions, parse, and WBS check, then milestone validation.
3. Validation fails; the server returns `400` naming the missing milestones. No tasks are stored.

### Flow D — Project without a recognised category (US-07)

1. The PM uploads a file to a project whose `Category` is empty.
2. The server refuses at the precondition stage — before the file is parsed — and returns `400` with a message telling the user to set the project category first.
3. The behavior is identical on the dry-run and import endpoints.

### Flow E — Not an MPP file, or a file that fails to parse

1. The PM selects an `.xlsx` file, or a corrupt `.mpp`.
2. For the wrong extension, the server refuses before writing a temp file.
3. For an unparseable file, the server refuses after attempting the parse, with a message that distinguishes "file cannot be read" from "milestones incomplete".

## 4. Functional Requirements

### FR-001: Dry-run validation endpoint

- **Traces to:** G2 / US-02
- **Priority:** Must
- **Description:** The system shall provide an endpoint that accepts one MPP file and a `project_id`, runs the full upload validation, and returns the milestone validation result **without creating, modifying, or deleting any row** in `project_tasks`, `project_task_schedules`, or the upload history table.
- **Trigger / Input:** `POST /api/v1/projects/tasks/upload/validate`, `multipart/form-data`, field `file` (a single file with the `.mpp` extension) and `project_id` (Guid, not `Guid.Empty`).
- **Behavior:**
  - Runs the validation stages in the order fixed by FR-010.
  - Does not call `PersistTasksAsync`, `RecordUploadHistoryAsync`, `ApplyTaskWeights`, `BuildSchedulesFromWorkingDays`, or `SendInvalidProjectTaskEmailAsync`.
  - Invalidates no cache.
  - Returns the payload defined in FR-012.
  - The result is stateless: calling the endpoint repeatedly with the same file yields the same payload (except `process_time`).
- **Validation & Errors:**

  | Condition | HTTP | Message |
  |---|---|---|
  | `file` absent or zero-length | 400 | `No file uploaded.` |
  | `project_id` = `00000000-0000-0000-0000-000000000000` | 400 | `Invalid projectid: {projectId}.` |
  | Extension is not `.mpp` | 400 | `Invalid file extension.` |
  | Project not found / deleted | 400 | `Project {projectId} not found` |
  | Project is not in draft status | 400 | the existing precondition message, unchanged |
  | Category empty / unrecognised | 400 | see FR-006 |
  | File fails to parse | 400 | `Failed to read MPP file. Make sure the file is a valid Microsoft Project file.` |
  | Duplicate WBS | 400 | `Duplicate breakdown (WBS) found in file: {list}. Upload rejected.` |
  | Unexpected failure | 500 | `Failed to validate file` |

  The `code` field on `ApiResponse` stays an empty string, following the `ApiResponseHelper` convention already used across this repository; error identity is carried by `message`.
- **Edge cases:**
  - An MPP file with no tasks at all → the parse succeeds, `total_task = 0`, every milestone is not found, `file_status = "need revision"`.
  - A request without an `Authorization` header → `401` from `R3ComponentFilter`, before the handler runs.
  - Two concurrent requests for the same project → no conflict; the dry-run writes nothing.
  - The temp file is deleted on both the success and the failure path (FR-011).
- **Acceptance criteria:**
  - Given a draft NWD project and an MPP file containing all four milestone names, When the client calls the validation endpoint, Then the response is `200` with `file_status = "valid"` and the `project_tasks` row count for that project is unchanged.
  - Given a valid MPP file, When the validation endpoint is called twice in a row, Then both responses carry identical `data` and no upload history is recorded.
  - Given a request with no `file` field, When the endpoint is called, Then the response is `400` with the message `No file uploaded.`

### FR-002: Required milestone list per category

- **Traces to:** G1 / US-03
- **Priority:** Must
- **Description:** The system shall determine the list of required milestone task names from the project's `Category`, using a fixed list defined in code.
- **Trigger / Input:** The `Project.Category` value (string, nullable).
- **Behavior:**

  | Category (stored value) | Label | Required milestone names (in order) | Required count |
  |---|---|---|---|
  | `fasprod` | Fasprod | `#On Stream` | 1 |
  | `newwelldevelopment` | New Well Development | `#Perizinan`, `#Land Acquisition`, `#Site Preparation`, `#On Stream` | 4 |
  | anything else, or empty/null | — | — | refused, see FR-006 |

  - The list lives in the constant `ProjectTaskConstant.RequiredMilestonesByCategory`, typed `IReadOnlyDictionary<string, IReadOnlyList<string>>`, with an `OrdinalIgnoreCase` key comparer.
  - The order of names within a list determines the order of elements in the response, so the modal renders consistently across calls.
  - The category lookup is case-insensitive against the stored value (see PRD Assumption A7).
- **Validation & Errors:** none; this is a data definition, and lookup failure is handled by FR-006.
- **Edge cases:**
  - `Category` of `"Fasprod"` or `"FASPROD"` → still recognised as Fasprod.
  - `Category` of `" fasprod "` (with spaces) → trimmed before lookup.
- **Acceptance criteria:**
  - Given a project with category `fasprod`, When the milestone rule is resolved, Then the list contains exactly one name, `#On Stream`.
  - Given a project with category `newwelldevelopment`, When the milestone rule is resolved, Then the list contains four names in the order `#Perizinan`, `#Land Acquisition`, `#Site Preparation`, `#On Stream`.

### FR-003: Task name matching rule

- **Traces to:** G1 / US-08
- **Priority:** Must
- **Description:** The system shall treat a task as satisfying a required milestone when the task name, after leading and trailing whitespace is removed, equals the milestone name under a case-insensitive comparison.
- **Trigger / Input:** The task name from the Aspose parse result (the `name` field on `MppContentResult`), and the milestone names from FR-002.
- **Behavior:**
  - Normalisation: `name.Trim()`. Nothing else changes — internal whitespace is **not** collapsed, non-ASCII characters are not altered, and the hashtag may not be dropped.
  - Comparison: `StringComparison.OrdinalIgnoreCase`.
  - Tasks whose name is `null`, empty, or whitespace-only are ignored entirely and never match any milestone.
  - A task at any level qualifies: header or item, at any WBS depth (see PRD Assumption A6).

  Behavior against the milestone `#On Stream`:

  | Task name in the file | Match? | Reason |
  |---|---|---|
  | `#On Stream` | Yes | exact |
  | `#on stream` | Yes | casing ignored |
  | `#On Stream ` (trailing space) | Yes | edge whitespace trimmed |
  | `  #On Stream` | Yes | edge whitespace trimmed |
  | `# On Stream` | No | extra space inside the name after the hashtag |
  | `#On  Stream` (double space) | No | internal whitespace is not collapsed |
  | `On Stream` | No | hashtag missing |
  | `#On Stream - Well A` | No | this is not substring matching |
  | `#OnStream` | No | space missing |
  | `` (empty) / `null` | No | empty names are ignored |
- **Validation & Errors:** no dedicated error; a non-matching name simply means the milestone is not yet satisfied.
- **Edge cases:** task names containing invisible characters (for example a non-breaking space ` `) do not match, because .NET's `Trim()` does not remove them from the middle and the comparison is ordinal.
- **Acceptance criteria:**
  - Given the file contains a task named `  #on stream `, When validation runs for a Fasprod project, Then the milestone `#On Stream` counts as valid.
  - Given the file contains a task named `# On Stream`, When validation runs for a Fasprod project, Then `#On Stream` appears in `not_found`.
  - Given the file contains a task with an empty name, When validation runs, Then that task does not affect the result.

### FR-004: Duplicate milestone handling

- **Traces to:** G1 / US-03
- **Priority:** Must
- **Description:** The system shall count each required milestone at most once, and when several tasks match the same milestone, shall select the task that appears topmost in the file.
- **Trigger / Input:** The parsed task collection, in the order the parser returns it (the row order of the MPP file).
- **Behavior:**
  - "Topmost" means the lowest index in the parsed task list.
  - The selected task only affects the reported detail (the verbatim name and WBS in the response); nothing is marked in the database.
  - The other duplicates are still imported as ordinary tasks at import time — a duplicate is not an error condition.
  - Each milestone's occurrence count is reported so the modal can surface an informative note.
- **Validation & Errors:** none; duplicates do not refuse the file.
- **Edge cases:**
  - Four tasks named `#On Stream` on a Fasprod project → `valid_count = 1`, `occurrence = 4`, `file_status = "valid"`.
  - Two tasks matching different milestones → both count, one each.
- **Acceptance criteria:**
  - Given a Fasprod file with three tasks named `#On Stream` at rows 3, 9, and 20, When validation runs, Then `valid_count = 1`, `occurrence = 3`, and the milestone detail points at the row-3 task.
  - Given an NWD file with two `#Perizinan` tasks and no `#On Stream`, When validation runs, Then `valid_count = 3` and `not_found_count = 1`.

### FR-005: Validation result computation

- **Traces to:** G1, G2 / US-03
- **Priority:** Must
- **Description:** The system shall compute Required Description Data, Valid, Not Found, and File Status from the matching outcome.
- **Trigger / Input:** The required milestone list (FR-002) and the matching outcome (FR-003, FR-004).
- **Behavior:**

  | Field | Formula |
  |---|---|
  | `required_count` | the number of names in the project category's required list |
  | `valid_count` | the number of required names with at least one matching task (capped at `required_count`) |
  | `not_found_count` | `required_count − valid_count` |
  | `file_status` | `"valid"` when `not_found_count = 0`, otherwise `"need revision"` |

  - `file_status` uses the constants `ProjectTaskConstant.FileStatusValid = "valid"` and `ProjectTaskConstant.FileStatusNeedRevision = "need revision"`, following the lowercase style of the existing status constants.
  - `valid_count` can never exceed `required_count`, because each required name counts at most once (FR-004).
- **Validation & Errors:** none.
- **Edge cases:** a file with no tasks at all → `valid_count = 0`, `not_found_count = required_count`, `file_status = "need revision"`.
- **Acceptance criteria:**
  - Given an NWD project and a file containing all four milestones, When validation runs, Then `required_count = 4`, `valid_count = 4`, `not_found_count = 0`, `file_status = "valid"`.
  - Given an NWD project and a file containing only `#Perizinan`, When validation runs, Then `required_count = 4`, `valid_count = 1`, `not_found_count = 3`, `file_status = "need revision"`.
  - Given a Fasprod project and a file with no `#On Stream`, When validation runs, Then `not_found_count = 1` and `file_status = "need revision"`.

### FR-006: Refusing projects without a recognised category

- **Traces to:** G1 / US-07
- **Priority:** Must
- **Description:** The system shall refuse both validation and import when `Project.Category` is null, empty, whitespace-only, or not listed in FR-002.
- **Trigger / Input:** The `Project.Category` value read during the precondition stage.
- **Behavior:**
  - The check runs **after** the project-exists and draft-status checks, and **before** the file is parsed — so a large file is never processed in vain.
  - It behaves identically on the dry-run and import endpoints.
  - No tasks are stored.
- **Validation & Errors:**

  | Condition | HTTP | Message |
  |---|---|---|
  | `Category` null / empty / whitespace-only | 400 | `Project category is required before uploading tasks. Please set the project category first.` |
  | `Category` present but unrecognised | 400 | `Project category '{category}' does not have a task milestone rule. Supported categories: Fasprod, New Well Development.` |
- **Edge cases:** a project uploaded to repeatedly with an empty category always receives the same message; there are no side effects.
- **Acceptance criteria:**
  - Given a draft project with a null `Category`, When the validation endpoint is called with a well-formed MPP file, Then the response is `400` stating the category is required, and the file is never parsed.
  - Given a draft project with `Category` set to `"maintenance"`, When the import endpoint is called, Then the response is `400` stating the category is unrecognised and no tasks are stored.

### FR-007: Dry-run preconditions mirror import preconditions

- **Traces to:** G2 / US-02
- **Priority:** Must
- **Description:** The system shall apply exactly the same preconditions on the dry-run and on import: the project exists, `deleted_at` is null, and the project status is `draft`.
- **Trigger / Input:** The `project_id` from the request.
- **Behavior:** the dry-run uses the same check path as `ValidateUploadPreconditionsAsync`, so there is no state in which the dry-run reports "valid" for a project that import would then refuse on preconditions.
- **Validation & Errors:** messages follow the current precondition messages, unchanged.
- **Edge cases:** a project that moves from `draft` to `in progress` between the dry-run and import → import refuses with the precondition message; this is accepted and needs no special handling.
- **Acceptance criteria:**
  - Given a project in `in progress` status, When the validation endpoint is called, Then the response is `400` with the same precondition message the import endpoint returns for the same condition.

### FR-008: Milestone enforcement on the import endpoint

- **Traces to:** G3 / US-05, US-06
- **Priority:** Must
- **Description:** The system shall refuse the whole file at the import endpoint when milestone validation fails, importing no tasks at all.
- **Trigger / Input:** `POST /api/v1/projects/tasks/upload`.
- **Behavior:**
  - Milestone validation runs before the mapping and persistence stages.
  - A failure is treated as a whole-file rejection, consistent with the `FailUploadAsync` path used for duplicate WBS: no partial import, and the transaction never starts.
  - There is no override mechanism for any role.
- **Validation & Errors:**

  | Condition | HTTP | Message |
  |---|---|---|
  | One or more required milestones not found | 400 | `Required milestone task not found: {comma-separated names}. Upload rejected.` |

  The response follows the current upload-rejection shape — `400` with `message` taken from the first failure entry.
- **Edge cases:**
  - A file that passed the dry-run and was then edited before import → import refuses it, because validation runs against the bytes actually sent.
  - A client that calls import without ever calling the dry-run → identical behavior; the dry-run is not a technical prerequisite.
- **Acceptance criteria:**
  - Given an NWD project and an MPP file without `#On Stream`, When the import endpoint is called directly, Then the response is `400` naming `#On Stream`, and the `project_tasks` row count for that project is unchanged.
  - Given an NWD project and a complete MPP file, When the import endpoint is called, Then the import proceeds as before and `total_success` is greater than 0.

### FR-009: Existing tasks survive a failed upload

- **Traces to:** G1 / US-05
- **Priority:** Must
- **Description:** The system shall ensure a project's existing tasks are neither deleted nor replaced when the uploaded file fails milestone validation.
- **Trigger / Input:** `POST /api/v1/projects/tasks/upload` on a project that already has tasks.
- **Behavior:** because milestone validation runs before `PersistTasksAsync`, the deletion/replacement of existing tasks never begins for a refused file.
- **Validation & Errors:** as FR-008.
- **Edge cases:** repeated failed uploads never leave the project empty.
- **Acceptance criteria:**
  - Given an NWD project that already has 50 tasks, When an MPP file without `#On Stream` is imported, Then the response is `400` and the project still has the same 50 tasks.

### FR-010: Validation stage order

- **Traces to:** G2 / US-02
- **Priority:** Must
- **Description:** The system shall run the validation stages in the following fixed order, stopping at the first failure.
- **Trigger / Input:** every dry-run and import call.
- **Behavior:**

  | Order | Stage | On failure |
  |---|---|---|
  | 1 | Request validation (file present, `.mpp` extension, `project_id` not the empty Guid) | 400, no temp file created |
  | 2 | Project exists, not deleted, in draft status | 400 |
  | 3 | Category recognised (FR-006) | 400, file not yet parsed |
  | 4 | MPP file parse | 400 |
  | 5 | No duplicate WBS | 400 |
  | 6 | Milestone validation (FR-002 through FR-005) | dry-run: 200 with `need revision`; import: 400 |

  The difference at stage 6 is deliberate: the dry-run's job is to *report* the outcome, while import's job is to *refuse*. Stages 1–5 behave identically on both endpoints.
- **Validation & Errors:** see the individual FRs.
- **Edge cases:** a file with both duplicate WBS **and** missing milestones is reported as a WBS failure first (see PRD Assumption A5).
- **Acceptance criteria:**
  - Given a file with duplicate WBS and no `#On Stream`, When the validation endpoint is called, Then the response is `400` with the duplicate-WBS message, not `200` with `need revision`.
  - Given a project with an empty category and a corrupt MPP file, When the validation endpoint is called, Then the response is `400` with the category message, because stage 3 precedes stage 4.

### FR-011: Temporary file cleanup

- **Traces to:** G4
- **Priority:** Must
- **Description:** The system shall delete the temporary file written during a dry-run, on both the success and the failure path.
- **Trigger / Input:** every dry-run call that reaches the point of writing a file to disk.
- **Behavior:** follows the `finally { if (File.Exists(filePath)) File.Delete(filePath); }` pattern already used by `UploadProjectTasksAsync`.
- **Validation & Errors:** a failed deletion does not change the response returned to the user, but is written to the log.
- **Edge cases:** two concurrent requests carrying identically named files for different projects can overwrite each other, because the temp file name derives from the uploaded file name — see NFR-005.
- **Acceptance criteria:**
  - Given any validation call, When the response has been returned, Then no leftover file for that request remains in the upload folder.

### FR-012: Validation result shape

- **Traces to:** G2 / US-03, US-04
- **Priority:** Must
- **Description:** The system shall return both the summary numbers and the per-milestone detail, so that the client never has to duplicate the milestone rule.
- **Trigger / Input:** a dry-run that passes stages 1–5.
- **Behavior:** the `data` payload carries the fields listed in the Data Model (§5). Content rules:
  - `milestones` contains one entry for **every** required name, found or not, in the FR-002 order.
  - `found = false` → `matched_task_name` and `wbs` are `null`, and `occurrence = 0`.
  - `found = true` → `matched_task_name` carries the task name **verbatim from the file** (not trimmed, casing untouched) so the user sees what is actually written; `wbs` is populated when the parser supplies it.
  - `not_found` is the list of required names with `found = false`, in the same order.
  - `category` carries the stored value, `category_label` a human-readable label (`Fasprod` / `New Well Development`).
- **Validation & Errors:** none.
- **Edge cases:** `required_count` always equals the length of the `milestones` array.
- **Acceptance criteria:**
  - Given an NWD project with three milestones found, When validation runs, Then the `milestones` array has exactly 4 entries and `not_found` exactly 1 name.
  - Given a file task named `#on stream `, When the milestone `#On Stream` is matched from it, Then `matched_task_name` is `#on stream ` (verbatim) and `name` is `#On Stream` (the canonical form).

## 5. Data Model

**No database schema change.** No new table, column, index, view, or migration. The feature only reads `projects.category` and the file parse result.

### Data read

| Source | Field | Type | Notes |
|---|---|---|---|
| `projects` | `category` | `nvarchar`, nullable | matched case-insensitively after trimming |
| `projects` | `status`, `deleted_at` | — | existing preconditions |
| Aspose parse result (`MppContentResult`) | `name` | `string?` | the source for milestone matching |
| Aspose parse result (`MppContentResult`) | `wbs` | `string?` | reported in the detail, optional |

### New structures (in-memory / DTO)

**`ProjectTaskConstant`** — added constants:

| Name | Type | Value |
|---|---|---|
| `FileStatusValid` | `const string` | `"valid"` |
| `FileStatusNeedRevision` | `const string` | `"need revision"` |
| `MilestoneOnStream` | `const string` | `"#On Stream"` |
| `MilestonePerizinan` | `const string` | `"#Perizinan"` |
| `MilestoneLandAcquisition` | `const string` | `"#Land Acquisition"` |
| `MilestoneSitePreparation` | `const string` | `"#Site Preparation"` |
| `RequiredMilestonesByCategory` | `IReadOnlyDictionary<string, IReadOnlyList<string>>` | `OrdinalIgnoreCase` keys; see FR-002 |
| `CategoryLabels` | `IReadOnlyDictionary<string, string>` | `fasprod` → `Fasprod`, `newwelldevelopment` → `New Well Development` |

**`ProjectTaskValidationResultDto`** (new, in `ProjectTasksDto.cs`):

| JSON field | Type | Description |
|---|---|---|
| `project_id` | `Guid` | the project validated |
| `category` | `string` | the stored value, e.g. `newwelldevelopment` |
| `category_label` | `string` | the readable label, e.g. `New Well Development` |
| `file_name` | `string` | the uploaded file name |
| `total_task` | `int` | the number of tasks parsed |
| `required_count` | `int` | Required Description Data |
| `valid_count` | `int` | Valid |
| `not_found_count` | `int` | Not Found |
| `file_status` | `string` | `valid` \| `need revision` |
| `milestones` | `List<ProjectTaskMilestoneCheckDto>` | one entry per required name |
| `not_found` | `List<string>` | the required names not yet found |

**`ProjectTaskMilestoneCheckDto`** (new):

| JSON field | Type | Description |
|---|---|---|
| `name` | `string` | the canonical required name, e.g. `#On Stream` |
| `found` | `bool` | whether it is satisfied |
| `occurrence` | `int` | how many tasks matched; `0` when not found |
| `matched_task_name` | `string?` | the verbatim task name from the file (topmost row); `null` when not found |
| `wbs` | `string?` | the selected task's WBS; `null` when unavailable |

JSON naming uses `snake_case` via `[JsonPropertyName]`, following the other DTOs in `ProjectTasksDto.cs`.

**Retention / PII:** no personal data. The temporary MPP file is deleted after processing (FR-011); on the dry-run its contents are never stored.

## 6. Interfaces

### 6.1 `POST /api/v1/projects/tasks/upload/validate` *(new)*

| | |
|---|---|
| **Auth** | Bearer token; passes through `R3ComponentFilter` by being registered on the same `ProjectTasks` route group |
| **Content-Type** | `multipart/form-data` |
| **Antiforgery** | disabled (`DisableAntiforgery()`), matching the existing upload endpoint |
| **Route name** | `ValidateProjectTasksUpload Service` |

**Request**

| Field | Type | Required | Notes |
|---|---|---|---|
| `file` | file | yes | a single file with the `.mpp` extension |
| `project_id` | Guid (form field) | yes | not `Guid.Empty` |

**Response `200 OK`**

```json
{
  "process_time": "1843.2ms",
  "status": "success",
  "code": "",
  "message": "File validated successfully",
  "data": {
    "project_id": "6f2b1e4c-9d55-4a10-8f3e-2c1b7a9d4e88",
    "category": "newwelldevelopment",
    "category_label": "New Well Development",
    "file_name": "nwd-schedule-2026.mpp",
    "total_task": 128,
    "required_count": 4,
    "valid_count": 3,
    "not_found_count": 1,
    "file_status": "need revision",
    "milestones": [
      { "name": "#Perizinan",        "found": true,  "occurrence": 1, "matched_task_name": "#Perizinan",   "wbs": "1.2" },
      { "name": "#Land Acquisition", "found": true,  "occurrence": 2, "matched_task_name": "#land acquisition", "wbs": "1.5" },
      { "name": "#Site Preparation", "found": true,  "occurrence": 1, "matched_task_name": "#Site Preparation ", "wbs": "2.1" },
      { "name": "#On Stream",        "found": false, "occurrence": 0, "matched_task_name": null, "wbs": null }
    ],
    "not_found": ["#On Stream"]
  }
}
```

A passing file (`file_status = "valid"`) uses the same shape with `valid_count = required_count`, `not_found_count = 0`, and an empty `not_found` array.

**Response `400 Bad Request`**

```json
{
  "process_time": "12.4ms",
  "status": "failed",
  "code": "",
  "message": "Project category is required before uploading tasks. Please set the project category first."
}
```

**Status codes**

| Status | When |
|---|---|
| `200` | Validation ran; `file_status` carries the outcome (`valid` or `need revision`) |
| `400` | Invalid request, failed precondition, unrecognised category, parse failure, or duplicate WBS |
| `401` | Missing or invalid `Authorization` header |
| `500` | Unexpected failure |

> Design note: a file missing milestones still answers `200`, not `400`. This endpoint's job is to report the outcome of a check; a failed check is a *result*, not a *protocol error*. The refusal still happens at the import endpoint (FR-008).

### 6.2 `POST /api/v1/projects/tasks/upload` *(changed)*

The request contract and the success response are unchanged. What changes: new rejection conditions.

| Change | Detail |
|---|---|
| New rejection | `400` with `message` = `Required milestone task not found: {list}. Upload rejected.` |
| New rejection | `400` with the category message from FR-006 |
| Success behavior | unchanged |

### 6.3 `GET /api/v1/projects/tasks/template` *(unchanged)*

Used by the Download Template section. No change to the route, the response, or the template file.

### 6.4 Events & third-party integrations

- **No new events** are emitted or consumed.
- **Consumed:** the Aspose parse service via `IMppService.ReadFileAsposeAsync` — already used by the current upload flow, with no contract change.
- **Failure notification email** (`SendInvalidProjectTaskEmailAsync`) is **not** sent by the dry-run; behavior on the import endpoint is unchanged.

## 7. Non-Functional Requirements

### NFR-001: Validation performance

- **Requirement:** the dry-run endpoint returns within < 5 seconds p95 for MPP files of ≤ 500 tasks, measured from `process_time` on the response. Milestone matching itself runs in a single pass over the task list (O(n) in the number of tasks, with at most 4 required milestones).
- **Traces to:** G4

### NFR-002: Authorisation

- **Requirement:** the dry-run endpoint requires the same session as the upload endpoint — registered on a route group that passes through `R3ComponentFilter`, so a request without a valid Bearer token is refused with `401` before the handler runs. There is no anonymous path.
- **Traces to:** G3

### NFR-003: The rule cannot be bypassed

- **Requirement:** no request parameter, header, configuration flag, or role can disable milestone validation on the import endpoint.
- **Traces to:** G3

### NFR-004: Error message clarity

- **Requirement:** every rejection message states a concrete cause and the action the user must take, and carries the missing milestone names exactly as they must be typed in MS Project. Messages are written in English, matching every existing error message on these endpoints.
- **Traces to:** G2

### NFR-005: Temporary file isolation

- **Requirement:** the dry-run's temporary file is written under a name that cannot collide across concurrent requests (for example prefixed with a Guid), and is deleted after processing. Without this, two users uploading identically named files overwrite each other.
- **Traces to:** G2
- **Note:** the existing upload endpoint uses the uploaded file name verbatim and has the same weakness; fixing the old endpoint is out of scope for this document, but the new endpoint must not repeat it.

### NFR-006: Observability

- **Requirement:** every milestone validation rejection is logged at `Warning` level with `project_id`, `category`, and the list of names not found. Parse failures are logged at `Error` level with the original exception.
- **Traces to:** G2, G3

### NFR-007: Cognitive complexity

- **Requirement:** every added or modified method stays at cognitive complexity ≤ 15, per `CLAUDE.md`. Milestone validation is implemented as focused helpers (for example `ResolveRequiredMilestones`, `MatchMilestones`, `BuildValidationResult`) rather than as another block inside the already-long `CreateProjectTaskFromFileAsync`.
- **Traces to:** — (internal repository standard)

### NFR-008: Contract stability

- **Requirement:** adding the endpoint changes the response shape of no existing endpoint. Existing clients calling `/projects/tasks/upload` keep working for files that satisfy the rule.
- **Traces to:** G3

## 8. Permissions & Roles

This feature adds no new permission dimension. The dry-run endpoint inherits the same access control as the upload endpoint.

| Role | Download template | Validate (dry-run) | Import | Override a Need Revision file |
|---|---|---|---|---|
| User with project task upload access | Yes | Yes | Yes | No — there is no override mechanism |
| User without project task upload access | Per current behavior | No | No | No |
| Unauthenticated | No | No (`401`) | No (`401`) | No |

Department/organisation scoping follows the behavior already in force on the upload endpoint; this feature neither adds to nor loosens that scope.

## 9. Analytics & Telemetry

The PRD metrics are measured from structured logs; no new analytics table.

| Event | Emitted when | Properties | Measures |
|---|---|---|---|
| `project_task_upload_validated` | Every dry-run that reaches stage 6 | `project_id`, `category`, `total_task`, `required_count`, `valid_count`, `not_found_count`, `file_status`, `duration_ms` | G2 (dry-run detection rate), G4 (p95 duration) |
| `project_task_upload_rejected_milestone` | An import refused for missing milestones | `project_id`, `category`, `missing` (name list) | G1, G3 — any value above 0 means a client skipped the modal; a persistently high value points at a client flow problem |
| `project_task_upload_rejected_category` | A dry-run or import refused on category | `project_id`, `category` (verbatim, may be null) | PRD Risks row 1 — tracks how many users are blocked by an empty category |
| `project_task_upload_succeeded` | An import succeeded | `project_id`, `category`, `total_success` | G1 — the denominator for the milestone completeness audit |

**G1 audit:** a monthly query over Fasprod/NWD projects that have tasks but whose task names do not cover every required milestone; the target is zero for projects uploaded after the release date.

## 10. Traceability Matrix

| PRD Goal/Story | FRs | NFRs |
|---|---|---|
| G1 — no import without required milestones | FR-002, FR-003, FR-004, FR-005, FR-006, FR-008, FR-009 | NFR-003 |
| G2 — users learn before anything is stored | FR-001, FR-005, FR-007, FR-010, FR-012 | NFR-004, NFR-005, NFR-006 |
| G3 — the rule cannot be bypassed | FR-006, FR-008 | NFR-002, NFR-003, NFR-006, NFR-008 |
| G4 — validation is responsive | FR-001, FR-011 | NFR-001 |
| US-01 — download template | FR-001 (context); §6.3 unchanged | — |
| US-02 — validate before storing | FR-001, FR-007, FR-010 | NFR-001 |
| US-03 — Required/Valid/Not Found summary | FR-002, FR-004, FR-005, FR-012 | — |
| US-04 — missing names are visible | FR-012 | NFR-004 |
| US-05 — Need Revision blocks import | FR-008, FR-009 | NFR-003 |
| US-06 — server-side enforcement | FR-008 | NFR-002, NFR-003 |
| US-07 — message for an empty category | FR-006 | NFR-004 |
| US-08 — tolerance for whitespace and casing | FR-003 | — |

Every FR links to at least one goal, and every goal and user story links to at least one FR.

## 11. Open Questions

| # | Question | Owner | Affected FRs |
|---|---|---|---|
| Q1 | Should `project-task-template.mpp` be updated to contain sample milestone rows? | Product / mnhafid | No FR becomes provisional; §6.3 assumes the template is unchanged. |
| Q2 | How many draft projects currently have an empty `Category`? | Project Control | Does not change FR-006, but sizes the release impact. Check before deploying. |
| Q3 | Is `wbs` always present in the parse result for every task? | Engineering (at implementation time) | FR-012 already allows `wbs` to be `null`, so no FR is provisional. |
