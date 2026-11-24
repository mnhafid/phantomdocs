/*  Phantom - migrations to apply on PRODUCTION
    Range : everything merged after PR #1076 (0ed51979, 2026-09-03) up to feat/shortenflowboqfilter.
    Source: dotnet ef migrations script --idempotent --context PhantomDbContext, sliced to the 11
            migrations in that range.

    Every statement is guarded by __EFMigrationsHistory, so it is safe to run twice and it does not
    matter which of these production already has.

    NOT INCLUDED - 20260911040000_AddSpkIdIndexToProjectTasks (PR #1166). That migration has no
    .Designer.cs, so it carries no [Migration] attribute and EF does not recognise it. It must be
    regenerated before it can ship anywhere.

    Run inside an explicit transaction and verify before COMMIT.
*/

IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901071036_AddProjectWeatherLogs'
)
BEGIN
    CREATE TABLE [weather_types] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [code] nvarchar(30) NOT NULL,
        [name] nvarchar(100) NOT NULL,
        [severity_score] int NOT NULL,
        [color_hex] nvarchar(7) NULL,
        [default_remark_title] nvarchar(200) NULL,
        [default_remark_body] nvarchar(max) NULL,
        [is_workable] bit NOT NULL DEFAULT CAST(1 AS bit),
        [sort_order] int NOT NULL DEFAULT 0,
        [is_active] bit NOT NULL DEFAULT CAST(1 AS bit),
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        CONSTRAINT [PK_weather_types] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901071036_AddProjectWeatherLogs'
)
BEGIN
    CREATE TABLE [project_weather_logs] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [project_id] uniqueidentifier NOT NULL,
        [log_date] date NOT NULL,
        [weather_type_id] uniqueidentifier NOT NULL,
        [start_time] time(0) NOT NULL,
        [end_time] time(0) NOT NULL,
        [duration_minutes] AS DATEDIFF(MINUTE, [start_time], [end_time]) PERSISTED,
        [remark_title] nvarchar(200) NULL,
        [remark_body] nvarchar(max) NULL,
        [attachments] nvarchar(max) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_project_weather_logs] PRIMARY KEY ([id]),
        CONSTRAINT [CK_project_weather_logs_time_range] CHECK ([end_time] > [start_time]),
        CONSTRAINT [FK_project_weather_logs_projects_project_id] FOREIGN KEY ([project_id]) REFERENCES [projects] ([id]),
        CONSTRAINT [FK_project_weather_logs_weather_types_weather_type_id] FOREIGN KEY ([weather_type_id]) REFERENCES [weather_types] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901071036_AddProjectWeatherLogs'
)
BEGIN
    CREATE INDEX [IX_project_weather_logs_project_date] ON [project_weather_logs] ([project_id], [log_date]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901071036_AddProjectWeatherLogs'
)
BEGIN
    CREATE INDEX [IX_project_weather_logs_weather_type_id] ON [project_weather_logs] ([weather_type_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901071036_AddProjectWeatherLogs'
)
BEGIN
    CREATE UNIQUE INDEX [UX_weather_types_code] ON [weather_types] ([code]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901071036_AddProjectWeatherLogs'
)
BEGIN
    IF EXISTS (SELECT * FROM [sys].[identity_columns] WHERE [name] IN (N'id', N'code', N'name', N'severity_score', N'color_hex', N'default_remark_title', N'default_remark_body', N'is_workable', N'sort_order', N'is_active', N'created_at') AND [object_id] = OBJECT_ID(N'[weather_types]'))
        SET IDENTITY_INSERT [weather_types] ON;
    EXEC(N'INSERT INTO [weather_types] ([id], [code], [name], [severity_score], [color_hex], [default_remark_title], [default_remark_body], [is_workable], [sort_order], [is_active], [created_at])
    VALUES (''6b1f4d3e-0c2a-4c8d-9a1e-2f7b5c9d0001'', N''BRIGHT'', N''Bright'', 1, N''#F5B700'', N''Normal Operation'', N''Cuaca cerah, pekerjaan berjalan normal sesuai jadwal.'', CAST(1 AS bit), 1, CAST(1 AS bit), ''2026-09-01T00:00:00.000''),
    (''6b1f4d3e-0c2a-4c8d-9a1e-2f7b5c9d0002'', N''DRIZZLY'', N''Drizzly'', 2, N''#8ECAE6'', N''Minor Disruption'', N''Gerimis, pekerjaan berjalan dengan perlambatan ringan.'', CAST(1 AS bit), 2, CAST(1 AS bit), ''2026-09-01T00:00:00.000''),
    (''6b1f4d3e-0c2a-4c8d-9a1e-2f7b5c9d0003'', N''RAIN'', N''Rain'', 3, N''#219EBC'', N''Work Slowdown'', N''Hujan, sebagian pekerjaan outdoor dihentikan sementara.'', CAST(0 AS bit), 3, CAST(1 AS bit), ''2026-09-01T00:00:00.000''),
    (''6b1f4d3e-0c2a-4c8d-9a1e-2f7b5c9d0004'', N''WET'', N''Wet'', 4, N''#023047'', N''Work Stopped'', N''Kondisi basah/tergenang, pekerjaan lapangan tidak dapat dilanjutkan.'', CAST(0 AS bit), 4, CAST(1 AS bit), ''2026-09-01T00:00:00.000'')');
    IF EXISTS (SELECT * FROM [sys].[identity_columns] WHERE [name] IN (N'id', N'code', N'name', N'severity_score', N'color_hex', N'default_remark_title', N'default_remark_body', N'is_workable', N'sort_order', N'is_active', N'created_at') AND [object_id] = OBJECT_ID(N'[weather_types]'))
        SET IDENTITY_INSERT [weather_types] OFF;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901071036_AddProjectWeatherLogs'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260901071036_AddProjectWeatherLogs', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901083652_AddProjectWeatherLogIsIssue'
)
BEGIN
    ALTER TABLE [project_weather_logs] ADD [is_issue] bit NOT NULL DEFAULT CAST(0 AS bit);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901083652_AddProjectWeatherLogIsIssue'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260901083652_AddProjectWeatherLogIsIssue', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260902031017_AddWellZoneNameUniqueIndex'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE name = 'IX_well_zones_name' AND object_id = OBJECT_ID('dbo.well_zones'))
    BEGIN
        CREATE UNIQUE NONCLUSTERED INDEX IX_well_zones_name
            ON dbo.well_zones (name)
            WHERE deleted_at IS NULL;
    END
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260902031017_AddWellZoneNameUniqueIndex'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260902031017_AddWellZoneNameUniqueIndex', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260904001347_AddUnitConversionTables'
)
BEGIN
    CREATE TABLE [setting_unit_conversions] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [name] nvarchar(50) NOT NULL,
        [phase] nvarchar(20) NOT NULL,
        [factor] float NOT NULL,
        [is_storage] bit NOT NULL,
        [is_active] int NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_setting_unit_conversions] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260904001347_AddUnitConversionTables'
)
BEGIN
    CREATE TABLE [unit_conversions] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [category] nvarchar(20) NOT NULL,
        [phase] nvarchar(20) NOT NULL,
        [to_unit_id] uniqueidentifier NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_unit_conversions] PRIMARY KEY ([id]),
        CONSTRAINT [FK_unit_conversions_setting_unit_conversions] FOREIGN KEY ([to_unit_id]) REFERENCES [setting_unit_conversions] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260904001347_AddUnitConversionTables'
)
BEGIN
    CREATE INDEX [IX_unit_conversions_to_unit_id] ON [unit_conversions] ([to_unit_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260904001347_AddUnitConversionTables'
)
BEGIN

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_unit_conversions_category_phase' AND object_id = OBJECT_ID('unit_conversions'))
        CREATE UNIQUE NONCLUSTERED INDEX IX_unit_conversions_category_phase
            ON unit_conversions (category, phase) WHERE deleted_at IS NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260904001347_AddUnitConversionTables'
)
BEGIN

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_setting_unit_conversions_name_phase' AND object_id = OBJECT_ID('setting_unit_conversions'))
        CREATE UNIQUE NONCLUSTERED INDEX IX_setting_unit_conversions_name_phase
            ON setting_unit_conversions (name, phase) WHERE deleted_at IS NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260904001347_AddUnitConversionTables'
)
BEGIN

    INSERT INTO setting_unit_conversions (id, name, phase, factor, is_storage, is_active, created_at, created_by)
    VALUES
        ('7d2f6a10-0001-4a00-8a00-000000000001', 'BBL',   'oil', 1,             1, 1, GETDATE(), '00000000-0000-0000-0000-000000000000'),
        ('7d2f6a10-0001-4a00-8a00-000000000002', 'MBO',   'oil', 1000,          0, 1, GETDATE(), '00000000-0000-0000-0000-000000000000'),
        ('7d2f6a10-0001-4a00-8a00-000000000003', 'MMBO',  'oil', 1000000,       0, 1, GETDATE(), '00000000-0000-0000-0000-000000000000'),
        ('7d2f6a10-0002-4a00-8a00-000000000001', 'MSCF',  'gas', 1,             0, 1, GETDATE(), '00000000-0000-0000-0000-000000000000'),
        ('7d2f6a10-0002-4a00-8a00-000000000002', 'MMSCF', 'gas', 1000,          1, 1, GETDATE(), '00000000-0000-0000-0000-000000000000'),
        ('7d2f6a10-0002-4a00-8a00-000000000003', 'BSCF',  'gas', 1000000,       0, 1, GETDATE(), '00000000-0000-0000-0000-000000000000'),
        ('7d2f6a10-0002-4a00-8a00-000000000004', 'TSCF',  'gas', 1000000000,    0, 1, GETDATE(), '00000000-0000-0000-0000-000000000000');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260904001347_AddUnitConversionTables'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260904001347_AddUnitConversionTables', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260904103010_AddWeatherTypeChartValue'
)
BEGIN
    ALTER TABLE [weather_types] ADD [chart_value] int NOT NULL DEFAULT 0;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260904103010_AddWeatherTypeChartValue'
)
BEGIN
    UPDATE weather_types SET chart_value = 4 WHERE code = 'BRIGHT';
    UPDATE weather_types SET chart_value = 3 WHERE code = 'DRIZZLY';
    UPDATE weather_types SET chart_value = 2 WHERE code = 'RAIN';
    UPDATE weather_types SET chart_value = 1 WHERE code = 'WET';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260904103010_AddWeatherTypeChartValue'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260904103010_AddWeatherTypeChartValue', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260907035810_AddAlertHighlightSnapshots'
)
BEGIN
    CREATE TABLE [alert_highlight_snapshots] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [snapshot_date] date NOT NULL,
        [type] nvarchar(20) NOT NULL,
        [alert_type] nvarchar(50) NOT NULL,
        [alert_key] nvarchar(200) NOT NULL,
        [well_id] uniqueidentifier NULL,
        [well_detail_id] uniqueidentifier NULL,
        [well_name] nvarchar(255) NOT NULL,
        [working_area] nvarchar(20) NOT NULL,
        [deviation] float NULL,
        [percentage] decimal(18,6) NULL,
        [cumprod_type] nvarchar(10) NULL,
        [depletion_date] datetime NULL,
        [action_plan_id] uniqueidentifier NULL,
        [action_plan_type] nvarchar(30) NULL,
        [well_test_action] nvarchar(20) NULL,
        [action_mode] nvarchar(30) NULL,
        [start_date] datetime NULL,
        [created_at] datetime NOT NULL,
        CONSTRAINT [PK_alert_highlight_snapshots] PRIMARY KEY ([id]),
        CONSTRAINT [FK_alert_highlight_snapshots_wells_well_id] FOREIGN KEY ([well_id]) REFERENCES [wells] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260907035810_AddAlertHighlightSnapshots'
)
BEGIN
    CREATE INDEX [IX_alert_highlight_snapshots_date_type] ON [alert_highlight_snapshots] ([snapshot_date], [type]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260907035810_AddAlertHighlightSnapshots'
)
BEGIN
    CREATE INDEX [IX_alert_highlight_snapshots_well_id] ON [alert_highlight_snapshots] ([well_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260907035810_AddAlertHighlightSnapshots'
)
BEGIN
    CREATE UNIQUE INDEX [UX_alert_highlight_snapshots_date_alert_key] ON [alert_highlight_snapshots] ([snapshot_date], [alert_key]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260907035810_AddAlertHighlightSnapshots'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260907035810_AddAlertHighlightSnapshots', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260907044438_SeedEurUnitConversionPicks'
)
BEGIN
    UPDATE c
    SET c.to_unit_id = seeded.id,
        c.updated_at = GETDATE()
    FROM unit_conversions c
    JOIN (VALUES ('gas', 'BSCF'), ('oil', 'MMBO')) AS v(phase, unit_name) ON v.phase = c.phase
    JOIN setting_unit_conversions seeded
      ON seeded.name = v.unit_name AND seeded.phase = v.phase AND seeded.deleted_at IS NULL
    WHERE c.category = 'eur' AND c.deleted_at IS NULL AND c.to_unit_id <> seeded.id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260907044438_SeedEurUnitConversionPicks'
)
BEGIN
    INSERT INTO unit_conversions (id, category, phase, to_unit_id, created_at, created_by)
    SELECT NEWID(), v.category, v.phase, s.id, GETDATE(), '00000000-0000-0000-0000-000000000000'
    FROM (VALUES ('eur', 'gas', 'BSCF'), ('eur', 'oil', 'MMBO')) AS v(category, phase, unit_name)
    JOIN setting_unit_conversions s
      ON s.name = v.unit_name AND s.phase = v.phase AND s.deleted_at IS NULL
    WHERE NOT EXISTS (
        SELECT 1 FROM unit_conversions c
        WHERE c.category = v.category AND c.phase = v.phase AND c.deleted_at IS NULL);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260907044438_SeedEurUnitConversionPicks'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260907044438_SeedEurUnitConversionPicks', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260907110000_OptimizeVwProjectTaskSummary'
)
BEGIN

    IF EXISTS (SELECT 1 FROM sys.indexes
               WHERE object_id = OBJECT_ID('dbo.project_task_schedules')
                 AND name = 'IX_project_task_schedules_task_id_date')
        DROP INDEX IX_project_task_schedules_task_id_date ON dbo.project_task_schedules;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260907110000_OptimizeVwProjectTaskSummary'
)
BEGIN

    CREATE NONCLUSTERED INDEX IX_project_task_schedules_task_id_date
        ON dbo.project_task_schedules (project_task_id, [date])
        INCLUDE (plan_progress, plan_weight, actual_progress, actual_weight);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260907110000_OptimizeVwProjectTaskSummary'
)
BEGIN
    ALTER VIEW [dbo].[vwProjectTaskSummary] AS
    WITH live AS (
        -- Every non-deleted task, with its project's category. NOTE: no filter on
        -- p.deleted_at here, on purpose -- see the header comment.
        SELECT pt.id, pt.project_id, pt.breakdown, pt.[description], pt.[weight],
               pt.data_type, pt.[status], pt.estimated_cost, p.category,
               p.deleted_at AS project_deleted_at,
               (LEN(pt.breakdown) - LEN(REPLACE(pt.breakdown, '.', '')) + 1) AS wbs_level
        FROM project_tasks pt
        JOIN projects p ON p.id = pt.project_id
        WHERE pt.deleted_at IS NULL
    ),
    itd AS (
        -- project_id is in the GROUP BY *and* the join key below, which is what
        -- lets the caller's project filter reach this aggregate.
        SELECT l.project_id, s.project_task_id,
               SUM(s.plan_progress)   AS plan_progress_itd,
               SUM(s.plan_weight)     AS plan_weight_itd,
               SUM(s.actual_progress) AS actual_progress_itd,
               SUM(s.actual_weight)   AS actual_weight_itd
        FROM project_task_schedules s
        JOIN live l ON l.id = s.project_task_id
        WHERE l.data_type = 'item'
          AND l.project_deleted_at IS NULL          -- matches the old `schedules` CTE
          -- ITD cut-off: same as C# (x.Date.Date <= today.Date), kept sargable
          AND s.[date] < DATEADD(day, 1, CAST(GETDATE() AS date))
        GROUP BY l.project_id, s.project_task_id
    ),
    items AS (
        -- Leaf items with their level-1 and level-2 ancestor keys. k1/k2 are NULL
        -- when the item IS at that level, which reproduces the old body's strict
        -- `LIKE breakdown + '.%'` (a node is not its own descendant).
        SELECT l.project_id, l.[weight],
               COALESCE(i.plan_progress_itd,   0) AS plan_progress_itd,
               COALESCE(i.plan_weight_itd,     0) AS plan_weight_itd,
               COALESCE(i.actual_progress_itd, 0) AS actual_progress_itd,
               COALESCE(i.actual_weight_itd,   0) AS actual_weight_itd,
               CASE WHEN CHARINDEX('.', l.breakdown) > 0
                    THEN LEFT(l.breakdown, CHARINDEX('.', l.breakdown) - 1) END AS k1,
               CASE WHEN CHARINDEX('.', l.breakdown, CHARINDEX('.', l.breakdown) + 1) > 0
                    THEN LEFT(l.breakdown,
                              CHARINDEX('.', l.breakdown, CHARINDEX('.', l.breakdown) + 1) - 1) END AS k2
        FROM live l
        LEFT JOIN itd i ON i.project_task_id = l.id AND i.project_id = l.project_id
        WHERE l.data_type = 'item'
    ),
    rollups AS (
        SELECT project_id, k1 AS anc,
               COUNT(*)                                AS child_count,
               SUM([weight])                           AS total_child_weight,
               SUM([weight] * plan_progress_itd)       AS weighted_plan,
               SUM([weight] * actual_progress_itd)     AS weighted_actual,
               SUM(plan_progress_itd)                  AS simple_plan,
               SUM(actual_progress_itd)                AS simple_actual,
               SUM(plan_weight_itd)                    AS plan_weight_sum,
               SUM(actual_weight_itd)                  AS actual_weight_sum
        FROM items WHERE k1 IS NOT NULL GROUP BY project_id, k1
        UNION ALL
        SELECT project_id, k2, COUNT(*), SUM([weight]),
               SUM([weight] * plan_progress_itd), SUM([weight] * actual_progress_itd),
               SUM(plan_progress_itd), SUM(actual_progress_itd),
               SUM(plan_weight_itd), SUM(actual_weight_itd)
        FROM items WHERE k2 IS NOT NULL GROUP BY project_id, k2
    ),
    CalculatedData AS (
        -- Header rollup mirrors ProjectTasksService.ComputeHeaderItd /
        -- ResolveHeaderProgress: weight-weighted average of child progress,
        -- falling back to a plain average when the children carry no weight,
        -- and to 0 when there are no children -- never NULL.
        SELECT l.project_id, l.breakdown AS wbs, l.wbs_level, l.[description], l.[weight],
               l.data_type, l.[status], l.estimated_cost, l.category AS project_category,

               CASE WHEN l.data_type = 'item' THEN COALESCE(i.plan_weight_itd, 0)
                    ELSE COALESCE(r.plan_weight_sum, 0) END            AS plan_weight_itd,

               CASE WHEN l.data_type = 'item' THEN ROUND(COALESCE(i.plan_progress_itd, 0), 2)
                    ELSE ROUND(COALESCE(
                           CASE WHEN r.total_child_weight > 0 THEN r.weighted_plan / r.total_child_weight
                                WHEN r.child_count        > 0 THEN r.simple_plan   / r.child_count
                           END, 0), 2) END                             AS plan_progress_itd,

               CASE WHEN l.data_type = 'item' THEN COALESCE(i.actual_weight_itd, 0)
                    ELSE COALESCE(r.actual_weight_sum, 0) END          AS actual_weight_itd,

               CASE WHEN l.data_type = 'item' THEN ROUND(COALESCE(i.actual_progress_itd, 0), 2)
                    ELSE ROUND(COALESCE(
                           CASE WHEN r.total_child_weight > 0 THEN r.weighted_actual / r.total_child_weight
                                WHEN r.child_count        > 0 THEN r.simple_actual   / r.child_count
                           END, 0), 2) END                             AS actual_progress_itd
        FROM live l
        LEFT JOIN itd     i ON i.project_task_id = l.id          AND i.project_id = l.project_id
        -- The '#' sentinel makes the comparison trailing-space SENSITIVE, matching the
        -- old body's `LIKE breakdown + '.%'` (and C# ComputeHeaderItd's StartsWith).
        -- Without it, ANSI padding would silently give a differing answer for headers
        -- whose breakdown has a trailing space -- see the note at the top of this file.
        LEFT JOIN rollups r ON r.anc + '#'       = l.breakdown + '#' AND r.project_id = l.project_id
        WHERE l.wbs_level IN (1, 2)
    )
    SELECT *,
           ROUND(actual_progress_itd - plan_progress_itd, 2) AS variance
    FROM CalculatedData;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260907110000_OptimizeVwProjectTaskSummary'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260907110000_OptimizeVwProjectTaskSummary', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260908013741_AddSpkIdToProjectTaskBoqDrafts'
)
BEGIN
    ALTER TABLE [project_task_boq_drafts] ADD [spk_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260908013741_AddSpkIdToProjectTaskBoqDrafts'
)
BEGIN
    UPDATE project_task_boq_drafts
    SET    spk_id = TRY_CAST(JSON_VALUE(payload, '$.spk_id') AS uniqueidentifier)
    WHERE  spk_id IS NULL
      AND  ISJSON(payload) = 1
      AND  NULLIF(JSON_VALUE(payload, '$.spk_id'), '') IS NOT NULL
      AND  TRY_CAST(JSON_VALUE(payload, '$.spk_id') AS uniqueidentifier) IS NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260908013741_AddSpkIdToProjectTaskBoqDrafts'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260908013741_AddSpkIdToProjectTaskBoqDrafts', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260908073005_SeedWaterGrossTemperatureUnits'
)
BEGIN
    INSERT INTO setting_unit_conversions (id, name, phase, factor, is_storage, is_active, created_at, created_by)
    SELECT v.id, v.name, v.phase, v.factor, v.is_storage, 1, GETDATE(), '00000000-0000-0000-0000-000000000000'
    FROM (VALUES
        ('7d2f6a10-0003-4a00-8a00-000000000001', 'BBL',  'water', 1e0, 1),
        ('7d2f6a10-0003-4a00-8a00-000000000002', 'MBW',  'water', 1e3, 0),
        ('7d2f6a10-0003-4a00-8a00-000000000003', 'MMBW', 'water', 1e6, 0),
        ('7d2f6a10-0004-4a00-8a00-000000000001', 'BBL',  'gross', 1e0, 1),
        ('7d2f6a10-0004-4a00-8a00-000000000002', 'MBL',  'gross', 1e3, 0),
        ('7d2f6a10-0004-4a00-8a00-000000000003', 'MMBL', 'gross', 1e6, 0),
        ('7d2f6a10-0005-4a00-8a00-000000000001', 'F',    'temperature', 1e0, 1)
    ) AS v(id, name, phase, factor, is_storage)
    WHERE NOT EXISTS (
        SELECT 1 FROM setting_unit_conversions s
        WHERE s.name = v.name AND s.phase = v.phase AND s.deleted_at IS NULL);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260908073005_SeedWaterGrossTemperatureUnits'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260908073005_SeedWaterGrossTemperatureUnits', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909091832_AddCriticalPathEtcToProjectTasks'
)
BEGIN
    ALTER TABLE [project_tasks] ADD [critical_path_etc] nvarchar(max) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260909091832_AddCriticalPathEtcToProjectTasks'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260909091832_AddCriticalPathEtcToProjectTasks', N'9.0.0');
END;

COMMIT;
GO
GO


-- Verify, then:  COMMIT TRANSACTION;   (or ROLLBACK TRANSACTION;)
