# SPK BoQ Shorten Flow

Everything for the shorten-flow wizard — spec, findings, and the SQL that supports it.
Merged 2026-09-05 from `docs/ShortenFlow/` and `docs/SPKBOQShortenflow/`, which had been
two halves of one doc set that already cross-referenced each other.

## Spec

| File | What it is |
|---|---|
| [PRD.md](PRD.md) | As-built product requirements. Start here. |
| [FSD.md](FSD.md) | Functional spec — endpoint contracts, the v1/v2 split, open gaps (§7). |

Both descend from `../2026-08-26-spk-boq-improvement-PRD.md` / `-FSD.md`.

| [task-boq-submit-400-FINDINGS.md](task-boq-submit-400-FINDINGS.md) | `POST /projects/tasks/boqs/submit` returning 400 on the FE's payload |
| [draft-spk-scope-and-search-FINDINGS.md](draft-spk-scope-and-search-FINDINGS.md) | Draft draws are contract-scoped, not SPK-scoped (F1); draft search |
| [spk-cancel-parity-FINDINGS.md](spk-cancel-parity-FINDINGS.md) | Cancel SPK: detach contract + drop task BoQ lines |
| [estimatedCost-review-resume.md](estimatedCost-review-resume.md) | Review resume for `feat/estimatedCost` (ecff33eb): P1 multi-SPK correctness + USD/IDR unit drift |
| [HANDOFF.md](HANDOFF.md) | Session handoff, 2026-09-03. Analysis only — some items were invalidated by concurrent edits; re-verify against the tree. |
## SQL

Run order for a production rollout: **checklist §A → migrations → checklist §A again**.

| File | Use | Where |
|---|---|---|
| [prod-shortenflow-checklist.sql](prod-shortenflow-checklist.sql) | Readiness verify (§A read-only) + remediation (§B) | prod |
| [prod-shortenflow-migrations.sql](prod-shortenflow-migrations.sql) | Hand-run form of `AddProjectTaskSpks` + `AddProjectTaskBoqDrafts`. Idempotent. **Run as a whole script** — the guarded `IF...BEGIN` blocks break in a client that splits on `;`. | prod |
| [repair-cancelled-spk-task-boqs.sql](repair-cancelled-spk-task-boqs.sql) | Repairs task BoQ lines orphaned by a cancelled SPK. Only when checklist A4 returns rows; audit section first. | prod |
| [data.sql](data.sql) | **Preferred fixture.** Self-contained: own contractor, 2 contracts, 2 BOQs, 1 project, 5 tasks, covering S-A happy path / S-B multi-SPK / S-C over-budget / S-D saved draft. Re-runnable; §1 alone is the teardown. | dev |
| [seed-shortenflow-fixture.sql](seed-shortenflow-fixture.sql) | Older 2-scenario fixture. Reuses existing dev rows (contractor, unit, `r3test.agil`) instead of creating its own — superseded by `data.sql`, kept because it exercises a hierarchical BOQ on borrowed data. | dev |

Every fixture owns the GUID range `5F000000-0000-4000-8000-0000000000XX`, so its rows are
always findable and removable.

Not shorten-flow, moved back to the repo root where their duplicates already lived:
`prod-add-artificial-lift-audit-columns.sql`, `prod-add-eur-gas-oil-well-zone-assignments.sql`,
`prod-add-project-search-code-and-fulltext.sql`.
