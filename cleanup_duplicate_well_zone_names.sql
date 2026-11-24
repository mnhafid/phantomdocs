-- Soft-deletes duplicate well_zones rows so a unique index on (name) can exist.
-- Keeper per name: the row with the most live children, oldest first as tie-break.
-- Soft delete, so it reverses by clearing deleted_at — no backup table needed.
-- Idempotent: once no name has more than one live row, it updates nothing.
SET QUOTED_IDENTIFIER ON;

WITH dup AS (
    SELECT name
    FROM   dbo.well_zones
    WHERE  deleted_at IS NULL
    GROUP  BY name
    HAVING COUNT(*) > 1
),
scored AS (
    SELECT z.id, z.name, z.created_at,
           (SELECT COUNT(*) FROM dbo.well_zone_assignments a WHERE a.well_zone_id = z.id AND a.deleted_at IS NULL)
         + (SELECT COUNT(*) FROM dbo.well_history_phss     h WHERE h.well_zone_id = z.id AND h.deleted_at IS NULL)
         + (SELECT COUNT(*) FROM dbo.well_history_pep      p WHERE p.well_zone_id = z.id AND p.deleted_at IS NULL) AS live_children
    FROM   dbo.well_zones z
    JOIN   dup d ON d.name = z.name
    WHERE  z.deleted_at IS NULL
),
ranked AS (
    -- id last so the order is total: two rows with the same score and timestamp still rank apart,
    -- which is what makes a re-run pick the same keeper.
    SELECT id, ROW_NUMBER() OVER (PARTITION BY name ORDER BY live_children DESC, created_at ASC, id ASC) AS rn
    FROM   scored
)
UPDATE z
SET    z.deleted_at = SYSDATETIME(),
       z.deleted_by = (SELECT TOP 1 id FROM dbo.users ORDER BY created_at)
FROM   dbo.well_zones z
JOIN   ranked r ON r.id = z.id
WHERE  r.rn > 1;
