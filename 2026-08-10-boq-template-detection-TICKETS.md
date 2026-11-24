# Tickets: BOQ Template Detection

Source: [FSD-boq-template-detection](2026-08-10-boq-template-detection-FSD.md) (v0.1) · Coverage: 12 FRs / 6 NFRs → 11 tickets, all covered

## Summary

| ID | Title | Epic | Size | Blocked by | Covers |
|---|---|---|---|---|---|
| T-01 | Define canonical header constants and derive column counts | E1 | S | — | FR-002 |
| T-02 | Select the BOQ parser from the declared template | E2 | S | T-01 | FR-001 |
| T-03 | Validate the header row against the declared template | E2 | M | T-02 | FR-003, FR-004, NFR-001 |
| T-04 | Build the invalid-row report from the canonical headers | E1 | S | T-01 | FR-005 |
| T-05 | Generate blank templates for all four types | E1 | M | T-01 | FR-006 |
| T-06 | Constrain BOQ file template names on create and update | E3 | M | — | FR-007, FR-008 |
| T-07 | Add the name unique index and seed the four templates `[infra]` | E3 | S | T-06 | FR-009, FR-011 |
| T-08 | Record the parsed template on each BOQ | E4 | M | — | FR-010, NFR-002 |
| T-09 | Log header rejections and accepted uploads | E2 | S | T-03 | NFR-003 |
| T-10 | Ship the audit and pre-rollout SQL artifacts `[infra]` | E5 | S | — | FR-012, NFR-004 |
| T-11 | Test suite for the parsers, header validation and templates | E5 | M | T-03, T-05, T-06, T-08 | NFR-005, NFR-006 |

**Buildable order:** T-01 → T-02 → T-03 → T-09, with T-04 and T-05 in parallel after T-01. T-06 → T-07 and T-08 and T-10 are independent of that chain and can run alongside. T-11 lands last.

**Deployment order note:** T-10's pre-rollout checks must be *run against each environment* before T-07's migration is applied, or a duplicate or non-approved template name will fail the index. This is a release-sequencing constraint, not a code dependency — T-07 can be built first.

## Epics

- **E1 — Canonical headers:** one definition of each template's column labels, feeding validation, the error report, and the downloadable blank workbooks.
- **E2 — Upload validation:** make the declared template authoritative and reject files that do not match it.
- **E3 — Template integrity:** stop an admin action from breaking the parser binding, and make a fresh database usable.
- **E4 — Audit trail:** record which template parsed each BOQ.
- **E5 — Verification and rollout:** tests, and the SQL that proves an environment is clean.

---

## T-01: Define canonical header constants and derive column counts

- **Epic:** E1 · **Size:** S · **Priority:** Must · **Blocked by:** —
- **Covers:** FR-002

**Context**

Every downstream ticket needs one authoritative list of column labels per template type. Today the column counts live in `BoqFileType.ColumnCount` and the labels are duplicated inline in each of the four builders' error-report arrays. See [FSD §4 FR-002](2026-08-10-boq-template-detection-FSD.md).

**Scope of work**

- Add four ordered header arrays (Type 1/2/3/4) to `BoqFileType`, transcribed exactly from FSD FR-002.
- Derive `ColumnCount` from the arrays' lengths rather than declaring it separately, so the two cannot disagree.
- Leave the builders, validation and endpoints untouched — later tickets consume this.

**Acceptance criteria**

- Given the four arrays, When their lengths are read, Then they are 8, 12, 25 and 13 respectively.
- Given `BoqFileType.ColumnCount`, When read for each type, Then it equals the corresponding array's length.

**Out of scope**

Consuming the arrays anywhere — T-03 (validation), T-04 (report), T-05 (blank templates) each own their consumer.

**Test notes**

Type 3 orders its money columns `PM | PC | DC` and Type 4 orders them `PM | DC | PC`. This inversion is correct and matches the shipped workbooks; a "tidy-up" that aligns them is a defect.

---

## T-02: Select the BOQ parser from the declared template

- **Epic:** E2 · **Size:** S · **Priority:** Must · **Blocked by:** T-01
- **Covers:** FR-001

**Context**

