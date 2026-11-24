# 13 — Migration: PEP SRP / ESP fields (PHI-2494..2497)

EF migrations (apply in this order):
1. `20261119022243_AddSrpEspToPepActionPlanArtificialLift`: adds 5 columns.
2. `20261119091214_WidenPepActionPlanArtificialLiftMethod`: changes `method` from `varchar(20)` to `varchar(30)`. `electric_submersible_pump` has 25 characters. With `varchar(20)`, an ESP submit gave HTTP 500 ("String or binary data would be truncated ... column 'method'").
Branch: `feat/phi-2494-ap-srp-esp` (worktree `.worktrees/phi-2494-ap-srp-esp`, stacked on PR #1476).

## What changes

Migration 1 adds 5 nullable columns to `dbo.pep_action_plan_artificial_lift`. Migration 2 makes the `method` column wider. Neither migration changes existing data.

| Column | Type | Method | Rule (backend) |
|---|---|---|---|
| `pump_type` | `nvarchar(200)` NULL | SRP | optional free text |
| `pump_brand` | `nvarchar(200)` NULL | SRP | optional free text |
| `prime_mover_name` | `nvarchar(200)` NULL | SRP | optional free text (the decimal `prime_mover` stays for the pump adjustment flow) |
| `frequency` | `decimal(18,6)` NULL | ESP | required, `>= 0`; `0` is a valid value |
| `electric_current` | `decimal(18,6)` NULL | ESP | required, `>= 0`; `0` is a valid value |
| `method` (changed) | `varchar(20)` → `varchar(30)` NULL | both | `sucker_rod_pump` (15 chars), `electric_submersible_pump` (25 chars) |

SRP also uses the existing columns `stroke_length`, `spm_freq` (API field `spmfreq`) and `power`.
PHSS gets no change: `phss_action_plan_artificial_lift` does not get these columns.

## How to run

You can use one of the two procedures. Do not use both.

1. **EF:** run `make db-update` from the worktree. Caution: this applies **all** pending migrations to the shared dev DB.
2. **SQL only (DBeaver):** run the script below.
   - Each statement is self-contained. The script has no `GO` and no `DECLARE`, so DBeaver can split it on `;`.
   - The script is idempotent, so you can run it again with no error.
   - The `INSERT` statements write the rows in `__EFMigrationsHistory`. A later `make db-update` then skips these migrations.

### Forward script

```sql
IF COL_LENGTH('dbo.pep_action_plan_artificial_lift', 'pump_type') IS NULL ALTER TABLE dbo.pep_action_plan_artificial_lift ADD pump_type nvarchar(200) NULL;
IF COL_LENGTH('dbo.pep_action_plan_artificial_lift', 'pump_brand') IS NULL ALTER TABLE dbo.pep_action_plan_artificial_lift ADD pump_brand nvarchar(200) NULL;
IF COL_LENGTH('dbo.pep_action_plan_artificial_lift', 'prime_mover_name') IS NULL ALTER TABLE dbo.pep_action_plan_artificial_lift ADD prime_mover_name nvarchar(200) NULL;
IF COL_LENGTH('dbo.pep_action_plan_artificial_lift', 'frequency') IS NULL ALTER TABLE dbo.pep_action_plan_artificial_lift ADD frequency decimal(18,6) NULL;
IF COL_LENGTH('dbo.pep_action_plan_artificial_lift', 'electric_current') IS NULL ALTER TABLE dbo.pep_action_plan_artificial_lift ADD electric_current decimal(18,6) NULL;
IF NOT EXISTS (SELECT 1 FROM dbo.__EFMigrationsHistory WHERE MigrationId = N'20261119022243_AddSrpEspToPepActionPlanArtificialLift') INSERT INTO dbo.__EFMigrationsHistory (MigrationId, ProductVersion) VALUES (N'20261119022243_AddSrpEspToPepActionPlanArtificialLift', N'9.0.0');
IF COL_LENGTH('dbo.pep_action_plan_artificial_lift', 'method') < 30 ALTER TABLE dbo.pep_action_plan_artificial_lift ALTER COLUMN method varchar(30) NULL;
IF NOT EXISTS (SELECT 1 FROM dbo.__EFMigrationsHistory WHERE MigrationId = N'20261119091214_WidenPepActionPlanArtificialLiftMethod') INSERT INTO dbo.__EFMigrationsHistory (MigrationId, ProductVersion) VALUES (N'20261119091214_WidenPepActionPlanArtificialLiftMethod', N'9.0.0');
```

### Check

Use `sys.columns`, not `INFORMATION_SCHEMA`. `INFORMATION_SCHEMA` gives the nvarchar length in bytes.

```sql
SELECT c.name, t.name AS type_name, c.max_length / 2 AS nvarchar_chars, c.precision, c.scale, c.is_nullable
FROM sys.columns c
JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('dbo.pep_action_plan_artificial_lift')
  AND c.name IN ('pump_type', 'pump_brand', 'prime_mover_name', 'frequency', 'electric_current')
ORDER BY c.name;
```

Expected result: 5 rows. All have `is_nullable = 1`. The 3 nvarchar columns have `nvarchar_chars = 200`. The 2 decimal columns have `precision = 18` and `scale = 6`.

```sql
SELECT COL_LENGTH('dbo.pep_action_plan_artificial_lift', 'method') AS method_chars;
```

Expected result: `30`. (`method` is `varchar`, so `COL_LENGTH` gives characters. Do not divide by 2.)

```sql
SELECT MigrationId, ProductVersion FROM dbo.__EFMigrationsHistory WHERE MigrationId IN (N'20261119022243_AddSrpEspToPepActionPlanArtificialLift', N'20261119091214_WidenPepActionPlanArtificialLiftMethod');
```

Expected result: 2 rows.

### Rollback

Run the rollback only when no live plan uses SRP or ESP. First, use this query to find those plans:

```sql
SELECT a.action_plan_id, a.method, p.record_state, p.approval_status
FROM dbo.pep_action_plan_artificial_lift a
JOIN dbo.pep_action_plan p ON p.id = a.action_plan_id
WHERE a.method IN ('sucker_rod_pump', 'electric_submersible_pump');
```

Migration 2 first. The `varchar(20)` step fails while an ESP row exists, so do it only after you remove or change those rows.

```sql
ALTER TABLE dbo.pep_action_plan_artificial_lift ALTER COLUMN method varchar(20) NULL;
DELETE FROM dbo.__EFMigrationsHistory WHERE MigrationId = N'20261119091214_WidenPepActionPlanArtificialLiftMethod';
```

Then migration 1:

```sql
IF COL_LENGTH('dbo.pep_action_plan_artificial_lift', 'electric_current') IS NOT NULL ALTER TABLE dbo.pep_action_plan_artificial_lift DROP COLUMN electric_current;
IF COL_LENGTH('dbo.pep_action_plan_artificial_lift', 'frequency') IS NOT NULL ALTER TABLE dbo.pep_action_plan_artificial_lift DROP COLUMN frequency;
IF COL_LENGTH('dbo.pep_action_plan_artificial_lift', 'prime_mover_name') IS NOT NULL ALTER TABLE dbo.pep_action_plan_artificial_lift DROP COLUMN prime_mover_name;
IF COL_LENGTH('dbo.pep_action_plan_artificial_lift', 'pump_brand') IS NOT NULL ALTER TABLE dbo.pep_action_plan_artificial_lift DROP COLUMN pump_brand;
IF COL_LENGTH('dbo.pep_action_plan_artificial_lift', 'pump_type') IS NOT NULL ALTER TABLE dbo.pep_action_plan_artificial_lift DROP COLUMN pump_type;
DELETE FROM dbo.__EFMigrationsHistory WHERE MigrationId = N'20261119022243_AddSrpEspToPepActionPlanArtificialLift';
```

## Notes

- The EF migrations contain only these changes (5 columns + `method` width). I removed the false `permission_groups` / `TempId` diff that the scaffolder adds. I also reverted the `AssignedDepartment` property-order drift in the snapshot.
- The column names in the EF migration and in this script are the same. Thus both procedures give the same schema.
