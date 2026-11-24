# FSD: BOQ Template Detection

| | |
|---|---|
| **Status** | Draft |
| **Related PRD** | [2026-08-10-boq-template-detection-PRD.md](2026-08-10-boq-template-detection-PRD.md) |
| **Date** | 2026-08-10 |
| **Version** | 0.1 |

## 1. System Overview

BOQ upload takes a multipart request naming a contract, a BOQ category, a file template, and an `.xlsx` workbook. Today the declared template is checked only for category membership and then discarded; the parser is chosen by measuring the header row's width. This document specifies the inverse: the declared template chooses the parser, and the header row is validated against that template's known column labels.

```
POST /boqs/upload (contract_id, boq_category_id, boq_file_template_id, file)
   │
   ├─ 1. Load contract, category; assert template is linked to category      (unchanged)
   ├─ 2. Resolve declared template name ──▶ parser + canonical header array   ◀── FR-001, FR-002
   ├─ 3. Read sheet; validate header width, then labels, against that array   ◀── FR-003, FR-004
   ├─ 4. Parse rows with the chosen parser                                    (unchanged)
   ├─ 5. Row validation; on failure email invalid-row report                  ◀── FR-005
   ├─ 6. Contract-value tolerance check                                       (unchanged)
   ├─ 7. Upload file to storage                                               (unchanged)
   └─ 8. Persist boq + details, recording boq_file_template_id                ◀── FR-010

CANONICAL_HEADERS[Type1..Type4]  (code constants)  ◀── FR-002
   ├──▶ header validation            (step 3)
   ├──▶ invalid-row report columns   (step 5)
   └──▶ generated blank templates    GET /boqs/template?type=…   ◀── FR-006
```

## 2. Scope

**In scope:** parser selection, header validation and its error contract, the canonical header definition and its three consumers, generated blank templates, template-name constraints, recording the parsed template on `boqs`, seeding the four template rows, and the pre/post-rollout audit queries.

**Out of scope**, mirrored from the PRD's non-goals: any change to `pms-backend`; backfilling historical `boq_file_template_id`; the parsers' column mappings, kind names, header/item rule, money-column fan-out and tolerance calculation; the `ParseDouble` culture defect; the missing permission gate; the `SaveUploadedFileAsync` path traversal; the absent request size limit; Type-4 fan-out ordering; seeding categories and category↔template links; repairing the known dev mismatch.

## 3. User Flows

### 3.1 Successful upload (US-01, US-06)

1. Cost Engineer downloads the blank workbook for the template their category uses (`GET /boqs/template?type=Type2`).
2. They fill in rows and upload it, selecting the same template in the form.
3. The system resolves `boq_file_template_id` to the name `Template 2` and its parser.
4. The header row is compared to the canonical Template 2 labels: 12 columns, matching after trim and case-fold.
5. Rows parse, validate, pass the tolerance check; the file is stored.
6. The BOQ is persisted with `boq_file_template_id` recorded. Response `201`.

### 3.2 Wrong template selected (US-01, US-02)

1. Cost Engineer selects Template 4 but uploads an 8-column Template 1 workbook.
2. Header width is 8, Template 4 expects 13.
3. Upload is rejected `400` before any row is parsed, before any email, and before anything is written to storage or the database. The message states both widths and names the template the file resembles.

### 3.3 Reordered column (US-03)

1. Cost Engineer uploads a 13-column Template 4 workbook in which `DC` and `PC` were swapped.
2. Width passes. Label comparison finds position 8 is `PC` where `DC` is expected, and position 9 is `DC` where `PC` is expected.
3. Upload is rejected `400` naming both positions.

### 3.4 Administrator renames a template (US-07)

1. BOQ Administrator calls the template update endpoint with `name = "Template 3 (Engineering)"`.
2. The name is not in the approved set; the request is rejected `400`. The template's parser binding is unaffected.

### 3.5 Auditing an environment (US-05)

1. Engineer runs the mismatch audit query (§6.5) against the target database.
2. Zero rows confirms no BOQ was parsed under a template its category forbids.

## 4. Functional Requirements

### FR-001: Declared template selects the parser