`UploadBoqAsync` currently ignores `boq_file_template_id` for parsing and infers the parser from the uploaded file's header width, which is how a Type 1 file was accepted into a Template-4-only category. The declared template must choose the parser. See [FSD §4 FR-001](2026-08-10-boq-template-detection-FSD.md).

**Scope of work**

- Resolve the declared template row's `name` in `LoadUploadContextAsync` (the category-membership check already loads it) and return it alongside the contract and next version.
- Dispatch to the Type 1–4 builders on that name instead of on `ReadExcelRows`'s detected type.
- Strip width-based *selection* from `ReadExcelRows`; it becomes a plain reader for a caller-supplied column count. Width survives only as validation (T-03).
- Keep the `Invalid BOQ file type` `400` for a name outside the four approved values, as a defence for rows predating T-06.

**Acceptance criteria**

- Given a category linked to Template 2, When a Template 2 workbook is uploaded declaring Template 2, Then it parses with the Type 2 parser.
- Given a category linked to Template 1 and Template 2, When a 12-column workbook is uploaded declaring Template 1, Then no Type 2 parse occurs.
- Given a template row named `Custom`, When an upload declares it, Then the response is `400` with `Invalid BOQ file type`.

**Out of scope**

Header validation and its error messages — T-03. Do not add validation here beyond the existing behavior, or the two tickets will conflict.

**Test notes**

The workbook's first worksheet is still the one read; do not introduce a `Sheet1` name requirement. A template row with a NULL name must hit the same `400`, not throw.

---

## T-03: Validate the header row against the declared template

- **Epic:** E2 · **Size:** M · **Priority:** Must · **Blocked by:** T-02
- **Covers:** FR-003, FR-004, NFR-001

**Context**

The core of the feature. Once the declared template selects the parser, the file must be proven to match it — by label, not just by width, because a reordered money column passes every check the system has today, including the tolerance gate, and silently books cost to the wrong discipline. See [FSD §4 FR-003, FR-004](2026-08-10-boq-template-detection-FSD.md).

**Scope of work**

- After resolving the template and reading row 1, run two ordered checks: header width equals the canonical length; then each header cell equals the canonical label at that position, compared trimmed and `OrdinalIgnoreCase`. Label checking runs only if width passes.
- Run both before any data row is parsed, before the storage upload, before any database write, and before the invalid-row email.
- Order relative to the existing empty-file check: a workbook with no used rows still returns `Validation failed, file is empty`; a workbook with a valid header but no data rows returns the same message *after* the header checks pass.
- Emit the three message shapes in FSD FR-004, including the "the file matches Template N" hint derived from the file's width, and the `(empty)` rendering for a blank header cell.
- Cap label mismatches at the first 5, ordered by column, appending `; and N more column(s)`.

**Acceptance criteria**

- Given a Template 4 declaration, When a workbook with 8 header columns is uploaded, Then the response is `400`, the message names both widths and identifies Template 1 as the match, and no `boqs` row is created.
- Given a Template 4 declaration, When a 13-column workbook has `DC` and `PC` swapped, Then the response is `400` naming both column positions with expected and found labels, and no `boqs` row is created.
- Given a Template 2 declaration, When a header cell reads `  upah ` instead of `UPAH`, Then the upload is accepted.
- Given a Template 4 declaration, When a 9-column workbook is uploaded, Then the message states that the file matches no known template.
- Given a Template 1 declaration, When the header is correct but there are no data rows, Then the response is `400` with `Validation failed, file is empty`.
- Given a file with 7 mismatched labels, When it is uploaded, Then the message lists 5 and states that 2 more exist.

**Out of scope**

Logging the rejection — T-09. Changing any parser's column mapping, kind names, header/item rule, fan-out or the tolerance calculation.

**Test notes**

NFR-001: validation must add no storage or network I/O — the labels are in-process constants. A trailing blank header cell legitimately fails the width check; that is intended, since the parser would otherwise read an unlabelled column. Data rows wider than the header are still ignored.

---

## T-04: Build the invalid-row report from the canonical headers

- **Epic:** E1 · **Size:** S · **Priority:** Should · **Blocked by:** T-01
- **Covers:** FR-005

**Context**

