# Notification Templates: Missing Rows (dev → target)

Source: dev `phantomdb.notification_templates`, 2026-11-11. Compared with `query_result_2026-11-11T16_30_42.csv` (30 rows), the release doc (sections 1–21) and the `phi-dev` branch.

The release doc adds 78 of the 93 rows that the target is missing. This file adds 12 more, which phi-dev code or phi-dev seeds need, and aligns one title. Same SQL as `notification-templates-missing-rows.sql`.

**Rules for every statement:**

- DBeaver-safe: no `DECLARE`, no `GO`. A `;` inside a message is written as `NCHAR(59)`.
- Re-run safe: each `INSERT` skips a row when the same `name` + `type` already exists.
- `id` is the dev GUID. `notification_category_id` is found by category name, because section 4 creates the categories with `NEWID()`.
- Run after doc sections 1, 2 and 4.

**Not included:** `action_plan_pic_request`, `action_plan_pic_diverted`, `action_plan_pic_responded`. They exist only in the dev DB. No code and no seed on any branch uses them.

## 22. Add Notification Template For Action Plan Approval

| Type | Prepared By | Approved By | Date Executed |
|---|---|---|---|
| DML | mnhafid |  |  |


Source: phi-dev `seed_action_plan_approval.sql` (same id, title, message). Read by the approval route config, not by a C# constant.

```sql
-- phantom_iac_action_plan_review_request
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT '22222222-2222-2222-2222-222222224001', N'phantom_iac_action_plan_review_request', N'[action_type] Request',
       N'WO Number [wo_number] [action_type] need Approval.',
       (SELECT TOP 1 id FROM notification_categories WHERE name = N'Request'), N'warning', N'notification', GETDATE(), '00000000-0000-0000-0000-000000000000'
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = N'phantom_iac_action_plan_review_request' AND type = N'notification' AND deleted_at IS NULL);

-- phantom_iac_action_plan_approved
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT '22222222-2222-2222-2222-222222224006', N'phantom_iac_action_plan_approved', N'[action_type] In Progress',
       N'WO Number [wo_number] [action_type] Action Plan has been approved and is in progress.',
       (SELECT TOP 1 id FROM notification_categories WHERE name = N'Approval'), N'positive', N'notification', GETDATE(), '00000000-0000-0000-0000-000000000000'
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = N'phantom_iac_action_plan_approved' AND type = N'notification' AND deleted_at IS NULL);

-- phantom_iac_action_plan_rejected
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT '22222222-2222-2222-2222-222222224007', N'phantom_iac_action_plan_rejected', N'Action Plan Rejected by Manager',
       N'WO Number [wo_number] Action Plan rejected',
       (SELECT TOP 1 id FROM notification_categories WHERE name = N'Approval'), N'danger', N'notification', GETDATE(), '00000000-0000-0000-0000-000000000000'
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = N'phantom_iac_action_plan_rejected' AND type = N'notification' AND deleted_at IS NULL);

-- phantom_iac_action_plan_returned
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT '22222222-2222-2222-2222-222222224005', N'phantom_iac_action_plan_returned', N'Action Plan Returned',
       N'WO Number [wo_number] Action Plan was returned by [approver_name]. Please modify or reject it.',
       (SELECT TOP 1 id FROM notification_categories WHERE name = N'Request'), N'warning', N'notification', GETDATE(), '00000000-0000-0000-0000-000000000000'
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = N'phantom_iac_action_plan_returned' AND type = N'notification' AND deleted_at IS NULL);

-- phantom_iac_action_plan_modify_approval_request
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT '22222222-2222-2222-2222-222222224002', N'phantom_iac_action_plan_modify_approval_request', N'Modify Action Plan',
       N'WO Number [wo_number] Action Plan requires your approval and remarks before returning to SSDP department.',
       (SELECT TOP 1 id FROM notification_categories WHERE name = N'Request'), N'warning', N'notification', GETDATE(), '00000000-0000-0000-0000-000000000000'
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = N'phantom_iac_action_plan_modify_approval_request' AND type = N'notification' AND deleted_at IS NULL);

-- phantom_iac_action_plan_modify_ssdp_approval_request
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT '22222222-2222-2222-2222-222222224003', N'phantom_iac_action_plan_modify_ssdp_approval_request', N'Modify Action Plan',
       N'WO Number [wo_number] Action Plan has been modified by Production Operations and requires your approval.',
       (SELECT TOP 1 id FROM notification_categories WHERE name = N'Request'), N'warning', N'notification', GETDATE(), '00000000-0000-0000-0000-000000000000'
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = N'phantom_iac_action_plan_modify_ssdp_approval_request' AND type = N'notification' AND deleted_at IS NULL);

-- phantom_iac_action_plan_reject_approval_request
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT '22222222-2222-2222-2222-222222224004', N'phantom_iac_action_plan_reject_approval_request', N'Reject Action Plan',
       N'WO Number [wo_number] Action Plan rejection requires your approval and remarks.',
       (SELECT TOP 1 id FROM notification_categories WHERE name = N'Request'), N'warning', N'notification', GETDATE(), '00000000-0000-0000-0000-000000000000'
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = N'phantom_iac_action_plan_reject_approval_request' AND type = N'notification' AND deleted_at IS NULL);
```

