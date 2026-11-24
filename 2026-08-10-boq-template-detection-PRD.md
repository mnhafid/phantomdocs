# PRD: BOQ Template Detection

| | |
|---|---|
| **Status** | Draft |
| **Author** | Claude (grilled with mnhafid) |
| **Date** | 2026-08-10 |
| **Version** | 0.1 |
| **Related docs** | [2026-08-10-boq-template-detection-FSD.md](2026-08-10-boq-template-detection-FSD.md) |

## 1. Overview

Contract BOQs are uploaded as Excel files in one of four fixed layouts ("Template 1".."Template 4"), each of which breaks a row's cost into a different set of categories. The uploader picks which template they are using; the backend then parses the file accordingly. In phiDev that pick is currently ignored — the parser is inferred from the file's header width — so a file can be parsed as a template its BOQ category does not permit, and cost can be booked against the wrong discipline without anything noticing. This work makes the declared template authoritative, validates the uploaded file's header against that template's known column labels, and records which template each BOQ was parsed with so the decision is auditable after the fact. It serves cost engineers uploading BOQs and the project-control staff who read the resulting cost breakdown. It is needed now because phiDev is about to take over BOQ writes from the Go backend, which does not have this defect.

## 2. Problem Statement

phiDev's `POST /api/v1/contracts/boqs/upload` accepts `boq_file_template_id`, verifies only that the template is linked to the chosen BOQ category, then discards it and infers the parser from the header row's column count. Three concrete consequences, all verified against the dev database and the shipped template files:

1. **A file can be parsed as a template its category forbids.** BOQ `1269865e-5748-4557-885c-f56561b7ca0a` sits in category *Quality Control / Quality Assurance*, which has been linked to Template 4 and only Template 4 since 2023-08-28. Its details are all `Default` kind, meaning it was parsed as Template 1. It was uploaded 2026-08-05 by `R3TEST.AGIL` from a file named `boqtype1 1M.xlsx`, via phiDev. The Go backend rejects this on two independent gates and has produced no such row in 108 BOQs.
2. **A reordered column is undetectable.** Template 3 orders its columns `PM | PC | DC`; Template 4 orders them `PM | DC | PC`. Swapping two money columns keeps the header width valid, keeps every row valid, and keeps the contract-value tolerance check passing, because that check sums all item totals regardless of category. The cost silently lands under the wrong discipline. Neither backend detects this today.
3. **The parse decision is unrecoverable.** The `boqs` table has no `boq_file_template_id` column. Templates 3 and 4 both emit `PM`/`PC`/`DC` kinds, so the source template cannot be reliably inferred from the stored details either. Problem 1 stayed invisible until it was searched for deliberately.

Two structural weaknesses feed this. The parser is selected by matching `boq_file_templates.name` against hard-coded strings, but that column is `nvarchar(20)`, nullable, has no unique index, and is writable to any value by the existing create and update endpoints — so an admin rename breaks parsing silently. And the downloadable `.xlsx` templates are mutable objects in cloud storage with no link to the parsers that must read them, so the file users are handed can drift from the code that consumes it.

## 3. Goals & Success Metrics

| ID | Goal | Metric | Target |
|---|---|---|---|
| G1 | No BOQ is parsed as a template its category forbids | Mismatch audit query result per environment, run at rollout and monthly | 0 rows |
| G2 | Malformed headers are caught, not silently mis-parsed | Share of uploads whose header deviates from the declared template's canonical labels that are rejected with a column-level message | 100% |
| G3 | The parse decision is auditable | Share of BOQs created after rollout with non-null `boq_file_template_id` | 100% |
| G4 | The handed-out template and the parser cannot drift | Count of template artifacts served from mutable storage | 0 of 4 |
| G5 | A freshly migrated database is usable | `boq_file_templates` row count after running migrations on an empty database | 4 |
| G6 | An admin action cannot break parsing | Template names outside the approved set accepted by create or update | 0 |

## 4. Non-Goals