Each of the four builders inlines its own copy of the report's column headers. Pointing them at the T-01 arrays removes the duplication and guarantees the emailed report matches the template it describes. See [FSD §4 FR-005](2026-08-10-boq-template-detection-FSD.md).

**Scope of work**

- Replace the four inline header arrays in `BuildBoqType{1..4}DetailsAsync` with the canonical array for the type, plus a trailing `ERROR DESCRIPTION` column.
- Leave report content, row ordering, recipient resolution, attachment name and the surrounding failure behavior unchanged.

**Acceptance criteria**

- Given a Type 3 upload with an invalid row, When the report is generated, Then its first 25 columns equal the canonical Type 3 labels and its 26th is `ERROR DESCRIPTION`.
- Given a Type 1 upload with an invalid row, When the report is generated, Then it has 9 columns.

**Out of scope**

Changing which rows are reported, the `|`-joined error text, or the in-memory report mechanism.

**Test notes**

Four Type 2 columns change case as a result (`Upah`→`UPAH`, `Material`→`MATERIAL`, `Sewa Alat`→`SEWA ALAT`, `Transport`→`TRANSPORT`). This is accepted per PRD assumption A6 — do not "fix" it back.

---

## T-05: Generate blank templates for all four types

- **Epic:** E1 · **Size:** M · **Priority:** Should · **Blocked by:** T-01
- **Covers:** FR-006

**Context**

`GET /boqs/template` generates a Type 1 workbook from a hardcoded header array; the other three types are only available as mutable objects in cloud storage, pointing at a bucket phiDev is not even configured for. Generating all four from the T-01 constants makes drift between the handed-out file and the parser structurally impossible. See [FSD §4 FR-006, §6.2](2026-08-10-boq-template-detection-FSD.md).

**Scope of work**

- Add an optional `type` query parameter accepting `Type1`..`Type4`, defaulting to `Type1` so the current no-argument call is unchanged.
- Generate via `SimpleXlsxWriter` with sheet name `BOQ <Type N>`, the canonical header row, and 2–3 sample rows per type. Filename `boq_template_type{n}.xlsx`.
- Sample rows must themselves pass that type's row validation, so a user can upload the blank template unchanged and see it accepted.
- Return `400` `Unknown template type. Valid values: Type1, Type2, Type3, Type4.` for anything else.

**Acceptance criteria**

- Given `?type=Type3`, When the file is downloaded, Then its header row equals the canonical Type 3 labels.
- Given no `type` parameter, When the file is downloaded, Then a Type 1 workbook is returned.
- Given `?type=Type9`, When requested, Then the response is `400`.
- Given a downloaded blank template for any type, When it is uploaded declaring that same type, Then header validation passes.

**Out of scope**

Removing `boq_file_templates.file_url` or deleting the storage objects — deferred by decision for one release (FSD §11).

**Test notes**

The last criterion is the round trip that catches a transcription error in T-01, so it must be automated, not eyeballed.

---

## T-06: Constrain BOQ file template names on create and update

- **Epic:** E3 · **Size:** M · **Priority:** Should · **Blocked by:** —
- **Covers:** FR-007, FR-008

**Context**

`AddBoqFileTemplateAsync` accepts any name with no validation, and `UpdateBoqFileTemplateAsync` will rename any template to anything. Since the parser is selected by matching that name, renaming *Template 3* silently breaks every Engineering BOQ upload. See [FSD §4 FR-007, FR-008](2026-08-10-boq-template-detection-FSD.md).

**Scope of work**

- On create: after the existing empty-name and `.xlsx` checks, require `name` to equal one of `Template 1`..`Template 4` exactly, and require no non-deleted row to already hold it.
- On update: the same two rules, excluding the row being updated from the uniqueness check. Replacing the attached file stays permitted.
- Error messages per FSD FR-007.

**Acceptance criteria**

- Given a create request with `name = "Custom"`, When submitted, Then the response is `400` and no row is created.
- Given all four templates exist, When a create request with `name = "Template 2"` is submitted, Then the response is `400`.
- Given Template 3, When renamed to `Template 3 (Engineering)`, Then the response is `400` and the stored name is unchanged.
- Given Template 3, When renamed to `Template 4`, Then the response is `400`.
- Given Template 3, When only its file is replaced with `name = "Template 3"`, Then the update succeeds.