- **Traces to:** G1 / US-01
- **Priority:** Must
- **Description:** The system shall choose the BOQ row parser from the template named by `boq_file_template_id`, and shall not infer it from the uploaded file.
- **Trigger / Input:** `boq_file_template_id` (GUID, required) on `POST /boqs/upload`.
- **Behavior:** After the existing category-membership check, the system resolves the template row and dispatches on its `name`:

  | `boq_file_templates.name` | Parser | Canonical columns |
  |---|---|---|
  | `Template 1` | Type 1 | 8 |
  | `Template 2` | Type 2 | 12 |
  | `Template 3` | Type 3 | 25 |
  | `Template 4` | Type 4 | 13 |

  Comparison is exact against the approved set. The existing width-based detection is removed as a selection mechanism; width survives only as a validation step (FR-003) and as an advisory hint in the error message (FR-004).
- **Validation & Errors:** A template whose `name` is not one of the four → `400`, `Invalid BOQ file type`. This is unreachable once FR-007 and FR-008 are in place, and exists as a defence for rows predating them.
- **Edge cases:** `name` is NULL → same `400`. The template exists but is soft-deleted → existing `404`, `BOQ category not found` path is unchanged because the membership check already filters `deleted_at IS NULL`. Sheet selection remains the workbook's first worksheet.
- **Acceptance criteria:**
  - Given a category linked to Template 2, When a Template 2 workbook is uploaded declaring Template 2, Then it parses with the Type 2 parser.
  - Given a category linked to both Template 1 and Template 2, When a 12-column workbook is uploaded declaring Template 1, Then the upload is rejected and no Type 2 parse occurs.
  - Given a template row whose name is `Custom`, When an upload declares it, Then the response is `400` with `Invalid BOQ file type`.

### FR-002: Canonical header labels defined once in code

- **Traces to:** G4 / US-02, US-06
- **Priority:** Must
- **Description:** The system shall define one canonical header array per template type in code, and shall use it as the sole source for header validation, invalid-row report columns, and generated blank templates.
- **Behavior:** Four arrays, transcribed from the workbooks currently in storage and verified 2026-08-10:

  | Type | Canonical header labels, in order |
  |---|---|
  | Type 1 | `BOQ LIBRARY ID`, `ORIGIN`, `BREAKDOWN`, `DESCRIPTION`, `QUANTITY`, `UNIT`, `TOTAL`, `REMARKS` |
  | Type 2 | …first six as Type 1…, `UPAH`, `MATERIAL`, `SEWA ALAT`, `TRANSPORT`, `TOTAL`, `REMARKS` |
  | Type 3 | …first six…, `PM`, `PC`, `DC`, `Sr. Engr 2`, `Sr. Engr 1`, `Engr-3`, `Engr-2`, `Engr-1`, `Sr. Dsgn 2`, `Sr. Dsgn 1`, `Dsgn-3`, `Dsgn-2`, `Dsgn-1`, `Sr. Drftr`, `Drftr-3`, `Drftr-2`, `Drftr-1`, `TOTAL`, `REMARKS` |
  | Type 4 | …first six…, `PM`, `DC`, `PC`, `Discipline Eng`, `Designer Eng`, `TOTAL`, `REMARKS` |

  The `PM/PC/DC` order in Type 3 and `PM/DC/PC` in Type 4 is correct and intentional; it matches both the shipped workbooks and the existing parsers.
  The existing per-type column counts (8/12/25/13) shall be derived from these arrays rather than declared separately, so the two cannot disagree.
- **Validation & Errors:** None directly; this requirement is a definition consumed by FR-003, FR-005 and FR-006.
- **Edge cases:** Adding a fifth type requires adding an array plus a parser plus a whitelist entry — all three, by construction.
- **Acceptance criteria:**
  - Given the four arrays, When their lengths are read, Then they are 8, 12, 25 and 13 respectively.
  - Given a generated blank template for a type, When its header row is validated against the same type, Then it passes.

### FR-003: Header row validated against the declared template

- **Traces to:** G2 / US-01, US-03
- **Priority:** Must
- **Description:** The system shall reject an upload whose header row does not match the declared template's canonical labels.
- **Trigger / Input:** Row 1 of the workbook's first worksheet, cells 1..*n* where *n* is the greater of the header's last used column and the canonical length.
- **Behavior:** Two checks, in order, both before any data row is parsed:

  | # | Check | Comparison |
  |---|---|---|
  | 1 | Width: the header's last used column equals the canonical length | Integer equality |
  | 2 | Labels: each header cell equals the canonical label at that position | Trim, then `OrdinalIgnoreCase` |

  Check 2 runs only if check 1 passes. Both run before the existing "file is empty" data-row check, so a structurally wrong file gets a structural error rather than an emptiness error.
