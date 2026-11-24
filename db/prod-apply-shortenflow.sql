/*  ShortenFlow / Multi Source SPK - the ONLY schema change the feature needs on PRODUCTION.

    Migration : 20260908013741_AddSpkIdToProjectTaskBoqDrafts   (PR #1139)
    Change    : project_task_boq_drafts.spk_id, plus a backfill out of the payload JSON.

    Promotes the draft's chosen SPK out of the payload JSON into its own column so it can be
    queried. Nullable and with no foreign key on purpose: a draft is a half-filled form that must
    be able to hold "no SPK picked yet".

    The backfill copies the value across for drafts written before the column existed. Without it
    the column reads NULL for every existing draft, so anything querying BY spk_id silently misses
    rows that do name an SPK. ISJSON guards a payload that is not an object; TRY_CAST guards a
    malformed guid.

    Guarded by __EFMigrationsHistory - safe to run twice, and safe if production already has it.

    NOT part of this: PRs #1161, #1163 and #1164 contain no migrations at all. Everything else in
    ShortenFlow (per-contract v2 grouping, the submit fallback, /eligible-spk, the contract_id
    filter, the spks array, progress on the grouped tree) is code-only and needs no SQL.
*/

BEGIN TRANSACTION;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260908013741_AddSpkIdToProjectTaskBoqDrafts'
)
BEGIN
    ALTER TABLE [project_task_boq_drafts] ADD [spk_id] uniqueidentifier NULL;
END;

GO

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

GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260908013741_AddSpkIdToProjectTaskBoqDrafts'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260908013741_AddSpkIdToProjectTaskBoqDrafts', N'9.0.0');
END;
GO

-- Verify, then:  COMMIT TRANSACTION;   (or ROLLBACK TRANSACTION;)
