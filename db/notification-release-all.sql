-- =====================================================================
-- Notification + Alert release: every SQL Server script not yet executed on target.
-- Built 2026-11-11 from the release Google Doc (sections without 'Date Executed')
-- + docs/db/notification-templates-missing-rows.sql (sections 22-26).
-- Run with SSMS / sqlcmd / Azure Data Studio: batches are split by GO.
-- DBeaver: run one section at a time (select the section, Ctrl+Enter), sections 2, 5 and 7 use DECLARE.
--
-- Excluded:
--   9-18 (first 18) : already executed Nov 11, 2026.
--   18 'Delete grant old Casbin regulator SDA1/SDA2' : its SQL is a copy of the first 18. Fix it in the doc.
--   19 'Rewrite ACL Retina (Oracle)' : Oracle, run on Retina separately.
--
-- Changed vs doc: section 5 finds the 'Alert' category by name (doc hardcoded dev's id F1CAA820-...).
-- =====================================================================

SET NOCOUNT ON;
GO

-- ---------------------------------------------------------------------
-- 1. Add table for Notification Category
-- ---------------------------------------------------------------------
CREATE TABLE [notification_categories] (
   [id]         uniqueidentifier NOT NULL DEFAULT ((newid())),
   [name]       nvarchar(100)    NOT NULL,
   [sort_order] int              NOT NULL DEFAULT 0,
   [created_at] datetime         NOT NULL,
   [created_by] uniqueidentifier NULL,
   [updated_at] datetime         NULL,
   [updated_by] uniqueidentifier NULL,
   CONSTRAINT [PK_notification_categories] PRIMARY KEY ([id])
);
GO

-- ---------------------------------------------------------------------
-- 2. Update table Notification Template
-- ---------------------------------------------------------------------
-- notification_templates.message: 255 → 1000
DECLARE @var1 sysname;
SELECT @var1 = [d].[name]
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[notification_templates]') AND [c].[name] = N'message');
IF @var1 IS NOT NULL EXEC(N'ALTER TABLE [notification_templates] DROP CONSTRAINT [' + @var1 + '];');
ALTER TABLE [notification_templates] ALTER COLUMN [message] nvarchar(1000) NOT NULL;
ALTER TABLE [notification_templates] ADD [notification_category_id] uniqueidentifier NULL;
ALTER TABLE [notification_templates] ADD [color_code] nvarchar(20) NULL;


CREATE INDEX [IX_notification_templates_notification_category_id]
   ON [notification_templates] ([notification_category_id]);


ALTER TABLE [notification_templates] ADD CONSTRAINT [FK_notification_templates_notification_categories]
   FOREIGN KEY ([notification_category_id]) REFERENCES [notification_categories] ([id]);
GO

-- ---------------------------------------------------------------------
-- 3. Update table Notification
-- ---------------------------------------------------------------------
-- notifications.message: 510 → 1000
DECLARE @var0 sysname;
SELECT @var0 = [d].[name]
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[notifications]') AND [c].[name] = N'message');
IF @var0 IS NOT NULL EXEC(N'ALTER TABLE [notifications] DROP CONSTRAINT [' + @var0 + '];');
ALTER TABLE [notifications] ALTER COLUMN [message] nvarchar(1000) NULL;


ALTER TABLE [notifications] ADD [notification_template_id] uniqueidentifier NULL; ALTER TABLE [notifications] ADD [notification_category_id] uniqueidentifier NULL; ALTER TABLE [notifications] ADD [search_text] nvarchar(1200) NULL; 


CREATE INDEX [IX_notifications_notification_template_id]
   ON [notifications] ([notification_template_id]);
CREATE INDEX [IX_notifications_notification_category_id] ON [notifications] ([notification_category_id]);
CREATE INDEX [IX_notifications_user_unread] ON [notifications] ([user_id], [deleted_at], [has_read]) INCLUDE ([notification_category_id], [created_at]);


ALTER TABLE [notifications] ADD CONSTRAINT [FK_notifications_notification_templates]
   FOREIGN KEY ([notification_template_id]) REFERENCES [notification_templates] ([id]);
ALTER TABLE [notifications] ADD CONSTRAINT [FK_notifications_notification_categories]
   FOREIGN KEY ([notification_category_id]) REFERENCES [notification_categories] ([id]);
GO

-- ---------------------------------------------------------------------
-- 4. Add Master Notification Category
-- ---------------------------------------------------------------------
INSERT INTO notification_categories (id, name, sort_order, created_at, created_by) VALUES
 (NEWID(), 'Alert',    1, GETDATE(), '00000000-0000-0000-0000-000000000000'),
 (NEWID(), 'Request',  2, GETDATE(), '00000000-0000-0000-0000-000000000000'),
 (NEWID(), 'Approval', 3, GETDATE(), '00000000-0000-0000-0000-000000000000'),
 (NEWID(), 'Schedule', 4, GETDATE(), '00000000-0000-0000-0000-000000000000');
GO

-- ---------------------------------------------------------------------
-- 5. Add Template Notification Template For Alert Service
-- ---------------------------------------------------------------------
DECLARE @now        datetime         = GETDATE();
DECLARE @systemUser uniqueidentifier = '00000000-0000-0000-0000-000000000000';
DECLARE @type       nvarchar(20)     = N'notification';
DECLARE @color      nvarchar(20)     = N'danger';
-- CHANGED vs doc: lookup by name, ids differ per environment (section 4 uses NEWID()).
DECLARE @category   uniqueidentifier = (SELECT TOP 1 id FROM notification_categories WHERE name = N'Alert');


IF NOT EXISTS (SELECT 1 FROM notification_categories WHERE id = @category)
BEGIN
    RAISERROR('notification_category Alert tidak ada di notification_categories.', 16, 1);
    RETURN;
END


BEGIN TRANSACTION;
BEGIN TRY


DECLARE @tpl TABLE (name nvarchar(100) NOT NULL PRIMARY KEY, title nvarchar(100) NOT NULL, message nvarchar(1000) NOT NULL);


INSERT INTO @tpl (name, title, message) VALUES
    (N'phantom_iac_sudden_inactive_well', N'Sudden Inactive Well Detected',
     N'<div style="width: 100%"><span><span style="color: #e7000b">{{well_name}}</span> <span style="color: #62748e">became inactive today.</span></span></div>'),
    (N'phantom_iac_well_intervention_recommended', N'Well No Flow with Remaining EUR',
     N'<div style="width: 100%"><div style="display: flex; flex-direction: column; gap: 4px"><span><span style="color: #e7000b">{{well_name}}</span> <span style="color: #62748e">has no flow with remaining EUR.</span></span><span style="color: #e7000b; font-weight: 700">Go to Action Plan &rarr;</span></div></div>'),
    (N'phantom_iac_fthp_anomaly_detected', N'FTHP Anomaly Detected',
     N'<div style="width: 100%"><span><span style="color: #e7000b">{{well_name}}</span> <span style="color: #62748e">&plusmn;{{fthp}} psi in {{hours}}h.</span></span></div>'),
    (N'phantom_iac_gradual_fthp_anomaly_detected', N'Gradual FTHP Anomaly Detected',
     N'<div style="width: 100%"><span><span style="color: #e7000b">{{well_name}}</span> <span style="color: #62748e">&plusmn;{{fthp}} psi in {{days}} days.</span></span></div>'),
    (N'phantom_iac_fthp_decline', N'FTHP Decline',
     N'<div style="width: 100%"><span><span style="color: #e7000b">{{well_name}}</span> <span style="color: #62748e">FTHP &darr;{{fthp}} psi in {{days}} days.</span></span></div>'),
    (N'phantom_iac_potential_sand_screen_anomaly', N'Potential Sand Screen Anomaly',
     N'<div style="width: 100%"><span><span style="color: #e7000b">{{well_name}}</span> <span style="color: #62748e">FTHP &uarr;{{fthp}} psi in {{days}} days.</span></span></div>'),
    (N'phantom_iac_debottlenecking_check_required', N'Debottlenecking Check Required',
     N'<div style="width: 100%"><span><span style="color: #e7000b">{{well_name}}</span> <span style="color: #62748e">FTHP increased by {{fthp}} psi in {{days}} days.</span></span></div>'),
    (N'phantom_iac_rtws_mtu_calibration_required', N'RTWS/MTU Calibration Required',
     N'<div style="width: 100%"><div style="display: flex; flex-direction: column; gap: 4px"><span><span style="color: #e7000b">{{well_name}} RTWS/MTU</span> <span style="color: #62748e">deviation exceed {{percentage}}%.</span></span><span style="color: #e7000b; font-weight: 700">Calibrate {{field}} &rarr;</span></div></div>'),
    (N'phantom_iac_oil_production_decline', N'Production Declined Detected',
     N'<div style="width: 100%"><span><span style="color: #e7000b">{{well_count}} Wells</span> <span style="color: #62748e">declined within</span> <span style="color: #e7000b">{{duration_day}} Day.</span></span></div>'),
    (N'phantom_iac_eur_treshold_reached', N'EUR Threshold Reached',
     N'<div style="width: 100%"><span style="color: #e7000b">{{well_name}}</span> <span style="color: #62748e">reached {{eur_percentage}}% of EUR.</span></div>'),
    (N'phantom_iac_eur_treshold_exceeded', N'EUR Threshold Exceeded',
     N'<div style="width: 100%"><span><span style="color: #e7000b">{{well_name}}</span> <span style="color: #62748e">exceeded {{eur_percentage}}% of EUR.</span></span></div>'),
    (N'phantom_iac_eur_exceeded', N'EUR Exceeded',
     N'<div style="width: 100%"><span><span style="color: #e7000b">{{well_name}}</span> <span style="color: #62748e">exceeded {{eur_percentage}}% of EUR.</span></span></div>');


MERGE notification_templates AS t
USING @tpl AS s
    ON t.name = s.name AND t.type = @type AND t.deleted_at IS NULL
WHEN MATCHED AND (t.title <> s.title
               OR t.message <> s.message
               OR ISNULL(t.color_code, N'') <> @color
               OR t.notification_category_id IS NULL OR t.notification_category_id <> @category) THEN
    UPDATE SET t.title                    = s.title,
               t.message                  = s.message,
               t.color_code               = @color,
               t.notification_category_id = @category,
               t.updated_at               = @now,
               t.updated_by               = @systemUser
WHEN NOT MATCHED BY TARGET THEN
    INSERT (name, title, message, color_code, notification_category_id, type, created_at, created_by)
    VALUES (s.name, s.title, s.message, @color, @category, @type, @now, @systemUser);


COMMIT TRANSACTION;


-- Verifikasi: 12 baris, color_code = danger, category terisi
SELECT t.name, t.title, t.type, t.color_code, t.notification_category_id
FROM notification_templates t
INNER JOIN @tpl s ON s.name = t.name
WHERE t.type = @type AND t.deleted_at IS NULL
ORDER BY t.name;


END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO
GO

-- ---------------------------------------------------------------------
-- 6. Update Search Text Notification
-- ---------------------------------------------------------------------
WHILE 1 = 1
BEGIN
   UPDATE TOP (5000) notifications
   SET search_text = LEFT(LTRIM(RTRIM(ISNULL(title, '') + ' ' + ISNULL(message, ''))), 1200)
   WHERE search_text IS NULL;
   IF @@ROWCOUNT = 0 BREAK;
END
GO

-- ---------------------------------------------------------------------
-- 7. Add Alert Content Template For Alert Service
-- ---------------------------------------------------------------------
DECLARE @now        datetime         = GETDATE();
DECLARE @systemUser uniqueidentifier = '00000000-0000-0000-0000-000000000000';
DECLARE @type       nvarchar(20)     = N'alert';
DECLARE @color      nvarchar(20)     = N'danger';




BEGIN TRANSACTION;
BEGIN TRY




DECLARE @tpl TABLE (
    name    nvarchar(100)  NOT NULL PRIMARY KEY,
    title   nvarchar(100)  NOT NULL,
    message nvarchar(1000) NOT NULL
);




INSERT INTO @tpl (name, title, message) VALUES
    -- 2.1 inactive_well (N32)
    (N'phantom_ac_well_surveilance_sudden_inactive_well', N'Sudden Inactive Well Detected',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{well_name}}</span> became inactive today.</span></div>'),
    -- [PRD]
    (N'phantom_ac_well_surveilance_sudden_inactive_well_multiple', N'Sudden Inactive Well Detected',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{count}} Wells</span> became inactive today.</span></div>'),




    -- 2.2 gas_lift_validation (N110)
        (N'phantom_ac_well_surveilance_gas_lift_need_validation', N'Gas Lift Need Validation',
     N'<div style="width: 100%"><div style="display: flex; flex-direction: column; gap: 4px"><span><span style="color: #e7000b; font-weight: 700">{{well_name}}</span> requires Gas Lift.</span><span style="color: #e7000b; font-weight: 700">Create Work Order &rarr;</span></div></div>'),
    -- [PRD]
        (N'phantom_ac_well_surveilance_gas_lift_need_validation_multiple', N'Gas Lift Need Validation',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{count}} Wells</span> require Gas Lift.</span></div>'),




    -- 2.3 no_flow_remaining_eur (N266 / FE: N26)
    (N'phantom_ac_well_surveilance_well_intervention_recommended', N'Well No Flow with Remaining EUR',
     N'<div style="width: 100%"><div style="display: flex; flex-direction: column; gap: 4px"><span><span style="color: #e7000b">{{well_name}}</span> has no flow with remaining EUR.</span><span style="color: #e7000b; font-weight: 700">Go to Action Plan &rarr;</span></div></div>'),
    -- [PRD]
    (N'phantom_ac_well_surveilance_well_intervention_recommended_multiple', N'Well No Flow with Remaining EUR',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{count}} Wells</span> have no flow while EUR remains.</span></div>'),




    -- 2.4 rtws_mtu_deviation (N396)
    (N'phantom_ac_well_surveilance_rtws_mtu_calibration_required', N'RTWS/MTU Calibration Required',
     N'<div style="width: 100%"><div style="display: flex; flex-direction: column; gap: 4px"><span><span style="color: #e7000b; font-weight: 700">{{well_name}} RTWS/MTU</span> deviation exceed <span style="color: #e7000b; font-weight: 700">{{percentage}}%</span></span><span style="color: #e7000b; font-weight: 700">Calibrate {{field}} &rarr;</span></div></div>'),
    -- [PRD]
    (N'phantom_ac_well_surveilance_rtws_mtu_calibration_required_multiple', N'RTWS/MTU Calibration Required',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{count}} Wells</span> RTWS/MTU deviation exceeding 15%.</span></div>'),




    -- 2.5 fthp_change_daily (N99)
    (N'phantom_ac_well_surveilance_fthp_anomaly_detected', N'FTHP Anomaly Detected',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{well_name}}</span> &plusmn;{{fthp}} psi in {{hours}}h.</span></div>'),
    -- [PRD]
    (N'phantom_ac_well_surveilance_fthp_anomaly_detected_multiple', N'FTHP Anomaly Detected',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{count}} Wells</span> FTHP has changed &ge;50 psi in {{hours}}h.</span></div>'),




    -- 2.6 fthp_change_gradual (Notion 99-2, tidak ada di daftar FE)
    (N'phantom_ac_well_surveilance_gradual_fthp_anomaly_detected', N'Gradual FTHP Anomaly Detected',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{well_name}}</span> &plusmn;{{fthp}} psi in {{days}} days.</span></div>'),
    -- [PRD]
    (N'phantom_ac_well_surveilance_gradual_fthp_anomaly_detected_multiple', N'Gradual FTHP Anomaly Detected',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{count}} Wells</span> FTHP &plusmn;200 psi in {{days}} days.</span></div>'),




    -- 2.9 oil_production_decline (N240)  ([PRD] single; file oil_production_decline.html = kartu multiple)
    (N'phantom_ac_well_surveilance_oil_production_decline_single', N'Oil Production Declined Detected',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{well_name}}</span> <span style="color: #62748e">oil production declined within</span> <span style="color: #e7000b; font-weight: 700">{{duration_day}} Day.</span></span></div>'),
    (N'phantom_ac_well_surveilance_oil_production_decline', N'Oil Production Declined Detected',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{well_count}} Wells</span> <span style="color: #62748e">declined within</span> <span style="color: #e7000b; font-weight: 700">{{duration_day}} Day.</span></span></div>'),




    -- 2.9 gas_production_decline [PRD] (belum ada file, tidak ada di daftar FE)
    (N'phantom_ac_well_surveilance_gas_production_decline_single', N'Gas Production Declined Detected',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{well_name}}</span> <span style="color: #62748e">gas production declined within</span> <span style="color: #e7000b; font-weight: 700">{{duration_day}} Day.</span></span></div>'),
    (N'phantom_ac_well_surveilance_gas_production_decline', N'Gas Production Declined Detected',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{well_count}} Wells</span> <span style="color: #62748e">declined within</span> <span style="color: #e7000b; font-weight: 700">{{duration_day}} Day.</span></span></div>'),




    -- 2.11 sand_screen_anomaly (N291)
    (N'phantom_ac_well_surveilance_potential_sand_screen_anomaly', N'Potential Sand Screen Anomaly',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{well_name}}</span> FTHP &uarr;{{fthp}} psi in {{days}} days.</span></div>'),
    -- [PRD]
    (N'phantom_ac_well_surveilance_potential_sand_screen_anomaly_multiple', N'Potential Sand Screen Anomaly',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{count}} Wells</span> FTHP &uarr;50 psi in {{days}} days.</span></div>'),




    -- 2.12 eur_threshold_reached (N297, 80% - < 100%)
    (N'phantom_ac_well_surveilance_eur_treshold_reached', N'EUR Threshold Reached',
     N'<div style="width: 100%"><span style="color: #e7000b; font-weight: 700">{{well_name}}</span> reached {{eur_percentage}}% of EUR.</div>'),
    -- [PRD]
    (N'phantom_ac_well_surveilance_eur_treshold_reached_multiple', N'EUR Threshold Reached',
     N'<div style="width: 100%"><span style="color: #e7000b; font-weight: 700">{{count}} Wells</span> reached 80% of EUR.</div>'),




    -- 2.13 eur_depletion (N374, > 90% - < 100%): HTML eur_treshold_reached.html (mapping FE),
    -- baris sendiri supaya judul "EUR Threshold Exceeded" dan angka multiple 90%
    (N'phantom_ac_well_surveilance_eur_treshold_reached_depletion', N'EUR Threshold Exceeded',
     N'<div style="width: 100%"><span style="color: #e7000b; font-weight: 700">{{well_name}}</span> reached {{eur_percentage}}% of EUR.</div>'),
    -- [PRD]
    (N'phantom_ac_well_surveilance_eur_treshold_reached_depletion_multiple', N'EUR Threshold Exceeded',
     N'<div style="width: 100%"><span style="color: #e7000b; font-weight: 700">{{count}} Wells</span> reached 90% of EUR.</div>'),




    -- eur_exceeded (>= 100%, bagian 2.12, tidak ada di daftar FE)
    (N'phantom_ac_well_surveilance_eur_treshold_exceeded', N'EUR Threshold Exceeded',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{well_name}}</span> exceeded {{eur_percentage}}% of EUR.</span></div>'),
    -- [PRD]
    (N'phantom_ac_well_surveilance_eur_treshold_exceeded_multiple', N'EUR Threshold Exceeded',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{count}} Wells</span> exceeded 100% of EUR.</span></div>'),




    -- 2.14 debottlenecking_check (N403)
    (N'phantom_ac_well_surveilance_debottlenecking_check_required', N'Debottlenecking Check Required',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{well_name}}</span> FTHP increased by {{fthp}} psi in {{days}} days.</span></div>'),
    -- [PRD]
    (N'phantom_ac_well_surveilance_debottlenecking_check_required_multiple', N'Debottlenecking Check Required',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{count}} Wells</span> FTHP increased by 50 psi in {{days}} days.</span></div>'),




    -- 2.16 fthp_decline_3d (N455)
    (N'phantom_ac_well_surveilance_fthp_decline', N'FTHP Decline',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{well_name}}</span> FTHP &darr;{{fthp}} psi in {{days}} days.</span></div>'),
    -- [PRD]
    (N'phantom_ac_well_surveilance_fthp_decline_multiple', N'FTHP Decline',
     N'<div style="width: 100%"><span><span style="color: #e7000b; font-weight: 700">{{count}} Wells</span> FTHP &darr; more than 30 psi in {{days}} days.</span></div>');




MERGE notification_templates AS t
USING @tpl AS s
    ON t.name = s.name AND t.type = @type AND t.deleted_at IS NULL
WHEN MATCHED AND (t.title <> s.title OR t.message <> s.message OR ISNULL(t.color_code, N'') <> @color) THEN
    UPDATE SET t.title      = s.title,
               t.message    = s.message,
               t.color_code = @color,
               t.updated_at = @now,
               t.updated_by = @systemUser
WHEN NOT MATCHED BY TARGET THEN
    INSERT (name, title, message, color_code, type, created_at, created_by)
    VALUES (s.name, s.title, s.message, @color, @type, @now, @systemUser);




COMMIT TRANSACTION;




-- Verifikasi: 28 baris, semua color_code = danger
SELECT t.name, t.title, t.type, t.color_code, LEN(t.message) AS message_len, t.created_at, t.updated_at
FROM notification_templates t
INNER JOIN @tpl s ON s.name = t.name
WHERE t.type = @type AND t.deleted_at IS NULL
ORDER BY t.name;




-- Harus 0 baris
SELECT s.name AS belum_masuk
FROM @tpl s
WHERE NOT EXISTS (
    SELECT 1 FROM notification_templates t
    WHERE t.name = s.name AND t.type = @type AND t.deleted_at IS NULL
);




END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO
GO

-- ---------------------------------------------------------------------
-- 8. Add CustomConfig Alert Schedule
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.custom_configurations WHERE name = N'alert_notification.schedule' AND deleted_at IS NULL)
BEGIN
    INSERT INTO dbo.custom_configurations (id, name, description, detail, created_at, created_by, updated_at, updated_by)
    SELECT NEWID(),
           N'alert_notification.schedule',
           N'Jadwal job alert Well & EUR (cron Quartz 6 kolom). check_cron = cek event triggered, digest_cron = digest daily/weekly, snapshot_cron = capture snapshot highlight, snapshot_retention_days = umur simpan snapshot. enabled=false mematikan ketiga jadwal. Nilai kosong/tidak valid memakai jadwal default. Perubahan berlaku maks. 10 menit.',
           N'[{"key":"enabled","value":"true","note":""},{"key":"check_cron","value":"0 0 * * * ?","note":"tiap jam"},{"key":"digest_cron","value":"0 0 8 * * ?","note":"08:00 tiap hari"},{"key":"snapshot_cron","value":"0 0 0 * * ?","note":"00:00 tiap hari"},{"key":"snapshot_retention_days","value":"14","note":"hari"}]',
           GETDATE(), u.id, GETDATE(), u.id
    FROM (SELECT TOP 1 id FROM dbo.users ORDER BY created_at) u;
