# Work Order: checklist to go to production

Made on 24 Nov. Use this list when the WO work is done. Update the "Status" column as work moves.
Sources: `03-Endpoint-Plan.md`, `02-Knowledge.md` §9, `01-Decision-Log.md`, and the merged code on `phi-dev` (checked 24 Nov).

Status words: **Done** (merged on `phi-dev`), **Open PR**, **To do**, **Decide** (needs a decision first).

---

## 1. Branches and PRs

The base for all WO PRs is `phi-dev`. A release branch (`release/YYYYMMDD`) is made from `ict-main`. Each WO PR is then cherry-picked into it (`git cherry-pick -m 1 -x <merge commit>`), in the merge order, as in PR #1528 / #1532.

| # | Branch → PR | What | Status |
|---|---|---|---|
| 1 | `feat/work-order-schema` → #1523 | 5 WO tables, migration `20261123141311_AddWorkOrders`, `projects.work_order_id` | Done (merged) |
| 2 | `feat/work-order-overview` → #1530 | `GET /work-order/{working_area}/overview` (6 cards) | Done (merged) |
| 3 | `feat/work-order-list` → #1533 | `GET /work-order/{working_area}` (list), with filters, sort, page_size max 100 | Done (merged) |
| 4a | `feat/work-order-draft` (staged, no PR) | Save As Draft, Update Draft, Create (submit) `POST /work-order/{working_area}` (multipart, 5 files); `request_to` codes in list / overview; WO numbers also checked against `work_orders`; seed `seed_work_order_config.sql` | Staged, not built |
| 4b | new | Form options, next number, submit, details, attachments, delete draft | To do |
| 5 | new | Level 0 approve / modify / reject, bulk approve, histories | To do |
| 6 | new | Set Approval Flow, Level 1/2 approve / modify / reject, modification / rejection decisions, approvers list | To do |
| 7 | new | Transfer, disposition, project prefill | To do |
| 8 | new | Changes to existing endpoints: users by permission (department filter), approval routes (layers + permission), WO number format, Action Plan link, projects (WO link, WBS optional, approval skip, finish closes WO) | To do |
| 9 | new | My approval list, notifications (`IMailerService`), urgent 2 × 24 h job (if kept) | To do / Decide |
| 10 | `phantom-fe` | WO pages, menu, permission guards (FE reads `/users/permissions`) | To do |

