# 14 — Enhancement: review Action Plan takes several execution PICs (`execution_pic_ids`)

- **Ticket / PR:** PHI-2243, PR #1543
- **Recorded:** 25 Nov 2026
- **Status:** PR #1543 open (commit 462fb64a). Build OK, ActionPlan tests 290/290, local curl OK. Migration applied on the dev DB.

## Why

The PO assigns the work order to more than one field PIC on review. The plan stored only one (`execution_pic_id`).

## Changes

- Review request (approve / modify): `execution_pic_id` (Guid) → `execution_pic_ids` (Guid list). The old key is ignored.
  - Well test: department and at least one PIC are required.
  - Each PIC must be an active user of `execution_department_id`. Duplicates are removed; ids are stored sorted.
- Detail PEP / PHSS: `execution_pic` → `execution_pics` (list). **Breaking for the FE.**
- Visibility: every execution PIC sees the plan.
- Open Modify rounds at deploy: the final approval still reads the old `execution_pic_id` key from the snapshot.

## Data

Migration `20261125063501_AddExecutionPicIdsToActionPlans`:
- `execution_pic_ids nvarchar(max) NOT NULL DEFAULT N'[]'` on `pep_action_plan` and `phss_action_plan`.
- Backfill from `execution_pic_id`. The old column stays (not written); drop it later.
- Needs DB compatibility level 130 or higher (`OPENJSON`). Dev = 170. Prod: check before deploy.

Dev DB (25 Nov 2026): applied with the idempotent script. Backfill 22 PEP + 10 PHSS rows.
Until this code deploys to dev, the deployed dev backend still writes only `execution_pic_id`, so new approvals there have `execution_pic_ids = []`.

Test data change on dev: plan `0054/WO/SDA1/2026` (`80816d11-…`) is now `approved` with PICs `r3test.po` + `phi.po`.

## Deploy

1. Check prod compatibility level: `SELECT compatibility_level FROM sys.databases WHERE name = DB_NAME();` (≥ 130).
2. Run the migration (`make db-update`, or the idempotent script).
3. Deploy with the FE change (send `execution_pic_ids`, read `execution_pics`).

## Verification

```sql
SELECT COUNT(*) FROM pep_action_plan WHERE execution_pic_id IS NOT NULL AND execution_pic_ids = N'[]';  -- 0
SELECT COUNT(*) FROM phss_action_plan WHERE execution_pic_id IS NOT NULL AND execution_pic_ids = N'[]'; -- 0
```
