# 04 — Feature: Action Plan PEP Artificial Lift, Sucker Rod Pump dan ESP installation dengan approval

- **Ticket / PR:** PHI-2494, PHI-2495, PHI-2496, PHI-2497 (NID 53,136 M002); PR #1495; Bruno phi-phantom-collections#214
- **Dicatat:** 20 Nov 2026
- **Status:** PR #1495 open. Review: satu temuan Medium sudah di-fix (`d1f7c6bb`), menunggu approve reviewer. Migration sudah di dev DB.
- **Bergantung pada:** PR #1476 (Action Plan approval) dan entry 01 (permission 161).

## Alasan

PRD M002: SSDP PEP harus bisa membuat Action Plan Artificial Lift untuk method baru
`sucker_rod_pump` (SRP) dan `electric_submersible_pump` (ESP). Installation selalu butuh review PO,
sama dengan WHC.

## Perubahan

- Method baru `sucker_rod_pump` dan `electric_submersible_pump`, **hanya PEP**, hanya
  `activity_type = installation` (`installation_schedule`, `installation_update`). PHSS → 400.
- `requires_approval = true` untuk SRP / ESP installation (`ActionPlanApprovalRules`). Flow sama dengan WHC:
  `waiting_review` → PO Approve / Modify / Reject.
- Aturan umum (`ActionPlanPumpInstallation`): `owned_by` wajib (`rental` / `owned`); `contract_number` hanya
  untuk rental, `asset_number` hanya untuk owned; `production`, `pressure` wajib `>= 0`; `pic_ids` minimal 1 saat submit.
- SRP (`ActionPlanSrp`): `stroke_length`, `spmfreq` wajib `> 0`; `power` opsional `>= 0`;
  `pump_type`, `pump_brand`, `prime_mover_name` teks bebas opsional.
- ESP (`ActionPlanEsp`): `frequency`, `electric_current` wajib `>= 0`. **0 adalah nilai valid**, hanya `null` yang ditolak.
- Field method lain dikosongkan oleh server.
- Schema: lihat entry 05.

## Langkah deploy

1. Jalankan migration (entry 05) **sebelum** deploy backend.
2. Deploy backend PR #1495.
3. Template notifikasi: pastikan `src-be/DataAccess/Database/seed_action_plan_notification_templates.sql`
   sudah dijalankan (bagian dari PR #1476). Di dev tabel `notification_templates` belum punya baris
   `phantom_iac_action_plan_*`, jadi API log "Notification template ... not found" dan notifikasi tidak terkirim.
   Flow approval tetap jalan.
4. Retina: tidak ada SEQ baru. Reviewer PO butuh SEQ 161 (entry 01).

## Verifikasi

1. `POST /api/v1/well-surveilence/action-plans/pep/submit` dengan `method = electric_submersible_pump`,
   `frequency = 0`, `electric_current = 0` → 200, `approval_status = waiting_review`.
2. Submit PHSS dengan method SRP / ESP → 400 "only available for PEP".
3. PO buka `GET /api/v1/my-task-list` → plan ada di `action_plan_review`.
4. Hasil curl di dev (19 Nov 2026): integration SRP 20/20, ESP 20/20; E2E SRP 38/50, ESP 38/50.
   Semua yang gagal adalah cek notifikasi (template belum ada, lihat langkah deploy 3).
   Dokumen: `docs/ActionPlan/IntegrationTest-SRP.md`, `IntegrationTest-ESP.md`,
   `08-ScenarioTest-curl-srp.md`, `08-ScenarioTest-curl-esp.md`.
5. Unit test: `ActionPlanSrpTests`, `ActionPlanEspTests`.