**Rules for every PR**
- Commit message: `[PHI-xxxx] feat(work-order): …` (ticket first).
- Run `make build`, the tests, and `make check-migrations` before the PR. Do not trust `dotnet test --no-build` after a failed build.
- Each new endpoint needs its service registered in `AppServiceSetup.cs`. Without it, the app crashes at start ("Body was inferred").
- Add the endpoints to the Bruno collection.
- A migration from `dotnet ef migrations add` also picks up the unrelated `permission_groups` / `TempId` change. Remove that part by hand.
- Merge order matters: a PR that uses code from another PR must merge after it (see #1528, which needs #1464).

---

## 2. Database (alter table / migration)

Apply in this order. The migrations run through EF (`dotnet ef database update`), or as a script (`dotnet ef migrations script`).

| # | Change | Where | Status |
|---|---|---|---|
| 1 | `work_order_sequences` | migration `20261109080000_AddWorkOrderSequences` | Done (already used by the Action Plan) |
| 2 | `work_orders`, `work_order_approvers` (with `stage`, `level`, `layer`, `permission_id`, `sla_hours`), `work_order_pics`, `work_order_attachments`, `work_order_histories`, filtered unique index `UX_work_orders_wo_number` | migration `20261123141311_AddWorkOrders` | Done (merged), not yet applied on prod |
| 3 | `projects.work_order_id` (nullable, not unique: one WO can own many projects) | same PR #1523 | Done (merged) |
| 4 | Approval route steps: Level (0/1/2), Layer (1/2), permission ID and SLA for each step. Choose a new table `approval_route_wo_layers` **or** new columns on `approval_route_users` (`layer`, `permission_id`, `user_id` nullable) | new migration | Decide, then To do |
| 5 | Action Plan link to the WO (`work_order_id` on `pep_action_plan` / `phss_action_plan`, or use `work_orders.action_plan_id` only) | new migration if needed | Decide |
| 6 | Any column found missing during the endpoint work (for example a sub-unit list or a proposal store for Modify) | new migration | To do |

**Notes for the run**
- The filtered unique index needs `SET QUOTED_IDENTIFIER ON` (with sqlcmd use `-I`).
- `SET PARSEONLY` does not stop a single-batch file from running. For a dry run, use `SET NOEXEC ON` + `GO` in a wrapper.
- The user's DBeaver splits on `;`, so `DECLARE` variables and `GO` break there. Write self-contained statements.
- Check on prod first that the referenced tables exist: `fields`, `areas`, `rkaps`, `approval_routes`, `projects`, `users`.

---

## 3. Seeds (data)

Write each seed as a self-contained, re-runnable file in `src-be/DataAccess/Database/` (`IF NOT EXISTS` / `WHERE NOT EXISTS`, literal GUIDs).

| #   | Seed                                | Content                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | Status                     |
| --- | ----------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- |
| 1   | `permission_groups` + `permissions` | New groups "Work Order" and "Work Order Approval". Privileges: Read, Create / Submit, Process, Approve Layer 1, Approve Layer 2, Set Approval Flow, Transfer. Numbers: see `02` §9 (proposal 273–279; P1 is open). These tables have no primary key, so check for duplicate ids after the insert.                                                                                                                                                                                         | Decide numbers, then To do |
| 2   | `custom_configurations`             | `work_order.request_to` (11 departments, Category / Function on or off), `work_order.categories`, `work_order.schedule_type` (simple / detailed per department), `work_order.transfer_departments` (+ sub-units), `work_order.disposition_work_types`, `work_order.number_format`, `permissions.retina_only_ids` (the WO privileges + 161–163), department name map (Request To ↔ `users.department`). Existing: `work_order_department_short_names`, `action_plan_review_permission_id`. | To do                      |
| 3   | `approval_routes`                   | One route for each department: category "Work Order - {Department}", the Level 0 / 1 / 2 steps with the permission ID of each layer. The admin can also add them in Data Config after go-live.                                                                                                                                                                                                                                                                                            | To do                      |
| 4   | `notification_templates`            | One row per WO notification N1–N20 (`03-Endpoint-Plan.md` §3.6.1): new file `seed_work_order_notification_templates.sql`. Needs the categories `Request` and `Approval` in `notification_categories`, and the HTML from `ocean-email-template`. In-app only; email needs no rows. | To do |
| 4b  | `seed_work_order_config.sql`        | `work_order.request_to` (codes → departments, G33) and `work_order.categories_without_approval` (D4). It also appends the short names PROJECTS, OSF, PO, DRILLING, WLI to `work_order_department_short_names` (G32). Before you run it, check that the Drilling, WLI, PHSS Field and Sangatta Field names are equal to `users.department`.                                                                                                                                                                                                                                                      | Staged, not run            |
| 5   | `work_order_sequences`              | None. The counter row is made on the first WO of each department and year.                                                                                                                                                                                                                                                                                                                                                                                                                | –                          |

---

## 4. Permissions and access

| # | Step | Who | Status |
|---|---|---|---|
| 1 | Add the WO privileges to the RBAC sheet ("Phantom PHI Mapping" and "PHI-NEW by Method": route, method, View / Modify) | Ocean | To do |
| 2 | Add the WO routes to `RbacRouteMaps` (page access). Decide first: does the route gate cover the WO pages? (`03` §5, open point 1) | Ocean | Decide |
| 3 | Retina: insert ROLEACL / ACL rows (SEQ = the new privilege ids) for each department SYSROLE (`{Dept} - Modify - Leader`, `- Modify - Member`, `- Read - Guest`, `- Approval - Member`). Use the insert-query format (`GET /roles/{id}/permissions/insert-query`). Replace `{ACLID_*}` before the run. | R3 team runs it on prod; Ocean prepares the file | To do |
| 4 | Put the new Retina-only ids in `permissions.retina_only_ids`, so that `/users/by-permission/{id}` can list the users | Ocean | To do |
| 5 | Dev / staging test users: add the new SEQ to the `mock_auth_sessions` payload, then log in again | Ocean | To do |
| 6 | Remember: the backend uses the permission ID **only to list users**. It never blocks an action by permission. The action checks are the WO status, the Level / Layer, and the copied approver list. | – | Rule |

---

## 5. Data clean-up and migration of old data

| # | Step | Status |
|---|---|---|
| 1 | The ~50 dev Action Plans that already have a `work_order_number`: keep them as they are, or make a WO row for each? (Q15) | Decide |
| 2 | `users.department` values: fix the duplicates ("OSF" / "Operation & Surface Facilities", "Project" / "Projects") and the empty ones. The Incoming / Outgoing tabs and the approver lists depend on them. | To do |
| 3 | Field departments (PHSS Field, Sangasanga / Sangatta / Tanjung Field) have no `users.department` value today. Decide how users of those fields are found. | Decide |

---

## 6. Release steps (each release)

1. Merge the WO PRs to `phi-dev` in order. Run the tests.
2. Cherry-pick into `release/YYYYMMDD` (one PR, as #1528 / #1532). List every included PR and the merge order in the PR text.
3. Before the deploy:
   - Prepare the migration script and the seed files.
   - Prepare the Retina insert file (send it to the R3 team).
   - Prepare the `custom_configurations` values for prod.
4. Deploy the backend. Then:
   - Run the migrations.
   - Run the seeds.
   - Ask the R3 team to run the Retina file.
5. Deploy the FE.
6. Users log in again, so that the new privileges load into the Retina ACL cache.
7. Smoke test:
   - Create a WO and submit it.
   - Approve it at Level 0.
   - Do Set Approval Flow, Modify and Reject at Level 1.
   - Transfer it, then make a Disposition.
   - Create a Project from it, then Finish.
   - Check the overview cards and the lists.
8. Log every change of this release in `docs/releases/release-YYYY-MM-DD/` (one file per change, plus a row in the README table).

---

## 7. Decisions needed before go-live
1. Privilege numbers (273+ or 164+).
2. Approval route steps: a new table or new columns.
3. Route gate (`RbacRouteMaps`) on the WO pages: yes or no.
4. Transfer: department + PIC (as the Figma shows) and a sub-unit (as the team doc says)?
5. Level 0 reject: final (decision) or resubmit (the Figma History shows "Revision")?
6. The urgent 2 × 24 h rule: keep or drop?
7. Old Action Plans with a WO number (Q15).
8. Facility Upgrade: OSF (Figma) or Project Z9 (team doc)?

## 8. Follow-ups accepted for later (24 Nov)
- PR #1533: change `field_id` (and optionally `page` / `page_size`) to `string?` (an empty query value gives a 500).
- PR #1533: Incoming hides a WO when the requestor department is also the target or assigned department. Check this before go-live.
- Create-WO PR: store `request_to` as the real department name (map the dropdown label); decide UTC or WIB for `created_at` / `approved_at`.



Test users and test cases: `06-Test-Cases-and-Users.md`.
