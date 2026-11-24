# 11 — Fix: `GET /my-task-list` timeout (500)

- **Ticket / PR:** tanpa ticket, PR #1493 (branch `fix/my-task-list-slow-query`, **open**, belum merge)
- **Dicatat:** 20 Nov 2026
- **Status:** index sudah di dev DB (manual, 18 Nov); kode menunggu review + merge; ikut release hanya kalau PR merge sebelum cut

## Alasan

`/my-task-list` sering 500 "Failed to get my task list" (SQL timeout 40–106s). Penyebab: `BuildProjectTaskSummaryAsync`
membaca `vwProjectTaskSummary` (rollup penuh semua task) hanya untuk progress top-WBS per project. DB dev lambat di disk I/O.

## Perubahan

- Query raw `LoadTopWbsProgressAsync` menggantikan view (aturan rollup sama; cocok 1.032/1.032 project di dev).
- Index `IX_project_tasks_project_id_cover` ditambah `breakdown` dan `weight` di INCLUDE (~3,2 MB di dev).
- Endpoint sekarang me-log exception + elapsed ms.

## Langkah deploy

1. Migration `20261118150000_CoverProjectTasksProjectIdIndex` (raw SQL: DROP IF EXISTS + CREATE; aman diulang).
   - **Dev:** sudah diterapkan manual 18 Nov (index + baris `__EFMigrationsHistory`).
     **Jangan** `dotnet ef database update` ke dev: 12 migration lokal lama tidak ada di history dev.
   - Prod/staging lain: cek dulu apakah index sudah ada dan INCLUDE-nya, lalu jalankan migration / SQL-nya.
2. Tidak ada perubahan kontrak API.

## Verifikasi

1. `SELECT i.name, c.name FROM sys.indexes i JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE i.name='IX_project_tasks_project_id_cover';`
   → ada `breakdown` dan `weight`.
2. `GET /api/v1/my-task-list` (agil) → 200. Lokal: 4,7–6,5s (sebelumnya 500 setelah 40–106s).
   Catatan: angka lokal mungkin dari build query versi sebelumnya (restart tidak terkonfirmasi); ulangi setelah deploy.
3. Nilai progress per project sama dengan view (contoh `PN08092026002` = 0.21, `PN08092026001` = 1.1).