| Not doing | Why cut |
|---|---|
| Any change to `pms-backend` (Go) | Go is the reference implementation and does not have this defect; it stays as-is during the transition. |
| Backfilling `boq_file_template_id` for the 108 historical BOQs | The source template is provably ambiguous for T3/T4 rows; a backfill would write guesses into the record. |
| Changing parser column mappings, kind names, the header/item rule, the money-column fan-out, or the tolerance calculation | All four parsers were verified correct against Go and against the shipped template files. Changing them here would mix a correctness fix with a behavior change. |
| Fixing the culture-dependent `ParseDouble` defect | Real and separately confirmed, but it is a numeric-parsing bug, not a template-detection one. Tracked separately. |
| Adding the missing permission gate on the upload endpoint | phiDev has no equivalent of Go's `RBACMiddleware("5","31")`. Separate security work item. |
| Fixing the `SaveUploadedFileAsync` path traversal and the absent request size limit | Same: separate security work items, unrelated to which parser runs. |
| Aligning phiDev's Type-4 fan-out order with Go's | Ordering-only divergence; no value or kind is mis-assigned. |
| Seeding BOQ categories and category↔template links | Environment-specific business configuration, not reference data tied to code. |
| Deleting or repairing the one known dev mismatch | It is phiDev test data and is more useful kept as a regression fixture. |

## 5. Users & Personas

| Persona | Description | Key need |
|---|---|---|
| Cost Engineer | Uploads the contract BOQ workbook against a contract and BOQ category. Works in Excel, not in the API. | To be told immediately and specifically when the file does not match the template they selected, instead of having it accepted wrongly. |
| Project Control / Finance | Reads the resulting cost breakdown by kind (Upah, Material, PM, Discipline Eng, …). Never touches the upload. | Confidence that a cost booked to a discipline actually came from that column. |
| BOQ Administrator | Manages BOQ categories, file templates, and which templates each category permits. | To rename or re-issue a template without silently breaking uploads. |
| Backend Engineer / QA | Operates the rollout and investigates BOQ data questions. | To determine, for any BOQ, which template parsed it — and to prove an environment is clean. |

## 6. User Stories

| ID | Story | Priority |
|---|---|---|
| US-01 | As a Cost Engineer, I want an upload rejected when the file does not match the template I selected, so that my cost data is never parsed under the wrong layout. | Must |
| US-02 | As a Cost Engineer, I want the rejection message to name the specific column that is wrong, so that I can fix the file without guessing. | Must |
| US-03 | As Project Control, I want a reordered or renamed column to be rejected, so that cost cannot be booked to the wrong discipline. | Must |
| US-04 | As a Backend Engineer, I want each BOQ to record the template it was parsed with, so that I can audit or re-verify a past upload. | Must |
| US-05 | As a Backend Engineer, I want a single query that proves an environment has no mismatched BOQs, so that I can measure rather than assume. | Must |
| US-06 | As a Cost Engineer, I want to download the blank template for any of the four types, so that I always start from a file the system will accept. | Should |
| US-07 | As a BOQ Administrator, I want the system to refuse a template name it cannot parse, so that I cannot break uploads by renaming. | Should |
| US-08 | As a Backend Engineer, I want the four templates present after migrating an empty database, so that a new environment works without manual setup. | Should |

## 7. Requirements (high level)

Detail and acceptance criteria live in the [FSD](2026-08-10-boq-template-detection-FSD.md).

1. **The declared template selects the parser.** `boq_file_template_id` determines which of the four parsers runs. Header width is no longer used to choose. — US-01
2. **The header row is validated against the declared template's canonical labels**, compared trimmed and case-insensitively. This subsumes the column-count check and additionally catches reordered and renamed columns. — US-01, US-02, US-03
3. **A mismatch is rejected with a column-level message** identifying the position, the expected label, and the label found; or, when the width is wrong, stating the expected and actual widths and which template the file resembles. — US-02
4. **The canonical header labels are defined once in code**, per template type, and are the single source for header validation, the invalid-row report columns, and the generated blank templates. — US-02, US-06
5. **The four blank templates are generated in code** rather than served from mutable cloud storage, so the file a user downloads and the parser that reads it cannot diverge. — US-06
6. **Template names are constrained to the four approved values** on create and update, and made unique. — US-07
7. **Each BOQ records the template it was parsed with**, populated on every new upload. Historical rows stay unset. — US-04
8. **The four template rows are seeded by migration**, idempotently and reusing the existing identifiers. — US-08
9. **A mismatch audit query ships as a rollout artifact** and is run per environment. — US-05

## 8. Constraints & Dependencies

