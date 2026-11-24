# PRD: SPK Warning Notification

| | |
|---|---|
| **Status** | Draft |
| **Author** | Claude (grilled with mnhafid) |
| **Date** | 2026-08-15 |
| **Version** | 0.1 |
| **Related docs** | [2026-08-15-spk-warning-notification-FSD.md](2026-08-15-spk-warning-notification-FSD.md) · [2026-08-15-spk-warning-notification-TICKETS.md](2026-08-15-spk-warning-notification-TICKETS.md) |

## 1. Overview

Field inspectors are the people accountable for an SPK's execution in the field, but today nothing tells them anything about it. They are not told when an SPK they are assigned to is released and the clock starts, and they are not told when its actual progress falls behind plan. Both facts already exist in the database — `spks.released_at` and the plan/actual weights in `spk_boq_schedules` that feed the SPK S-curve — but they are only visible to someone who opens the SPK detail page and reads the curve.

This work adds two push warnings to the SPK's field inspectors: a one-off notification the moment an SPK is released, and a recurring warning while an SPK's actual progress sits at or below a configured negative deviation from plan. Both go out as email plus an in-app notification, using the mailer and notification plumbing already in the codebase. Two rows are added to Custom Configuration so the deviation threshold and the resend cadence are business-tunable without a deploy.

## 2. Problem Statement

1. **Release is silent.** `SpksService.ReleaseSpkAsync` flips status to `released`, stamps `released_at`/`released_by`, and returns. The field inspectors named on `spk_field_inspectors` are never told the work is now live, so the start of execution depends on someone telling them out of band.
2. **Falling behind is invisible until someone looks.** phiDev already computes an SPK S-curve (`GetSpkSCurveDataAsync`, from `spk_boq_schedules.plan_weight` vs `actual_weight`), but it is a pull-only chart on a detail screen. An SPK can drift 20 percentage points behind plan for weeks with nobody notified.
3. **Comparable warnings exist for contracts, not for SPKs.** Contract value depletion has a full warning pipeline (threshold in Custom Configuration, Quartz job, email + in-app, configurable frequency). Projects have a "task without SPK" reminder. SPK — the object that actually carries field execution — has neither.
4. **Any threshold hard-coded now becomes a deploy.** The tolerable deviation is a business judgment that will be re-tuned; so is how often people want to be nagged. Both belong in Custom Configuration, next to `contracts.budget_threshold` and `contracts.time_threshold`.

## 3. Goals & Success Metrics

| ID | Goal | Metric | Target |
|---|---|---|---|
| G1 | Field inspectors learn about a release without being told manually | Share of SPK releases that queue a notification to every active field inspector with an email | 100% |
| G2 | An SPK that falls behind plan raises a warning without anyone looking | Share of released SPKs whose deviation is at or below the threshold that produce a warning within one job cycle (24h) | 100% |
| G3 | Threshold and cadence are tunable without a deploy | Code changes required to change the deviation threshold or the resend cadence after rollout | 0 |
| G4 | Warnings do not become noise | Duplicate warnings for the same SPK inside one breach episode when frequency is `one_time` | 0 |

## 4. Non-Goals

| Not doing | Why cut |
|---|---|
| A configurable recipient list (admin picks who gets SPK warnings) | Decided in grilling: recipients are the SPK's own field inspectors, the people who can act on it. A settings table + endpoints + UI is the contract-depletion shape and is not needed here. |
| Reminders on the release trigger | Release is an event, not a condition. It fires once, at release. Only the deviation warning has a cadence. |
| Warnings for `draft` / `approved` / `on hold` / `finished` / `cancelled` SPKs | Deviation is only meaningful while the SPK is live. |
| Cost-value deviation (plan vs actual rupiah) | Decided in grilling: deviation means **progress** deviation, from the S-curve weights. Cost deviation is a separate metric on the same table if it is ever wanted. |
| A UI screen for these settings | Custom Configuration already has a working admin CRUD screen and API. Two new rows need no new screen. |
| Escalation (notify the approver / manager when the inspector ignores it) | Not asked for. Add when someone reports warnings being ignored. |
| Per-SPK or per-department override of the threshold | One global threshold matches the wording of the acceptance criteria. Revisit if departments disagree on the number. |
| Changing how `spk_boq_schedules` weights are produced | The S-curve source is taken as correct; this feature only reads it. |

