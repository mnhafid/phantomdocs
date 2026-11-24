/*  Fix: duplicate alert_states rows and the missing unique index (Luvus t83)

    WHY
    AlertCheckJob builds a map keyed on (well_id, alert_type) and died every 08:00 run on
    production with "An item with the same key has already been added. Key: (…, well_life)".
    Migration 20260901072710_AddAlertStates creates UX_alert_states_type_well_id_alert_type, but
    production does not have it (dev does), so duplicates accumulated. The code now tolerates
    duplicates (AlertService.DedupeStates); this script removes them and adds the index so they
    cannot return.

    RULE: per (type, well_id, alert_type) keep the active row, else the most recently updated.
    Run step 1 alone first to see what step 2 will delete.
*/
-- 1. preview the rows that step 2 deletes
;WITH ranked AS (
    SELECT id, type, well_id, alert_type, is_active, updated_at,
           ROW_NUMBER() OVER (PARTITION BY type, well_id, alert_type
                              ORDER BY is_active DESC, updated_at DESC, id) rn
    FROM dbo.alert_states)
SELECT * FROM ranked WHERE rn > 1;

-- 2. delete the losers
;WITH ranked AS (
    SELECT id, ROW_NUMBER() OVER (PARTITION BY type, well_id, alert_type
                                  ORDER BY is_active DESC, updated_at DESC, id) rn
    FROM dbo.alert_states)
DELETE FROM dbo.alert_states WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

-- 3. the unique index from the migration, if missing
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.alert_states') AND name = 'UX_alert_states_type_well_id_alert_type')
    CREATE UNIQUE NONCLUSTERED INDEX UX_alert_states_type_well_id_alert_type
        ON dbo.alert_states (type, well_id, alert_type);

-- verify: expect 0 rows
SELECT type, well_id, alert_type, COUNT(*) n FROM dbo.alert_states GROUP BY type, well_id, alert_type HAVING COUNT(*) > 1;
