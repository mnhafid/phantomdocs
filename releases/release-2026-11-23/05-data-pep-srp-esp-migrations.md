# 05 — Data: migration kolom SRP / ESP di `pep_action_plan_artificial_lift`

- **Ticket / PR:** PHI-2494..2497, PR #1495
- **Dicatat:** 20 Nov 2026
- **Status:** dev DB sudah ter-apply (19 Nov 2026, kedua migration ada di `__EFMigrationsHistory`). Prod: belum.

## Alasan

SRP dan ESP butuh 5 field baru. `method` `varchar(20)` terlalu pendek untuk `electric_submersible_pump`
(25 karakter): submit ESP memberi HTTP 500 "String or binary data would be truncated".

## Perubahan

| Migration | Isi |
|---|---|
| `20261119022243_AddSrpEspToPepActionPlanArtificialLift` | Tambah kolom nullable: `pump_type`, `pump_brand`, `prime_mover_name` (`nvarchar(200)`), `frequency`, `electric_current` (`decimal(18,6)`) |
| `20261119091214_WidenPepActionPlanArtificialLiftMethod` | `method` `varchar(20)` → `varchar(30)` |

Tidak ada perubahan data. Tabel PHSS tidak berubah. Di antara keduanya ada migration phi-dev
`20261119090000_AddLpoReportPlantAndUnitWell` (bukan bagian dari PR ini; urutannya aman).

## Langkah deploy

Pilih satu cara, jangan dua-duanya:

1. **EF:** `make db-update`. Hati-hati: ini menjalankan **semua** migration pending.
2. **SQL (DBeaver):** script idempotent di `docs/ActionPlan/13-Migration-SRP-ESP.md` (juga ada di deskripsi PR #1495).
   Script ini juga menulis baris `__EFMigrationsHistory`, jadi `make db-update` nanti melewati keduanya.

Rollback: lihat `docs/ActionPlan/13-Migration-SRP-ESP.md`. Rollback migration 2 gagal selama masih ada baris ESP.

## Verifikasi

```sql
SELECT COL_LENGTH('dbo.pep_action_plan_artificial_lift', 'method') AS method_chars; -- 30
SELECT c.name, t.name, c.max_length, c.precision, c.scale FROM sys.columns c JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('dbo.pep_action_plan_artificial_lift')
  AND c.name IN ('pump_type','pump_brand','prime_mover_name','frequency','electric_current'); -- 5 baris
SELECT MigrationId FROM dbo.__EFMigrationsHistory
WHERE MigrationId IN (N'20261119022243_AddSrpEspToPepActionPlanArtificialLift', N'20261119091214_WidenPepActionPlanArtificialLiftMethod'); -- 2 baris
```
