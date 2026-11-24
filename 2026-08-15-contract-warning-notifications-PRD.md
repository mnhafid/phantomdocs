# PRD: Contract Warning Notifications

| | |
|---|---|
| **Status** | Draft |
| **Author** | Claude |
| **Date** | 2026-08-15 |
| **Version** | 0.1 |
| **Related docs** | [FSD](2026-08-15-contract-warning-notifications-FSD.md) · [TICKETS](2026-08-15-contract-warning-notifications-TICKETS.md) · sibling feature: [Task Gap Reminders PRD](2026-08-15-task-gap-reminders-PRD.md) |

## 1. Overview

Contracts run out of two things: time and money. PHANTOM already computes both — `GetContractCriticalAsync` derives a remaining-value percentage and a remaining-day count for every active contract, and the Contract Critical section of Contract Monitoring colours contracts by them. What it does not do is tell the Contract PIC. This feature adds two threshold warnings, emailed one per contract to that contract's PIC: one when the contract is X days from ending, one when its remaining value falls to X percent or below. Both thresholds live in Custom Config and are the same numbers Contract Critical uses, so the email and the dashboard can never tell different stories.

## 2. Problem Statement

- A contract approaching its end date needs either an amendment or a new tender, and both take months of lead time. Today nobody is told; the Contract PIC has to remember to look at Contract Monitoring.
- A contract whose remaining value is nearly consumed cannot absorb new SPKs. The consequence of missing this is discovered when an SPK is raised and there is no budget behind it.
- The two thresholds that define "critical" are already configured (`contracts.time_threshold`, `contracts.budget_threshold`) and already drive the dashboard, but they drive nothing that reaches a person.
- The one contract email that does exist — `ContractDepletionNotifyJob` → `SendContractValueDepletionWarningNotificationAsync` — is a different thing: it is driven by data-science predicted warning dates (`ds_contract_warning_dates`), and it sends **one email per PIC with a spreadsheet of all their contracts** rather than one email per contract. It answers "which of my contracts will deplete", not "this contract just crossed the line".

## 3. Goals & Success Metrics

| ID | Goal | Metric | Target |
|---|---|---|---|
| G1 | Contract PICs learn about an ending contract in time to act | % of contracts reaching their end date whose PIC received a time warning at least X days earlier (X = configured threshold) | ≥ 95% within one month of launch |
| G2 | Contract PICs learn about a depleting contract | % of contracts crossing the remaining-value threshold whose PIC received a value warning within one scheduled run of the crossing | ≥ 95% within one month of launch |
| G3 | The dashboard and the emails agree | Number of contracts flagged critical in Contract Monitoring that used a different threshold value than the email pipeline | 0, permanently — enforced by a single configuration source |
| G4 | Warnings do not become noise | Emails per contract per warning type | Exactly 1 per threshold crossing |
| G5 | Thresholds are self-service | Engineering tickets needed to change either threshold or the evaluation frequency | 0 — all three are Custom Config rows |

## 4. Non-Goals

| Not doing | Why cut |
|---|---|
| Retiring the existing data-science depletion warning | Confirmed during grilling: the two are different. The predicted-depletion mail and the threshold-crossing mail coexist. See R2 for the duplicate-mail risk this accepts. |
| Per-contract threshold overrides | Both thresholds are organisation-wide policy, consistent with how Contract Critical already treats them. |
| Warning on `work_end_date` as well as `contract_end_date` | Confirmed during grilling that the time trigger uses the contract end date. |
| A new configuration UI or API | Custom Config already has full CRUD endpoints (`/api/v1/custom-configurations/...`). Adding a dedicated settings endpoint would be a second way to write the same rows. |
| Repeating reminders while a contract stays over threshold | Confirmed as once-per-crossing. A weekly nudge is a possible follow-up (Q2). |
| SMS / WhatsApp channels | Email plus the existing in-app notification covers the ask. |

## 5. Users & Personas

| Persona | Description | Key need |
|---|---|---|
| **Contract PIC** | The user assigned to a contract through `contract_pics`. Accountable for keeping the contract valid and funded. | To be told, once and clearly, that this specific contract is running out of time or money — with a link straight to it. |
| **Contract Administrator** | Sets organisation-wide contract policy through Custom Config. | To tune both thresholds and the evaluation cadence without an engineering ticket, and to know the change also moves Contract Critical. |
| **Procurement / Tender planner** | Consumes Contract Critical in Contract Monitoring to decide amendment versus new tender. | The dashboard and the warning emails must be derived from the same numbers, or the two contradict each other in meetings. |