**Out of scope**

The database-level unique index — T-07. Removing or deprecating the create endpoint; it stays as the repair path for a deleted row.

**Test notes**

A soft-deleted row holding the same name must not block creation — the uniqueness rule applies to non-deleted rows only.

---

## T-07: Add the name unique index and seed the four templates `[infra]`

- **Epic:** E3 · **Size:** S · **Priority:** Should · **Blocked by:** T-06
- **Covers:** FR-009, FR-011

**Context**

A fresh phiDev database has zero BOQ file templates — there is no seed migration — so every upload fails on "BOQ file template not found in this category". The four rows exist in dev only because someone POSTed them. See [FSD §4 FR-009, FR-011](2026-08-10-boq-template-detection-FSD.md).

**Scope of work**

- Migration: filtered unique index on `boq_file_templates.name` where `deleted_at IS NULL`.
- Migration: idempotent insert of the four rows using the identifiers in FSD FR-011, so the dev database is unaffected. Leave `file_url` NULL for newly seeded rows and do not modify existing values.
- Do not seed BOQ categories or category↔template links.

**Acceptance criteria**

- Given an empty database, When migrations run, Then `boq_file_templates` contains exactly the four rows from FSD FR-011.
- Given the dev database, When migrations run, Then no template row is inserted or modified.
- Given two active rows named `Template 1`, When the migration runs, Then it fails with a clear index-violation error.
- Given a soft-deleted `Template 1` and an active `Template 1`, When the migration runs, Then it succeeds.

**Out of scope**

Making `name` non-nullable — avoided so no legacy row fails.

**Test notes**

Per project convention, every EF migration sweeps in a spurious `permission_groups`/`TempId` diff; strip it before committing. Run T-10's pre-rollout checks against each environment before applying this migration — a duplicate or non-approved name will fail the index.

---

## T-08: Record the parsed template on each BOQ

- **Epic:** E4 · **Size:** M · **Priority:** Must · **Blocked by:** —
- **Covers:** FR-010, NFR-002

**Context**

`boqs` has no column recording which template parsed it, and the source template cannot be reliably inferred from the details either, because Types 3 and 4 both emit `PM`/`PC`/`DC` kinds. That is why the known mismatch stayed invisible until it was searched for. See [FSD §4 FR-010, §5](2026-08-10-boq-template-detection-FSD.md).

**Scope of work**

- Migration: nullable `boq_file_template_id uniqueidentifier` on `boqs`, FK to `boq_file_templates(id)`, `ON DELETE NO ACTION`.
- Set it from the request inside the existing persistence transaction.
- Add it to `BoqDto` so list and detail responses expose it.

**Acceptance criteria**

- Given a successful upload declaring Template 2, When the BOQ is read back, Then `boq_file_template_id` equals the Template 2 identifier.
- Given a BOQ created before this change, When it is read back, Then `boq_file_template_id` is `null` and no error occurs.
- Given a template that is soft-deleted, When BOQs referencing it are read, Then they are returned unchanged.

**Out of scope**

Backfilling the 108 historical rows — explicitly a non-goal, because the T3/T4 inference is ambiguous.

**Test notes**

NFR-002: the column must be nullable and the change additive, because the Go backend keeps writing to this table during the transition. Verify a Go-shaped insert (no `boq_file_template_id`) still succeeds.

---

## T-09: Log header rejections and accepted uploads

- **Epic:** E2 · **Size:** S · **Priority:** Should · **Blocked by:** T-03
- **Covers:** NFR-003

**Context**

A rejected upload must be reconstructable from logs alone, without the file — otherwise diagnosing a user's "it won't accept my file" means asking them to send it. See [FSD §7 NFR-003, §9](2026-08-10-boq-template-detection-FSD.md).

**Scope of work**

- On rejection, log at Warning: declared template name, the file's header width, the width the declared template expects, and the mismatched column positions.
- On acceptance, log at Information: declared template name, contract id, category id, detail count.
- Cover the template-name rejections from T-06 and the blank-template downloads from T-05 with the properties in FSD §9.

**Acceptance criteria**

