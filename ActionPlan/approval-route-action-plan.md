|                                                                                                 |                              |
| :---------------------------------------------------------------------------------------------- | :--------------------------- |
| 1. Add Action Plan Approval tables and columns (migration 20261102150929_AddActionPlanApproval) |                              |
| Type                                                                                            | DDL                          |
| Prepared By                                                                                     | nurhafid.oceantech@gmail.com |
| Approved By                                                                                     |                              |
| Date Executed                                                                                   |                              |

-- 1a. New columns on the plan tables
ALTER TABLE pep_action_plan ADD
    department_id           nvarchar(50)     NULL,
    requires_approval       bit              NOT NULL CONSTRAINT DF_pep_action_plan_requires_approval DEFAULT 0,
    approval_status         varchar(30)      NULL,
    current_cycle_id        uniqueidentifier NULL,
    approved_at             datetime         NULL,
    approved_by             uniqueidentifier NULL,
    rejected_at             datetime         NULL,
    rejected_by             uniqueidentifier NULL,
    work_order_number       nvarchar(100)    NULL,
    assigned_department     nvarchar(50)     NULL,
    review_pic_id           uniqueidentifier NULL,
    execution_department_id nvarchar(50)     NULL,
    execution_pic_id        uniqueidentifier NULL;

ALTER TABLE phss_action_plan ADD
    department_id           nvarchar(50)     NULL,
    requires_approval       bit              NOT NULL CONSTRAINT DF_phss_action_plan_requires_approval DEFAULT 0,
    approval_status         varchar(30)      NULL,
    current_cycle_id        uniqueidentifier NULL,
    approved_at             datetime         NULL,
    approved_by             uniqueidentifier NULL,
    rejected_at             datetime         NULL,
    rejected_by             uniqueidentifier NULL,
    work_order_number       nvarchar(100)    NULL,
    assigned_department     nvarchar(50)     NULL,
    review_pic_id           uniqueidentifier NULL,
    execution_department_id nvarchar(50)     NULL,
    execution_pic_id        uniqueidentifier NULL;

-- 1b. WHC fields on artificial lift (PHI-2242)
ALTER TABLE pep_action_plan_artificial_lift ADD
    whc_type         varchar(20)   NULL,
    compression_type decimal(18,6) NULL,
    owned_by         varchar(20)   NULL,
    contract_number  nvarchar(100) NULL,
    asset_number     nvarchar(100) NULL,
    cost_allocation  nvarchar(100) NULL;

ALTER TABLE phss_action_plan_artificial_lift ADD
    whc_type         varchar(20)   NULL,
    compression_type decimal(18,6) NULL,
    owned_by         varchar(20)   NULL,
    contract_number  nvarchar(100) NULL,
    asset_number     nvarchar(100) NULL,
    cost_allocation  nvarchar(100) NULL;

-- 1c. Free-text contract number on well test (PHI-2354)
ALTER TABLE pep_action_plan_well_test  ADD contract_number nvarchar(100) NULL;
ALTER TABLE phss_action_plan_well_test ADD contract_number nvarchar(100) NULL;

-- 1d. Widen the approval engine columns for the per-type route category / flow names
ALTER TABLE approval_routes    ALTER COLUMN category      nvarchar(100) NULL;
ALTER TABLE approval_processes ALTER COLUMN approval_flow nvarchar(100) NOT NULL;

-- 1e. New tables
CREATE TABLE action_plan_approval_cycles (
    id                  uniqueidentifier NOT NULL DEFAULT ((newid())),
    action_plan_source  varchar(10)      NULL,
    action_plan_id      uniqueidentifier NOT NULL,
    cycle_no            int              NOT NULL,
    path                varchar(20)      NULL,
    previous_cycle_id   uniqueidentifier NULL,
    approval_process_id uniqueidentifier NULL,
    decided_by          uniqueidentifier NOT NULL,
    decided_at          datetime         NOT NULL,
    remarks             nvarchar(max)    NULL,
    outcome             varchar(20)      NULL,
    closed_at           datetime         NULL,
    closed_by           uniqueidentifier NULL,
    created_at          datetime         NOT NULL,
    created_by          uniqueidentifier NOT NULL,
    CONSTRAINT PK_action_plan_approval_cycles PRIMARY KEY (id),
    CONSTRAINT FK_action_plan_approval_cycles_approval_processes FOREIGN KEY (approval_process_id) REFERENCES approval_processes (id),
    CONSTRAINT FK_action_plan_approval_cycles_previous_cycle_id FOREIGN KEY (previous_cycle_id) REFERENCES action_plan_approval_cycles (id)
);