## 6. User Stories

| ID | Story | Priority |
|---|---|---|
| US-01 | As a **Contract PIC**, I want an email X days before my contract ends, so that I can start an amendment or a tender while there is still time. | Must |
| US-02 | As a **Contract PIC**, I want an email when my contract's remaining value drops to X% or below, so that I stop committing SPKs against a budget that is nearly gone. | Must |
| US-03 | As a **Contract PIC**, I want one email per contract rather than a bundled spreadsheet, so that the message is about a decision I can act on now. | Must |
| US-04 | As a **Contract Administrator**, I want both thresholds and the evaluation frequency in Custom Config, so that I can tune them myself. | Must |
| US-05 | As a **Procurement planner**, I want Contract Critical to use exactly the same thresholds as the warnings, so that the dashboard and my inbox agree. | Must |
| US-06 | As a **Contract PIC**, I want the warning to appear in my in-app notifications too, so that it is not lost if I miss the email. | Should |

## 7. Requirements (high level)

1. **Three Custom Config rows** — `contracts.warning_time_remaining` (days), `contracts.warning_remaining_available_value` (percent), `contracts.warning_reminder_frequency` (evaluation cadence). *(US-04)*
2. **Contract Critical reads the same two threshold rows**, replacing `contracts.time_threshold` and `contracts.budget_threshold`, so one number drives both surfaces. *(US-05)*
3. **Time warning** fires when a contract's remaining days fall to the configured threshold or below. *(US-01)*
4. **Value warning** fires when remaining value percentage falls to the configured threshold or below, using the same `(contract_value − spk_value) / contract_value × 100` calculation Contract Critical already performs. *(US-02)*
5. **Once per crossing** — each warning type fires once per contract, and re-arms only if the condition clears and later recurs. *(G4)*
6. **One email per contract**, addressed to that contract's PICs, with the exact copy specified in the FSD. *(US-03)*
7. **A matching in-app notification** for every email. *(US-06)*
8. **A scheduled job plus an internal trigger endpoint** for the evaluation run. *(US-01, US-02)*

Full behavior, thresholds, copy, and error handling are in the [FSD](2026-08-15-contract-warning-notifications-FSD.md).

## 8. Constraints & Dependencies

- **Custom Config storage shape is fixed.** `ApplyCriticalThresholdsAsync` reads rows through `CustomConfigsByNamesAsync` and parses `detail` as a list of `{key, value}` items. New rows must use the same shape or the existing reader silently falls back to defaults.
- **The background job has no user context.** `GetContractCriticalAsync` filters by `deptContext.ActiveDepartments`, which is request-scoped. The evaluation job must not inherit that filter, or it will warn about nothing. This is the single most likely way to ship this feature broken.
- **`IMailerService` queues sends**; the job can confirm queueing, not delivery.
- **Email copy is specified in English**, unlike the existing Indonesian contract templates. This is deliberate — the copy was given verbatim — and makes the contract mailbox bilingual.
- **Cognitive complexity ≤ 15 per method** (`CLAUDE.md`).
- **EF migrations here sweep a spurious `permission_groups`/`TempId` diff**; the migration must be hand-trimmed.
- **Depends on** `contract_pics`, `contracts` (`contract_end_date`, `contract_value`, `spk_value`, `contract_title`, `contract_no`, `status`), `custom_configurations`, `IMailerService`, `INotificationDispatcher` — all existing.
- **Shares infrastructure patterns** with [Task Gap Reminders](2026-08-15-task-gap-reminders-PRD.md): both use a durable Quartz job, a state table to avoid repeat sends, and the same recipient-eligibility predicate. Building the task-gap feature first means this one reuses proven shapes.

## 9. Assumptions

