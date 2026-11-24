# Release minggu 23 Nov 2026

Folder ini mencatat semua perubahan yang ikut release minggu depan (minggu 23–27 Nov 2026).
Tanggal pasti release belum ditetapkan; ganti nama folder kalau tanggalnya berubah.

## Aturan

- Satu file per perubahan: `NN-<jenis>-<topik>.md` (jenis: `feature`, `enhancement`, `fix`, `data`, `config`).
- Tiap file berisi: alasan, perubahan, langkah deploy (SQL, Retina, config), cara verifikasi, status.
- Nomor = nomor tertinggi yang ada + 1. Banyak sesi menulis ke folder ini: cek `ls` lagi tepat sebelum membuat file. Nomor yang sudah dipakai tidak diubah (08 dulu 02, bentrok).
- Tambahkan baris di tabel di bawah setiap kali menambah file.
- `docs/` di-gitignore: folder ini catatan lokal, bukan bagian dari PR.

## Daftar perubahan

| # | Jenis | Topik | Ticket / PR | Status |
|---|-------|-------|-------------|--------|
| 01 | enhancement | [Permission 161 Review Action Plan untuk akun PO](01-enhancement-po-review-permission-161.md) | PHI-2243 / PR #1476 | Dev selesai (data mock); prod menunggu R3 team |
| 02 | feature | [List role dari Retina (SYSROLE, query 169)](02-feature-list-role-retina.md) | PHI-2119 / PR belum | BE + FE staged, belum commit; ikut release belum dikonfirmasi |
| 03 | data | [FK wells.field_id dari well_fields ke fields](03-data-wells-field-fk-to-fields.md) | migration RepointWellsFieldToFields | SQL dev siap; prod perlu dicek |
| 04 | feature | [Action Plan PEP SRP / ESP installation dengan approval](04-feature-pep-srp-esp-installation.md) | PHI-2494..2497 / PR #1495 | PR open, menunggu approve reviewer |
| 05 | data | [Migration kolom SRP / ESP + `method` varchar(30)](05-data-pep-srp-esp-migrations.md) | PHI-2494..2497 / PR #1495 | Dev sudah apply; prod belum |
| 06 | enhancement | [Field `method` di my-task-list / need-action](06-enhancement-action-plan-method-in-task-list.md) | PHI-2494 / PR #1495 | Di branch PR; Bruno staged |
| 07 | fix | [Draft PHSS menolak SRP / ESP](07-fix-phss-draft-rejects-srp-esp.md) | PHI-2496 / PR #1495 | Di branch PR (`d1f7c6bb`) |
| 08 | config | [Merge ict-main ke release/20261116-dev (konflik #1491)](08-config-release-merge-ict-main-1491.md) | PR #1491 | Merge di-stage; menunggu commit + push + PR sync |
| 09 | enhancement | [Card On Stream: Plan / Rebaseline / Expected](09-enhancement-onstream-plan-rebaseline.md) | PHI-2267 / PR #1485 | Merged; backfill SQL belum dijalankan |
| 10 | enhancement | [Aksi approval rebaseline di Personal Dashboard](10-enhancement-rebaseline-approval-dashboard.md) | PHI-2263 / PR #1485 | Merged; seed template belum dijalankan; `/review` on-hold 500 di staging |
| 11 | fix | [`/my-task-list` timeout: query raw + cover index](11-fix-my-task-list-timeout.md) | tanpa ticket / PR #1493 | PR open; index sudah di dev |