CREATE TABLE action_plan_approver_slas (
    id       uniqueidentifier NOT NULL DEFAULT ((newid())),
    cycle_id uniqueidentifier NOT NULL,
    level    int              NOT NULL,
    sla_days int              NOT NULL,
    CONSTRAINT PK_action_plan_approver_slas PRIMARY KEY (id),
    CONSTRAINT FK_action_plan_approver_slas_cycles FOREIGN KEY (cycle_id) REFERENCES action_plan_approval_cycles (id)
);

CREATE TABLE action_plan_approvers (
    id       uniqueidentifier NOT NULL DEFAULT ((newid())),
    cycle_id uniqueidentifier NOT NULL,
    level    int              NOT NULL,
    user_id  uniqueidentifier NOT NULL,
    CONSTRAINT PK_action_plan_approvers PRIMARY KEY (id),
    CONSTRAINT FK_action_plan_approvers_cycles FOREIGN KEY (cycle_id) REFERENCES action_plan_approval_cycles (id),
    CONSTRAINT FK_action_plan_approvers_users FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE action_plan_modifications (
    id                uniqueidentifier NOT NULL DEFAULT ((newid())),
    cycle_id          uniqueidentifier NOT NULL,
    original_snapshot nvarchar(max)    NULL,
    proposed_snapshot nvarchar(max)    NULL,
    changed_fields    nvarchar(max)    NULL,
    applied_at        datetime         NULL,
    applied_by        uniqueidentifier NULL,
    created_at        datetime         NOT NULL,
    created_by        uniqueidentifier NOT NULL,
    CONSTRAINT PK_action_plan_modifications PRIMARY KEY (id),
    CONSTRAINT FK_action_plan_modifications_cycles FOREIGN KEY (cycle_id) REFERENCES action_plan_approval_cycles (id)
);

-- 1f. Indexes
CREATE INDEX IX_pep_action_plan_approval_status_department ON pep_action_plan (approval_status, department_id) WHERE deleted_at IS NULL;
CREATE INDEX IX_pep_action_plan_current_cycle_id ON pep_action_plan (current_cycle_id);
CREATE INDEX IX_pep_action_plan_execution_pic_id ON pep_action_plan (execution_pic_id);
CREATE INDEX IX_pep_action_plan_review_pic_id ON pep_action_plan (review_pic_id);
CREATE UNIQUE INDEX UX_pep_action_plan_work_order_number ON pep_action_plan (work_order_number) WHERE work_order_number IS NOT NULL;

CREATE INDEX IX_phss_action_plan_approval_status_department ON phss_action_plan (approval_status, department_id) WHERE deleted_at IS NULL;
CREATE INDEX IX_phss_action_plan_current_cycle_id ON phss_action_plan (current_cycle_id);
CREATE INDEX IX_phss_action_plan_execution_pic_id ON phss_action_plan (execution_pic_id);
CREATE INDEX IX_phss_action_plan_review_pic_id ON phss_action_plan (review_pic_id);
CREATE UNIQUE INDEX UX_phss_action_plan_work_order_number ON phss_action_plan (work_order_number) WHERE work_order_number IS NOT NULL;

CREATE INDEX IX_action_plan_approval_cycles_approval_process_id ON action_plan_approval_cycles (approval_process_id);
CREATE INDEX IX_action_plan_approval_cycles_previous_cycle_id ON action_plan_approval_cycles (previous_cycle_id);
CREATE UNIQUE INDEX UX_action_plan_approval_cycles_plan_cycle_no ON action_plan_approval_cycles (action_plan_source, action_plan_id, cycle_no) WHERE action_plan_source IS NOT NULL;
CREATE UNIQUE INDEX UX_action_plan_approver_slas_cycle_level ON action_plan_approver_slas (cycle_id, level);
CREATE INDEX IX_action_plan_approvers_cycle_level ON action_plan_approvers (cycle_id, level);
CREATE INDEX IX_action_plan_approvers_user_id ON action_plan_approvers (user_id);
CREATE UNIQUE INDEX UX_action_plan_approvers_cycle_user ON action_plan_approvers (cycle_id, user_id);
CREATE UNIQUE INDEX UX_action_plan_modifications_cycle_id ON action_plan_modifications (cycle_id);

-- 1g. Foreign keys from the plan tables
ALTER TABLE pep_action_plan  ADD CONSTRAINT FK_pep_action_plan_current_cycle FOREIGN KEY (current_cycle_id) REFERENCES action_plan_approval_cycles (id);
ALTER TABLE pep_action_plan  ADD CONSTRAINT FK_pep_action_plan_users_execution_pic_id FOREIGN KEY (execution_pic_id) REFERENCES users (id);
ALTER TABLE pep_action_plan  ADD CONSTRAINT FK_pep_action_plan_users_review_pic_id FOREIGN KEY (review_pic_id) REFERENCES users (id);
ALTER TABLE phss_action_plan ADD CONSTRAINT FK_phss_action_plan_current_cycle FOREIGN KEY (current_cycle_id) REFERENCES action_plan_approval_cycles (id);
ALTER TABLE phss_action_plan ADD CONSTRAINT FK_phss_action_plan_users_execution_pic_id FOREIGN KEY (execution_pic_id) REFERENCES users (id);
ALTER TABLE phss_action_plan ADD CONSTRAINT FK_phss_action_plan_users_review_pic_id FOREIGN KEY (review_pic_id) REFERENCES users (id);

-- 1h. Record the migration so EF tooling agrees with the DB
INSERT INTO __EFMigrationsHistory (MigrationId, ProductVersion)
SELECT '20261102150929_AddActionPlanApproval', '9.0.0'
WHERE NOT EXISTS (SELECT 1 FROM __EFMigrationsHistory WHERE MigrationId = '20261102150929_AddActionPlanApproval');

|  |  |
| :- | :- |
| 2. Seed Action Plan Approval config, permission group 30 (161-163) and notification templates |  |
| Type | DML |
| Prepared By | nurhafid.oceantech@gmail.com |
| Approved By |  |
| Date Executed |  |

-- Source: src-be/DataAccess/Database/seed_action_plan_approval.sql, sections 1-3. Idempotent. Run after item 1.

-- 1. custom_configurations ---------------------------------------------------------------------------------------

-- WO number department segment: {seq:D4}/WO/{short}/{year}. key = submitter department, value = short name ("/" not allowed).
INSERT INTO custom_configurations (id, name, description, detail, created_at, created_by, updated_at, updated_by)
SELECT '33333333-3333-3333-3333-333333330001', 'work_order_department_short_names', 'Action Plan - WO number department short names',
       N'[{"key":"Subsurface Development Area 1","value":"SDA1","note":""},{"key":"Subsurface Development Area 2","value":"SDA2","note":""}]',
       GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at),
       GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM custom_configurations WHERE name = 'work_order_department_short_names' AND deleted_at IS NULL);