- **Validation & Errors:** See FR-004 for message shapes. Both failures are `400`. Neither writes to storage, the database, nor sends email.
- **Edge cases:**
  - Workbook with no used rows at all → existing `400` `Validation failed, file is empty`, checked first since there is no header to compare.
  - Header valid but no data rows → existing `400` `Validation failed, file is empty`, checked after the header checks.
  - Trailing blank header cell reduces the last-used column and therefore fails check 1 with a width error — intended, since the parser would read a column the file does not label.
  - Data rows wider than the header are ignored, as today; only the canonical column count is read per row.
  - Leading/trailing whitespace and differing case in a label are accepted.
- **Acceptance criteria:**
  - Given a Template 4 declaration, When a workbook with 8 header columns is uploaded, Then the response is `400` and no `boqs` row is created.
  - Given a Template 4 declaration, When a 13-column workbook has `DC` and `PC` swapped, Then the response is `400` and no `boqs` row is created.
  - Given a Template 2 declaration, When the header reads `  upah ` instead of `UPAH`, Then the upload is accepted.
  - Given a Template 1 declaration, When the header is correct but there are no data rows, Then the response is `400` with `Validation failed, file is empty`.

### FR-004: Mismatch error contract

- **Traces to:** G2 / US-02
- **Priority:** Must
- **Description:** The system shall reject a header mismatch with a message that identifies what is wrong and what was expected.
- **Behavior:**

  | Case | Message |
  |---|---|
  | Width wrong, file's width matches another template | `Invalid Format: "Template 4" expects 13 columns, the file has 8. The file matches "Template 1" — select that template, or upload a Template 4 workbook.` |
  | Width wrong, matches no template | `Invalid Format: "Template 4" expects 13 columns, the file has 9. The file does not match any known template.` |
  | Labels wrong | `Invalid Format: the file does not match "Template 4". Column 8 must be "DC" but found "PC"; column 9 must be "PC" but found "DC".` |

  Label mismatches are reported for every offending position, ordered by column, capped at the first 5 with `; and N more column(s)` appended when exceeded.
- **Validation & Errors:** HTTP `400`, standard `ApiResponse` envelope, `data: null`. Logged at Warning with the declared template, the file's width, and the mismatched positions.
- **Edge cases:** A blank header cell renders as `(empty)` in the message. Messages are English, matching the rest of this endpoint.
- **Acceptance criteria:**
  - Given a Template 4 declaration and an 8-column file, When it is uploaded, Then the message names both widths and identifies Template 1 as the match.
  - Given a 13-column file with two swapped labels, When it is uploaded, Then the message names both column positions with expected and found labels.
  - Given a file with 7 mismatched labels, When it is uploaded, Then the message lists 5 and states that 2 more exist.

### FR-005: Invalid-row report reuses the canonical headers

- **Traces to:** G4 / US-02
- **Priority:** Should
- **Description:** The system shall build the emailed invalid-row report's column headers from the canonical array for the parsed type, plus a trailing `ERROR DESCRIPTION` column.
- **Behavior:** Replaces the four separately-maintained header arrays currently inlined in the builders. Report content, recipient, attachment name and the surrounding failure behavior are unchanged.
- **Validation & Errors:** Unchanged — a build or send failure still surfaces the existing errors.
- **Edge cases:** Per PRD assumption A6, four Type 2 columns change case in the report (`Upah`→`UPAH`, `Material`→`MATERIAL`, `Sewa Alat`→`SEWA ALAT`, `Transport`→`TRANSPORT`). Accepted.
- **Acceptance criteria:**
  - Given a Type 3 upload with an invalid row, When the report is generated, Then its first 25 columns equal the canonical Type 3 labels and its 26th is `ERROR DESCRIPTION`.

### FR-006: Blank templates generated in code for all four types

