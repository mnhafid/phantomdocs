# 06 — Enhancement: field `method` di item Action Plan pada my-task-list dan need-action

- **Ticket / PR:** PHI-2494 (PR #1495, commit `ece300ab`); Bruno phi-phantom-collections#214
- **Dicatat:** 20 Nov 2026
- **Status:** sudah di branch PR #1495. Bruno staged di branch `feat/phi-2494-ap-srp-esp-bruno`.

## Alasan

Card dashboard hanya menampilkan `activity_type` (`installation`), jadi FE tidak bisa membedakan WHC, SRP, dan ESP.

## Perubahan

- Field baru `method` di item `action_plan_review` / `action_plan_approval` pada:
  - `GET /api/v1/my-task-list`
  - `GET /api/v1/my-approval-list`
  - `GET /api/v1/well-surveilence/action-plans/approvals/need-action`
- Nilai: `gas_lift`, `pump`, `well_head_compressor`, `sucker_rod_pump`, `electric_submersible_pump`; `null` untuk `well_test`.
- Aditif: FE lama tidak terpengaruh. FE perlu tahu nilai baru.

## Langkah deploy

Tidak ada SQL, Retina, atau config. Ikut deploy backend PR #1495.

## Verifikasi

1. PO buka `GET /api/v1/my-task-list` → item artificial lift punya `method` (mis. `well_head_compressor`).
2. Item well test → `method: null`.
3. Unit test: `ActionPlanApprovalTests.MyTask_ArtificialLiftItem_ShowsTheMethod`.
