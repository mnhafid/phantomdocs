-- PHI-1641. Run ONCE per database. Rows already stored in MMSCF/BBL would be scaled again.

UPDATE well_zone_assignments
SET eur_gas = eur_gas * 1000
WHERE eur_gas IS NOT NULL;

UPDATE well_zone_assignments
SET eur_oil = eur_oil * 1000000
WHERE eur_oil IS NOT NULL;

UPDATE well_zone_assignments
SET eur = ISNULL(eur_gas, 0) + ISNULL(eur_oil, 0)
WHERE eur_gas IS NOT NULL OR eur_oil IS NOT NULL;
