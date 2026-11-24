/* PRODUCTION — split well_zone_assignments.eur into eur_gas + eur_oil.
   Manual equivalent of migration 20260831123501_AddEurGasOilToWellZoneAssignment.

   Run in PRODUCTION BEFORE deploying the code. The API reads and writes both new
   columns, so shipping the code first makes every well-zone-assignment endpoint
   fail with "Invalid column name 'eur_gas'".

   GO between the two parts is REQUIRED, not styling: SQL Server compiles a batch
   as a whole, so an UPDATE naming eur_gas in the same batch that adds it fails
   with "Invalid column name". If your tool strips GO, run part 1 and part 2
   separately, in order.

   Does NOT write to __EFMigrationsHistory — prod is managed manually. */

/* Part 1 — add the two phase columns. eur stays and becomes the derived total. */
ALTER TABLE dbo.well_zone_assignments ADD eur_gas decimal(18,4) NULL;
ALTER TABLE dbo.well_zone_assignments ADD eur_oil decimal(18,4) NULL;
GO

/* Part 2 — backfill. eur used to hold a single value whose phase is given by the
   row's type, so move it into the matching column. Rows typed water, or with no
   type, are not attributable to a phase: they keep eur and leave both new columns
   NULL. Do not skip this — without it, the first edit of an existing row
   recomputes eur from two NULL phase columns and wipes the stored value. */
UPDATE dbo.well_zone_assignments
SET eur_gas = CASE WHEN LOWER(type) = 'gas' THEN eur END,
    eur_oil = CASE WHEN LOWER(type) = 'oil' THEN eur END
WHERE eur IS NOT NULL AND LOWER(type) IN ('gas', 'oil');
GO

/* Verification — expected: 3 columns decimal(18,4) NULL, and 0 violations
   (every row with a phase value must satisfy eur = eur_gas + eur_oil). */
SELECT name, TYPE_NAME(system_type_id) + '(' + CAST(precision AS varchar) + ',' + CAST(scale AS varchar) + ')' AS data_type, is_nullable
FROM   sys.columns
WHERE  object_id = OBJECT_ID('dbo.well_zone_assignments')
  AND  name IN ('eur', 'eur_gas', 'eur_oil')
ORDER  BY name;

SELECT COUNT(*) AS invariant_violations
FROM   dbo.well_zone_assignments
WHERE  (eur_gas IS NOT NULL OR eur_oil IS NOT NULL)
  AND  (eur IS NULL OR eur <> ISNULL(eur_gas, 0) + ISNULL(eur_oil, 0));
GO