-- PO review pool = users holding this permission (161 Review Action Plan).
INSERT INTO custom_configurations (id, name, description, detail, created_at, created_by, updated_at, updated_by)
SELECT '33333333-3333-3333-3333-333333330002', 'action_plan_review_permission_id', 'Action Plan - permission id of the PO review pool',
       N'[{"key":"permission_id","value":"161","note":""}]',
       GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at),
       GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM custom_configurations WHERE name = 'action_plan_review_permission_id' AND deleted_at IS NULL);

-- PO review SLA in working days (same shape as approval_sla_default_days).
INSERT INTO custom_configurations (id, name, description, detail, created_at, created_by, updated_at, updated_by)
SELECT '33333333-3333-3333-3333-333333330003', 'action_plan_review_sla_days', 'Action Plan - PO review SLA in working days',
       N'[{"key":"days","value":"3","note":""}]',
       GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at),
       GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM custom_configurations WHERE name = 'action_plan_review_sla_days' AND deleted_at IS NULL);

-- 2. permissions (group 30) [Q9] -------------------------------------------------------------------------------------------
-- Group 30 "Action Plan Approval". 160 Process Action Plan Request (group 29) is left as it is and not used.
INSERT INTO permission_groups (id, name, description, created_at, updated_at)
SELECT 30, 'Action Plan Approval', 'Action Plan Approval', GETDATE(), GETDATE()
WHERE NOT EXISTS (SELECT 1 FROM permission_groups WHERE id = 30);

INSERT INTO permissions (id, permission_group_id, name, description, created_at)
SELECT v.id, 30, v.name, v.description, GETDATE()
FROM (VALUES
    (161, 'Review Action Plan',  'PO review of a submitted action plan (approve / modify / reject)'),
    (162, 'Approve Action Plan', 'Approve the pending level of an action plan Modify / Reject approval'),
    (163, 'Reject Action Plan',  'Reject the pending level of an action plan Modify / Reject approval')
) v (id, name, description)
WHERE NOT EXISTS (SELECT 1 FROM permissions p WHERE p.id = v.id);

