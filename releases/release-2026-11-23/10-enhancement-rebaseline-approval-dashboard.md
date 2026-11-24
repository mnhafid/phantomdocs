# 10 — Enhancement: aksi approval rebaseline di Personal Dashboard

- **Ticket / PR:** PHI-2263 (PRD 624), PR #1485 (merged ke phi-dev 19 Nov 2026)
- **Dicatat:** 20 Nov 2026
- **Status:** kode di phi-dev dan staging; seed template notifikasi **belum** dijalankan; uji race (2 approver bersamaan) belum dijalankan

## Alasan

Gap PRD 624 vs API: `/review` masih jalan untuk rebaseline yang sudah diproses, approver level yang sudah lewat
mendapat pesan yang salah, tidak ada guard untuk 2 approver yang klik bersamaan, dan teks notifikasi memakai key mentah `ProjectRebaseline`.

## Perubahan

- `GET /projects/rebaseline/{id}/review`: rebaseline yang tidak `on hold` → **400 code `03`**
  "This rebaseline request has already been processed or is no longer pending." (dengan `error_data`).
- `POST /projects/rebaseline/approval`: approver level yang sudah lewat → 400 code `03` (bukan "not allowed").
- Guard konkurensi: `ExecuteUpdate` approve/reject hanya berlaku kalau `status='active'` dan level masih sama;
  0 baris → 400 code `03`, transaksi (termasuk approval log) di-rollback.
- Notifikasi: label "Project Rebaseline", subject email "Project Rebaseline Approval Required",
  template in-app baru `project_rebaseline_approval_notif` (fallback ke `approval_notif` kalau belum di-seed).
- Di luar scope (disepakati PO): cancel/withdraw rebaseline.

## Langkah deploy

1. Deploy BE (sudah ikut phi-dev).
2. Jalankan per environment: `src-be/DataAccess/Database/seed_rebaseline_approval_notification_template.sql`
   (idempotent; id `22222222-2222-2222-2222-222222222263`).
3. FE: tangani 400 code `03` dari `/review` dan `/approval` → toast "already processed" + hapus card.

## Verifikasi (staging 19 Nov 2026, user R3TEST.agil)

| Tes | Hasil |
|---|---|
| `/review` rebaseline rejected / done | ✅ 400 `03` |
| `/review` id tidak ada | ✅ 404 |
| `/approval` rebaseline rejected | ✅ 400 `03` |
| `/approval` notes kosong / action salah | ✅ 400 |
| Approver level 1 saat sudah level 2 | ✅ 400 `03` |
| Approver level 2 saat level 1 pending / bukan approver | ✅ 400 "not allowed" |
| `my-approval-list?approval_type=project_rebaseline` | ✅ 3 card (PLA-0001, PN19072601 delayed; PRBO2837489 near due) |
| `/review` rebaseline `on hold` (7F148AF6) | ❌ 500 setelah 30.3s (3/3). Lokal 200 dalam 39s. Bukan dari PR ini (status check lolos); dugaan SQL timeout 30s di tahap diff. Log staging: journey `077434b8-bbb1-4ae4-90df-8940da61b929` |

Setelah seed: buat satu pengajuan rebaseline → cek notifikasi approver berjudul "Project Rebaseline Approval Required".
