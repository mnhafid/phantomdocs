-- =====================================================================
-- notification_templates: rows the target is missing after the release doc (sections 1-21).
-- Source: dev phantomdb, 2026-11-11. Every row is required by phi-dev code or a phi-dev seed.
-- Run AFTER doc sections 1, 2 and 4 (category table, color_code/notification_category_id columns, categories).
-- DBeaver-safe: no DECLARE / GO. A ';' inside a message is NCHAR(59).
-- Re-run safe: each INSERT skips a row whose name + type already exists.
-- Not included: action_plan_pic_request/diverted/responded (dev DB only, no code or seed on any branch).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 22. Add Notification Template For Action Plan Approval
-- Source: phi-dev `seed_action_plan_approval.sql` (same id, title, message). Read by the approval route config, not by a C# constant.

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

-- ---------------------------------------------------------------------
-- 23. Add Notification Template For EUR Update Rejected
-- Source: phi-dev `seed_eur_update_notification_templates.sql`. Read by `EurUpdateRequestConstants.TemplateRejected`. The approval request and approved rows already exist on target.

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

-- ---------------------------------------------------------------------
-- 24. Add Highlight Template For Well Surveillance
-- Source: phi-dev `seed_highlight_templates.sql`. Read by `HighlightTemplates.WellByAlertType` (InactiveWellDownhole, NoFlowRemainingEur).

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

-- ---------------------------------------------------------------------
-- 25. Add Notification Template For Contract Remaining Warning
-- Read by `ContractsService` (ContractRemainingTime/ValueNotificationTemplate). Values are from dev: the phi-dev `seed_contract_warning_config.sql` has older wording and other ids.

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

-- ---------------------------------------------------------------------
-- 26. Update contract_value_depletion_warning title + message to dev (target title: 'Contract Value Reminder').
-- No auto rollback: back up the current title/message first.

UPDATE notification_templates
SET title = N'Contract [contract_number] Value Warning',
    message = N'Contract [contract_number] with a value of [contract_value] is predicted to be depleted by [contract_expired_date]. Please review it.',
    updated_at = GETDATE(), updated_by = '00000000-0000-0000-0000-000000000000'
WHERE name = N'contract_value_depletion_warning' AND type = N'notification' AND deleted_at IS NULL;

-- ---------------------------------------------------------------------
-- Verify: expect 13 rows.
SELECT t.name, t.type, t.title, t.color_code, c.name AS category
FROM notification_templates t
LEFT JOIN notification_categories c ON c.id = t.notification_category_id
WHERE t.deleted_at IS NULL AND t.name IN (N'phantom_iac_action_plan_review_request', N'phantom_iac_action_plan_approved', N'phantom_iac_action_plan_rejected', N'phantom_iac_action_plan_returned', N'phantom_iac_action_plan_modify_approval_request', N'phantom_iac_action_plan_modify_ssdp_approval_request', N'phantom_iac_action_plan_reject_approval_request', N'phantom_iac_eur_cumprod_eur_update_rejected', N'phantom_hc_well_surveilance_inactive_well_detected', N'phantom_hc_well_surveilance_well_intervention_recommended', N'contract_remaining_value_warning', N'contract_remaining_time_warning', N'contract_value_depletion_warning')
ORDER BY t.name;

-- Rollback (inserts only):
-- DELETE FROM notification_templates WHERE id IN ('22222222-2222-2222-2222-222222224001', '22222222-2222-2222-2222-222222224006', '22222222-2222-2222-2222-222222224007', '22222222-2222-2222-2222-222222224005', '22222222-2222-2222-2222-222222224002', '22222222-2222-2222-2222-222222224003', '22222222-2222-2222-2222-222222224004', '22222222-2222-2222-2222-222222221939', '18570000-0000-4000-8000-000000000026', '18570000-0000-4000-8000-000000000025', '9C1F5A10-2E44-4B6D-8F31-6D0A7C21B003', '9C1F5A10-2E44-4B6D-8F31-6D0A7C21B002');