- **A1: The two existing threshold rows are renamed, not duplicated.** `contracts.time_threshold` → `contracts.warning_time_remaining` and `contracts.budget_threshold` → `contracts.warning_remaining_available_value`, with `ApplyCriticalThresholdsAsync` updated to read the new names. The stated requirement is that Contract Critical shares these parameters; keeping both sets of rows would create two numbers for one concept. — *Impact if wrong:* if duplication was actually wanted, the fix is to leave the old rows in place and point only the email pipeline at the new ones. Reversible, but the drift risk returns.
- **A2: "Contract name" in the email body is `contract_title`, falling back to `contract_no` when it is empty.** — *Impact if wrong:* the email identifies contracts by the wrong label; a one-line change.
- **A3: "Validity end agreement" in the time-warning body is `contract_end_date`.** Confirmed during grilling as the trigger date; the body's wording is treated as a label for the same field. — *Impact if wrong:* the email shows a date that is not the one the warning was computed from, which is worse than either alone.
- **A4: A contract with several PICs produces one email per PIC**, each greeting that PIC by name, rather than one email addressed to all of them. The body is personalised, so it cannot be shared. "1 email per contract" is preserved in the sense that matters: no PIC receives more than one email per contract per crossing. — *Impact if wrong:* PIC count changes the send volume; trivial to switch to a single multi-recipient send.
- **A5: Scope matches Contract Critical's own filter** — status approved, `start_date ≤ today ≤ contract_end_date`, `contract_value > 0`, not deleted — **minus** the department filter, which is request-scoped and meaningless in a job. — *Impact if wrong:* either whole classes of contract are never warned about, or the job warns about draft and expired contracts.
- **A6: Remaining value percentage is `(contract_value − spk_value) / contract_value × 100`, clamped at zero**, exactly as `GetContractCriticalAsync` computes it. — *Impact if wrong:* the email and the dashboard disagree, defeating G3.
- **A7: The frequency row accepts the same vocabulary the existing contract depletion schedule uses** (`daily`, `weekly`), defaulting to `daily`. — *Impact if wrong:* an administrator sets a value the scheduler does not recognise; mitigated by validating on read and falling back with a warning.

## 10. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **R1 — The job inherits the department filter** and silently warns about nothing. Symptom is indistinguishable from "no contracts are near threshold". | High if unguarded | High | Called out as a constraint, as A5, and as an explicit ticket acceptance criterion. The run summary logs contracts evaluated, so zero is visible rather than silent. |
| **R2 — Contract PICs receive two overlapping warnings** — the existing predicted-depletion mail and the new value-threshold mail — about the same contract. Accepted deliberately (the two were kept). | High | Medium | Distinct subjects and copy so the two are not mistaken for duplicates. Track complaints for one month; if they arrive, merging is a small follow-up. |
| **R3 — Renaming the config rows breaks Contract Critical** if the data migration and the code change ship apart. | Medium | High | Both in the same ticket (T-01), with the reader falling back to defaults rather than throwing if a row is missing. |
| **R4 — A large threshold makes the first run email every active contract at once.** A 90-day default time threshold means every contract ending within 90 days fires on day one. | High | High | Phase 0 dry run reports how many contracts would fire before any send. Set the thresholds deliberately low for the first live run, then raise them. |
| **R5 — Warning state never re-arms**, so a contract that recovers (amendment adds value or extends the end date) is never warned about again. | Medium | Medium | Explicit reset rule in FR-004: the state row is deleted when the condition clears. |
| **R6 — Rounding at the boundary.** A contract at exactly 12.25% against a 12.25% threshold must fire; a naive `<` comparison misses it. | Medium | Low | The FSD specifies `≤` and matching the dashboard's 2-decimal rounding, with a boundary test. |

## 11. Release & Rollout

1. **Phase 0 — dry run.** Deploy with the internal endpoint only, in dry-run mode. It reports how many contracts would fire per warning type without sending, answering R4 before anyone's inbox does.
2. **Phase 1 — config migration.** Rename the two threshold rows and point Contract Critical at the new names. Add the frequency row. No behavior change visible to users.
3. **Phase 2 — enable sending.** Arm the scheduled trigger at the configured frequency.

The kill switch is the frequency row: an unrecognised value leaves the trigger unset and sends nothing, which is also the failure mode, so the run summary log is the thing to watch.

## 12. Open Questions

| # | Question | Owner | Blocks |
|---|---|---|---|
| Q1 | Should the time warning also consider `work_end_date`, which often precedes `contract_end_date`? Currently contract end date only. | Product | Nothing — one predicate if it changes |
| Q2 | Should a contract that stays over threshold get a weekly nudge after the first email? Currently once per crossing. | Product | Follow-up only |
| ~~Q3~~ | ~~Which permission guards writing the three config rows?~~ **Resolved 2026-08-15: reuse the existing Custom Config permission (obj 17), add nothing.** | — | Closed |
