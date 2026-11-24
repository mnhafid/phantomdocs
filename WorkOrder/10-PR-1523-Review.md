# Review: PR #1523 "feat(work-order): add work_orders schema"

Checked on 24 Nov against the WO knowledge in this folder (00, 03, 06, 07, 08, 09) and the dev database (read-only).
The PR adds the schema only: 5 tables (`work_orders`, `work_order_approvers`, `work_order_pics`, `work_order_attachments`, `work_order_histories`), 1 migration and the status constants. It has no service or endpoint.

Verdict: a good base. It follows the MoM Level / Layer words, it copies the approvers at submit, and it has one history table with snapshots. But 5 points conflict with decisions that we already made. Fix them before the migration goes to dev, because the schema is hard to change after that.

---

## A. Conflicts with our decisions (fix before merge)

**A1. One WO has only one project (`work_orders.project_id`). We decided that one WO can have more than one schedule.**
- Our decisions:
  - MoM 19 Nov: "all schedules under the same Work Order will be Finished too".
  - K15.
  - 08 §2: `projects.work_order_id`, **not unique**.
  - F1: a flag on `projects` (origin = `work_order`).
- PR: the link goes from the WO to one project. A second schedule has no place.
- Fix: put `work_order_id` (and the origin flag) on `projects`. Remove `work_orders.project_id`, or keep it only as the "main project".

**A2. A simple-schedule WO links only to an AP. We decided that a well WO also makes a simple Project (P1).**
- Our decision: P1 (20 Nov). SPK and contract need a project. An AP WO skips only the project **approval**.
- PR: simple schedule → `action_plan_source` / `action_plan_id` only. `project_preparation` → `on_going` without a project.
- Fix: a simple-schedule WO also gets a project (through A1). The AP link stays.

**A3. A rejection at Level 1 stops at the target Manager. We decided that it goes to Level 0 too (D3b, R8).**
- Our decisions:
  - MoM, R8: two confirmations. First Layer 2 Level 1 ("Yes, Reject / No, Cancel"), then Level 0 approves or rejects the rejection.
  - D3b: if Level 0 declines the rejection, the WO goes back to Layer 1 Level 1, and the Reject button is hidden.
- PR: `rejection_review` is final at the target Manager. "Return to Senior" sets `no_reject`. The PR calls the Level 0 step a "PO decision".
- Fix: add the step `rejection_review` at level 0 / layer 2. Set `no_reject` when Level 0 declines (D3b). The target Manager's "No, Cancel" is a separate return. The columns can hold this; only the status flow must change.

**A4. When Level 0 declines a modification, the PR goes to `needs_revision`. We decided that the WO goes to Approved with the old values (X5).**
- Our decision: X5. The system drops the proposal. The WO goes to `approved` with the old parameters.
- PR (step 4b and the status table): Modify writes the new values **into `work_orders`**. "Not OK" → `needs_revision`.
- Problem: while the modification waits for Layer 2 Level 1 and Layer 2 Level 0, the WO row already holds values that nobody approved. To drop the proposal, the system must restore the old values from the previous snapshot.
- Fix: keep the proposal **outside** the WO row (for example `work_order_histories.snapshot` with action `modify_proposed`), and copy it into `work_orders` only after the last approval. The Level 0 modify (X2: edit and approve in one step) can still write directly.

**A5. All approvers are copied once at submit, and one user can be in only one row per WO.**
- Our design: 07. Each stage (submit, target_review, modify, reject, transfer_review) has its own route. The system copies the approvers **at the start of each stage**.
- PR:
  - The requestor picks one `approval_route_id` in the form. The system copies all levels at submit.
  - Unique index `(work_order_id, user_id)`.
- Problems:
  - The Level 2 approvers are not known at submit, because the Transfer happens later.
  - The requestor must not choose the route of the target department.
  - The same Manager can act in two stages (for example Layer 2 Level 0 in `submit` and in the rejection check). A GM / SM with two departments can also be in two Levels. The unique index blocks these cases.
- Fix:
  - Add `stage` to `work_order_approvers`.
  - Insert the rows at the start of each stage.
  - Change the unique index to `(work_order_id, stage, level, layer, user_id)`.
  - Find the route from the bindings (07), not from a form field.

---

## B. Points to check (medium)

**B1. Two numbering paths for the WO number.**
- `pep_action_plan` / `phss_action_plan` already have `work_order_number`. `work_order_sequences` counts per `short_name` + `year`, and `work_order_department_short_names` = SDA1 / SDA2. So the AP makes its own WO number today.
- D1: the WO is the parent. The AP must take the number of the WO and must not make a second number.
- D5b: `custom_configurations` sets the format. The PR says `NNNN/WO/PROJECT/YYYY` with no reference to a config.
- Q45 is still open.