- **Traces to:** G4 / US-06
- **Priority:** Should
- **Description:** The system shall generate a downloadable blank workbook for each of the four template types from the canonical header arrays.
- **Trigger / Input:** `GET /api/v1/contracts/boqs/template?type={Type1|Type2|Type3|Type4}`. `type` is optional and defaults to `Type1`, preserving the current no-argument behavior.
- **Behavior:** Generates via `SimpleXlsxWriter` with sheet name `BOQ <Type N>`, the canonical header row, and 2–3 illustrative sample rows appropriate to the type. Filename `boq_template_type{n}.xlsx`. The stored `file_url` is no longer used to serve downloads.
- **Validation & Errors:** Unrecognised `type` → `400`, `Unknown template type. Valid values: Type1, Type2, Type3, Type4.`
- **Edge cases:** Sample rows must themselves pass row validation for their type, so a user can upload the blank template's examples unchanged and see them accepted.
- **Acceptance criteria:**
  - Given `?type=Type3`, When the file is downloaded, Then its header row equals the canonical Type 3 labels.
  - Given no `type` parameter, When the file is downloaded, Then a Type 1 workbook is returned.
  - Given `?type=Type9`, When requested, Then the response is `400`.

### FR-007: Template name whitelist on create

- **Traces to:** G6 / US-07
- **Priority:** Should
- **Description:** The system shall reject creation of a BOQ file template whose name is not one of the four approved values.
- **Trigger / Input:** `POST /boqs/file-templates`, multipart `name`, `file`.
- **Behavior:** After the existing empty-name and `.xlsx` checks, `name` must equal one of `Template 1`..`Template 4` exactly. A non-deleted template with the same name must not already exist.
- **Validation & Errors:** Name outside the set → `400`, `Template name must be one of: Template 1, Template 2, Template 3, Template 4.` Name already in use → `400`, `A BOQ file template named "{name}" already exists.`
- **Edge cases:** Because FR-011 seeds all four, this endpoint is in practice reachable only to restore a deleted row. A soft-deleted row with the same name does not block creation.
- **Acceptance criteria:**
  - Given a request with `name = "Custom"`, When submitted, Then the response is `400` and no row is created.
  - Given all four templates exist, When a request with `name = "Template 2"` is submitted, Then the response is `400`.

### FR-008: Template name whitelist on update

- **Traces to:** G6 / US-07
- **Priority:** Should
- **Description:** The system shall reject an update that would set a BOQ file template's name to a value outside the approved set or to a name already in use.
- **Trigger / Input:** `POST /boqs/file-templates/{templateId}/update`, multipart `name` required, `file` optional.
- **Behavior:** Same whitelist and uniqueness rules as FR-007, excluding the row being updated from the uniqueness check. Replacing the attached file remains permitted.
- **Validation & Errors:** As FR-007.
- **Edge cases:** Setting a template's name to its current value is a no-op and succeeds.
- **Acceptance criteria:**
  - Given Template 3, When renamed to `Template 3 (Engineering)`, Then the response is `400` and the stored name is unchanged.
  - Given Template 3, When renamed to `Template 4`, Then the response is `400`.
  - Given Template 3, When only its file is replaced with `name = "Template 3"`, Then the update succeeds.

### FR-009: Template names are unique in the database

- **Traces to:** G6
- **Priority:** Should
- **Description:** The system shall enforce uniqueness of `boq_file_templates.name` among non-deleted rows at the database level.
- **Behavior:** A filtered unique index on `name` where `deleted_at IS NULL`, so soft-deleted rows do not block reuse.
- **Validation & Errors:** A violation surfaces as the existing `500` path; FR-007 and FR-008 are the user-facing guard. This requirement is defence in depth against writes that bypass the service.
- **Edge cases:** The migration fails if an environment already holds duplicate active names — surfaced by the pre-rollout check in §6.6.
- **Acceptance criteria:**
  - Given two active rows named `Template 1`, When the migration runs, Then it fails with a clear index-violation error.
  - Given a soft-deleted `Template 1` and an active `Template 1`, When the migration runs, Then it succeeds.

### FR-010: Record the parsed template on each BOQ