-- Who holds 161 / 162 / 163 is set in Retina (R3TINA ROLEACL / ACL), not in casbin: the API gates read the caller's
-- Retina ACL, like GET /users/permissions. See the RETINA insert queries (Approval Route Action Plan doc).

-- 3. notification_templates (7) [Q8] ---------------------------------------------------------------------------------
-- Placeholders: [action_type], [wo_number], [approver_name]. Plain-text copy from Approval.md §Notifikasi;
-- swap in the FE notification_inapp_content HTML with an UPDATE once it exists (see seed_eur_update_notification_templates.sql).
-- returned is "draft" copy (not yet requested). approved / rejected follow PRD 2243 / 2247 / 2259 [Q8].
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, created_at, created_by)
SELECT v.id, v.name, v.title, v.message,
       (SELECT TOP 1 id FROM notification_categories WHERE name = v.category),
       v.color_code,
       GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
FROM (VALUES
    ('22222222-2222-2222-2222-222222224001', 'phantom_iac_action_plan_review_request',
     '[action_type] Request', N'WO Number [wo_number] [action_type] need Approval.', 'Request', 'warning'),
    ('22222222-2222-2222-2222-222222224002', 'phantom_iac_action_plan_modify_approval_request',
     'Modify Action Plan', N'WO Number [wo_number] Action Plan requires your approval and remarks before returning to SSDP department.', 'Request', 'warning'),
    ('22222222-2222-2222-2222-222222224003', 'phantom_iac_action_plan_modify_ssdp_approval_request',
     'Modify Action Plan', N'WO Number [wo_number] Action Plan has been modified by Production Operations and requires your approval.', 'Request', 'warning'),
    ('22222222-2222-2222-2222-222222224004', 'phantom_iac_action_plan_reject_approval_request',
     'Reject Action Plan', N'WO Number [wo_number] Action Plan rejection requires your approval and remarks.', 'Request', 'warning'),
    ('22222222-2222-2222-2222-222222224005', 'phantom_iac_action_plan_returned',
     'Action Plan Returned', N'WO Number [wo_number] Action Plan was returned by [approver_name]. Please modify or reject it.', 'Request', 'warning'),
    ('22222222-2222-2222-2222-222222224006', 'phantom_iac_action_plan_approved',
     '[action_type] In Progress', N'WO Number [wo_number] [action_type] Action Plan has been approved and is in progress.', 'Approval', 'positive'),
    ('22222222-2222-2222-2222-222222224007', 'phantom_iac_action_plan_rejected',
     'Action Plan Rejected by Manager', N'WO Number [wo_number] Action Plan rejected', 'Approval', 'danger')
) v (id, name, title, message, category, color_code)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates t WHERE t.id = v.id);

|  |  |
| :- | :- |
| 3. Backfill approval status on already-submitted action plans |  |
| Type | DML |
| Prepared By | nurhafid.oceantech@gmail.com |
| Approved By |  |
| Date Executed |  |

-- Plans submitted before approval existed become approved (no cycle rows, no WO number).
-- Only rows with approval_status IS NULL, so a re-run never overwrites live approval data.
-- Dev, 2026-11-03: 74 PEP + 5156 PHSS submitted rows.
UPDATE ap
SET ap.approval_status   = 'approved',
    ap.requires_approval = 0,
    ap.approved_at       = ap.submitted_at,
    ap.department_id     = NULLIF(u.department, '')
FROM pep_action_plan ap
LEFT JOIN users u ON u.id = ap.created_by
WHERE ap.record_state = 'submitted' AND ap.approval_status IS NULL;

UPDATE ap
SET ap.approval_status   = 'approved',
    ap.requires_approval = 0,
    ap.approved_at       = ap.submitted_at,
    ap.department_id     = NULLIF(u.department, '')
FROM phss_action_plan ap
LEFT JOIN users u ON u.id = ap.created_by
WHERE ap.record_state = 'submitted' AND ap.approval_status IS NULL;

|  |  |
| :- | :- |
| 4. Retina (R3TINA, Oracle): Action Plan Approval privileges 161-163 |  |
| Type | DML |
| Prepared By | nurhafid.oceantech@gmail.com |
| Approved By |  |
| Date Executed |  |