END
GO

-- ---------------------------------------------------------------------
-- 20. Add Alert Template For Alert Sprint 2
-- ---------------------------------------------------------------------
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_sudden_temperature_increase', 'Sudden Temperature Increase',
       N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span>
      <span style="color: #e7000b; font-weight: 700">{{well_name}}</span>
      +{{temperature_with_unit}} in {{duration_day}} day.
    </span>
    <span style="color: #e7000b; font-weight: 700"
      >Create Work Order &rarr;</span
    >
  </div>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_sudden_temperature_increase' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_sudden_temperature_increase_multiple', 'Sudden Temperature Increase',
       N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span>
      <span style="color: #e7000b; font-weight: 700">{{well_count}} Wells</span>
      <span style="color: #62748e">+30&deg;F in {{duration_day}} day.</span>
    </span>
    <span style="color: #e7000b; font-weight: 700">Create Work Order &rarr;</span>
  </div>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_sudden_temperature_increase_multiple' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_critical_rate_anomaly', 'Critical Rate Anomaly',
       N'<div style="width: 100%">
  <span>
    <span style="color: #e7000b; font-weight: 700">{{well_name}}</span> requires
    intervention.
  </span>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_critical_rate_anomaly' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_critical_rate_anomaly_multiple', 'Critical Rate Anomaly',
       N'<div style="width: 100%">
  <span>
    <span style="color: #e7000b; font-weight: 700">{{well_count}} Wells</span>
    <span style="color: #62748e">require intervention.</span>
  </span>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_critical_rate_anomaly_multiple' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_choke_adjustment_recommended', 'Choke Adjustment Recommended',
       N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span>
      <span style="color: #e7000b; font-weight: 700">{{well_name}}</span>
      requires choke adjustment.
    </span>
    <span style="color: #e7000b; font-weight: 700"
      >Create Work Order &rarr;</span
    >
  </div>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_eur_treshold_reached' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_eur_treshold_reached' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_choke_adjustment_recommended' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_choke_adjustment_recommended_multiple', 'Choke Adjustment Recommended',
       N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span>
      <span style="color: #e7000b; font-weight: 700">{{well_count}} Wells</span>
      <span style="color: #62748e">require choke adjustment.</span>
    </span>
    <span style="color: #e7000b; font-weight: 700">Create Work Order &rarr;</span>
  </div>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_eur_treshold_reached' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_eur_treshold_reached' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_choke_adjustment_recommended_multiple' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_sudden_fthp_decrease', 'Sudden FTHP Decrease',
       N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span>
      <span style="color: #e7000b; font-weight: 700">{{well_name}}</span>
      descrease by {{fthp}} psi in {{hours}}h.
    </span>
    <span style="color: #e7000b; font-weight: 700"
      >Create Work Order &rarr;</span
    >
  </div>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_sudden_fthp_decrease' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_sudden_fthp_decrease_multiple', 'Sudden FTHP Decrease',
       N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span>
      <span style="color: #e7000b; font-weight: 700">{{well_count}} Wells</span>
      <span style="color: #62748e">FTHP decreased by 30 psi or more in {{hours}}h.</span>
    </span>
    <span style="color: #e7000b; font-weight: 700">Create Work Order &rarr;</span>
  </div>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_sudden_fthp_decrease_multiple' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_sudden_flp_increase', 'Sudden FLP Increase',
       N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span>
      <span style="color: #e7000b; font-weight: 700">{{well_name}}</span>
      increase by {{fthp}} psi in {{hours}}h.
    </span>
    <span style="color: #e7000b; font-weight: 700"
      >Create Work Order &rarr;</span
    >
  </div>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_sudden_flp_increase' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_sudden_flp_increase_multiple', 'Sudden FLP Increase',
       N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span>
      <span style="color: #e7000b; font-weight: 700">{{well_count}} Wells</span>
      <span style="color: #62748e">FLP increased by 30 psi or more in {{hours}}h.</span>
    </span>
    <span style="color: #e7000b; font-weight: 700">Create Work Order &rarr;</span>
  </div>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_sudden_flp_increase_multiple' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_rtws_data_unavailable', 'RTWS Data Unavailable',
       N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span> Check {{well_name}} RTWS status. </span>
    <span style="color: #e7000b; font-weight: 700"
      >RTWS Inspection Work Order &rarr;</span
    >
  </div>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_rtws_data_unavailable' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_rtws_data_unavailable_multiple', 'RTWS Data Unavailable',
       N'<div style="width: 100%">
  <span>
    <span style="color: #e7000b; font-weight: 700">{{well_count}} Wells</span>
    <span style="color: #62748e">RTWS data unavailable.</span>
  </span>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_rtws_data_unavailable_multiple' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_well_production_check_required', 'Well Production Check Required',
       N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span> Check {{well_name}} RTWS status. </span>
    <span style="color: #e7000b; font-weight: 700"
      >Well Inspection Work Order &rarr;</span
    >
  </div>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_well_production_check_required' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_well_production_check_required_multiple', 'Well Production Check Required',
       N'<div style="width: 100%">
  <span>
    <span style="color: #e7000b; font-weight: 700">{{well_count}} Wells</span>
    <span style="color: #62748e">production status requires checking.</span>
  </span>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_well_production_check_required_multiple' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_cyclic_well_ready', 'Cyclic Well Ready',
       N'<div style="width: 100%">
  <span>
    <span style="color: #e7000b; font-weight: 700">{{well_name}}</span> is
    <span style="color: #e7000b"><b>Ready for Production</b></span>
  </span>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_cyclic_well_ready' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_cyclic_well_ready_multiple', 'Cyclic Well Ready',
       N'<div style="width: 100%">
  <span>
    <span style="color: #e7000b; font-weight: 700">{{well_count}} Cyclic Wells</span>
    <span style="color: #62748e">are Ready for Production.</span>
  </span>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_cyclic_well_ready_multiple' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_inactive_well_detected', 'Inactive Well Detected',
       N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span>
      <span style="color: #e7000b; font-weight: 700"
        >{{well_name}} Inactive</span
      >
      - {{issue}} Problem.
    </span>
    <span style="color: #e7000b; font-weight: 700"
      >Create Work Order &rarr;</span
    >
  </div>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_inactive_well_detected' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_inactive_well_detected_multiple', 'Inactive Well Detected',
       N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span>
      <span style="color: #e7000b; font-weight: 700">{{well_count}} Wells Inactive</span>
      <span style="color: #62748e">- Downhole Problem.</span>
    </span>
    <span style="color: #e7000b; font-weight: 700">Create Work Order &rarr;</span>
  </div>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_inactive_well_detected_multiple' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_gas_lift_recommendation', 'Gas Lift Recommendation',
       N'<div style="width: 100%">
  <span>
    <span style="color: #e7000b; font-weight: 700">{{well_name}}</span> may
    require Gas Lift within {{days}} days.
  </span>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_gas_lift_recommendation' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_ac_well_surveilance_gas_lift_recommendation_multiple', 'Gas Lift Recommendation',
       N'<div style="width: 100%">
  <span>
    <span style="color: #e7000b; font-weight: 700">{{well_count}} Wells</span>
    <span style="color: #62748e">may require Gas Lift within {{days}} days.</span>
  </span>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_fthp_anomaly_detected' AND deleted_at IS NULL),
       'alert', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_ac_well_surveilance_gas_lift_recommendation_multiple' AND deleted_at IS NULL);