- **Traces to:** G3 / US-04
- **Priority:** Must
- **Description:** The system shall store the identifier of the template used to parse each BOQ on the `boqs` row.
- **Behavior:** `boqs.boq_file_template_id` is set from the request's `boq_file_template_id` inside the existing persistence transaction. The value is included in `BoqDto` responses.
- **Validation & Errors:** None additional; the identifier was already validated by the category-membership check.
- **Edge cases:** Historical rows remain NULL and are serialized as `null`. Deleting a template must not delete or orphan BOQs — the FK is `ON DELETE NO ACTION`, and template deletion is a soft delete regardless.
- **Acceptance criteria:**
  - Given a successful upload declaring Template 2, When the BOQ is read back, Then `boq_file_template_id` equals the Template 2 identifier.
  - Given a BOQ created before this change, When it is read back, Then `boq_file_template_id` is `null` and no error occurs.

### FR-011: Seed the four template rows

- **Traces to:** G5 / US-08
- **Priority:** Should
- **Description:** The system shall ensure the four approved BOQ file templates exist after migrations run.
- **Behavior:** An idempotent migration inserts any of the four rows that are absent, keyed on the existing identifiers so environments that already hold them are unaffected:

  | Name | Id |
  |---|---|
  | Template 1 | `84c490ee-b814-4fb8-b644-71bf142cb7b2` |
  | Template 2 | `8c1eb61b-13a6-4019-9404-367a71817fad` |
  | Template 3 | `8e0b2b94-5cda-4350-8c90-016d1b6da9a3` |
  | Template 4 | `38469f0e-0be3-407b-8d41-516b2d1562d8` |

  `file_url` is left NULL for newly seeded rows; downloads are generated (FR-006). Existing `file_url` values are not modified.
- **Validation & Errors:** The migration must not fail on a database that already contains all four.
- **Edge cases:** A row present with the same identifier but a different name is left untouched and reported by the §6.6 pre-rollout check. BOQ categories and category↔template links are not seeded, so a fresh database still needs those configured before an upload can succeed.
- **Acceptance criteria:**
  - Given an empty database, When migrations run, Then `boq_file_templates` contains exactly the four rows above.
  - Given the dev database, When migrations run, Then no template row is inserted or modified.

### FR-012: Mismatch audit query artifact

- **Traces to:** G1 / US-05
- **Priority:** Must
- **Description:** The system shall ship a single-statement SQL query that lists BOQs whose inferred template is not permitted by their category.
- **Behavior:** The query in §6.5, checked into the repository alongside the migration. It infers a BOQ's template from its detail kinds, treats a BOQ whose only kinds are `PM`/`PC`/`DC` as ambiguous and excludes it, and reports rows whose inferred template has no active link to their category.
- **Validation & Errors:** Read-only; mutates nothing.
- **Edge cases:** Ambiguous rows are excluded rather than reported, so the result is a floor, not a ceiling — noted in the artifact's header comment. Must run as one statement, without `GO` or `DECLARE`, for the team's SQL client.
- **Acceptance criteria:**
  - Given the dev database as of 2026-08-10, When the query runs, Then it returns exactly one row, BOQ `1269865e-5748-4557-885c-f56561b7ca0a`.
  - Given a database with no mismatches, When the query runs, Then it returns zero rows.

## 5. Data Model

**Modified — `boqs`**

| Field | Type | Null | Notes |
|---|---|---|---|
| `boq_file_template_id` | `uniqueidentifier` | Yes | **New.** FK → `boq_file_templates(id)`, `ON DELETE NO ACTION`. NULL for the 108 pre-existing rows; required in practice for all new writes. Nullable so rows written by the Go backend remain valid. |

**Modified — `boq_file_templates`**

| Change | Notes |
|---|---|
| Filtered unique index on `name` where `deleted_at IS NULL` | **New.** FR-009. |
| `name` | Unchanged `nvarchar(20)`, nullable. Constrained to the four approved values at the service layer (FR-007, FR-008). Not made non-nullable to avoid failing on any legacy row. |
| `file_url` | Unchanged and retained, but no longer the source for template downloads (PRD A2). |
| Seed rows | Four rows per FR-011. |

**Unchanged:** `boq_details`, `boq_categories`, `boq_category_template_types`. No retention or PII implications — BOQ data is commercial, not personal.

## 6. Interfaces

Only additions and changes are listed. All endpoints sit behind `R3ComponentFilter` (§8).

### 6.1 `POST /api/v1/contracts/boqs/upload` — changed