**B2. The two department columns use different words.**
- `requestor_department` = the `users.department` name ("Production Operations").
- `request_to` = an FE key (`osf | projects | phss_field | po | wli`).
- The Level check (09: the department of the user sets the Level) must compare the two. Use the same key for both, or add a map in `custom_configurations`.
- The PR list has no Drilling, PEP RAM, PHSS or PEP PE. They are in the Figma lanes (06, 23 Nov).

**B3. Categories and budget type.**
- The PR lists only the OSF categories (HE / AFA-Modification / Maintenance / Inspection / Study). Our 06 has categories for each Request To (Flowline, RTWS, Gas Lift, Well Test, AL, …).
- `budget_type` (form) and `disposition_type` (`ABI BD / ABI NBD / ABO Routine / ABO Non Routine`) overlap. The Figma project class uses Budget Type → Project Category → Class, and for OSF the budget type sets the class. Decide which field sets the class.
- `schedule_kind` must come from the Request To / category (C6, K13, Q29). The user must not set it.

**B4. Level 2 Transfer.** The PR asks the PO whether Level 2 can transfer. We already have M8: Level 2 makes a Disposition only, and it cannot transfer again.

**B5. No-approval category (R1).** The status table has no path from `draft` directly to `approved` for a no-approval category (R1: the whole chain is skipped). The service will need it.

**B6. Urgent WO.** The MoM says 2 × 24 h per layer. After that, the WO goes to the next layer, and the system records this. `sla_days` is in days, and no history action records the bypass. Add the action `sla_bypassed` and decide on hours or days.

**B7. Requestor Senior skip (G3).** The PR has the case (submit → 0 / 2). The system needs a way to know that a user is Senior / Asst. Manager. See `09-WO-Permission-Level-Plan.md` (privileges 276 / 277). The position columns are not usable.

---

## C. Code points (low)

- **C1.** The migration makes `wo_number`, `title`, `status`, `request_to`, `requestor_department`, `schedule_kind`, histories `action` / `to_status` and attachment `file_name` / `file_url` **nullable**. The entities have them as non-null strings. Make them NOT NULL, as in the entities. `wo_number` is the most important: the PR text says that it must be set from draft.
- **C2.** `current_layer` is `tinyint?`, but `layer` in approvers / histories is `int` NOT NULL. Use one type. Also, MoM Layer 0 = PIC / requestor: use `0` for the requestor / PIC steps, not `null`, so that the words match the MoM glossary.
- **C3.** `work_order_histories.created_at` has no default, and there is no index on `actor_id` in the config (the migration has one). Check that the model and the migration match (`make check-migrations`).
- **C4.** `action_plan_id` is polymorphic with no FK. That is the same as `action_plan_approval_cycles`. It is OK, but if Q15 allows more than one AP per WO, this column is not enough.
- **C5.** No permission seeds. That is OK for a schema PR. The follow-up needs the Layer privileges (09).

---

## D. Matches our decisions (no change)
- Level 0/1/2 and Layer 1/2 words = the MoM 19 Nov glossary.
- Approver copy, so that a route change does not change a running WO (07).
- X2: the Level 0 approver edits and approves in one step.
- X3: a reject at Level 0 is final; no re-submit.
- X4: Layer 2 Level 0 checks a Level 1 modification.
- Project No = WO number (Figma sample, Q35).
- Soft delete, attachments as in `project_documents`, a filtered unique index on `wo_number`.

---

## Update 24 Nov: follow-up comment
Posted: https://github.com/oceaninov/phantom/pull/1523#issuecomment-7127114186

New decisions change problem **A5** (approvers):
- Each department selects its own flow (requestor in Create WO; target and assigned department in "Set Approval Flow"). So "the requestor must not choose the route" is wrong. The rest of A5 is still valid: the approvers are copied per department, and the unique index must include the step.
- Approvers = every user with the permission ID of the layer, only in the department of the Level. The backend only lists users by permission; it does not check the permission on actions.
- `work_order_approvers` must store the permission ID (and the department), or the user list made from it.

Also in the comment: the Transfer rules (permission, department list, sub-unit, optional notes, no second transfer, status back to Waiting Approval), the Level names, the schedule type by department, the Request To list, the Disposition Work Type and the spelling fixes.
Problems A1–A4, B and C do not change.
