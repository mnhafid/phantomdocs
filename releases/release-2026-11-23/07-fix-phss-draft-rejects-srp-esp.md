# 07 — Fix: draft PHSS menolak method SRP / ESP

- **Ticket / PR:** PHI-2496, PR #1495 (commit `d1f7c6bb`), temuan review Medium
- **Dicatat:** 20 Nov 2026
- **Status:** sudah di branch PR #1495; reply di thread review sudah dikirim, menunggu reviewer menutup thread.

## Alasan

`RejectOnPhss` hanya dipanggil di submit dan Modify proposal PHSS. Save draft dan update draft PHSS menerima
`electric_submersible_pump` (25 karakter), lalu masuk ke `phss_action_plan_artificial_lift.method varchar(20)`
→ HTTP 500 (truncation).

## Perubahan

- `RejectOnPhss` dipindah ke `ValidateArtificialLiftMode` (`ActionPlanPhssService.cs`). Save draft, update draft,
  submit, dan Modify proposal semuanya memanggil method ini → 400 "only available for PEP".
- Test baru `Phss_SaveDraft_Rejected` dan `Phss_UpdateDraft_Rejected` di `ActionPlanSrpTests` dan `ActionPlanEspTests`.
- BOM di awal file migration `20261119091214_...` dihapus (kosmetik).

## Langkah deploy

Tidak ada SQL, Retina, atau config. Ikut deploy backend PR #1495.

## Verifikasi

1. `POST` save draft PHSS dengan `artificial_lift.method = electric_submersible_pump` → 400, bukan 500, dan tidak ada baris baru.
2. Test `ActionPlan|MyTask|MyApproval`: 370/370 lulus (20 Nov 2026).