- Given a width mismatch, When the upload is rejected, Then a Warning entry records both widths and the declared template.
- Given a label mismatch, When the upload is rejected, Then a Warning entry records the mismatched column positions.
- Given a successful upload, When it persists, Then an Information entry records the declared template and detail count.

**Out of scope**

Wiring a metrics backend or dashboards.

**Test notes**

Log the header *labels* found, not row content — the file may contain commercially sensitive pricing.

---

## T-10: Ship the audit and pre-rollout SQL artifacts `[infra]`

- **Epic:** E5 · **Size:** S · **Priority:** Must · **Blocked by:** —
- **Covers:** FR-012, NFR-004

**Context**

Production is served by Go, which cannot produce this defect, but that is an inference from reading code. The audit query measures it instead. It also becomes the standing check while both backends can write. See [FSD §4 FR-012, §6.5, §6.6](2026-08-10-boq-template-detection-FSD.md).

**Scope of work**

- Check the three statements from FSD §6.5 and §6.6 into the repository alongside the migrations: the mismatch audit, the non-approved-name check, and the duplicate-name check.
- Header comment on the audit query stating that rows whose only kinds are `PM`/`PC`/`DC` are ambiguous and excluded, so a zero result means "no *provable* mismatch".
- Record each environment's results as part of the rollout.

**Acceptance criteria**

- Given the dev database as of 2026-08-10, When the audit query runs, Then it returns exactly one row, BOQ `1269865e-5748-4557-885c-f56561b7ca0a`.
- Given a database with no mismatches, When the audit query runs, Then it returns zero rows.
- Given the dev database, When both pre-rollout checks run, Then each returns zero rows.

**Out of scope**

Deleting or repairing the dev mismatch — it is kept deliberately as a regression fixture for T-11.

**Test notes**

NFR-004: each artifact must be a single statement with no `GO`, no `DECLARE`, and no interior `;` — the team's JDBC client splits on semicolons and will otherwise mangle them.

---

## T-11: Test suite for the parsers, header validation and templates

- **Epic:** E5 · **Size:** M · **Priority:** Must · **Blocked by:** T-03, T-05, T-06, T-08
- **Covers:** NFR-005, NFR-006

**Context**

The four parsers have no test coverage at all today — roughly 700 lines handling contract money. The reordered-column case this feature introduces is precisely the one nothing currently catches, so shipping without tests would leave the main new guarantee unverified. See [FSD §7 NFR-005, NFR-006](2026-08-10-boq-template-detection-FSD.md).

**Scope of work**

- Per template type: a valid-header case, a wrong-width case, and a reordered-label case.
- A round trip asserting each generated blank template validates against its own type.
- A case-and-whitespace-insensitivity case.
- Template name create/update rejection cases from T-06.
- A persistence case asserting `boq_file_template_id` is recorded, and one asserting a NULL value on a legacy row reads back cleanly.
- Use the dev mismatch file shape (8-column workbook declared as Template 4) as an explicit regression fixture.

**Acceptance criteria**

- Given the suite, When it runs, Then every template type has valid, wrong-width and reordered-label coverage.
- Given each generated blank template, When validated against its own type, Then it passes.
- Given the regression fixture, When uploaded declaring Template 4, Then it is rejected.

**Out of scope**

Tests for the deferred defects — the `ParseDouble` culture bug, the missing permission gate, the path traversal, the request size limit. They are separately tracked.

**Test notes**

NFR-005: include an explicit review check that this work added and removed no authentication or authorization. The endpoints remain authenticated by `R3ComponentFilter` with no per-permission gate; that gap stays open by decision and must not be silently closed or widened here.

---

## Coverage check

| FR / NFR | Ticket |
|---|---|
| FR-001 | T-02 |
| FR-002 | T-01 |
| FR-003, FR-004 | T-03 |
| FR-005 | T-04 |
| FR-006 | T-05 |
| FR-007, FR-008 | T-06 |
| FR-009, FR-011 | T-07 |
| FR-010 | T-08 |
| FR-012 | T-10 |
| NFR-001 | T-03 |
| NFR-002 | T-08 |
| NFR-003 | T-09 |
| NFR-004 | T-10 |
| NFR-005, NFR-006 | T-11 |

All 12 FRs and all 6 NFRs are covered by at least one ticket.