## 23. Add Notification Template For EUR Update Rejected

| Type | Prepared By | Approved By | Date Executed |
|---|---|---|---|
| DML | mnhafid |  |  |


Source: phi-dev `seed_eur_update_notification_templates.sql`. Read by `EurUpdateRequestConstants.TemplateRejected`. The approval request and approved rows already exist on target.

```sql
-- phantom_iac_eur_cumprod_eur_update_rejected
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT '22222222-2222-2222-2222-222222221939', N'phantom_iac_eur_cumprod_eur_update_rejected', N'EUR Update Rejected',
       N'<div style="width: 100%">
  <div style="display: flex' + NCHAR(59) + N' flex-direction: column' + NCHAR(59) + N' gap: 4px">
    <span style="color: #62748e">
      EUR update for <span style="color: #e7000b"> {{well_name}} Well </span>
      has been rejected by the Manager.
    </span>

    <span style="color: #e7000b' + NCHAR(59) + N' font-weight: bold">
      Go to EUR Update &rarr' + NCHAR(59) + N'
    </span>
  </div>
</div>',
       (SELECT TOP 1 id FROM notification_categories WHERE name = N'Approval'), N'danger', N'notification', GETDATE(), '00000000-0000-0000-0000-000000000000'
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = N'phantom_iac_eur_cumprod_eur_update_rejected' AND type = N'notification' AND deleted_at IS NULL);
```

## 24. Add Highlight Template For Well Surveillance

| Type | Prepared By | Approved By | Date Executed |
|---|---|---|---|
| DML | mnhafid |  |  |


Source: phi-dev `seed_highlight_templates.sql`. Read by `HighlightTemplates.WellByAlertType` (InactiveWellDownhole, NoFlowRemainingEur).

```sql
-- phantom_hc_well_surveilance_inactive_well_detected
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT '18570000-0000-4000-8000-000000000026', N'phantom_hc_well_surveilance_inactive_well_detected', N'Inactive Well Detected',
       N'<div style="width: 100%">
  <div style="display: flex' + NCHAR(59) + N' flex-direction: column' + NCHAR(59) + N' gap: 4px">
    <span>
      <span style="color: #e7000b">{{well_name}}</span>
      <span style="color: #62748e"
        >are inactive - <b>{{issue}} Problem.</b></span
      >
    </span>
    <span style="color: #e7000b' + NCHAR(59) + N' font-weight: 700"
      >Create Work Order &rarr' + NCHAR(59) + N'</span
    >
  </div>
</div>',
       NULL, N'danger', N'highlight', GETDATE(), '00000000-0000-0000-0000-000000000000'
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = N'phantom_hc_well_surveilance_inactive_well_detected' AND type = N'highlight' AND deleted_at IS NULL);

-- phantom_hc_well_surveilance_well_intervention_recommended
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT '18570000-0000-4000-8000-000000000025', N'phantom_hc_well_surveilance_well_intervention_recommended', N'Well Intervention Recommended',
       N'<div style="width: 100%">
  <div style="display: flex' + NCHAR(59) + N' flex-direction: column' + NCHAR(59) + N' gap: 4px">
    <span>
      <span style="color: #e7000b">{{well_name}}</span>
      <span style="color: #62748e">has no flow with remaining EUR.</span>
    </span>
    <span style="color: #e7000b' + NCHAR(59) + N' font-weight: 700"
      >Go to Action Plan &rarr' + NCHAR(59) + N'</span
    >
  </div>
</div>',
       NULL, N'danger', N'highlight', GETDATE(), '00000000-0000-0000-0000-000000000000'
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = N'phantom_hc_well_surveilance_well_intervention_recommended' AND type = N'highlight' AND deleted_at IS NULL);
```