- **Parser binding stays name-based.** Decided during grilling: dispatch continues to match `boq_file_templates.name`, guarded by a whitelist and a unique index, rather than introducing a discriminator column. This caps template names at the four approved strings and at `nvarchar(20)`.
- **Go remains in production** and continues to write BOQs until phiDev takes over. Nothing in this work may make data written by Go unreadable, and the `boqs` schema change must therefore be additive and nullable.
- **The four category↔template links and 9 categories are live data** in each environment; this work does not create or alter them.
- **Existing identifiers must be preserved.** The dev database already holds the four template rows; the seed must reuse those GUIDs so it is a no-op there.
- **Audit query portability.** The team's SQL client splits scripts on `;` and does not support `GO` or `DECLARE`-based scripts reliably, so the audit artifact must be a single self-contained statement.
- **Depends on** `SimpleXlsxWriter`, already used to generate the Type-1 blank template.

## 9. Assumptions

- **A1: The four template rows stay in `boq_file_templates` even though the files are generated in code** — the category↔template link table and the upload request both reference them by identifier. *Impact if wrong:* the seed and the FK on `boqs` would need rethinking, and the upload contract would change shape.
- **A2: `file_url` stops being the source for template downloads** but the column is left in place and unused rather than dropped. *Impact if wrong:* an unused column persists; no functional effect.
- **A3: Production, still served by Go, contains no mismatched BOQs.** Based on reading Go's two rejection gates and on 107 of 108 dev rows being clean. *Impact if wrong:* the audit query returns non-zero and a remediation decision is needed before phiDev takes over writes — which is exactly why the query ships.
- **A4: The canonical labels are those in the four `.xlsx` files currently in storage**, extracted and verified 2026-08-10. *Impact if wrong:* files users already hold would be rejected, requiring the constants to be corrected.
- **A5: No environment has a fifth BOQ file template.** Dev has exactly four. *Impact if wrong:* the whitelist would reject an in-use template and block uploads for its categories.
- **A6: Adopting the shipped files' labels verbatim changes the casing of four columns in the emailed invalid-row report** (`Upah`→`UPAH`, `Material`→`MATERIAL`, `Sewa Alat`→`SEWA ALAT`, `Transport`→`TRANSPORT`). Accepted as a cosmetic consequence of having one source of truth. *Impact if wrong:* a downstream consumer parsing that report by header text would break.

## 10. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Users hold locally-edited workbooks whose headers were retyped or reformatted, and the stricter check rejects them | Medium | Medium | Compare trimmed and case-insensitively; make the error name the exact column and expected label; ship the generated blank templates alongside so a correct file is one click away. |
| An environment has a template row whose name is outside the whitelist, and the migration's unique index or the whitelist blocks it | Low | High | Audit template names per environment before rollout, as part of the same pre-rollout step as the mismatch query. |
| Production contains mismatched BOQs after all | Low | High | The audit query runs before phiDev takes over writes; a non-zero result blocks cutover pending a remediation decision. |
| Header validation is added but the four constant arrays are transcribed with an error | Low | High | Constants are also used to generate the blank templates, so a transcription error is visible in the downloaded file and caught by a round-trip test. |
| Making `name` unique fails on an environment with duplicate names | Low | Medium | Include a duplicate-name check in the pre-rollout audit. |

## 11. Release & Rollout

Single release, no feature flag — the change makes previously-accepted invalid uploads fail, which is the intent, and a flag would leave the defect reachable.

1. **Pre-rollout, per environment:** run the mismatch audit query, the template-name check, and the duplicate-name check. Record results. A non-zero mismatch count in production blocks cutover of BOQ writes to phiDev.
2. **Deploy:** migration adds the nullable `boq_file_template_id` column on `boqs`, the unique index on `boq_file_templates.name`, and the idempotent seed of the four template rows. Application deploy follows.
3. **Post-rollout:** re-run the audit query and confirm 0. Confirm the four generated blank templates download and that a file produced from each is accepted end to end.
4. **Ongoing:** the audit query becomes a monthly check while both backends can write.

Communication: cost engineers should be told that uploads now verify the file against the selected template, and pointed at the blank-template download.

## 12. Open Questions

None blocking. One item deferred by decision: whether the `file_url` column and the storage-hosted template objects are eventually removed once code-generated templates are proven — revisit after one release. Owner: mnhafid.