Request unchanged: multipart `contract_id`, `boq_category_id`, `boq_file_template_id`, `file`.

| Status | When | Body |
|---|---|---|
| `201` | Success | `ApiResponse<BoqDto>`; `BoqDto` now carries `boq_file_template_id`. |
| `400` | Header width or labels mismatch | FR-004 messages. **New.** |
| `400` | Template name not in the approved set | `Invalid BOQ file type`. |
| `400` | Existing cases: not `.xlsx`, empty file, row validation failed, tolerance exceeded | Unchanged. |
| `404` | Contract or category not found | Unchanged. |

### 6.2 `GET /api/v1/contracts/boqs/template` — changed

| | |
|---|---|
| Query | `type` — optional, one of `Type1`, `Type2`, `Type3`, `Type4`; defaults to `Type1`. |
| `200` | `.xlsx` stream, `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`, filename `boq_template_type{n}.xlsx`. |
| `400` | Unknown `type`. **New.** |

### 6.3 `POST /api/v1/contracts/boqs/file-templates` — changed

Adds `400` for a non-approved name and for a name already in use (FR-007). Success and other errors unchanged.

### 6.4 `POST /api/v1/contracts/boqs/file-templates/{templateId}/update` — changed

Adds the same two `400` cases (FR-008). Success and other errors unchanged.

### 6.5 Audit query — new artifact

Single statement, no `GO`, no `DECLARE`. Ambiguous rows are excluded, so a zero result means "no *provable* mismatch".

```sql
WITH inferred AS (
    SELECT b.id, b.contract_id, b.boq_category_id,
           CASE
             WHEN MAX(CASE WHEN d.kind IN ('Discipline Eng','Designer Eng') THEN 1 ELSE 0 END) = 1 THEN 'Template 4'
             WHEN MAX(CASE WHEN d.kind IN ('Sr. Engr 2','Sr. Engr 1','Engr 3','Engr 2','Engr 1',
                                           'Sr. Dsgn 2','Sr. Dsgn 1','Dsgn 3','Dsgn 2','Dsgn 1',
                                           'Sr. Drftr','Drftr 3','Drftr 2','Drftr 1') THEN 1 ELSE 0 END) = 1 THEN 'Template 3'
             WHEN MAX(CASE WHEN d.kind IN ('Upah','Material','Sewa Alat','Transport') THEN 1 ELSE 0 END) = 1 THEN 'Template 2'
             WHEN MAX(CASE WHEN d.kind = 'Default' THEN 1 ELSE 0 END) = 1 THEN 'Template 1'
             ELSE 'ambiguous'
           END AS inferred_template
    FROM boqs b
    JOIN boq_details d ON d.boq_id = b.id
    WHERE b.deleted_at IS NULL
    GROUP BY b.id, b.contract_id, b.boq_category_id
)
SELECT i.id AS boq_id, i.contract_id, c.name AS category, i.inferred_template
FROM inferred i
LEFT JOIN boq_categories c ON c.id = i.boq_category_id
WHERE i.inferred_template <> 'ambiguous'
  AND NOT EXISTS (
        SELECT 1
        FROM boq_category_template_types ct
        JOIN boq_file_templates f ON f.id = ct.boq_file_template_id
        WHERE ct.boq_category_id = i.boq_category_id
          AND ct.deleted_at IS NULL
          AND f.name = i.inferred_template)
```

### 6.6 Pre-rollout checks — new artifacts

Two further single statements, run before the migration:

```sql
SELECT id, name FROM boq_file_templates WHERE deleted_at IS NULL AND (name IS NULL OR name NOT IN ('Template 1','Template 2','Template 3','Template 4'))
```

```sql
SELECT name, COUNT(*) AS n FROM boq_file_templates WHERE deleted_at IS NULL GROUP BY name HAVING COUNT(*) > 1
```

Both must return zero rows before deploying, or FR-009's index and FR-001's dispatch will fail.

### 6.7 Events and third-party integrations

None added or changed. The invalid-row report continues to be sent through `IMailerService`; storage continues to be MinIO.

## 7. Non-Functional Requirements

### NFR-001: No added latency on the upload path
- **Requirement:** Header validation adds no network or storage I/O. Canonical labels are in-process constants, and the comparison is O(*n*) over at most 25 cells. Upload p95 must not regress measurably.
- **Traces to:** G4

