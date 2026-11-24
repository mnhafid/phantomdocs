SET QUOTED_IDENTIFIER ON;
-- PHI-1644: repair well_history_phss volumes written with the wrong unit scale.
-- Only GAS converts (MSCF -> MMSCF, /1000); oil/water/gross are BBL on both sides.
-- Two historical shapes exist; each UPDATE detects its own and is idempotent.
-- Requires STG_PHPUMONCUM to still hold the loads that produced the rows.

WITH days AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM days WHERE n < 31
),
per_cpid_daily AS (
    SELECT w.id AS well_id,
           wz.id AS well_zone_id,
           DATEFROMPARTS(YEAR(p.PDATE), MONTH(p.PDATE), d.n) AS prod_date,
           p.MONOIL / NULLIF(p.MONDAYS, 0)          AS oil,
           p.MONGAS / NULLIF(p.MONDAYS, 0) / 1000.0 AS gas_out,
           p.MONWTR / NULLIF(p.MONDAYS, 0)          AS water,
           (p.MONOIL + p.MONWTR) / NULLIF(p.MONDAYS, 0) AS gross
    FROM   dbo.STG_PHPUMONCUM p
    JOIN   dbo.wells      w  ON REPLACE(w.well_name, '-', '') = p.WELL AND w.deleted_at IS NULL
    JOIN   dbo.well_zones wz ON wz.name = p.ZONE                       AND wz.deleted_at IS NULL
    JOIN   days d ON d.n <= p.MONDAYS AND d.n <= DAY(EOMONTH(p.PDATE))
    WHERE  p.PDATE IS NOT NULL
),
agg AS (
    SELECT well_id, well_zone_id, prod_date,
           SUM(oil) AS oil, SUM(gas_out) AS gas_out, SUM(water) AS water, SUM(gross) AS gross
    FROM   per_cpid_daily
    GROUP BY well_id, well_zone_id, prod_date
)
UPDATE t SET t.gas_out = a.gas_out, t.updated_at = SYSDATETIME()
FROM dbo.well_history_phss t
JOIN agg a ON a.well_id = t.well_id AND a.well_zone_id = t.well_zone_id AND a.prod_date = t.prod_date
WHERE t.deleted_at IS NULL
  AND a.gas_out > 0
  AND ABS(t.gas_out - a.gas_out * 1000.0) <= 1e-6 * a.gas_out * 1000.0
OPTION (MAXRECURSION 31);

WITH days AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM days WHERE n < 31
),
per_cpid_daily AS (
    SELECT w.id AS well_id,
           wz.id AS well_zone_id,
           DATEFROMPARTS(YEAR(p.PDATE), MONTH(p.PDATE), d.n) AS prod_date,
           p.MONOIL / NULLIF(p.MONDAYS, 0)          AS oil,
           p.MONWTR / NULLIF(p.MONDAYS, 0)          AS water,
           (p.MONOIL + p.MONWTR) / NULLIF(p.MONDAYS, 0) AS gross
    FROM   dbo.STG_PHPUMONCUM p
    JOIN   dbo.wells      w  ON REPLACE(w.well_name, '-', '') = p.WELL AND w.deleted_at IS NULL
    JOIN   dbo.well_zones wz ON wz.name = p.ZONE                       AND wz.deleted_at IS NULL
    JOIN   days d ON d.n <= p.MONDAYS AND d.n <= DAY(EOMONTH(p.PDATE))
    WHERE  p.PDATE IS NOT NULL
),
agg AS (
    SELECT well_id, well_zone_id, prod_date,
           SUM(oil) AS oil, SUM(water) AS water, SUM(gross) AS gross
    FROM   per_cpid_daily
    GROUP BY well_id, well_zone_id, prod_date
)
UPDATE t SET t.oil = a.oil, t.water = a.water, t.gross = a.gross, t.updated_at = SYSDATETIME()
FROM dbo.well_history_phss t
JOIN agg a ON a.well_id = t.well_id AND a.well_zone_id = t.well_zone_id AND a.prod_date = t.prod_date
WHERE t.deleted_at IS NULL
  AND a.gross > 0
  AND ABS(t.gross - a.gross / 1000.0) <= 1e-6 * a.gross / 1000.0
OPTION (MAXRECURSION 31);