## 25. Add Notification Template For Contract Remaining Warning

| Type | Prepared By | Approved By | Date Executed |
|---|---|---|---|
| DML | mnhafid |  |  |


Read by `ContractsService` (ContractRemainingTime/ValueNotificationTemplate). Values are from dev: the phi-dev `seed_contract_warning_config.sql` has older wording and other ids.

```sql
-- contract_remaining_value_warning
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT '9C1F5A10-2E44-4B6D-8F31-6D0A7C21B003', N'contract_remaining_value_warning', N'Contract Remaining Value Warning',
       N'Contract [contract_name] has reached the [threshold_percent]% remaining-value threshold and expires on [contract_expired_date]. Please review it.',
       NULL, NULL, N'notification', GETDATE(), '00000000-0000-0000-0000-000000000000'
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = N'contract_remaining_value_warning' AND type = N'notification' AND deleted_at IS NULL);

-- contract_remaining_time_warning
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT '9C1F5A10-2E44-4B6D-8F31-6D0A7C21B002', N'contract_remaining_time_warning', N'Contract Remaining Time Warning',
       N'Contract [contract_name] is nearing its end date and will expire on [contract_expired_date]. Please review it.',
       NULL, NULL, N'notification', GETDATE(), '00000000-0000-0000-0000-000000000000'
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = N'contract_remaining_time_warning' AND type = N'notification' AND deleted_at IS NULL);
```

## 26. Update Notification Template Contract Value Depletion Warning

| Type | Prepared By | Approved By | Date Executed |
|---|---|---|---|
| DML | mnhafid |  |  |


Target title is `Contract Value Reminder`. Dev title is `Contract [contract_number] Value Warning`. This aligns title and message to dev. No automatic rollback: keep the old title and message before you run it.

```sql
UPDATE notification_templates
SET title = N'Contract [contract_number] Value Warning',
    message = N'Contract [contract_number] with a value of [contract_value] is predicted to be depleted by [contract_expired_date]. Please review it.',
    updated_at = GETDATE(), updated_by = '00000000-0000-0000-0000-000000000000'
WHERE name = N'contract_value_depletion_warning' AND type = N'notification' AND deleted_at IS NULL;
```

## Verify

Expect 13 rows.

```sql
SELECT t.name, t.type, t.title, t.color_code, c.name AS category
FROM notification_templates t
LEFT JOIN notification_categories c ON c.id = t.notification_category_id
WHERE t.deleted_at IS NULL AND t.name IN (N'phantom_iac_action_plan_review_request', N'phantom_iac_action_plan_approved', N'phantom_iac_action_plan_rejected', N'phantom_iac_action_plan_returned', N'phantom_iac_action_plan_modify_approval_request', N'phantom_iac_action_plan_modify_ssdp_approval_request', N'phantom_iac_action_plan_reject_approval_request', N'phantom_iac_eur_cumprod_eur_update_rejected', N'phantom_hc_well_surveilance_inactive_well_detected', N'phantom_hc_well_surveilance_well_intervention_recommended', N'contract_remaining_value_warning', N'contract_remaining_time_warning', N'contract_value_depletion_warning')
ORDER BY t.name;
```

## Rollback

Deletes only the rows this file inserted (by dev id).

```sql
DELETE FROM notification_templates WHERE id IN ('22222222-2222-2222-2222-222222224001', '22222222-2222-2222-2222-222222224006', '22222222-2222-2222-2222-222222224007', '22222222-2222-2222-2222-222222224005', '22222222-2222-2222-2222-222222224002', '22222222-2222-2222-2222-222222224003', '22222222-2222-2222-2222-222222224004', '22222222-2222-2222-2222-222222221939', '18570000-0000-4000-8000-000000000026', '18570000-0000-4000-8000-000000000025', '9C1F5A10-2E44-4B6D-8F31-6D0A7C21B003', '9C1F5A10-2E44-4B6D-8F31-6D0A7C21B002');
```

## Not in scope

- `project_due_date_reminder`: phi-dev `ProjectRemindersService` needs it. It exists on target, but **not on dev**, so the project due-date in-app notification is skipped on dev.
- `project_task_without_spk_reminder`: exists on target, no phi-dev code uses it.