-- Cek: harus 20 baris.
SELECT name, title, color_code FROM notification_templates WHERE type = 'alert' AND deleted_at IS NULL AND name IN (
  'phantom_ac_well_surveilance_sudden_temperature_increase', 'phantom_ac_well_surveilance_sudden_temperature_increase_multiple',
  'phantom_ac_well_surveilance_critical_rate_anomaly', 'phantom_ac_well_surveilance_critical_rate_anomaly_multiple',
  'phantom_ac_well_surveilance_choke_adjustment_recommended', 'phantom_ac_well_surveilance_choke_adjustment_recommended_multiple',
  'phantom_ac_well_surveilance_sudden_fthp_decrease', 'phantom_ac_well_surveilance_sudden_fthp_decrease_multiple',
  'phantom_ac_well_surveilance_sudden_flp_increase', 'phantom_ac_well_surveilance_sudden_flp_increase_multiple',
  'phantom_ac_well_surveilance_rtws_data_unavailable', 'phantom_ac_well_surveilance_rtws_data_unavailable_multiple',
  'phantom_ac_well_surveilance_well_production_check_required', 'phantom_ac_well_surveilance_well_production_check_required_multiple',
  'phantom_ac_well_surveilance_cyclic_well_ready', 'phantom_ac_well_surveilance_cyclic_well_ready_multiple',
  'phantom_ac_well_surveilance_inactive_well_detected', 'phantom_ac_well_surveilance_inactive_well_detected_multiple',
  'phantom_ac_well_surveilance_gas_lift_recommendation', 'phantom_ac_well_surveilance_gas_lift_recommendation_multiple');
