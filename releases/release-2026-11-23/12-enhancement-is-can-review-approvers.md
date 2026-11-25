# 12 — Enhancement: `is_can_review` di list Action Plan juga untuk approver

- **Ticket / PR:** PHI-2243 (approval), branch `feat/PHI-2243-is-can-review-approvers` (dari `origin/phi-dev` 91509cd5), PR belum dibuat
- **Dicatat:** 25 Nov 2026
- **Status:** staged di `.worktrees/ap-is-can-review-approvers`, belum commit; build + test belum dijalankan

## Alasan

FE mengira `is_can_review` di list PEP / PHSS sudah mencakup approver. Ternyata hanya PO pool (161) saat
`waiting_review`. Approver yang levelnya sedang menunggu (ronde Reject atau ronde Modify) tidak punya flag di list.

## Perubahan

`is_can_review` (field baris dan query filter) di `GET /well-surveilence/{wellId}/action-plans/pep` dan `/phss`
sekarang `true` kalau plan menunggu aksi dari user yang login:

| approval_status | Syarat |
|---|---|
| `waiting_review` | PO pool (161), sama seperti sebelumnya |
| `modify_in_approval` | approver level yang pending + 162 atau 163; atau SSDP creator di level terakhirnya sendiri (tanpa 162 / 163) |
| `reject_in_approval` | approver level yang pending + 163 (`approval/reject` atau `approval/modify`) |

Aturan sama dengan guard endpoint review / approval, jadi baris yang di-flag tidak menjawab 403.
Detail tidak berubah: `can_review` tetap untuk PO saja; approver pakai `can_approve`.

File: `ActionPlanApprovalAccess.cs` (`ActionPlanListReviewScope`, `ResolveListScopeAsync`), `ActionPlanPepService.cs`,
`ActionPlanPhssService.cs`, kedua DTO (doc comment), `Tests/ActionPlanApprovalTests.cs` (2 test baru).

## Langkah deploy

Tidak ada SQL / config. Kabari FE: arti `is_can_review` lebih luas (PO + approver level pending).

## Verifikasi

1. Plan di-Modify PO (2 level manager): Manager 1 → `is_can_review=true`; Manager 2 dan PO → `false`.
2. Manager 1 approve: Manager 2 → `true`. Manager 2 approve: SSDP creator → `true`.
3. Plan di-Reject PO: Manager 1 → `true`; Manager 2 → `false` sampai Manager 1 setuju reject.
4. `?is_can_review=true` mengembalikan baris yang sama dengan flag `true`.