-- Action Plan Approval privileges in Retina (R3TINA, Oracle) — PHI-2243 / PHI-2242 / PHI-2354, 2026-11-05.
-- Format = GET /api/v1/roles/{id}/permissions/insert-query: URLPATH = COMPONENTID = permission group name,
-- SEQ = dbo.permissions.id, PAGE = permission name. Only SEQ is evaluated.
-- The Phantom side (permission group 30 + permissions 161-163) is in seed_action_plan_approval.sql; run that first,
-- otherwise GET /users/permissions drops these SEQs.
--
-- The four roles already exist: substitute each {ACLID_*} with that role's EXISTING ROLEACL.ACLID
-- (SELECT ACLID, SYSROLE FROM R3TINA.ROLEACL WHERE SYSNAME = 'PHANTOM'). Dev SYSROLE names may be short codes
-- (e.g. 'PO'): use whatever SYSROLE the environment's users carry.
--
--   SEQ 161 Review Action Plan  -> PO review pool (POST .../review)
--   SEQ 162 Approve Action Plan -> level approvers (POST .../approval/approve)
--   SEQ 163 Reject Action Plan  -> level approvers (POST .../approval/reject)
-- Phantom's API checks the caller's Retina ACL for these SEQs (same source as GET /users/permissions); a level
-- decision also needs the user to be on the pending level of the cycle.

-- Production Operations: review + level approve / reject (PO managers)
INSERT INTO R3TINA.ACL (ACLID, URLPATH, COMPONENTID, HIDDEN, READONLY, DISABLED, SEQ, PAGE) VALUES({ACLID_PO},'Action Plan Approval','Action Plan Approval',0,0,0,161,'Review Action Plan');
INSERT INTO R3TINA.ACL (ACLID, URLPATH, COMPONENTID, HIDDEN, READONLY, DISABLED, SEQ, PAGE) VALUES({ACLID_PO},'Action Plan Approval','Action Plan Approval',0,0,0,162,'Approve Action Plan');
INSERT INTO R3TINA.ACL (ACLID, URLPATH, COMPONENTID, HIDDEN, READONLY, DISABLED, SEQ, PAGE) VALUES({ACLID_PO},'Action Plan Approval','Action Plan Approval',0,0,0,163,'Reject Action Plan');

-- Subsurface Development Area 1 / 2: last level of a Modify (SSDP approver)
INSERT INTO R3TINA.ACL (ACLID, URLPATH, COMPONENTID, HIDDEN, READONLY, DISABLED, SEQ, PAGE) VALUES({ACLID_SDA1},'Action Plan Approval','Action Plan Approval',0,0,0,162,'Approve Action Plan');
INSERT INTO R3TINA.ACL (ACLID, URLPATH, COMPONENTID, HIDDEN, READONLY, DISABLED, SEQ, PAGE) VALUES({ACLID_SDA1},'Action Plan Approval','Action Plan Approval',0,0,0,163,'Reject Action Plan');
INSERT INTO R3TINA.ACL (ACLID, URLPATH, COMPONENTID, HIDDEN, READONLY, DISABLED, SEQ, PAGE) VALUES({ACLID_SDA2},'Action Plan Approval','Action Plan Approval',0,0,0,162,'Approve Action Plan');
INSERT INTO R3TINA.ACL (ACLID, URLPATH, COMPONENTID, HIDDEN, READONLY, DISABLED, SEQ, PAGE) VALUES({ACLID_SDA2},'Action Plan Approval','Action Plan Approval',0,0,0,163,'Reject Action Plan');

-- Super Admin: all three
INSERT INTO R3TINA.ACL (ACLID, URLPATH, COMPONENTID, HIDDEN, READONLY, DISABLED, SEQ, PAGE) VALUES({ACLID_SUPERADMIN},'Action Plan Approval','Action Plan Approval',0,0,0,161,'Review Action Plan');
INSERT INTO R3TINA.ACL (ACLID, URLPATH, COMPONENTID, HIDDEN, READONLY, DISABLED, SEQ, PAGE) VALUES({ACLID_SUPERADMIN},'Action Plan Approval','Action Plan Approval',0,0,0,162,'Approve Action Plan');
INSERT INTO R3TINA.ACL (ACLID, URLPATH, COMPONENTID, HIDDEN, READONLY, DISABLED, SEQ, PAGE) VALUES({ACLID_SUPERADMIN},'Action Plan Approval','Action Plan Approval',0,0,0,163,'Reject Action Plan');

COMMIT;
