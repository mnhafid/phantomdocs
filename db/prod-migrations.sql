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
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225060939_InitPhantomDb'
)
BEGIN
    CREATE TABLE [users] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [full_name] nvarchar(255) NULL,
        [email] nvarchar(255) NULL,
        [password_hash] nvarchar(max) NULL,
        [role_id] int NULL,
        [status] nvarchar(50) NULL,
        [zone] nvarchar(50) NULL,
        [working_area] nvarchar(50) NULL,
        [created_at] datetime2 NOT NULL,
        [updated_at] datetime2 NULL,
        [deleted_at] datetime2 NULL,
        [created_by] uniqueidentifier NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_users] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225060939_InitPhantomDb'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260225060939_InitPhantomDb', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225060950_AddBanks'
)
BEGIN
    CREATE TABLE [banks] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [code] nvarchar(100) NULL,
        [name] nvarchar(255) NULL,
        [is_active] int NOT NULL,
        [tenant_id] uniqueidentifier NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_banks] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225060950_AddBanks'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260225060950_AddBanks', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225061000_AddContractors'
)
BEGIN
    CREATE TABLE [contractors] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [code] nvarchar(50) NULL,
        [name] nvarchar(255) NULL,
        [address] nvarchar(max) NULL,
        [telephone] nvarchar(50) NULL,
        [fax] nvarchar(50) NULL,
        [email] nvarchar(255) NULL,
        [category_industry] nvarchar(100) NULL,
        [enterprise_sizing] nvarchar(100) NULL,
        [is_active] int NOT NULL,
        [tenant_id] uniqueidentifier NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_contractors] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225061000_AddContractors'
)
BEGIN
    CREATE INDEX [IX_contractors_tenant_id] ON [contractors] ([tenant_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225061000_AddContractors'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260225061000_AddContractors', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225062000_AddFields'
)
BEGIN
    CREATE TABLE [fields] (
        [field_id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [name] nvarchar(100) NOT NULL,
        [working_area] nvarchar(10) NOT NULL,
        [is_active] int NOT NULL DEFAULT 1,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NOT NULL,
        [updated_by] uniqueidentifier NOT NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_fields] PRIMARY KEY ([field_id]),
        CONSTRAINT [FK_fields_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_fields_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225062000_AddFields'
)
BEGIN
    CREATE INDEX [IX_fields_created_by] ON [fields] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225062000_AddFields'
)
BEGIN
    CREATE INDEX [IX_fields_is_active] ON [fields] ([is_active]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225062000_AddFields'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [IX_fields_name] ON [fields] ([name]) WHERE [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225062000_AddFields'
)
BEGIN
    CREATE INDEX [IX_fields_updated_by] ON [fields] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225062000_AddFields'
)
BEGIN
    CREATE INDEX [IX_fields_working_area] ON [fields] ([working_area]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225062000_AddFields'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260225062000_AddFields', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225063000_AddContracts'
)
BEGIN
    CREATE TABLE [contracts] (
        [contract_id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [contractor_id] uniqueidentifier NOT NULL,
        [contract_no] nvarchar(100) NULL,
        [contract_title] nvarchar(255) NULL,
        [start_date] date NOT NULL,
        [work_end_date] date NOT NULL,
        [contract_end_date] date NOT NULL,
        [contract_value] float NOT NULL,
        [spk_count] int NOT NULL,
        [spk_value] float NOT NULL,
        [physical_progress_value] float NOT NULL,
        [sa_value] float NOT NULL,
        [invoice_value] float NOT NULL,
        [status] text NULL,
        [remark] text NULL,
        [submitted_at] datetime NULL,
        [submitted_by] uniqueidentifier NULL,
        [canceled_at] datetime NULL,
        [canceled_by] uniqueidentifier NULL,
        [cancelation_note] text NULL,
        [finished_at] datetime NULL,
        [finished_by] uniqueidentifier NULL,
        [finished_note] text NULL,
        [bank_id] uniqueidentifier NULL,
        [bank_branch] varchar(320) NULL,
        [bank_key] varchar(17) NULL,
        [init_spk_seq_number] int NULL,
        [bank_account_name] nvarchar(250) NULL,
        [contract_types] varchar(255) NULL,
        [autogenerated_spk_number] bit NULL,
        [retention_percentage] numeric(5,2) NULL,
        [tenant_id] uniqueidentifier NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_contracts] PRIMARY KEY ([contract_id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225063000_AddContracts'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260225063000_AddContracts', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225064000_AddProjects'
)
BEGIN
    CREATE TABLE [projects] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [field_id] uniqueidentifier NULL,
        [zone] nvarchar(100) NULL,
        [project_no] nvarchar(255) NULL,
        [rk_baseline] nvarchar(100) NULL,
        [wbs] nvarchar(255) NULL,
        [description] nvarchar(255) NULL,
        [category] nvarchar(max) NULL,
        [start_date] date NULL,
        [end_date] date NULL,
        [budget_forecast] float NULL,
        [status] nvarchar(max) NULL,
        [ts] nvarchar(max) NULL,
        [submitted_at] datetime NULL,
        [submitted_by] uniqueidentifier NULL,
        [canceled_at] datetime NULL,
        [canceled_by] uniqueidentifier NULL,
        [cancelation_note] nvarchar(max) NULL,
        [finished_at] datetime NULL,
        [finished_by] uniqueidentifier NULL,
        [finished_note] nvarchar(max) NULL,
        [tenant_id] uniqueidentifier NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_projects] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225064000_AddProjects'
)
BEGIN
    CREATE INDEX [IX_projects_project_no] ON [projects] ([project_no]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225064000_AddProjects'
)
BEGIN
    CREATE INDEX [IX_projects_tenant_id] ON [projects] ([tenant_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225064000_AddProjects'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260225064000_AddProjects', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225065000_AddRkaps'
)
BEGIN
    CREATE TABLE [rkaps] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [code] nvarchar(16) NULL,
        [name] nvarchar(200) NULL,
        [description] nvarchar(255) NULL,
        [start_date] date NOT NULL,
        [end_date] date NOT NULL,
        [is_active] int NOT NULL,
        [tenant_id] uniqueidentifier NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_rkaps] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225065000_AddRkaps'
)
BEGIN
    CREATE INDEX [IX_rkaps_code] ON [rkaps] ([code]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225065000_AddRkaps'
)
BEGIN
    CREATE INDEX [IX_rkaps_tenant_id] ON [rkaps] ([tenant_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225065000_AddRkaps'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260225065000_AddRkaps', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225066000_AddProjectTasks'
)
BEGIN
    CREATE TABLE [project_tasks] (
        [id] uniqueidentifier NOT NULL,
        [project_id] uniqueidentifier NOT NULL,
        [breakdown] nvarchar(200) NULL,
        [description] text NULL,
        [remarks] text NULL,
        [weight] float NOT NULL,
        [start_date] date NOT NULL,
        [end_date] date NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        [data_type] varchar(20) NULL,
        [status] varchar(30) NULL,
        [ts] nvarchar(1) NULL,
        [assignee] uniqueidentifier NULL,
        [contract_id] uniqueidentifier NULL,
        [unique_id] int NOT NULL,
        [parent_unique_id] int NULL,
        [estimated_cost] float NULL,
        [spk_id] uniqueidentifier NULL,
        [spk_cost] float NULL,
        [predecessor] nvarchar(max) NULL,
        [successor] nvarchar(max) NULL,
        [etc] date NULL,
        [start_etc] date NULL,
        [milestone] int NOT NULL,
        [duration] int NOT NULL,
        [critical_path] nvarchar(max) NULL,
        [project_calendar] nvarchar(max) NULL,
        [constraint_date] varchar(100) NULL,
        [constraint_type] varchar(100) NULL,
        [is_critical_path] bit NOT NULL,
        [tenant_id] uniqueidentifier NULL,
        CONSTRAINT [PK_project_tasks] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225066000_AddProjectTasks'
)
BEGIN
    CREATE INDEX [IX_project_tasks_tenant_id] ON [project_tasks] ([tenant_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225066000_AddProjectTasks'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260225066000_AddProjectTasks', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225067000_AddProjectTaskSchedules'
)
BEGIN
    CREATE TABLE [project_task_schedules] (
        [id] uniqueidentifier NOT NULL,
        [project_task_id] uniqueidentifier NOT NULL,
        [date] date NOT NULL,
        [plan_weight] float NOT NULL,
        [plan_weight_accumulation] float NOT NULL,
        [plan_volume] float NOT NULL,
        [plan_volume_accumulation] float NOT NULL,
        [plan_progress] float NOT NULL,
        [plan_progress_accumulation] float NOT NULL,
        [plan_cost] float NOT NULL,
        [actual_progress] float NOT NULL,
        [actual_progress_accumulation] float NOT NULL,
        [plan_cost_accumulation] float NOT NULL,
        [actual_cost] float NOT NULL,
        [actual_cost_accumulation] float NOT NULL,
        [actual_weight] float NOT NULL,
        CONSTRAINT [PK_project_task_schedules] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260225067000_AddProjectTaskSchedules'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260225067000_AddProjectTaskSchedules', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260226003032_AddCustomConfigurations'
)
BEGIN
    CREATE TABLE [custom_configurations] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [name] nvarchar(255) NULL,
        [description] nvarchar(500) NULL,
        [detail] nvarchar(max) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NOT NULL,
        [updated_by] uniqueidentifier NOT NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_custom_configurations] PRIMARY KEY ([id]),
        CONSTRAINT [FK_custom_configurations_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_custom_configurations_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260226003032_AddCustomConfigurations'
)
BEGIN
    CREATE INDEX [IX_custom_configurations_created_by] ON [custom_configurations] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260226003032_AddCustomConfigurations'
)
BEGIN
    CREATE INDEX [IX_custom_configurations_name] ON [custom_configurations] ([name]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260226003032_AddCustomConfigurations'
)
BEGIN
    CREATE INDEX [IX_custom_configurations_updated_by] ON [custom_configurations] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260226003032_AddCustomConfigurations'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260226003032_AddCustomConfigurations', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260226094018_AddApprovalRoutes'
)
BEGIN
    CREATE TABLE [approval_routes] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [title] nvarchar(100) NULL,
        [description] nvarchar(255) NULL,
        [category] nvarchar(20) NULL,
        [status] text NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_approval_routes] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260226094018_AddApprovalRoutes'
)
BEGIN
    CREATE TABLE [approval_route_users] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [approval_route_id] uniqueidentifier NOT NULL,
        [user_id] uniqueidentifier NOT NULL,
        [level] bigint NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_approval_route_users] PRIMARY KEY ([id]),
        CONSTRAINT [FK_approval_route_users_approval_routes_approval_route_id] FOREIGN KEY ([approval_route_id]) REFERENCES [approval_routes] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260226094018_AddApprovalRoutes'
)
BEGIN
    CREATE INDEX [IX_approval_route_users_approval_route_id] ON [approval_route_users] ([approval_route_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260226094018_AddApprovalRoutes'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260226094018_AddApprovalRoutes', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260226120000_ChangeApprovalRouteStatusToIsActive'
)
BEGIN
    DECLARE @var0 sysname;
    SELECT @var0 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[approval_routes]') AND [c].[name] = N'status');
    IF @var0 IS NOT NULL EXEC(N'ALTER TABLE [approval_routes] DROP CONSTRAINT [' + @var0 + '];');
    ALTER TABLE [approval_routes] DROP COLUMN [status];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260226120000_ChangeApprovalRouteStatusToIsActive'
)
BEGIN
    ALTER TABLE [approval_routes] ADD [is_active] bit NOT NULL DEFAULT CAST(1 AS bit);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260226120000_ChangeApprovalRouteStatusToIsActive'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260226120000_ChangeApprovalRouteStatusToIsActive', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260226123855_AlterContractorsIsActiveToBool'
)
BEGIN
    DECLARE @var1 sysname;
    SELECT @var1 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[contractors]') AND [c].[name] = N'is_active');
    IF @var1 IS NOT NULL EXEC(N'ALTER TABLE [contractors] DROP CONSTRAINT [' + @var1 + '];');
    ALTER TABLE [contractors] ALTER COLUMN [is_active] bit NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260226123855_AlterContractorsIsActiveToBool'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260226123855_AlterContractorsIsActiveToBool', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260227105753_AddTenantIdToApprovalRoutes'
)
BEGIN
    ALTER TABLE [approval_routes] ADD [tenant_id] uniqueidentifier NOT NULL DEFAULT (('00000000-0000-0000-0000-000000000000'));
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260227105753_AddTenantIdToApprovalRoutes'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260227105753_AddTenantIdToApprovalRoutes', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260228000000_AddInvoices'
)
BEGIN
    CREATE TABLE [invoices] (
        [id] uniqueidentifier NOT NULL,
        [invoice_no] nvarchar(100) NULL,
        [invoice_date] date NULL,
        [invoice_from] nvarchar(200) NULL,
        [invoice_to] nvarchar(200) NULL,
        [receipt] nvarchar(100) NULL,
        [tax_invoice] nvarchar(100) NULL,
        [bast_no] nvarchar(100) NULL,
        [description] nvarchar(500) NULL,
        [currency] text NOT NULL,
        [sa_amount] numeric NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        [retention_amount] numeric NULL,
        [tenant_id] uniqueidentifier NULL,
        CONSTRAINT [PK_invoices] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260228000000_AddInvoices'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260228000000_AddInvoices', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260228010000_AddBoqs'
)
BEGIN
    CREATE TABLE [boq_categories] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [name] nvarchar(50) NOT NULL,
        [description] nvarchar(255) NULL,
        [created_at] datetime NOT NULL,
        [updated_at] datetime NULL,
        [deleted_at] datetime NULL,
        CONSTRAINT [PK_boq_categories] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260228010000_AddBoqs'
)
BEGIN
    CREATE TABLE [boq_file_templates] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [name] nvarchar(10) NOT NULL,
        [file_url] nvarchar(255) NOT NULL,
        [created_at] datetime NOT NULL,
        [updated_at] datetime NULL,
        [deleted_at] datetime NULL,
        CONSTRAINT [PK_boq_file_templates] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260228010000_AddBoqs'
)
BEGIN
    CREATE TABLE [boq_category_template_types] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [boq_category_id] uniqueidentifier NOT NULL,
        [boq_file_template_id] uniqueidentifier NOT NULL,
        [created_at] datetime NOT NULL,
        [updated_at] datetime NULL,
        [deleted_at] datetime NULL,
        CONSTRAINT [PK_boq_category_template_types] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260228010000_AddBoqs'
)
BEGIN
    CREATE TABLE [boqs] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [contract_id] uniqueidentifier NOT NULL,
        [boq_category_id] uniqueidentifier NULL,
        [original_file] nvarchar(100) NOT NULL,
        [is_active] int NOT NULL DEFAULT 1,
        [version] int NOT NULL DEFAULT 1,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_boqs] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260228010000_AddBoqs'
)
BEGIN
    CREATE TABLE [boq_details] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [boq_id] uniqueidentifier NOT NULL,
        [boq_library_id] uniqueidentifier NULL,
        [origin_number] int NOT NULL,
        [code] nvarchar(50) NOT NULL,
        [description] nvarchar(max) NOT NULL,
        [kind] nvarchar(20) NULL,
        [quantity] bigint NULL,
        [unit_id] uniqueidentifier NULL,
        [total] float NULL DEFAULT 0.0E0,
        [remark] nvarchar(max) NULL,
        [data_type] nvarchar(20) NOT NULL DEFAULT N'header',
        [order] int NOT NULL,
        CONSTRAINT [PK_boq_details] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260228010000_AddBoqs'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260228010000_AddBoqs', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304000000_AddApprovalLogs'
)
BEGIN
    CREATE TABLE [approval_processes] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [reference_id] uniqueidentifier NOT NULL,
        [approval_flow] nvarchar(30) NOT NULL,
        [latest_approval_level] int NOT NULL,
        [status] nvarchar(20) NOT NULL DEFAULT N'active',
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        CONSTRAINT [PK_approval_processes] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304000000_AddApprovalLogs'
)
BEGIN
    CREATE TABLE [approval_logs] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [approval_process_id] uniqueidentifier NOT NULL,
        [status] nvarchar(20) NOT NULL DEFAULT N'initiate',
        [reference_status] nvarchar(20) NULL DEFAULT N'draft',
        [approval_level] int NOT NULL,
        [remarks] nvarchar(max) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        CONSTRAINT [PK_approval_logs] PRIMARY KEY ([id]),
        CONSTRAINT [FK_approval_logs_approval_processes_approval_process_id] FOREIGN KEY ([approval_process_id]) REFERENCES [approval_processes] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304000000_AddApprovalLogs'
)
BEGIN
    CREATE INDEX [IX_approval_logs_approval_process_id] ON [approval_logs] ([approval_process_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304000000_AddApprovalLogs'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260304000000_AddApprovalLogs', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304135645_AddContractorUsersAndFixSchema'
)
BEGIN
    DECLARE @var2 sysname;
    SELECT @var2 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[invoices]') AND [c].[name] = N'tenant_id');
    IF @var2 IS NOT NULL EXEC(N'ALTER TABLE [invoices] DROP CONSTRAINT [' + @var2 + '];');
    EXEC(N'UPDATE [invoices] SET [tenant_id] = ''00000000-0000-0000-0000-000000000000'' WHERE [tenant_id] IS NULL');
    ALTER TABLE [invoices] ALTER COLUMN [tenant_id] uniqueidentifier NOT NULL;
    ALTER TABLE [invoices] ADD DEFAULT '00000000-0000-0000-0000-000000000000' FOR [tenant_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304135645_AddContractorUsersAndFixSchema'
)
BEGIN
    DECLARE @var3 sysname;
    SELECT @var3 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[invoices]') AND [c].[name] = N'sa_amount');
    IF @var3 IS NOT NULL EXEC(N'ALTER TABLE [invoices] DROP CONSTRAINT [' + @var3 + '];');
    EXEC(N'UPDATE [invoices] SET [sa_amount] = 0.0 WHERE [sa_amount] IS NULL');
    ALTER TABLE [invoices] ALTER COLUMN [sa_amount] numeric(18,0) NOT NULL;
    ALTER TABLE [invoices] ADD DEFAULT 0.0 FOR [sa_amount];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304135645_AddContractorUsersAndFixSchema'
)
BEGIN
    DECLARE @var4 sysname;
    SELECT @var4 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[invoices]') AND [c].[name] = N'retention_amount');
    IF @var4 IS NOT NULL EXEC(N'ALTER TABLE [invoices] DROP CONSTRAINT [' + @var4 + '];');
    EXEC(N'UPDATE [invoices] SET [retention_amount] = 0.0 WHERE [retention_amount] IS NULL');
    ALTER TABLE [invoices] ALTER COLUMN [retention_amount] numeric(18,0) NOT NULL;
    ALTER TABLE [invoices] ADD DEFAULT 0.0 FOR [retention_amount];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304135645_AddContractorUsersAndFixSchema'
)
BEGIN
    DECLARE @var5 sysname;
    SELECT @var5 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[boqs]') AND [c].[name] = N'original_file');
    IF @var5 IS NOT NULL EXEC(N'ALTER TABLE [boqs] DROP CONSTRAINT [' + @var5 + '];');
    ALTER TABLE [boqs] ALTER COLUMN [original_file] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304135645_AddContractorUsersAndFixSchema'
)
BEGIN
    DECLARE @var6 sysname;
    SELECT @var6 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[boq_file_templates]') AND [c].[name] = N'name');
    IF @var6 IS NOT NULL EXEC(N'ALTER TABLE [boq_file_templates] DROP CONSTRAINT [' + @var6 + '];');
    ALTER TABLE [boq_file_templates] ALTER COLUMN [name] nvarchar(10) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304135645_AddContractorUsersAndFixSchema'
)
BEGIN
    DECLARE @var7 sysname;
    SELECT @var7 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[boq_file_templates]') AND [c].[name] = N'file_url');
    IF @var7 IS NOT NULL EXEC(N'ALTER TABLE [boq_file_templates] DROP CONSTRAINT [' + @var7 + '];');
    ALTER TABLE [boq_file_templates] ALTER COLUMN [file_url] nvarchar(255) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304135645_AddContractorUsersAndFixSchema'
)
BEGIN
    DECLARE @var8 sysname;
    SELECT @var8 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[boq_details]') AND [c].[name] = N'description');
    IF @var8 IS NOT NULL EXEC(N'ALTER TABLE [boq_details] DROP CONSTRAINT [' + @var8 + '];');
    ALTER TABLE [boq_details] ALTER COLUMN [description] nvarchar(max) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304135645_AddContractorUsersAndFixSchema'
)
BEGIN
    DECLARE @var9 sysname;
    SELECT @var9 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[boq_details]') AND [c].[name] = N'data_type');
    IF @var9 IS NOT NULL EXEC(N'ALTER TABLE [boq_details] DROP CONSTRAINT [' + @var9 + '];');
    ALTER TABLE [boq_details] ALTER COLUMN [data_type] nvarchar(20) NULL;
    ALTER TABLE [boq_details] ADD DEFAULT N'header' FOR [data_type];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304135645_AddContractorUsersAndFixSchema'
)
BEGIN
    DECLARE @var10 sysname;
    SELECT @var10 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[boq_details]') AND [c].[name] = N'code');
    IF @var10 IS NOT NULL EXEC(N'ALTER TABLE [boq_details] DROP CONSTRAINT [' + @var10 + '];');
    ALTER TABLE [boq_details] ALTER COLUMN [code] nvarchar(50) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304135645_AddContractorUsersAndFixSchema'
)
BEGIN
    DECLARE @var11 sysname;
    SELECT @var11 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[boq_categories]') AND [c].[name] = N'name');
    IF @var11 IS NOT NULL EXEC(N'ALTER TABLE [boq_categories] DROP CONSTRAINT [' + @var11 + '];');
    ALTER TABLE [boq_categories] ALTER COLUMN [name] nvarchar(50) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304135645_AddContractorUsersAndFixSchema'
)
BEGIN
    CREATE TABLE [contractor_users] (
        [id] bigint NOT NULL IDENTITY,
        [contractor_id] uniqueidentifier NOT NULL,
        [user_id] uniqueidentifier NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_contractor_users] PRIMARY KEY ([id]),
        CONSTRAINT [FK_contractor_users_users_user_id] FOREIGN KEY ([user_id]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304135645_AddContractorUsersAndFixSchema'
)
BEGIN
    CREATE INDEX [IX_contractor_users_user_id] ON [contractor_users] ([user_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304135645_AddContractorUsersAndFixSchema'
)
BEGIN

                    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_users_users_created_by')
                        ALTER TABLE [users] DROP CONSTRAINT [FK_users_users_created_by];
                    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_users_users_updated_by')
                        ALTER TABLE [users] DROP CONSTRAINT [FK_users_users_updated_by];
                    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_users_users_deleted_by')
                        ALTER TABLE [users] DROP CONSTRAINT [FK_users_users_deleted_by];
                    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_User_Created_By')
                        ALTER TABLE [users] DROP CONSTRAINT [FK_User_Created_By];
                    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_User_Updated_By')
                        ALTER TABLE [users] DROP CONSTRAINT [FK_User_Updated_By];
                    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_User_Deleted_By')
                        ALTER TABLE [users] DROP CONSTRAINT [FK_User_Deleted_By];
                
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304135645_AddContractorUsersAndFixSchema'
)
BEGIN

                    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_contractor_users_users_created_by')
                        ALTER TABLE [contractor_users] DROP CONSTRAINT [FK_contractor_users_users_created_by];
                    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_contractor_users_users_updated_by')
                        ALTER TABLE [contractor_users] DROP CONSTRAINT [FK_contractor_users_users_updated_by];
                    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_contractor_users_users_deleted_by')
                        ALTER TABLE [contractor_users] DROP CONSTRAINT [FK_contractor_users_users_deleted_by];
                
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304135645_AddContractorUsersAndFixSchema'
)
BEGIN

                    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_users_created_by' AND object_id = OBJECT_ID('dbo.users') AND is_unique = 1)
                        DROP INDEX [IX_users_created_by] ON [users];
                    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_users_updated_by' AND object_id = OBJECT_ID('dbo.users') AND is_unique = 1)
                        DROP INDEX [IX_users_updated_by] ON [users];
                    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_users_deleted_by' AND object_id = OBJECT_ID('dbo.users') AND is_unique = 1)
                        DROP INDEX [IX_users_deleted_by] ON [users];
                
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260304135645_AddContractorUsersAndFixSchema'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260304135645_AddContractorUsersAndFixSchema', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260305091505_AddProjectSpendingPlans'
)
BEGIN
    CREATE TABLE [project_spending_plans] (
        [id] uniqueidentifier NOT NULL,
        [project_id] uniqueidentifier NOT NULL,
        [rkap_id] uniqueidentifier NOT NULL,
        [date] date NOT NULL,
        [plan_cost] float NOT NULL DEFAULT 0.0E0,
        [actual_cost] float NOT NULL DEFAULT 0.0E0,
        [remarks] text NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        [tenant_id] uniqueidentifier NULL,
        CONSTRAINT [PK_project_spending_plans] PRIMARY KEY ([id]),
        CONSTRAINT [FK_project_spending_plans_projects_project_id] FOREIGN KEY ([project_id]) REFERENCES [projects] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_project_spending_plans_rkaps_rkap_id] FOREIGN KEY ([rkap_id]) REFERENCES [rkaps] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260305091505_AddProjectSpendingPlans'
)
BEGIN
    CREATE TABLE [rkap_projects] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [project_id] uniqueidentifier NOT NULL,
        [rkap_id] uniqueidentifier NOT NULL,
        [rkap_cost] float NOT NULL DEFAULT 0.0E0,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_rkap_projects] PRIMARY KEY ([id]),
        CONSTRAINT [FK_rkap_projects_projects_project_id] FOREIGN KEY ([project_id]) REFERENCES [projects] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_rkap_projects_rkaps_rkap_id] FOREIGN KEY ([rkap_id]) REFERENCES [rkaps] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260305091505_AddProjectSpendingPlans'
)
BEGIN
    CREATE INDEX [IX_contracts_bank_id] ON [contracts] ([bank_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260305091505_AddProjectSpendingPlans'
)
BEGIN
    CREATE INDEX [IX_contracts_contractor_id] ON [contracts] ([contractor_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260305091505_AddProjectSpendingPlans'
)
BEGIN
    CREATE INDEX [IX_project_spending_plans_project_id] ON [project_spending_plans] ([project_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260305091505_AddProjectSpendingPlans'
)
BEGIN
    CREATE INDEX [IX_project_spending_plans_rkap_id] ON [project_spending_plans] ([rkap_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260305091505_AddProjectSpendingPlans'
)
BEGIN
    CREATE INDEX [IX_project_spending_plans_tenant_id] ON [project_spending_plans] ([tenant_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260305091505_AddProjectSpendingPlans'
)
BEGIN
    CREATE INDEX [IX_rkap_projects_project_id] ON [rkap_projects] ([project_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260305091505_AddProjectSpendingPlans'
)
BEGIN
    CREATE INDEX [IX_rkap_projects_rkap_id] ON [rkap_projects] ([rkap_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260305091505_AddProjectSpendingPlans'
)
BEGIN
    ALTER TABLE [contracts] ADD CONSTRAINT [FK_contracts_banks_bank_id] FOREIGN KEY ([bank_id]) REFERENCES [banks] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260305091505_AddProjectSpendingPlans'
)
BEGIN
    ALTER TABLE [contracts] ADD CONSTRAINT [FK_contracts_contractors_contractor_id] FOREIGN KEY ([contractor_id]) REFERENCES [contractors] ([id]) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260305091505_AddProjectSpendingPlans'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260305091505_AddProjectSpendingPlans', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260306005855_AddTenderProcessCategoryTable'
)
BEGIN
    CREATE TABLE [tender_process_categories] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [description] nvarchar(100) NULL,
        [order] bigint NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        [tenant_id] uniqueidentifier NULL,
        CONSTRAINT [PK_tender_process_categories] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260306005855_AddTenderProcessCategoryTable'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260306005855_AddTenderProcessCategoryTable', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260306095007_AddTenderProcessTable'
)
BEGIN
    CREATE TABLE [tender_processes] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [tender_process_category_id] uniqueidentifier NOT NULL,
        [description] nvarchar(100) NULL,
        [duration] bigint NOT NULL,
        [order] bigint NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        [tenant_id] uniqueidentifier NULL,
        CONSTRAINT [PK_tender_processes] PRIMARY KEY ([id]),
        CONSTRAINT [FK_tender_processes_tender_process_categories] FOREIGN KEY ([tender_process_category_id]) REFERENCES [tender_process_categories] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260306095007_AddTenderProcessTable'
)
BEGIN
    CREATE INDEX [IX_tender_processes_tender_process_category_id] ON [tender_processes] ([tender_process_category_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260306095007_AddTenderProcessTable'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260306095007_AddTenderProcessTable', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260306101506_RemoveDeletedFieldsFromSpendingPlan'
)
BEGIN
    DECLARE @var12 sysname;
    SELECT @var12 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[project_spending_plans]') AND [c].[name] = N'deleted_at');
    IF @var12 IS NOT NULL EXEC(N'ALTER TABLE [project_spending_plans] DROP CONSTRAINT [' + @var12 + '];');
    ALTER TABLE [project_spending_plans] DROP COLUMN [deleted_at];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260306101506_RemoveDeletedFieldsFromSpendingPlan'
)
BEGIN
    DECLARE @var13 sysname;
    SELECT @var13 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[project_spending_plans]') AND [c].[name] = N'deleted_by');
    IF @var13 IS NOT NULL EXEC(N'ALTER TABLE [project_spending_plans] DROP CONSTRAINT [' + @var13 + '];');
    ALTER TABLE [project_spending_plans] DROP COLUMN [deleted_by];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260306101506_RemoveDeletedFieldsFromSpendingPlan'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260306101506_RemoveDeletedFieldsFromSpendingPlan', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260310044831_AddSpks'
)
BEGIN
    CREATE TABLE [spks] (
        [spk_id] uniqueidentifier NOT NULL,
        [contract_id] uniqueidentifier NOT NULL,
        [spk_no] nvarchar(100) NOT NULL,
        [spk_title] nvarchar(255) NOT NULL,
        [start_date] date NOT NULL,
        [end_date] date NOT NULL,
        [spk_value] float NOT NULL,
        [final_spk_value] float NOT NULL,
        [physical_progress_value] float NOT NULL,
        [remark] nvarchar(255) NULL,
        [status] nvarchar(50) NOT NULL,
        [version] bigint NOT NULL,
        [pekerjaan] nvarchar(max) NULL,
        [masa_pemeliharaan] nvarchar(max) NULL,
        [cost_element] nvarchar(max) NULL,
        [is_various] bigint NOT NULL,
        [sum_released_spk_value] float NOT NULL,
        [remaining_contract_value] float NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        [tenant_id] uniqueidentifier NULL,
        [canceled_at] datetime NULL,
        [canceled_by] uniqueidentifier NULL,
        [cancelation_note] nvarchar(max) NULL,
        [finished_at] datetime NULL,
        [finished_by] uniqueidentifier NULL,
        [finished_note] nvarchar(max) NULL,
        [submitted_at] datetime NULL,
        [submitted_by] uniqueidentifier NULL,
        [approved_at] datetime NULL,
        [approved_by] uniqueidentifier NULL,
        [released_at] datetime NULL,
        [released_by] uniqueidentifier NULL,
        [last_bast_date] datetime NULL,
        CONSTRAINT [PK_spks] PRIMARY KEY ([spk_id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260310044831_AddSpks'
)
BEGIN
    CREATE INDEX [IX_spks_tenant_id] ON [spks] ([tenant_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260310044831_AddSpks'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260310044831_AddSpks', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260311235402_AddMaterialMonitoring'
)
BEGIN
    CREATE TABLE [material_monitorings] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [file_name] nvarchar(150) NULL,
        [file_url] nvarchar(255) NULL,
        [status] nvarchar(50) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        CONSTRAINT [PK_material_monitorings] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260311235402_AddMaterialMonitoring'
)
BEGIN
    CREATE TABLE [material_monitoring_details] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [material_monitoring_id] uniqueidentifier NOT NULL,
        [number] int NOT NULL,
        [rev] nvarchar(20) NULL,
        [project] nvarchar(150) NULL,
        [comodities] nvarchar(50) NULL,
        [kimap] nvarchar(20) NULL,
        [description] nvarchar(max) NULL,
        [bom_received] numeric(5,2) NOT NULL,
        [sourcing_or_reservation] numeric(5,2) NOT NULL,
        [spk_or_contract] numeric(5,2) NOT NULL,
        [po_or_ro] numeric(5,2) NOT NULL,
        [material_onsite] numeric(5,2) NOT NULL,
        [target_ready_on_site] date NULL,
        [target_po_date] date NULL,
        [eta] date NULL,
        [size] nvarchar(20) NULL,
        [bom_qty] numeric(9,5) NOT NULL,
        [unit] nvarchar(20) NULL,
        [procurement_status] nvarchar(50) NULL,
        [reservation_number] nvarchar(50) NULL,
        [reservation_qty] numeric(9,5) NOT NULL,
        [spk_qty] numeric(9,5) NOT NULL,
        [spk_number] nvarchar(50) NULL,
        [po_number] nvarchar(50) NULL,
        [po_qty] numeric(9,5) NOT NULL,
        [deviation] int NOT NULL,
        [note] nvarchar(max) NULL,
        CONSTRAINT [PK_material_monitoring_details] PRIMARY KEY ([id]),
        CONSTRAINT [FK_material_monitoring_details_material_monitorings] FOREIGN KEY ([material_monitoring_id]) REFERENCES [material_monitorings] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260311235402_AddMaterialMonitoring'
)
BEGIN
    CREATE INDEX [IX_material_monitoring_details_material_monitoring_id] ON [material_monitoring_details] ([material_monitoring_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260311235402_AddMaterialMonitoring'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260311235402_AddMaterialMonitoring', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260314000000_AddAuditTrails'
)
BEGIN
    CREATE TABLE [audit_trails] (
        [id] uniqueidentifier NOT NULL,
        [user_id] uniqueidentifier NULL,
        [user_email] nvarchar(255) NULL,
        [user_name] nvarchar(255) NULL,
        [user_role] nvarchar(100) NULL,
        [action] nvarchar(50) NOT NULL,
        [url] nvarchar(2048) NOT NULL,
        [request_id] nvarchar(100) NULL,
        [created_at] datetime2 NOT NULL,
        CONSTRAINT [PK_audit_trails] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260314000000_AddAuditTrails'
)
BEGIN
    CREATE INDEX [IX_audit_trails_user_id] ON [audit_trails] ([user_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260314000000_AddAuditTrails'
)
BEGIN
    CREATE INDEX [IX_audit_trails_created_at] ON [audit_trails] ([created_at]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260314000000_AddAuditTrails'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260314000000_AddAuditTrails', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260315074949_AddSpkFlowEntities'
)
BEGIN
    CREATE TABLE [ros] (
        [ro_id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [spk_id] uniqueidentifier NOT NULL,
        [ro_no] nvarchar(100) NULL,
        [ro_amount] decimal(18,2) NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        [CreatedBy] uniqueidentifier NOT NULL,
        [UpdatedAt] datetime2 NULL,
        [UpdatedBy] uniqueidentifier NULL,
        [DeletedAt] datetime2 NULL,
        [DeletedBy] uniqueidentifier NULL,
        CONSTRAINT [PK_ros] PRIMARY KEY ([ro_id]),
        CONSTRAINT [FK_ros_spks] FOREIGN KEY ([spk_id]) REFERENCES [spks] ([spk_id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260315074949_AddSpkFlowEntities'
)
BEGIN
    CREATE TABLE [spk_approvers] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [spk_id] uniqueidentifier NOT NULL,
        [user_id] uniqueidentifier NOT NULL,
        [level] int NOT NULL,
        CONSTRAINT [PK_spk_approvers] PRIMARY KEY ([id]),
        CONSTRAINT [FK_spk_approvers_spks] FOREIGN KEY ([spk_id]) REFERENCES [spks] ([spk_id]) ON DELETE CASCADE,
        CONSTRAINT [FK_spk_approvers_users] FOREIGN KEY ([user_id]) REFERENCES [users] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260315074949_AddSpkFlowEntities'
)
BEGIN
    CREATE TABLE [spk_boq_progresses] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [spk_boq_schedule_id] uniqueidentifier NOT NULL,
        [date] date NOT NULL,
        [volume_addition] float NOT NULL,
        [remarks] nvarchar(max) NULL,
        [attachments] nvarchar(max) NULL,
        [status] nvarchar(100) NULL DEFAULT (('draft')),
        [CreatedAt] datetime2 NOT NULL,
        [CreatedBy] uniqueidentifier NOT NULL,
        [UpdatedAt] datetime2 NULL,
        [UpdatedBy] uniqueidentifier NULL,
        [DeletedAt] datetime2 NULL,
        [DeletedBy] uniqueidentifier NULL,
        [ApprovedAt] datetime2 NULL,
        [ApprovedBy] uniqueidentifier NULL,
        [RejectedAt] datetime2 NULL,
        [RejectedBy] uniqueidentifier NULL,
        [RejectedNote] nvarchar(max) NULL,
        CONSTRAINT [PK_spk_boq_progresses] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260315074949_AddSpkFlowEntities'
)
BEGIN
    CREATE TABLE [spk_boqs] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [spk_id] uniqueidentifier NOT NULL,
        [project_task_boq_id] nvarchar(max) NULL,
        [weighted_project_task] float NOT NULL,
        [weighted_spk] float NOT NULL,
        [physical_progress] float NOT NULL,
        [physical_progress_weighted] float NOT NULL,
        [actual_volume] float NOT NULL,
        [actual_progress_cost] float NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        [CreatedBy] uniqueidentifier NOT NULL,
        [UpdatedAt] datetime2 NULL,
        [UpdatedBy] uniqueidentifier NULL,
        [DeletedAt] datetime2 NULL,
        [DeletedBy] uniqueidentifier NULL,
        CONSTRAINT [PK_spk_boqs] PRIMARY KEY ([id]),
        CONSTRAINT [FK_spk_boqs_spks_spk_id] FOREIGN KEY ([spk_id]) REFERENCES [spks] ([spk_id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260315074949_AddSpkFlowEntities'
)
BEGIN
    CREATE TABLE [spk_field_inspectors] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [spk_id] uniqueidentifier NOT NULL,
        [user_id] uniqueidentifier NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        [CreatedBy] uniqueidentifier NOT NULL,
        [UpdatedAt] datetime2 NULL,
        [UpdatedBy] uniqueidentifier NULL,
        [DeletedAt] datetime2 NULL,
        [DeletedBy] uniqueidentifier NULL,
        CONSTRAINT [PK_spk_field_inspectors] PRIMARY KEY ([id]),
        CONSTRAINT [FK_spk_field_inspectors_spks] FOREIGN KEY ([spk_id]) REFERENCES [spks] ([spk_id]) ON DELETE CASCADE,
        CONSTRAINT [FK_spk_field_inspectors_users] FOREIGN KEY ([user_id]) REFERENCES [users] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260315074949_AddSpkFlowEntities'
)
BEGIN
    CREATE TABLE [service_acceptances] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [ro_id] uniqueidentifier NOT NULL,
        [contract_id] uniqueidentifier NOT NULL,
        [sa_no] nvarchar(100) NULL,
        [cost_usd] decimal(18,2) NOT NULL,
        [cost_idr] decimal(18,2) NOT NULL,
        [document_date] date NULL,
        [status] nvarchar(100) NULL DEFAULT (('unpaid')),
        [invoice_amount] decimal(18,2) NULL,
        [tenant_id] uniqueidentifier NULL,
        [CreatedAt] datetime2 NOT NULL,
        [CreatedBy] uniqueidentifier NOT NULL,
        [UpdatedAt] datetime2 NULL,
        [UpdatedBy] uniqueidentifier NULL,
        [DeletedAt] datetime2 NULL,
        [DeletedBy] uniqueidentifier NULL,
        CONSTRAINT [PK_service_acceptances] PRIMARY KEY ([id]),
        CONSTRAINT [FK_service_acceptances_ros] FOREIGN KEY ([ro_id]) REFERENCES [ros] ([ro_id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260315074949_AddSpkFlowEntities'
)
BEGIN
    CREATE TABLE [spk_boq_schedules] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [spk_boq_id] uniqueidentifier NOT NULL,
        [date] date NOT NULL,
        [plan_volume] float NULL,
        [plan_volume_accumulation] float NULL,
        [actual_volume] float NOT NULL,
        [actual_volume_accumulation] float NOT NULL,
        [plan_progress] float NOT NULL,
        [plan_progress_accumulation] float NOT NULL,
        [plan_weight] float NOT NULL,
        [plan_weight_accumulation] float NOT NULL,
        [actual_progress] float NOT NULL,
        [actual_progress_accumulation] float NOT NULL,
        [actual_weight] float NOT NULL,
        [actual_weight_accumulation] float NOT NULL,
        [plan_cost] float NOT NULL,
        [plan_cost_accumulation] float NOT NULL,
        [actual_cost] float NOT NULL,
        [actual_cost_accumulation] float NOT NULL,
        [plan_weight_project_task] float NOT NULL,
        [plan_weight_accumulation_project_task] float NOT NULL,
        [actual_weight_project_task] float NOT NULL,
        [actual_weight_accumulation_project_task] float NOT NULL,
        CONSTRAINT [PK_spk_boq_schedules] PRIMARY KEY ([id]),
        CONSTRAINT [FK_spk_boq_schedules_spk_boqs_spk_boq_id] FOREIGN KEY ([spk_boq_id]) REFERENCES [spk_boqs] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260315074949_AddSpkFlowEntities'
)
BEGIN
    CREATE INDEX [IX_ros_spk_id] ON [ros] ([spk_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260315074949_AddSpkFlowEntities'
)
BEGIN
    CREATE INDEX [IX_service_acceptances_ro_id] ON [service_acceptances] ([ro_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260315074949_AddSpkFlowEntities'
)
BEGIN
    CREATE INDEX [IX_spk_approvers_spk_id] ON [spk_approvers] ([spk_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260315074949_AddSpkFlowEntities'
)
BEGIN
    CREATE INDEX [IX_spk_approvers_user_id] ON [spk_approvers] ([user_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260315074949_AddSpkFlowEntities'
)
BEGIN
    CREATE INDEX [IX_spk_boq_schedules_spk_boq_id] ON [spk_boq_schedules] ([spk_boq_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260315074949_AddSpkFlowEntities'
)
BEGIN
    CREATE INDEX [IX_spk_boqs_spk_id] ON [spk_boqs] ([spk_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260315074949_AddSpkFlowEntities'
)
BEGIN
    CREATE INDEX [IX_spk_field_inspectors_spk_id] ON [spk_field_inspectors] ([spk_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260315074949_AddSpkFlowEntities'
)
BEGIN
    CREATE INDEX [IX_spk_field_inspectors_user_id] ON [spk_field_inspectors] ([user_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260315074949_AddSpkFlowEntities'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260315074949_AddSpkFlowEntities', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260317114242_AddUserExtendedColumns'
)
BEGIN
    ALTER TABLE [users] ADD [avatar_url] nvarchar(500) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260317114242_AddUserExtendedColumns'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260317114242_AddUserExtendedColumns', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260318003228_AddTendersTableAndFixDescriptionNotNull'
)
BEGIN
    DECLARE @var14 sysname;
    SELECT @var14 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[tender_processes]') AND [c].[name] = N'description');
    IF @var14 IS NOT NULL EXEC(N'ALTER TABLE [tender_processes] DROP CONSTRAINT [' + @var14 + '];');
    EXEC(N'UPDATE [tender_processes] SET [description] = N'''' WHERE [description] IS NULL');
    ALTER TABLE [tender_processes] ALTER COLUMN [description] nvarchar(100) NOT NULL;
    ALTER TABLE [tender_processes] ADD DEFAULT N'' FOR [description];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260318003228_AddTendersTableAndFixDescriptionNotNull'
)
BEGIN
    DECLARE @var15 sysname;
    SELECT @var15 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[tender_process_categories]') AND [c].[name] = N'description');
    IF @var15 IS NOT NULL EXEC(N'ALTER TABLE [tender_process_categories] DROP CONSTRAINT [' + @var15 + '];');
    EXEC(N'UPDATE [tender_process_categories] SET [description] = N'''' WHERE [description] IS NULL');
    ALTER TABLE [tender_process_categories] ALTER COLUMN [description] nvarchar(100) NOT NULL;
    ALTER TABLE [tender_process_categories] ADD DEFAULT N'' FOR [description];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260318003228_AddTendersTableAndFixDescriptionNotNull'
)
BEGIN
    CREATE TABLE [tenders] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [pic_legal] nvarchar(100) NULL,
        [review_legal_start] date NULL,
        [review_legal_end] date NULL,
        [tender_category] nvarchar(max) NOT NULL,
        [buyer] nvarchar(100) NULL,
        [committee] nvarchar(100) NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_tenders] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260318003228_AddTendersTableAndFixDescriptionNotNull'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260318003228_AddTendersTableAndFixDescriptionNotNull', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260320000000_AddContractDocuments'
)
BEGIN
    CREATE TABLE [contract_documents] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [contract_id] uniqueidentifier NOT NULL,
        [file_name] nvarchar(150) NOT NULL,
        [file_type] nvarchar(150) NULL,
        [file_size] nvarchar(20) NULL,
        [file_url] text NULL,
        [description] nvarchar(255) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_contract_documents] PRIMARY KEY ([id]),
        CONSTRAINT [FK_contract_documents_contracts_contract_id] FOREIGN KEY ([contract_id]) REFERENCES [contracts] ([contract_id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260320000000_AddContractDocuments'
)
BEGIN
    CREATE INDEX [IX_contract_documents_contract_id] ON [contract_documents] ([contract_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260320000000_AddContractDocuments'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260320000000_AddContractDocuments', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260324000000_AddRequestNumbersToTenderContract'
)
BEGIN
    ALTER TABLE [tender_contracts] ADD [request_numbers] nvarchar(500) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260324000000_AddRequestNumbersToTenderContract'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260324000000_AddRequestNumbersToTenderContract', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260324071427_AddSpkBoqProgressApprover'
)
BEGIN
    CREATE TABLE [spk_boq_progress_approvers] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [spk_id] uniqueidentifier NOT NULL,
        [user_id] uniqueidentifier NOT NULL,
        [level] int NOT NULL,
        CONSTRAINT [PK_spk_boq_progress_approvers] PRIMARY KEY ([id]),
        CONSTRAINT [FK_spk_boq_progress_approvers_spks] FOREIGN KEY ([spk_id]) REFERENCES [spks] ([spk_id]) ON DELETE CASCADE,
        CONSTRAINT [FK_spk_boq_progress_approvers_users] FOREIGN KEY ([user_id]) REFERENCES [users] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260324071427_AddSpkBoqProgressApprover'
)
BEGIN
    CREATE INDEX [IX_spk_boq_progress_approvers_spk_id] ON [spk_boq_progress_approvers] ([spk_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260324071427_AddSpkBoqProgressApprover'
)
BEGIN
    CREATE INDEX [IX_spk_boq_progress_approvers_user_id] ON [spk_boq_progress_approvers] ([user_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260324071427_AddSpkBoqProgressApprover'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260324071427_AddSpkBoqProgressApprover', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260325004935_AddTenderPlanAndHistoryTables'
)
BEGIN
    DECLARE @var16 sysname;
    SELECT @var16 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[tender_actual_timelines]') AND [c].[name] = N'duration');
    IF @var16 IS NOT NULL EXEC(N'ALTER TABLE [tender_actual_timelines] DROP CONSTRAINT [' + @var16 + '];');
    ALTER TABLE [tender_actual_timelines] ALTER COLUMN [duration] bigint NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260325004935_AddTenderPlanAndHistoryTables'
)
BEGIN
    DECLARE @var17 sysname;
    SELECT @var17 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[tender_contracts]') AND [c].[name] = N'request_numbers');
    IF @var17 IS NOT NULL EXEC(N'ALTER TABLE [tender_contracts] DROP CONSTRAINT [' + @var17 + '];');
    ALTER TABLE [tender_contracts] DROP COLUMN [request_numbers];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260325004935_AddTenderPlanAndHistoryTables'
)
BEGIN
    CREATE TABLE [tender_contract_request_numbers] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [tender_contract_id] uniqueidentifier NOT NULL,
        [request_number] nvarchar(100) NULL,
        CONSTRAINT [PK_tender_contract_request_numbers] PRIMARY KEY ([id]),
        CONSTRAINT [FK_tender_contract_request_numbers_tender_contracts] FOREIGN KEY ([tender_contract_id]) REFERENCES [tender_contracts] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260325004935_AddTenderPlanAndHistoryTables'
)
BEGIN
    CREATE TABLE [tender_plan_timelines] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [tender_contract_id] uniqueidentifier NOT NULL,
        [tender_process_id] uniqueidentifier NOT NULL,
        [plan_start_date] date NULL,
        [plan_end_date] date NULL,
        [duration] bigint NOT NULL,
        CONSTRAINT [PK_tender_plan_timelines] PRIMARY KEY ([id]),
        CONSTRAINT [FK_tender_plan_timelines_process_snapshots] FOREIGN KEY ([tender_process_id]) REFERENCES [tender_process_snapshots] ([id]),
        CONSTRAINT [FK_tender_plan_timelines_tender_contracts] FOREIGN KEY ([tender_contract_id]) REFERENCES [tender_contracts] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260325004935_AddTenderPlanAndHistoryTables'
)
BEGIN
    CREATE TABLE [tender_timeline_histories] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [tender_actual_timeline_id] uniqueidentifier NOT NULL,
        [tender_process_id] uniqueidentifier NOT NULL,
        [actual_start_date] date NULL,
        [actual_end_date] date NULL,
        [remarks] nvarchar(255) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        CONSTRAINT [PK_tender_timeline_histories] PRIMARY KEY ([id]),
        CONSTRAINT [FK_tender_timeline_histories_process_snapshots] FOREIGN KEY ([tender_process_id]) REFERENCES [tender_process_snapshots] ([id]),
        CONSTRAINT [FK_tender_timeline_histories_tender_actual_timelines] FOREIGN KEY ([tender_actual_timeline_id]) REFERENCES [tender_actual_timelines] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260325004935_AddTenderPlanAndHistoryTables'
)
BEGIN
    CREATE INDEX [IX_tender_contract_request_numbers_tender_contract_id] ON [tender_contract_request_numbers] ([tender_contract_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260325004935_AddTenderPlanAndHistoryTables'
)
BEGIN
    CREATE INDEX [IX_tender_plan_timelines_tender_contract_id] ON [tender_plan_timelines] ([tender_contract_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260325004935_AddTenderPlanAndHistoryTables'
)
BEGIN
    CREATE INDEX [IX_tender_plan_timelines_tender_process_id] ON [tender_plan_timelines] ([tender_process_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260325004935_AddTenderPlanAndHistoryTables'
)
BEGIN
    CREATE INDEX [IX_tender_timeline_histories_tender_actual_timeline_id] ON [tender_timeline_histories] ([tender_actual_timeline_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260325004935_AddTenderPlanAndHistoryTables'
)
BEGIN
    CREATE INDEX [IX_tender_timeline_histories_tender_process_id] ON [tender_timeline_histories] ([tender_process_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260325004935_AddTenderPlanAndHistoryTables'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260325004935_AddTenderPlanAndHistoryTables', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260327084402_AddProjectTaskBoqEntities'
)
BEGIN
    DECLARE @var18 sysname;
    SELECT @var18 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[spk_boqs]') AND [c].[name] = N'project_task_boq_id');
    IF @var18 IS NOT NULL EXEC(N'ALTER TABLE [spk_boqs] DROP CONSTRAINT [' + @var18 + '];');
    ALTER TABLE [spk_boqs] ALTER COLUMN [project_task_boq_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260327084402_AddProjectTaskBoqEntities'
)
BEGIN
    CREATE TABLE [project_task_boqs] (
        [id] uniqueidentifier NOT NULL,
        [project_task_id] uniqueidentifier NULL,
        [code] varchar(20) NULL,
        [description] text NOT NULL,
        [kind] varchar(20) NULL,
        [unit_id] uniqueidentifier NOT NULL,
        [volume] float NOT NULL,
        [total_price] float NOT NULL,
        [remarks] text NULL,
        [start_date] date NOT NULL,
        [end_date] date NOT NULL,
        [type] varchar(50) NOT NULL DEFAULT 'inline',
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_project_task_boqs] PRIMARY KEY ([id]),
        CONSTRAINT [FK_project_task_boqs_project_tasks_project_task_id] FOREIGN KEY ([project_task_id]) REFERENCES [project_tasks] ([id]),
        CONSTRAINT [FK_project_task_boqs_units_unit_id] FOREIGN KEY ([unit_id]) REFERENCES [units] ([unit_id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260327084402_AddProjectTaskBoqEntities'
)
BEGIN
    CREATE TABLE [project_task_boq_details] (
        [id] uniqueidentifier NOT NULL,
        [project_task_boq_id] uniqueidentifier NOT NULL,
        [boq_detail_id] uniqueidentifier NOT NULL,
        [unit_id] uniqueidentifier NOT NULL,
        [volume] float NOT NULL,
        [unit_price] float NOT NULL,
        [total_price] float NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_project_task_boq_details] PRIMARY KEY ([id]),
        CONSTRAINT [FK_project_task_boq_details_boq_details_boq_detail_id] FOREIGN KEY ([boq_detail_id]) REFERENCES [boq_details] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_project_task_boq_details_project_task_boqs_project_task_boq_id] FOREIGN KEY ([project_task_boq_id]) REFERENCES [project_task_boqs] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_project_task_boq_details_units_unit_id] FOREIGN KEY ([unit_id]) REFERENCES [units] ([unit_id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260327084402_AddProjectTaskBoqEntities'
)
BEGIN
    CREATE INDEX [IX_project_task_boq_details_boq_detail_id] ON [project_task_boq_details] ([boq_detail_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260327084402_AddProjectTaskBoqEntities'
)
BEGIN
    CREATE INDEX [IX_project_task_boq_details_project_task_boq_id] ON [project_task_boq_details] ([project_task_boq_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260327084402_AddProjectTaskBoqEntities'
)
BEGIN
    CREATE INDEX [IX_project_task_boq_details_unit_id] ON [project_task_boq_details] ([unit_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260327084402_AddProjectTaskBoqEntities'
)
BEGIN
    CREATE INDEX [IX_project_task_boqs_project_task_id] ON [project_task_boqs] ([project_task_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260327084402_AddProjectTaskBoqEntities'
)
BEGIN
    CREATE INDEX [IX_project_task_boqs_unit_id] ON [project_task_boqs] ([unit_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260327084402_AddProjectTaskBoqEntities'
)
BEGIN
    CREATE INDEX [IX_spk_boqs_project_task_boq_id] ON [spk_boqs] ([project_task_boq_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260327084402_AddProjectTaskBoqEntities'
)
BEGIN
    ALTER TABLE [spk_boqs] ADD CONSTRAINT [FK_spk_boqs_project_task_boqs_project_task_boq_id] FOREIGN KEY ([project_task_boq_id]) REFERENCES [project_task_boqs] ([id]) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260327084402_AddProjectTaskBoqEntities'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260327084402_AddProjectTaskBoqEntities', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260330145404_AddSpkRemarkLogs'
)
BEGIN
    EXEC sp_rename N'[audit_trails].[user_name]', N'UserName', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260330145404_AddSpkRemarkLogs'
)
BEGIN
    DECLARE @var19 sysname;
    SELECT @var19 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[audit_trails]') AND [c].[name] = N'UserName');
    IF @var19 IS NOT NULL EXEC(N'ALTER TABLE [audit_trails] DROP CONSTRAINT [' + @var19 + '];');
    ALTER TABLE [audit_trails] ALTER COLUMN [UserName] nvarchar(max) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260330145404_AddSpkRemarkLogs'
)
BEGIN
    CREATE TABLE [spk_remark_logs] (
        [id] uniqueidentifier NOT NULL,
        [spk_id] uniqueidentifier NOT NULL,
        [remark] text NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        CONSTRAINT [PK_spk_remark_logs] PRIMARY KEY ([id]),
        CONSTRAINT [FK_spk_remark_logs_spks_spk_id] FOREIGN KEY ([spk_id]) REFERENCES [spks] ([spk_id]) ON DELETE CASCADE,
        CONSTRAINT [FK_spk_remark_logs_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260330145404_AddSpkRemarkLogs'
)
BEGIN
    CREATE INDEX [IX_spk_remark_logs_created_by] ON [spk_remark_logs] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260330145404_AddSpkRemarkLogs'
)
BEGIN
    CREATE INDEX [IX_spk_remark_logs_spk_id] ON [spk_remark_logs] ([spk_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260330145404_AddSpkRemarkLogs'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260330145404_AddSpkRemarkLogs', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260331000000_AddContractValueDepletionWarningNotification'
)
BEGIN
    CREATE TABLE [contract_value_depletion_warning_notifications] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [frequency] nvarchar(50) NOT NULL,
        [recipients] nvarchar(max) NULL,
        [cron_id] int NOT NULL DEFAULT 0,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        CONSTRAINT [PK_contract_value_depletion_warning_notifications] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260331000000_AddContractValueDepletionWarningNotification'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260331000000_AddContractValueDepletionWarningNotification', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260331104816_AddSpkDocumentsTable'
)
BEGIN
    CREATE TABLE [spk_documents] (
        [id] uniqueidentifier NOT NULL,
        [spk_id] uniqueidentifier NOT NULL,
        [file_name] varchar(150) NOT NULL,
        [file_type] varchar(150) NULL,
        [file_size] varchar(20) NULL,
        [file_url] text NULL,
        [description] varchar(255) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_spk_documents] PRIMARY KEY ([id]),
        CONSTRAINT [FK_spk_documents_spks_spk_id] FOREIGN KEY ([spk_id]) REFERENCES [spks] ([spk_id]) ON DELETE CASCADE,
        CONSTRAINT [FK_spk_documents_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_spk_documents_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260331104816_AddSpkDocumentsTable'
)
BEGIN
    CREATE INDEX [IX_spk_documents_created_by] ON [spk_documents] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260331104816_AddSpkDocumentsTable'
)
BEGIN
    CREATE INDEX [IX_spk_documents_spk_id] ON [spk_documents] ([spk_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260331104816_AddSpkDocumentsTable'
)
BEGIN
    CREATE INDEX [IX_spk_documents_updated_by] ON [spk_documents] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260331104816_AddSpkDocumentsTable'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260331104816_AddSpkDocumentsTable', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260401021832_RemoveFkSpkDocuments'
)
BEGIN
    ALTER TABLE [spk_documents] DROP CONSTRAINT [FK_spk_documents_spks_spk_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260401021832_RemoveFkSpkDocuments'
)
BEGIN
    ALTER TABLE [spk_documents] DROP CONSTRAINT [FK_spk_documents_users_created_by];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260401021832_RemoveFkSpkDocuments'
)
BEGIN
    ALTER TABLE [spk_documents] DROP CONSTRAINT [FK_spk_documents_users_updated_by];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260401021832_RemoveFkSpkDocuments'
)
BEGIN
    DROP INDEX [IX_spk_documents_created_by] ON [spk_documents];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260401021832_RemoveFkSpkDocuments'
)
BEGIN
    DROP INDEX [IX_spk_documents_spk_id] ON [spk_documents];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260401021832_RemoveFkSpkDocuments'
)
BEGIN
    DROP INDEX [IX_spk_documents_updated_by] ON [spk_documents];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260401021832_RemoveFkSpkDocuments'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260401021832_RemoveFkSpkDocuments', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260402035237_AddSpkBoqDocumentsTable'
)
BEGIN
    CREATE TABLE [spk_boq_documents] (
        [id] uniqueidentifier NOT NULL,
        [spk_boq_id] uniqueidentifier NOT NULL,
        [file_name] varchar(150) NOT NULL,
        [file_type] varchar(150) NULL,
        [file_size] varchar(20) NULL,
        [file_url] text NULL,
        [description] varchar(255) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_spk_boq_documents] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260402035237_AddSpkBoqDocumentsTable'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260402035237_AddSpkBoqDocumentsTable', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260407090944_AddSpkVariousWbsCostAllocation'
)
BEGIN
    CREATE TABLE [spk_cost_allocations] (
        [id] uniqueidentifier NOT NULL DEFAULT (NEWID()),
        [spk_id] uniqueidentifier NOT NULL,
        [project_id] uniqueidentifier NOT NULL,
        [cost_allocation] numeric(18,0) NOT NULL,
        [is_connect] bigint NOT NULL DEFAULT CAST(0 AS bigint),
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_spk_cost_allocations] PRIMARY KEY ([id]),
        CONSTRAINT [FK_spk_cost_allocations_projects_project_id] FOREIGN KEY ([project_id]) REFERENCES [projects] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_spk_cost_allocations_spks_spk_id] FOREIGN KEY ([spk_id]) REFERENCES [spks] ([spk_id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260407090944_AddSpkVariousWbsCostAllocation'
)
BEGIN
    CREATE INDEX [IX_spk_cost_allocations_project_id] ON [spk_cost_allocations] ([project_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260407090944_AddSpkVariousWbsCostAllocation'
)
BEGIN
    CREATE INDEX [IX_spk_cost_allocations_spk_id] ON [spk_cost_allocations] ([spk_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260407090944_AddSpkVariousWbsCostAllocation'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260407090944_AddSpkVariousWbsCostAllocation', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260408223225_AddCategoryIndustryAndEnterpriseSizingToContracts'
)
BEGIN
    DECLARE @var20 sysname;
    SELECT @var20 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[spk_cost_allocations]') AND [c].[name] = N'id');
    IF @var20 IS NOT NULL EXEC(N'ALTER TABLE [spk_cost_allocations] DROP CONSTRAINT [' + @var20 + '];');
    ALTER TABLE [spk_cost_allocations] ADD DEFAULT (NEWID()) FOR [id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260408223225_AddCategoryIndustryAndEnterpriseSizingToContracts'
)
BEGIN
    ALTER TABLE [contracts] ADD [category_industry] nvarchar(500) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260408223225_AddCategoryIndustryAndEnterpriseSizingToContracts'
)
BEGIN
    ALTER TABLE [contracts] ADD [enterprise_sizing] nvarchar(500) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260408223225_AddCategoryIndustryAndEnterpriseSizingToContracts'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260408223225_AddCategoryIndustryAndEnterpriseSizingToContracts', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260410034937_AddRelasiSpkBoqProgress'
)
BEGIN
    DECLARE @var21 sysname;
    SELECT @var21 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[spk_cost_allocations]') AND [c].[name] = N'id');
    IF @var21 IS NOT NULL EXEC(N'ALTER TABLE [spk_cost_allocations] DROP CONSTRAINT [' + @var21 + '];');
    ALTER TABLE [spk_cost_allocations] ADD DEFAULT (NEWID()) FOR [id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260410034937_AddRelasiSpkBoqProgress'
)
BEGIN
    CREATE INDEX [IX_spk_boq_progresses_spk_boq_schedule_id] ON [spk_boq_progresses] ([spk_boq_schedule_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260410034937_AddRelasiSpkBoqProgress'
)
BEGIN
    ALTER TABLE [spk_boq_progresses] ADD CONSTRAINT [FK_spk_boq_progresses_schedules] FOREIGN KEY ([spk_boq_schedule_id]) REFERENCES [spk_boq_schedules] ([id]) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260410034937_AddRelasiSpkBoqProgress'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260410034937_AddRelasiSpkBoqProgress', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415030741_AddInvoiceRetentionsTable'
)
BEGIN
    ALTER TABLE [spks] ADD [last_bast_date] datetime NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415030741_AddInvoiceRetentionsTable'
)
BEGIN
    ALTER TABLE [role_permissions] ADD [RoleId1] int NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415030741_AddInvoiceRetentionsTable'
)
BEGIN
    ALTER TABLE [role_approval_tierings] ADD [RoleId1] int NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415030741_AddInvoiceRetentionsTable'
)
BEGIN
    CREATE TABLE [invoice_retentions] (
        [id] uniqueidentifier NOT NULL,
        [invoice_id] uniqueidentifier NOT NULL,
        [service_acceptance_id] uniqueidentifier NOT NULL,
        [contract_id] uniqueidentifier NOT NULL,
        [retention_percentage] decimal(18,4) NOT NULL,
        [retention_amount] decimal(18,4) NOT NULL,
        [status] nvarchar(50) NOT NULL,
        [invoice_payment_id] uniqueidentifier NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NOT NULL,
        [updated_by] uniqueidentifier NOT NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_invoice_retentions] PRIMARY KEY ([id]),
        CONSTRAINT [FK_invoice_retentions_contracts_contract_id] FOREIGN KEY ([contract_id]) REFERENCES [contracts] ([contract_id]),
        CONSTRAINT [FK_invoice_retentions_invoices_invoice_id] FOREIGN KEY ([invoice_id]) REFERENCES [invoices] ([id]),
        CONSTRAINT [FK_invoice_retentions_invoices_invoice_payment_id] FOREIGN KEY ([invoice_payment_id]) REFERENCES [invoices] ([id]),
        CONSTRAINT [FK_invoice_retentions_service_acceptances_service_acceptance_id] FOREIGN KEY ([service_acceptance_id]) REFERENCES [service_acceptances] ([id]),
        CONSTRAINT [FK_invoice_retentions_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_invoice_retentions_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415030741_AddInvoiceRetentionsTable'
)
BEGIN
    CREATE TABLE [notifications] (
        [id] uniqueidentifier NOT NULL,
        [title] nvarchar(200) NULL,
        [message] nvarchar(510) NULL,
        [has_read] int NOT NULL,
        [web_link] nvarchar(510) NULL,
        [mobile_link] nvarchar(510) NULL,
        [created_at] datetime NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        [user_id] uniqueidentifier NOT NULL,
        [tenant_id] uniqueidentifier NULL,
        CONSTRAINT [PK_notifications] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415030741_AddInvoiceRetentionsTable'
)
BEGIN
    CREATE INDEX [IX_users_role_id] ON [users] ([role_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415030741_AddInvoiceRetentionsTable'
)
BEGIN
    CREATE INDEX [IX_role_permissions_RoleId1] ON [role_permissions] ([RoleId1]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415030741_AddInvoiceRetentionsTable'
)
BEGIN
    CREATE INDEX [IX_role_approval_tierings_RoleId1] ON [role_approval_tierings] ([RoleId1]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415030741_AddInvoiceRetentionsTable'
)
BEGIN
    CREATE INDEX [IX_invoice_retentions_contract_id] ON [invoice_retentions] ([contract_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415030741_AddInvoiceRetentionsTable'
)
BEGIN
    CREATE INDEX [IX_invoice_retentions_created_by] ON [invoice_retentions] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415030741_AddInvoiceRetentionsTable'
)
BEGIN
    CREATE INDEX [IX_invoice_retentions_invoice_id] ON [invoice_retentions] ([invoice_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415030741_AddInvoiceRetentionsTable'
)
BEGIN
    CREATE INDEX [IX_invoice_retentions_invoice_payment_id] ON [invoice_retentions] ([invoice_payment_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415030741_AddInvoiceRetentionsTable'
)
BEGIN
    CREATE INDEX [IX_invoice_retentions_service_acceptance_id] ON [invoice_retentions] ([service_acceptance_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415030741_AddInvoiceRetentionsTable'
)
BEGIN
    CREATE INDEX [IX_invoice_retentions_updated_by] ON [invoice_retentions] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415030741_AddInvoiceRetentionsTable'
)
BEGIN
    ALTER TABLE [role_approval_tierings] ADD CONSTRAINT [FK_role_approval_tierings_roles_RoleId1] FOREIGN KEY ([RoleId1]) REFERENCES [roles] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415030741_AddInvoiceRetentionsTable'
)
BEGIN
    ALTER TABLE [role_permissions] ADD CONSTRAINT [FK_role_permissions_roles_RoleId1] FOREIGN KEY ([RoleId1]) REFERENCES [roles] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415030741_AddInvoiceRetentionsTable'
)
BEGIN
    ALTER TABLE [users] ADD CONSTRAINT [FK_users_roles_role_id] FOREIGN KEY ([role_id]) REFERENCES [roles] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415030741_AddInvoiceRetentionsTable'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260415030741_AddInvoiceRetentionsTable', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415104204_AddContractWorkingArea'
)
BEGIN
    CREATE TABLE [contract_working_areas] (
        [contract_working_area_id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [contract_id] uniqueidentifier NOT NULL,
        [working_area] nvarchar(100) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_contract_working_areas] PRIMARY KEY ([contract_working_area_id]),
        CONSTRAINT [FK_contract_working_areas_contracts] FOREIGN KEY ([contract_id]) REFERENCES [contracts] ([contract_id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415104204_AddContractWorkingArea'
)
BEGIN
    CREATE INDEX [IX_contract_working_areas_contract_id] ON [contract_working_areas] ([contract_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260415104204_AddContractWorkingArea'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260415104204_AddContractWorkingArea', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260421223157_AddProjectTaskProgresses'
)
BEGIN
    CREATE TABLE [project_scurve_datasets] (
        [id] uniqueidentifier NOT NULL,
        [project_id] uniqueidentifier NOT NULL,
        [version] int NOT NULL,
        [daily_dataset] text NULL,
        [weekly_dataset] text NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        CONSTRAINT [PK_project_scurve_datasets] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260421223157_AddProjectTaskProgresses'
)
BEGIN
    CREATE TABLE [project_task_progresses] (
        [id] uniqueidentifier NOT NULL,
        [project_task_schedule_id] uniqueidentifier NOT NULL,
        [date] date NOT NULL,
        [progress_addition] float NOT NULL,
        [remarks] text NULL,
        [attachments] nvarchar(max) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        CONSTRAINT [PK_project_task_progresses] PRIMARY KEY ([id]),
        CONSTRAINT [FK_project_task_progresses_project_task_schedules_project_task_schedule_id] FOREIGN KEY ([project_task_schedule_id]) REFERENCES [project_task_schedules] ([id]),
        CONSTRAINT [FK_project_task_progresses_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_project_task_progresses_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260421223157_AddProjectTaskProgresses'
)
BEGIN
    CREATE INDEX [IX_project_task_progresses_created_by] ON [project_task_progresses] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260421223157_AddProjectTaskProgresses'
)
BEGIN
    CREATE INDEX [IX_project_task_progresses_project_task_schedule_id] ON [project_task_progresses] ([project_task_schedule_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260421223157_AddProjectTaskProgresses'
)
BEGIN
    CREATE INDEX [IX_project_task_progresses_updated_by] ON [project_task_progresses] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260421223157_AddProjectTaskProgresses'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260421223157_AddProjectTaskProgresses', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    ALTER TABLE [service_acceptances] DROP CONSTRAINT [FK_service_acceptances_ros];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    EXEC sp_rename N'[service_acceptances].[UpdatedBy]', N'updated_by', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    EXEC sp_rename N'[service_acceptances].[UpdatedAt]', N'updated_at', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    EXEC sp_rename N'[service_acceptances].[DeletedBy]', N'deleted_by', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    EXEC sp_rename N'[service_acceptances].[DeletedAt]', N'deleted_at', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    EXEC sp_rename N'[service_acceptances].[CreatedBy]', N'created_by', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    EXEC sp_rename N'[service_acceptances].[CreatedAt]', N'created_at', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    DECLARE @var22 sysname;
    SELECT @var22 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[service_acceptances]') AND [c].[name] = N'status');
    IF @var22 IS NOT NULL EXEC(N'ALTER TABLE [service_acceptances] DROP CONSTRAINT [' + @var22 + '];');
    EXEC(N'UPDATE [service_acceptances] SET [status] = N''unpaid'' WHERE [status] IS NULL');
    ALTER TABLE [service_acceptances] ALTER COLUMN [status] nvarchar(50) NOT NULL;
    ALTER TABLE [service_acceptances] ADD DEFAULT N'unpaid' FOR [status];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    DECLARE @var23 sysname;
    SELECT @var23 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[service_acceptances]') AND [c].[name] = N'sa_no');
    IF @var23 IS NOT NULL EXEC(N'ALTER TABLE [service_acceptances] DROP CONSTRAINT [' + @var23 + '];');
    EXEC(N'UPDATE [service_acceptances] SET [sa_no] = N'''' WHERE [sa_no] IS NULL');
    ALTER TABLE [service_acceptances] ALTER COLUMN [sa_no] nvarchar(100) NOT NULL;
    ALTER TABLE [service_acceptances] ADD DEFAULT N'' FOR [sa_no];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    DECLARE @var24 sysname;
    SELECT @var24 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[service_acceptances]') AND [c].[name] = N'invoice_amount');
    IF @var24 IS NOT NULL EXEC(N'ALTER TABLE [service_acceptances] DROP CONSTRAINT [' + @var24 + '];');
    ALTER TABLE [service_acceptances] ALTER COLUMN [invoice_amount] numeric(18,4) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    DECLARE @var25 sysname;
    SELECT @var25 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[service_acceptances]') AND [c].[name] = N'cost_usd');
    IF @var25 IS NOT NULL EXEC(N'ALTER TABLE [service_acceptances] DROP CONSTRAINT [' + @var25 + '];');
    ALTER TABLE [service_acceptances] ALTER COLUMN [cost_usd] numeric(18,4) NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    DECLARE @var26 sysname;
    SELECT @var26 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[service_acceptances]') AND [c].[name] = N'cost_idr');
    IF @var26 IS NOT NULL EXEC(N'ALTER TABLE [service_acceptances] DROP CONSTRAINT [' + @var26 + '];');
    ALTER TABLE [service_acceptances] ALTER COLUMN [cost_idr] numeric(18,4) NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    DECLARE @var27 sysname;
    SELECT @var27 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[service_acceptances]') AND [c].[name] = N'id');
    IF @var27 IS NOT NULL EXEC(N'ALTER TABLE [service_acceptances] DROP CONSTRAINT [' + @var27 + '];');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    DECLARE @var28 sysname;
    SELECT @var28 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[service_acceptances]') AND [c].[name] = N'updated_at');
    IF @var28 IS NOT NULL EXEC(N'ALTER TABLE [service_acceptances] DROP CONSTRAINT [' + @var28 + '];');
    ALTER TABLE [service_acceptances] ALTER COLUMN [updated_at] datetime NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    DECLARE @var29 sysname;
    SELECT @var29 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[service_acceptances]') AND [c].[name] = N'deleted_at');
    IF @var29 IS NOT NULL EXEC(N'ALTER TABLE [service_acceptances] DROP CONSTRAINT [' + @var29 + '];');
    ALTER TABLE [service_acceptances] ALTER COLUMN [deleted_at] datetime NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    DECLARE @var30 sysname;
    SELECT @var30 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[service_acceptances]') AND [c].[name] = N'created_at');
    IF @var30 IS NOT NULL EXEC(N'ALTER TABLE [service_acceptances] DROP CONSTRAINT [' + @var30 + '];');
    ALTER TABLE [service_acceptances] ALTER COLUMN [created_at] datetime NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    ALTER TABLE [service_acceptances] ADD [line_item] bigint NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    ALTER TABLE [service_acceptances] ADD [project_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    CREATE TABLE [invoice_service_acceptances] (
        [id] uniqueidentifier NOT NULL,
        [invoice_id] uniqueidentifier NOT NULL,
        [service_acceptance_id] uniqueidentifier NOT NULL,
        [sa_amount] numeric(18,4) NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_invoice_service_acceptances] PRIMARY KEY ([id]),
        CONSTRAINT [FK_invoice_service_acceptances_invoices_invoice_id] FOREIGN KEY ([invoice_id]) REFERENCES [invoices] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_invoice_service_acceptances_service_acceptances_service_acceptance_id] FOREIGN KEY ([service_acceptance_id]) REFERENCES [service_acceptances] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    CREATE INDEX [IX_service_acceptances_contract_id] ON [service_acceptances] ([contract_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    CREATE INDEX [IX_service_acceptances_project_id] ON [service_acceptances] ([project_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    CREATE INDEX [IX_invoice_service_acceptances_invoice_id] ON [invoice_service_acceptances] ([invoice_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    CREATE INDEX [IX_invoice_service_acceptances_service_acceptance_id] ON [invoice_service_acceptances] ([service_acceptance_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    ALTER TABLE [service_acceptances] ADD CONSTRAINT [FK_service_acceptances_contracts_contract_id] FOREIGN KEY ([contract_id]) REFERENCES [contracts] ([contract_id]) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    ALTER TABLE [service_acceptances] ADD CONSTRAINT [FK_service_acceptances_projects_project_id] FOREIGN KEY ([project_id]) REFERENCES [projects] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    ALTER TABLE [service_acceptances] ADD CONSTRAINT [FK_service_acceptances_ros_ro_id] FOREIGN KEY ([ro_id]) REFERENCES [ros] ([ro_id]) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422043634_AddServiceAcceptanceAndInvoiceRelations'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260422043634_AddServiceAcceptanceAndInvoiceRelations', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422084654_RemoveShadowPropertyRoId'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260422084654_RemoveShadowPropertyRoId', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422092155_FixRoIdShadowProperty'
)
BEGIN
    ALTER TABLE [service_acceptances] DROP CONSTRAINT [FK_service_acceptances_ros_RoId1];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422092155_FixRoIdShadowProperty'
)
BEGIN
    DROP INDEX [IX_service_acceptances_RoId1] ON [service_acceptances];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422092155_FixRoIdShadowProperty'
)
BEGIN
    DECLARE @var31 sysname;
    SELECT @var31 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[service_acceptances]') AND [c].[name] = N'RoId1');
    IF @var31 IS NOT NULL EXEC(N'ALTER TABLE [service_acceptances] DROP CONSTRAINT [' + @var31 + '];');
    ALTER TABLE [service_acceptances] DROP COLUMN [RoId1];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260422092155_FixRoIdShadowProperty'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260422092155_FixRoIdShadowProperty', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502000000_AddWellFields'
)
BEGIN
    CREATE TABLE [well_fields] (
        [id] uniqueidentifier NOT NULL,
        [name] nvarchar(100) NOT NULL,
        [is_active] int NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_fields] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_fields_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_fields_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_fields_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502000000_AddWellFields'
)
BEGIN
    CREATE INDEX [IX_well_fields_created_by] ON [well_fields] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502000000_AddWellFields'
)
BEGIN
    CREATE INDEX [IX_well_fields_updated_by] ON [well_fields] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502000000_AddWellFields'
)
BEGIN
    CREATE INDEX [IX_well_fields_deleted_by] ON [well_fields] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502000000_AddWellFields'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260502000000_AddWellFields', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502010000_AddWellAreas'
)
BEGIN
    CREATE TABLE [well_areas] (
        [id] uniqueidentifier NOT NULL,
        [name] nvarchar(100) NOT NULL,
        [is_active] int NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_areas] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_areas_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_areas_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_areas_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502010000_AddWellAreas'
)
BEGIN
    CREATE INDEX [IX_well_areas_created_by] ON [well_areas] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502010000_AddWellAreas'
)
BEGIN
    CREATE INDEX [IX_well_areas_updated_by] ON [well_areas] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502010000_AddWellAreas'
)
BEGIN
    CREATE INDEX [IX_well_areas_deleted_by] ON [well_areas] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502010000_AddWellAreas'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260502010000_AddWellAreas', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502020000_AddWellLiftingTypes'
)
BEGIN
    CREATE TABLE [well_lifting_types] (
        [id] uniqueidentifier NOT NULL,
        [name] nvarchar(100) NOT NULL,
        [is_active] int NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_lifting_types] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_lifting_types_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_lifting_types_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_lifting_types_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502020000_AddWellLiftingTypes'
)
BEGIN
    CREATE INDEX [IX_well_lifting_types_created_by] ON [well_lifting_types] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502020000_AddWellLiftingTypes'
)
BEGIN
    CREATE INDEX [IX_well_lifting_types_updated_by] ON [well_lifting_types] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502020000_AddWellLiftingTypes'
)
BEGIN
    CREATE INDEX [IX_well_lifting_types_deleted_by] ON [well_lifting_types] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502020000_AddWellLiftingTypes'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260502020000_AddWellLiftingTypes', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502030000_AddWellLocations'
)
BEGIN
    CREATE TABLE [well_locations] (
        [id] uniqueidentifier NOT NULL,
        [name] nvarchar(100) NOT NULL,
        [is_active] int NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_locations] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_locations_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_locations_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_locations_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502030000_AddWellLocations'
)
BEGIN
    CREATE INDEX [IX_well_locations_created_by] ON [well_locations] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502030000_AddWellLocations'
)
BEGIN
    CREATE INDEX [IX_well_locations_updated_by] ON [well_locations] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502030000_AddWellLocations'
)
BEGIN
    CREATE INDEX [IX_well_locations_deleted_by] ON [well_locations] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502030000_AddWellLocations'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260502030000_AddWellLocations', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502040000_AddWellPlants'
)
BEGIN
    CREATE TABLE [well_plants] (
        [id] uniqueidentifier NOT NULL,
        [name] nvarchar(100) NOT NULL,
        [is_active] int NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_plants] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_plants_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_plants_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_plants_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502040000_AddWellPlants'
)
BEGIN
    CREATE INDEX [IX_well_plants_created_by] ON [well_plants] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502040000_AddWellPlants'
)
BEGIN
    CREATE INDEX [IX_well_plants_updated_by] ON [well_plants] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502040000_AddWellPlants'
)
BEGIN
    CREATE INDEX [IX_well_plants_deleted_by] ON [well_plants] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502040000_AddWellPlants'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260502040000_AddWellPlants', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502050000_AddWellProductionDestinationTypes'
)
BEGIN
    CREATE TABLE [well_production_destination_types] (
        [id] uniqueidentifier NOT NULL,
        [name] nvarchar(100) NOT NULL,
        [is_active] int NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_production_destination_types] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_production_destination_types_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_production_destination_types_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_production_destination_types_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502050000_AddWellProductionDestinationTypes'
)
BEGIN
    CREATE INDEX [IX_well_production_destination_types_created_by] ON [well_production_destination_types] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502050000_AddWellProductionDestinationTypes'
)
BEGIN
    CREATE INDEX [IX_well_production_destination_types_updated_by] ON [well_production_destination_types] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502050000_AddWellProductionDestinationTypes'
)
BEGIN
    CREATE INDEX [IX_well_production_destination_types_deleted_by] ON [well_production_destination_types] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502050000_AddWellProductionDestinationTypes'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260502050000_AddWellProductionDestinationTypes', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502060000_AddWellTypes'
)
BEGIN
    CREATE TABLE [well_types] (
        [id] uniqueidentifier NOT NULL,
        [name] nvarchar(100) NOT NULL,
        [is_active] int NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_types] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_types_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_types_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_types_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502060000_AddWellTypes'
)
BEGIN
    CREATE INDEX [IX_well_types_created_by] ON [well_types] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502060000_AddWellTypes'
)
BEGIN
    CREATE INDEX [IX_well_types_updated_by] ON [well_types] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502060000_AddWellTypes'
)
BEGIN
    CREATE INDEX [IX_well_types_deleted_by] ON [well_types] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502060000_AddWellTypes'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260502060000_AddWellTypes', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502070000_AddWellZones'
)
BEGIN
    CREATE TABLE [well_zones] (
        [id] uniqueidentifier NOT NULL,
        [name] nvarchar(100) NOT NULL,
        [is_active] int NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_zones] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_zones_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_zones_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_zones_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502070000_AddWellZones'
)
BEGIN
    CREATE INDEX [IX_well_zones_created_by] ON [well_zones] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502070000_AddWellZones'
)
BEGIN
    CREATE INDEX [IX_well_zones_updated_by] ON [well_zones] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502070000_AddWellZones'
)
BEGIN
    CREATE INDEX [IX_well_zones_deleted_by] ON [well_zones] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502070000_AddWellZones'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260502070000_AddWellZones', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502080000_AddWells'
)
BEGIN
    CREATE TABLE [wells] (
        [id] uniqueidentifier NOT NULL,
        [location_id] uniqueidentifier NOT NULL,
        [well_id] nvarchar(100) NOT NULL,
        [field_id] uniqueidentifier NOT NULL,
        [zone_id] uniqueidentifier NOT NULL,
        [area_id] uniqueidentifier NOT NULL,
        [status] nvarchar(20) NULL,
        [production_destination_type_id] uniqueidentifier NOT NULL,
        [production_destination_name] nvarchar(255) NULL,
        [production_start_date] datetime2 NULL,
        [type_id] uniqueidentifier NOT NULL,
        [lifting_type_id] uniqueidentifier NOT NULL,
        [production_target_oil] float NULL,
        [production_target_gas] float NULL,
        [pic] uniqueidentifier NULL,
        [remarks] text NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_wells] PRIMARY KEY ([id]),
        CONSTRAINT [FK_wells_well_areas_area_id] FOREIGN KEY ([area_id]) REFERENCES [well_areas] ([id]),
        CONSTRAINT [FK_wells_well_fields_field_id] FOREIGN KEY ([field_id]) REFERENCES [well_fields] ([id]),
        CONSTRAINT [FK_wells_well_lifting_types_lifting_type_id] FOREIGN KEY ([lifting_type_id]) REFERENCES [well_lifting_types] ([id]),
        CONSTRAINT [FK_wells_well_locations_location_id] FOREIGN KEY ([location_id]) REFERENCES [well_locations] ([id]),
        CONSTRAINT [FK_wells_well_production_destination_types_production_destination_type_id] FOREIGN KEY ([production_destination_type_id]) REFERENCES [well_production_destination_types] ([id]),
        CONSTRAINT [FK_wells_well_types_type_id] FOREIGN KEY ([type_id]) REFERENCES [well_types] ([id]),
        CONSTRAINT [FK_wells_well_zones_zone_id] FOREIGN KEY ([zone_id]) REFERENCES [well_zones] ([id]),
        CONSTRAINT [FK_wells_users_pic] FOREIGN KEY ([pic]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_wells_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_wells_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_wells_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502080000_AddWells'
)
BEGIN
    CREATE INDEX [IX_wells_area_id] ON [wells] ([area_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502080000_AddWells'
)
BEGIN
    CREATE INDEX [IX_wells_created_by] ON [wells] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502080000_AddWells'
)
BEGIN
    CREATE INDEX [IX_wells_deleted_by] ON [wells] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502080000_AddWells'
)
BEGIN
    CREATE INDEX [IX_wells_field_id] ON [wells] ([field_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502080000_AddWells'
)
BEGIN
    CREATE INDEX [IX_wells_lifting_type_id] ON [wells] ([lifting_type_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502080000_AddWells'
)
BEGIN
    CREATE INDEX [IX_wells_location_id] ON [wells] ([location_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502080000_AddWells'
)
BEGIN
    CREATE INDEX [IX_wells_pic] ON [wells] ([pic]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502080000_AddWells'
)
BEGIN
    CREATE INDEX [IX_wells_production_destination_type_id] ON [wells] ([production_destination_type_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502080000_AddWells'
)
BEGIN
    CREATE INDEX [IX_wells_type_id] ON [wells] ([type_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502080000_AddWells'
)
BEGIN
    CREATE INDEX [IX_wells_updated_by] ON [wells] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502080000_AddWells'
)
BEGIN
    CREATE INDEX [IX_wells_zone_id] ON [wells] ([zone_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260502080000_AddWells'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260502080000_AddWells', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507000000_AddWellCompressorDestinations'
)
BEGIN
    CREATE TABLE [well_compressor_destinations] (
        [id] uniqueidentifier NOT NULL,
        [name] nvarchar(100) NOT NULL,
        [plant_id] uniqueidentifier NOT NULL,
        [is_active] int NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_compressor_destinations] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_compressor_destinations_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_compressor_destinations_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_compressor_destinations_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507000000_AddWellCompressorDestinations'
)
BEGIN
    CREATE INDEX [IX_well_compressor_destinations_created_by] ON [well_compressor_destinations] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507000000_AddWellCompressorDestinations'
)
BEGIN
    CREATE INDEX [IX_well_compressor_destinations_updated_by] ON [well_compressor_destinations] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507000000_AddWellCompressorDestinations'
)
BEGIN
    CREATE INDEX [IX_well_compressor_destinations_deleted_by] ON [well_compressor_destinations] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507000000_AddWellCompressorDestinations'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260507000000_AddWellCompressorDestinations', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_project_approvers_projects_id') ALTER TABLE project_approvers DROP CONSTRAINT FK_project_approvers_projects_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_role_approval_tierings_roles_RoleId1') ALTER TABLE role_approval_tierings DROP CONSTRAINT FK_role_approval_tierings_roles_RoleId1;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_well_areas_users_created_by') ALTER TABLE well_areas DROP CONSTRAINT FK_well_areas_users_created_by;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_well_compressor_destinations_users_created_by') ALTER TABLE well_compressor_destinations DROP CONSTRAINT FK_well_compressor_destinations_users_created_by;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_well_fields_users_created_by') ALTER TABLE well_fields DROP CONSTRAINT FK_well_fields_users_created_by;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_well_lifting_types_users_created_by') ALTER TABLE well_lifting_types DROP CONSTRAINT FK_well_lifting_types_users_created_by;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_well_locations_users_created_by') ALTER TABLE well_locations DROP CONSTRAINT FK_well_locations_users_created_by;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_well_plants_users_created_by') ALTER TABLE well_plants DROP CONSTRAINT FK_well_plants_users_created_by;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_well_production_destination_types_users_created_by') ALTER TABLE well_production_destination_types DROP CONSTRAINT FK_well_production_destination_types_users_created_by;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_well_types_users_created_by') ALTER TABLE well_types DROP CONSTRAINT FK_well_types_users_created_by;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_well_zones_users_created_by') ALTER TABLE well_zones DROP CONSTRAINT FK_well_zones_users_created_by;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_users_created_by') ALTER TABLE wells DROP CONSTRAINT FK_wells_users_created_by;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_areas_area_id') ALTER TABLE wells DROP CONSTRAINT FK_wells_well_areas_area_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_fields_field_id') ALTER TABLE wells DROP CONSTRAINT FK_wells_well_fields_field_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_lifting_types_lifting_type_id') ALTER TABLE wells DROP CONSTRAINT FK_wells_well_lifting_types_lifting_type_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_locations_location_id') ALTER TABLE wells DROP CONSTRAINT FK_wells_well_locations_location_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_production_destination_types_production_destination_type_id') ALTER TABLE wells DROP CONSTRAINT FK_wells_well_production_destination_types_production_destination_type_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_types_type_id') ALTER TABLE wells DROP CONSTRAINT FK_wells_well_types_type_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_zones_zone_id') ALTER TABLE wells DROP CONSTRAINT FK_wells_well_zones_zone_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_role_approval_tierings_RoleId1' AND object_id = OBJECT_ID('role_approval_tierings')) DROP INDEX IX_role_approval_tierings_RoleId1 ON role_approval_tierings;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('role_approval_tierings') AND name = 'RoleId1') ALTER TABLE role_approval_tierings DROP COLUMN RoleId1;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    DECLARE @var32 sysname;
    SELECT @var32 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[wells]') AND [c].[name] = N'well_id');
    IF @var32 IS NOT NULL EXEC(N'ALTER TABLE [wells] DROP CONSTRAINT [' + @var32 + '];');
    ALTER TABLE [wells] ALTER COLUMN [well_id] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    DECLARE @var33 sysname;
    SELECT @var33 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_zones]') AND [c].[name] = N'name');
    IF @var33 IS NOT NULL EXEC(N'ALTER TABLE [well_zones] DROP CONSTRAINT [' + @var33 + '];');
    ALTER TABLE [well_zones] ALTER COLUMN [name] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    DECLARE @var34 sysname;
    SELECT @var34 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_types]') AND [c].[name] = N'name');
    IF @var34 IS NOT NULL EXEC(N'ALTER TABLE [well_types] DROP CONSTRAINT [' + @var34 + '];');
    ALTER TABLE [well_types] ALTER COLUMN [name] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    DECLARE @var35 sysname;
    SELECT @var35 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_production_destination_types]') AND [c].[name] = N'name');
    IF @var35 IS NOT NULL EXEC(N'ALTER TABLE [well_production_destination_types] DROP CONSTRAINT [' + @var35 + '];');
    ALTER TABLE [well_production_destination_types] ALTER COLUMN [name] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    DECLARE @var36 sysname;
    SELECT @var36 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_plants]') AND [c].[name] = N'name');
    IF @var36 IS NOT NULL EXEC(N'ALTER TABLE [well_plants] DROP CONSTRAINT [' + @var36 + '];');
    ALTER TABLE [well_plants] ALTER COLUMN [name] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    DECLARE @var37 sysname;
    SELECT @var37 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_locations]') AND [c].[name] = N'updated_at');
    IF @var37 IS NOT NULL EXEC(N'ALTER TABLE [well_locations] DROP CONSTRAINT [' + @var37 + '];');
    ALTER TABLE [well_locations] ALTER COLUMN [updated_at] datetime2 NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    DECLARE @var38 sysname;
    SELECT @var38 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_locations]') AND [c].[name] = N'name');
    IF @var38 IS NOT NULL EXEC(N'ALTER TABLE [well_locations] DROP CONSTRAINT [' + @var38 + '];');
    ALTER TABLE [well_locations] ALTER COLUMN [name] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    DECLARE @var39 sysname;
    SELECT @var39 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_locations]') AND [c].[name] = N'deleted_at');
    IF @var39 IS NOT NULL EXEC(N'ALTER TABLE [well_locations] DROP CONSTRAINT [' + @var39 + '];');
    ALTER TABLE [well_locations] ALTER COLUMN [deleted_at] datetime2 NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    DECLARE @var40 sysname;
    SELECT @var40 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_locations]') AND [c].[name] = N'created_at');
    IF @var40 IS NOT NULL EXEC(N'ALTER TABLE [well_locations] DROP CONSTRAINT [' + @var40 + '];');
    ALTER TABLE [well_locations] ALTER COLUMN [created_at] datetime2 NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    DECLARE @var41 sysname;
    SELECT @var41 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_lifting_types]') AND [c].[name] = N'name');
    IF @var41 IS NOT NULL EXEC(N'ALTER TABLE [well_lifting_types] DROP CONSTRAINT [' + @var41 + '];');
    ALTER TABLE [well_lifting_types] ALTER COLUMN [name] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    DECLARE @var42 sysname;
    SELECT @var42 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_fields]') AND [c].[name] = N'name');
    IF @var42 IS NOT NULL EXEC(N'ALTER TABLE [well_fields] DROP CONSTRAINT [' + @var42 + '];');
    ALTER TABLE [well_fields] ALTER COLUMN [name] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    DECLARE @var43 sysname;
    SELECT @var43 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_compressor_destinations]') AND [c].[name] = N'name');
    IF @var43 IS NOT NULL EXEC(N'ALTER TABLE [well_compressor_destinations] DROP CONSTRAINT [' + @var43 + '];');
    ALTER TABLE [well_compressor_destinations] ALTER COLUMN [name] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    DECLARE @var44 sysname;
    SELECT @var44 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_areas]') AND [c].[name] = N'name');
    IF @var44 IS NOT NULL EXEC(N'ALTER TABLE [well_areas] DROP CONSTRAINT [' + @var44 + '];');
    ALTER TABLE [well_areas] ALTER COLUMN [name] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('users') AND name = 'retina_id') ALTER TABLE users ADD retina_id nvarchar(255) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    DECLARE @var45 sysname;
    SELECT @var45 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[rkaps]') AND [c].[name] = N'created_by');
    IF @var45 IS NOT NULL EXEC(N'ALTER TABLE [rkaps] DROP CONSTRAINT [' + @var45 + '];');
    ALTER TABLE [rkaps] ALTER COLUMN [created_by] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    DECLARE @var46 sysname;
    SELECT @var46 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[projects]') AND [c].[name] = N'created_by');
    IF @var46 IS NOT NULL EXEC(N'ALTER TABLE [projects] DROP CONSTRAINT [' + @var46 + '];');
    ALTER TABLE [projects] ALTER COLUMN [created_by] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    DECLARE @var47 sysname;
    SELECT @var47 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[fields]') AND [c].[name] = N'updated_by');
    IF @var47 IS NOT NULL EXEC(N'ALTER TABLE [fields] DROP CONSTRAINT [' + @var47 + '];');
    ALTER TABLE [fields] ALTER COLUMN [updated_by] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    DECLARE @var48 sysname;
    SELECT @var48 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[fields]') AND [c].[name] = N'updated_at');
    IF @var48 IS NOT NULL EXEC(N'ALTER TABLE [fields] DROP CONSTRAINT [' + @var48 + '];');
    ALTER TABLE [fields] ALTER COLUMN [updated_at] datetime2 NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    DECLARE @var49 sysname;
    SELECT @var49 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[fields]') AND [c].[name] = N'created_by');
    IF @var49 IS NOT NULL EXEC(N'ALTER TABLE [fields] DROP CONSTRAINT [' + @var49 + '];');
    ALTER TABLE [fields] ALTER COLUMN [created_by] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    CREATE TABLE [phantom_well_prod] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [field] nvarchar(40) NULL,
        [structure] nvarchar(4000) NULL,
        [well] nvarchar(40) NULL,
        [well_location] nvarchar(80) NULL,
        [prod_date] datetime2 NULL,
        [prod_hours] float NULL,
        [gross] float NULL,
        [oil] float NULL,
        [gas] float NULL,
        [water] float NULL,
        [water_cut] float NULL,
        [artificial_lift] nvarchar(70) NULL,
        [production_test] datetime2 NULL,
        [thp] float NULL,
        [flp] float NULL,
        [casing_pressure] float NULL,
        [separator_pressure] float NULL,
        [bean_choke] nvarchar(100) NULL,
        [temperature] float NULL,
        [stroke_length] float NULL,
        [stroke_per_minutes] float NULL,
        [ampere] nvarchar(10) NULL,
        [power] nvarchar(20) NULL,
        [pump_size] nvarchar(20) NULL,
        [pump_efficiency] decimal(10,0) NULL,
        [pump_intake_depth] float NULL,
        [submerging] float NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_phantom_well_prod] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    CREATE TABLE [phantom_well_sonolog] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [field] nvarchar(40) NULL,
        [structure] nvarchar(80) NULL,
        [well] nvarchar(80) NULL,
        [sonolog_test_date] datetime2 NULL,
        [dynamic_fluid_level] nvarchar(20) NULL,
        [static_fluid_level] nvarchar(20) NULL,
        [pump_intake_depth] float NULL,
        [total_gaseous_liq_column] float NULL,
        [submergen_gas] float NULL,
        [casing_pressure] float NULL,
        [tubing_pressure] nvarchar(20) NULL,
        [gas_flow] float NULL,
        [pbhp] float NULL,
        [sbhp] float NULL,
        [pump_type] nvarchar(100) NULL,
        [stroke_length] float NULL,
        [stroke_per_minutes] float NULL,
        [pump_frequency] float NULL,
        [time] nvarchar(10) NULL,
        [remark] nvarchar(4000) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_phantom_well_sonolog] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_project_approvers_project_id' AND object_id = OBJECT_ID('project_approvers')) CREATE INDEX IX_project_approvers_project_id ON project_approvers(project_id);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_casbin_rule_ptype_v0' AND object_id = OBJECT_ID('casbin_rule')) CREATE INDEX IX_casbin_rule_ptype_v0 ON casbin_rule(ptype, v0);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_casbin_rule_ptype_v0_v1' AND object_id = OBJECT_ID('casbin_rule')) CREATE INDEX IX_casbin_rule_ptype_v0_v1 ON casbin_rule(ptype, v0, v1);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_project_approvers_projects_project_id') ALTER TABLE project_approvers ADD CONSTRAINT FK_project_approvers_projects_project_id FOREIGN KEY (project_id) REFERENCES projects(id);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_well_areas_users_created_by') ALTER TABLE well_areas ADD CONSTRAINT FK_well_areas_users_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_well_compressor_destinations_users_created_by') ALTER TABLE well_compressor_destinations ADD CONSTRAINT FK_well_compressor_destinations_users_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_well_fields_users_created_by') ALTER TABLE well_fields ADD CONSTRAINT FK_well_fields_users_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_well_lifting_types_users_created_by') ALTER TABLE well_lifting_types ADD CONSTRAINT FK_well_lifting_types_users_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_well_locations_users_created_by') ALTER TABLE well_locations ADD CONSTRAINT FK_well_locations_users_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_well_plants_users_created_by') ALTER TABLE well_plants ADD CONSTRAINT FK_well_plants_users_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_well_production_destination_types_users_created_by') ALTER TABLE well_production_destination_types ADD CONSTRAINT FK_well_production_destination_types_users_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_well_types_users_created_by') ALTER TABLE well_types ADD CONSTRAINT FK_well_types_users_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_well_zones_users_created_by') ALTER TABLE well_zones ADD CONSTRAINT FK_well_zones_users_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_users_created_by') ALTER TABLE wells ADD CONSTRAINT FK_wells_users_created_by FOREIGN KEY (created_by) REFERENCES users(id);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_areas_area_id') ALTER TABLE wells ADD CONSTRAINT FK_wells_well_areas_area_id FOREIGN KEY (area_id) REFERENCES well_areas(id);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_fields_field_id') ALTER TABLE wells ADD CONSTRAINT FK_wells_well_fields_field_id FOREIGN KEY (field_id) REFERENCES well_fields(id);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_lifting_types_lifting_type_id') ALTER TABLE wells ADD CONSTRAINT FK_wells_well_lifting_types_lifting_type_id FOREIGN KEY (lifting_type_id) REFERENCES well_lifting_types(id);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_locations_location_id') ALTER TABLE wells ADD CONSTRAINT FK_wells_well_locations_location_id FOREIGN KEY (location_id) REFERENCES well_locations(id);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_production_destination_types_production_destination_type_id') ALTER TABLE wells ADD CONSTRAINT FK_wells_well_production_destination_types_production_destination_type_id FOREIGN KEY (production_destination_type_id) REFERENCES well_production_destination_types(id);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_types_type_id') ALTER TABLE wells ADD CONSTRAINT FK_wells_well_types_type_id FOREIGN KEY (type_id) REFERENCES well_types(id);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_zones_zone_id') ALTER TABLE wells ADD CONSTRAINT FK_wells_well_zones_zone_id FOREIGN KEY (zone_id) REFERENCES well_zones(id);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260507005722_SyncModelSnapshot'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260507005722_SyncModelSnapshot', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260511120928_AddWellPlantAndCompressorDestination'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_production_destination_types_production_destination_type_id') ALTER TABLE wells DROP CONSTRAINT FK_wells_well_production_destination_types_production_destination_type_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260511120928_AddWellPlantAndCompressorDestination'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_types_type_id') ALTER TABLE wells DROP CONSTRAINT FK_wells_well_types_type_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260511120928_AddWellPlantAndCompressorDestination'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_wells_type_id' AND object_id = OBJECT_ID('wells')) DROP INDEX IX_wells_type_id ON wells;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260511120928_AddWellPlantAndCompressorDestination'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('wells') AND name = 'type_id') EXEC sp_rename 'wells.type_id', 'well_type_id', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260511120928_AddWellPlantAndCompressorDestination'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_wells_well_type_id' AND object_id = OBJECT_ID('wells')) CREATE INDEX IX_wells_well_type_id ON wells(well_type_id);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260511120928_AddWellPlantAndCompressorDestination'
)
BEGIN
    DECLARE @var50 sysname;
    SELECT @var50 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[wells]') AND [c].[name] = N'production_destination_type_id');
    IF @var50 IS NOT NULL EXEC(N'ALTER TABLE [wells] DROP CONSTRAINT [' + @var50 + '];');
    ALTER TABLE [wells] ALTER COLUMN [production_destination_type_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260511120928_AddWellPlantAndCompressorDestination'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('wells') AND name = 'compressor_destination_id') ALTER TABLE wells ADD compressor_destination_id uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260511120928_AddWellPlantAndCompressorDestination'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_wells_compressor_destination_id' AND object_id = OBJECT_ID('wells')) CREATE INDEX IX_wells_compressor_destination_id ON wells(compressor_destination_id);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260511120928_AddWellPlantAndCompressorDestination'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('wells') AND name = 'plant_id') ALTER TABLE wells ADD plant_id uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260511120928_AddWellPlantAndCompressorDestination'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_wells_plant_id' AND object_id = OBJECT_ID('wells')) CREATE INDEX IX_wells_plant_id ON wells(plant_id);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260511120928_AddWellPlantAndCompressorDestination'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_compressor_destinations_compressor_destination_id') ALTER TABLE wells ADD CONSTRAINT FK_wells_well_compressor_destinations_compressor_destination_id FOREIGN KEY (compressor_destination_id) REFERENCES well_compressor_destinations(id);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260511120928_AddWellPlantAndCompressorDestination'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_plants_plant_id') ALTER TABLE wells ADD CONSTRAINT FK_wells_well_plants_plant_id FOREIGN KEY (plant_id) REFERENCES well_plants(id);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260511120928_AddWellPlantAndCompressorDestination'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_production_destination_types_production_destination_type_id') ALTER TABLE wells ADD CONSTRAINT FK_wells_well_production_destination_types_production_destination_type_id FOREIGN KEY (production_destination_type_id) REFERENCES well_production_destination_types(id);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260511120928_AddWellPlantAndCompressorDestination'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_wells_well_types_well_type_id') ALTER TABLE wells ADD CONSTRAINT FK_wells_well_types_well_type_id FOREIGN KEY (well_type_id) REFERENCES well_types(id) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260511120928_AddWellPlantAndCompressorDestination'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260511120928_AddWellPlantAndCompressorDestination', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516024131_AddWellHistoriesPhss'
)
BEGIN
    CREATE TABLE [well_detail_phss] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [field] nvarchar(40) NULL,
        [structure] nvarchar(4000) NULL,
        [well] nvarchar(40) NULL,
        [well_location] nvarchar(80) NULL,
        [prod_date] datetime2 NULL,
        [oil] float NULL,
        [gas_out] float NULL,
        [gas_in] float NULL,
        [water_cut] float NULL,
        [gross] float NULL,
        [fthp] float NULL,
        [flp] float NULL,
        [temperature] float NULL,
        [choke_size] nvarchar(100) NULL,
        [mtu_date] datetime2 NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_detail_phss] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516024131_AddWellHistoriesPhss'
)
BEGIN
    CREATE INDEX [IX_well_detail_phss_well] ON [well_detail_phss] ([well]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516024131_AddWellHistoriesPhss'
)
BEGIN
    CREATE INDEX [IX_well_detail_phss_prod_date] ON [well_detail_phss] ([prod_date]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516024131_AddWellHistoriesPhss'
)
BEGIN
    CREATE INDEX [IX_well_detail_phss_created_by] ON [well_detail_phss] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516024131_AddWellHistoriesPhss'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260516024131_AddWellHistoriesPhss', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516070621_EnhanceWellHistoriesPhss'
)
BEGIN
    UPDATE well_detail_phss SET choke_size = NULL WHERE choke_size IS NOT NULL AND TRY_CAST(choke_size AS FLOAT) IS NULL
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516070621_EnhanceWellHistoriesPhss'
)
BEGIN
    DECLARE @var51 sysname;
    SELECT @var51 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_detail_phss]') AND [c].[name] = N'choke_size');
    IF @var51 IS NOT NULL EXEC(N'ALTER TABLE [well_detail_phss] DROP CONSTRAINT [' + @var51 + '];');
    ALTER TABLE [well_detail_phss] ALTER COLUMN [choke_size] float NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516070621_EnhanceWellHistoriesPhss'
)
BEGIN
    ALTER TABLE [well_detail_phss] ADD [zone_id] nvarchar(40) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516070621_EnhanceWellHistoriesPhss'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260516070621_EnhanceWellHistoriesPhss', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516074942_AddWellHistoriesPep'
)
BEGIN
    CREATE TABLE [well_detail_pep] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [well] nvarchar(255) NULL,
        [zone_id] nvarchar(40) NULL,
        [prod_date] datetime2 NULL,
        [oil] float NULL,
        [gas_out] float NULL,
        [gas_in] float NULL,
        [water_cut] float NULL,
        [gross] float NULL,
        [fthp] float NULL,
        [flp] float NULL,
        [temperature] float NULL,
        [choke_size] float NULL,
        [ampere] float NULL,
        [stroke_length] float NULL,
        [stroke_per_minute] float NULL,
        [latest_production_test] datetime2 NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_detail_pep] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516074942_AddWellHistoriesPep'
)
BEGIN
    CREATE INDEX [IX_well_detail_pep_well] ON [well_detail_pep] ([well]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516074942_AddWellHistoriesPep'
)
BEGIN
    CREATE INDEX [IX_well_detail_pep_prod_date] ON [well_detail_pep] ([prod_date]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516074942_AddWellHistoriesPep'
)
BEGIN
    CREATE INDEX [IX_well_detail_pep_created_by] ON [well_detail_pep] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516074942_AddWellHistoriesPep'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260516074942_AddWellHistoriesPep', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516082716_RenameWellDetailTables'
)
BEGIN
    ALTER TABLE [well_detail_phss] DROP CONSTRAINT [PK_well_detail_phss];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516082716_RenameWellDetailTables'
)
BEGIN
    ALTER TABLE [well_detail_pep] DROP CONSTRAINT [PK_well_detail_pep];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516082716_RenameWellDetailTables'
)
BEGIN
    EXEC sp_rename N'[well_detail_phss]', N'well_histories_phss', 'OBJECT';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516082716_RenameWellDetailTables'
)
BEGIN
    EXEC sp_rename N'[well_detail_pep]', N'well_histories_pep', 'OBJECT';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516082716_RenameWellDetailTables'
)
BEGIN
    EXEC sp_rename N'[well_histories_phss].[IX_well_detail_phss_well]', N'IX_well_histories_phss_well', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516082716_RenameWellDetailTables'
)
BEGIN
    EXEC sp_rename N'[well_histories_phss].[IX_well_detail_phss_prod_date]', N'IX_well_histories_phss_prod_date', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516082716_RenameWellDetailTables'
)
BEGIN
    EXEC sp_rename N'[well_histories_phss].[IX_well_detail_phss_created_by]', N'IX_well_histories_phss_created_by', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516082716_RenameWellDetailTables'
)
BEGIN
    EXEC sp_rename N'[well_histories_pep].[IX_well_detail_pep_well]', N'IX_well_histories_pep_well', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516082716_RenameWellDetailTables'
)
BEGIN
    EXEC sp_rename N'[well_histories_pep].[IX_well_detail_pep_prod_date]', N'IX_well_histories_pep_prod_date', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516082716_RenameWellDetailTables'
)
BEGIN
    EXEC sp_rename N'[well_histories_pep].[IX_well_detail_pep_created_by]', N'IX_well_histories_pep_created_by', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516082716_RenameWellDetailTables'
)
BEGIN
    ALTER TABLE [well_histories_phss] ADD CONSTRAINT [PK_well_histories_phss] PRIMARY KEY ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516082716_RenameWellDetailTables'
)
BEGIN
    ALTER TABLE [well_histories_pep] ADD CONSTRAINT [PK_well_histories_pep] PRIMARY KEY ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260516082716_RenameWellDetailTables'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260516082716_RenameWellDetailTables', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260517024923_SeedWellFieldPep'
)
BEGIN
    INSERT INTO well_fields (id, name, is_active, created_at, created_by)
    VALUES (NEWID(), 'PEP', 1, GETDATE(), '02a1922b-5cf1-471a-b735-fb2ceb2bbd72')
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260517024923_SeedWellFieldPep'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260517024923_SeedWellFieldPep', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260517033712_AddPhantomWellSonologIndexes'
)
BEGIN
    CREATE INDEX [IX_phantom_well_sonolog_created_by] ON [phantom_well_sonolog] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260517033712_AddPhantomWellSonologIndexes'
)
BEGIN
    CREATE INDEX [IX_phantom_well_sonolog_sonolog_test_date] ON [phantom_well_sonolog] ([sonolog_test_date]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260517033712_AddPhantomWellSonologIndexes'
)
BEGIN
    CREATE INDEX [IX_phantom_well_sonolog_well] ON [phantom_well_sonolog] ([well]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260517033712_AddPhantomWellSonologIndexes'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260517033712_AddPhantomWellSonologIndexes', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260518001440_SeedWellProductionDestinationTypes'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM well_production_destination_types WHERE name = 'Tank')
      INSERT INTO well_production_destination_types (id, name, is_active, created_at, created_by)
      VALUES (NEWID(), 'Tank', 1, GETDATE(), '02a1922b-5cf1-471a-b735-fb2ceb2bbd72');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260518001440_SeedWellProductionDestinationTypes'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM well_production_destination_types WHERE name = 'Pipeline')
      INSERT INTO well_production_destination_types (id, name, is_active, created_at, created_by)
      VALUES (NEWID(), 'Pipeline', 1, GETDATE(), '02a1922b-5cf1-471a-b735-fb2ceb2bbd72');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260518001440_SeedWellProductionDestinationTypes'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM well_production_destination_types WHERE name = 'Manifold')
      INSERT INTO well_production_destination_types (id, name, is_active, created_at, created_by)
      VALUES (NEWID(), 'Manifold', 1, GETDATE(), '02a1922b-5cf1-471a-b735-fb2ceb2bbd72');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260518001440_SeedWellProductionDestinationTypes'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM well_production_destination_types WHERE name = 'Separator')
      INSERT INTO well_production_destination_types (id, name, is_active, created_at, created_by)
      VALUES (NEWID(), 'Separator', 1, GETDATE(), '02a1922b-5cf1-471a-b735-fb2ceb2bbd72');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260518001440_SeedWellProductionDestinationTypes'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260518001440_SeedWellProductionDestinationTypes', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260518095113_AddEntitySaDocument'
)
BEGIN
    CREATE TABLE [service_acceptance_documents] (
        [id] uniqueidentifier NOT NULL,
        [service_acceptance_id] uniqueidentifier NOT NULL,
        [file_name] nvarchar(300) NULL,
        [file_type] nvarchar(300) NULL,
        [file_size] nvarchar(40) NULL,
        [file_url] text NULL,
        [description] nvarchar(510) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_service_acceptance_documents] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260518095113_AddEntitySaDocument'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260518095113_AddEntitySaDocument', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    CREATE TABLE [well_zone_assignments] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [well_id] uniqueidentifier NOT NULL,
        [well_zone_id] uniqueidentifier NOT NULL,
        [status] nvarchar(20) NULL,
        [production_start_date] datetime2 NULL,
        [production_target_gas] float NULL,
        [production_target_oil] float NULL,
        [compressor_destination_id] uniqueidentifier NULL,
        [production_destination_type_id] uniqueidentifier NULL,
        [production_destination_name] nvarchar(255) NULL,
        [remarks] text NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_zone_assignments] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_zone_assignments_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_zone_assignments_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_zone_assignments_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_zone_assignments_well_compressor_destinations_compressor_destination_id] FOREIGN KEY ([compressor_destination_id]) REFERENCES [well_compressor_destinations] ([id]),
        CONSTRAINT [FK_well_zone_assignments_well_production_destination_types_production_destination_type_id] FOREIGN KEY ([production_destination_type_id]) REFERENCES [well_production_destination_types] ([id]),
        CONSTRAINT [FK_well_zone_assignments_well_zones_well_zone_id] FOREIGN KEY ([well_zone_id]) REFERENCES [well_zones] ([id]),
        CONSTRAINT [FK_well_zone_assignments_wells_well_id] FOREIGN KEY ([well_id]) REFERENCES [wells] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    CREATE INDEX [IX_well_zone_assignments_compressor_destination_id] ON [well_zone_assignments] ([compressor_destination_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    CREATE INDEX [IX_well_zone_assignments_created_by] ON [well_zone_assignments] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    CREATE INDEX [IX_well_zone_assignments_deleted_by] ON [well_zone_assignments] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    CREATE INDEX [IX_well_zone_assignments_production_destination_type_id] ON [well_zone_assignments] ([production_destination_type_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    CREATE INDEX [IX_well_zone_assignments_updated_by] ON [well_zone_assignments] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    CREATE INDEX [IX_well_zone_assignments_well_id] ON [well_zone_assignments] ([well_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    CREATE INDEX [IX_well_zone_assignments_well_zone_id] ON [well_zone_assignments] ([well_zone_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    INSERT INTO well_zone_assignments (
        id, well_id, well_zone_id, status,
        production_start_date, production_target_gas, production_target_oil,
        compressor_destination_id, production_destination_type_id, production_destination_name,
        remarks,
        created_at, created_by, updated_at, updated_by, deleted_at, deleted_by)
    SELECT
        id, id, zone_id, status,
        production_start_date, production_target_gas, production_target_oil,
        compressor_destination_id, production_destination_type_id, production_destination_name,
        remarks,
        created_at, created_by, updated_at, updated_by, deleted_at, deleted_by
    FROM wells
    WHERE zone_id IS NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_wells_well_id_zone_id' AND object_id = OBJECT_ID('dbo.wells'))
        DROP INDEX IX_wells_well_id_zone_id ON dbo.wells;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    ALTER TABLE [wells] DROP CONSTRAINT [FK_wells_well_compressor_destinations_compressor_destination_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    ALTER TABLE [wells] DROP CONSTRAINT [FK_wells_well_production_destination_types_production_destination_type_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    ALTER TABLE [wells] DROP CONSTRAINT [FK_wells_well_zones_zone_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    DROP INDEX [IX_wells_compressor_destination_id] ON [wells];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    DROP INDEX [IX_wells_production_destination_type_id] ON [wells];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    DROP INDEX [IX_wells_zone_id] ON [wells];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    DECLARE @var52 sysname;
    SELECT @var52 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[wells]') AND [c].[name] = N'compressor_destination_id');
    IF @var52 IS NOT NULL EXEC(N'ALTER TABLE [wells] DROP CONSTRAINT [' + @var52 + '];');
    ALTER TABLE [wells] DROP COLUMN [compressor_destination_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    DECLARE @var53 sysname;
    SELECT @var53 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[wells]') AND [c].[name] = N'production_destination_name');
    IF @var53 IS NOT NULL EXEC(N'ALTER TABLE [wells] DROP CONSTRAINT [' + @var53 + '];');
    ALTER TABLE [wells] DROP COLUMN [production_destination_name];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    DECLARE @var54 sysname;
    SELECT @var54 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[wells]') AND [c].[name] = N'production_destination_type_id');
    IF @var54 IS NOT NULL EXEC(N'ALTER TABLE [wells] DROP CONSTRAINT [' + @var54 + '];');
    ALTER TABLE [wells] DROP COLUMN [production_destination_type_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    DECLARE @var55 sysname;
    SELECT @var55 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[wells]') AND [c].[name] = N'production_start_date');
    IF @var55 IS NOT NULL EXEC(N'ALTER TABLE [wells] DROP CONSTRAINT [' + @var55 + '];');
    ALTER TABLE [wells] DROP COLUMN [production_start_date];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    DECLARE @var56 sysname;
    SELECT @var56 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[wells]') AND [c].[name] = N'production_target_gas');
    IF @var56 IS NOT NULL EXEC(N'ALTER TABLE [wells] DROP CONSTRAINT [' + @var56 + '];');
    ALTER TABLE [wells] DROP COLUMN [production_target_gas];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    DECLARE @var57 sysname;
    SELECT @var57 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[wells]') AND [c].[name] = N'production_target_oil');
    IF @var57 IS NOT NULL EXEC(N'ALTER TABLE [wells] DROP CONSTRAINT [' + @var57 + '];');
    ALTER TABLE [wells] DROP COLUMN [production_target_oil];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    DECLARE @var58 sysname;
    SELECT @var58 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[wells]') AND [c].[name] = N'remarks');
    IF @var58 IS NOT NULL EXEC(N'ALTER TABLE [wells] DROP CONSTRAINT [' + @var58 + '];');
    ALTER TABLE [wells] DROP COLUMN [remarks];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    DECLARE @var59 sysname;
    SELECT @var59 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[wells]') AND [c].[name] = N'status');
    IF @var59 IS NOT NULL EXEC(N'ALTER TABLE [wells] DROP CONSTRAINT [' + @var59 + '];');
    ALTER TABLE [wells] DROP COLUMN [status];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    DECLARE @var60 sysname;
    SELECT @var60 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[wells]') AND [c].[name] = N'zone_id');
    IF @var60 IS NOT NULL EXEC(N'ALTER TABLE [wells] DROP CONSTRAINT [' + @var60 + '];');
    ALTER TABLE [wells] DROP COLUMN [zone_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    ;WITH ranked AS (
        SELECT id, well_id,
               ROW_NUMBER() OVER (PARTITION BY well_id ORDER BY created_at ASC, id ASC) AS rn,
               FIRST_VALUE(id) OVER (PARTITION BY well_id ORDER BY created_at ASC, id ASC) AS keeper_id
        FROM wells
        WHERE deleted_at IS NULL
    )
    UPDATE wza
    SET wza.well_id = r.keeper_id,
        wza.updated_at = SYSDATETIME()
    FROM well_zone_assignments wza
    INNER JOIN ranked r ON wza.well_id = r.id
    WHERE r.rn > 1;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    ;WITH ranked AS (
        SELECT id, well_id,
               ROW_NUMBER() OVER (PARTITION BY well_id ORDER BY created_at ASC, id ASC) AS rn
        FROM wells
        WHERE deleted_at IS NULL
    )
    UPDATE wells
    SET deleted_at = SYSDATETIME(),
        deleted_by = COALESCE((SELECT TOP 1 id FROM users ORDER BY created_at), CAST('00000000-0000-0000-0000-000000000000' AS uniqueidentifier))
    FROM wells
    INNER JOIN ranked r ON wells.id = r.id
    WHERE r.rn > 1;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_wells_well_id' AND object_id = OBJECT_ID('dbo.wells'))
        CREATE UNIQUE NONCLUSTERED INDEX IX_wells_well_id
        ON dbo.wells (well_id)
        WHERE deleted_at IS NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_well_zone_assignments_well_id_well_zone_id' AND object_id = OBJECT_ID('dbo.well_zone_assignments'))
        CREATE UNIQUE NONCLUSTERED INDEX IX_well_zone_assignments_well_id_well_zone_id
        ON dbo.well_zone_assignments (well_id, well_zone_id)
        WHERE deleted_at IS NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520011708_RestructureWellsZonesPivot'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260520011708_RestructureWellsZonesPivot', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520022645_MaterializePermissionsAndRoleNullability'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'permissions' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        CREATE TABLE dbo.permissions (
            id int NOT NULL,
            permission_group_id uniqueidentifier NULL,
            name nvarchar(100) NULL,
            description nvarchar(500) NULL,
            created_at datetime2 NOT NULL,
            updated_at datetime2 NULL,
            deleted_at datetime2 NULL,
            CONSTRAINT PK_permissions PRIMARY KEY (id),
            CONSTRAINT FK_permissions_permission_groups FOREIGN KEY (permission_group_id)
                REFERENCES dbo.permission_groups (id)
        );

        CREATE INDEX IX_permissions_permission_group_id ON dbo.permissions (permission_group_id);
    END
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520022645_MaterializePermissionsAndRoleNullability'
)
BEGIN
    IF EXISTS (
        SELECT 1 FROM sys.columns
        WHERE Name = 'created_by'
          AND Object_ID = OBJECT_ID('dbo.roles')
          AND is_nullable = 0
    )
        ALTER TABLE dbo.roles ALTER COLUMN created_by uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520022645_MaterializePermissionsAndRoleNullability'
)
BEGIN
    IF EXISTS (
        SELECT 1 FROM sys.columns
        WHERE Name = 'updated_by'
          AND Object_ID = OBJECT_ID('dbo.roles')
          AND is_nullable = 0
    )
        ALTER TABLE dbo.roles ALTER COLUMN updated_by uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520022645_MaterializePermissionsAndRoleNullability'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260520022645_MaterializePermissionsAndRoleNullability', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520051204_ReplaceWellsLocationFkWithText'
)
BEGIN
    ALTER TABLE [wells] ADD [location] nvarchar(255) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520051204_ReplaceWellsLocationFkWithText'
)
BEGIN
    UPDATE w
    SET w.location = wl.name
    FROM dbo.wells w
    INNER JOIN dbo.well_locations wl ON wl.id = w.location_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520051204_ReplaceWellsLocationFkWithText'
)
BEGIN
    ALTER TABLE [wells] DROP CONSTRAINT [FK_wells_well_locations_location_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520051204_ReplaceWellsLocationFkWithText'
)
BEGIN
    DROP INDEX [IX_wells_location_id] ON [wells];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520051204_ReplaceWellsLocationFkWithText'
)
BEGIN
    DECLARE @var61 sysname;
    SELECT @var61 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[wells]') AND [c].[name] = N'location_id');
    IF @var61 IS NOT NULL EXEC(N'ALTER TABLE [wells] DROP CONSTRAINT [' + @var61 + '];');
    ALTER TABLE [wells] DROP COLUMN [location_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520051204_ReplaceWellsLocationFkWithText'
)
BEGIN
    UPDATE dbo.wells SET location = '' WHERE location IS NULL;
    ALTER TABLE dbo.wells ALTER COLUMN location nvarchar(255) NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260520051204_ReplaceWellsLocationFkWithText'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260520051204_ReplaceWellsLocationFkWithText', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521055634_AddWellCompressorAssignments'
)
BEGIN
    CREATE TABLE [well_compressor_assignments] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [well_id] uniqueidentifier NOT NULL,
        [compressor_destination_id] uniqueidentifier NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_compressor_assignments] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_compressor_assignments_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_well_compressor_assignments_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_well_compressor_assignments_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_well_compressor_assignments_well_compressor_destinations_compressor_destination_id] FOREIGN KEY ([compressor_destination_id]) REFERENCES [well_compressor_destinations] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_well_compressor_assignments_wells_well_id] FOREIGN KEY ([well_id]) REFERENCES [wells] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521055634_AddWellCompressorAssignments'
)
BEGIN
    CREATE INDEX [IX_well_compressor_assignments_compressor_destination_id] ON [well_compressor_assignments] ([compressor_destination_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521055634_AddWellCompressorAssignments'
)
BEGIN
    CREATE INDEX [IX_well_compressor_assignments_created_by] ON [well_compressor_assignments] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521055634_AddWellCompressorAssignments'
)
BEGIN
    CREATE INDEX [IX_well_compressor_assignments_deleted_by] ON [well_compressor_assignments] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521055634_AddWellCompressorAssignments'
)
BEGIN
    CREATE INDEX [IX_well_compressor_assignments_updated_by] ON [well_compressor_assignments] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521055634_AddWellCompressorAssignments'
)
BEGIN
    CREATE INDEX [IX_well_compressor_assignments_well_id] ON [well_compressor_assignments] ([well_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521055634_AddWellCompressorAssignments'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_well_compressor_assignments_well_id_compressor_destination_id' AND object_id = OBJECT_ID('dbo.well_compressor_assignments'))
        CREATE UNIQUE NONCLUSTERED INDEX IX_well_compressor_assignments_well_id_compressor_destination_id
        ON dbo.well_compressor_assignments (well_id, compressor_destination_id)
        WHERE deleted_at IS NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521055634_AddWellCompressorAssignments'
)
BEGIN
    ;WITH src AS (
        SELECT well_id,
               compressor_destination_id,
               MIN(created_at) AS created_at,
               MIN(CAST(created_by AS varchar(36))) AS created_by
        FROM dbo.well_zone_assignments
        WHERE deleted_at IS NULL AND compressor_destination_id IS NOT NULL
        GROUP BY well_id, compressor_destination_id
    )
    INSERT INTO dbo.well_compressor_assignments (id, well_id, compressor_destination_id, created_at, created_by)
    SELECT NEWID(), src.well_id, src.compressor_destination_id, src.created_at, CAST(src.created_by AS uniqueidentifier)
    FROM src;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521055634_AddWellCompressorAssignments'
)
BEGIN
    ALTER TABLE [well_zone_assignments] DROP CONSTRAINT [FK_well_zone_assignments_well_compressor_destinations_compressor_destination_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521055634_AddWellCompressorAssignments'
)
BEGIN
    DROP INDEX [IX_well_zone_assignments_compressor_destination_id] ON [well_zone_assignments];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521055634_AddWellCompressorAssignments'
)
BEGIN
    DECLARE @var62 sysname;
    SELECT @var62 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_zone_assignments]') AND [c].[name] = N'compressor_destination_id');
    IF @var62 IS NOT NULL EXEC(N'ALTER TABLE [well_zone_assignments] DROP CONSTRAINT [' + @var62 + '];');
    ALTER TABLE [well_zone_assignments] DROP COLUMN [compressor_destination_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521055634_AddWellCompressorAssignments'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260521055634_AddWellCompressorAssignments', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521113951_AddWaterToWellHistories'
)
BEGIN
    ALTER TABLE [well_histories_phss] ADD [water] float NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521113951_AddWaterToWellHistories'
)
BEGIN
    ALTER TABLE [well_histories_pep] ADD [water] float NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521113951_AddWaterToWellHistories'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260521113951_AddWaterToWellHistories', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521151023_AddEntityInvoiceAdditionalReductionCost'
)
BEGIN
    ALTER TABLE [invoice_service_acceptances] ADD [InvoiceId1] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521151023_AddEntityInvoiceAdditionalReductionCost'
)
BEGIN
    CREATE TABLE [file_upload_attachments] (
        [id] uniqueidentifier NOT NULL,
        [file_name] nvarchar(150) NOT NULL,
        [file_type] nvarchar(50) NULL,
        [file_size] nvarchar(20) NULL,
        [file_url] nvarchar(max) NULL,
        [description] nvarchar(255) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_file_upload_attachments] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521151023_AddEntityInvoiceAdditionalReductionCost'
)
BEGIN
    CREATE TABLE [invoice_additional_costs] (
        [id] uniqueidentifier NOT NULL,
        [invoice_id] uniqueidentifier NOT NULL,
        [description] nvarchar(100) NULL,
        [cost] decimal(18,4) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NOT NULL,
        [updated_by] uniqueidentifier NOT NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_invoice_additional_costs] PRIMARY KEY ([id]),
        CONSTRAINT [FK_invoice_additional_costs_invoices_invoice_id] FOREIGN KEY ([invoice_id]) REFERENCES [invoices] ([id]),
        CONSTRAINT [FK_invoice_additional_costs_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_invoice_additional_costs_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521151023_AddEntityInvoiceAdditionalReductionCost'
)
BEGIN
    CREATE TABLE [invoice_cost_reductions] (
        [id] uniqueidentifier NOT NULL,
        [invoice_id] uniqueidentifier NOT NULL,
        [description] nvarchar(100) NULL,
        [cost] decimal(18,4) NULL,
        [is_removable] bit NOT NULL DEFAULT CAST(1 AS bit),
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NOT NULL,
        [updated_by] uniqueidentifier NOT NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_invoice_cost_reductions] PRIMARY KEY ([id]),
        CONSTRAINT [FK_invoice_cost_reductions_invoices_invoice_id] FOREIGN KEY ([invoice_id]) REFERENCES [invoices] ([id]),
        CONSTRAINT [FK_invoice_cost_reductions_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_invoice_cost_reductions_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521151023_AddEntityInvoiceAdditionalReductionCost'
)
BEGIN
    CREATE TABLE [invoice_attachments] (
        [id] uniqueidentifier NOT NULL,
        [invoice_id] uniqueidentifier NOT NULL,
        [file_upload_id] uniqueidentifier NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NOT NULL,
        [updated_by] uniqueidentifier NOT NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_invoice_attachments] PRIMARY KEY ([id]),
        CONSTRAINT [FK_invoice_attachments_file_upload_attachments_file_upload_id] FOREIGN KEY ([file_upload_id]) REFERENCES [file_upload_attachments] ([id]),
        CONSTRAINT [FK_invoice_attachments_invoices_invoice_id] FOREIGN KEY ([invoice_id]) REFERENCES [invoices] ([id]),
        CONSTRAINT [FK_invoice_attachments_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_invoice_attachments_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521151023_AddEntityInvoiceAdditionalReductionCost'
)
BEGIN
    CREATE INDEX [IX_invoice_service_acceptances_InvoiceId1] ON [invoice_service_acceptances] ([InvoiceId1]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521151023_AddEntityInvoiceAdditionalReductionCost'
)
BEGIN
    CREATE INDEX [IX_invoice_additional_costs_created_by] ON [invoice_additional_costs] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521151023_AddEntityInvoiceAdditionalReductionCost'
)
BEGIN
    CREATE INDEX [IX_invoice_additional_costs_invoice_id] ON [invoice_additional_costs] ([invoice_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521151023_AddEntityInvoiceAdditionalReductionCost'
)
BEGIN
    CREATE INDEX [IX_invoice_additional_costs_updated_by] ON [invoice_additional_costs] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521151023_AddEntityInvoiceAdditionalReductionCost'
)
BEGIN
    CREATE INDEX [IX_invoice_attachments_created_by] ON [invoice_attachments] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521151023_AddEntityInvoiceAdditionalReductionCost'
)
BEGIN
    CREATE INDEX [IX_invoice_attachments_file_upload_id] ON [invoice_attachments] ([file_upload_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521151023_AddEntityInvoiceAdditionalReductionCost'
)
BEGIN
    CREATE INDEX [IX_invoice_attachments_invoice_id] ON [invoice_attachments] ([invoice_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521151023_AddEntityInvoiceAdditionalReductionCost'
)
BEGIN
    CREATE INDEX [IX_invoice_attachments_updated_by] ON [invoice_attachments] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521151023_AddEntityInvoiceAdditionalReductionCost'
)
BEGIN
    CREATE INDEX [IX_invoice_cost_reductions_created_by] ON [invoice_cost_reductions] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521151023_AddEntityInvoiceAdditionalReductionCost'
)
BEGIN
    CREATE INDEX [IX_invoice_cost_reductions_invoice_id] ON [invoice_cost_reductions] ([invoice_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521151023_AddEntityInvoiceAdditionalReductionCost'
)
BEGIN
    CREATE INDEX [IX_invoice_cost_reductions_updated_by] ON [invoice_cost_reductions] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521151023_AddEntityInvoiceAdditionalReductionCost'
)
BEGIN
    ALTER TABLE [invoice_service_acceptances] ADD CONSTRAINT [FK_invoice_service_acceptances_invoices_InvoiceId1] FOREIGN KEY ([InvoiceId1]) REFERENCES [invoices] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521151023_AddEntityInvoiceAdditionalReductionCost'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260521151023_AddEntityInvoiceAdditionalReductionCost', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521205703_AddProjectNotificationReminderTable'
)
BEGIN
    CREATE TABLE [project_notification_recipients] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [users] nvarchar(max) NULL,
        [cron_id] int NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        CONSTRAINT [PK_project_notification_recipients] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521205703_AddProjectNotificationReminderTable'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260521205703_AddProjectNotificationReminderTable', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521213943_AddQuartzPersistentStoreTables'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260521213943_AddQuartzPersistentStoreTables', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521214327_AddQuartzSqlServerTables'
)
BEGIN

    IF OBJECT_ID(N'[dbo].[QRTZ_JOB_DETAILS]', N'U') IS NULL
    CREATE TABLE [dbo].[QRTZ_JOB_DETAILS] (
        [SCHED_NAME]        nvarchar(120)  NOT NULL,
        [JOB_NAME]          nvarchar(150)  NOT NULL,
        [JOB_GROUP]         nvarchar(150)  NOT NULL,
        [DESCRIPTION]       nvarchar(250)  NULL,
        [JOB_CLASS_NAME]    nvarchar(250)  NOT NULL,
        [IS_DURABLE]        bit            NOT NULL,
        [IS_NONCONCURRENT]  bit            NOT NULL,
        [IS_UPDATE_DATA]    bit            NOT NULL,
        [REQUESTS_RECOVERY] bit            NOT NULL,
        [JOB_DATA]          varbinary(max) NULL,
        CONSTRAINT [PK_QRTZ_JOB_DETAILS] PRIMARY KEY ([SCHED_NAME],[JOB_NAME],[JOB_GROUP])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521214327_AddQuartzSqlServerTables'
)
BEGIN

    IF OBJECT_ID(N'[dbo].[QRTZ_TRIGGERS]', N'U') IS NULL
    CREATE TABLE [dbo].[QRTZ_TRIGGERS] (
        [SCHED_NAME]     nvarchar(120)  NOT NULL,
        [TRIGGER_NAME]   nvarchar(150)  NOT NULL,
        [TRIGGER_GROUP]  nvarchar(150)  NOT NULL,
        [JOB_NAME]       nvarchar(150)  NOT NULL,
        [JOB_GROUP]      nvarchar(150)  NOT NULL,
        [DESCRIPTION]    nvarchar(250)  NULL,
        [NEXT_FIRE_TIME] bigint         NULL,
        [PREV_FIRE_TIME] bigint         NULL,
        [PRIORITY]       int            NULL,
        [TRIGGER_STATE]  nvarchar(16)   NOT NULL,
        [TRIGGER_TYPE]   nvarchar(8)    NOT NULL,
        [START_TIME]     bigint         NOT NULL,
        [END_TIME]       bigint         NULL,
        [CALENDAR_NAME]  nvarchar(200)  NULL,
        [MISFIRE_INSTR]  int            NULL,
        [JOB_DATA]       varbinary(max) NULL,
        CONSTRAINT [PK_QRTZ_TRIGGERS] PRIMARY KEY ([SCHED_NAME],[TRIGGER_NAME],[TRIGGER_GROUP]),
        CONSTRAINT [FK_QRTZ_TRIGGERS_JOB_DETAILS] FOREIGN KEY ([SCHED_NAME],[JOB_NAME],[JOB_GROUP])
            REFERENCES [dbo].[QRTZ_JOB_DETAILS]([SCHED_NAME],[JOB_NAME],[JOB_GROUP])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521214327_AddQuartzSqlServerTables'
)
BEGIN

    IF OBJECT_ID(N'[dbo].[QRTZ_CRON_TRIGGERS]', N'U') IS NULL
    CREATE TABLE [dbo].[QRTZ_CRON_TRIGGERS] (
        [SCHED_NAME]      nvarchar(120) NOT NULL,
        [TRIGGER_NAME]    nvarchar(150) NOT NULL,
        [TRIGGER_GROUP]   nvarchar(150) NOT NULL,
        [CRON_EXPRESSION] nvarchar(120) NOT NULL,
        [TIME_ZONE_ID]    nvarchar(80)  NULL,
        CONSTRAINT [PK_QRTZ_CRON_TRIGGERS] PRIMARY KEY ([SCHED_NAME],[TRIGGER_NAME],[TRIGGER_GROUP]),
        CONSTRAINT [FK_QRTZ_CRON_TRIGGERS_TRIGGERS] FOREIGN KEY ([SCHED_NAME],[TRIGGER_NAME],[TRIGGER_GROUP])
            REFERENCES [dbo].[QRTZ_TRIGGERS]([SCHED_NAME],[TRIGGER_NAME],[TRIGGER_GROUP])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521214327_AddQuartzSqlServerTables'
)
BEGIN

    IF OBJECT_ID(N'[dbo].[QRTZ_SIMPLE_TRIGGERS]', N'U') IS NULL
    CREATE TABLE [dbo].[QRTZ_SIMPLE_TRIGGERS] (
        [SCHED_NAME]      nvarchar(120) NOT NULL,
        [TRIGGER_NAME]    nvarchar(150) NOT NULL,
        [TRIGGER_GROUP]   nvarchar(150) NOT NULL,
        [REPEAT_COUNT]    int           NOT NULL,
        [REPEAT_INTERVAL] bigint        NOT NULL,
        [TIMES_TRIGGERED] int           NOT NULL,
        CONSTRAINT [PK_QRTZ_SIMPLE_TRIGGERS] PRIMARY KEY ([SCHED_NAME],[TRIGGER_NAME],[TRIGGER_GROUP]),
        CONSTRAINT [FK_QRTZ_SIMPLE_TRIGGERS_TRIGGERS] FOREIGN KEY ([SCHED_NAME],[TRIGGER_NAME],[TRIGGER_GROUP])
            REFERENCES [dbo].[QRTZ_TRIGGERS]([SCHED_NAME],[TRIGGER_NAME],[TRIGGER_GROUP])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521214327_AddQuartzSqlServerTables'
)
BEGIN

    IF OBJECT_ID(N'[dbo].[QRTZ_SIMPROP_TRIGGERS]', N'U') IS NULL
    CREATE TABLE [dbo].[QRTZ_SIMPROP_TRIGGERS] (
        [SCHED_NAME]    nvarchar(120) NOT NULL,
        [TRIGGER_NAME]  nvarchar(150) NOT NULL,
        [TRIGGER_GROUP] nvarchar(150) NOT NULL,
        [STR_PROP_1]    nvarchar(512) NULL,
        [STR_PROP_2]    nvarchar(512) NULL,
        [STR_PROP_3]    nvarchar(512) NULL,
        [INT_PROP_1]    int           NULL,
        [INT_PROP_2]    int           NULL,
        [LONG_PROP_1]   bigint        NULL,
        [LONG_PROP_2]   bigint        NULL,
        [DEC_PROP_1]    numeric(13,4) NULL,
        [DEC_PROP_2]    numeric(13,4) NULL,
        [BOOL_PROP_1]   bit           NULL,
        [BOOL_PROP_2]   bit           NULL,
        [TIME_ZONE_ID]  nvarchar(80)  NULL,
        CONSTRAINT [PK_QRTZ_SIMPROP_TRIGGERS] PRIMARY KEY ([SCHED_NAME],[TRIGGER_NAME],[TRIGGER_GROUP]),
        CONSTRAINT [FK_QRTZ_SIMPROP_TRIGGERS_TRIGGERS] FOREIGN KEY ([SCHED_NAME],[TRIGGER_NAME],[TRIGGER_GROUP])
            REFERENCES [dbo].[QRTZ_TRIGGERS]([SCHED_NAME],[TRIGGER_NAME],[TRIGGER_GROUP])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521214327_AddQuartzSqlServerTables'
)
BEGIN

    IF OBJECT_ID(N'[dbo].[QRTZ_BLOB_TRIGGERS]', N'U') IS NULL
    CREATE TABLE [dbo].[QRTZ_BLOB_TRIGGERS] (
        [SCHED_NAME]    nvarchar(120)  NOT NULL,
        [TRIGGER_NAME]  nvarchar(150)  NOT NULL,
        [TRIGGER_GROUP] nvarchar(150)  NOT NULL,
        [BLOB_DATA]     varbinary(max) NULL,
        CONSTRAINT [PK_QRTZ_BLOB_TRIGGERS] PRIMARY KEY ([SCHED_NAME],[TRIGGER_NAME],[TRIGGER_GROUP]),
        CONSTRAINT [FK_QRTZ_BLOB_TRIGGERS_TRIGGERS] FOREIGN KEY ([SCHED_NAME],[TRIGGER_NAME],[TRIGGER_GROUP])
            REFERENCES [dbo].[QRTZ_TRIGGERS]([SCHED_NAME],[TRIGGER_NAME],[TRIGGER_GROUP])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521214327_AddQuartzSqlServerTables'
)
BEGIN

    IF OBJECT_ID(N'[dbo].[QRTZ_CALENDARS]', N'U') IS NULL
    CREATE TABLE [dbo].[QRTZ_CALENDARS] (
        [SCHED_NAME]    nvarchar(120)  NOT NULL,
        [CALENDAR_NAME] nvarchar(200)  NOT NULL,
        [CALENDAR]      varbinary(max) NOT NULL,
        CONSTRAINT [PK_QRTZ_CALENDARS] PRIMARY KEY ([SCHED_NAME],[CALENDAR_NAME])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521214327_AddQuartzSqlServerTables'
)
BEGIN

    IF OBJECT_ID(N'[dbo].[QRTZ_PAUSED_TRIGGER_GRPS]', N'U') IS NULL
    CREATE TABLE [dbo].[QRTZ_PAUSED_TRIGGER_GRPS] (
        [SCHED_NAME]    nvarchar(120) NOT NULL,
        [TRIGGER_GROUP] nvarchar(150) NOT NULL,
        CONSTRAINT [PK_QRTZ_PAUSED_TRIGGER_GRPS] PRIMARY KEY ([SCHED_NAME],[TRIGGER_GROUP])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521214327_AddQuartzSqlServerTables'
)
BEGIN

    IF OBJECT_ID(N'[dbo].[QRTZ_FIRED_TRIGGERS]', N'U') IS NULL
    CREATE TABLE [dbo].[QRTZ_FIRED_TRIGGERS] (
        [SCHED_NAME]        nvarchar(120) NOT NULL,
        [ENTRY_ID]          nvarchar(140) NOT NULL,
        [TRIGGER_NAME]      nvarchar(150) NOT NULL,
        [TRIGGER_GROUP]     nvarchar(150) NOT NULL,
        [INSTANCE_NAME]     nvarchar(200) NOT NULL,
        [FIRED_TIME]        bigint        NOT NULL,
        [SCHED_TIME]        bigint        NOT NULL,
        [PRIORITY]          int           NOT NULL,
        [STATE]             nvarchar(16)  NOT NULL,
        [JOB_NAME]          nvarchar(150) NULL,
        [JOB_GROUP]         nvarchar(150) NULL,
        [IS_NONCONCURRENT]  bit           NULL,
        [REQUESTS_RECOVERY] bit           NULL,
        CONSTRAINT [PK_QRTZ_FIRED_TRIGGERS] PRIMARY KEY ([SCHED_NAME],[ENTRY_ID])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521214327_AddQuartzSqlServerTables'
)
BEGIN

    IF OBJECT_ID(N'[dbo].[QRTZ_SCHEDULER_STATE]', N'U') IS NULL
    CREATE TABLE [dbo].[QRTZ_SCHEDULER_STATE] (
        [SCHED_NAME]        nvarchar(120) NOT NULL,
        [INSTANCE_NAME]     nvarchar(200) NOT NULL,
        [LAST_CHECKIN_TIME] bigint        NOT NULL,
        [CHECKIN_INTERVAL]  bigint        NOT NULL,
        CONSTRAINT [PK_QRTZ_SCHEDULER_STATE] PRIMARY KEY ([SCHED_NAME],[INSTANCE_NAME])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521214327_AddQuartzSqlServerTables'
)
BEGIN

    IF OBJECT_ID(N'[dbo].[QRTZ_LOCKS]', N'U') IS NULL
    CREATE TABLE [dbo].[QRTZ_LOCKS] (
        [SCHED_NAME] nvarchar(120) NOT NULL,
        [LOCK_NAME]  nvarchar(40)  NOT NULL,
        CONSTRAINT [PK_QRTZ_LOCKS] PRIMARY KEY ([SCHED_NAME],[LOCK_NAME])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521214327_AddQuartzSqlServerTables'
)
BEGIN

    IF NOT EXISTS (SELECT 1 FROM [dbo].[QRTZ_LOCKS] WHERE [SCHED_NAME] = 'PhantomScheduler')
    BEGIN
        INSERT INTO [dbo].[QRTZ_LOCKS] VALUES ('PhantomScheduler','TRIGGER_ACCESS');
        INSERT INTO [dbo].[QRTZ_LOCKS] VALUES ('PhantomScheduler','JOB_ACCESS');
        INSERT INTO [dbo].[QRTZ_LOCKS] VALUES ('PhantomScheduler','CALENDAR_ACCESS');
        INSERT INTO [dbo].[QRTZ_LOCKS] VALUES ('PhantomScheduler','STATE_ACCESS');
        INSERT INTO [dbo].[QRTZ_LOCKS] VALUES ('PhantomScheduler','MISFIRE_ACCESS');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260521214327_AddQuartzSqlServerTables'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260521214327_AddQuartzSqlServerTables', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523123356_AddWellCategoryAndZoneNameAndDropWellZones'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [well_category] nvarchar(8) NOT NULL DEFAULT N'-';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523123356_AddWellCategoryAndZoneNameAndDropWellZones'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [well_zone_name] nvarchar(100) NOT NULL DEFAULT N'-';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523123356_AddWellCategoryAndZoneNameAndDropWellZones'
)
BEGIN
    UPDATE wza
    SET wza.well_zone_name = wz.name
    FROM dbo.well_zone_assignments wza
    INNER JOIN dbo.well_zones wz ON wz.id = wza.well_zone_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523123356_AddWellCategoryAndZoneNameAndDropWellZones'
)
BEGIN
    ALTER TABLE [well_zone_assignments] DROP CONSTRAINT [FK_well_zone_assignments_well_zones_well_zone_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523123356_AddWellCategoryAndZoneNameAndDropWellZones'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_well_zone_assignments_well_id_well_zone_id' AND object_id = OBJECT_ID('dbo.well_zone_assignments'))
        DROP INDEX IX_well_zone_assignments_well_id_well_zone_id ON dbo.well_zone_assignments;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523123356_AddWellCategoryAndZoneNameAndDropWellZones'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_well_zone_assignments_well_zone_id' AND object_id = OBJECT_ID('dbo.well_zone_assignments'))
        DROP INDEX IX_well_zone_assignments_well_zone_id ON dbo.well_zone_assignments;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523123356_AddWellCategoryAndZoneNameAndDropWellZones'
)
BEGIN
    DECLARE @var63 sysname;
    SELECT @var63 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_zone_assignments]') AND [c].[name] = N'well_zone_id');
    IF @var63 IS NOT NULL EXEC(N'ALTER TABLE [well_zone_assignments] DROP CONSTRAINT [' + @var63 + '];');
    ALTER TABLE [well_zone_assignments] DROP COLUMN [well_zone_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523123356_AddWellCategoryAndZoneNameAndDropWellZones'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_well_zone_assignments_well_id_well_zone_name' AND object_id = OBJECT_ID('dbo.well_zone_assignments'))
        CREATE UNIQUE NONCLUSTERED INDEX IX_well_zone_assignments_well_id_well_zone_name
        ON dbo.well_zone_assignments (well_id, well_zone_name)
        WHERE deleted_at IS NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523123356_AddWellCategoryAndZoneNameAndDropWellZones'
)
BEGIN
    UPDATE dbo.well_histories_phss SET zone_id = '-' WHERE zone_id IS NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523123356_AddWellCategoryAndZoneNameAndDropWellZones'
)
BEGIN
    UPDATE dbo.well_histories_pep SET zone_id = '-' WHERE zone_id IS NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523123356_AddWellCategoryAndZoneNameAndDropWellZones'
)
BEGIN
    DROP TABLE [well_zones];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523123356_AddWellCategoryAndZoneNameAndDropWellZones'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260523123356_AddWellCategoryAndZoneNameAndDropWellZones', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523130813_SeedWellEurMonitoringConfigs'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.custom_configurations WHERE name = 'well_eur_monitoring.status')
      INSERT INTO dbo.custom_configurations (id, name, description, detail, created_at, created_by, updated_at, updated_by)
      VALUES (NEWID(),
              'well_eur_monitoring.status',
              'EUR Monitoring status enum (advisory)',
              '["approaching_eur","eur_exceeded","normal"]',
              GETDATE(), '02a1922b-5cf1-471a-b735-fb2ceb2bbd72',
              GETDATE(), '02a1922b-5cf1-471a-b735-fb2ceb2bbd72');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523130813_SeedWellEurMonitoringConfigs'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.custom_configurations WHERE name = 'well_eur_monitoring.decline_rate_threshold')
      INSERT INTO dbo.custom_configurations (id, name, description, detail, created_at, created_by, updated_at, updated_by)
      VALUES (NEWID(),
              'well_eur_monitoring.decline_rate_threshold',
              'EUR Monitoring decline rate thresholds (warning/danger %)',
              '{"warning":5.0,"danger":10.0}',
              GETDATE(), '02a1922b-5cf1-471a-b735-fb2ceb2bbd72',
              GETDATE(), '02a1922b-5cf1-471a-b735-fb2ceb2bbd72');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523130813_SeedWellEurMonitoringConfigs'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260523130813_SeedWellEurMonitoringConfigs', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523140250_RestoreWellZonesAndPivotFk'
)
BEGIN
    CREATE TABLE [well_zones] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [name] nvarchar(100) NOT NULL,
        [is_active] int NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_zones] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_zones_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_zones_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_zones_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523140250_RestoreWellZonesAndPivotFk'
)
BEGIN
    CREATE INDEX [IX_well_zones_created_by] ON [well_zones] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523140250_RestoreWellZonesAndPivotFk'
)
BEGIN
    CREATE INDEX [IX_well_zones_deleted_by] ON [well_zones] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523140250_RestoreWellZonesAndPivotFk'
)
BEGIN
    CREATE INDEX [IX_well_zones_updated_by] ON [well_zones] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523140250_RestoreWellZonesAndPivotFk'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_well_zone_assignments_well_id_well_zone_name' AND object_id = OBJECT_ID('dbo.well_zone_assignments'))
        DROP INDEX IX_well_zone_assignments_well_id_well_zone_name ON dbo.well_zone_assignments;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523140250_RestoreWellZonesAndPivotFk'
)
BEGIN
    DROP INDEX [IX_well_zone_assignments_well_id] ON [well_zone_assignments];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523140250_RestoreWellZonesAndPivotFk'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [well_zone_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523140250_RestoreWellZonesAndPivotFk'
)
BEGIN
    DECLARE @var64 sysname;
    SELECT @var64 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_zone_assignments]') AND [c].[name] = N'well_zone_name');
    IF @var64 IS NOT NULL EXEC(N'ALTER TABLE [well_zone_assignments] DROP CONSTRAINT [' + @var64 + '];');
    ALTER TABLE [well_zone_assignments] DROP COLUMN [well_zone_name];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523140250_RestoreWellZonesAndPivotFk'
)
BEGIN
    CREATE INDEX [IX_well_zone_assignments_well_zone_id] ON [well_zone_assignments] ([well_zone_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523140250_RestoreWellZonesAndPivotFk'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD CONSTRAINT [FK_well_zone_assignments_well_zones_well_zone_id] FOREIGN KEY ([well_zone_id]) REFERENCES [well_zones] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523140250_RestoreWellZonesAndPivotFk'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_well_zone_assignments_well_id_well_zone_id' AND object_id = OBJECT_ID('dbo.well_zone_assignments'))
        CREATE UNIQUE NONCLUSTERED INDEX IX_well_zone_assignments_well_id_well_zone_id
        ON dbo.well_zone_assignments (well_id, well_zone_id)
        WHERE deleted_at IS NULL AND well_zone_id IS NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523140250_RestoreWellZonesAndPivotFk'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260523140250_RestoreWellZonesAndPivotFk', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523164118_AddZoneAssignmentDetailColumns'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [upper_lower] nvarchar(20) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523164118_AddZoneAssignmentDetailColumns'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [type] nvarchar(50) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523164118_AddZoneAssignmentDetailColumns'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [eur] float NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523164118_AddZoneAssignmentDetailColumns'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [top_sand] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523164118_AddZoneAssignmentDetailColumns'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [bottom_sand] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523164118_AddZoneAssignmentDetailColumns'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260523164118_AddZoneAssignmentDetailColumns', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523170524_DropWellZoneAssignmentWellFkAndAddWellName'
)
BEGIN
    ALTER TABLE [well_zone_assignments] DROP CONSTRAINT [FK_well_zone_assignments_wells_well_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523170524_DropWellZoneAssignmentWellFkAndAddWellName'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [well_name] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260523170524_DropWellZoneAssignmentWellFkAndAddWellName'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260523170524_DropWellZoneAssignmentWellFkAndAddWellName', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260524055424_ResetWellsDataAndChangeWellIdToUuid'
)
BEGIN
    DELETE FROM well_compressor_assignments;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260524055424_ResetWellsDataAndChangeWellIdToUuid'
)
BEGIN
    DELETE FROM well_zone_assignments;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260524055424_ResetWellsDataAndChangeWellIdToUuid'
)
BEGIN
    DELETE FROM well_histories_phss;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260524055424_ResetWellsDataAndChangeWellIdToUuid'
)
BEGIN
    DELETE FROM well_histories_pep;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260524055424_ResetWellsDataAndChangeWellIdToUuid'
)
BEGIN
    DELETE FROM wells;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260524055424_ResetWellsDataAndChangeWellIdToUuid'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_wells_well_id' AND object_id = OBJECT_ID('dbo.wells'))
        DROP INDEX IX_wells_well_id ON dbo.wells;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260524055424_ResetWellsDataAndChangeWellIdToUuid'
)
BEGIN
    DECLARE @var65 sysname;
    SELECT @var65 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[wells]') AND [c].[name] = N'well_id');
    IF @var65 IS NOT NULL EXEC(N'ALTER TABLE [wells] DROP CONSTRAINT [' + @var65 + '];');
    ALTER TABLE [wells] ALTER COLUMN [well_id] uniqueidentifier NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260524055424_ResetWellsDataAndChangeWellIdToUuid'
)
BEGIN
    ALTER TABLE [wells] ADD [well_name] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260524055424_ResetWellsDataAndChangeWellIdToUuid'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_wells_well_id' AND object_id = OBJECT_ID('dbo.wells'))
        CREATE UNIQUE NONCLUSTERED INDEX IX_wells_well_id
        ON dbo.wells (well_id)
        WHERE deleted_at IS NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260524055424_ResetWellsDataAndChangeWellIdToUuid'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260524055424_ResetWellsDataAndChangeWellIdToUuid', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260524070742_DropWellsWellNameColumn'
)
BEGIN
    DECLARE @var66 sysname;
    SELECT @var66 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[wells]') AND [c].[name] = N'well_name');
    IF @var66 IS NOT NULL EXEC(N'ALTER TABLE [wells] DROP CONSTRAINT [' + @var66 + '];');
    ALTER TABLE [wells] DROP COLUMN [well_name];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260524070742_DropWellsWellNameColumn'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260524070742_DropWellsWellNameColumn', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260524074335_AddIsSelectedToWellZoneAssignments'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [is_selected] bit NOT NULL DEFAULT CAST(0 AS bit);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260524074335_AddIsSelectedToWellZoneAssignments'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260524074335_AddIsSelectedToWellZoneAssignments', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260524100916_AddProjectTaskWithoutSpkNotificationTable'
)
BEGIN
    CREATE TABLE [project_task_without_spk_notifications] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [frequency] nvarchar(50) NOT NULL,
        [recipients] nvarchar(max) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        CONSTRAINT [PK_project_task_without_spk_notifications] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260524100916_AddProjectTaskWithoutSpkNotificationTable'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260524100916_AddProjectTaskWithoutSpkNotificationTable', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260525081246_IncreaseFileTypeColoumnLength'
)
BEGIN
    DECLARE @var67 sysname;
    SELECT @var67 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[file_upload_attachments]') AND [c].[name] = N'file_type');
    IF @var67 IS NOT NULL EXEC(N'ALTER TABLE [file_upload_attachments] DROP CONSTRAINT [' + @var67 + '];');
    ALTER TABLE [file_upload_attachments] ALTER COLUMN [file_type] nvarchar(255) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260525081246_IncreaseFileTypeColoumnLength'
)
BEGIN
    DECLARE @var68 sysname;
    SELECT @var68 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[file_upload_attachments]') AND [c].[name] = N'file_name');
    IF @var68 IS NOT NULL EXEC(N'ALTER TABLE [file_upload_attachments] DROP CONSTRAINT [' + @var68 + '];');
    ALTER TABLE [file_upload_attachments] ALTER COLUMN [file_name] nvarchar(255) NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260525081246_IncreaseFileTypeColoumnLength'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260525081246_IncreaseFileTypeColoumnLength', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260529040642_AddProjectRebaselineTable'
)
BEGIN
    CREATE TABLE [project_rebaselines] (
        [id] uniqueidentifier NOT NULL,
        [project_id] uniqueidentifier NOT NULL,
        [file_name] nvarchar(300) NULL,
        [file_type] nvarchar(300) NULL,
        [file_size] nvarchar(40) NULL,
        [file_url] text NULL,
        [description] nvarchar(510) NULL,
        [status] varchar(20) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_project_rebaselines] PRIMARY KEY ([id]),
        CONSTRAINT [FK_project_rebaselines_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_project_rebaselines_projects_project_id] FOREIGN KEY ([project_id]) REFERENCES [projects] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260529040642_AddProjectRebaselineTable'
)
BEGIN
    CREATE INDEX [IX_project_rebaselines_created_by] ON [project_rebaselines] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260529040642_AddProjectRebaselineTable'
)
BEGIN
    CREATE INDEX [IX_project_rebaselines_project_id] ON [project_rebaselines] ([project_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260529040642_AddProjectRebaselineTable'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260529040642_AddProjectRebaselineTable', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260530071731_AddDcaRuns'
)
BEGIN
    CREATE TABLE [dca_runs] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [project_no] nvarchar(64) NULL,
        [mode] nvarchar(20) NULL,
        [config_json] nvarchar(max) NULL,
        [input_csv_file_name] nvarchar(255) NULL,
        [input_csv_sha256] nvarchar(64) NULL,
        [input_csv_size_bytes] bigint NOT NULL,
        [status] nvarchar(16) NULL,
        [result_json] nvarchar(max) NULL,
        [processing_time_ms] bigint NOT NULL,
        [error_message] nvarchar(2000) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NOT NULL,
        [updated_by] uniqueidentifier NOT NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_dca_runs] PRIMARY KEY ([id]),
        CONSTRAINT [FK_dca_runs_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_dca_runs_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260530071731_AddDcaRuns'
)
BEGIN
    CREATE INDEX [IX_dca_runs_created_by] ON [dca_runs] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260530071731_AddDcaRuns'
)
BEGIN
    CREATE INDEX [IX_dca_runs_input_csv_sha256] ON [dca_runs] ([input_csv_sha256]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260530071731_AddDcaRuns'
)
BEGIN
    CREATE INDEX [IX_dca_runs_project_no_created_at] ON [dca_runs] ([project_no], [created_at] DESC);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260530071731_AddDcaRuns'
)
BEGIN
    CREATE INDEX [IX_dca_runs_updated_by] ON [dca_runs] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260530071731_AddDcaRuns'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260530071731_AddDcaRuns', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260601062649_AddDcaRunResults'
)
BEGIN
    CREATE TABLE [dca_run_results] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [dca_run_id] uniqueidentifier NOT NULL,
        [model] nvarchar(20) NULL,
        [label] nvarchar(64) NULL,
        [is_manual] bit NOT NULL,
        [is_best] bit NOT NULL,
        [qi] float NOT NULL,
        [d] float NOT NULL,
        [b] float NOT NULL,
        [rmse] float NULL,
        [r2] float NULL,
        [cumulative] float NOT NULL,
        [segment_cumulative] float NOT NULL,
        [eur] float NOT NULL,
        [remaining_eur] float NOT NULL,
        [remaining_days] int NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_dca_run_results] PRIMARY KEY ([id]),
        CONSTRAINT [FK_dca_run_results_dca_runs_dca_run_id] FOREIGN KEY ([dca_run_id]) REFERENCES [dca_runs] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260601062649_AddDcaRunResults'
)
BEGIN
    CREATE INDEX [IX_dca_run_results_dca_run_id] ON [dca_run_results] ([dca_run_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260601062649_AddDcaRunResults'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260601062649_AddDcaRunResults', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260601072010_SeedDcaDefaultConfig'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM custom_configurations WHERE name = 'dca.default')
       AND EXISTS (SELECT 1 FROM users)
    BEGIN
        DECLARE @uid uniqueidentifier = (SELECT TOP 1 id FROM users ORDER BY created_at);
        INSERT INTO custom_configurations (id, name, description, detail, created_at, created_by, updated_at, updated_by)
        VALUES (
            NEWID(),
            'dca.default',
            'Default DCA run configuration (fallback when POST /api/v1/dca/run omits configJson).',
            '{"economic_limit":10,"initial_eur":0,"preprocessing":{"max_shutin_gap":30,"workover_ratio":3.0,"min_segment_points":30,"hampel_window":5,"hampel_threshold":3.0},"hyperbolic":{"b":0,"initial_guess":{"qi":0,"D":0,"b":0}},"model_selection":{"auto_select":true,"criteria":"rmse"},"manual_decline":{"enabled":false,"model":"exponential","qi":0,"d":0,"d_unit":"per_day","b":0},"critical_rate":{"enabled":false,"fthp":0,"temperature":0,"gas_comp":0,"tubing_id":0,"fluid_type":"water"}}',
            SYSUTCDATETIME(),
            @uid,
            SYSUTCDATETIME(),
            @uid);
    END
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260601072010_SeedDcaDefaultConfig'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260601072010_SeedDcaDefaultConfig', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    ALTER TABLE [wells] DROP CONSTRAINT [FK_wells_well_areas_area_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    ALTER TABLE [wells] DROP CONSTRAINT [FK_wells_well_lifting_types_lifting_type_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    ALTER TABLE [wells] DROP CONSTRAINT [FK_wells_well_types_well_type_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    DROP INDEX [IX_well_zone_assignments_well_id_well_zone_id] ON [well_zone_assignments];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    DROP INDEX [IX_wells_well_id] ON [wells];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    DECLARE @var69 sysname;
    SELECT @var69 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[wells]') AND [c].[name] = N'well_id');
    IF @var69 IS NOT NULL EXEC(N'ALTER TABLE [wells] DROP CONSTRAINT [' + @var69 + '];');
    ALTER TABLE [wells] DROP COLUMN [well_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    DECLARE @var70 sysname;
    SELECT @var70 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_zone_assignments]') AND [c].[name] = N'well_category');
    IF @var70 IS NOT NULL EXEC(N'ALTER TABLE [well_zone_assignments] DROP CONSTRAINT [' + @var70 + '];');
    ALTER TABLE [well_zone_assignments] DROP COLUMN [well_category];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    DECLARE @var71 sysname;
    SELECT @var71 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_zone_assignments]') AND [c].[name] = N'well_name');
    IF @var71 IS NOT NULL EXEC(N'ALTER TABLE [well_zone_assignments] DROP CONSTRAINT [' + @var71 + '];');
    ALTER TABLE [well_zone_assignments] DROP COLUMN [well_name];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    EXEC sp_rename N'[well_zone_assignments].[well_id]', N'well_ref_id', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    DECLARE @var72 sysname;
    SELECT @var72 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[wells]') AND [c].[name] = N'well_type_id');
    IF @var72 IS NOT NULL EXEC(N'ALTER TABLE [wells] DROP CONSTRAINT [' + @var72 + '];');
    ALTER TABLE [wells] ALTER COLUMN [well_type_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    DECLARE @var73 sysname;
    SELECT @var73 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[wells]') AND [c].[name] = N'lifting_type_id');
    IF @var73 IS NOT NULL EXEC(N'ALTER TABLE [wells] DROP CONSTRAINT [' + @var73 + '];');
    ALTER TABLE [wells] ALTER COLUMN [lifting_type_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    DECLARE @var74 sysname;
    SELECT @var74 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[wells]') AND [c].[name] = N'area_id');
    IF @var74 IS NOT NULL EXEC(N'ALTER TABLE [wells] DROP CONSTRAINT [' + @var74 + '];');
    ALTER TABLE [wells] ALTER COLUMN [area_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    ALTER TABLE [wells] ADD [is_production] bit NOT NULL DEFAULT CAST(0 AS bit);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    ALTER TABLE [wells] ADD [well_name] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [well_field_id] uniqueidentifier NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    CREATE INDEX [IX_well_zone_assignments_well_field_id] ON [well_zone_assignments] ([well_field_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [IX_well_zone_assignments_well_ref_id_well_zone_id] ON [well_zone_assignments] ([well_ref_id], [well_zone_id]) WHERE [deleted_at] IS NULL AND [well_zone_id] IS NOT NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD CONSTRAINT [FK_well_zone_assignments_well_fields_well_field_id] FOREIGN KEY ([well_field_id]) REFERENCES [well_fields] ([id]) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD CONSTRAINT [FK_well_zone_assignments_wells_well_ref_id] FOREIGN KEY ([well_ref_id]) REFERENCES [wells] ([id]) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    ALTER TABLE [wells] ADD CONSTRAINT [FK_wells_well_areas_area_id] FOREIGN KEY ([area_id]) REFERENCES [well_areas] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    ALTER TABLE [wells] ADD CONSTRAINT [FK_wells_well_lifting_types_lifting_type_id] FOREIGN KEY ([lifting_type_id]) REFERENCES [well_lifting_types] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    ALTER TABLE [wells] ADD CONSTRAINT [FK_wells_well_types_well_type_id] FOREIGN KEY ([well_type_id]) REFERENCES [well_types] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604052856_RefactorWellZoneAssignmentsSchema'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260604052856_RefactorWellZoneAssignmentsSchema', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604060036_RenameWellRefIdToWellId'
)
BEGIN
    ALTER TABLE [well_zone_assignments] DROP CONSTRAINT [FK_well_zone_assignments_wells_well_ref_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604060036_RenameWellRefIdToWellId'
)
BEGIN
    DROP INDEX [IX_well_zone_assignments_well_ref_id_well_zone_id] ON [well_zone_assignments];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604060036_RenameWellRefIdToWellId'
)
BEGIN
    EXEC sp_rename N'[well_zone_assignments].[well_ref_id]', N'well_id', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604060036_RenameWellRefIdToWellId'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [IX_well_zone_assignments_well_id_well_zone_id] ON [well_zone_assignments] ([well_id], [well_zone_id]) WHERE [deleted_at] IS NULL AND [well_zone_id] IS NOT NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604060036_RenameWellRefIdToWellId'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD CONSTRAINT [FK_well_zone_assignments_wells_well_id] FOREIGN KEY ([well_id]) REFERENCES [wells] ([id]) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260604060036_RenameWellRefIdToWellId'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260604060036_RenameWellRefIdToWellId', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260605174623_AddRksTable'
)
BEGIN
    CREATE TABLE [rks] (
        [contract_id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [contract_name] nvarchar(500) NULL,
        [document_number] nvarchar(255) NULL,
        [contract_type] nvarchar(255) NULL,
        [category] nvarchar(100) NULL,
        [currency] decimal(18,2) NOT NULL,
        [selected_count] int NOT NULL,
        [need_input_count] int NOT NULL,
        [plain_text] nvarchar(max) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_rks] PRIMARY KEY ([contract_id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260605174623_AddRksTable'
)
BEGIN
    CREATE INDEX [IX_rks_contract_id] ON [rks] ([contract_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260605174623_AddRksTable'
)
BEGIN
    CREATE INDEX [IX_rks_document_number] ON [rks] ([document_number]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260605174623_AddRksTable'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260605174623_AddRksTable', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260605184613_AddRksClauseTable'
)
BEGIN
    CREATE TABLE [rks_clause] (
        [clause_id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [contract_id] uniqueidentifier NOT NULL,
        [clause_number] nvarchar(50) NULL,
        [clause_title] nvarchar(500) NULL,
        [clause_content] nvarchar(max) NULL,
        [included] bit NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_rks_clause] PRIMARY KEY ([clause_id]),
        CONSTRAINT [FK_rks_clause_rks] FOREIGN KEY ([contract_id]) REFERENCES [rks] ([contract_id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260605184613_AddRksClauseTable'
)
BEGIN
    CREATE INDEX [IX_rks_clause_contract_id] ON [rks_clause] ([contract_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260605184613_AddRksClauseTable'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260605184613_AddRksClauseTable', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260605192409_AddSortOrderToRksClause'
)
BEGIN
    ALTER TABLE [rks_clause] ADD [sort_order] int NOT NULL DEFAULT 0;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260605192409_AddSortOrderToRksClause'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260605192409_AddSortOrderToRksClause', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260607052809_RebuildWellHistoryPhss'
)
BEGIN
    DROP TABLE [well_histories_phss];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260607052809_RebuildWellHistoryPhss'
)
BEGIN
    CREATE TABLE [well_history_phss] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [well_id] uniqueidentifier NOT NULL,
        [well_zone_id] uniqueidentifier NOT NULL,
        [prod_date] date NULL,
        [oil] float NULL,
        [gas_out] float NULL,
        [gas_in] float NULL,
        [water_cut] float NULL,
        [gross] float NULL,
        [fthp] float NULL,
        [flp] float NULL,
        [temperatur_number] float NULL,
        [choke_size] float NULL,
        [mtu_date] date NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_history_phss] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_history_phss_well_zones_well_zone_id] FOREIGN KEY ([well_zone_id]) REFERENCES [well_zones] ([id]),
        CONSTRAINT [FK_well_history_phss_wells_well_id] FOREIGN KEY ([well_id]) REFERENCES [wells] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260607052809_RebuildWellHistoryPhss'
)
BEGIN
    CREATE INDEX [IX_well_history_phss_created_by] ON [well_history_phss] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260607052809_RebuildWellHistoryPhss'
)
BEGIN
    CREATE INDEX [IX_well_history_phss_prod_date] ON [well_history_phss] ([prod_date]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260607052809_RebuildWellHistoryPhss'
)
BEGIN
    CREATE INDEX [IX_well_history_phss_well_id] ON [well_history_phss] ([well_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260607052809_RebuildWellHistoryPhss'
)
BEGIN
    CREATE INDEX [IX_well_history_phss_well_zone_id] ON [well_history_phss] ([well_zone_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260607052809_RebuildWellHistoryPhss'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260607052809_RebuildWellHistoryPhss', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260608115040_AddWaterDropMtuDateToWellHistoryPhss'
)
BEGIN
    ALTER TABLE [well_history_phss] ADD [water] float NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260608115040_AddWaterDropMtuDateToWellHistoryPhss'
)
BEGIN
    DECLARE @var75 sysname;
    SELECT @var75 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_history_phss]') AND [c].[name] = N'mtu_date');
    IF @var75 IS NOT NULL EXEC(N'ALTER TABLE [well_history_phss] DROP CONSTRAINT [' + @var75 + '];');
    ALTER TABLE [well_history_phss] DROP COLUMN [mtu_date];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260608115040_AddWaterDropMtuDateToWellHistoryPhss'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260608115040_AddWaterDropMtuDateToWellHistoryPhss', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042153_ConvertWellZoneAssignmentSandAndEurToDecimal'
)
BEGIN
    UPDATE well_zone_assignments SET top_sand = NULL WHERE top_sand IS NOT NULL AND TRY_CONVERT(decimal(18,4), top_sand) IS NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042153_ConvertWellZoneAssignmentSandAndEurToDecimal'
)
BEGIN
    UPDATE well_zone_assignments SET bottom_sand = NULL WHERE bottom_sand IS NOT NULL AND TRY_CONVERT(decimal(18,4), bottom_sand) IS NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042153_ConvertWellZoneAssignmentSandAndEurToDecimal'
)
BEGIN
    DECLARE @var76 sysname;
    SELECT @var76 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_zone_assignments]') AND [c].[name] = N'top_sand');
    IF @var76 IS NOT NULL EXEC(N'ALTER TABLE [well_zone_assignments] DROP CONSTRAINT [' + @var76 + '];');
    ALTER TABLE [well_zone_assignments] ALTER COLUMN [top_sand] decimal(18,4) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042153_ConvertWellZoneAssignmentSandAndEurToDecimal'
)
BEGIN
    DECLARE @var77 sysname;
    SELECT @var77 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_zone_assignments]') AND [c].[name] = N'eur');
    IF @var77 IS NOT NULL EXEC(N'ALTER TABLE [well_zone_assignments] DROP CONSTRAINT [' + @var77 + '];');
    ALTER TABLE [well_zone_assignments] ALTER COLUMN [eur] decimal(18,4) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042153_ConvertWellZoneAssignmentSandAndEurToDecimal'
)
BEGIN
    DECLARE @var78 sysname;
    SELECT @var78 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_zone_assignments]') AND [c].[name] = N'bottom_sand');
    IF @var78 IS NOT NULL EXEC(N'ALTER TABLE [well_zone_assignments] DROP CONSTRAINT [' + @var78 + '];');
    ALTER TABLE [well_zone_assignments] ALTER COLUMN [bottom_sand] decimal(18,4) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042153_ConvertWellZoneAssignmentSandAndEurToDecimal'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260609042153_ConvertWellZoneAssignmentSandAndEurToDecimal', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042646_AddAreasPlantsCompressors'
)
BEGIN
    CREATE TABLE [areas] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [name] nvarchar(100) NULL,
        [is_active] int NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_areas] PRIMARY KEY ([id]),
        CONSTRAINT [FK_areas_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_areas_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_areas_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042646_AddAreasPlantsCompressors'
)
BEGIN
    CREATE TABLE [plants] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [name] nvarchar(100) NULL,
        [area_id] uniqueidentifier NOT NULL,
        [is_active] int NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_plants] PRIMARY KEY ([id]),
        CONSTRAINT [FK_plants_areas_area_id] FOREIGN KEY ([area_id]) REFERENCES [areas] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_plants_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_plants_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_plants_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042646_AddAreasPlantsCompressors'
)
BEGIN
    CREATE TABLE [compressors] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [name] nvarchar(100) NULL,
        [plant_id] uniqueidentifier NOT NULL,
        [is_active] int NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressors] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressors_plants_plant_id] FOREIGN KEY ([plant_id]) REFERENCES [plants] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressors_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressors_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressors_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042646_AddAreasPlantsCompressors'
)
BEGIN
    CREATE INDEX [IX_areas_created_by] ON [areas] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042646_AddAreasPlantsCompressors'
)
BEGIN
    CREATE INDEX [IX_areas_deleted_by] ON [areas] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042646_AddAreasPlantsCompressors'
)
BEGIN
    CREATE INDEX [IX_areas_updated_by] ON [areas] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042646_AddAreasPlantsCompressors'
)
BEGIN
    CREATE INDEX [IX_compressors_created_by] ON [compressors] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042646_AddAreasPlantsCompressors'
)
BEGIN
    CREATE INDEX [IX_compressors_deleted_by] ON [compressors] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042646_AddAreasPlantsCompressors'
)
BEGIN
    CREATE INDEX [IX_compressors_plant_id] ON [compressors] ([plant_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042646_AddAreasPlantsCompressors'
)
BEGIN
    CREATE INDEX [IX_compressors_updated_by] ON [compressors] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042646_AddAreasPlantsCompressors'
)
BEGIN
    CREATE INDEX [IX_plants_area_id] ON [plants] ([area_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042646_AddAreasPlantsCompressors'
)
BEGIN
    CREATE INDEX [IX_plants_created_by] ON [plants] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042646_AddAreasPlantsCompressors'
)
BEGIN
    CREATE INDEX [IX_plants_deleted_by] ON [plants] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042646_AddAreasPlantsCompressors'
)
BEGIN
    CREATE INDEX [IX_plants_updated_by] ON [plants] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609042646_AddAreasPlantsCompressors'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260609042646_AddAreasPlantsCompressors', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609065542_AddWellEurSummariesAndForecasts'
)
BEGIN
    CREATE TABLE [well_eur_summaries] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [well_id] uniqueidentifier NOT NULL,
        [well_zone_id] uniqueidentifier NOT NULL,
        [model_calculation] nvarchar(50) NULL,
        [is_best] bit NOT NULL,
        [eur] float NOT NULL,
        [eur_remaining] float NOT NULL,
        [eur_remaining_days] int NOT NULL,
        [qi] float NOT NULL,
        [d] float NOT NULL,
        [b] float NOT NULL,
        [rmse] float NULL,
        [r2] float NULL,
        [economic_limit] float NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_eur_summaries] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_eur_summaries_well_zones_well_zone_id] FOREIGN KEY ([well_zone_id]) REFERENCES [well_zones] ([id]),
        CONSTRAINT [FK_well_eur_summaries_wells_well_id] FOREIGN KEY ([well_id]) REFERENCES [wells] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609065542_AddWellEurSummariesAndForecasts'
)
BEGIN
    CREATE TABLE [well_eur_forecasts] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [well_eur_summary_id] uniqueidentifier NOT NULL,
        [day] int NOT NULL,
        [forecast_date] date NOT NULL,
        [rate] float NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_eur_forecasts] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_eur_forecasts_well_eur_summaries_well_eur_summary_id] FOREIGN KEY ([well_eur_summary_id]) REFERENCES [well_eur_summaries] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609065542_AddWellEurSummariesAndForecasts'
)
BEGIN
    CREATE INDEX [IX_well_eur_forecasts_well_eur_summary_id] ON [well_eur_forecasts] ([well_eur_summary_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609065542_AddWellEurSummariesAndForecasts'
)
BEGIN
    CREATE INDEX [IX_well_eur_summaries_well_id] ON [well_eur_summaries] ([well_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609065542_AddWellEurSummariesAndForecasts'
)
BEGIN
    CREATE INDEX [IX_well_eur_summaries_well_zone_id] ON [well_eur_summaries] ([well_zone_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609065542_AddWellEurSummariesAndForecasts'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260609065542_AddWellEurSummariesAndForecasts', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609074354_AddTubingColumnsAndWellCasings'
)
BEGIN
    ALTER TABLE [wells] ADD [lower_tubing_depth] float NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609074354_AddTubingColumnsAndWellCasings'
)
BEGIN
    ALTER TABLE [wells] ADD [lower_tubing_size] nvarchar(50) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609074354_AddTubingColumnsAndWellCasings'
)
BEGIN
    ALTER TABLE [wells] ADD [upper_tubing_depth] float NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609074354_AddTubingColumnsAndWellCasings'
)
BEGIN
    ALTER TABLE [wells] ADD [upper_tubing_size] nvarchar(50) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609074354_AddTubingColumnsAndWellCasings'
)
BEGIN
    CREATE TABLE [well_casings] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [well_id] uniqueidentifier NOT NULL,
        [category] nvarchar(50) NULL,
        [depth] float NULL,
        [size] nvarchar(50) NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_casings] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_casings_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_well_casings_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_well_casings_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_well_casings_wells_well_id] FOREIGN KEY ([well_id]) REFERENCES [wells] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609074354_AddTubingColumnsAndWellCasings'
)
BEGIN
    CREATE INDEX [IX_well_casings_created_by] ON [well_casings] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609074354_AddTubingColumnsAndWellCasings'
)
BEGIN
    CREATE INDEX [IX_well_casings_deleted_by] ON [well_casings] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609074354_AddTubingColumnsAndWellCasings'
)
BEGIN
    CREATE INDEX [IX_well_casings_updated_by] ON [well_casings] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609074354_AddTubingColumnsAndWellCasings'
)
BEGIN
    CREATE INDEX [IX_well_casings_well_id] ON [well_casings] ([well_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609074354_AddTubingColumnsAndWellCasings'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260609074354_AddTubingColumnsAndWellCasings', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609194717_AddPercentageToWellZoneAssignments'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [percentage] decimal(18,4) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260609194717_AddPercentageToWellZoneAssignments'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260609194717_AddPercentageToWellZoneAssignments', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260610045041_AddOeGenerators'
)
BEGIN
    ALTER TABLE [file_upload_attachments] ADD [module] nvarchar(255) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260610045041_AddOeGenerators'
)
BEGIN
    CREATE TABLE [oe_generators] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [description] nvarchar(500) NULL,
        [created_at] datetime NULL,
        [created_by] uniqueidentifier NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_oe_generators] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260610045041_AddOeGenerators'
)
BEGIN
    CREATE TABLE [oe_generator_configurations] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [oe_generator_id] uniqueidentifier NOT NULL,
        [contract_id] uniqueidentifier NULL,
        [priority] int NOT NULL,
        [source_type] nvarchar(150) NOT NULL,
        [created_at] datetime NULL,
        [created_by] uniqueidentifier NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_oe_generator_configurations] PRIMARY KEY ([id]),
        CONSTRAINT [FK_oe_generator_configurations_contracts_contract_id] FOREIGN KEY ([contract_id]) REFERENCES [contracts] ([contract_id]),
        CONSTRAINT [FK_oe_generator_configurations_oe_generators_oe_generator_id] FOREIGN KEY ([oe_generator_id]) REFERENCES [oe_generators] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260610045041_AddOeGenerators'
)
BEGIN
    CREATE TABLE [oe_generator_documents] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [oe_generator_configuration_id] uniqueidentifier NOT NULL,
        [file_name] nvarchar(255) NULL,
        [file_type] nvarchar(250) NULL,
        [file_size] nvarchar(250) NULL,
        [file_url] nvarchar(1000) NULL,
        [description] nvarchar(500) NULL,
        [created_at] datetime NULL,
        [created_by] uniqueidentifier NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_oe_generator_documents] PRIMARY KEY ([id]),
        CONSTRAINT [FK_oe_generator_documents_oe_generator_configurations_oe_generator_configuration_id] FOREIGN KEY ([oe_generator_configuration_id]) REFERENCES [oe_generator_configurations] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260610045041_AddOeGenerators'
)
BEGIN
    CREATE TABLE [oe_generator_items] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [oe_generator_configuration_id] uniqueidentifier NOT NULL,
        [document_id] uniqueidentifier NULL,
        [contract_id] uniqueidentifier NULL,
        [file_upload_id] uniqueidentifier NULL,
        [breakdown] nvarchar(255) NULL,
        [name] nvarchar(500) NULL,
        [unit] nvarchar(50) NULL,
        [price] decimal(18,4) NULL,
        [item_type] nvarchar(150) NULL,
        [url] nvarchar(1000) NULL,
        [trace_source] nvarchar(150) NULL,
        [created_at] datetime NULL,
        [created_by] uniqueidentifier NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_oe_generator_items] PRIMARY KEY ([id]),
        CONSTRAINT [FK_oe_generator_items_contracts_contract_id] FOREIGN KEY ([contract_id]) REFERENCES [contracts] ([contract_id]),
        CONSTRAINT [FK_oe_generator_items_file_upload_attachments_file_upload_id] FOREIGN KEY ([file_upload_id]) REFERENCES [file_upload_attachments] ([id]),
        CONSTRAINT [FK_oe_generator_items_oe_generator_configurations_oe_generator_configuration_id] FOREIGN KEY ([oe_generator_configuration_id]) REFERENCES [oe_generator_configurations] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_oe_generator_items_oe_generator_documents_document_id] FOREIGN KEY ([document_id]) REFERENCES [oe_generator_documents] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260610045041_AddOeGenerators'
)
BEGIN
    CREATE INDEX [IX_oe_generator_configurations_contract_id] ON [oe_generator_configurations] ([contract_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260610045041_AddOeGenerators'
)
BEGIN
    CREATE INDEX [IX_oe_generator_configurations_oe_generator_id] ON [oe_generator_configurations] ([oe_generator_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260610045041_AddOeGenerators'
)
BEGIN
    CREATE INDEX [IX_oe_generator_documents_oe_generator_configuration_id] ON [oe_generator_documents] ([oe_generator_configuration_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260610045041_AddOeGenerators'
)
BEGIN
    CREATE INDEX [IX_oe_generator_items_contract_id] ON [oe_generator_items] ([contract_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260610045041_AddOeGenerators'
)
BEGIN
    CREATE INDEX [IX_oe_generator_items_document_id] ON [oe_generator_items] ([document_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260610045041_AddOeGenerators'
)
BEGIN
    CREATE INDEX [IX_oe_generator_items_file_upload_id] ON [oe_generator_items] ([file_upload_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260610045041_AddOeGenerators'
)
BEGIN
    CREATE INDEX [IX_oe_generator_items_oe_generator_configuration_id] ON [oe_generator_items] ([oe_generator_configuration_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260610045041_AddOeGenerators'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260610045041_AddOeGenerators', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260611073854_AddWellAreaAndWellPlantColumns'
)
BEGIN
    EXEC sp_rename N'[well_plant_assignments].[plant_id]', N'well_plant_id', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260611073854_AddWellAreaAndWellPlantColumns'
)
BEGIN

                IF NOT EXISTS (
                    SELECT 1
                    FROM INFORMATION_SCHEMA.COLUMNS
                    WHERE TABLE_NAME = 'well_plants'
                      AND COLUMN_NAME = 'well_area_id'
                )
                BEGIN
                    ALTER TABLE well_plants
                    ADD well_area_id uniqueidentifier NOT NULL
                    CONSTRAINT DF_well_plants_well_area_id
                    DEFAULT ('00000000-0000-0000-0000-000000000000')
                END
                
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260611073854_AddWellAreaAndWellPlantColumns'
)
BEGIN

                IF NOT EXISTS (
                    SELECT 1
                    FROM INFORMATION_SCHEMA.COLUMNS
                    WHERE TABLE_NAME = 'well_compressor_destinations'
                      AND COLUMN_NAME = 'well_plant_id'
                )
                BEGIN
                    ALTER TABLE well_compressor_destinations
                    ADD well_plant_id uniqueidentifier NULL
                END
                
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260611073854_AddWellAreaAndWellPlantColumns'
)
BEGIN
    CREATE INDEX [IX_well_plants_well_area_id] ON [well_plants] ([well_area_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260611073854_AddWellAreaAndWellPlantColumns'
)
BEGIN
    CREATE INDEX [IX_well_compressor_destinations_well_plant_id] ON [well_compressor_destinations] ([well_plant_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260611073854_AddWellAreaAndWellPlantColumns'
)
BEGIN
    ALTER TABLE [well_compressor_destinations] ADD CONSTRAINT [FK_well_compressor_destinations_well_plants_well_plant_id] FOREIGN KEY ([well_plant_id]) REFERENCES [well_plants] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260611073854_AddWellAreaAndWellPlantColumns'
)
BEGIN
    ALTER TABLE [well_plants] ADD CONSTRAINT [FK_well_plants_well_areas_well_area_id] FOREIGN KEY ([well_area_id]) REFERENCES [well_areas] ([id]) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260611073854_AddWellAreaAndWellPlantColumns'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260611073854_AddWellAreaAndWellPlantColumns', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260612033801_AddRksMasterClauseTables'
)
BEGIN
    CREATE TABLE [rks_master_clause] (
        [clause_id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [clause_order] int NOT NULL,
        [clause_code] nvarchar(50) NULL,
        [clause_name] nvarchar(255) NULL,
        [description] nvarchar(max) NULL,
        [category] nvarchar(100) NULL,
        [is_active] bit NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_rks_master_clause] PRIMARY KEY ([clause_id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260612033801_AddRksMasterClauseTables'
)
BEGIN
    CREATE TABLE [rks_master_sub_clause] (
        [sub_clause_id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [clause_id] uniqueidentifier NOT NULL,
        [sub_clause_order] int NOT NULL,
        [sub_clause_name] nvarchar(255) NULL,
        [sub_clause_content] nvarchar(max) NULL,
        [is_active] bit NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_rks_master_sub_clause] PRIMARY KEY ([sub_clause_id]),
        CONSTRAINT [FK_rks_master_sub_clause_rks_master_clause] FOREIGN KEY ([clause_id]) REFERENCES [rks_master_clause] ([clause_id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260612033801_AddRksMasterClauseTables'
)
BEGIN
    CREATE INDEX [IX_rks_master_clause_code] ON [rks_master_clause] ([clause_code]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260612033801_AddRksMasterClauseTables'
)
BEGIN
    CREATE INDEX [IX_rks_master_sub_clause_clause_id] ON [rks_master_sub_clause] ([clause_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260612033801_AddRksMasterClauseTables'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260612033801_AddRksMasterClauseTables', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260613081915_AddUploadColumnsToWellZoneAssignments'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [field] nvarchar(255) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260613081915_AddUploadColumnsToWellZoneAssignments'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [well_actual] nvarchar(255) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260613081915_AddUploadColumnsToWellZoneAssignments'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [fid] nvarchar(255) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260613081915_AddUploadColumnsToWellZoneAssignments'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [reserve_gas] decimal(18,4) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260613081915_AddUploadColumnsToWellZoneAssignments'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [reserve_oil] decimal(18,4) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260613081915_AddUploadColumnsToWellZoneAssignments'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260613081915_AddUploadColumnsToWellZoneAssignments', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260615100539_AdjustmentOeGeneratorDocument'
)
BEGIN
    DECLARE @var79 sysname;
    SELECT @var79 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[oe_generator_documents]') AND [c].[name] = N'oe_generator_configuration_id');
    IF @var79 IS NOT NULL EXEC(N'ALTER TABLE [oe_generator_documents] DROP CONSTRAINT [' + @var79 + '];');
    ALTER TABLE [oe_generator_documents] ALTER COLUMN [oe_generator_configuration_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260615100539_AdjustmentOeGeneratorDocument'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260615100539_AdjustmentOeGeneratorDocument', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260616095811_AddCriticalRateToWellHistoryPhss'
)
BEGIN
    ALTER TABLE [well_history_phss] ADD [turner_rate_mmscfd] float NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260616095811_AddCriticalRateToWellHistoryPhss'
)
BEGIN
    ALTER TABLE [well_history_phss] ADD [coleman_rate_mmscfd] float NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260616095811_AddCriticalRateToWellHistoryPhss'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260616095811_AddCriticalRateToWellHistoryPhss', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260617030324_AddWellZoneAssignmentRemarks'
)
BEGIN
    CREATE TABLE [well_zone_assignment_remarks] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [well_zone_assignment_id] uniqueidentifier NOT NULL,
        [occurred_at] datetime2 NOT NULL,
        [remarks] nvarchar(1000) NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_zone_assignment_remarks] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_zone_assignment_remarks_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_zone_assignment_remarks_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_zone_assignment_remarks_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_well_zone_assignment_remarks_well_zone_assignments_id] FOREIGN KEY ([well_zone_assignment_id]) REFERENCES [well_zone_assignments] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260617030324_AddWellZoneAssignmentRemarks'
)
BEGIN
    CREATE INDEX [IX_well_zone_assignment_remarks_created_by] ON [well_zone_assignment_remarks] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260617030324_AddWellZoneAssignmentRemarks'
)
BEGIN
    CREATE INDEX [IX_well_zone_assignment_remarks_deleted_by] ON [well_zone_assignment_remarks] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260617030324_AddWellZoneAssignmentRemarks'
)
BEGIN
    CREATE INDEX [IX_well_zone_assignment_remarks_updated_by] ON [well_zone_assignment_remarks] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260617030324_AddWellZoneAssignmentRemarks'
)
BEGIN
    CREATE INDEX [IX_wza_remarks_assignment_id_occurred_at] ON [well_zone_assignment_remarks] ([well_zone_assignment_id], [occurred_at]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260617030324_AddWellZoneAssignmentRemarks'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260617030324_AddWellZoneAssignmentRemarks', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260617082848_AlignWellAssignmentMappings'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260617082848_AlignWellAssignmentMappings', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260617091234_AddWellPlantAssignmentUniqueIndex'
)
BEGIN
    WITH ranked AS (
        SELECT id,
               ROW_NUMBER() OVER (
                   PARTITION BY well_id, well_plant_id
                   ORDER BY created_at ASC, id ASC
               ) AS rn
        FROM dbo.well_plant_assignments
        WHERE deleted_at IS NULL
    )
    UPDATE wpa
        SET wpa.deleted_at = SYSUTCDATETIME()
    FROM dbo.well_plant_assignments wpa
    INNER JOIN ranked r ON r.id = wpa.id
    WHERE r.rn > 1;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260617091234_AddWellPlantAssignmentUniqueIndex'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_well_plant_assignments_well_id_well_plant_id' AND object_id = OBJECT_ID('dbo.well_plant_assignments'))
        CREATE UNIQUE NONCLUSTERED INDEX IX_well_plant_assignments_well_id_well_plant_id
        ON dbo.well_plant_assignments (well_id, well_plant_id)
        WHERE deleted_at IS NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260617091234_AddWellPlantAssignmentUniqueIndex'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260617091234_AddWellPlantAssignmentUniqueIndex', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260617130244_AddDynamicInputsToRksMasterSubClause'
)
BEGIN
    ALTER TABLE [rks_master_sub_clause] ADD [dynamic_inputs] nvarchar(max) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260617130244_AddDynamicInputsToRksMasterSubClause'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260617130244_AddDynamicInputsToRksMasterSubClause', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE TABLE [pep_action_plan] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [well_zone_assingment_id] uniqueidentifier NULL,
        [action_plan_type] varchar(30) NULL,
        [record_state] varchar(20) NULL DEFAULT 'draft',
        [submitted_at] datetime NULL,
        [start_date] date NULL,
        [end_date] date NULL,
        [pic_id] uniqueidentifier NULL,
        [notes] nvarchar(max) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_pep_action_plan] PRIMARY KEY ([id]),
        CONSTRAINT [FK_pep_action_plan_users_pic_id] FOREIGN KEY ([pic_id]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_pep_action_plan_wells_well_id] FOREIGN KEY ([well_zone_assingment_id]) REFERENCES [wells] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE TABLE [phss_action_plan] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [well_zone_assingment_id] uniqueidentifier NULL,
        [action_plan_type] varchar(30) NULL,
        [record_state] varchar(20) NULL DEFAULT 'draft',
        [submitted_at] datetime NULL,
        [start_date] date NULL,
        [end_date] date NULL,
        [pic_id] uniqueidentifier NULL,
        [notes] nvarchar(max) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_phss_action_plan] PRIMARY KEY ([id]),
        CONSTRAINT [FK_phss_action_plan_users_pic_id] FOREIGN KEY ([pic_id]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_phss_action_plan_wells_well_id] FOREIGN KEY ([well_zone_assingment_id]) REFERENCES [wells] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE TABLE [pep_action_plan_artificial_lift] (
        [action_plan_id] uniqueidentifier NOT NULL,
        [activity_type] varchar(20) NULL,
        [action_mode] varchar(30) NULL,
        [method] varchar(20) NULL,
        [prime_mover] decimal(18,6) NULL,
        [power] decimal(18,6) NULL,
        [bean] decimal(18,6) NULL,
        [thp] decimal(18,6) NULL,
        [flowline_pressure] decimal(18,6) NULL,
        [casing_pressure] decimal(18,6) NULL,
        [separator_pressure] decimal(18,6) NULL,
        [spm_freq] decimal(18,6) NULL,
        [pump_size] decimal(18,6) NULL,
        [pump_displacement] decimal(18,6) NULL,
        [pump_efficiency] decimal(18,6) NULL,
        [stroke_length] decimal(18,6) NULL,
        [pump_intake_depth] decimal(18,6) NULL,
        [submerging] decimal(18,6) NULL,
        [production] decimal(18,6) NULL,
        [pressure] decimal(18,6) NULL,
        CONSTRAINT [PK_pep_action_plan_artificial_lift] PRIMARY KEY ([action_plan_id]),
        CONSTRAINT [FK_pep_action_plan_artificial_lift_pep_action_plan_action_plan_id] FOREIGN KEY ([action_plan_id]) REFERENCES [pep_action_plan] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE TABLE [pep_action_plan_choke] (
        [action_plan_id] uniqueidentifier NOT NULL,
        [gas] decimal(18,6) NULL,
        [oil] decimal(18,6) NULL,
        [bean_setting] varchar(100) NULL,
        [choke_setting] varchar(100) NULL,
        [relation_gain] decimal(18,6) NULL,
        [production_destination] varchar(100) NULL,
        CONSTRAINT [PK_pep_action_plan_choke] PRIMARY KEY ([action_plan_id]),
        CONSTRAINT [FK_pep_action_plan_choke_pep_action_plan_action_plan_id] FOREIGN KEY ([action_plan_id]) REFERENCES [pep_action_plan] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE TABLE [pep_action_plan_sonolog] (
        [action_plan_id] uniqueidentifier NOT NULL,
        [fluid_level] decimal(18,6) NULL,
        [pump_intake] decimal(18,6) NULL,
        CONSTRAINT [PK_pep_action_plan_sonolog] PRIMARY KEY ([action_plan_id]),
        CONSTRAINT [FK_pep_action_plan_sonolog_pep_action_plan_action_plan_id] FOREIGN KEY ([action_plan_id]) REFERENCES [pep_action_plan] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE TABLE [pep_action_plan_well_test] (
        [action_plan_id] uniqueidentifier NOT NULL,
        [well_test_action] varchar(20) NULL,
        [contract_id] uniqueidentifier NULL,
        [well_test_type] varchar(100) NULL,
        [tank_number] varchar(100) NULL,
        [start_date_time] datetime NULL,
        [end_date_time] datetime NULL,
        [planned_duration_hours] decimal(18,6) NULL,
        [actual_duration_hours] decimal(18,6) NULL,
        [gas] decimal(18,6) NULL,
        [oil] decimal(18,6) NULL,
        [u_press] decimal(18,6) NULL,
        [chp] decimal(18,6) NULL,
        [choke] decimal(18,6) NULL,
        [whfp] decimal(18,6) NULL,
        [flp] decimal(18,6) NULL,
        [gi] decimal(18,6) NULL,
        [liquid] decimal(18,6) NULL,
        [water] decimal(18,6) NULL,
        [bsw] decimal(18,6) NULL,
        [sand] decimal(18,6) NULL,
        CONSTRAINT [PK_pep_action_plan_well_test] PRIMARY KEY ([action_plan_id]),
        CONSTRAINT [FK_pep_action_plan_well_test_contracts_contract_id] FOREIGN KEY ([contract_id]) REFERENCES [contracts] ([contract_id]),
        CONSTRAINT [FK_pep_action_plan_well_test_pep_action_plan_action_plan_id] FOREIGN KEY ([action_plan_id]) REFERENCES [pep_action_plan] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE TABLE [phss_action_plan_artificial_lift] (
        [action_plan_id] uniqueidentifier NOT NULL,
        [activity_type] varchar(20) NULL,
        [action_mode] varchar(30) NULL,
        [method] varchar(20) NULL,
        [prime_mover] decimal(18,6) NULL,
        [power] decimal(18,6) NULL,
        [bean] decimal(18,6) NULL,
        [thp] decimal(18,6) NULL,
        [flowline_pressure] decimal(18,6) NULL,
        [casing_pressure] decimal(18,6) NULL,
        [separator_pressure] decimal(18,6) NULL,
        [spm_freq] decimal(18,6) NULL,
        [pump_size] decimal(18,6) NULL,
        [pump_displacement] decimal(18,6) NULL,
        [pump_efficiency] decimal(18,6) NULL,
        [stroke_length] decimal(18,6) NULL,
        [pump_intake_depth] decimal(18,6) NULL,
        [submerging] decimal(18,6) NULL,
        [production] decimal(18,6) NULL,
        [pressure] decimal(18,6) NULL,
        CONSTRAINT [PK_phss_action_plan_artificial_lift] PRIMARY KEY ([action_plan_id]),
        CONSTRAINT [FK_phss_action_plan_artificial_lift_phss_action_plan_action_plan_id] FOREIGN KEY ([action_plan_id]) REFERENCES [phss_action_plan] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE TABLE [phss_action_plan_choke] (
        [action_plan_id] uniqueidentifier NOT NULL,
        [gas] decimal(18,6) NULL,
        [oil] decimal(18,6) NULL,
        [bean_setting] varchar(100) NULL,
        [choke_setting] varchar(100) NULL,
        [relation_gain] decimal(18,6) NULL,
        [compressor_id] uniqueidentifier NULL,
        CONSTRAINT [PK_phss_action_plan_choke] PRIMARY KEY ([action_plan_id]),
        CONSTRAINT [FK_phss_action_plan_choke_compressors_compressor_id] FOREIGN KEY ([compressor_id]) REFERENCES [compressors] ([id]),
        CONSTRAINT [FK_phss_action_plan_choke_phss_action_plan_action_plan_id] FOREIGN KEY ([action_plan_id]) REFERENCES [phss_action_plan] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE TABLE [phss_action_plan_well_test] (
        [action_plan_id] uniqueidentifier NOT NULL,
        [well_test_action] varchar(20) NULL,
        [contract_id] uniqueidentifier NULL,
        [well_test_type] varchar(100) NULL,
        [gas] decimal(18,6) NULL,
        [oil] decimal(18,6) NULL,
        [u_press] decimal(18,6) NULL,
        [chp] decimal(18,6) NULL,
        [choke] decimal(18,6) NULL,
        [whfp] decimal(18,6) NULL,
        [flp] decimal(18,6) NULL,
        [gi] decimal(18,6) NULL,
        [liquid] decimal(18,6) NULL,
        [water] decimal(18,6) NULL,
        [bsw] decimal(18,6) NULL,
        [sand] decimal(18,6) NULL,
        CONSTRAINT [PK_phss_action_plan_well_test] PRIMARY KEY ([action_plan_id]),
        CONSTRAINT [FK_phss_action_plan_well_test_contracts_contract_id] FOREIGN KEY ([contract_id]) REFERENCES [contracts] ([contract_id]),
        CONSTRAINT [FK_phss_action_plan_well_test_phss_action_plan_action_plan_id] FOREIGN KEY ([action_plan_id]) REFERENCES [phss_action_plan] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE INDEX [IX_pep_action_plan_action_plan_type] ON [pep_action_plan] ([action_plan_type]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE INDEX [IX_pep_action_plan_created_by] ON [pep_action_plan] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE INDEX [IX_pep_action_plan_pic_id] ON [pep_action_plan] ([pic_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE INDEX [IX_pep_action_plan_record_state] ON [pep_action_plan] ([record_state]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE INDEX [IX_pep_action_plan_start_date] ON [pep_action_plan] ([start_date]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE INDEX [IX_pep_action_plan_well_id] ON [pep_action_plan] ([well_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE INDEX [IX_pep_action_plan_well_test_contract_id] ON [pep_action_plan_well_test] ([contract_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE INDEX [IX_phss_action_plan_action_plan_type] ON [phss_action_plan] ([action_plan_type]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE INDEX [IX_phss_action_plan_created_by] ON [phss_action_plan] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE INDEX [IX_phss_action_plan_pic_id] ON [phss_action_plan] ([pic_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE INDEX [IX_phss_action_plan_record_state] ON [phss_action_plan] ([record_state]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE INDEX [IX_phss_action_plan_start_date] ON [phss_action_plan] ([start_date]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE INDEX [IX_phss_action_plan_well_id] ON [phss_action_plan] ([well_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE INDEX [IX_phss_action_plan_choke_compressor_id] ON [phss_action_plan_choke] ([compressor_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    CREATE INDEX [IX_phss_action_plan_well_test_contract_id] ON [phss_action_plan_well_test] ([contract_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618014839_AddActionPlanTables'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260618014839_AddActionPlanTables', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618055923_RetargetActionPlanWellFkToWellZoneAssignment'
)
BEGIN
    ALTER TABLE [pep_action_plan] DROP CONSTRAINT [FK_pep_action_plan_wells_well_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618055923_RetargetActionPlanWellFkToWellZoneAssignment'
)
BEGIN
    ALTER TABLE [phss_action_plan] DROP CONSTRAINT [FK_phss_action_plan_wells_well_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618055923_RetargetActionPlanWellFkToWellZoneAssignment'
)
BEGIN
    ALTER TABLE [pep_action_plan] ADD CONSTRAINT [FK_pep_action_plan_well_zone_assignments_well_id] FOREIGN KEY ([well_id]) REFERENCES [well_zone_assignments] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618055923_RetargetActionPlanWellFkToWellZoneAssignment'
)
BEGIN
    ALTER TABLE [phss_action_plan] ADD CONSTRAINT [FK_phss_action_plan_well_zone_assignments_well_id] FOREIGN KEY ([well_id]) REFERENCES [well_zone_assignments] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618055923_RetargetActionPlanWellFkToWellZoneAssignment'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260618055923_RetargetActionPlanWellFkToWellZoneAssignment', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618060821_AddRksMasterCategory'
)
BEGIN
    CREATE TABLE [rks_master_category] (
        [category_id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [category_code] nvarchar(50) NULL,
        [category_name] nvarchar(200) NULL,
        [is_active] bit NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_rks_master_category] PRIMARY KEY ([category_id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618060821_AddRksMasterCategory'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260618060821_AddRksMasterCategory', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618061328_RetargetChokeCompressorFkToWellCompressorDestination'
)
BEGIN
    ALTER TABLE [phss_action_plan_choke] DROP CONSTRAINT [FK_phss_action_plan_choke_compressors_compressor_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618061328_RetargetChokeCompressorFkToWellCompressorDestination'
)
BEGIN
    ALTER TABLE [phss_action_plan_choke] ADD CONSTRAINT [FK_phss_action_plan_choke_well_compressor_destinations_compressor_id] FOREIGN KEY ([compressor_id]) REFERENCES [well_compressor_destinations] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618061328_RetargetChokeCompressorFkToWellCompressorDestination'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260618061328_RetargetChokeCompressorFkToWellCompressorDestination', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618082218_ChangeRksMasterClauseCategoryToCategoryId'
)
BEGIN
    ALTER TABLE [rks_master_clause] ADD [category_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618082218_ChangeRksMasterClauseCategoryToCategoryId'
)
BEGIN

    UPDATE c
    SET c.category_id = mc.category_id
    FROM rks_master_clause c
    INNER JOIN rks_master_category mc
        ON mc.category_code = c.category

END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618082218_ChangeRksMasterClauseCategoryToCategoryId'
)
BEGIN
    DECLARE @var80 sysname;
    SELECT @var80 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[rks_master_clause]') AND [c].[name] = N'category');
    IF @var80 IS NOT NULL EXEC(N'ALTER TABLE [rks_master_clause] DROP CONSTRAINT [' + @var80 + '];');
    ALTER TABLE [rks_master_clause] DROP COLUMN [category];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618082218_ChangeRksMasterClauseCategoryToCategoryId'
)
BEGIN
    DECLARE @var81 sysname;
    SELECT @var81 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[rks_master_clause]') AND [c].[name] = N'category_id');
    IF @var81 IS NOT NULL EXEC(N'ALTER TABLE [rks_master_clause] DROP CONSTRAINT [' + @var81 + '];');
    ALTER TABLE [rks_master_clause] ALTER COLUMN [category_id] uniqueidentifier NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618082218_ChangeRksMasterClauseCategoryToCategoryId'
)
BEGIN
    CREATE INDEX [IX_rks_master_clause_category_id] ON [rks_master_clause] ([category_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618082218_ChangeRksMasterClauseCategoryToCategoryId'
)
BEGIN
    ALTER TABLE [rks_master_clause] ADD CONSTRAINT [FK_rks_master_clause_rks_master_category] FOREIGN KEY ([category_id]) REFERENCES [rks_master_category] ([category_id]) ON DELETE NO ACTION;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618082218_ChangeRksMasterClauseCategoryToCategoryId'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260618082218_ChangeRksMasterClauseCategoryToCategoryId', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618094720_AddCategoryIdAndNameToRks'
)
BEGIN
    DECLARE @var82 sysname;
    SELECT @var82 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[rks]') AND [c].[name] = N'category');
    IF @var82 IS NOT NULL EXEC(N'ALTER TABLE [rks] DROP CONSTRAINT [' + @var82 + '];');
    ALTER TABLE [rks] DROP COLUMN [category];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618094720_AddCategoryIdAndNameToRks'
)
BEGIN
    ALTER TABLE [rks] ADD [category_id] uniqueidentifier NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618094720_AddCategoryIdAndNameToRks'
)
BEGIN
    ALTER TABLE [rks] ADD [category_name] nvarchar(200) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260618094720_AddCategoryIdAndNameToRks'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260618094720_AddCategoryIdAndNameToRks', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260622000001_SeedActionPlanData'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM phss_action_plan)
       AND (SELECT COUNT(*) FROM well_zone_assignments WHERE deleted_at IS NULL) >= 3
    BEGIN
        DECLARE @uid UNIQUEIDENTIFIER = (SELECT TOP 1 id FROM users ORDER BY created_at);

        -- Pick 3 WZA IDs
        DECLARE @wza1 UNIQUEIDENTIFIER, @wza2 UNIQUEIDENTIFIER, @wza3 UNIQUEIDENTIFIER;
        SELECT @wza1 = id FROM (
            SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) rn
            FROM well_zone_assignments WHERE deleted_at IS NULL
        ) t WHERE rn = 1;
        SELECT @wza2 = id FROM (
            SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) rn
            FROM well_zone_assignments WHERE deleted_at IS NULL
        ) t WHERE rn = 2;
        SELECT @wza3 = id FROM (
            SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) rn
            FROM well_zone_assignments WHERE deleted_at IS NULL
        ) t WHERE rn = 3;

        DECLARE @ap1 UNIQUEIDENTIFIER = NEWID();
        DECLARE @ap2 UNIQUEIDENTIFIER = NEWID();
        DECLARE @ap3 UNIQUEIDENTIFIER = NEWID();

        INSERT INTO phss_action_plan
            (id, well_zone_assingment_id, action_plan_type, record_state, submitted_at, start_date, end_date, notes, created_at, created_by)
        VALUES
            (@ap1, @wza1, 'choke',           'submitted', GETDATE(), '2026-06-10', '2026-06-30', 'Choke adjustment to improve gas flow rate', GETDATE(), @uid),
            (@ap2, @wza2, 'well_test',       'submitted', GETDATE(), '2026-06-15', '2026-07-15', 'Scheduled well test for production data update', GETDATE(), @uid),
            (@ap3, @wza3, 'artificial_lift', 'draft',     NULL,      '2026-07-01', NULL,         'Pump adjustment plan for declining production', GETDATE(), @uid);

        INSERT INTO phss_action_plan_choke (action_plan_id, gas, oil, bean_setting, choke_setting, relation_gain)
        VALUES (@ap1, 1500.00, 85.00, 'bean_16_64', 'choke_16_64', 16.50);

        INSERT INTO phss_action_plan_well_test (action_plan_id, well_test_action, well_test_type, gas, oil, liquid, water, bsw)
        VALUES (@ap2, 'perform_well_test', 'conventional', 1200.00, 60.00, 200.00, 140.00, 70.00);

        INSERT INTO phss_action_plan_artificial_lift (action_plan_id, activity_type, action_mode, method, prime_mover, power)
        VALUES (@ap3, 'adjustment', 'adjustment_schedule', 'pump', 45.00, 22.00);
    END
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260622000001_SeedActionPlanData'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pep_action_plan)
       AND (SELECT COUNT(*) FROM well_zone_assignments WHERE deleted_at IS NULL) >= 4
    BEGIN
        DECLARE @uid UNIQUEIDENTIFIER = (SELECT TOP 1 id FROM users ORDER BY created_at);

        -- Pick WZAs 1-4 (may overlap with PHSS seed — different action plan tables)
        DECLARE @wza1 UNIQUEIDENTIFIER, @wza2 UNIQUEIDENTIFIER,
                @wza3 UNIQUEIDENTIFIER, @wza4 UNIQUEIDENTIFIER;
        SELECT @wza1 = id FROM (
            SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) rn
            FROM well_zone_assignments WHERE deleted_at IS NULL
        ) t WHERE rn = 1;
        SELECT @wza2 = id FROM (
            SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) rn
            FROM well_zone_assignments WHERE deleted_at IS NULL
        ) t WHERE rn = 2;
        SELECT @wza3 = id FROM (
            SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) rn
            FROM well_zone_assignments WHERE deleted_at IS NULL
        ) t WHERE rn = 3;
        SELECT @wza4 = id FROM (
            SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) rn
            FROM well_zone_assignments WHERE deleted_at IS NULL
        ) t WHERE rn = 4;

        DECLARE @ap1 UNIQUEIDENTIFIER = NEWID();
        DECLARE @ap2 UNIQUEIDENTIFIER = NEWID();
        DECLARE @ap3 UNIQUEIDENTIFIER = NEWID();
        DECLARE @ap4 UNIQUEIDENTIFIER = NEWID();

        INSERT INTO pep_action_plan
            (id, well_zone_assignment_id, action_plan_type, record_state, submitted_at, start_date, end_date, notes, created_at, created_by)
        VALUES
            (@ap1, @wza1, 'choke',           'submitted', GETDATE(), '2026-06-12', '2026-07-12', 'Choke size increase after recent well test results', GETDATE(), @uid),
            (@ap2, @wza2, 'sonolog',         'submitted', GETDATE(), '2026-06-17', '2026-06-17', 'Sonolog survey to measure fluid level and pump intake', GETDATE(), @uid),
            (@ap3, @wza3, 'well_test',       'draft',     NULL,      '2026-07-05', '2026-07-20', 'Planned well test for zone evaluation', GETDATE(), @uid),
            (@ap4, @wza4, 'artificial_lift', 'draft',     NULL,      '2026-07-10', NULL,         'ESP installation plan for new zone activation', GETDATE(), @uid);

        INSERT INTO pep_action_plan_choke (action_plan_id, gas, oil, bean_setting, choke_setting, relation_gain, production_destination)
        VALUES (@ap1, 800.00, 120.00, 'bean_24_64', 'choke_24_64', 24.00, 'export');

        INSERT INTO pep_action_plan_sonolog (action_plan_id, fluid_level, pump_intake)
        VALUES (@ap2, 650.00, 820.00);

        INSERT INTO pep_action_plan_well_test
            (action_plan_id, well_test_action, well_test_type, planned_duration_hours, gas, oil, liquid, water, bsw, choke, whfp)
        VALUES (@ap3, 'schedule', 'conventional', 24.00, 950.00, 75.00, 180.00, 105.00, 58.00, 24.00, 420.00);

        INSERT INTO pep_action_plan_artificial_lift (action_plan_id, activity_type, action_mode, method, production, pressure)
        VALUES (@ap4, 'installation', 'installation_schedule', 'pump', 300.00, 150.00);
    END
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260622000001_SeedActionPlanData'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260622000001_SeedActionPlanData', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260622073853_AddWellDeclineRates'
)
BEGIN
    CREATE TABLE [well_decline_rates] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [well_id] uniqueidentifier NOT NULL,
        [eur] float NOT NULL,
        [peak_production] float NOT NULL,
        [cumulative_production] float NOT NULL,
        [remaining_reserves] float NOT NULL,
        [median_monthly_decline] float NOT NULL,
        [annualized_decline] float NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_decline_rates] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_decline_rates_wells_well_id] FOREIGN KEY ([well_id]) REFERENCES [wells] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260622073853_AddWellDeclineRates'
)
BEGIN
    CREATE INDEX [IX_well_decline_rates_well_id] ON [well_decline_rates] ([well_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260622073853_AddWellDeclineRates'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260622073853_AddWellDeclineRates', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260623052132_AdjustmentEntityProject'
)
BEGIN
    ALTER TABLE [projects] ADD [potential_gain_unit] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260623052132_AdjustmentEntityProject'
)
BEGIN
    ALTER TABLE [projects] ADD [potential_gain_value] decimal(18,2) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260623052132_AdjustmentEntityProject'
)
BEGIN
    ALTER TABLE [projects] ADD [remarks] nvarchar(500) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260623052132_AdjustmentEntityProject'
)
BEGIN
    CREATE TABLE [project_pics] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [project_id] uniqueidentifier NULL,
        [user_id] uniqueidentifier NULL,
        [created_at] datetime NULL,
        [created_by] uniqueidentifier NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_project_pics] PRIMARY KEY ([id]),
        CONSTRAINT [FK_project_pics_projects_project_id] FOREIGN KEY ([project_id]) REFERENCES [projects] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_project_pics_users_user_id] FOREIGN KEY ([user_id]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260623052132_AdjustmentEntityProject'
)
BEGIN
    CREATE INDEX [IX_project_pics_project_id] ON [project_pics] ([project_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260623052132_AdjustmentEntityProject'
)
BEGIN
    CREATE INDEX [IX_project_pics_user_id] ON [project_pics] ([user_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260623052132_AdjustmentEntityProject'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_project_pics_project_user] ON [project_pics] ([project_id], [user_id]) WHERE [project_id] IS NOT NULL AND [user_id] IS NOT NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260623052132_AdjustmentEntityProject'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260623052132_AdjustmentEntityProject', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260623081003_ChangeRksCurrencyToString'
)
BEGIN
    DECLARE @var83 sysname;
    SELECT @var83 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[rks]') AND [c].[name] = N'currency');
    IF @var83 IS NOT NULL EXEC(N'ALTER TABLE [rks] DROP CONSTRAINT [' + @var83 + '];');
    ALTER TABLE [rks] ALTER COLUMN [currency] nvarchar(10) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260623081003_ChangeRksCurrencyToString'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260623081003_ChangeRksCurrencyToString', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260623134358_AddMaterialOverhaulBrand'
)
BEGIN
    CREATE TABLE [material_overhaul_brands] (
        [brand_id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [brand_name] nvarchar(200) NOT NULL,
        [description] nvarchar(500) NULL,
        [is_active] bit NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_material_overhaul_brands] PRIMARY KEY ([brand_id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260623134358_AddMaterialOverhaulBrand'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260623134358_AddMaterialOverhaulBrand', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260623154802_AddMaterialOverhaulPackage'
)
BEGIN
    CREATE TABLE [material_overhaul_packages] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [brand_id] uniqueidentifier NOT NULL,
        [package_name] nvarchar(200) NOT NULL,
        [engine] nvarchar(100) NOT NULL,
        [description] nvarchar(500) NULL,
        [from_hour] int NOT NULL,
        [to_hour] int NOT NULL,
        [is_active] bit NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_material_overhaul_packages] PRIMARY KEY ([id]),
        CONSTRAINT [FK_material_overhaul_packages_material_overhaul_brands] FOREIGN KEY ([brand_id]) REFERENCES [material_overhaul_brands] ([brand_id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260623154802_AddMaterialOverhaulPackage'
)
BEGIN
    CREATE INDEX [IX_material_overhaul_packages_brand_id] ON [material_overhaul_packages] ([brand_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260623154802_AddMaterialOverhaulPackage'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260623154802_AddMaterialOverhaulPackage', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624024129_AddMaterialOverhaulPackageMaterial'
)
BEGIN
    CREATE TABLE [material_overhaul_package_materials] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [package_id] uniqueidentifier NOT NULL,
        [kimap] nvarchar(100) NOT NULL,
        [part_number] nvarchar(100) NOT NULL,
        [material_name] nvarchar(255) NOT NULL,
        [uom] nvarchar(50) NOT NULL,
        [quantity] decimal(18,2) NOT NULL,
        [notes] nvarchar(500) NULL,
        [is_active] bit NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_material_overhaul_package_materials] PRIMARY KEY ([id]),
        CONSTRAINT [FK_material_overhaul_package_materials_material_overhaul_packages] FOREIGN KEY ([package_id]) REFERENCES [material_overhaul_packages] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624024129_AddMaterialOverhaulPackageMaterial'
)
BEGIN
    CREATE INDEX [IX_material_overhaul_package_materials_package_id] ON [material_overhaul_package_materials] ([package_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624024129_AddMaterialOverhaulPackageMaterial'
)
BEGIN
    CREATE UNIQUE INDEX [UX_material_overhaul_package_materials_package_id_kimap] ON [material_overhaul_package_materials] ([package_id], [kimap]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624024129_AddMaterialOverhaulPackageMaterial'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260624024129_AddMaterialOverhaulPackageMaterial', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624063001_AlterColumnNumericPrecision'
)
BEGIN
    DECLARE @var84 sysname;
    SELECT @var84 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[spk_cost_allocations]') AND [c].[name] = N'cost_allocation');
    IF @var84 IS NOT NULL EXEC(N'ALTER TABLE [spk_cost_allocations] DROP CONSTRAINT [' + @var84 + '];');
    ALTER TABLE [spk_cost_allocations] ALTER COLUMN [cost_allocation] numeric(18,2) NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624063001_AlterColumnNumericPrecision'
)
BEGIN
    DECLARE @var85 sysname;
    SELECT @var85 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[invoices]') AND [c].[name] = N'sa_amount');
    IF @var85 IS NOT NULL EXEC(N'ALTER TABLE [invoices] DROP CONSTRAINT [' + @var85 + '];');
    ALTER TABLE [invoices] ALTER COLUMN [sa_amount] numeric(18,2) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624063001_AlterColumnNumericPrecision'
)
BEGIN
    DECLARE @var86 sysname;
    SELECT @var86 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[invoices]') AND [c].[name] = N'retention_amount');
    IF @var86 IS NOT NULL EXEC(N'ALTER TABLE [invoices] DROP CONSTRAINT [' + @var86 + '];');
    ALTER TABLE [invoices] ALTER COLUMN [retention_amount] numeric(18,2) NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624063001_AlterColumnNumericPrecision'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260624063001_AlterColumnNumericPrecision', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624072854_AddTemplatesTable'
)
BEGIN
    CREATE TABLE [templates] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [name] nvarchar(255) NOT NULL,
        [module] nvarchar(100) NOT NULL,
        [description] nvarchar(500) NULL,
        [file_url] nvarchar(500) NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_templates] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624072854_AddTemplatesTable'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260624072854_AddTemplatesTable', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624082247_AddWellStatus'
)
BEGIN
    ALTER TABLE [wells] ADD [status] nvarchar(20) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624082247_AddWellStatus'
)
BEGIN
    ;WITH firsts AS (
        SELECT well_id, status,
               ROW_NUMBER() OVER (PARTITION BY well_id ORDER BY created_at ASC, id ASC) AS rn
        FROM well_zone_assignments
        WHERE deleted_at IS NULL
    )
    UPDATE w SET w.status = f.status
    FROM wells w
    INNER JOIN firsts f ON w.id = f.well_id
    WHERE f.rn = 1;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624082247_AddWellStatus'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260624082247_AddWellStatus', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624085442_AddMaterialOverhaulBrandType'
)
BEGIN
    CREATE TABLE [material_overhaul_brand_types] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [brand_id] uniqueidentifier NOT NULL,
        [type_name] nvarchar(200) NOT NULL,
        [description] nvarchar(500) NULL,
        [is_active] bit NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_material_overhaul_brand_types] PRIMARY KEY ([id]),
        CONSTRAINT [FK_material_overhaul_brand_types_material_overhaul_brands] FOREIGN KEY ([brand_id]) REFERENCES [material_overhaul_brands] ([brand_id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624085442_AddMaterialOverhaulBrandType'
)
BEGIN
    CREATE INDEX [IX_material_overhaul_brand_types_brand_id] ON [material_overhaul_brand_types] ([brand_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624085442_AddMaterialOverhaulBrandType'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260624085442_AddMaterialOverhaulBrandType', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624101051_AddMaterialOverhaulEngine'
)
BEGIN
    CREATE TABLE [material_overhaul_engines] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [engine_name] nvarchar(200) NOT NULL,
        [description] nvarchar(500) NULL,
        [is_active] bit NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_material_overhaul_engines] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624101051_AddMaterialOverhaulEngine'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260624101051_AddMaterialOverhaulEngine', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624120347_AddMaterialOverhaulEngineType'
)
BEGIN
    CREATE TABLE [material_overhaul_engine_types] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [engine_id] uniqueidentifier NOT NULL,
        [type_name] nvarchar(200) NOT NULL,
        [description] nvarchar(500) NULL,
        [is_active] bit NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_material_overhaul_engine_types] PRIMARY KEY ([id]),
        CONSTRAINT [FK_material_overhaul_engine_types_material_overhaul_engines] FOREIGN KEY ([engine_id]) REFERENCES [material_overhaul_engines] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624120347_AddMaterialOverhaulEngineType'
)
BEGIN
    CREATE INDEX [IX_material_overhaul_engine_types_engine_id] ON [material_overhaul_engine_types] ([engine_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624120347_AddMaterialOverhaulEngineType'
)
BEGIN
    CREATE UNIQUE INDEX [UX_material_overhaul_engine_types_engine_id_type_name] ON [material_overhaul_engine_types] ([engine_id], [type_name]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624120347_AddMaterialOverhaulEngineType'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260624120347_AddMaterialOverhaulEngineType', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624161736_RefactorMaterialOverhaulPackageToBrandTypeServicePackage'
)
BEGIN
    ALTER TABLE [material_overhaul_package_materials] DROP CONSTRAINT [FK_material_overhaul_package_materials_material_overhaul_packages];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624161736_RefactorMaterialOverhaulPackageToBrandTypeServicePackage'
)
BEGIN
    ALTER TABLE [material_overhaul_packages] DROP CONSTRAINT [FK_material_overhaul_packages_material_overhaul_brands];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624161736_RefactorMaterialOverhaulPackageToBrandTypeServicePackage'
)
BEGIN
    EXEC sp_rename N'[material_overhaul_packages]', N'material_overhaul_brand_type_service_packages', 'OBJECT';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624161736_RefactorMaterialOverhaulPackageToBrandTypeServicePackage'
)
BEGIN
    ALTER TABLE [material_overhaul_brand_type_service_packages] DROP CONSTRAINT [PK_material_overhaul_packages];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624161736_RefactorMaterialOverhaulPackageToBrandTypeServicePackage'
)
BEGIN
    ALTER TABLE [material_overhaul_brand_type_service_packages] ADD CONSTRAINT [PK_material_overhaul_brand_type_service_packages] PRIMARY KEY ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624161736_RefactorMaterialOverhaulPackageToBrandTypeServicePackage'
)
BEGIN
    EXEC sp_rename N'[material_overhaul_brand_type_service_packages].[brand_id]', N'brand_type_id', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624161736_RefactorMaterialOverhaulPackageToBrandTypeServicePackage'
)
BEGIN
    EXEC sp_rename N'[material_overhaul_brand_type_service_packages].[IX_material_overhaul_packages_brand_id]', N'IX_material_overhaul_brand_type_service_packages_brand_type_id', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624161736_RefactorMaterialOverhaulPackageToBrandTypeServicePackage'
)
BEGIN
    DECLARE @var87 sysname;
    SELECT @var87 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[material_overhaul_brand_type_service_packages]') AND [c].[name] = N'engine');
    IF @var87 IS NOT NULL EXEC(N'ALTER TABLE [material_overhaul_brand_type_service_packages] DROP CONSTRAINT [' + @var87 + '];');
    ALTER TABLE [material_overhaul_brand_type_service_packages] DROP COLUMN [engine];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624161736_RefactorMaterialOverhaulPackageToBrandTypeServicePackage'
)
BEGIN
    CREATE UNIQUE INDEX [UX_material_overhaul_brand_type_service_packages_brand_type_id_package_name] ON [material_overhaul_brand_type_service_packages] ([brand_type_id], [package_name]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624161736_RefactorMaterialOverhaulPackageToBrandTypeServicePackage'
)
BEGIN
    ALTER TABLE [material_overhaul_brand_type_service_packages] ADD CONSTRAINT [FK_material_overhaul_brand_type_service_packages_material_overhaul_brand_types] FOREIGN KEY ([brand_type_id]) REFERENCES [material_overhaul_brand_types] ([id]) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624161736_RefactorMaterialOverhaulPackageToBrandTypeServicePackage'
)
BEGIN
    ALTER TABLE [material_overhaul_package_materials] ADD CONSTRAINT [FK_material_overhaul_package_materials_material_overhaul_brand_type_service_packages] FOREIGN KEY ([package_id]) REFERENCES [material_overhaul_brand_type_service_packages] ([id]) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624161736_RefactorMaterialOverhaulPackageToBrandTypeServicePackage'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260624161736_RefactorMaterialOverhaulPackageToBrandTypeServicePackage', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624173702_AddMaterialOverhaulEngineTypeServicePackage'
)
BEGIN
    CREATE TABLE [material_overhaul_engine_type_service_packages] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [engine_type_id] uniqueidentifier NOT NULL,
        [package_name] nvarchar(200) NOT NULL,
        [description] nvarchar(500) NULL,
        [from_hour] int NOT NULL,
        [to_hour] int NOT NULL,
        [is_active] bit NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_material_overhaul_engine_type_service_packages] PRIMARY KEY ([id]),
        CONSTRAINT [FK_material_overhaul_engine_type_service_packages_material_overhaul_engine_types] FOREIGN KEY ([engine_type_id]) REFERENCES [material_overhaul_engine_types] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624173702_AddMaterialOverhaulEngineTypeServicePackage'
)
BEGIN
    CREATE INDEX [IX_material_overhaul_engine_type_service_packages_engine_type_id] ON [material_overhaul_engine_type_service_packages] ([engine_type_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624173702_AddMaterialOverhaulEngineTypeServicePackage'
)
BEGIN
    CREATE UNIQUE INDEX [UX_material_overhaul_engine_type_service_packages_engine_type_id_package_name] ON [material_overhaul_engine_type_service_packages] ([engine_type_id], [package_name]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624173702_AddMaterialOverhaulEngineTypeServicePackage'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260624173702_AddMaterialOverhaulEngineTypeServicePackage', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624191445_AddMaterialOverhaulBrandTypeServicePackageMaterial'
)
BEGIN
    DROP TABLE [material_overhaul_package_materials];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624191445_AddMaterialOverhaulBrandTypeServicePackageMaterial'
)
BEGIN
    CREATE TABLE [material_overhaul_brand_type_service_package_materials] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [package_id] uniqueidentifier NOT NULL,
        [kimap] nvarchar(100) NOT NULL,
        [part_number] nvarchar(100) NOT NULL,
        [material_name] nvarchar(255) NOT NULL,
        [uom] nvarchar(50) NOT NULL,
        [quantity] decimal(18,2) NOT NULL,
        [notes] nvarchar(500) NULL,
        [is_active] bit NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_material_overhaul_brand_type_service_package_materials] PRIMARY KEY ([id]),
        CONSTRAINT [FK_material_overhaul_brand_type_service_package_materials_material_overhaul_brand_type_service_packages] FOREIGN KEY ([package_id]) REFERENCES [material_overhaul_brand_type_service_packages] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624191445_AddMaterialOverhaulBrandTypeServicePackageMaterial'
)
BEGIN
    CREATE INDEX [IX_material_overhaul_brand_type_service_package_materials_package_id] ON [material_overhaul_brand_type_service_package_materials] ([package_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624191445_AddMaterialOverhaulBrandTypeServicePackageMaterial'
)
BEGIN
    CREATE UNIQUE INDEX [UX_material_overhaul_brand_type_service_package_materials_package_id_kimap] ON [material_overhaul_brand_type_service_package_materials] ([package_id], [kimap]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624191445_AddMaterialOverhaulBrandTypeServicePackageMaterial'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260624191445_AddMaterialOverhaulBrandTypeServicePackageMaterial', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624204531_AddMaterialOverhaulEngineTypeServicePackageMaterial'
)
BEGIN
    CREATE TABLE [material_overhaul_engine_type_service_package_materials] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [package_id] uniqueidentifier NOT NULL,
        [kimap] nvarchar(100) NOT NULL,
        [part_number] nvarchar(100) NOT NULL,
        [material_name] nvarchar(255) NOT NULL,
        [uom] nvarchar(50) NOT NULL,
        [quantity] decimal(18,2) NOT NULL,
        [notes] nvarchar(500) NULL,
        [is_active] bit NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_material_overhaul_engine_type_service_package_materials] PRIMARY KEY ([id]),
        CONSTRAINT [FK_material_overhaul_engine_type_service_package_materials_material_overhaul_engine_type_service_packages] FOREIGN KEY ([package_id]) REFERENCES [material_overhaul_engine_type_service_packages] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624204531_AddMaterialOverhaulEngineTypeServicePackageMaterial'
)
BEGIN
    CREATE INDEX [IX_material_overhaul_engine_type_service_package_materials_package_id] ON [material_overhaul_engine_type_service_package_materials] ([package_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624204531_AddMaterialOverhaulEngineTypeServicePackageMaterial'
)
BEGIN
    CREATE UNIQUE INDEX [UX_material_overhaul_engine_type_service_package_materials_package_id_kimap] ON [material_overhaul_engine_type_service_package_materials] ([package_id], [kimap]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260624204531_AddMaterialOverhaulEngineTypeServicePackageMaterial'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260624204531_AddMaterialOverhaulEngineTypeServicePackageMaterial', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260625031859_FixMaterialOverhaulFilteredUniqueIndexes'
)
BEGIN
    IF OBJECT_ID(
            N'dbo.material_overhaul_package_materials'
        ) IS NOT NULL
    BEGIN

        IF EXISTS
        (
            SELECT 1
            FROM sys.indexes
            WHERE
                name =
                    'UX_material_overhaul_package_materials_package_id_kimap'
                AND object_id =
                    OBJECT_ID(
                        N'dbo.material_overhaul_package_materials')
        )
        BEGIN
            DROP INDEX
                UX_material_overhaul_package_materials_package_id_kimap
            ON dbo.material_overhaul_package_materials;
        END

        IF NOT EXISTS
        (
            SELECT 1
            FROM sys.indexes
            WHERE
                name =
                    'UX_material_overhaul_package_materials_package_id_kimap'
                AND object_id =
                    OBJECT_ID(
                        N'dbo.material_overhaul_package_materials')
        )
        BEGIN
            CREATE UNIQUE NONCLUSTERED INDEX
                UX_material_overhaul_package_materials_package_id_kimap
            ON dbo.material_overhaul_package_materials
            (
                package_id,
                kimap
            )
            WHERE deleted_at IS NULL;
        END

    END
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260625031859_FixMaterialOverhaulFilteredUniqueIndexes'
)
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE
            name = 'UX_material_overhaul_engine_types_engine_id_type_name'
            AND object_id =
                OBJECT_ID(N'dbo.material_overhaul_engine_types')
    )
    BEGIN
        DROP INDEX
            UX_material_overhaul_engine_types_engine_id_type_name
        ON dbo.material_overhaul_engine_types;
    END

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE
            name = 'UX_material_overhaul_engine_types_engine_id_type_name'
            AND object_id =
                OBJECT_ID(N'dbo.material_overhaul_engine_types')
    )
    BEGIN
        CREATE UNIQUE NONCLUSTERED INDEX
            UX_material_overhaul_engine_types_engine_id_type_name
        ON dbo.material_overhaul_engine_types
        (
            engine_id,
            type_name
        )
        WHERE deleted_at IS NULL;
    END
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260625031859_FixMaterialOverhaulFilteredUniqueIndexes'
)
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE
            name =
                'UX_material_overhaul_brand_types_brand_id_type_name'
            AND object_id =
                OBJECT_ID(
                    N'dbo.material_overhaul_brand_types')
    )
    BEGIN
        DROP INDEX
            UX_material_overhaul_brand_types_brand_id_type_name
        ON dbo.material_overhaul_brand_types;
    END

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE
            name =
                'UX_material_overhaul_brand_types_brand_id_type_name'
            AND object_id =
                OBJECT_ID(
                    N'dbo.material_overhaul_brand_types')
    )
    BEGIN
        CREATE UNIQUE NONCLUSTERED INDEX
            UX_material_overhaul_brand_types_brand_id_type_name
        ON dbo.material_overhaul_brand_types
        (
            brand_id,
            type_name
        )
        WHERE deleted_at IS NULL;
    END
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260625031859_FixMaterialOverhaulFilteredUniqueIndexes'
)
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE
            name =
                'UX_material_overhaul_brand_type_service_packages_brand_type_id_package_name'
            AND object_id =
                OBJECT_ID(
                    N'dbo.material_overhaul_brand_type_service_packages')
    )
    BEGIN
        DROP INDEX
            UX_material_overhaul_brand_type_service_packages_brand_type_id_package_name
        ON dbo.material_overhaul_brand_type_service_packages;
    END

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE
            name =
                'UX_material_overhaul_brand_type_service_packages_brand_type_id_package_name'
            AND object_id =
                OBJECT_ID(
                    N'dbo.material_overhaul_brand_type_service_packages')
    )
    BEGIN
        CREATE UNIQUE NONCLUSTERED INDEX
            UX_material_overhaul_brand_type_service_packages_brand_type_id_package_name
        ON dbo.material_overhaul_brand_type_service_packages
        (
            brand_type_id,
            package_name
        )
        WHERE deleted_at IS NULL;
    END
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260625031859_FixMaterialOverhaulFilteredUniqueIndexes'
)
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE
            name =
                'UX_material_overhaul_engine_type_service_packages_engine_type_id_package_name'
            AND object_id =
                OBJECT_ID(
                    N'dbo.material_overhaul_engine_type_service_packages')
    )
    BEGIN
        DROP INDEX
            UX_material_overhaul_engine_type_service_packages_engine_type_id_package_name
        ON dbo.material_overhaul_engine_type_service_packages;
    END

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE
            name =
                'UX_material_overhaul_engine_type_service_packages_engine_type_id_package_name'
            AND object_id =
                OBJECT_ID(
                    N'dbo.material_overhaul_engine_type_service_packages')
    )
    BEGIN
        CREATE UNIQUE NONCLUSTERED INDEX
            UX_material_overhaul_engine_type_service_packages_engine_type_id_package_name
        ON dbo.material_overhaul_engine_type_service_packages
        (
            engine_type_id,
            package_name
        )
        WHERE deleted_at IS NULL;
    END
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260625031859_FixMaterialOverhaulFilteredUniqueIndexes'
)
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE
            name =
                'UX_material_overhaul_brand_type_service_package_materials_package_id_kimap'
            AND object_id =
                OBJECT_ID(
                    N'dbo.material_overhaul_brand_type_service_package_materials')
    )
    BEGIN
        DROP INDEX
            UX_material_overhaul_brand_type_service_package_materials_package_id_kimap
        ON dbo.material_overhaul_brand_type_service_package_materials;
    END

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE
            name =
                'UX_material_overhaul_brand_type_service_package_materials_package_id_kimap'
            AND object_id =
                OBJECT_ID(
                    N'dbo.material_overhaul_brand_type_service_package_materials')
    )
    BEGIN
        CREATE UNIQUE NONCLUSTERED INDEX
            UX_material_overhaul_brand_type_service_package_materials_package_id_kimap
        ON dbo.material_overhaul_brand_type_service_package_materials
        (
            package_id,
            kimap
        )
        WHERE deleted_at IS NULL;
    END
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260625031859_FixMaterialOverhaulFilteredUniqueIndexes'
)
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE
            name =
                'UX_material_overhaul_engine_type_service_package_materials_package_id_kimap'
            AND object_id =
                OBJECT_ID(
                    N'dbo.material_overhaul_engine_type_service_package_materials')
    )
    BEGIN
        DROP INDEX
            UX_material_overhaul_engine_type_service_package_materials_package_id_kimap
        ON dbo.material_overhaul_engine_type_service_package_materials;
    END

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE
            name =
                'UX_material_overhaul_engine_type_service_package_materials_package_id_kimap'
            AND object_id =
                OBJECT_ID(
                    N'dbo.material_overhaul_engine_type_service_package_materials')
    )
    BEGIN
        CREATE UNIQUE NONCLUSTERED INDEX
            UX_material_overhaul_engine_type_service_package_materials_package_id_kimap
        ON dbo.material_overhaul_engine_type_service_package_materials
        (
            package_id,
            kimap
        )
        WHERE deleted_at IS NULL;
    END
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260625031859_FixMaterialOverhaulFilteredUniqueIndexes'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260625031859_FixMaterialOverhaulFilteredUniqueIndexes', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260625071806_AdjustmentLengtCodeProjectTaskBoq'
)
BEGIN
    DECLARE @var88 sysname;
    SELECT @var88 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[project_task_boqs]') AND [c].[name] = N'code');
    IF @var88 IS NOT NULL EXEC(N'ALTER TABLE [project_task_boqs] DROP CONSTRAINT [' + @var88 + '];');
    ALTER TABLE [project_task_boqs] ALTER COLUMN [code] varchar(50) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260625071806_AdjustmentLengtCodeProjectTaskBoq'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260625071806_AdjustmentLengtCodeProjectTaskBoq', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260625072746_AddWellHistorianRaw'
)
BEGIN
    CREATE TABLE [well_historian_raws] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [well_name] nvarchar(100) NOT NULL,
        [date] date NOT NULL,
        [press] decimal(18,2) NULL,
        [dpress] decimal(18,2) NULL,
        [temp] decimal(18,2) NULL,
        [flow] decimal(18,2) NULL,
        [created_at] datetime2 NOT NULL,
        [updated_at] datetime2 NULL,
        [deleted_at] datetime2 NULL,
        CONSTRAINT [PK_well_historian_raws] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260625072746_AddWellHistorianRaw'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260625072746_AddWellHistorianRaw', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626025808_AddPorosityNetSandNetPayWellZoneAssignment'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [porosity] decimal(18,4) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626025808_AddPorosityNetSandNetPayWellZoneAssignment'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [net_sand] decimal(18,4) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626025808_AddPorosityNetSandNetPayWellZoneAssignment'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [net_pay] decimal(18,4) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626025808_AddPorosityNetSandNetPayWellZoneAssignment'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260626025808_AddPorosityNetSandNetPayWellZoneAssignment', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [material_overhaul_brand_type_service_package_materials] DROP CONSTRAINT [FK_material_overhaul_brand_type_service_package_materials_material_overhaul_brand_type_service_packages];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [material_overhaul_brand_type_service_packages] DROP CONSTRAINT [FK_material_overhaul_brand_type_service_packages_material_overhaul_brand_types];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [material_overhaul_brand_types] DROP CONSTRAINT [FK_material_overhaul_brand_types_material_overhaul_brands];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [material_overhaul_engine_type_service_package_materials] DROP CONSTRAINT [FK_material_overhaul_engine_type_service_package_materials_material_overhaul_engine_type_service_packages];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [material_overhaul_engine_type_service_packages] DROP CONSTRAINT [FK_material_overhaul_engine_type_service_packages_material_overhaul_engine_types];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [material_overhaul_engine_types] DROP CONSTRAINT [FK_material_overhaul_engine_types_material_overhaul_engines];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [material_overhaul_brands] DROP CONSTRAINT [PK_material_overhaul_brands];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [material_overhaul_brand_types] DROP CONSTRAINT [PK_material_overhaul_brand_types];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [material_overhaul_brand_type_service_packages] DROP CONSTRAINT [PK_material_overhaul_brand_type_service_packages];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [material_overhaul_brand_type_service_package_materials] DROP CONSTRAINT [PK_material_overhaul_brand_type_service_package_materials];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [material_overhaul_engines] DROP CONSTRAINT [PK_material_overhaul_engines];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [material_overhaul_engine_types] DROP CONSTRAINT [PK_material_overhaul_engine_types];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [material_overhaul_engine_type_service_packages] DROP CONSTRAINT [PK_material_overhaul_engine_type_service_packages];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [material_overhaul_engine_type_service_package_materials] DROP CONSTRAINT [PK_material_overhaul_engine_type_service_package_materials];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    EXEC sp_rename N'[material_overhaul_brands]', N'compressor_brands', 'OBJECT';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    EXEC sp_rename N'[material_overhaul_brand_types]', N'compressor_brand_types', 'OBJECT';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    EXEC sp_rename N'[material_overhaul_brand_type_service_packages]', N'compressor_brand_type_service_packages', 'OBJECT';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    EXEC sp_rename N'[material_overhaul_brand_type_service_package_materials]', N'compressor_brand_type_service_package_materials', 'OBJECT';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    EXEC sp_rename N'[material_overhaul_engines]', N'compressor_engines', 'OBJECT';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    EXEC sp_rename N'[material_overhaul_engine_types]', N'compressor_engine_types', 'OBJECT';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    EXEC sp_rename N'[material_overhaul_engine_type_service_packages]', N'compressor_engine_type_service_packages', 'OBJECT';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    EXEC sp_rename N'[material_overhaul_engine_type_service_package_materials]', N'compressor_engine_type_service_package_materials', 'OBJECT';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    EXEC sp_rename N'[compressor_brand_types].[IX_material_overhaul_brand_types_brand_id]', N'IX_compressor_brand_types_brand_id', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    EXEC sp_rename N'[compressor_brand_type_service_packages].[IX_material_overhaul_brand_type_service_packages_brand_type_id]', N'IX_compressor_brand_type_service_packages_brand_type_id', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    EXEC sp_rename N'[compressor_brand_type_service_packages].[UX_material_overhaul_brand_type_service_packages_brand_type_id_package_name]', N'UX_compressor_brand_type_service_packages_brand_type_id_package_name', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    EXEC sp_rename N'[compressor_brand_type_service_package_materials].[IX_material_overhaul_brand_type_service_package_materials_package_id]', N'IX_compressor_brand_type_service_package_materials_package_id', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    EXEC sp_rename N'[compressor_brand_type_service_package_materials].[UX_material_overhaul_brand_type_service_package_materials_package_id_kimap]', N'UX_compressor_brand_type_service_package_materials_package_id_kimap', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    EXEC sp_rename N'[compressor_engine_types].[IX_material_overhaul_engine_types_engine_id]', N'IX_compressor_engine_types_engine_id', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    EXEC sp_rename N'[compressor_engine_type_service_packages].[IX_material_overhaul_engine_type_service_packages_engine_type_id]', N'IX_compressor_engine_type_service_packages_engine_type_id', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    EXEC sp_rename N'[compressor_engine_type_service_packages].[UX_material_overhaul_engine_type_service_packages_engine_type_id_package_name]', N'UX_compressor_engine_type_service_packages_engine_type_id_package_name', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    EXEC sp_rename N'[compressor_engine_type_service_package_materials].[IX_material_overhaul_engine_type_service_package_materials_package_id]', N'IX_compressor_engine_type_service_package_materials_package_id', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    EXEC sp_rename N'[compressor_engine_type_service_package_materials].[UX_material_overhaul_engine_type_service_package_materials_package_id_kimap]', N'UX_compressor_engine_type_service_package_materials_package_id_kimap', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [compressor_brands] ADD CONSTRAINT [PK_compressor_brands] PRIMARY KEY ([brand_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [compressor_brand_types] ADD CONSTRAINT [PK_compressor_brand_types] PRIMARY KEY ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [compressor_brand_type_service_packages] ADD CONSTRAINT [PK_compressor_brand_type_service_packages] PRIMARY KEY ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [compressor_brand_type_service_package_materials] ADD CONSTRAINT [PK_compressor_brand_type_service_package_materials] PRIMARY KEY ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [compressor_engines] ADD CONSTRAINT [PK_compressor_engines] PRIMARY KEY ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [compressor_engine_types] ADD CONSTRAINT [PK_compressor_engine_types] PRIMARY KEY ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [compressor_engine_type_service_packages] ADD CONSTRAINT [PK_compressor_engine_type_service_packages] PRIMARY KEY ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [compressor_engine_type_service_package_materials] ADD CONSTRAINT [PK_compressor_engine_type_service_package_materials] PRIMARY KEY ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [compressor_brand_types] ADD CONSTRAINT [FK_compressor_brand_types_compressor_brands] FOREIGN KEY ([brand_id]) REFERENCES [compressor_brands] ([brand_id]) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [compressor_brand_type_service_packages] ADD CONSTRAINT [FK_compressor_brand_type_service_packages_compressor_brand_types] FOREIGN KEY ([brand_type_id]) REFERENCES [compressor_brand_types] ([id]) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [compressor_brand_type_service_package_materials] ADD CONSTRAINT [FK_compressor_brand_type_service_package_materials_compressor_brand_type_service_packages] FOREIGN KEY ([package_id]) REFERENCES [compressor_brand_type_service_packages] ([id]) ON DELETE CASCADE;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [compressor_engine_types] ADD CONSTRAINT [FK_compressor_engine_types_compressor_engines] FOREIGN KEY ([engine_id]) REFERENCES [compressor_engines] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [compressor_engine_type_service_packages] ADD CONSTRAINT [FK_compressor_engine_type_service_packages_compressor_engine_types] FOREIGN KEY ([engine_type_id]) REFERENCES [compressor_engine_types] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    ALTER TABLE [compressor_engine_type_service_package_materials] ADD CONSTRAINT [FK_compressor_engine_type_service_package_materials_compressor_engine_type_service_packages] FOREIGN KEY ([package_id]) REFERENCES [compressor_engine_type_service_packages] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626055408_RenameMaterialOverhaulToCompressor'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260626055408_RenameMaterialOverhaulToCompressor', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626083240_RenameMaterialOverhaulBrandTypeUniqueIndex'
)
BEGIN
    EXEC sp_rename N'[compressor_brand_types].[UX_material_overhaul_brand_types_brand_id_type_name]', N'UX_compressor_brand_types_brand_id_type_name', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260626083240_RenameMaterialOverhaulBrandTypeUniqueIndex'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260626083240_RenameMaterialOverhaulBrandTypeUniqueIndex', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260629081103_AddWellGasLiftAssignments'
)
BEGIN
    CREATE TABLE [well_gas_lift_assignments] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [well_id] uniqueidentifier NOT NULL,
        [gas_lift_input] uniqueidentifier NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_gas_lift_assignments] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_gas_lift_assignments_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_well_gas_lift_assignments_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_well_gas_lift_assignments_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_well_gas_lift_assignments_wells_well_id] FOREIGN KEY ([well_id]) REFERENCES [wells] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260629081103_AddWellGasLiftAssignments'
)
BEGIN
    CREATE INDEX [IX_well_gas_lift_assignments_created_by] ON [well_gas_lift_assignments] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260629081103_AddWellGasLiftAssignments'
)
BEGIN
    CREATE INDEX [IX_well_gas_lift_assignments_deleted_by] ON [well_gas_lift_assignments] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260629081103_AddWellGasLiftAssignments'
)
BEGIN
    CREATE INDEX [IX_well_gas_lift_assignments_updated_by] ON [well_gas_lift_assignments] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260629081103_AddWellGasLiftAssignments'
)
BEGIN
    CREATE INDEX [IX_well_gas_lift_assignments_well_id] ON [well_gas_lift_assignments] ([well_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260629081103_AddWellGasLiftAssignments'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_well_gas_lift_assignments_well_id_gas_lift_input' AND object_id = OBJECT_ID('dbo.well_gas_lift_assignments'))
        CREATE UNIQUE NONCLUSTERED INDEX IX_well_gas_lift_assignments_well_id_gas_lift_input
        ON dbo.well_gas_lift_assignments (well_id, gas_lift_input)
        WHERE deleted_at IS NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260629081103_AddWellGasLiftAssignments'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260629081103_AddWellGasLiftAssignments', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260629094728_AddNotificationTemplates'
)
BEGIN
    CREATE TABLE [notification_templates] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [name] nvarchar(100) NOT NULL,
        [title] nvarchar(100) NOT NULL,
        [message] nvarchar(255) NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_notification_templates] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260629094728_AddNotificationTemplates'
)
BEGIN

                IF NOT EXISTS (SELECT 1 FROM notification_templates WHERE name = 'approval_notif')
                INSERT INTO notification_templates (id, name, title, message, created_at, created_by)
                VALUES (NEWID(), 'approval_notif', 'Approval Request',
                    'Hello [fullname], you have a contract awaiting your approval. Open: [approval_url]',
                    GETDATE(), '00000000-0000-0000-0000-000000000000');
            
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260629094728_AddNotificationTemplates'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260629094728_AddNotificationTemplates', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260629100852_BackfillContractApprovers'
)
BEGIN

                INSERT INTO contract_approvers (id, contract_id, user_id, level)
                SELECT NEWID(), ap.reference_id, aru.user_id, CAST(aru.level AS int)
                FROM approval_route_users aru
                JOIN approval_processes ap
                    ON aru.approval_route_id = ap.id AND ap.approval_flow = 'contract'
                WHERE aru.deleted_at IS NULL
                  AND NOT EXISTS (
                    SELECT 1 FROM contract_approvers ca
                    WHERE ca.contract_id = ap.reference_id
                      AND ca.user_id = aru.user_id
                      AND (ca.level = CAST(aru.level AS int) OR (ca.level IS NULL AND aru.level IS NULL))
                  );
            
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260629100852_BackfillContractApprovers'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260629100852_BackfillContractApprovers', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260629103259_RemoveRksMasterCategoryForeignKey'
)
BEGIN
    ALTER TABLE [rks_master_clause] DROP CONSTRAINT [FK_rks_master_clause_rks_master_category];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260629103259_RemoveRksMasterCategoryForeignKey'
)
BEGIN
    DROP INDEX [IX_rks_master_clause_category_id] ON [rks_master_clause];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260629103259_RemoveRksMasterCategoryForeignKey'
)
BEGIN
    ALTER TABLE [rks_master_clause] ADD [category] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260629103259_RemoveRksMasterCategoryForeignKey'
)
BEGIN

                UPDATE mc
                SET mc.category = cat.category_name
                FROM rks_master_clause mc
                INNER JOIN rks_master_category cat
                    ON mc.category_id = cat.category_id
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260629103259_RemoveRksMasterCategoryForeignKey'
)
BEGIN
    DECLARE @var89 sysname;
    SELECT @var89 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[rks_master_clause]') AND [c].[name] = N'category_id');
    IF @var89 IS NOT NULL EXEC(N'ALTER TABLE [rks_master_clause] DROP CONSTRAINT [' + @var89 + '];');
    ALTER TABLE [rks_master_clause] DROP COLUMN [category_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260629103259_RemoveRksMasterCategoryForeignKey'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260629103259_RemoveRksMasterCategoryForeignKey', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260630202252_AddCompressorBrandAndEngineMaterialTemplates'
)
BEGIN
    CREATE TABLE [compressor_brand_type_service_package_material_templates] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [package_id] uniqueidentifier NOT NULL,
        [file_name] nvarchar(255) NOT NULL,
        [file_path] nvarchar(500) NOT NULL,
        [file_size] bigint NOT NULL,
        [is_active] bit NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_brand_type_service_package_material_templates] PRIMARY KEY ([id]),
        CONSTRAINT [FK_cbtsp_material_templates_package] FOREIGN KEY ([package_id]) REFERENCES [compressor_brand_type_service_packages] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_compressor_brand_type_service_package_material_templates_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_compressor_brand_type_service_package_material_templates_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_compressor_brand_type_service_package_material_templates_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260630202252_AddCompressorBrandAndEngineMaterialTemplates'
)
BEGIN
    CREATE TABLE [compressor_engine_type_service_package_material_templates] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [package_id] uniqueidentifier NOT NULL,
        [file_name] nvarchar(255) NOT NULL,
        [file_path] nvarchar(500) NOT NULL,
        [file_size] bigint NOT NULL,
        [is_active] bit NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_engine_type_service_package_material_templates] PRIMARY KEY ([id]),
        CONSTRAINT [FK_cetsp_material_templates_package] FOREIGN KEY ([package_id]) REFERENCES [compressor_engine_type_service_packages] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_compressor_engine_type_service_package_material_templates_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_compressor_engine_type_service_package_material_templates_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_compressor_engine_type_service_package_material_templates_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260630202252_AddCompressorBrandAndEngineMaterialTemplates'
)
BEGIN
    CREATE UNIQUE INDEX [IX_cbtsp_material_templates_package_id] ON [compressor_brand_type_service_package_material_templates] ([package_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260630202252_AddCompressorBrandAndEngineMaterialTemplates'
)
BEGIN
    CREATE INDEX [IX_compressor_brand_type_service_package_material_templates_created_by] ON [compressor_brand_type_service_package_material_templates] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260630202252_AddCompressorBrandAndEngineMaterialTemplates'
)
BEGIN
    CREATE INDEX [IX_compressor_brand_type_service_package_material_templates_deleted_by] ON [compressor_brand_type_service_package_material_templates] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260630202252_AddCompressorBrandAndEngineMaterialTemplates'
)
BEGIN
    CREATE INDEX [IX_compressor_brand_type_service_package_material_templates_updated_by] ON [compressor_brand_type_service_package_material_templates] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260630202252_AddCompressorBrandAndEngineMaterialTemplates'
)
BEGIN
    CREATE UNIQUE INDEX [IX_cetsp_material_templates_package_id] ON [compressor_engine_type_service_package_material_templates] ([package_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260630202252_AddCompressorBrandAndEngineMaterialTemplates'
)
BEGIN
    CREATE INDEX [IX_compressor_engine_type_service_package_material_templates_created_by] ON [compressor_engine_type_service_package_material_templates] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260630202252_AddCompressorBrandAndEngineMaterialTemplates'
)
BEGIN
    CREATE INDEX [IX_compressor_engine_type_service_package_material_templates_deleted_by] ON [compressor_engine_type_service_package_material_templates] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260630202252_AddCompressorBrandAndEngineMaterialTemplates'
)
BEGIN
    CREATE INDEX [IX_compressor_engine_type_service_package_material_templates_updated_by] ON [compressor_engine_type_service_package_material_templates] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260630202252_AddCompressorBrandAndEngineMaterialTemplates'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260630202252_AddCompressorBrandAndEngineMaterialTemplates', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260630230339_AddCompressorMonitoringPlant'
)
BEGIN
    CREATE TABLE [compressor_monitoring_plants] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [plant_name] nvarchar(200) NOT NULL,
        [area_id] uniqueidentifier NOT NULL,
        [system_type] nvarchar(100) NOT NULL,
        [pic_id] uniqueidentifier NOT NULL,
        [is_active] bit NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_monitoring_plants] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressor_monitoring_plants_areas] FOREIGN KEY ([area_id]) REFERENCES [areas] ([id]),
        CONSTRAINT [FK_compressor_monitoring_plants_users_pic] FOREIGN KEY ([pic_id]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_compressor_monitoring_plants_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_compressor_monitoring_plants_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]),
        CONSTRAINT [FK_compressor_monitoring_plants_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260630230339_AddCompressorMonitoringPlant'
)
BEGIN
    CREATE INDEX [IX_compressor_monitoring_plants_area_id] ON [compressor_monitoring_plants] ([area_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260630230339_AddCompressorMonitoringPlant'
)
BEGIN
    CREATE INDEX [IX_compressor_monitoring_plants_pic_id] ON [compressor_monitoring_plants] ([pic_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260630230339_AddCompressorMonitoringPlant'
)
BEGIN
    CREATE INDEX [IX_compressor_monitoring_plants_created_by] ON [compressor_monitoring_plants] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260630230339_AddCompressorMonitoringPlant'
)
BEGIN
    CREATE INDEX [IX_compressor_monitoring_plants_updated_by] ON [compressor_monitoring_plants] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260630230339_AddCompressorMonitoringPlant'
)
BEGIN
    CREATE INDEX [IX_compressor_monitoring_plants_deleted_by] ON [compressor_monitoring_plants] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260630230339_AddCompressorMonitoringPlant'
)
BEGIN
    CREATE UNIQUE INDEX [UX_compressor_monitoring_plants_plant_name] ON [compressor_monitoring_plants] ([plant_name]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260630230339_AddCompressorMonitoringPlant'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260630230339_AddCompressorMonitoringPlant', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260701140157_SeedEurModelSourceConfig'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.custom_configurations WHERE name = 'well_eur_monitoring.eur_model_source')
      INSERT INTO dbo.custom_configurations (id, name, description, detail, created_at, created_by, updated_at, updated_by)
      VALUES (NEWID(),
              'well_eur_monitoring.eur_model_source',
              'EUR Monitoring: which summary model feeds EUR (is_best | model_calculation)',
              '{"mode":"is_best"}',
              GETDATE(), '02a1922b-5cf1-471a-b735-fb2ceb2bbd72',
              GETDATE(), '02a1922b-5cf1-471a-b735-fb2ceb2bbd72');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260701140157_SeedEurModelSourceConfig'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260701140157_SeedEurModelSourceConfig', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260702022003_AddFidAndAreaId'
)
BEGIN
    DECLARE @var90 sysname;
    SELECT @var90 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[projects]') AND [c].[name] = N'potential_gain_unit');
    IF @var90 IS NOT NULL EXEC(N'ALTER TABLE [projects] DROP CONSTRAINT [' + @var90 + '];');
    ALTER TABLE [projects] DROP COLUMN [potential_gain_unit];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260702022003_AddFidAndAreaId'
)
BEGIN
    EXEC sp_rename N'[projects].[potential_gain_value]', N'potential_gain_mmscfd', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260702022003_AddFidAndAreaId'
)
BEGIN
    ALTER TABLE [projects] ADD [area_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260702022003_AddFidAndAreaId'
)
BEGIN
    ALTER TABLE [projects] ADD [fid] nvarchar(255) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260702022003_AddFidAndAreaId'
)
BEGIN
    ALTER TABLE [projects] ADD [potential_gain_bopd] decimal(18,2) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260702022003_AddFidAndAreaId'
)
BEGIN
    ALTER TABLE [projects] ADD [rig_name] nvarchar(255) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260702022003_AddFidAndAreaId'
)
BEGIN
    ALTER TABLE [projects] ADD [sub_category] nvarchar(255) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260702022003_AddFidAndAreaId'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260702022003_AddFidAndAreaId', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260703083210_AddTagNumberForBrandAndEngine'
)
BEGIN
    DROP TABLE [compressor_tag_numbers];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260703083210_AddTagNumberForBrandAndEngine'
)
BEGIN
    CREATE TABLE [compressor_brand_tag_numbers] (
        [id] uniqueidentifier NOT NULL,
        [tag_number] nvarchar(100) NOT NULL,
        [description] nvarchar(500) NULL,
        [brand_type_id] uniqueidentifier NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_brand_tag_numbers] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressor_brand_tag_numbers_compressor_brand_types_brand_type_id] FOREIGN KEY ([brand_type_id]) REFERENCES [compressor_brand_types] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260703083210_AddTagNumberForBrandAndEngine'
)
BEGIN
    CREATE TABLE [compressor_engine_tag_numbers] (
        [id] uniqueidentifier NOT NULL,
        [tag_number] nvarchar(100) NOT NULL,
        [description] nvarchar(500) NULL,
        [engine_type_id] uniqueidentifier NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_engine_tag_numbers] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressor_engine_tag_numbers_compressor_engine_types_engine_type_id] FOREIGN KEY ([engine_type_id]) REFERENCES [compressor_engine_types] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260703083210_AddTagNumberForBrandAndEngine'
)
BEGIN
    CREATE INDEX [IX_compressor_brand_tag_numbers_brand_type_id] ON [compressor_brand_tag_numbers] ([brand_type_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260703083210_AddTagNumberForBrandAndEngine'
)
BEGIN
    CREATE UNIQUE INDEX [IX_compressor_brand_tag_numbers_tag_number] ON [compressor_brand_tag_numbers] ([tag_number]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260703083210_AddTagNumberForBrandAndEngine'
)
BEGIN
    CREATE INDEX [IX_compressor_engine_tag_numbers_engine_type_id] ON [compressor_engine_tag_numbers] ([engine_type_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260703083210_AddTagNumberForBrandAndEngine'
)
BEGIN
    CREATE UNIQUE INDEX [IX_compressor_engine_tag_numbers_tag_number] ON [compressor_engine_tag_numbers] ([tag_number]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260703083210_AddTagNumberForBrandAndEngine'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260703083210_AddTagNumberForBrandAndEngine', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260705042440_AddWellZoneAssignmentHistories'
)
BEGIN
    CREATE TABLE [well_zone_assignment_histories] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [well_id] uniqueidentifier NOT NULL,
        [well_zone_assignment_id] uniqueidentifier NOT NULL,
        [change_group_id] uniqueidentifier NOT NULL,
        [field_name] nvarchar(50) NULL,
        [old_value] nvarchar(255) NULL,
        [new_value] nvarchar(255) NULL,
        [change_type] nvarchar(10) NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        CONSTRAINT [PK_well_zone_assignment_histories] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260705042440_AddWellZoneAssignmentHistories'
)
BEGIN
    CREATE INDEX [IX_well_zone_assignment_histories_well_id_created_at] ON [well_zone_assignment_histories] ([well_id], [created_at]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260705042440_AddWellZoneAssignmentHistories'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260705042440_AddWellZoneAssignmentHistories', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260705203022_AddCompressorStrategy'
)
BEGIN
    CREATE TABLE [compressor_strategies] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [name] nvarchar(100) NOT NULL,
        [area_id] uniqueidentifier NOT NULL,
        [plant_id] uniqueidentifier NOT NULL,
        [compressor_type] nvarchar(50) NULL,
        [category] nvarchar(100) NULL,
        [compressor_brand_tag_number_id] uniqueidentifier NOT NULL,
        [compressor_engine_tag_number_id] uniqueidentifier NOT NULL,
        [max_capacity] decimal(18,2) NOT NULL,
        [status] nvarchar(50) NOT NULL DEFAULT N'Running',
        [running_date] datetime NOT NULL,
        [is_active] int NOT NULL,
        [last_activity_at] datetime NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_strategies] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressor_strategies_areas_area_id] FOREIGN KEY ([area_id]) REFERENCES [areas] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_strategies_compressor_brand_tag_number_id] FOREIGN KEY ([compressor_brand_tag_number_id]) REFERENCES [compressor_brand_tag_numbers] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_strategies_compressor_engine_tag_number_id] FOREIGN KEY ([compressor_engine_tag_number_id]) REFERENCES [compressor_engine_tag_numbers] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_strategies_compressor_monitoring_plants_plant_id] FOREIGN KEY ([plant_id]) REFERENCES [compressor_monitoring_plants] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_strategies_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_strategies_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_strategies_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260705203022_AddCompressorStrategy'
)
BEGIN
    CREATE INDEX [IX_compressor_strategies_area_id] ON [compressor_strategies] ([area_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260705203022_AddCompressorStrategy'
)
BEGIN
    CREATE INDEX [IX_compressor_strategies_compressor_brand_tag_number_id] ON [compressor_strategies] ([compressor_brand_tag_number_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260705203022_AddCompressorStrategy'
)
BEGIN
    CREATE INDEX [IX_compressor_strategies_compressor_engine_tag_number_id] ON [compressor_strategies] ([compressor_engine_tag_number_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260705203022_AddCompressorStrategy'
)
BEGIN
    CREATE INDEX [IX_compressor_strategies_created_by] ON [compressor_strategies] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260705203022_AddCompressorStrategy'
)
BEGIN
    CREATE INDEX [IX_compressor_strategies_deleted_by] ON [compressor_strategies] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260705203022_AddCompressorStrategy'
)
BEGIN
    CREATE INDEX [IX_compressor_strategies_plant_id] ON [compressor_strategies] ([plant_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260705203022_AddCompressorStrategy'
)
BEGIN
    CREATE INDEX [IX_compressor_strategies_updated_by] ON [compressor_strategies] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260705203022_AddCompressorStrategy'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260705203022_AddCompressorStrategy', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260706053255_AddContractPicAndNewColumns'
)
BEGIN
    ALTER TABLE [contracts] ADD [ContractMasterNumber] nvarchar(max) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260706053255_AddContractPicAndNewColumns'
)
BEGIN
    ALTER TABLE [contracts] ADD [Currency] nvarchar(max) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260706053255_AddContractPicAndNewColumns'
)
BEGIN
    ALTER TABLE [contracts] ADD [PaymentTerms] nvarchar(max) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260706053255_AddContractPicAndNewColumns'
)
BEGIN
    ALTER TABLE [contracts] ADD [PenaltyRate] float NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260706053255_AddContractPicAndNewColumns'
)
BEGIN
    ALTER TABLE [contracts] ADD [ReplacedContract] nvarchar(max) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260706053255_AddContractPicAndNewColumns'
)
BEGIN
    CREATE TABLE [contract_pics] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [contract_id] uniqueidentifier NOT NULL,
        [user_id] uniqueidentifier NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_contract_pics] PRIMARY KEY ([id]),
        CONSTRAINT [FK_contract_pics_contracts_contract_id] FOREIGN KEY ([contract_id]) REFERENCES [contracts] ([contract_id]) ON DELETE CASCADE,
        CONSTRAINT [FK_contract_pics_users_user_id] FOREIGN KEY ([user_id]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260706053255_AddContractPicAndNewColumns'
)
BEGIN
    CREATE INDEX [IX_contract_pics_contract_id] ON [contract_pics] ([contract_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260706053255_AddContractPicAndNewColumns'
)
BEGIN
    CREATE INDEX [IX_contract_pics_user_id] ON [contract_pics] ([user_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260706053255_AddContractPicAndNewColumns'
)
BEGIN
    CREATE UNIQUE INDEX [UX_contract_pics_contract_user] ON [contract_pics] ([contract_id], [user_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260706053255_AddContractPicAndNewColumns'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260706053255_AddContractPicAndNewColumns', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260706081146_AddPermeabilityWellZoneAssignment'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [permeability] decimal(18,4) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260706081146_AddPermeabilityWellZoneAssignment'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260706081146_AddPermeabilityWellZoneAssignment', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707015056_AddFieldIdToAreas'
)
BEGIN
    ALTER TABLE [areas] ADD [field_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707015056_AddFieldIdToAreas'
)
BEGIN
    CREATE INDEX [IX_areas_field_id] ON [areas] ([field_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707015056_AddFieldIdToAreas'
)
BEGIN
    ALTER TABLE [areas] ADD CONSTRAINT [FK_areas_fields] FOREIGN KEY ([field_id]) REFERENCES [fields] ([field_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707015056_AddFieldIdToAreas'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260707015056_AddFieldIdToAreas', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy'
)
BEGIN
    ALTER TABLE [compressor_monitoring_plants] DROP CONSTRAINT [FK_compressor_monitoring_plants_areas];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy'
)
BEGIN
    ALTER TABLE [compressor_monitoring_plants] DROP CONSTRAINT [FK_compressor_monitoring_plants_users_created_by];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy'
)
BEGIN
    ALTER TABLE [compressor_monitoring_plants] DROP CONSTRAINT [FK_compressor_monitoring_plants_users_deleted_by];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy'
)
BEGIN
    ALTER TABLE [compressor_monitoring_plants] DROP CONSTRAINT [FK_compressor_monitoring_plants_users_pic];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy'
)
BEGIN
    ALTER TABLE [compressor_monitoring_plants] DROP CONSTRAINT [FK_compressor_monitoring_plants_users_updated_by];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy'
)
BEGIN
    DROP INDEX [UX_compressor_monitoring_plants_plant_name] ON [compressor_monitoring_plants];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy'
)
BEGIN
    ALTER TABLE [compressor_strategies] ADD [field_id] uniqueidentifier NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy'
)
BEGIN
    ALTER TABLE [compressor_monitoring_plants] ADD [field_id] uniqueidentifier NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy'
)
BEGIN
    CREATE INDEX [IX_compressor_strategies_field_id] ON [compressor_strategies] ([field_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy'
)
BEGIN
    CREATE INDEX [IX_compressor_monitoring_plants_field_id] ON [compressor_monitoring_plants] ([field_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy'
)
BEGIN
    CREATE UNIQUE INDEX [UX_compressor_monitoring_plants_field_id_plant_name] ON [compressor_monitoring_plants] ([field_id], [plant_name]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy'
)
BEGIN
    ALTER TABLE [compressor_monitoring_plants] ADD CONSTRAINT [FK_compressor_monitoring_plants_areas_area_id] FOREIGN KEY ([area_id]) REFERENCES [areas] ([id]) ON DELETE NO ACTION;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy'
)
BEGIN
    ALTER TABLE [compressor_monitoring_plants] ADD CONSTRAINT [FK_compressor_monitoring_plants_fields_field_id] FOREIGN KEY ([field_id]) REFERENCES [fields] ([field_id]) ON DELETE NO ACTION;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy'
)
BEGIN
    ALTER TABLE [compressor_monitoring_plants] ADD CONSTRAINT [FK_compressor_monitoring_plants_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy'
)
BEGIN
    ALTER TABLE [compressor_monitoring_plants] ADD CONSTRAINT [FK_compressor_monitoring_plants_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy'
)
BEGIN
    ALTER TABLE [compressor_monitoring_plants] ADD CONSTRAINT [FK_compressor_monitoring_plants_users_pic_id] FOREIGN KEY ([pic_id]) REFERENCES [users] ([id]) ON DELETE NO ACTION;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy'
)
BEGIN
    ALTER TABLE [compressor_monitoring_plants] ADD CONSTRAINT [FK_compressor_monitoring_plants_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy'
)
BEGIN
    ALTER TABLE [compressor_strategies] ADD CONSTRAINT [FK_compressor_strategies_fields_field_id] FOREIGN KEY ([field_id]) REFERENCES [fields] ([field_id]) ON DELETE NO ACTION;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260707044015_AddFieldHierarcyToMonitoringPlantAndCompressorStrategy', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707140322_AddCompresorStrategyTemplate'
)
BEGIN
    ALTER TABLE [compressor_strategies] DROP CONSTRAINT [FK_compressor_strategies_areas_area_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707140322_AddCompresorStrategyTemplate'
)
BEGIN
    ALTER TABLE [compressor_strategies] DROP CONSTRAINT [FK_compressor_strategies_fields_field_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707140322_AddCompresorStrategyTemplate'
)
BEGIN
    DROP INDEX [IX_compressor_strategies_area_id] ON [compressor_strategies];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707140322_AddCompresorStrategyTemplate'
)
BEGIN
    DROP INDEX [IX_compressor_strategies_field_id] ON [compressor_strategies];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707140322_AddCompresorStrategyTemplate'
)
BEGIN
    DECLARE @var91 sysname;
    SELECT @var91 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[compressor_strategies]') AND [c].[name] = N'area_id');
    IF @var91 IS NOT NULL EXEC(N'ALTER TABLE [compressor_strategies] DROP CONSTRAINT [' + @var91 + '];');
    ALTER TABLE [compressor_strategies] DROP COLUMN [area_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707140322_AddCompresorStrategyTemplate'
)
BEGIN
    DECLARE @var92 sysname;
    SELECT @var92 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[compressor_strategies]') AND [c].[name] = N'field_id');
    IF @var92 IS NOT NULL EXEC(N'ALTER TABLE [compressor_strategies] DROP CONSTRAINT [' + @var92 + '];');
    ALTER TABLE [compressor_strategies] DROP COLUMN [field_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707140322_AddCompresorStrategyTemplate'
)
BEGIN
    CREATE TABLE [compressor_strategy_templates] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [working_area] nvarchar(10) NOT NULL,
        [file_name] nvarchar(255) NOT NULL,
        [file_path] nvarchar(500) NOT NULL,
        [file_size] bigint NOT NULL,
        [is_active] bit NOT NULL DEFAULT CAST(1 AS bit),
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_strategy_templates] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressor_strategy_templates_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_strategy_templates_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_strategy_templates_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707140322_AddCompresorStrategyTemplate'
)
BEGIN
    CREATE INDEX [IX_compressor_strategy_templates_created_by] ON [compressor_strategy_templates] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707140322_AddCompresorStrategyTemplate'
)
BEGIN
    CREATE INDEX [IX_compressor_strategy_templates_deleted_by] ON [compressor_strategy_templates] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707140322_AddCompresorStrategyTemplate'
)
BEGIN
    CREATE INDEX [IX_compressor_strategy_templates_file_name] ON [compressor_strategy_templates] ([file_name]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707140322_AddCompresorStrategyTemplate'
)
BEGIN
    CREATE INDEX [IX_compressor_strategy_templates_updated_by] ON [compressor_strategy_templates] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707140322_AddCompresorStrategyTemplate'
)
BEGIN
    CREATE INDEX [IX_compressor_strategy_templates_working_area] ON [compressor_strategy_templates] ([working_area]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260707140322_AddCompresorStrategyTemplate'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260707140322_AddCompresorStrategyTemplate', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260708053153_RepointWellsFieldToFields'
)
BEGIN
    ALTER TABLE [wells] DROP CONSTRAINT [FK_wells_well_fields_field_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260708053153_RepointWellsFieldToFields'
)
BEGIN
    ALTER TABLE [wells] ADD CONSTRAINT [FK_wells_fields_field_id] FOREIGN KEY ([field_id]) REFERENCES [fields] ([field_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260708053153_RepointWellsFieldToFields'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260708053153_RepointWellsFieldToFields', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260708074833_RepointWellsAreaToAreas'
)
BEGIN
    ALTER TABLE [wells] DROP CONSTRAINT [FK_wells_well_areas_area_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260708074833_RepointWellsAreaToAreas'
)
BEGIN
    ALTER TABLE [wells] ADD CONSTRAINT [FK_wells_areas_area_id] FOREIGN KEY ([area_id]) REFERENCES [areas] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260708074833_RepointWellsAreaToAreas'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260708074833_RepointWellsAreaToAreas', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709032337_RepurposeWzaWellFieldToWorkingArea'
)
BEGIN
    ALTER TABLE [well_zone_assignments] DROP CONSTRAINT [FK_well_zone_assignments_well_fields_well_field_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709032337_RepurposeWzaWellFieldToWorkingArea'
)
BEGIN
    DROP INDEX [IX_well_zone_assignments_well_field_id] ON [well_zone_assignments];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709032337_RepurposeWzaWellFieldToWorkingArea'
)
BEGIN
    DECLARE @var93 sysname;
    SELECT @var93 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_zone_assignments]') AND [c].[name] = N'well_field_id');
    IF @var93 IS NOT NULL EXEC(N'ALTER TABLE [well_zone_assignments] DROP CONSTRAINT [' + @var93 + '];');
    ALTER TABLE [well_zone_assignments] DROP COLUMN [well_field_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709032337_RepurposeWzaWellFieldToWorkingArea'
)
BEGIN
    DECLARE @var94 sysname;
    SELECT @var94 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[wells]') AND [c].[name] = N'field_id');
    IF @var94 IS NOT NULL EXEC(N'ALTER TABLE [wells] DROP CONSTRAINT [' + @var94 + '];');
    ALTER TABLE [wells] ALTER COLUMN [field_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709032337_RepurposeWzaWellFieldToWorkingArea'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [working_area] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709032337_RepurposeWzaWellFieldToWorkingArea'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260709032337_RepurposeWzaWellFieldToWorkingArea', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709033022_AddCompresorMonitoringPlantTemplate'
)
BEGIN
    CREATE TABLE [compressor_monitoring_plant_templates] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [working_area] nvarchar(10) NOT NULL,
        [file_name] nvarchar(255) NOT NULL,
        [file_path] nvarchar(500) NOT NULL,
        [file_size] bigint NOT NULL,
        [is_active] bit NOT NULL DEFAULT CAST(1 AS bit),
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_monitoring_plant_templates] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressor_monitoring_plant_templates_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_monitoring_plant_templates_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_monitoring_plant_templates_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709033022_AddCompresorMonitoringPlantTemplate'
)
BEGIN
    CREATE INDEX [IX_compressor_monitoring_plant_templates_created_by] ON [compressor_monitoring_plant_templates] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709033022_AddCompresorMonitoringPlantTemplate'
)
BEGIN
    CREATE INDEX [IX_compressor_monitoring_plant_templates_deleted_by] ON [compressor_monitoring_plant_templates] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709033022_AddCompresorMonitoringPlantTemplate'
)
BEGIN
    CREATE INDEX [IX_compressor_monitoring_plant_templates_file_name] ON [compressor_monitoring_plant_templates] ([file_name]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709033022_AddCompresorMonitoringPlantTemplate'
)
BEGIN
    CREATE INDEX [IX_compressor_monitoring_plant_templates_updated_by] ON [compressor_monitoring_plant_templates] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709033022_AddCompresorMonitoringPlantTemplate'
)
BEGIN
    CREATE INDEX [IX_compressor_monitoring_plant_templates_working_area] ON [compressor_monitoring_plant_templates] ([working_area]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709033022_AddCompresorMonitoringPlantTemplate'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260709033022_AddCompresorMonitoringPlantTemplate', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709070030_AddWorkingAreaToWells'
)
BEGIN
    ALTER TABLE [wells] ADD [working_area] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709070030_AddWorkingAreaToWells'
)
BEGIN
    UPDATE w SET w.working_area = LOWER(f.working_area) FROM wells w INNER JOIN fields f ON w.field_id = f.field_id WHERE w.working_area IS NULL AND f.working_area IS NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709070030_AddWorkingAreaToWells'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260709070030_AddWorkingAreaToWells', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709081139_AddDataScienceTables'
)
BEGIN
    CREATE TABLE [ds_contract_depletion_weekly_data] (
        [id] int NOT NULL IDENTITY,
        [contract_id] uniqueidentifier NOT NULL,
        [date] date NOT NULL,
        [cum_sum] float NOT NULL,
        [spk_value] float NOT NULL,
        [group] nvarchar(max) NOT NULL,
        [is_warning] bit NOT NULL DEFAULT CAST(0 AS bit),
        [is_depleted] bit NOT NULL DEFAULT CAST(0 AS bit),
        [created_at] datetime2 NOT NULL DEFAULT ((sysutcdatetime())),
        CONSTRAINT [PK_ds_contract_depletion_weekly_data] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709081139_AddDataScienceTables'
)
BEGIN
    CREATE TABLE [ds_contract_warning_date] (
        [contract_id] uniqueidentifier NOT NULL,
        [contract_no] nvarchar(max) NOT NULL,
        [contract_value] float NOT NULL,
        [contract_end_date] datetime2 NOT NULL,
        [warning_date] datetime2 NOT NULL,
        [start_notif_date] datetime2 NOT NULL,
        [expired_reason] nvarchar(max) NOT NULL DEFAULT N'',
        [updated_at] datetime2 NOT NULL DEFAULT ((sysutcdatetime())),
        CONSTRAINT [PK_ds_contract_warning_date] PRIMARY KEY ([contract_id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709081139_AddDataScienceTables'
)
BEGIN
    CREATE TABLE [ds_contractor_performance_data] (
        [id] int NOT NULL IDENTITY,
        [contractor_id] uniqueidentifier NOT NULL,
        [date] date NOT NULL,
        [plan_cost] float NOT NULL,
        [actual_cost] float NOT NULL,
        [contract_id] nvarchar(max) NOT NULL DEFAULT N'',
        [created_at] datetime2 NOT NULL DEFAULT ((sysutcdatetime())),
        CONSTRAINT [PK_ds_contractor_performance_data] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709081139_AddDataScienceTables'
)
BEGIN
    CREATE INDEX [IX_ds_contract_depletion_weekly_data_contract_id_created_at] ON [ds_contract_depletion_weekly_data] ([contract_id], [created_at]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709081139_AddDataScienceTables'
)
BEGIN
    CREATE INDEX [IX_ds_contractor_performance_data_contractor_id_created_at] ON [ds_contractor_performance_data] ([contractor_id], [created_at]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260709081139_AddDataScienceTables'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260709081139_AddDataScienceTables', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260710043357_AddCompresorStrategyPeriodic'
)
BEGIN
    CREATE TABLE [compressor_strategy_periodics] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [compressor_strategy_id] uniqueidentifier NOT NULL,
        [actual_flow] decimal(18,2) NULL,
        [reliability] decimal(18,2) NULL,
        [availability] decimal(18,2) NULL,
        [total_running_hours] decimal(18,2) NULL,
        [last_pm_date] datetime NULL,
        [last_overhaul_date] datetime NULL,
        [last_breakdown_date] datetime NULL,
        [next_overhaul_date] datetime NULL,
        [inspection_date] datetime NULL,
        [inspector] nvarchar(100) NULL,
        [lpo] nvarchar(100) NULL,
        [notes] nvarchar(2000) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_strategy_periodics] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressor_strategy_periodics_compressor_strategy_id] FOREIGN KEY ([compressor_strategy_id]) REFERENCES [compressor_strategies] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_strategy_periodics_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_strategy_periodics_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_strategy_periodics_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260710043357_AddCompresorStrategyPeriodic'
)
BEGIN
    CREATE INDEX [IX_compressor_strategy_periodics_compressor_strategy_id] ON [compressor_strategy_periodics] ([compressor_strategy_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260710043357_AddCompresorStrategyPeriodic'
)
BEGIN
    CREATE INDEX [IX_compressor_strategy_periodics_created_at] ON [compressor_strategy_periodics] ([created_at]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260710043357_AddCompresorStrategyPeriodic'
)
BEGIN
    CREATE INDEX [IX_compressor_strategy_periodics_created_by] ON [compressor_strategy_periodics] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260710043357_AddCompresorStrategyPeriodic'
)
BEGIN
    CREATE INDEX [IX_compressor_strategy_periodics_updated_by] ON [compressor_strategy_periodics] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260710043357_AddCompresorStrategyPeriodic'
)
BEGIN
    CREATE INDEX [IX_compressor_strategy_periodics_deleted_by] ON [compressor_strategy_periodics] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260710043357_AddCompresorStrategyPeriodic'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260710043357_AddCompresorStrategyPeriodic', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260710075224_AddRemarkAtributSp3Monitoring'
)
BEGIN
    ALTER TABLE [invoices] ADD [remarks] nvarchar(500) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260710075224_AddRemarkAtributSp3Monitoring'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260710075224_AddRemarkAtributSp3Monitoring', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260710095659_AddAtributPlantId'
)
BEGIN
    ALTER TABLE [projects] ADD [plant_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260710095659_AddAtributPlantId'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260710095659_AddAtributPlantId', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260710104110_AddColumnFlowInCompressorMonitoringPlant'
)
BEGIN
    ALTER TABLE [compressor_monitoring_plants] ADD [flow] decimal(18,2) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260710104110_AddColumnFlowInCompressorMonitoringPlant'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260710104110_AddColumnFlowInCompressorMonitoringPlant', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260711162853_UpdateCompressorStrategyPeriodicStructure'
)
BEGIN
    DECLARE @var95 sysname;
    SELECT @var95 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[compressor_strategy_periodics]') AND [c].[name] = N'inspector');
    IF @var95 IS NOT NULL EXEC(N'ALTER TABLE [compressor_strategy_periodics] DROP CONSTRAINT [' + @var95 + '];');
    ALTER TABLE [compressor_strategy_periodics] DROP COLUMN [inspector];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260711162853_UpdateCompressorStrategyPeriodicStructure'
)
BEGIN
    DECLARE @var96 sysname;
    SELECT @var96 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[compressor_strategy_periodics]') AND [c].[name] = N'next_overhaul_date');
    IF @var96 IS NOT NULL EXEC(N'ALTER TABLE [compressor_strategy_periodics] DROP CONSTRAINT [' + @var96 + '];');
    ALTER TABLE [compressor_strategy_periodics] DROP COLUMN [next_overhaul_date];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260711162853_UpdateCompressorStrategyPeriodicStructure'
)
BEGIN
    DECLARE @var97 sysname;
    SELECT @var97 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[compressor_strategies]') AND [c].[name] = N'last_activity_at');
    IF @var97 IS NOT NULL EXEC(N'ALTER TABLE [compressor_strategies] DROP CONSTRAINT [' + @var97 + '];');
    ALTER TABLE [compressor_strategies] DROP COLUMN [last_activity_at];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260711162853_UpdateCompressorStrategyPeriodicStructure'
)
BEGIN
    EXEC sp_rename N'[compressor_strategy_periodics].[total_running_hours]', N'last_pm_hours', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260711162853_UpdateCompressorStrategyPeriodicStructure'
)
BEGIN
    EXEC sp_rename N'[compressor_strategy_periodics].[reliability]', N'last_overhaul_hours', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260711162853_UpdateCompressorStrategyPeriodicStructure'
)
BEGIN
    EXEC sp_rename N'[compressor_strategy_periodics].[availability]', N'last_breakdown_hours', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260711162853_UpdateCompressorStrategyPeriodicStructure'
)
BEGIN
    DECLARE @var98 sysname;
    SELECT @var98 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[compressor_strategy_periodics]') AND [c].[name] = N'lpo');
    IF @var98 IS NOT NULL EXEC(N'ALTER TABLE [compressor_strategy_periodics] DROP CONSTRAINT [' + @var98 + '];');
    ALTER TABLE [compressor_strategy_periodics] ALTER COLUMN [lpo] decimal(18,2) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260711162853_UpdateCompressorStrategyPeriodicStructure'
)
BEGIN
    ALTER TABLE [compressor_strategy_periodics] ADD [inspector_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260711162853_UpdateCompressorStrategyPeriodicStructure'
)
BEGIN
    ALTER TABLE [compressor_strategy_periodics] ADD [periodic_update_date] datetime NOT NULL DEFAULT '0001-01-01T00:00:00.000';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260711162853_UpdateCompressorStrategyPeriodicStructure'
)
BEGIN
    ALTER TABLE [compressor_strategy_periodics] ADD [type] nvarchar(50) NOT NULL DEFAULT N'';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260711162853_UpdateCompressorStrategyPeriodicStructure'
)
BEGIN
    ALTER TABLE [compressor_strategy_periodics] ADD [is_current] bit NOT NULL DEFAULT CAST(1 AS bit);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260711162853_UpdateCompressorStrategyPeriodicStructure'
)
BEGIN
    DECLARE @var99 sysname;
    SELECT @var99 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[compressor_strategies]') AND [c].[name] = N'status');
    IF @var99 IS NOT NULL EXEC(N'ALTER TABLE [compressor_strategies] DROP CONSTRAINT [' + @var99 + '];');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260711162853_UpdateCompressorStrategyPeriodicStructure'
)
BEGIN
    CREATE INDEX [IX_compressor_strategy_periodics_inspector_id] ON [compressor_strategy_periodics] ([inspector_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260711162853_UpdateCompressorStrategyPeriodicStructure'
)
BEGIN
    CREATE INDEX [IX_compressor_strategy_periodics_strategy_periodic] ON [compressor_strategy_periodics] ([compressor_strategy_id], [type], [periodic_update_date]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260711162853_UpdateCompressorStrategyPeriodicStructure'
)
BEGIN
    CREATE INDEX [IX_compressor_strategy_periodics_current] ON [compressor_strategy_periodics] ([compressor_strategy_id], [type], [is_current]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260711162853_UpdateCompressorStrategyPeriodicStructure'
)
BEGIN
    ALTER TABLE [compressor_strategy_periodics] ADD CONSTRAINT [FK_compressor_strategy_periodics_users_inspector_id] FOREIGN KEY ([inspector_id]) REFERENCES [users] ([id]) ON DELETE NO ACTION;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260711162853_UpdateCompressorStrategyPeriodicStructure'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260711162853_UpdateCompressorStrategyPeriodicStructure', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260713082801_RenameCompressorMonitoringPlantToCompressorPlantType'
)
BEGIN
    DROP INDEX [UX_compressor_monitoring_plants_field_id_plant_name] ON [compressor_monitoring_plants];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260713082801_RenameCompressorMonitoringPlantToCompressorPlantType'
)
BEGIN
    DECLARE @var100 sysname;
    SELECT @var100 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[compressor_monitoring_plants]') AND [c].[name] = N'plant_name');
    IF @var100 IS NOT NULL EXEC(N'ALTER TABLE [compressor_monitoring_plants] DROP CONSTRAINT [' + @var100 + '];');
    ALTER TABLE [compressor_monitoring_plants] DROP COLUMN [plant_name];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260713082801_RenameCompressorMonitoringPlantToCompressorPlantType'
)
BEGIN
    EXEC sp_rename N'[compressor_monitoring_plants]', N'compressor_plant_types', 'OBJECT';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260713082801_RenameCompressorMonitoringPlantToCompressorPlantType'
)
BEGIN
    EXEC sp_rename N'[compressor_plant_types].[IX_compressor_monitoring_plants_updated_by]', N'IX_compressor_plant_types_updated_by', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260713082801_RenameCompressorMonitoringPlantToCompressorPlantType'
)
BEGIN
    EXEC sp_rename N'[compressor_plant_types].[IX_compressor_monitoring_plants_deleted_by]', N'IX_compressor_plant_types_deleted_by', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260713082801_RenameCompressorMonitoringPlantToCompressorPlantType'
)
BEGIN
    EXEC sp_rename N'[compressor_plant_types].[IX_compressor_monitoring_plants_created_by]', N'IX_compressor_plant_types_created_by', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260713082801_RenameCompressorMonitoringPlantToCompressorPlantType'
)
BEGIN
    ALTER TABLE [compressor_plant_types] ADD [plant_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260713082801_RenameCompressorMonitoringPlantToCompressorPlantType'
)
BEGIN
    CREATE INDEX [IX_compressor_plant_types_plant_id] ON [compressor_plant_types] ([plant_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260713082801_RenameCompressorMonitoringPlantToCompressorPlantType'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_compressor_plant_types_field_id_plant_id] ON [compressor_plant_types] ([field_id], [plant_id]) WHERE [plant_id] IS NOT NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260713082801_RenameCompressorMonitoringPlantToCompressorPlantType'
)
BEGIN
    ALTER TABLE [compressor_plant_types] ADD CONSTRAINT [FK_compressor_plant_types_plants_plant_id] FOREIGN KEY ([plant_id]) REFERENCES [plants] ([id]) ON DELETE NO ACTION;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260713082801_RenameCompressorMonitoringPlantToCompressorPlantType'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260713082801_RenameCompressorMonitoringPlantToCompressorPlantType', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260713101559_AddSystemTypeToCompressorPlantTypeUniqueIndex'
)
BEGIN
    DROP INDEX [UX_compressor_plant_types_field_id_plant_id] ON [compressor_plant_types];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260713101559_AddSystemTypeToCompressorPlantTypeUniqueIndex'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_compressor_plant_types_field_id_plant_id_system_type] ON [compressor_plant_types] ([field_id], [plant_id], [system_type]) WHERE [plant_id] IS NOT NULL AND [system_type] IS NOT NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260713101559_AddSystemTypeToCompressorPlantTypeUniqueIndex'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260713101559_AddSystemTypeToCompressorPlantTypeUniqueIndex', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260713105214_FixCompressorPlantTypeUniqueIndexDeletedAtFilter'
)
BEGIN
    DROP INDEX [UX_compressor_plant_types_field_id_plant_id_system_type] ON [compressor_plant_types];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260713105214_FixCompressorPlantTypeUniqueIndexDeletedAtFilter'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_compressor_plant_types_field_id_plant_id_system_type] ON [compressor_plant_types] ([field_id], [plant_id], [system_type]) WHERE [plant_id] IS NOT NULL AND [system_type] IS NOT NULL AND [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260713105214_FixCompressorPlantTypeUniqueIndexDeletedAtFilter'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260713105214_FixCompressorPlantTypeUniqueIndexDeletedAtFilter', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714010000_AddTypeToProjectRebaselines'
)
BEGIN
    ALTER TABLE [project_rebaselines] ADD [type] varchar(20) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714010000_AddTypeToProjectRebaselines'
)
BEGIN
    UPDATE project_rebaselines SET type = 'rebaseline' WHERE type IS NULL
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714010000_AddTypeToProjectRebaselines'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260714010000_AddTypeToProjectRebaselines', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714020000_AddVersionToProjectRebaselines'
)
BEGIN
    ALTER TABLE [project_rebaselines] ADD [version] varchar(20) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714020000_AddVersionToProjectRebaselines'
)
BEGIN

                UPDATE pr
                SET pr.version = 'v' + CAST(ranked.rn AS varchar(10))
                FROM project_rebaselines pr
                INNER JOIN (
                    SELECT id, ROW_NUMBER() OVER (PARTITION BY project_id ORDER BY created_at) AS rn
                    FROM project_rebaselines
                    WHERE version IS NULL
                ) ranked ON ranked.id = pr.id
            
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714020000_AddVersionToProjectRebaselines'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260714020000_AddVersionToProjectRebaselines', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714040228_AddCompressorConnectionTables'
)
BEGIN
    CREATE TABLE [compressor_connection_entities] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [name] nvarchar(255) NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_connection_entities] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714040228_AddCompressorConnectionTables'
)
BEGIN
    CREATE TABLE [compressor_connection_others] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [name] nvarchar(255) NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_connection_others] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714040228_AddCompressorConnectionTables'
)
BEGIN
    CREATE TABLE [compressor_connections] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [from_type] char(1) NULL,
        [from_id] uniqueidentifier NOT NULL,
        [to_type] char(1) NULL,
        [to_id] uniqueidentifier NOT NULL,
        [relationship_type] nvarchar(50) NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_connections] PRIMARY KEY ([id]),
        CONSTRAINT [CK_compressor_connections_from_type] CHECK (from_type IN ('W','C','E','O')),
        CONSTRAINT [CK_compressor_connections_relationship_type] CHECK (relationship_type IN ('PRODUCTION','PRESSURE','GAS_LIFT','ENTITY','OTHER')),
        CONSTRAINT [CK_compressor_connections_to_type] CHECK (to_type IN ('W','C','E','O'))
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714040228_AddCompressorConnectionTables'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260714040228_AddCompressorConnectionTables', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714041640_ChangeNavigationPlant'
)
BEGIN
    ALTER TABLE [compressor_strategies] DROP CONSTRAINT [FK_compressor_strategies_compressor_monitoring_plants_plant_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714041640_ChangeNavigationPlant'
)
BEGIN
    ALTER TABLE [compressor_strategies] ADD CONSTRAINT [FK_compressor_strategies_plants_plant_id] FOREIGN KEY ([plant_id]) REFERENCES [plants] ([id]) ON DELETE NO ACTION;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714041640_ChangeNavigationPlant'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260714041640_ChangeNavigationPlant', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714120000_AddVwProjectSummary'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260714120000_AddVwProjectSummary', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714120357_RenameCompressorPlantTypesToSystemTypesAndUpdateStrategy'
)
BEGIN
    ALTER TABLE [compressor_strategies] DROP CONSTRAINT [FK_compressor_strategies_plants_plant_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714120357_RenameCompressorPlantTypesToSystemTypesAndUpdateStrategy'
)
BEGIN
    DECLARE @var101 sysname;
    SELECT @var101 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[compressor_strategies]') AND [c].[name] = N'compressor_type');
    IF @var101 IS NOT NULL EXEC(N'ALTER TABLE [compressor_strategies] DROP CONSTRAINT [' + @var101 + '];');
    ALTER TABLE [compressor_strategies] DROP COLUMN [compressor_type];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714120357_RenameCompressorPlantTypesToSystemTypesAndUpdateStrategy'
)
BEGIN
    EXEC sp_rename N'[compressor_plant_types]', N'compressor_system_types', 'OBJECT';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714120357_RenameCompressorPlantTypesToSystemTypesAndUpdateStrategy'
)
BEGIN
    EXEC sp_rename N'[compressor_strategies].[plant_id]', N'compressor_system_type_id', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714120357_RenameCompressorPlantTypesToSystemTypesAndUpdateStrategy'
)
BEGIN
    EXEC sp_rename N'[compressor_system_types].[IX_compressor_plant_types_updated_by]', N'IX_compressor_system_types_updated_by', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714120357_RenameCompressorPlantTypesToSystemTypesAndUpdateStrategy'
)
BEGIN
    EXEC sp_rename N'[compressor_system_types].[IX_compressor_plant_types_deleted_by]', N'IX_compressor_system_types_deleted_by', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714120357_RenameCompressorPlantTypesToSystemTypesAndUpdateStrategy'
)
BEGIN
    EXEC sp_rename N'[compressor_system_types].[IX_compressor_plant_types_created_by]', N'IX_compressor_system_types_created_by', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714120357_RenameCompressorPlantTypesToSystemTypesAndUpdateStrategy'
)
BEGIN
    ALTER TABLE [compressor_strategies] ADD CONSTRAINT [FK_compressor_strategies_compressor_system_types_compressor_system_type_id] FOREIGN KEY ([compressor_system_type_id]) REFERENCES [compressor_system_types] ([id]) ON DELETE NO ACTION;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714120357_RenameCompressorPlantTypesToSystemTypesAndUpdateStrategy'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260714120357_RenameCompressorPlantTypesToSystemTypesAndUpdateStrategy', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714120500_RedefineVwProjectsEtc'
)
BEGIN
    DROP VIEW IF EXISTS [dbo].[vwProjects];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714120500_RedefineVwProjectsEtc'
)
BEGIN

                   CREATE view [dbo].[vwProjects]
                   as
                        select a.*,b.name as field_name, b.working_area,
                        c.rkap_id,
                        d.code as rkap_code,
                        d.[description] as rkap_description,
                        '' as physical_progress_variance,
                        CONVERT(varchar(10), (
                            select max(pt.etc) from project_tasks pt
                            where pt.project_id = a.id and pt.deleted_at is null
                        ), 105) as etc
                        from projects a
                        left join fields b on a.field_id=b.field_id
                        left join rkap_projects c on a.id=c.project_id
                        left join rkaps d on c.rkap_id=d.id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714120500_RedefineVwProjectsEtc'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260714120500_RedefineVwProjectsEtc', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714162150_AddCompressorServicePackageUniqueIndexes'
)
BEGIN
    DROP INDEX [UX_compressor_engine_type_service_packages_engine_type_id_package_name] ON [compressor_engine_type_service_packages];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714162150_AddCompressorServicePackageUniqueIndexes'
)
BEGIN
    DROP INDEX [UX_compressor_engine_type_service_package_materials_package_id_kimap] ON [compressor_engine_type_service_package_materials];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714162150_AddCompressorServicePackageUniqueIndexes'
)
BEGIN
    DROP INDEX [UX_compressor_brand_type_service_packages_brand_type_id_package_name] ON [compressor_brand_type_service_packages];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714162150_AddCompressorServicePackageUniqueIndexes'
)
BEGIN
    DROP INDEX [UX_compressor_brand_type_service_package_materials_package_id_kimap] ON [compressor_brand_type_service_package_materials];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714162150_AddCompressorServicePackageUniqueIndexes'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_compressor_engine_type_service_packages_engine_type_id_package_name] ON [compressor_engine_type_service_packages] ([engine_type_id], [package_name]) WHERE [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714162150_AddCompressorServicePackageUniqueIndexes'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_compressor_engine_type_service_package_materials_package_id_kimap] ON [compressor_engine_type_service_package_materials] ([package_id], [kimap]) WHERE [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714162150_AddCompressorServicePackageUniqueIndexes'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_compressor_brand_type_service_packages_brand_type_id_package_name] ON [compressor_brand_type_service_packages] ([brand_type_id], [package_name]) WHERE [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714162150_AddCompressorServicePackageUniqueIndexes'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_compressor_brand_type_service_package_materials_package_id_kimap] ON [compressor_brand_type_service_package_materials] ([package_id], [kimap]) WHERE [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260714162150_AddCompressorServicePackageUniqueIndexes'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260714162150_AddCompressorServicePackageUniqueIndexes', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260715010000_AddUniqueIndexProjectRebaselinesVersion'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [IX_project_rebaselines_project_id_type_version] ON [project_rebaselines] ([project_id], [type], [version]) WHERE [deleted_at] IS NULL AND [version] IS NOT NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260715010000_AddUniqueIndexProjectRebaselinesVersion'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260715010000_AddUniqueIndexProjectRebaselinesVersion', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260715024259_AddCompressorSystemStrategyAndPlanningTimeline'
)
BEGIN
    CREATE TABLE [compressor_planning_timelines] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [compressor_id] uniqueidentifier NOT NULL,
        [compressor_system_id] uniqueidentifier NOT NULL,
        [start_date] datetime NOT NULL,
        [end_date] datetime NOT NULL,
        [remark] nvarchar(500) NULL,
        [capacity] decimal(18,2) NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_planning_timelines] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressor_planning_timelines_compressor_system_types_compressor_system_id] FOREIGN KEY ([compressor_system_id]) REFERENCES [compressor_system_types] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_planning_timelines_compressors_compressor_id] FOREIGN KEY ([compressor_id]) REFERENCES [compressors] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_planning_timelines_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_planning_timelines_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_planning_timelines_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260715024259_AddCompressorSystemStrategyAndPlanningTimeline'
)
BEGIN
    CREATE TABLE [compressor_system_strategies] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [compressor_id] uniqueidentifier NOT NULL,
        [compressor_system_id] uniqueidentifier NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_system_strategies] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressor_system_strategies_compressor_system_types_compressor_system_id] FOREIGN KEY ([compressor_system_id]) REFERENCES [compressor_system_types] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_system_strategies_compressors_compressor_id] FOREIGN KEY ([compressor_id]) REFERENCES [compressors] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_system_strategies_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_system_strategies_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_system_strategies_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260715024259_AddCompressorSystemStrategyAndPlanningTimeline'
)
BEGIN
    CREATE INDEX [IX_compressor_planning_timelines_compressor_id] ON [compressor_planning_timelines] ([compressor_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260715024259_AddCompressorSystemStrategyAndPlanningTimeline'
)
BEGIN
    CREATE INDEX [IX_compressor_planning_timelines_compressor_system_id] ON [compressor_planning_timelines] ([compressor_system_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260715024259_AddCompressorSystemStrategyAndPlanningTimeline'
)
BEGIN
    CREATE INDEX [IX_compressor_planning_timelines_created_by] ON [compressor_planning_timelines] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260715024259_AddCompressorSystemStrategyAndPlanningTimeline'
)
BEGIN
    CREATE INDEX [IX_compressor_planning_timelines_deleted_by] ON [compressor_planning_timelines] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260715024259_AddCompressorSystemStrategyAndPlanningTimeline'
)
BEGIN
    CREATE INDEX [IX_compressor_planning_timelines_updated_by] ON [compressor_planning_timelines] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260715024259_AddCompressorSystemStrategyAndPlanningTimeline'
)
BEGIN
    CREATE INDEX [IX_compressor_system_strategies_compressor_id] ON [compressor_system_strategies] ([compressor_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260715024259_AddCompressorSystemStrategyAndPlanningTimeline'
)
BEGIN
    CREATE INDEX [IX_compressor_system_strategies_compressor_system_id] ON [compressor_system_strategies] ([compressor_system_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260715024259_AddCompressorSystemStrategyAndPlanningTimeline'
)
BEGIN
    CREATE INDEX [IX_compressor_system_strategies_created_by] ON [compressor_system_strategies] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260715024259_AddCompressorSystemStrategyAndPlanningTimeline'
)
BEGIN
    CREATE INDEX [IX_compressor_system_strategies_deleted_by] ON [compressor_system_strategies] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260715024259_AddCompressorSystemStrategyAndPlanningTimeline'
)
BEGIN
    CREATE INDEX [IX_compressor_system_strategies_updated_by] ON [compressor_system_strategies] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260715024259_AddCompressorSystemStrategyAndPlanningTimeline'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260715024259_AddCompressorSystemStrategyAndPlanningTimeline', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000000_AddPosNameToUsers'
)
BEGIN
    IF COL_LENGTH('users', 'pos_name') IS NULL ALTER TABLE users ADD pos_name nvarchar(255) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000000_AddPosNameToUsers'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260716000000_AddPosNameToUsers', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF OBJECT_ID('FK_projects_organization_id', 'F') IS NOT NULL ALTER TABLE projects DROP CONSTRAINT FK_projects_organization_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_projects_organization_id' AND object_id = OBJECT_ID('projects')) DROP INDEX IX_projects_organization_id ON projects;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF COL_LENGTH('projects', 'organization_id') IS NOT NULL ALTER TABLE projects DROP COLUMN organization_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF COL_LENGTH('projects', 'org_path') IS NOT NULL ALTER TABLE projects DROP COLUMN org_path;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF OBJECT_ID('FK_contracts_organization_id', 'F') IS NOT NULL ALTER TABLE contracts DROP CONSTRAINT FK_contracts_organization_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_contracts_organization_id' AND object_id = OBJECT_ID('contracts')) DROP INDEX IX_contracts_organization_id ON contracts;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF COL_LENGTH('contracts', 'organization_id') IS NOT NULL ALTER TABLE contracts DROP COLUMN organization_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF COL_LENGTH('contracts', 'org_path') IS NOT NULL ALTER TABLE contracts DROP COLUMN org_path;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF OBJECT_ID('FK_spks_organization_id', 'F') IS NOT NULL ALTER TABLE spks DROP CONSTRAINT FK_spks_organization_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_spks_organization_id' AND object_id = OBJECT_ID('spks')) DROP INDEX IX_spks_organization_id ON spks;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF COL_LENGTH('spks', 'organization_id') IS NOT NULL ALTER TABLE spks DROP COLUMN organization_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF COL_LENGTH('spks', 'org_path') IS NOT NULL ALTER TABLE spks DROP COLUMN org_path;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF OBJECT_ID('FK_invoices_organization_id', 'F') IS NOT NULL ALTER TABLE invoices DROP CONSTRAINT FK_invoices_organization_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_invoices_organization_id' AND object_id = OBJECT_ID('invoices')) DROP INDEX IX_invoices_organization_id ON invoices;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF COL_LENGTH('invoices', 'organization_id') IS NOT NULL ALTER TABLE invoices DROP COLUMN organization_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF COL_LENGTH('invoices', 'org_path') IS NOT NULL ALTER TABLE invoices DROP COLUMN org_path;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF OBJECT_ID('FK_service_acceptances_organization_id', 'F') IS NOT NULL ALTER TABLE service_acceptances DROP CONSTRAINT FK_service_acceptances_organization_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_service_acceptances_organization_id' AND object_id = OBJECT_ID('service_acceptances')) DROP INDEX IX_service_acceptances_organization_id ON service_acceptances;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF COL_LENGTH('service_acceptances', 'organization_id') IS NOT NULL ALTER TABLE service_acceptances DROP COLUMN organization_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    IF COL_LENGTH('service_acceptances', 'org_path') IS NOT NULL ALTER TABLE service_acceptances DROP COLUMN org_path;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260716000100_DropOrganizationLinkFromRoots'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260716000100_DropOrganizationLinkFromRoots', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260717012438_MakeCompressorPlanningTimelineCompressorIdNullable'
)
BEGIN
    DECLARE @var102 sysname;
    SELECT @var102 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[compressor_planning_timelines]') AND [c].[name] = N'compressor_id');
    IF @var102 IS NOT NULL EXEC(N'ALTER TABLE [compressor_planning_timelines] DROP CONSTRAINT [' + @var102 + '];');
    ALTER TABLE [compressor_planning_timelines] ALTER COLUMN [compressor_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260717012438_MakeCompressorPlanningTimelineCompressorIdNullable'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260717012438_MakeCompressorPlanningTimelineCompressorIdNullable', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260717030649_IncreaseBoqOriginalFileLength'
)
BEGIN
    DECLARE @var103 sysname;
    SELECT @var103 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[boqs]') AND [c].[name] = N'original_file');
    IF @var103 IS NOT NULL EXEC(N'ALTER TABLE [boqs] DROP CONSTRAINT [' + @var103 + '];');
    ALTER TABLE [boqs] ALTER COLUMN [original_file] nvarchar(500) NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260717030649_IncreaseBoqOriginalFileLength'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260717030649_IncreaseBoqOriginalFileLength', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260717104702_RetargetCompressorSystemStrategyToCompressorStrategy'
)
BEGIN
    ALTER TABLE [compressor_system_strategies] DROP CONSTRAINT [FK_compressor_system_strategies_compressors_compressor_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260717104702_RetargetCompressorSystemStrategyToCompressorStrategy'
)
BEGIN
    ALTER TABLE [compressor_system_strategies] ADD CONSTRAINT [FK_compressor_system_strategies_compressor_strategies_compressor_id] FOREIGN KEY ([compressor_id]) REFERENCES [compressor_strategies] ([id]) ON DELETE NO ACTION;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260717104702_RetargetCompressorSystemStrategyToCompressorStrategy'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260717104702_RetargetCompressorSystemStrategyToCompressorStrategy', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260718065055_FixVwProjectTaskSummaryFormula'
)
BEGIN

            ALTER VIEW [dbo].[vwProjectTaskSummary] AS
            WITH schedules AS (
                SELECT pts.*
                FROM project_task_schedules pts
                JOIN project_tasks pt ON pts.project_task_id = pt.id
                JOIN projects p ON pt.project_id = p.id
                WHERE pt.deleted_at IS NULL AND p.deleted_at IS NULL AND pt.data_type = 'item'
            ),
            tempProjectTask AS (
                SELECT
                    pt.project_id, pt.breakdown, pt.[description], pt.[weight], pt.data_type, pt.[status], pt.estimated_cost,
                    p.category,
                    (LEN(pt.breakdown) - LEN(REPLACE(pt.breakdown, '.', '')) + 1) AS wbs_level,
                    COALESCE((SELECT SUM(pts.plan_progress)   FROM schedules pts WHERE pts.project_task_id = pt.id AND pts.date <= GETDATE()), 0) AS plan_progress_itd,
                    COALESCE((SELECT SUM(pts.plan_weight)     FROM schedules pts WHERE pts.project_task_id = pt.id AND pts.date <= GETDATE()), 0) AS plan_weight_itd,
                    COALESCE((SELECT SUM(pts.actual_progress) FROM schedules pts WHERE pts.project_task_id = pt.id AND pts.date <= GETDATE()), 0) AS actual_progress_itd,
                    COALESCE((SELECT SUM(pts.actual_weight)   FROM schedules pts WHERE pts.project_task_id = pt.id AND pts.date <= GETDATE()), 0) AS actual_weight_itd
                FROM project_tasks pt
                JOIN projects p ON pt.project_id = p.id
                WHERE pt.deleted_at IS NULL
            ),
            CalculatedData AS (
                SELECT
                    tpt.project_id, tpt.breakdown AS wbs, tpt.wbs_level, tpt.description, tpt.weight,
                    tpt.data_type, tpt.status, tpt.estimated_cost, tpt.category AS project_category,
                    CASE
                        WHEN tpt.data_type = 'item' THEN tpt.plan_weight_itd
                        ELSE (SELECT SUM(tt2.plan_weight_itd) FROM tempProjectTask tt2
                              WHERE tt2.project_id = tpt.project_id
                                AND (tt2.breakdown LIKE tpt.breakdown + '.%' OR tt2.breakdown = tpt.breakdown))
                    END AS plan_weight_itd,
                    CASE
                        WHEN tpt.data_type = 'item' THEN ROUND(tpt.plan_progress_itd, 2)
                        ELSE ROUND(
                            (SELECT SUM(tt2.plan_weight_itd) FROM tempProjectTask tt2
                             WHERE tt2.project_id = tpt.project_id
                               AND (tt2.breakdown LIKE tpt.breakdown + '.%' OR tt2.breakdown = tpt.breakdown))
                            / NULLIF((SELECT SUM(tt3.weight) FROM tempProjectTask tt3
                                      WHERE tt3.project_id = tpt.project_id AND tt3.data_type = 'item'
                                        AND (tt3.breakdown LIKE tpt.breakdown + '.%' OR tt3.breakdown = tpt.breakdown)), 0)
                            * 100, 2)
                    END AS plan_progress_itd,
                    CASE
                        WHEN tpt.data_type = 'item' THEN tpt.actual_weight_itd
                        ELSE (SELECT SUM(tt2.actual_weight_itd) FROM tempProjectTask tt2
                              WHERE tt2.project_id = tpt.project_id
                                AND (tt2.breakdown LIKE tpt.breakdown + '.%' OR tt2.breakdown = tpt.breakdown))
                    END AS actual_weight_itd,
                    CASE
                        WHEN tpt.data_type = 'item' THEN ROUND(tpt.actual_progress_itd, 2)
                        ELSE ROUND(
                            (SELECT SUM(tt2.actual_weight_itd) FROM tempProjectTask tt2
                             WHERE tt2.project_id = tpt.project_id
                               AND (tt2.breakdown LIKE tpt.breakdown + '.%' OR tt2.breakdown = tpt.breakdown))
                            / NULLIF((SELECT SUM(tt3.weight) FROM tempProjectTask tt3
                                      WHERE tt3.project_id = tpt.project_id AND tt3.data_type = 'item'
                                        AND (tt3.breakdown LIKE tpt.breakdown + '.%' OR tt3.breakdown = tpt.breakdown)), 0)
                            * 100, 2)
                    END AS actual_progress_itd
                FROM tempProjectTask tpt
            )
            SELECT *,
                   ROUND(actual_progress_itd - plan_progress_itd, 2) AS variance
            FROM CalculatedData
            WHERE wbs_level IN (1, 2);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260718065055_FixVwProjectTaskSummaryFormula'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260718065055_FixVwProjectTaskSummaryFormula', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260718103700_RetargetCompressorPlanningTimelineToCompressorStrategy'
)
BEGIN
    ALTER TABLE [compressor_planning_timelines] DROP CONSTRAINT [FK_compressor_planning_timelines_compressors_compressor_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260718103700_RetargetCompressorPlanningTimelineToCompressorStrategy'
)
BEGIN
    ALTER TABLE [compressor_planning_timelines] ADD CONSTRAINT [FK_compressor_planning_timelines_compressor_strategies_compressor_id] FOREIGN KEY ([compressor_id]) REFERENCES [compressor_strategies] ([id]) ON DELETE NO ACTION;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260718103700_RetargetCompressorPlanningTimelineToCompressorStrategy'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260718103700_RetargetCompressorPlanningTimelineToCompressorStrategy', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260719000000_RetargetWellCompressorAssignmentToCompressorStrategy'
)
BEGIN
    ALTER TABLE [well_compressor_assignments] DROP CONSTRAINT [FK_well_compressor_assignments_well_compressor_destinations_compressor_destination_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260719000000_RetargetWellCompressorAssignmentToCompressorStrategy'
)
BEGIN
    ALTER TABLE [well_compressor_assignments] ADD CONSTRAINT [FK_well_compressor_assignments_compressor_strategies_compressor_destination_id] FOREIGN KEY ([compressor_destination_id]) REFERENCES [compressor_strategies] ([id]) ON DELETE NO ACTION;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260719000000_RetargetWellCompressorAssignmentToCompressorStrategy'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260719000000_RetargetWellCompressorAssignmentToCompressorStrategy', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260719000100_RetargetWellsPlantToPlants'
)
BEGIN
    ALTER TABLE [wells] DROP CONSTRAINT [FK_wells_well_plants_plant_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260719000100_RetargetWellsPlantToPlants'
)
BEGIN
    ALTER TABLE [wells] ADD CONSTRAINT [FK_wells_plants_plant_id] FOREIGN KEY ([plant_id]) REFERENCES [plants] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260719000100_RetargetWellsPlantToPlants'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260719000100_RetargetWellsPlantToPlants', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260719000200_RetargetWellPlantAssignmentToPlants'
)
BEGIN
    ALTER TABLE [well_plant_assignments] DROP CONSTRAINT [FK_well_plant_assignments_well_plants_well_plant_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260719000200_RetargetWellPlantAssignmentToPlants'
)
BEGIN
    ALTER TABLE [well_plant_assignments] ADD CONSTRAINT [FK_well_plant_assignments_plants_well_plant_id] FOREIGN KEY ([well_plant_id]) REFERENCES [plants] ([id]) ON DELETE NO ACTION;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260719000200_RetargetWellPlantAssignmentToPlants'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260719000200_RetargetWellPlantAssignmentToPlants', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260720035105_AddOtherJsonColumn'
)
BEGIN
    ALTER TABLE [spks] ADD [other] nvarchar(max) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260720035105_AddOtherJsonColumn'
)
BEGIN
    ALTER TABLE [projects] ADD [other] nvarchar(max) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260720035105_AddOtherJsonColumn'
)
BEGIN
    ALTER TABLE [project_tasks] ADD [other] nvarchar(max) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260720035105_AddOtherJsonColumn'
)
BEGIN
    ALTER TABLE [contracts] ADD [other] nvarchar(max) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260720035105_AddOtherJsonColumn'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260720035105_AddOtherJsonColumn', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260720042941_AddWellHistoryPhssNaturalKeyUniqueIndex'
)
BEGIN
    WITH ranked AS (
        SELECT id,
               ROW_NUMBER() OVER (
                   PARTITION BY well_id, well_zone_id, prod_date
                   ORDER BY created_at, id) AS rn
        FROM   dbo.well_history_phss
        WHERE  deleted_at IS NULL
    )
    UPDATE h
       SET h.deleted_at = SYSDATETIME()
    FROM dbo.well_history_phss h
    JOIN ranked r ON r.id = h.id
    WHERE r.rn > 1;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260720042941_AddWellHistoryPhssNaturalKeyUniqueIndex'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_well_history_phss_well_zone_prod_date')
        CREATE UNIQUE NONCLUSTERED INDEX IX_well_history_phss_well_zone_prod_date
            ON dbo.well_history_phss (well_id, well_zone_id, prod_date)
            WHERE deleted_at IS NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260720042941_AddWellHistoryPhssNaturalKeyUniqueIndex'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260720042941_AddWellHistoryPhssNaturalKeyUniqueIndex', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260720075823_AddWellHistoriesPepNaturalKeyUniqueIndex'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_well_histories_pep_well_zone_prod_date')
        CREATE UNIQUE NONCLUSTERED INDEX IX_well_histories_pep_well_zone_prod_date
            ON dbo.well_histories_pep (well, zone_id, prod_date)
            WHERE deleted_at IS NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260720075823_AddWellHistoriesPepNaturalKeyUniqueIndex'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260720075823_AddWellHistoriesPepNaturalKeyUniqueIndex', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260721034334_AddEurSweeperState'
)
BEGIN
    IF OBJECT_ID('dbo.eur_sweeper_state', 'U') IS NULL
    BEGIN
        CREATE TABLE dbo.eur_sweeper_state (
            kind               VARCHAR(8)       NOT NULL CONSTRAINT PK_eur_sweeper_state PRIMARY KEY,
            last_swept_at      DATETIME2(7)     NOT NULL,
            last_well_id       UNIQUEIDENTIFIER NOT NULL,
            last_well_zone_id  UNIQUEIDENTIFIER NOT NULL,
            created_at         DATETIME2(7)     NOT NULL,
            updated_at         DATETIME2(7)     NULL
        );
        INSERT INTO dbo.eur_sweeper_state (kind, last_swept_at, last_well_id, last_well_zone_id, created_at)
        VALUES ('phss', '1900-01-01', '00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000000', SYSDATETIME()),
               ('pep',  '1900-01-01', '00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000000', SYSDATETIME());
    END
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260721034334_AddEurSweeperState'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260721034334_AddEurSweeperState', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260721034358_LengthKimapMaterialMonitoring'
)
BEGIN
    DECLARE @var104 sysname;
    SELECT @var104 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[material_monitoring_details]') AND [c].[name] = N'kimap');
    IF @var104 IS NOT NULL EXEC(N'ALTER TABLE [material_monitoring_details] DROP CONSTRAINT [' + @var104 + '];');
    ALTER TABLE [material_monitoring_details] ALTER COLUMN [kimap] nvarchar(50) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260721034358_LengthKimapMaterialMonitoring'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260721034358_LengthKimapMaterialMonitoring', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260723091832_RetargetPhssActionPlanChokeCompressorToCompressorStrategy'
)
BEGIN
    ALTER TABLE [phss_action_plan_choke] DROP CONSTRAINT [FK_phss_action_plan_choke_well_compressor_destinations_compressor_id];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260723091832_RetargetPhssActionPlanChokeCompressorToCompressorStrategy'
)
BEGIN
    ALTER TABLE [phss_action_plan_choke] ADD CONSTRAINT [FK_phss_action_plan_choke_compressor_strategies_compressor_id] FOREIGN KEY ([compressor_id]) REFERENCES [compressor_strategies] ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260723091832_RetargetPhssActionPlanChokeCompressorToCompressorStrategy'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260723091832_RetargetPhssActionPlanChokeCompressorToCompressorStrategy', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260723192555_AddArtificialLiftMultiRowSupport'
)
BEGIN
    ALTER TABLE [phss_action_plan_artificial_lift] DROP CONSTRAINT [PK_phss_action_plan_artificial_lift];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260723192555_AddArtificialLiftMultiRowSupport'
)
BEGIN
    ALTER TABLE [phss_action_plan_artificial_lift] ADD [id] uniqueidentifier NOT NULL DEFAULT ((newid()));
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260723192555_AddArtificialLiftMultiRowSupport'
)
BEGIN
    ALTER TABLE [phss_action_plan_artificial_lift] ADD CONSTRAINT [PK_phss_action_plan_artificial_lift] PRIMARY KEY ([id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260723192555_AddArtificialLiftMultiRowSupport'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [IX_phss_action_plan_artificial_lift_action_plan_id_action_mode] ON [phss_action_plan_artificial_lift] ([action_plan_id], [action_mode]) WHERE [action_mode] IS NOT NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260723192555_AddArtificialLiftMultiRowSupport'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260723192555_AddArtificialLiftMultiRowSupport', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260724102955_MakeWellEurSummaryWellZoneIdNullable'
)
BEGIN
    DECLARE @var105 sysname;
    SELECT @var105 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[well_eur_summaries]') AND [c].[name] = N'well_zone_id');
    IF @var105 IS NOT NULL EXEC(N'ALTER TABLE [well_eur_summaries] DROP CONSTRAINT [' + @var105 + '];');
    ALTER TABLE [well_eur_summaries] ALTER COLUMN [well_zone_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260724102955_MakeWellEurSummaryWellZoneIdNullable'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260724102955_MakeWellEurSummaryWellZoneIdNullable', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260726082330_AddWellHistoryPepGuidFk'
)
BEGIN
    CREATE TABLE [well_history_pep] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [well_id] uniqueidentifier NOT NULL,
        [well_zone_id] uniqueidentifier NOT NULL,
        [prod_date] date NULL,
        [oil] float NULL,
        [gas_out] float NULL,
        [gas_in] float NULL,
        [water_cut] float NULL,
        [gross] float NULL,
        [water] float NULL,
        [fthp] float NULL,
        [flp] float NULL,
        [temperature] float NULL,
        [choke_size] float NULL,
        [ampere] float NULL,
        [stroke_length] float NULL,
        [stroke_per_minute] float NULL,
        [latest_production_test] datetime2 NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_history_pep] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_history_pep_well_zones_well_zone_id] FOREIGN KEY ([well_zone_id]) REFERENCES [well_zones] ([id]),
        CONSTRAINT [FK_well_history_pep_wells_well_id] FOREIGN KEY ([well_id]) REFERENCES [wells] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260726082330_AddWellHistoryPepGuidFk'
)
BEGIN
    CREATE INDEX [IX_well_history_pep_created_by] ON [well_history_pep] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260726082330_AddWellHistoryPepGuidFk'
)
BEGIN
    CREATE INDEX [IX_well_history_pep_prod_date] ON [well_history_pep] ([prod_date]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260726082330_AddWellHistoryPepGuidFk'
)
BEGIN
    CREATE INDEX [IX_well_history_pep_well_id] ON [well_history_pep] ([well_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260726082330_AddWellHistoryPepGuidFk'
)
BEGIN
    CREATE INDEX [IX_well_history_pep_well_zone_id] ON [well_history_pep] ([well_zone_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260726082330_AddWellHistoryPepGuidFk'
)
BEGIN
    WITH mapped AS (
        SELECT p.id, w.id AS well_id, z.id AS well_zone_id,
               CAST(p.prod_date AS date) AS prod_date,
               p.oil, p.gas_out, p.gas_in, p.water_cut, p.gross, p.water,
               p.fthp, p.flp, p.temperature, p.choke_size,
               p.ampere, p.stroke_length, p.stroke_per_minute, p.latest_production_test,
               p.created_at, p.created_by, p.updated_at, p.updated_by,
               ROW_NUMBER() OVER (
                   PARTITION BY w.id, z.id, CAST(p.prod_date AS date)
                   ORDER BY p.created_at, p.id) AS rn
        FROM   dbo.well_histories_pep p
        JOIN   dbo.well_zones z
               ON z.id = TRY_CONVERT(uniqueidentifier, p.zone_id) AND z.deleted_at IS NULL
        JOIN   dbo.wells w
               ON w.well_name = p.well AND w.deleted_at IS NULL
        JOIN   dbo.well_zone_assignments a
               ON a.well_id = w.id AND a.well_zone_id = z.id
              AND a.working_area = 'pep' AND a.deleted_at IS NULL
        WHERE  p.deleted_at IS NULL AND p.prod_date IS NOT NULL
    )
    INSERT INTO dbo.well_history_pep
        (id, well_id, well_zone_id, prod_date, oil, gas_out, gas_in, water_cut, gross, water,
         fthp, flp, temperature, choke_size, ampere, stroke_length, stroke_per_minute,
         latest_production_test, created_at, created_by, updated_at, updated_by)
    SELECT id, well_id, well_zone_id, prod_date, oil, gas_out, gas_in, water_cut, gross, water,
           fthp, flp, temperature, choke_size, ampere, stroke_length, stroke_per_minute,
           latest_production_test, created_at, created_by, updated_at, updated_by
    FROM   mapped
    WHERE  rn = 1;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260726082330_AddWellHistoryPepGuidFk'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_well_history_pep_well_zone_prod_date')
        CREATE UNIQUE NONCLUSTERED INDEX IX_well_history_pep_well_zone_prod_date
            ON dbo.well_history_pep (well_id, well_zone_id, prod_date)
            WHERE deleted_at IS NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260726082330_AddWellHistoryPepGuidFk'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260726082330_AddWellHistoryPepGuidFk', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260726130423_RetargetActionPlanWellFkBackToWells'
)
BEGIN
    DECLARE @fk_phss_action_plan sysname = (
        SELECT TOP 1 fk.name
        FROM   sys.foreign_keys fk
        JOIN   sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
        JOIN   sys.columns c ON c.object_id = fk.parent_object_id AND c.column_id = fkc.parent_column_id
        WHERE  fk.parent_object_id = OBJECT_ID('dbo.phss_action_plan') AND c.name = 'well_id');
    IF @fk_phss_action_plan IS NOT NULL
        EXEC('ALTER TABLE dbo.phss_action_plan DROP CONSTRAINT [' + @fk_phss_action_plan + ']');

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'phss_action_plan_wells_FK')
        ALTER TABLE dbo.phss_action_plan
            ADD CONSTRAINT [phss_action_plan_wells_FK] FOREIGN KEY (well_id) REFERENCES dbo.wells (id);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260726130423_RetargetActionPlanWellFkBackToWells'
)
BEGIN
    DECLARE @fk_pep_action_plan sysname = (
        SELECT TOP 1 fk.name
        FROM   sys.foreign_keys fk
        JOIN   sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
        JOIN   sys.columns c ON c.object_id = fk.parent_object_id AND c.column_id = fkc.parent_column_id
        WHERE  fk.parent_object_id = OBJECT_ID('dbo.pep_action_plan') AND c.name = 'well_id');
    IF @fk_pep_action_plan IS NOT NULL
        EXEC('ALTER TABLE dbo.pep_action_plan DROP CONSTRAINT [' + @fk_pep_action_plan + ']');

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'pep_action_plan_wells_FK')
        ALTER TABLE dbo.pep_action_plan
            ADD CONSTRAINT [pep_action_plan_wells_FK] FOREIGN KEY (well_id) REFERENCES dbo.wells (id);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260726130423_RetargetActionPlanWellFkBackToWells'
)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_pep_action_plan_well_zone_assignment_id' AND object_id = OBJECT_ID('dbo.pep_action_plan'))
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_pep_action_plan_well_id' AND object_id = OBJECT_ID('dbo.pep_action_plan'))
        EXEC sp_rename 'dbo.pep_action_plan.IX_pep_action_plan_well_zone_assignment_id', 'IX_pep_action_plan_well_id', 'INDEX';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260726130423_RetargetActionPlanWellFkBackToWells'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260726130423_RetargetActionPlanWellFkBackToWells', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260726152410_AddArtificialLiftAuditColumns'
)
BEGIN
    DROP INDEX [IX_phss_action_plan_artificial_lift_action_plan_id_action_mode] ON [phss_action_plan_artificial_lift];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260726152410_AddArtificialLiftAuditColumns'
)
BEGIN
    ALTER TABLE [phss_action_plan_artificial_lift] ADD [created_at] datetime NOT NULL DEFAULT ((getdate()));
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260726152410_AddArtificialLiftAuditColumns'
)
BEGIN
    ALTER TABLE [phss_action_plan_artificial_lift] ADD [updated_at] datetime NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260726152410_AddArtificialLiftAuditColumns'
)
BEGIN
    ALTER TABLE [phss_action_plan_artificial_lift] ADD [deleted_at] datetime NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260726152410_AddArtificialLiftAuditColumns'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [IX_phss_action_plan_artificial_lift_action_plan_id_action_mode] ON [phss_action_plan_artificial_lift] ([action_plan_id], [action_mode]) WHERE [action_mode] IS NOT NULL AND [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260726152410_AddArtificialLiftAuditColumns'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260726152410_AddArtificialLiftAuditColumns', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260729020033_SeedEurStatusThreshold'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.custom_configurations WHERE name = 'well_eur_monitoring.eur_status_threshold')
      INSERT INTO dbo.custom_configurations (id, name, description, detail, created_at, created_by, updated_at, updated_by)
      SELECT NEWID(),
             'well_eur_monitoring.eur_status_threshold',
             'EUR Monitoring status threshold: cumprod/EUR ratio % at which a well becomes Approaching (>= 100% is EUR Exceeded)',
             '{"approaching":90.0}',
             GETDATE(), u.id, GETDATE(), u.id
      FROM (SELECT TOP 1 id FROM dbo.users ORDER BY created_at) u;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260729020033_SeedEurStatusThreshold'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260729020033_SeedEurStatusThreshold', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260729063943_SeedCriticalRateSource'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.custom_configurations WHERE name = 'well_histories.critical_rate_source')
      INSERT INTO dbo.custom_configurations (id, name, description, detail, created_at, created_by, updated_at, updated_by)
      SELECT NEWID(),
             'well_histories.critical_rate_source',
             'Which stored column feeds critical_rate: "turner" -> turner_rate_mmscfd, "coleman" -> coleman_rate_mmscfd. Default turner (more conservative).',
             '{"source":"turner"}',
             GETDATE(), u.id, GETDATE(), u.id
      FROM (SELECT TOP 1 id FROM dbo.users ORDER BY created_at) u;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260729063943_SeedCriticalRateSource'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260729063943_SeedCriticalRateSource', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260730165600_AddDepartmentIdToMaterialMonitorings'
)
BEGIN
    ALTER TABLE [material_monitorings] ADD [department_id] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260730165600_AddDepartmentIdToMaterialMonitorings'
)
BEGIN
    CREATE INDEX [IX_material_monitorings_department_id] ON [material_monitorings] ([department_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260730165600_AddDepartmentIdToMaterialMonitorings'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260730165600_AddDepartmentIdToMaterialMonitorings', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260731074135_AddDepartmentIdToTenders'
)
BEGIN
    ALTER TABLE [tenders] ADD [department_id] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260731074135_AddDepartmentIdToTenders'
)
BEGIN
    CREATE INDEX [IX_tenders_department_id] ON [tenders] ([department_id], [deleted_at]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260731074135_AddDepartmentIdToTenders'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260731074135_AddDepartmentIdToTenders', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260731074345_BackfillMaterialMonitoringDepartmentId'
)
BEGIN

                UPDATE m
                SET m.department_id = u.department
                FROM material_monitorings m
                INNER JOIN users u ON u.id = m.created_by
                WHERE m.department_id IS NULL AND u.department IS NOT NULL
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260731074345_BackfillMaterialMonitoringDepartmentId'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260731074345_BackfillMaterialMonitoringDepartmentId', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260731120000_AddDepartmentIdToApprovalRoutes'
)
BEGIN
    ALTER TABLE [approval_routes] ADD [department_id] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260731120000_AddDepartmentIdToApprovalRoutes'
)
BEGIN
    CREATE INDEX [IX_approval_routes_department_id] ON [approval_routes] ([department_id], [deleted_at]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260731120000_AddDepartmentIdToApprovalRoutes'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260731120000_AddDepartmentIdToApprovalRoutes', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260805022828_AddProjectTaskPics'
)
BEGIN
    CREATE TABLE [project_task_pics] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [project_task_id] uniqueidentifier NULL,
        [user_id] uniqueidentifier NULL,
        [created_at] datetime NULL,
        [created_by] uniqueidentifier NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_project_task_pics] PRIMARY KEY ([id]),
        CONSTRAINT [FK_project_task_pics_project_tasks_project_task_id] FOREIGN KEY ([project_task_id]) REFERENCES [project_tasks] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_project_task_pics_users_user_id] FOREIGN KEY ([user_id]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260805022828_AddProjectTaskPics'
)
BEGIN
    CREATE INDEX [IX_project_task_pics_project_task_id] ON [project_task_pics] ([project_task_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260805022828_AddProjectTaskPics'
)
BEGIN
    CREATE INDEX [IX_project_task_pics_user_id] ON [project_task_pics] ([user_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260805022828_AddProjectTaskPics'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_project_task_pics_project_user] ON [project_task_pics] ([project_task_id], [user_id]) WHERE [project_task_id] IS NOT NULL AND [user_id] IS NOT NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260805022828_AddProjectTaskPics'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260805022828_AddProjectTaskPics', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806080845_AddWellPicAssignments'
)
BEGIN
    CREATE TABLE [well_pic_assignments] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [well_id] uniqueidentifier NOT NULL,
        [well_pic_id] uniqueidentifier NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_well_pic_assignments] PRIMARY KEY ([id]),
        CONSTRAINT [FK_well_pic_assignments_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_well_pic_assignments_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_well_pic_assignments_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_well_pic_assignments_users_well_pic_id] FOREIGN KEY ([well_pic_id]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_well_pic_assignments_wells_well_id] FOREIGN KEY ([well_id]) REFERENCES [wells] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806080845_AddWellPicAssignments'
)
BEGIN
    CREATE INDEX [IX_well_pic_assignments_created_by] ON [well_pic_assignments] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806080845_AddWellPicAssignments'
)
BEGIN
    CREATE INDEX [IX_well_pic_assignments_deleted_by] ON [well_pic_assignments] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806080845_AddWellPicAssignments'
)
BEGIN
    CREATE INDEX [IX_well_pic_assignments_updated_by] ON [well_pic_assignments] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806080845_AddWellPicAssignments'
)
BEGIN
    CREATE INDEX [IX_well_pic_assignments_well_id] ON [well_pic_assignments] ([well_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806080845_AddWellPicAssignments'
)
BEGIN
    CREATE INDEX [IX_well_pic_assignments_well_pic_id] ON [well_pic_assignments] ([well_pic_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806080845_AddWellPicAssignments'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260806080845_AddWellPicAssignments', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806094849_AddPhssActionPlanPicAssignment'
)
BEGIN
    CREATE TABLE [phss_action_plan_pic_assignments] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [action_plan_id] uniqueidentifier NOT NULL,
        [pic_id] uniqueidentifier NOT NULL,
        [working_area] nvarchar(max) NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_phss_action_plan_pic_assignments] PRIMARY KEY ([id]),
        CONSTRAINT [FK_pic_assignments_phss_action_plans_action_plan_id] FOREIGN KEY ([action_plan_id]) REFERENCES [phss_action_plan] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_pic_assignments_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_pic_assignments_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_pic_assignments_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_pic_assignments_users_well_pic_id] FOREIGN KEY ([pic_id]) REFERENCES [users] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806094849_AddPhssActionPlanPicAssignment'
)
BEGIN
    CREATE INDEX [IX_phss_action_plan_pic_assignments_action_plan_id] ON [phss_action_plan_pic_assignments] ([action_plan_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806094849_AddPhssActionPlanPicAssignment'
)
BEGIN
    CREATE INDEX [IX_phss_action_plan_pic_assignments_created_by] ON [phss_action_plan_pic_assignments] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806094849_AddPhssActionPlanPicAssignment'
)
BEGIN
    CREATE INDEX [IX_phss_action_plan_pic_assignments_deleted_by] ON [phss_action_plan_pic_assignments] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806094849_AddPhssActionPlanPicAssignment'
)
BEGIN
    CREATE INDEX [IX_phss_action_plan_pic_assignments_pic_id] ON [phss_action_plan_pic_assignments] ([pic_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806094849_AddPhssActionPlanPicAssignment'
)
BEGIN
    CREATE INDEX [IX_phss_action_plan_pic_assignments_updated_by] ON [phss_action_plan_pic_assignments] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806094849_AddPhssActionPlanPicAssignment'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260806094849_AddPhssActionPlanPicAssignment', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806103435_AddPepActionPlanPicAssignment'
)
BEGIN
    CREATE TABLE [pep_action_plan_pic_assignments] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [action_plan_id] uniqueidentifier NOT NULL,
        [pic_id] uniqueidentifier NOT NULL,
        [working_area] nvarchar(max) NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_pep_action_plan_pic_assignments] PRIMARY KEY ([id]),
        CONSTRAINT [FK_pep_action_plan_pic_assignments_action_plan_id] FOREIGN KEY ([action_plan_id]) REFERENCES [pep_action_plan] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_pep_action_plan_pic_assignments_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_pep_action_plan_pic_assignments_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_pep_action_plan_pic_assignments_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_pep_action_plan_pic_assignments_users_well_pic_id] FOREIGN KEY ([pic_id]) REFERENCES [users] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806103435_AddPepActionPlanPicAssignment'
)
BEGIN
    CREATE INDEX [IX_pep_action_plan_pic_assignments_action_plan_id] ON [pep_action_plan_pic_assignments] ([action_plan_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806103435_AddPepActionPlanPicAssignment'
)
BEGIN
    CREATE INDEX [IX_pep_action_plan_pic_assignments_created_by] ON [pep_action_plan_pic_assignments] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806103435_AddPepActionPlanPicAssignment'
)
BEGIN
    CREATE INDEX [IX_pep_action_plan_pic_assignments_deleted_by] ON [pep_action_plan_pic_assignments] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806103435_AddPepActionPlanPicAssignment'
)
BEGIN
    CREATE INDEX [IX_pep_action_plan_pic_assignments_pic_id] ON [pep_action_plan_pic_assignments] ([pic_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806103435_AddPepActionPlanPicAssignment'
)
BEGIN
    CREATE INDEX [IX_pep_action_plan_pic_assignments_updated_by] ON [pep_action_plan_pic_assignments] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806103435_AddPepActionPlanPicAssignment'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260806103435_AddPepActionPlanPicAssignment', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806161704_AddApprovalRouteKpiConfig'
)
BEGIN
    ALTER TABLE [spks] ADD [approval_version] int NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806161704_AddApprovalRouteKpiConfig'
)
BEGIN
    ALTER TABLE [approval_routes] ADD [spk_value_threshold] decimal(18,2) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806161704_AddApprovalRouteKpiConfig'
)
BEGIN
    CREATE TABLE [approval_route_levels] (
        [id] uniqueidentifier NOT NULL,
        [approval_route_id] uniqueidentifier NOT NULL,
        [level_number] int NOT NULL,
        [signature_method] nvarchar(100) NULL,
        [wording] nvarchar(100) NULL,
        [kpi_paraf1_days] int NULL,
        [kpi_paraf2_days] int NULL,
        [kpi_full_sign_days] int NOT NULL,
        [full_sign_user_id] uniqueidentifier NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime2 NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_approval_route_levels] PRIMARY KEY ([id]),
        CONSTRAINT [FK_approval_route_levels_approval_routes_approval_route_id] FOREIGN KEY ([approval_route_id]) REFERENCES [approval_routes] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_approval_route_levels_users_full_sign_user_id] FOREIGN KEY ([full_sign_user_id]) REFERENCES [users] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806161704_AddApprovalRouteKpiConfig'
)
BEGIN
    CREATE TABLE [approval_route_level_users] (
        [id] uniqueidentifier NOT NULL,
        [approval_route_level_id] uniqueidentifier NOT NULL,
        [slot_number] int NOT NULL,
        [user_id] uniqueidentifier NOT NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [deleted_at] datetime2 NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_approval_route_level_users] PRIMARY KEY ([id]),
        CONSTRAINT [FK_approval_route_level_users_approval_route_levels_approval_route_level_id] FOREIGN KEY ([approval_route_level_id]) REFERENCES [approval_route_levels] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_approval_route_level_users_users_user_id] FOREIGN KEY ([user_id]) REFERENCES [users] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806161704_AddApprovalRouteKpiConfig'
)
BEGIN
    CREATE INDEX [IX_approval_route_level_users_approval_route_level_id] ON [approval_route_level_users] ([approval_route_level_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806161704_AddApprovalRouteKpiConfig'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [IX_approval_route_level_users_approval_route_level_id_user_id] ON [approval_route_level_users] ([approval_route_level_id], [user_id]) WHERE [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806161704_AddApprovalRouteKpiConfig'
)
BEGIN
    CREATE INDEX [IX_approval_route_level_users_user_id] ON [approval_route_level_users] ([user_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806161704_AddApprovalRouteKpiConfig'
)
BEGIN
    CREATE INDEX [IX_approval_route_levels_approval_route_id] ON [approval_route_levels] ([approval_route_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806161704_AddApprovalRouteKpiConfig'
)
BEGIN
    CREATE INDEX [IX_approval_route_levels_full_sign_user_id] ON [approval_route_levels] ([full_sign_user_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260806161704_AddApprovalRouteKpiConfig'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260806161704_AddApprovalRouteKpiConfig', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260807081726_DropActionPlanPicColumn'
)
BEGIN
    DECLARE @var106 sysname;
    SELECT @var106 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[pep_action_plan_pic_assignments]') AND [c].[name] = N'working_area');
    IF @var106 IS NOT NULL EXEC(N'ALTER TABLE [pep_action_plan_pic_assignments] DROP CONSTRAINT [' + @var106 + '];');
    ALTER TABLE [pep_action_plan_pic_assignments] DROP COLUMN [working_area];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260807081726_DropActionPlanPicColumn'
)
BEGIN
    DECLARE @var107 sysname;
    SELECT @var107 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[phss_action_plan_pic_assignments]') AND [c].[name] = N'working_area');
    IF @var107 IS NOT NULL EXEC(N'ALTER TABLE [phss_action_plan_pic_assignments] DROP CONSTRAINT [' + @var107 + '];');
    ALTER TABLE [phss_action_plan_pic_assignments] DROP COLUMN [working_area];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260807081726_DropActionPlanPicColumn'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260807081726_DropActionPlanPicColumn', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810040737_AddDepartmentIdToAuditLogs'
)
BEGIN
    IF COL_LENGTH('audit_logs', 'department_id') IS NULL ALTER TABLE audit_logs ADD department_id nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810040737_AddDepartmentIdToAuditLogs'
)
BEGIN

                DECLARE @tbl sysname, @sql nvarchar(max);
                DECLARE tbl_cursor CURSOR LOCAL FAST_FORWARD FOR
                    SELECT DISTINCT table_name
                    FROM audit_logs
                    WHERE department_id IS NULL AND table_name IS NOT NULL;
                OPEN tbl_cursor;
                FETCH NEXT FROM tbl_cursor INTO @tbl;
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    IF COL_LENGTH(@tbl, 'id') IS NOT NULL AND COL_LENGTH(@tbl, 'department_id') IS NOT NULL
                    BEGIN
                        SET @sql = N'UPDATE a
                            SET a.department_id = t.department_id
                            FROM audit_logs a
                            INNER JOIN ' + QUOTENAME(@tbl) + N' t ON t.id = a.object_id
                            WHERE a.table_name = @tn
                              AND a.department_id IS NULL
                              AND t.department_id IS NOT NULL';
                        EXEC sp_executesql @sql, N'@tn nvarchar(200)', @tn = @tbl;
                    END
                    FETCH NEXT FROM tbl_cursor INTO @tbl;
                END
                CLOSE tbl_cursor;
                DEALLOCATE tbl_cursor;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810040737_AddDepartmentIdToAuditLogs'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260810040737_AddDepartmentIdToAuditLogs', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810054104_AddTemplateTypeToBoqCategoryTemplateTypes'
)
BEGIN
    ALTER TABLE [boq_category_template_types] ADD [template_type] nvarchar(20) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810054104_AddTemplateTypeToBoqCategoryTemplateTypes'
)
BEGIN
    UPDATE ct
    SET template_type = CASE ft.name
        WHEN 'Template 1' THEN 'Type 1'
        WHEN 'Template 2' THEN 'Type 2'
        WHEN 'Template 3' THEN 'Type 3'
        WHEN 'Template 4' THEN 'Type 4'
      END
    FROM boq_category_template_types ct
    INNER JOIN boq_file_templates ft ON ft.id = ct.boq_file_template_id
    WHERE ct.template_type IS NULL
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810054104_AddTemplateTypeToBoqCategoryTemplateTypes'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260810054104_AddTemplateTypeToBoqCategoryTemplateTypes', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810060000_AddTemplateTypeToBoqs'
)
BEGIN
    ALTER TABLE [boqs] ADD [template_type] nvarchar(20) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810060000_AddTemplateTypeToBoqs'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260810060000_AddTemplateTypeToBoqs', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810075605_AddTenderContractCommoditiesTable'
)
BEGIN
    CREATE TABLE [tender_contract_commodities] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [tender_contract_id] uniqueidentifier NULL,
        [commodity] nvarchar(100) NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_tender_contract_commodities] PRIMARY KEY ([id]),
        CONSTRAINT [FK_tender_contract_commodities_tender_contracts] FOREIGN KEY ([tender_contract_id]) REFERENCES [tender_contracts] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810075605_AddTenderContractCommoditiesTable'
)
BEGIN
    CREATE INDEX [IX_tender_contract_commodities_tender_contract_id] ON [tender_contract_commodities] ([tender_contract_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810075605_AddTenderContractCommoditiesTable'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_tender_contract_commodities_contract_id_commodity] ON [tender_contract_commodities] ([tender_contract_id], [commodity]) WHERE [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810075605_AddTenderContractCommoditiesTable'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260810075605_AddTenderContractCommoditiesTable', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810091159_AddOwnershipToActionPlans'
)
BEGIN
    ALTER TABLE [phss_action_plan] ADD [ownership] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810091159_AddOwnershipToActionPlans'
)
BEGIN
    ALTER TABLE [pep_action_plan] ADD [ownership] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810091159_AddOwnershipToActionPlans'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260810091159_AddOwnershipToActionPlans', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260811035406_AddContractCommoditiesTable'
)
BEGIN
    CREATE TABLE [contract_commodities] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [contract_id] uniqueidentifier NOT NULL,
        [commodity] nvarchar(100) NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_contract_commodities] PRIMARY KEY ([id]),
        CONSTRAINT [FK_contract_commodities_contracts] FOREIGN KEY ([contract_id]) REFERENCES [contracts] ([contract_id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260811035406_AddContractCommoditiesTable'
)
BEGIN
    CREATE INDEX [IX_contract_commodities_contract_id] ON [contract_commodities] ([contract_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260811035406_AddContractCommoditiesTable'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_contract_commodities_contract_id_commodity] ON [contract_commodities] ([contract_id], [commodity]) WHERE [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260811035406_AddContractCommoditiesTable'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260811035406_AddContractCommoditiesTable', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260811050730_AddMultiplePicSupport'
)
BEGIN
    CREATE TABLE [compressor_monitoring_plant_pics] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [compressor_monitoring_plant_id] uniqueidentifier NULL,
        [user_id] uniqueidentifier NULL,
        [created_at] datetime NULL,
        [created_by] uniqueidentifier NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_monitoring_plant_pics] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressor_monitoring_plant_pics_compressor_system_types_compressor_monitoring_plant_id] FOREIGN KEY ([compressor_monitoring_plant_id]) REFERENCES [compressor_system_types] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_compressor_monitoring_plant_pics_users_user_id] FOREIGN KEY ([user_id]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260811050730_AddMultiplePicSupport'
)
BEGIN
    CREATE TABLE [compressor_strategy_periodic_pics] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [compressor_strategy_periodic_id] uniqueidentifier NULL,
        [user_id] uniqueidentifier NULL,
        [created_at] datetime NULL,
        [created_by] uniqueidentifier NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_strategy_periodic_pics] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressor_strategy_periodic_pics_compressor_strategy_periodics_compressor_strategy_periodic_id] FOREIGN KEY ([compressor_strategy_periodic_id]) REFERENCES [compressor_strategy_periodics] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_compressor_strategy_periodic_pics_users_user_id] FOREIGN KEY ([user_id]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260811050730_AddMultiplePicSupport'
)
BEGIN
    CREATE TABLE [compressor_strategy_pics] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [compressor_strategy_id] uniqueidentifier NULL,
        [user_id] uniqueidentifier NULL,
        [created_at] datetime NULL,
        [created_by] uniqueidentifier NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_strategy_pics] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressor_strategy_pics_compressor_strategies_compressor_strategy_id] FOREIGN KEY ([compressor_strategy_id]) REFERENCES [compressor_strategies] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_compressor_strategy_pics_users_user_id] FOREIGN KEY ([user_id]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260811050730_AddMultiplePicSupport'
)
BEGIN
    CREATE INDEX [IX_compressor_monitoring_plant_pics_plant_id] ON [compressor_monitoring_plant_pics] ([compressor_monitoring_plant_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260811050730_AddMultiplePicSupport'
)
BEGIN
    CREATE INDEX [IX_compressor_monitoring_plant_pics_user_id] ON [compressor_monitoring_plant_pics] ([user_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260811050730_AddMultiplePicSupport'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_compressor_monitoring_plant_pics_plant_user] ON [compressor_monitoring_plant_pics] ([compressor_monitoring_plant_id], [user_id]) WHERE [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260811050730_AddMultiplePicSupport'
)
BEGIN
    CREATE INDEX [IX_compressor_strategy_periodic_pics_periodic_id] ON [compressor_strategy_periodic_pics] ([compressor_strategy_periodic_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260811050730_AddMultiplePicSupport'
)
BEGIN
    CREATE INDEX [IX_compressor_strategy_periodic_pics_user_id] ON [compressor_strategy_periodic_pics] ([user_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260811050730_AddMultiplePicSupport'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_compressor_strategy_periodic_pics_periodic_user] ON [compressor_strategy_periodic_pics] ([compressor_strategy_periodic_id], [user_id]) WHERE [compressor_strategy_periodic_id] IS NOT NULL AND [user_id] IS NOT NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260811050730_AddMultiplePicSupport'
)
BEGIN
    CREATE INDEX [IX_compressor_strategy_pics_strategy_id] ON [compressor_strategy_pics] ([compressor_strategy_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260811050730_AddMultiplePicSupport'
)
BEGIN
    CREATE INDEX [IX_compressor_strategy_pics_user_id] ON [compressor_strategy_pics] ([user_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260811050730_AddMultiplePicSupport'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_compressor_strategy_pics_strategy_user] ON [compressor_strategy_pics] ([compressor_strategy_id], [user_id]) WHERE [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260811050730_AddMultiplePicSupport'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260811050730_AddMultiplePicSupport', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812022539_AddRunningHoursRedesignTables'
)
BEGIN
    CREATE TABLE [compressor_running_hours_configs] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [compressor_strategy_id] uniqueidentifier NOT NULL,
        [type] nvarchar(50) NOT NULL,
        [initial_running_hours] decimal(18,2) NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_running_hours_configs] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressor_running_hours_configs_compressor_strategies_compressor_strategy_id] FOREIGN KEY ([compressor_strategy_id]) REFERENCES [compressor_strategies] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812022539_AddRunningHoursRedesignTables'
)
BEGIN
    CREATE TABLE [compressor_running_rate_histories] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [compressor_strategy_id] uniqueidentifier NOT NULL,
        [type] nvarchar(50) NOT NULL,
        [rate] decimal(18,2) NOT NULL,
        [status] nvarchar(50) NULL,
        [effective_at] datetime NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        CONSTRAINT [PK_compressor_running_rate_histories] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressor_running_rate_histories_compressor_strategies_compressor_strategy_id] FOREIGN KEY ([compressor_strategy_id]) REFERENCES [compressor_strategies] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812022539_AddRunningHoursRedesignTables'
)
BEGIN
    CREATE UNIQUE INDEX [UX_compressor_running_hours_configs_strategy_type] ON [compressor_running_hours_configs] ([compressor_strategy_id], [type]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812022539_AddRunningHoursRedesignTables'
)
BEGIN
    CREATE INDEX [IX_compressor_running_rate_histories_strategy_type_effective] ON [compressor_running_rate_histories] ([compressor_strategy_id], [type], [effective_at]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812022539_AddRunningHoursRedesignTables'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260812022539_AddRunningHoursRedesignTables', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812063201_AddProjectTaskSpks'
)
BEGIN
    ALTER TABLE [project_tasks] ADD [spk_type] nvarchar(20) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812063201_AddProjectTaskSpks'
)
BEGIN
    CREATE TABLE [project_task_spks] (
        [id] uniqueidentifier NOT NULL DEFAULT (NEWID()),
        [project_task_id] uniqueidentifier NOT NULL,
        [spk_id] uniqueidentifier NOT NULL,
        [spk_cost] float NULL,
        [is_primary] bit NOT NULL DEFAULT CAST(0 AS bit),
        [unassigned_at] datetime NULL,
        [unassigned_by] uniqueidentifier NULL,
        [unassignment_reason] nvarchar(100) NULL,
        [source] nvarchar(50) NULL,
        [created_at] datetime NULL,
        [created_by] uniqueidentifier NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_project_task_spks] PRIMARY KEY ([id]),
        CONSTRAINT [FK_project_task_spks_project_tasks_project_task_id] FOREIGN KEY ([project_task_id]) REFERENCES [project_tasks] ([id]),
        CONSTRAINT [FK_project_task_spks_spks_spk_id] FOREIGN KEY ([spk_id]) REFERENCES [spks] ([spk_id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812063201_AddProjectTaskSpks'
)
BEGIN
    CREATE INDEX [IX_project_task_spks_spk_id] ON [project_task_spks] ([spk_id], [unassigned_at]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812063201_AddProjectTaskSpks'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_project_task_spks_active] ON [project_task_spks] ([project_task_id], [spk_id]) WHERE [unassigned_at] IS NULL AND [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812063201_AddProjectTaskSpks'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_project_task_spks_primary] ON [project_task_spks] ([project_task_id]) WHERE [is_primary] = 1 AND [unassigned_at] IS NULL AND [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812063201_AddProjectTaskSpks'
)
BEGIN

                INSERT INTO project_task_spks
                    (id, project_task_id, spk_id, spk_cost, is_primary, source, created_at, created_by)
                SELECT NEWID(), pt.id, pt.spk_id, pt.spk_cost, 1, 'column',
                       COALESCE(pt.updated_at, pt.created_at, SYSUTCDATETIME()), pt.updated_by
                FROM   project_tasks pt
                WHERE  pt.spk_id IS NOT NULL
                  AND  pt.deleted_at IS NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812063201_AddProjectTaskSpks'
)
BEGIN

                INSERT INTO project_task_spks
                    (id, project_task_id, spk_id, spk_cost, is_primary, source, created_at)
                SELECT NEWID(), ptb.project_task_id, sb.spk_id,
                       SUM(ptb.total_price), 0, 'spk_boqs', MIN(sb.CreatedAt)
                FROM   spk_boqs sb
                JOIN   project_task_boqs ptb ON ptb.id = sb.project_task_boq_id
                JOIN   project_tasks pt      ON pt.id  = ptb.project_task_id
                WHERE  sb.DeletedAt IS NULL
                  AND  ptb.deleted_at IS NULL
                  AND  pt.deleted_at IS NULL
                  AND  ptb.project_task_id IS NOT NULL
                  AND  NOT EXISTS (
                           SELECT 1 FROM project_task_spks x
                           WHERE  x.project_task_id = ptb.project_task_id
                             AND  x.spk_id          = sb.spk_id)
                GROUP BY ptb.project_task_id, sb.spk_id;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812063201_AddProjectTaskSpks'
)
BEGIN

                UPDATE l
                SET    l.unassigned_at       = COALESCE(s.canceled_at, SYSUTCDATETIME()),
                       l.unassigned_by       = s.canceled_by,
                       l.unassignment_reason = s.status,
                       l.is_primary          = 0
                FROM   project_task_spks l
                JOIN   spks s ON s.spk_id = l.spk_id
                WHERE  s.status = 'canceled'
                  AND  l.unassigned_at IS NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812063201_AddProjectTaskSpks'
)
BEGIN

                UPDATE pt
                SET    pt.spk_type = t.new_type
                FROM   project_tasks pt
                CROSS APPLY (
                    SELECT CASE WHEN a.n = 0 THEN NULL
                                WHEN a.n = 1 THEN 'single'
                                ELSE              'multi' END AS new_type
                    FROM  (SELECT COUNT(*) AS n
                           FROM   project_task_spks l
                           WHERE  l.project_task_id = pt.id
                             AND  l.unassigned_at IS NULL
                             AND  l.deleted_at    IS NULL) a
                ) t
                WHERE ISNULL(pt.spk_type, '~') <> ISNULL(t.new_type, '~');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812063201_AddProjectTaskSpks'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260812063201_AddProjectTaskSpks', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812121248_AddProjectSearchCodeAndFullTextIndex'
)
BEGIN
    EXEC(N'ALTER TABLE [projects] ADD [search_code] AS LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL([project_no], ''''), ''-'', ''''), ''_'', ''''), ''/'', ''''), ''.'', ''''), '' '', '''')) PERSISTED');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812121248_AddProjectSearchCodeAndFullTextIndex'
)
BEGIN
    CREATE INDEX [IX_projects_search_code] ON [projects] ([search_code]);
END;

COMMIT;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812121248_AddProjectSearchCodeAndFullTextIndex'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = 'ft_phantom')
                       CREATE FULLTEXT CATALOG ft_phantom;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812121248_AddProjectSearchCodeAndFullTextIndex'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.projects'))
                       CREATE FULLTEXT INDEX ON dbo.projects (project_no, description)
                       KEY INDEX PK_projects ON ft_phantom WITH CHANGE_TRACKING AUTO;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260812121248_AddProjectSearchCodeAndFullTextIndex'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260812121248_AddProjectSearchCodeAndFullTextIndex', N'9.0.0');
END;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260813163717_AddSpkESignApproval'
)
BEGIN
    DECLARE @var108 sysname;
    SELECT @var108 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[spks]') AND [c].[name] = N'approval_version');
    IF @var108 IS NOT NULL EXEC(N'ALTER TABLE [spks] DROP CONSTRAINT [' + @var108 + '];');
    ALTER TABLE [spks] DROP COLUMN [approval_version];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260813163717_AddSpkESignApproval'
)
BEGIN
    ALTER TABLE [spks] ADD [approval_category] nvarchar(20) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260813163717_AddSpkESignApproval'
)
BEGIN
    CREATE TABLE [user_signatures] (
        [id] uniqueidentifier NOT NULL,
        [user_id] uniqueidentifier NOT NULL,
        [bucket] nvarchar(255) NOT NULL,
        [object_name] nvarchar(500) NOT NULL,
        [content_type] nvarchar(100) NOT NULL,
        [file_size] bigint NULL,
        [source] nvarchar(20) NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_user_signatures] PRIMARY KEY ([id]),
        CONSTRAINT [FK_user_signatures_users_user_id] FOREIGN KEY ([user_id]) REFERENCES [users] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260813163717_AddSpkESignApproval'
)
BEGIN
    CREATE TABLE [spk_approval_esigns] (
        [id] uniqueidentifier NOT NULL,
        [spk_id] uniqueidentifier NOT NULL,
        [approval_route_id] uniqueidentifier NOT NULL,
        [level] int NOT NULL,
        [approval_type] nvarchar(30) NOT NULL,
        [wording] nvarchar(100) NULL,
        [kpi_days] int NULL,
        [user_id] uniqueidentifier NOT NULL,
        [status] nvarchar(20) NOT NULL,
        [received_date] datetime NULL,
        [due_at] datetime NULL,
        [action_date] datetime NULL,
        [user_signature_id] uniqueidentifier NULL,
        [position_snapshot] nvarchar(255) NULL,
        [remarks] nvarchar(500) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_spk_approval_esigns] PRIMARY KEY ([id]),
        CONSTRAINT [FK_spk_approval_esigns_approval_routes_approval_route_id] FOREIGN KEY ([approval_route_id]) REFERENCES [approval_routes] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_spk_approval_esigns_spks_spk_id] FOREIGN KEY ([spk_id]) REFERENCES [spks] ([spk_id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_spk_approval_esigns_user_signatures_user_signature_id] FOREIGN KEY ([user_signature_id]) REFERENCES [user_signatures] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_spk_approval_esigns_users_user_id] FOREIGN KEY ([user_id]) REFERENCES [users] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260813163717_AddSpkESignApproval'
)
BEGIN
    CREATE INDEX [IX_spk_approval_esigns_approval_route_id] ON [spk_approval_esigns] ([approval_route_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260813163717_AddSpkESignApproval'
)
BEGIN
    CREATE INDEX [ix_spk_approval_esigns_spk_level] ON [spk_approval_esigns] ([spk_id], [level]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260813163717_AddSpkESignApproval'
)
BEGIN
    CREATE INDEX [IX_spk_approval_esigns_user_signature_id] ON [spk_approval_esigns] ([user_signature_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260813163717_AddSpkESignApproval'
)
BEGIN
    CREATE INDEX [ix_spk_approval_esigns_user_status] ON [spk_approval_esigns] ([user_id], [status]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260813163717_AddSpkESignApproval'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [ux_spk_approval_esigns_type_user_active] ON [spk_approval_esigns] ([spk_id], [level], [approval_type], [user_id]) WHERE [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260813163717_AddSpkESignApproval'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [ux_user_signatures_user_id_active] ON [user_signatures] ([user_id]) WHERE [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260813163717_AddSpkESignApproval'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260813163717_AddSpkESignApproval', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260814014253_AddServiceAcceptanceStagingTable'
)
BEGIN
    CREATE TABLE [stg_service_acceptances] (
        [id] uniqueidentifier NOT NULL DEFAULT (NEWID()),
        [contract_number] nvarchar(100) NOT NULL,
        [ro_number] nvarchar(100) NOT NULL,
        [sa_number] nvarchar(100) NOT NULL,
        [currency] nvarchar(10) NOT NULL,
        [sa_value] numeric(18,4) NOT NULL,
        [document_date] nvarchar(50) NULL,
        [wbs] nvarchar(100) NOT NULL,
        [line_item] int NOT NULL,
        [status] nvarchar(20) NOT NULL DEFAULT N'pending',
        [remark] nvarchar(500) NULL,
        [retry_count] int NOT NULL DEFAULT 0,
        [last_attempt_at] datetime NULL,
        [service_acceptance_id] uniqueidentifier NULL,
        [processed_at] datetime NULL,
        [created_at] datetime NOT NULL DEFAULT (GETDATE()),
        [updated_at] datetime NULL,
        CONSTRAINT [PK_stg_service_acceptances] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260814014253_AddServiceAcceptanceStagingTable'
)
BEGIN
    CREATE INDEX [IX_stg_service_acceptances_status] ON [stg_service_acceptances] ([status]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260814014253_AddServiceAcceptanceStagingTable'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260814014253_AddServiceAcceptanceStagingTable', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260814101414_AddServiceAcceptanceConflictTable'
)
BEGIN
    CREATE TABLE [stg_service_acceptance_conflicts] (
        [id] uniqueidentifier NOT NULL DEFAULT (NEWID()),
        [stg_service_acceptance_id] uniqueidentifier NOT NULL,
        [service_acceptance_id] uniqueidentifier NOT NULL,
        [contract_number] nvarchar(100) NOT NULL,
        [ro_number] nvarchar(100) NOT NULL,
        [sa_number] nvarchar(100) NOT NULL,
        [wbs] nvarchar(100) NOT NULL,
        [line_item] int NOT NULL,
        [incoming_sa_value] numeric(18,4) NOT NULL,
        [incoming_document_date] nvarchar(50) NULL,
        [existing_sa_value] numeric(18,4) NOT NULL,
        [existing_document_date] date NULL,
        [remark] nvarchar(500) NULL,
        [created_at] datetime NOT NULL DEFAULT (GETDATE()),
        CONSTRAINT [PK_stg_service_acceptance_conflicts] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260814101414_AddServiceAcceptanceConflictTable'
)
BEGIN
    CREATE INDEX [IX_stg_service_acceptance_conflicts_stg_service_acceptance_id] ON [stg_service_acceptance_conflicts] ([stg_service_acceptance_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260814101414_AddServiceAcceptanceConflictTable'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260814101414_AddServiceAcceptanceConflictTable', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260814131410_AddProjectRebaselineApproval'
)
BEGIN
    ALTER TABLE [project_rebaselines] ADD [approved_at] datetime NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260814131410_AddProjectRebaselineApproval'
)
BEGIN
    ALTER TABLE [project_rebaselines] ADD [approved_by] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260814131410_AddProjectRebaselineApproval'
)
BEGIN
    ALTER TABLE [project_rebaselines] ADD [error_message] nvarchar(max) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260814131410_AddProjectRebaselineApproval'
)
BEGIN
    ALTER TABLE [project_rebaselines] ADD [notes] nvarchar(max) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260814131410_AddProjectRebaselineApproval'
)
BEGIN
    ALTER TABLE [project_rebaselines] ADD [rejected_at] datetime NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260814131410_AddProjectRebaselineApproval'
)
BEGIN
    ALTER TABLE [project_rebaselines] ADD [rejected_by] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260814131410_AddProjectRebaselineApproval'
)
BEGIN
    CREATE TABLE [project_rebaseline_approver_defaults] (
        [id] uniqueidentifier NOT NULL,
        [project_id] uniqueidentifier NOT NULL,
        [user_id] uniqueidentifier NOT NULL,
        [level] int NOT NULL,
        CONSTRAINT [PK_project_rebaseline_approver_defaults] PRIMARY KEY ([id]),
        CONSTRAINT [FK_project_rebaseline_approver_defaults_projects_project_id] FOREIGN KEY ([project_id]) REFERENCES [projects] ([id]),
        CONSTRAINT [FK_project_rebaseline_approver_defaults_users_user_id] FOREIGN KEY ([user_id]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260814131410_AddProjectRebaselineApproval'
)
BEGIN
    CREATE TABLE [project_rebaseline_approvers] (
        [id] uniqueidentifier NOT NULL,
        [project_rebaseline_id] uniqueidentifier NOT NULL,
        [user_id] uniqueidentifier NOT NULL,
        [level] int NULL,
        CONSTRAINT [PK_project_rebaseline_approvers] PRIMARY KEY ([id]),
        CONSTRAINT [FK_project_rebaseline_approvers_project_rebaselines_project_rebaseline_id] FOREIGN KEY ([project_rebaseline_id]) REFERENCES [project_rebaselines] ([id]),
        CONSTRAINT [FK_project_rebaseline_approvers_users_user_id] FOREIGN KEY ([user_id]) REFERENCES [users] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260814131410_AddProjectRebaselineApproval'
)
BEGIN
    CREATE INDEX [IX_project_rebaseline_approver_defaults_project_id] ON [project_rebaseline_approver_defaults] ([project_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260814131410_AddProjectRebaselineApproval'
)
BEGIN
    CREATE INDEX [IX_project_rebaseline_approver_defaults_user_id] ON [project_rebaseline_approver_defaults] ([user_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260814131410_AddProjectRebaselineApproval'
)
BEGIN
    CREATE INDEX [IX_project_rebaseline_approvers_project_rebaseline_id] ON [project_rebaseline_approvers] ([project_rebaseline_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260814131410_AddProjectRebaselineApproval'
)
BEGIN
    CREATE INDEX [IX_project_rebaseline_approvers_user_id] ON [project_rebaseline_approvers] ([user_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260814131410_AddProjectRebaselineApproval'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260814131410_AddProjectRebaselineApproval', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817044007_AddTenderTemplateLibraries'
)
BEGIN
    CREATE TABLE [tender_template_libraries] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [name] nvarchar(200) NOT NULL,
        [description] nvarchar(500) NULL,
        [department_id] nvarchar(100) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        [tenant_id] uniqueidentifier NULL,
        CONSTRAINT [PK_tender_template_libraries] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817044007_AddTenderTemplateLibraries'
)
BEGIN
    CREATE TABLE [tender_template_library_categories] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [tender_template_library_id] uniqueidentifier NOT NULL,
        [tender_process_category_id] uniqueidentifier NOT NULL,
        [order] bigint NOT NULL,
        CONSTRAINT [PK_tender_template_library_categories] PRIMARY KEY ([id]),
        CONSTRAINT [FK_tender_template_library_categories_tender_process_categories] FOREIGN KEY ([tender_process_category_id]) REFERENCES [tender_process_categories] ([id]),
        CONSTRAINT [FK_tender_template_library_categories_tender_template_libraries] FOREIGN KEY ([tender_template_library_id]) REFERENCES [tender_template_libraries] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817044007_AddTenderTemplateLibraries'
)
BEGIN
    CREATE TABLE [tender_template_library_processes] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [tender_template_library_category_id] uniqueidentifier NOT NULL,
        [tender_process_id] uniqueidentifier NOT NULL,
        [order] bigint NOT NULL,
        CONSTRAINT [PK_tender_template_library_processes] PRIMARY KEY ([id]),
        CONSTRAINT [FK_tender_template_library_processes_tender_processes] FOREIGN KEY ([tender_process_id]) REFERENCES [tender_processes] ([id]),
        CONSTRAINT [FK_tender_template_library_processes_tender_template_library_categories] FOREIGN KEY ([tender_template_library_category_id]) REFERENCES [tender_template_library_categories] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817044007_AddTenderTemplateLibraries'
)
BEGIN
    CREATE INDEX [IX_tender_template_libraries_department_id] ON [tender_template_libraries] ([department_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817044007_AddTenderTemplateLibraries'
)
BEGIN
    CREATE INDEX [IX_tender_template_library_categories_tender_process_category_id] ON [tender_template_library_categories] ([tender_process_category_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817044007_AddTenderTemplateLibraries'
)
BEGIN
    CREATE INDEX [IX_tender_template_library_categories_tender_template_library_id] ON [tender_template_library_categories] ([tender_template_library_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817044007_AddTenderTemplateLibraries'
)
BEGIN
    CREATE INDEX [IX_tender_template_library_processes_tender_process_id] ON [tender_template_library_processes] ([tender_process_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817044007_AddTenderTemplateLibraries'
)
BEGIN
    CREATE INDEX [IX_tender_template_library_processes_tender_template_library_category_id] ON [tender_template_library_processes] ([tender_template_library_category_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817044007_AddTenderTemplateLibraries'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260817044007_AddTenderTemplateLibraries', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817222024_AddTaskGapReminderTables'
)
BEGIN
    CREATE TABLE [project_task_gap_states] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [project_task_id] uniqueidentifier NOT NULL,
        [gap_type] varchar(20) NOT NULL,
        [first_detected_at] datetime NOT NULL,
        [last_notified_at] datetime NULL,
        CONSTRAINT [PK_project_task_gap_states] PRIMARY KEY ([id]),
        CONSTRAINT [FK_project_task_gap_states_project_tasks_project_task_id] FOREIGN KEY ([project_task_id]) REFERENCES [project_tasks] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817222024_AddTaskGapReminderTables'
)
BEGIN
    CREATE TABLE [project_task_reminder_schedules] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [project_id] uniqueidentifier NOT NULL,
        [frequency] varchar(20) NOT NULL DEFAULT 'weekly',
        [interval_days] int NULL,
        [is_active] bit NOT NULL DEFAULT CAST(1 AS bit),
        [last_sent_at] datetime NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        CONSTRAINT [PK_project_task_reminder_schedules] PRIMARY KEY ([id]),
        CONSTRAINT [FK_project_task_reminder_schedules_projects_project_id] FOREIGN KEY ([project_id]) REFERENCES [projects] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817222024_AddTaskGapReminderTables'
)
BEGIN
    CREATE INDEX [IX_project_task_gap_states_first_detected_at] ON [project_task_gap_states] ([first_detected_at]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817222024_AddTaskGapReminderTables'
)
BEGIN
    CREATE UNIQUE INDEX [UX_project_task_gap_states_task_type] ON [project_task_gap_states] ([project_task_id], [gap_type]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817222024_AddTaskGapReminderTables'
)
BEGIN
    CREATE UNIQUE INDEX [UX_project_task_reminder_schedules_project_id] ON [project_task_reminder_schedules] ([project_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817222024_AddTaskGapReminderTables'
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.custom_configurations WHERE name = 'task_gap_reminder_thresholds')
      INSERT INTO dbo.custom_configurations (id, name, description, detail, created_at, created_by, updated_at, updated_by)
      SELECT NEWID(),
             'task_gap_reminder_thresholds',
             'Project task gap reminders: days a task SPK/BoQ may stay empty, and days before plan start an SPK must be released',
             '{"spkBoqEmptyDays":30,"spkNotReleasedDays":14}',
             GETDATE(), u.id, GETDATE(), u.id
      FROM (SELECT TOP 1 id FROM dbo.users ORDER BY created_at) u;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817222024_AddTaskGapReminderTables'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260817222024_AddTaskGapReminderTables', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817223128_AddSpkDeviationWarnings'
)
BEGIN
    CREATE TABLE [spk_deviation_warnings] (
        [id] uniqueidentifier NOT NULL,
        [spk_id] uniqueidentifier NOT NULL,
        [last_notified_at] datetime NOT NULL,
        [last_deviation] float NOT NULL,
        [created_at] datetime NOT NULL,
        [updated_at] datetime NULL,
        CONSTRAINT [PK_spk_deviation_warnings] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817223128_AddSpkDeviationWarnings'
)
BEGIN
    CREATE UNIQUE INDEX [UX_spk_deviation_warnings_spk_id] ON [spk_deviation_warnings] ([spk_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817223128_AddSpkDeviationWarnings'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260817223128_AddSpkDeviationWarnings', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817230252_AddProjectTaskBoqDrafts'
)
BEGIN
    CREATE TABLE [project_task_boq_drafts] (
        [id] uniqueidentifier NOT NULL,
        [project_task_id] uniqueidentifier NOT NULL,
        [contract_id] uniqueidentifier NOT NULL,
        [payload] nvarchar(max) NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        CONSTRAINT [PK_project_task_boq_drafts] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817230252_AddProjectTaskBoqDrafts'
)
BEGIN
    CREATE UNIQUE INDEX [UX_project_task_boq_drafts_project_task_id] ON [project_task_boq_drafts] ([project_task_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260817230252_AddProjectTaskBoqDrafts'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260817230252_AddProjectTaskBoqDrafts', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260818074547_AddApprovalSlaProjectFlow'
)
BEGIN
    CREATE TABLE [approval_process_levels] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [approval_process_id] uniqueidentifier NOT NULL,
        [level] int NOT NULL,
        [sla_days] int NOT NULL,
        [started_at] datetime NOT NULL,
        [due_at] datetime NOT NULL,
        [closed_at] datetime NULL,
        [outcome] nvarchar(50) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        CONSTRAINT [PK_approval_process_levels] PRIMARY KEY ([id]),
        CONSTRAINT [FK_approval_process_levels_approval_processes_approval_process_id] FOREIGN KEY ([approval_process_id]) REFERENCES [approval_processes] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260818074547_AddApprovalSlaProjectFlow'
)
BEGIN
    CREATE TABLE [approval_route_level_slas] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [approval_route_id] uniqueidentifier NOT NULL,
        [level] int NOT NULL,
        [sla_days] int NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_approval_route_level_slas] PRIMARY KEY ([id]),
        CONSTRAINT [FK_approval_route_level_slas_approval_routes_approval_route_id] FOREIGN KEY ([approval_route_id]) REFERENCES [approval_routes] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260818074547_AddApprovalSlaProjectFlow'
)
BEGIN
    CREATE TABLE [project_approver_slas] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [project_id] uniqueidentifier NOT NULL,
        [level] int NOT NULL,
        [sla_days] int NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        CONSTRAINT [PK_project_approver_slas] PRIMARY KEY ([id]),
        CONSTRAINT [FK_project_approver_slas_projects_project_id] FOREIGN KEY ([project_id]) REFERENCES [projects] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260818074547_AddApprovalSlaProjectFlow'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [IX_approval_process_levels_approval_process_id_level] ON [approval_process_levels] ([approval_process_id], [level]) WHERE [closed_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260818074547_AddApprovalSlaProjectFlow'
)
BEGIN
    CREATE INDEX [IX_approval_process_levels_closed_at] ON [approval_process_levels] ([closed_at]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260818074547_AddApprovalSlaProjectFlow'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [IX_approval_route_level_slas_approval_route_id_level] ON [approval_route_level_slas] ([approval_route_id], [level]) WHERE [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260818074547_AddApprovalSlaProjectFlow'
)
BEGIN
    CREATE UNIQUE INDEX [IX_project_approver_slas_project_id_level] ON [project_approver_slas] ([project_id], [level]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260818074547_AddApprovalSlaProjectFlow'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260818074547_AddApprovalSlaProjectFlow', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819031223_AddVendorAnalysisTables'
)
BEGIN
    CREATE TABLE [contractor_commodities] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [contractor_id] uniqueidentifier NOT NULL,
        [commodity] nvarchar(100) NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_contractor_commodities] PRIMARY KEY ([id]),
        CONSTRAINT [FK_contractor_commodities_contractors] FOREIGN KEY ([contractor_id]) REFERENCES [contractors] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819031223_AddVendorAnalysisTables'
)
BEGIN
    CREATE TABLE [score_parameters] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [name] nvarchar(255) NOT NULL,
        [category] nvarchar(50) NOT NULL,
        [is_mandatory] bit NOT NULL,
        [icon] nvarchar(255) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_score_parameters] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819031223_AddVendorAnalysisTables'
)
BEGIN
    CREATE INDEX [IX_contractor_commodities_contractor_id] ON [contractor_commodities] ([contractor_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819031223_AddVendorAnalysisTables'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_contractor_commodities_contractor_id_commodity] ON [contractor_commodities] ([contractor_id], [commodity]) WHERE [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819031223_AddVendorAnalysisTables'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_score_parameters_name] ON [score_parameters] ([name]) WHERE [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819031223_AddVendorAnalysisTables'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260819031223_AddVendorAnalysisTables', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819032150_AddContractorSpdaNumber'
)
BEGIN
    ALTER TABLE [contractors] ADD [spda_number] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819032150_AddContractorSpdaNumber'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260819032150_AddContractorSpdaNumber', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819034449_AddContractorAssessments'
)
BEGIN
    CREATE TABLE [contractor_assessments] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [contractor_id] uniqueidentifier NOT NULL,
        [assessment_date] datetime NOT NULL,
        [assessor_id] uniqueidentifier NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_contractor_assessments] PRIMARY KEY ([id]),
        CONSTRAINT [FK_contractor_assessments_contractors] FOREIGN KEY ([contractor_id]) REFERENCES [contractors] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819034449_AddContractorAssessments'
)
BEGIN
    CREATE TABLE [contractor_assessment_scores] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [assessment_id] uniqueidentifier NOT NULL,
        [score_parameter_id] uniqueidentifier NOT NULL,
        [score] int NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_contractor_assessment_scores] PRIMARY KEY ([id]),
        CONSTRAINT [FK_contractor_assessment_scores_assessments] FOREIGN KEY ([assessment_id]) REFERENCES [contractor_assessments] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_contractor_assessment_scores_score_parameters] FOREIGN KEY ([score_parameter_id]) REFERENCES [score_parameters] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819034449_AddContractorAssessments'
)
BEGIN
    CREATE INDEX [IX_contractor_assessment_scores_assessment_id] ON [contractor_assessment_scores] ([assessment_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819034449_AddContractorAssessments'
)
BEGIN
    CREATE INDEX [IX_contractor_assessment_scores_score_parameter_id] ON [contractor_assessment_scores] ([score_parameter_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819034449_AddContractorAssessments'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_contractor_assessment_scores_assessment_id_score_parameter_id] ON [contractor_assessment_scores] ([assessment_id], [score_parameter_id]) WHERE [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819034449_AddContractorAssessments'
)
BEGIN
    CREATE INDEX [IX_contractor_assessments_contractor_id] ON [contractor_assessments] ([contractor_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819034449_AddContractorAssessments'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260819034449_AddContractorAssessments', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819063500_AddActionPlanOthers'
)
BEGIN
    CREATE TABLE [pep_action_plan_others] (
        [action_plan_id] uniqueidentifier NOT NULL,
        [json_data] nvarchar(max) NULL,
        CONSTRAINT [PK_pep_action_plan_others] PRIMARY KEY ([action_plan_id]),
        CONSTRAINT [FK_pep_action_plan_others_pep_action_plan_action_plan_id] FOREIGN KEY ([action_plan_id]) REFERENCES [pep_action_plan] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819063500_AddActionPlanOthers'
)
BEGIN
    CREATE TABLE [phss_action_plan_others] (
        [action_plan_id] uniqueidentifier NOT NULL,
        [json_data] nvarchar(max) NULL,
        CONSTRAINT [PK_phss_action_plan_others] PRIMARY KEY ([action_plan_id]),
        CONSTRAINT [FK_phss_action_plan_others_phss_action_plan_action_plan_id] FOREIGN KEY ([action_plan_id]) REFERENCES [phss_action_plan] ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819063500_AddActionPlanOthers'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260819063500_AddActionPlanOthers', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819064248_AddContractorWorkingAreas'
)
BEGIN
    CREATE TABLE [contractor_working_areas] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [contractor_id] uniqueidentifier NOT NULL,
        [working_area] nvarchar(100) NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_contractor_working_areas] PRIMARY KEY ([id]),
        CONSTRAINT [FK_contractor_working_areas_contractors] FOREIGN KEY ([contractor_id]) REFERENCES [contractors] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819064248_AddContractorWorkingAreas'
)
BEGIN
    CREATE INDEX [IX_contractor_working_areas_contractor_id] ON [contractor_working_areas] ([contractor_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819064248_AddContractorWorkingAreas'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_contractor_working_areas_contractor_id_working_area] ON [contractor_working_areas] ([contractor_id], [working_area]) WHERE [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819064248_AddContractorWorkingAreas'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260819064248_AddContractorWorkingAreas', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819074333_AddCompressorLtpEntries'
)
BEGIN
    CREATE TABLE [compressor_ltp_entries] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [compressor_system_id] uniqueidentifier NOT NULL,
        [period] date NOT NULL,
        [existing] decimal(18,2) NOT NULL,
        [gas_lift] decimal(18,2) NOT NULL,
        [development_well] decimal(18,2) NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        [deleted_at] datetime NULL,
        [deleted_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_ltp_entries] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressor_ltp_entries_compressor_system_types_compressor_system_id] FOREIGN KEY ([compressor_system_id]) REFERENCES [compressor_system_types] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_ltp_entries_users_created_by] FOREIGN KEY ([created_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_ltp_entries_users_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_compressor_ltp_entries_users_updated_by] FOREIGN KEY ([updated_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819074333_AddCompressorLtpEntries'
)
BEGIN
    CREATE INDEX [IX_compressor_ltp_entries_created_by] ON [compressor_ltp_entries] ([created_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819074333_AddCompressorLtpEntries'
)
BEGIN
    CREATE INDEX [IX_compressor_ltp_entries_deleted_by] ON [compressor_ltp_entries] ([deleted_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819074333_AddCompressorLtpEntries'
)
BEGIN
    CREATE INDEX [IX_compressor_ltp_entries_updated_by] ON [compressor_ltp_entries] ([updated_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819074333_AddCompressorLtpEntries'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_compressor_ltp_entries_system_period] ON [compressor_ltp_entries] ([compressor_system_id], [period]) WHERE [deleted_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260819074333_AddCompressorLtpEntries'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260819074333_AddCompressorLtpEntries', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260820000000_AddPositionNameToUsers'
)
BEGIN
    IF COL_LENGTH('users', 'position_name') IS NULL ALTER TABLE users ADD position_name nvarchar(255) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260820000000_AddPositionNameToUsers'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260820000000_AddPositionNameToUsers', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260820013247_WidenAuditTrailAction'
)
BEGIN
    DECLARE @var109 sysname;
    SELECT @var109 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[audit_trails]') AND [c].[name] = N'action');
    IF @var109 IS NOT NULL EXEC(N'ALTER TABLE [audit_trails] DROP CONSTRAINT [' + @var109 + '];');
    ALTER TABLE [audit_trails] ALTER COLUMN [action] nvarchar(255) NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260820013247_WidenAuditTrailAction'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260820013247_WidenAuditTrailAction', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260820015058_AddScoreParameterDescription'
)
BEGIN
    ALTER TABLE [score_parameters] ADD [description] nvarchar(1000) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260820015058_AddScoreParameterDescription'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260820015058_AddScoreParameterDescription', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260820122252_AddContractApproverSlas'
)
BEGIN
    CREATE TABLE [contract_approver_slas] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [contract_id] uniqueidentifier NOT NULL,
        [level] int NOT NULL,
        [sla_days] int NOT NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        CONSTRAINT [PK_contract_approver_slas] PRIMARY KEY ([id]),
        CONSTRAINT [FK_contract_approver_slas_contracts_contract_id] FOREIGN KEY ([contract_id]) REFERENCES [contracts] ([contract_id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260820122252_AddContractApproverSlas'
)
BEGIN
    CREATE UNIQUE INDEX [IX_contract_approver_slas_contract_id_level] ON [contract_approver_slas] ([contract_id], [level]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260820122252_AddContractApproverSlas'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260820122252_AddContractApproverSlas', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260821071513_AddContractStagingTables'
)
BEGIN
    CREATE TABLE [stg_contract_pep] (
        [id] uniqueidentifier NOT NULL DEFAULT (NEWID()),
        [purchasing_group] nvarchar(255) NULL,
        [sap_status] nvarchar(255) NULL,
        [document_type] nvarchar(255) NULL,
        [contract_number] nvarchar(255) NULL,
        [vendor] nvarchar(255) NULL,
        [vendor_name] nvarchar(500) NULL,
        [short_text] nvarchar(500) NULL,
        [target_value] nvarchar(255) NULL,
        [total_po_so] nvarchar(255) NULL,
        [total_se_gr] nvarchar(255) NULL,
        [total_released_se_gr] nvarchar(255) NULL,
        [total_invoice] nvarchar(255) NULL,
        [remaining_value_po] nvarchar(255) NULL,
        [remaining_value_gr] nvarchar(255) NULL,
        [currency] nvarchar(255) NULL,
        [spending_percentage] nvarchar(255) NULL,
        [effective_date] nvarchar(255) NULL,
        [validity_start] nvarchar(255) NULL,
        [validity_end] nvarchar(255) NULL,
        [remaining_period_day] nvarchar(255) NULL,
        [tender_number] nvarchar(255) NULL,
        [number_of_se] nvarchar(255) NULL,
        [sap_created_by] nvarchar(255) NULL,
        [company_code] nvarchar(255) NULL,
        [purchasing_organization] nvarchar(255) NULL,
        [pgr_end_user] nvarchar(255) NULL,
        [contract_actual_release] nvarchar(255) NULL,
        [procurement_method] nvarchar(255) NULL,
        [description] nvarchar(500) NULL,
        [status] nvarchar(20) NOT NULL DEFAULT N'pending',
        [remark] nvarchar(500) NULL,
        [retry_count] int NOT NULL DEFAULT 0,
        [last_attempt_at] datetime NULL,
        [contract_id] uniqueidentifier NULL,
        [processed_at] datetime NULL,
        [created_at] datetime NOT NULL DEFAULT (GETDATE()),
        [updated_at] datetime NULL,
        CONSTRAINT [PK_stg_contract_pep] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260821071513_AddContractStagingTables'
)
BEGIN
    CREATE TABLE [stg_contract_phss] (
        [id] uniqueidentifier NOT NULL DEFAULT (NEWID()),
        [company_code] nvarchar(255) NULL,
        [purchasing_organization] nvarchar(255) NULL,
        [pgr_end_user] nvarchar(255) NULL,
        [tender_number] nvarchar(255) NULL,
        [purchasing_group] nvarchar(255) NULL,
        [document_type] nvarchar(255) NULL,
        [sap_created_by] nvarchar(255) NULL,
        [contract_number] nvarchar(255) NULL,
        [vendor] nvarchar(255) NULL,
        [vendor_name] nvarchar(500) NULL,
        [short_text] nvarchar(500) NULL,
        [procurement_method] nvarchar(255) NULL,
        [effective_date] nvarchar(255) NULL,
        [description] nvarchar(500) NULL,
        [validity_start] nvarchar(255) NULL,
        [validity_end] nvarchar(255) NULL,
        [currency] nvarchar(255) NULL,
        [target_value] nvarchar(255) NULL,
        [total_po_so] nvarchar(255) NULL,
        [total_se_gr] nvarchar(255) NULL,
        [total_released_se_gr] nvarchar(255) NULL,
        [total_invoice] nvarchar(255) NULL,
        [remaining_value_po] nvarchar(255) NULL,
        [remaining_value_gr] nvarchar(255) NULL,
        [spending_percentage] nvarchar(255) NULL,
        [number_of_se] nvarchar(255) NULL,
        [sap_status] nvarchar(255) NULL,
        [remaining_period_day] nvarchar(255) NULL,
        [status] nvarchar(20) NOT NULL DEFAULT N'pending',
        [remark] nvarchar(500) NULL,
        [retry_count] int NOT NULL DEFAULT 0,
        [last_attempt_at] datetime NULL,
        [contract_id] uniqueidentifier NULL,
        [processed_at] datetime NULL,
        [created_at] datetime NOT NULL DEFAULT (GETDATE()),
        [updated_at] datetime NULL,
        CONSTRAINT [PK_stg_contract_phss] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260821071513_AddContractStagingTables'
)
BEGIN
    CREATE INDEX [IX_stg_contract_pep_status] ON [stg_contract_pep] ([status]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260821071513_AddContractStagingTables'
)
BEGIN
    CREATE INDEX [IX_stg_contract_phss_status] ON [stg_contract_phss] ([status]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260821071513_AddContractStagingTables'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260821071513_AddContractStagingTables', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260824044324_AddCompressorAlertNotificationTables'
)
BEGIN
    CREATE TABLE [compressor_alert_notification_settings] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [user_id] uniqueidentifier NOT NULL,
        [frequency] nvarchar(20) NOT NULL,
        [weekly_day] nvarchar(10) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        CONSTRAINT [PK_compressor_alert_notification_settings] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressor_alert_notification_settings_users_user_id] FOREIGN KEY ([user_id]) REFERENCES [users] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260824044324_AddCompressorAlertNotificationTables'
)
BEGIN
    CREATE TABLE [compressor_alert_states] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [compressor_strategy_id] uniqueidentifier NOT NULL,
        [alert_type] nvarchar(20) NOT NULL,
        [is_active] bit NOT NULL,
        [last_notified_at] datetime NULL,
        [updated_at] datetime NOT NULL,
        CONSTRAINT [PK_compressor_alert_states] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressor_alert_states_compressor_strategies_compressor_strategy_id] FOREIGN KEY ([compressor_strategy_id]) REFERENCES [compressor_strategies] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260824044324_AddCompressorAlertNotificationTables'
)
BEGIN
    CREATE UNIQUE INDEX [UX_compressor_alert_notification_settings_user_id] ON [compressor_alert_notification_settings] ([user_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260824044324_AddCompressorAlertNotificationTables'
)
BEGIN
    CREATE UNIQUE INDEX [UX_compressor_alert_states_strategy_alert_type] ON [compressor_alert_states] ([compressor_strategy_id], [alert_type]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260824044324_AddCompressorAlertNotificationTables'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260824044324_AddCompressorAlertNotificationTables', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260826025918_ConvertActionPlanChokeSettingToNumeric'
)
BEGIN
    ALTER TABLE [phss_action_plan_choke] ADD [choke_setting_new] decimal(18,2) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260826025918_ConvertActionPlanChokeSettingToNumeric'
)
BEGIN
    ALTER TABLE [pep_action_plan_choke] ADD [choke_setting_new] decimal(18,2) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260826025918_ConvertActionPlanChokeSettingToNumeric'
)
BEGIN
    UPDATE phss_action_plan_choke SET choke_setting_new = CASE choke_setting
        WHEN 'choke_16_64' THEN 16 WHEN 'choke_24_64' THEN 24 WHEN 'choke_32_64' THEN 32
        ELSE NULL END;
    UPDATE pep_action_plan_choke SET choke_setting_new = CASE choke_setting
        WHEN 'choke_16_64' THEN 16 WHEN 'choke_24_64' THEN 24 WHEN 'choke_32_64' THEN 32
        ELSE NULL END;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260826025918_ConvertActionPlanChokeSettingToNumeric'
)
BEGIN
    DECLARE @var110 sysname;
    SELECT @var110 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[phss_action_plan_choke]') AND [c].[name] = N'choke_setting');
    IF @var110 IS NOT NULL EXEC(N'ALTER TABLE [phss_action_plan_choke] DROP CONSTRAINT [' + @var110 + '];');
    ALTER TABLE [phss_action_plan_choke] DROP COLUMN [choke_setting];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260826025918_ConvertActionPlanChokeSettingToNumeric'
)
BEGIN
    DECLARE @var111 sysname;
    SELECT @var111 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[pep_action_plan_choke]') AND [c].[name] = N'choke_setting');
    IF @var111 IS NOT NULL EXEC(N'ALTER TABLE [pep_action_plan_choke] DROP CONSTRAINT [' + @var111 + '];');
    ALTER TABLE [pep_action_plan_choke] DROP COLUMN [choke_setting];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260826025918_ConvertActionPlanChokeSettingToNumeric'
)
BEGIN
    EXEC sp_rename N'[phss_action_plan_choke].[choke_setting_new]', N'choke_setting', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260826025918_ConvertActionPlanChokeSettingToNumeric'
)
BEGIN
    EXEC sp_rename N'[pep_action_plan_choke].[choke_setting_new]', N'choke_setting', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260826025918_ConvertActionPlanChokeSettingToNumeric'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260826025918_ConvertActionPlanChokeSettingToNumeric', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260826084615_AddRkapTypeToProjects'
)
BEGIN
    ALTER TABLE [projects] ADD [rkap_type] nvarchar(10) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260826084615_AddRkapTypeToProjects'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260826084615_AddRkapTypeToProjects', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260826150539_AddSpkModificationLogs'
)
BEGIN
    CREATE TABLE [spk_modification_logs] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [spk_id] uniqueidentifier NOT NULL,
        [approval_process_id] uniqueidentifier NOT NULL,
        [change_group_id] uniqueidentifier NOT NULL,
        [approval_level] int NOT NULL,
        [category] nvarchar(10) NULL,
        [change_type] nvarchar(10) NULL,
        [field_name] nvarchar(50) NULL,
        [reference_id] uniqueidentifier NULL,
        [reference_label] nvarchar(255) NULL,
        [old_value] nvarchar(1000) NULL,
        [new_value] nvarchar(1000) NULL,
        [created_at] datetime2 NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        CONSTRAINT [PK_spk_modification_logs] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260826150539_AddSpkModificationLogs'
)
BEGIN
    CREATE INDEX [IX_spk_modification_logs_approval_process_id] ON [spk_modification_logs] ([approval_process_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260826150539_AddSpkModificationLogs'
)
BEGIN
    CREATE INDEX [IX_spk_modification_logs_spk_id_created_at] ON [spk_modification_logs] ([spk_id], [created_at]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260826150539_AddSpkModificationLogs'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260826150539_AddSpkModificationLogs', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260827044129_AddCostCenterAndNullableWbsToStgServiceAcceptance'
)
BEGIN
    IF COL_LENGTH('dbo.stg_service_acceptances', 'cost_center') IS NULL ALTER TABLE dbo.stg_service_acceptances ADD cost_center nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260827044129_AddCostCenterAndNullableWbsToStgServiceAcceptance'
)
BEGIN
    ALTER TABLE dbo.stg_service_acceptances ALTER COLUMN wbs nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260827044129_AddCostCenterAndNullableWbsToStgServiceAcceptance'
)
BEGIN
    IF COL_LENGTH('dbo.stg_service_acceptance_conflicts', 'cost_center') IS NULL ALTER TABLE dbo.stg_service_acceptance_conflicts ADD cost_center nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260827044129_AddCostCenterAndNullableWbsToStgServiceAcceptance'
)
BEGIN
    ALTER TABLE dbo.stg_service_acceptance_conflicts ALTER COLUMN wbs nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260827044129_AddCostCenterAndNullableWbsToStgServiceAcceptance'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260827044129_AddCostCenterAndNullableWbsToStgServiceAcceptance', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260827093121_FixPicAssignment'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260827093121_FixPicAssignment', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260827102546_FixWellHistoryNav'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260827102546_FixWellHistoryNav', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260827132904_AddContractorAssessmentContractId'
)
BEGIN
    ALTER TABLE [contractor_assessments] ADD [contract_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260827132904_AddContractorAssessmentContractId'
)
BEGIN
    CREATE INDEX [IX_contractor_assessments_contract_id] ON [contractor_assessments] ([contract_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260827132904_AddContractorAssessmentContractId'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260827132904_AddContractorAssessmentContractId', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828081258_AddAlertNotificationSettings'
)
BEGIN
    CREATE TABLE [alert_notification_settings] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [user_id] uniqueidentifier NOT NULL,
        [frequency] nvarchar(20) NOT NULL,
        [weekly_day] nvarchar(10) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        CONSTRAINT [PK_alert_notification_settings] PRIMARY KEY ([id]),
        CONSTRAINT [FK_alert_notification_settings_users_user_id] FOREIGN KEY ([user_id]) REFERENCES [users] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828081258_AddAlertNotificationSettings'
)
BEGIN
    CREATE UNIQUE INDEX [UX_alert_notification_settings_user_id] ON [alert_notification_settings] ([user_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828081258_AddAlertNotificationSettings'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260828081258_AddAlertNotificationSettings', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828081549_AddContractShares'
)
BEGIN
    CREATE TABLE [contract_shares] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [contract_id] uniqueidentifier NOT NULL,
        [owner_department_id] nvarchar(100) NOT NULL,
        [shared_department_id] nvarchar(100) NOT NULL,
        [requested_by] uniqueidentifier NULL,
        [requested_at] datetime NULL,
        [granted_by] uniqueidentifier NOT NULL,
        [granted_at] datetime NOT NULL,
        [expires_at] datetime NULL,
        [revoked_at] datetime NULL,
        [revoked_by] uniqueidentifier NULL,
        [revoke_note] nvarchar(500) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        CONSTRAINT [PK_contract_shares] PRIMARY KEY ([id]),
        CONSTRAINT [FK_contract_shares_contracts_contract_id] FOREIGN KEY ([contract_id]) REFERENCES [contracts] ([contract_id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828081549_AddContractShares'
)
BEGIN
    CREATE INDEX [IX_contract_shares_contract_id] ON [contract_shares] ([contract_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828081549_AddContractShares'
)
BEGIN
    CREATE INDEX [IX_contract_shares_shared_department_revoked] ON [contract_shares] ([shared_department_id], [revoked_at]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828081549_AddContractShares'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UX_contract_shares_contract_shared_department_active] ON [contract_shares] ([contract_id], [shared_department_id]) WHERE [revoked_at] IS NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828081549_AddContractShares'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260828081549_AddContractShares', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828083057_UpdateAlertNotificationSetting'
)
BEGIN
    ALTER TABLE [alert_notification_settings] ADD [Type] nvarchar(max) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828083057_UpdateAlertNotificationSetting'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260828083057_UpdateAlertNotificationSetting', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828092639_AddContractShareRequestsAndValueCap'
)
BEGIN
    ALTER TABLE [contract_shares] ADD [request_id] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828092639_AddContractShareRequestsAndValueCap'
)
BEGIN
    ALTER TABLE [contract_shares] ADD [value_cap] decimal(18,4) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828092639_AddContractShareRequestsAndValueCap'
)
BEGIN
    CREATE TABLE [contract_share_requests] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [requester_department_id] nvarchar(100) NOT NULL,
        [target_department_id] nvarchar(100) NOT NULL,
        [description] nvarchar(200) NOT NULL,
        [justification] nvarchar(1000) NOT NULL,
        [status] nvarchar(20) NOT NULL,
        [requested_by] uniqueidentifier NOT NULL,
        [requested_at] datetime NOT NULL,
        [responded_by] uniqueidentifier NULL,
        [responded_at] datetime NULL,
        [reject_reason] nvarchar(500) NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        CONSTRAINT [PK_contract_share_requests] PRIMARY KEY ([id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828092639_AddContractShareRequestsAndValueCap'
)
BEGIN
    CREATE INDEX [IX_contract_share_requests_target_status] ON [contract_share_requests] ([target_department_id], [status]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828092639_AddContractShareRequestsAndValueCap'
)
BEGIN
    CREATE INDEX [IX_contract_share_requests_requester_status] ON [contract_share_requests] ([requester_department_id], [status]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828092639_AddContractShareRequestsAndValueCap'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260828092639_AddContractShareRequestsAndValueCap', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828092726_AddIndexTypeAlertNotificationSetting'
)
BEGIN
    DROP INDEX [UX_alert_notification_settings_user_id] ON [alert_notification_settings];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828092726_AddIndexTypeAlertNotificationSetting'
)
BEGIN
    DECLARE @var112 sysname;
    SELECT @var112 = [d].[name]
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[alert_notification_settings]') AND [c].[name] = N'type');
    IF @var112 IS NOT NULL EXEC(N'ALTER TABLE [alert_notification_settings] DROP CONSTRAINT [' + @var112 + '];');
    EXEC(N'UPDATE [alert_notification_settings] SET [type] = N'''' WHERE [type] IS NULL');
    ALTER TABLE [alert_notification_settings] ALTER COLUMN [type] nvarchar(20) NOT NULL;
    ALTER TABLE [alert_notification_settings] ADD DEFAULT N'' FOR [type];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828092726_AddIndexTypeAlertNotificationSetting'
)
BEGIN
    CREATE UNIQUE INDEX [UX_alert_notification_settings_user_id_type] ON [alert_notification_settings] ([user_id], [type]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260828092726_AddIndexTypeAlertNotificationSetting'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260828092726_AddIndexTypeAlertNotificationSetting', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260831000000_AddContractShareRequestSequenceNumber'
)
BEGIN
    ALTER TABLE [contract_share_requests] ADD [sequence_number] int NOT NULL DEFAULT 0;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260831000000_AddContractShareRequestSequenceNumber'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260831000000_AddContractShareRequestSequenceNumber', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260831142301_AddEurGasOilToWellZoneAssignment'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [eur_gas] decimal(18,4) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260831142301_AddEurGasOilToWellZoneAssignment'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [eur_oil] decimal(18,4) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260831142301_AddEurGasOilToWellZoneAssignment'
)
BEGIN

    UPDATE well_zone_assignments
    SET eur_gas = CASE WHEN LOWER(type) = 'gas' THEN eur END,
        eur_oil = CASE WHEN LOWER(type) = 'oil' THEN eur END
    WHERE eur IS NOT NULL AND LOWER(type) IN ('gas', 'oil');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260831142301_AddEurGasOilToWellZoneAssignment'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260831142301_AddEurGasOilToWellZoneAssignment', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901045429_AddCompressorHighlightSnapshotAndAlertChannel'
)
BEGIN
    DROP INDEX [UX_compressor_alert_notification_settings_user_id] ON [compressor_alert_notification_settings];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901045429_AddCompressorHighlightSnapshotAndAlertChannel'
)
BEGIN
    ALTER TABLE [compressor_alert_notification_settings] ADD [channel] nvarchar(20) NOT NULL DEFAULT N'';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901045429_AddCompressorHighlightSnapshotAndAlertChannel'
)
BEGIN
    UPDATE compressor_alert_notification_settings SET channel = 'email' WHERE channel = '';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901045429_AddCompressorHighlightSnapshotAndAlertChannel'
)
BEGIN
    CREATE TABLE [compressor_highlight_snapshots] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [snapshot_date] date NOT NULL,
        [compressor_strategy_id] uniqueidentifier NOT NULL,
        [alert_type] nvarchar(20) NOT NULL,
        [compressor_name] nvarchar(255) NOT NULL,
        [working_area] nvarchar(20) NOT NULL,
        [percentage] decimal(5,2) NULL,
        [schedule] nvarchar(20) NULL,
        [created_at] datetime NOT NULL,
        CONSTRAINT [PK_compressor_highlight_snapshots] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressor_highlight_snapshots_compressor_strategies_compressor_strategy_id] FOREIGN KEY ([compressor_strategy_id]) REFERENCES [compressor_strategies] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901045429_AddCompressorHighlightSnapshotAndAlertChannel'
)
BEGIN
    CREATE UNIQUE INDEX [UX_compressor_alert_notification_settings_user_id_channel] ON [compressor_alert_notification_settings] ([user_id], [channel]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901045429_AddCompressorHighlightSnapshotAndAlertChannel'
)
BEGIN
    CREATE INDEX [IX_compressor_highlight_snapshots_compressor_strategy_id] ON [compressor_highlight_snapshots] ([compressor_strategy_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901045429_AddCompressorHighlightSnapshotAndAlertChannel'
)
BEGIN
    CREATE UNIQUE INDEX [UX_compressor_highlight_snapshots_date_strategy_alert_type] ON [compressor_highlight_snapshots] ([snapshot_date], [compressor_strategy_id], [alert_type]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901045429_AddCompressorHighlightSnapshotAndAlertChannel'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260901045429_AddCompressorHighlightSnapshotAndAlertChannel', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901050503_AddSpkApprovalRevisions'
)
BEGIN
    CREATE TABLE [spk_approval_revisions] (
        [id] uniqueidentifier NOT NULL,
        [spk_id] uniqueidentifier NOT NULL,
        [cycle_number] int NOT NULL,
        [revise_type] nvarchar(30) NOT NULL,
        [requested_by] uniqueidentifier NOT NULL,
        [requested_at_level] int NOT NULL,
        [returned_to_level] int NULL,
        [remarks] nvarchar(max) NOT NULL,
        [tasks_snapshot] nvarchar(max) NULL,
        [resubmitted_at] datetime NULL,
        [resubmitted_by] uniqueidentifier NULL,
        [created_at] datetime NOT NULL,
        [created_by] uniqueidentifier NOT NULL,
        [updated_at] datetime NULL,
        [updated_by] uniqueidentifier NULL,
        CONSTRAINT [PK_spk_approval_revisions] PRIMARY KEY ([id]),
        CONSTRAINT [FK_spk_approval_revisions_spks_spk_id] FOREIGN KEY ([spk_id]) REFERENCES [spks] ([spk_id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_spk_approval_revisions_users_requested_by] FOREIGN KEY ([requested_by]) REFERENCES [users] ([id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901050503_AddSpkApprovalRevisions'
)
BEGIN
    CREATE INDEX [IX_spk_approval_revisions_requested_by] ON [spk_approval_revisions] ([requested_by]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901050503_AddSpkApprovalRevisions'
)
BEGIN
    CREATE UNIQUE INDEX [ux_spk_approval_revisions_spk_cycle] ON [spk_approval_revisions] ([spk_id], [cycle_number]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901050503_AddSpkApprovalRevisions'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260901050503_AddSpkApprovalRevisions', N'9.0.0');
END;

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
    WHERE [MigrationId] = N'20260901072710_AddAlertStates'
)
BEGIN
    CREATE TABLE [alert_states] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [well_id] uniqueidentifier NOT NULL,
        [type] nvarchar(20) NOT NULL,
        [alert_type] nvarchar(50) NOT NULL,
        [is_active] bit NOT NULL,
        [last_notified_at] datetime NOT NULL,
        [updated_at] datetime NOT NULL,
        CONSTRAINT [PK_alert_states] PRIMARY KEY ([id]),
        CONSTRAINT [FK_alert_states_wells_well_id] FOREIGN KEY ([well_id]) REFERENCES [wells] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901072710_AddAlertStates'
)
BEGIN
    CREATE INDEX [IX_alert_states_well_id] ON [alert_states] ([well_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901072710_AddAlertStates'
)
BEGIN
    CREATE UNIQUE INDEX [UX_alert_states_type_well_id_alert_type] ON [alert_states] ([type], [well_id], [alert_type]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901072710_AddAlertStates'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260901072710_AddAlertStates', N'9.0.0');
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
    WHERE [MigrationId] = N'20260901101913_AddCategoryAlertNotificationSettings'
)
BEGIN
    DROP INDEX [UX_alert_notification_settings_user_id_type] ON [alert_notification_settings];
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901101913_AddCategoryAlertNotificationSettings'
)
BEGIN
    ALTER TABLE [alert_notification_settings] ADD [category] nvarchar(20) NOT NULL DEFAULT N'';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901101913_AddCategoryAlertNotificationSettings'
)
BEGIN
    CREATE UNIQUE INDEX [UX_alert_notification_settings_user_id_type_category] ON [alert_notification_settings] ([user_id], [type], [category]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901101913_AddCategoryAlertNotificationSettings'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260901101913_AddCategoryAlertNotificationSettings', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901153628_AddCompressorAlertEvents'
)
BEGIN
    CREATE TABLE [compressor_alert_events] (
        [id] uniqueidentifier NOT NULL DEFAULT ((newid())),
        [compressor_strategy_id] uniqueidentifier NOT NULL,
        [alert_type] nvarchar(20) NOT NULL,
        [event_date] date NOT NULL,
        [created_at] datetime NOT NULL,
        CONSTRAINT [PK_compressor_alert_events] PRIMARY KEY ([id]),
        CONSTRAINT [FK_compressor_alert_events_compressor_strategies_compressor_strategy_id] FOREIGN KEY ([compressor_strategy_id]) REFERENCES [compressor_strategies] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901153628_AddCompressorAlertEvents'
)
BEGIN
    CREATE INDEX [IX_compressor_alert_events_event_date] ON [compressor_alert_events] ([event_date]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901153628_AddCompressorAlertEvents'
)
BEGIN
    CREATE UNIQUE INDEX [UX_compressor_alert_events_strategy_alert_type_date] ON [compressor_alert_events] ([compressor_strategy_id], [alert_type], [event_date]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260901153628_AddCompressorAlertEvents'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260901153628_AddCompressorAlertEvents', N'9.0.0');
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
    WHERE [MigrationId] = N'20260903000000_AddContractShareRequestSequenceNumberUniqueIndex'
)
BEGIN
    CREATE UNIQUE INDEX [UX_contract_share_requests_sequence_number] ON [contract_share_requests] ([sequence_number]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260903000000_AddContractShareRequestSequenceNumberUniqueIndex'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260903000000_AddContractShareRequestSequenceNumberUniqueIndex', N'9.0.0');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260903072556_AddSyncedAtToWellZoneAssignment'
)
BEGIN
    ALTER TABLE [well_zone_assignments] ADD [synced_at] datetime2 NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260903072556_AddSyncedAtToWellZoneAssignment'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260903072556_AddSyncedAtToWellZoneAssignment', N'9.0.0');
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