### NFR-002: Backward compatibility with Go-written data
- **Requirement:** The schema change is additive and nullable. All 108 existing BOQs and 20,507 details remain readable and unmodified, and the Go backend continues to write successfully against the same schema throughout the transition.
- **Traces to:** G3

### NFR-003: Observability
- **Requirement:** Every rejected upload logs, at Warning, the declared template name, the file's header width, the width the declared template expects, and the mismatched column positions. Every accepted upload logs the declared template at Information. Enough to reconstruct any rejection from logs alone, without the file.
- **Traces to:** G1, G2

### NFR-004: Audit artifact portability
- **Requirement:** Each SQL artifact is a single statement containing no `GO` batch separator, no `DECLARE`, and no interior statement terminator, so it runs unmodified in the team's JDBC-based client.
- **Traces to:** G1

### NFR-005: Security posture unchanged
- **Requirement:** This work neither adds nor removes authentication or authorization. The upload endpoint remains authenticated by `R3ComponentFilter` with no per-permission gate, and the known path-traversal and request-size gaps remain open. All three are recorded here so their absence is deliberate and traceable, not overlooked; they are tracked as separate work.
- **Traces to:** —

### NFR-006: Test coverage
- **Requirement:** The four parsers currently have no test coverage. This work must land with tests covering, per type, a valid header, a wrong-width header, and a reordered-label header; plus a round trip asserting that each generated blank template validates against its own type.
- **Traces to:** G2, G4

## 8. Permissions & Roles

| Action | Today | After this work |
|---|---|---|
| Upload a BOQ | Any authenticated user with an active department scope | Unchanged |
| Download a blank template | Any authenticated user with an active department scope | Unchanged |
| Create / update / delete a file template | Any authenticated user with an active department scope | Unchanged, but the name is now constrained (FR-007, FR-008) |
| Run the audit queries | Direct database access | Unchanged |

phiDev has no equivalent of Go's `RBACMiddleware("5","31")` on any of these routes; `R3ComponentFilter` performs authentication and department scoping only. Out of scope here, recorded under NFR-005.

## 9. Analytics & Telemetry

| Event | Properties | When | Measures |
|---|---|---|---|
| `boq_upload_rejected_header` | `declared_template`, `expected_columns`, `actual_columns`, `mismatched_positions`, `reason` ∈ {`width`,`labels`} | Header validation fails | G2 |
| `boq_upload_accepted` | `declared_template`, `contract_id`, `boq_category_id`, `detail_count` | Upload persists | G1, G3 |
| `boq_template_name_rejected` | `attempted_name`, `operation` ∈ {`create`,`update`} | FR-007 / FR-008 rejects | G6 |
| `boq_blank_template_downloaded` | `type` | FR-006 serves a file | G4 |

G1's target is verified by the §6.5 query rather than by telemetry; G5's by the row count after migration.

## 10. Traceability Matrix

| PRD Goal / Story | FRs | NFRs |
|---|---|---|
| G1 — no forbidden-template parses | FR-001, FR-003, FR-012 | NFR-003, NFR-004 |
| G2 — malformed headers caught | FR-003, FR-004 | NFR-003, NFR-006 |
| G3 — parse decision auditable | FR-010 | NFR-002 |
| G4 — no template/parser drift | FR-002, FR-005, FR-006 | NFR-001, NFR-006 |
| G5 — fresh database usable | FR-011 | — |
| G6 — admin cannot break parsing | FR-007, FR-008, FR-009 | — |
| US-01 | FR-001, FR-003 | — |
| US-02 | FR-004, FR-005 | NFR-003 |
| US-03 | FR-003, FR-004 | — |
| US-04 | FR-010 | NFR-002 |
| US-05 | FR-012 | NFR-004 |
| US-06 | FR-002, FR-006 | — |
| US-07 | FR-007, FR-008 | — |
| US-08 | FR-011 | — |

Every FR traces to a goal and a story; every goal and story has at least one FR.

## 11. Open Questions

None blocking. Deferred by decision and revisited after one release: whether `boq_file_templates.file_url` and the storage-hosted template objects are removed once code-generated templates are proven in use. Owner: mnhafid.