## 5. Users & Personas

| Persona | Description | Key need |
|---|---|---|
| Field Inspector | Named on `spk_field_inspectors`. Accountable for execution and progress reporting of one or more SPKs. Lives in email and on a phone, not on the SPK detail screen. | To be told the moment their SPK goes live, and to be told when it is slipping — without opening the app to find out. |
| Business Admin | Maintains Custom Configuration rows. | To change the deviation threshold and the warning cadence without asking engineering for a release. |
| Backend Engineer / QA | Operates the rollout and verifies behavior on dev. | A way to fire the deviation check on demand instead of waiting for the cron, and logs that say what was evaluated and what was skipped. |

## 6. User Stories

| ID | Story | Goal |
|---|---|---|
| US-01 | As a **Field Inspector**, I want an email and in-app notification when an SPK I am assigned to is released, so that I know execution has started and against which dates. | G1 |
| US-02 | As a **Field Inspector**, I want a warning when my SPK's actual progress falls to or below the tolerated deviation from plan, so that I can act before the slip becomes unrecoverable. | G2 |
| US-03 | As a **Business Admin**, I want to set the deviation threshold in Custom Configuration, so that the definition of "behind schedule" can be tuned to how the business actually runs. | G3 |
| US-04 | As a **Business Admin**, I want to choose whether deviation warnings repeat daily, weekly, or fire once per breach, so that the warnings stay useful instead of being filtered out as spam. | G3, G4 |
| US-05 | As a **QA engineer**, I want to trigger the deviation check on demand, so that I can verify the feature without waiting a day for the schedule. | G2 |

## 7. Custom Configuration

Two rows, following the existing `contracts.budget_threshold` naming and detail shape.

| `name` | Type | Meaning | Default when unset |
|---|---|---|---|
| `warning.spk_deviation_threshold` | float, 2 decimals | Warn when the SPK's actual-minus-plan progress is **at or below negative X percentage points**. `5.00` means warn at −5.00 pp or worse. | `5.00` (see Assumptions) |
| `warning.spk_reminder_frequency` | enum: `daily` / `weekly` / `one_time` | How often a deviation warning is re-sent while an SPK stays in breach. | `one_time` |

## 8. Assumptions

1. **The threshold is written as a magnitude.** The acceptance criteria say "sama atau kurang dari negatif X persen". An admin may reasonably type `5.00` or `-5.00` meaning the same thing, so the reader takes the magnitude: the effective comparison is always `deviation ≤ -|X|`. Flagged because it silently forgives a sign mistake that would otherwise invert the feature.
2. **Default threshold `5.00`** when the config row is missing or unparseable. The acceptance criteria give a default only for frequency. Warning at −5 pp is a conservative starting point; if the business wants "no warning until configured", say so and the default becomes "skip the deviation check entirely".
3. **`one_time` means once per breach episode**, not once per SPK forever: if an SPK recovers above the threshold and later falls back below it, it warns again. Confirmed in grilling.
4. **Deviation is in percentage points of progress weight**, since `spk_boq_schedules` weights sum to 100 across an SPK. `actual 45, plan 52` → deviation `-7.00`.
5. **Recipients are the SPK's active field inspectors with a non-empty email.** An SPK with no such inspector is skipped with a warning log — same behavior as the project-task reminder skipping projects without a PIC.
6. **The daily check runs at 08:00 local**, matching every other notification schedule in the codebase.

## 9. Rollout

Two Custom Configuration rows are seeded by a self-contained idempotent SQL script (the repo convention: literal GUIDs, no `DECLARE`/`GO`). Behavior is inert until an SPK is released or a released SPK breaches the threshold, so there is no backfill and no migration of historical SPKs — the first run only evaluates current state. Rollback is dropping the Quartz job registration; the config rows and the state table are harmless if left behind.
