# 09 — Enhancement: card On Stream menampilkan Plan, Rebaseline, Expected

- **Ticket / PR:** PHI-2267 (PRD 617), PR #1485 (merged ke phi-dev 19 Nov 2026)
- **Dicatat:** 20 Nov 2026
- **Status:** kode di phi-dev dan staging (build `v1.4.0+20261119.004`); backfill **belum** dijalankan di dev/staging/prod

## Alasan

Rebaseline yang di-apply menimpa `project_tasks.end_date` task `#On Stream`. Akibatnya tanggal plan awal (RB 0)
hilang, dan card tidak bisa membedakan delay terhadap plan awal dan delay terhadap target rebaseline.

## Perubahan

- Tanggal on-stream = `end_date` task `#On Stream` (PRD Background: `plan_on_stream_date` dari `project_tasks.end_date`).
- Tanggal dibekukan di JSON `projects.other` (tanpa kolom baru):
  - `plan_on_stream_date` (RB 0), diisi saat upload baseline;
  - `rebaseline_on_stream_date`, diisi saat rebaseline di-apply (plan tidak pernah ditimpa).
- `GET /api/v1/projects/{id}/on-stream`:
  - field baru `rebaseline_on_stream_date`;
  - status/delay dihitung terhadap `rebaseline ?? plan`;
  - `target_days` = (expected ?? latest) − hari ini (kontrak FE; PRD berbeda, diputuskan tetap 19 Nov);
  - `delay_days` hanya diisi kalau `behind`.
- Error 400 `/review` memakai `BadRequestError` (ada `error_data`).

## Langkah deploy

1. Deploy BE (sudah ikut phi-dev).
2. Jalankan sekali per environment: `src-be/DataAccess/Database/backfill_projects_on_stream_dates.sql`
   (idempotent, satu statement, aman untuk DBeaver).
   - **Batasan:** project yang sudah pernah rebaseline sebelum PHI-2267 mendapat plan = tanggal rebaseline terakhir.
     RB 0 asli tidak bisa dipulihkan dari DB. Kalau PO butuh RB 0 asli, perlu script terpisah yang membaca
     `#On Stream` dari file baseline (`project_rebaselines.type = 'baseline'`).
3. FE harus sudah membaca `rebaseline_on_stream_date` dan arti baru `target_days`.

## Verifikasi

1. Sebelum backfill: `SELECT COUNT(*) FROM projects WHERE ISJSON(other)=1 AND JSON_VALUE(other,'$.plan_on_stream_date') IS NOT NULL;`
2. Sesudah backfill: angka di atas ≈ jumlah project yang punya task `#On Stream` (dev: ~912).
3. `GET /projects/{id}/on-stream` → `plan_on_stream_date` = `end_date` marker (staging 19 Nov: project 4DA73FB3 → `19-08-2026`, end_date 19-08, start 12-08 ✅).
4. Approve + apply satu rebaseline → `rebaseline_on_stream_date` terisi, `plan_on_stream_date` tetap.