GO

-- ---------------------------------------------------------------------
-- 21. Add Notification Template For Alert Sprint 2
-- ---------------------------------------------------------------------
-- In-app Notification Center templates for the Sprint 2 well alerts (N141, N280, N408, N160, N212-1), type = 'notification'.
-- Insert-only with NEWID(); skips a row whose name already exists as type = 'notification', so a re-run is safe. DBeaver-safe (no DECLARE / GO).
-- Single HTML = ocean-email-template/phantom/notification_inapp_content/<name>.html (main 77d4a8f, PR #18), filled by AlertNotifier.
-- "_multiple" rows (more than 1 well per recipient, type and area) have no FE file yet: copy = "Multiple Alert" in the PRD.
-- A later HTML change needs its own UPDATE by name: a re-run of this file does not overwrite existing rows.
-- color_code = the FE values shared by alerts, notifications and highlights: danger | warning | info | positive.


-- sudden_temperature_increase (N141). Placeholders: {{well_name}}, {{temperature_with_unit}}, {{duration_day}}.
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_iac_well_surveilance_sudden_temperature_increase', 'Sudden Temperature Increase',
       N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span>
      <span style="color: #e7000b">{{well_name}}</span>
      <span style="color: #62748e"
        >+{{temperature_with_unit}} in {{duration_day}} day.</span
      >
    </span>
    <span style="color: #e7000b; font-weight: 700"
      >Create Work Order &rarr;</span
    >
  </div>
</div>',
       (SELECT TOP 1 id FROM notification_categories WHERE name = 'Alert'), 'danger', 'notification',
       GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_iac_well_surveilance_sudden_temperature_increase' AND type = 'notification');


-- sudden_temperature_increase multiple. Placeholders: {{well_count}}, {{duration_day}}.
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_iac_well_surveilance_sudden_temperature_increase_multiple', 'Sudden Temperature Increase',
       N'<div style="width: 100%">
  <span>
    <span style="color: #e7000b">{{well_count}} Wells</span>
    <span style="color: #62748e">+30&deg;F in {{duration_day}} day.</span>
  </span>
</div>',
       (SELECT TOP 1 id FROM notification_categories WHERE name = 'Alert'), 'danger', 'notification',
       GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_iac_well_surveilance_sudden_temperature_increase_multiple' AND type = 'notification');


-- critical_rate_anomaly (N280). Placeholders: {{well_name}}.
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_iac_critical_rate_anomaly', 'Critical Rate Anomaly',
       N'<div style="width: 100%">
  <span>
    <span style="color: #e7000b">{{well_name}}</span>
    <span style="color: #62748e">requires intervention.</span>
  </span>
</div>',
       (SELECT TOP 1 id FROM notification_categories WHERE name = 'Alert'), 'danger', 'notification',
       GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_iac_critical_rate_anomaly' AND type = 'notification');


-- critical_rate_anomaly multiple. Placeholders: {{well_count}}.
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_iac_critical_rate_anomaly_multiple', 'Critical Rate Anomaly',
       N'<div style="width: 100%">
  <span>
    <span style="color: #e7000b">{{well_count}} Wells</span>
    <span style="color: #62748e">require intervention.</span>
  </span>
</div>',
       (SELECT TOP 1 id FROM notification_categories WHERE name = 'Alert'), 'danger', 'notification',
       GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_iac_critical_rate_anomaly_multiple' AND type = 'notification');


-- gas_lift_recommendation (N408). Placeholders: {{well_name}}, {{days}}.
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_iac_gas_lift_recommendation', 'Gas Lift Recommendation',
       N'<div style="width: 100%">
  <span>
    <span style="color: #e7000b">{{well_name}}</span>
    <span style="color: #62748e"
      >may require Gas Lift within {{days}} days.</span
    >
  </span>
</div>',
       (SELECT TOP 1 id FROM notification_categories WHERE name = 'Alert'), 'danger', 'notification',
       GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_iac_gas_lift_recommendation' AND type = 'notification');


-- gas_lift_recommendation multiple. Placeholders: {{well_count}}, {{days}}.
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_iac_gas_lift_recommendation_multiple', 'Gas Lift Recommendation',
       N'<div style="width: 100%">
  <span>
    <span style="color: #e7000b">{{well_count}} Wells</span>
    <span style="color: #62748e">may require Gas Lift within {{days}} days.</span>
  </span>
</div>',
       (SELECT TOP 1 id FROM notification_categories WHERE name = 'Alert'), 'danger', 'notification',
       GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_iac_gas_lift_recommendation_multiple' AND type = 'notification');


-- choke_adjustment (N160). Category yellow in the PRD -> warning. Placeholders: {{well_name}}.
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_iac_well_surveilance_choke_adjustment_recommended', 'Choke Adjustment Recommended',
       N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span>
      <span style="color: #e7000b">{{well_name}}</span>
      <span style="color: #62748e">requires choke adjustment.</span>
    </span>
    <span style="color: #e7000b; font-weight: 700"
      >Create Work Order &rarr;</span
    >
  </div>
</div>',
       (SELECT TOP 1 id FROM notification_categories WHERE name = 'Alert'), 'warning', 'notification',
       GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_iac_well_surveilance_choke_adjustment_recommended' AND type = 'notification');


-- choke_adjustment multiple. Placeholders: {{well_count}}.
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_iac_well_surveilance_choke_adjustment_recommended_multiple', 'Choke Adjustment Recommended',
       N'<div style="width: 100%">
  <span>
    <span style="color: #e7000b">{{well_count}} Wells</span>
    <span style="color: #62748e">require choke adjustment.</span>
  </span>
</div>',
       (SELECT TOP 1 id FROM notification_categories WHERE name = 'Alert'), 'warning', 'notification',
       GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_iac_well_surveilance_choke_adjustment_recommended_multiple' AND type = 'notification');


-- inactive_well_downhole (N212-1). Placeholders: {{well_name}}, {{issue}} (= Downhole).
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_iac_well_surveilance_inactive_well_detected', 'Inactive Well Detected',
       N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span>
      <span style="color: #e7000b">{{well_name}}</span>
      <span style="color: #62748e"
        >are inactive - <b>{{issue}} Problem.</b></span
      >
    </span>
    <span style="color: #e7000b; font-weight: 700"
      >Create Work Order &rarr;</span
    >
  </div>
</div>',
       (SELECT TOP 1 id FROM notification_categories WHERE name = 'Alert'), 'danger', 'notification',
       GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_iac_well_surveilance_inactive_well_detected' AND type = 'notification');


-- inactive_well_downhole multiple. Placeholders: {{well_count}}, {{issue}} (= Downhole).
INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_iac_well_surveilance_inactive_well_detected_multiple', 'Inactive Well Detected',
       N'<div style="width: 100%">
  <span>
    <span style="color: #e7000b">{{well_count}} Wells</span>
    <span style="color: #62748e">inactive - <b>{{issue}} Problem.</b></span>
  </span>
</div>',
       (SELECT TOP 1 id FROM notification_categories WHERE name = 'Alert'), 'danger', 'notification',
       GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_iac_well_surveilance_inactive_well_detected_multiple' AND type = 'notification');




/* ==========================================================================
   Template in-app (type notification) untuk alert sumur yang sebelumnya toast saja:
   gas_lift_validation + 5 tipe Sprint 2 (N529, N496, N367).
   Dipakai InAppTemplateNames; satu notifikasi per sumur (link Detail Well), jadi tidak ada "_multiple".
   Aman dijalankan berulang: INSERT hanya untuk nama yang belum ada.
   ========================================================================== */
SET NOCOUNT ON;


DECLARE @now datetime = GETDATE();
DECLARE @sys uniqueidentifier = '00000000-0000-0000-0000-000000000000';
-- Kategori "Alert" diambil dari template in-app alert sumur yang sudah ada.
DECLARE @category uniqueidentifier = (
  SELECT TOP 1 notification_category_id FROM notification_templates
  WHERE name = 'phantom_iac_potential_sand_screen_anomaly' AND deleted_at IS NULL);


DECLARE @t TABLE(name nvarchar(200) PRIMARY KEY, title nvarchar(200), message nvarchar(max));
INSERT @t(name, title, message) VALUES
(N'phantom_iac_gas_lift_need_validation', N'Gas Lift Need Validation',
N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span>
      <span style="color: #e7000b">{{well_name}}</span>
      <span style="color: #62748e">requires Gas Lift.</span>
    </span>
    <span style="color: #e7000b; font-weight: 700"
      >Create Work Order &rarr;</span
    >
  </div>
</div>'),
(N'phantom_iac_well_surveilance_sudden_fthp_decrease', N'Sudden FTHP Decrease',
N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span>
      <span style="color: #e7000b">{{well_name}}</span>
      <span style="color: #62748e">
        descrease by {{fthp}} psi in {{hours}}h.</span
      >
    </span>
    <span style="color: #e7000b; font-weight: 700"
      >Create Work Order &rarr;</span
    >
  </div>
</div>'),
(N'phantom_iac_well_surveilance_sudden_flp_increase', N'Sudden FLP Increase',
N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span>
      <span style="color: #e7000b">{{well_name}}</span>
      <span style="color: #62748e">
        increase by {{fthp}} psi in {{hours}}h.</span
      >
    </span>
    <span style="color: #e7000b; font-weight: 700"
      >Create Work Order &rarr;</span
    >
  </div>
</div>'),
(N'phantom_iac_well_surveilance_rtws_data_unavailable', N'RTWS Data Unavailable',
N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span>
      <span style="color: #e7000b">{{well_name}}</span>
      <span style="color: #62748e">RTWS data unavailable.</span>
    </span>
    <span style="color: #e7000b; font-weight: 700"
      >RTWS Inspection Work Order &rarr;</span
    >
  </div>
</div>'),
(N'phantom_iac_well_surveilance_well_production_check_required', N'Well Production Check Required',
N'<div style="width: 100%">
  <div style="display: flex; flex-direction: column; gap: 4px">
    <span>
      <span style="color: #e7000b">{{well_name}}</span>
      <span style="color: #62748e">production status requires checking.</span>
    </span>
    <span style="color: #e7000b; font-weight: 700"
      >Well Inspection Work Order &rarr;</span
    >
  </div>
</div>'),
(N'phantom_iac_cyclic_well_ready', N'Cyclic Well Ready',
N'<div style="width: 100%">
  <span>
    <span style="color: #e7000b">{{well_name}}</span>
    <span style="color: #62748e">is <b>Ready for Production</b>.</span>
  </span>
</div>');


INSERT notification_templates(id, name, title, message, type, color_code, notification_category_id, created_at, created_by)
SELECT NEWID(), t.name, t.title, t.message, N'notification', N'danger', @category, @now, @sys
FROM @t t
WHERE NOT EXISTS (SELECT 1 FROM notification_templates n
                  WHERE n.name = t.name AND n.type = N'notification' AND n.deleted_at IS NULL);


SELECT n.name, n.title, n.type, n.color_code, n.notification_category_id
FROM notification_templates n JOIN @t t ON t.name = n.name
WHERE n.type = N'notification' AND n.deleted_at IS NULL
ORDER BY n.name;




INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_iac_oil_production_decline_multiple', 'Production Declined Detected',
       N'<div style="width: 100%">
  <span>
    <span style="color: #e7000b">{{well_count}} Wells</span>
    <span style="color: #62748e">declined within</span>
    <span style="color: #e7000b">{{duration_day}} Day.</span>
  </span>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_iac_oil_production_decline' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_iac_oil_production_decline' AND deleted_at IS NULL),
       'notification', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_iac_oil_production_decline_multiple' AND deleted_at IS NULL);


INSERT INTO notification_templates (id, name, title, message, notification_category_id, color_code, type, created_at, created_by)
SELECT NEWID(), 'phantom_iac_gas_lift_need_validation_multiple', 'Gas Lift Need Validation',
       N'<div style="width: 100%">
  <span>
    <span style="color: #e7000b">{{well_count}} Wells</span>
    <span style="color: #62748e">require Gas Lift.</span>
  </span>
</div>',
       (SELECT TOP 1 notification_category_id FROM notification_templates WHERE name = 'phantom_iac_gas_lift_need_validation' AND deleted_at IS NULL),
       (SELECT TOP 1 color_code FROM notification_templates WHERE name = 'phantom_iac_gas_lift_need_validation' AND deleted_at IS NULL),
       'notification', GETDATE(), (SELECT TOP 1 id FROM users WHERE deleted_at IS NULL ORDER BY created_at)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'phantom_iac_gas_lift_need_validation_multiple' AND deleted_at IS NULL);

UPDATE notification_templates
SET updated_at = GETDATE(),
   message = N'<div style="width: 100%">
 <span>
   <span style="color: #e7000b">{{well_name}}</span>
   <span style="color: #62748e">oil production declined within</span>
   <span style="color: #e7000b">{{duration_day}} Day.</span>
 </span>
</div>'
WHERE name = 'phantom_iac_oil_production_decline' AND deleted_at IS NULL;
GO

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

GO

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

GO

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

GO

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

GO

-- ---------------------------------------------------------------------
-- 26. Update contract_value_depletion_warning title + message to dev (target title: 'Contract Value Reminder').
-- No auto rollback: back up the current title/message first.

UPDATE notification_templates
SET title = N'Contract [contract_number] Value Warning',
    message = N'Contract [contract_number] with a value of [contract_value] is predicted to be depleted by [contract_expired_date]. Please review it.',
    updated_at = GETDATE(), updated_by = '00000000-0000-0000-0000-000000000000'
WHERE name = N'contract_value_depletion_warning' AND type = N'notification' AND deleted_at IS NULL;
GO

-- ---------------------------------------------------------------------
-- Verify
-- ---------------------------------------------------------------------
SELECT type, COUNT(*) AS templates FROM notification_templates WHERE deleted_at IS NULL GROUP BY type ORDER BY type;
SELECT name, sort_order FROM notification_categories ORDER BY sort_order;
SELECT name FROM custom_configurations WHERE name = N'alert_notification.schedule' AND deleted_at IS NULL;
GO
