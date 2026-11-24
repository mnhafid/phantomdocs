# 01 — Enhancement: permission 161 (Review Action Plan) untuk akun PO

- **Ticket / PR:** PHI-2243, PR #1476 (Action Plan approval)
- **Dicatat:** 20 Nov 2026
- **Status:** dev selesai (data mock); prod menunggu R3 team (Retina)

## Alasan

User submit Action Plan Artificial Lift (WHC) dan memilih `r3test.po` sebagai PIC. Plan masuk
`waiting_review`, tetapi dashboard `r3test.po` (`my-task-list`, `my-approval-list`) kosong.

Penyebab: `action_plan_review` hanya diisi untuk user dengan permission **161 Review Action Plan**
(group 30) di Retina ACL. Permission ID dibaca dari custom config `action_plan_review_permission_id`
(dev = 161). PIC tidak membuat task di dashboard; PIC adalah pelaksana setelah plan di-approve.
ACL `r3test.po` hanya `[153, 155, 159]`, sedangkan `phi.po` `[153, 155, 159, 161, 162, 163]`.

## Perubahan

### Dev (sudah dilakukan, 20 Nov 2026)

- `mock_auth_sessions` id `b6469443-1715-45c7-b4f7-a877f491f1ca` (`r3test.po`, stage `session`, SYSROLE `PO`):
  ditambah baris ACL SEQ 161, disalin dari `phi.po`:
  `{"COMPONENTID":"PHANTOM_Action_Plan_Approval","URLPATH":"Action Plan Approval","HIDDEN":0,"READONLY":0,"DISABLED":0,"PAGE":"Review Action Plan","SEQ":161}`
- Backup payload lama: scratchpad sesi `mock_backup_r3test_po/session_b6469443.json`.
- 162 / 163 (approve / reject level) **tidak** ditambahkan: itu untuk Manager approver, bukan reviewer PO.

### Prod (langkah deploy)

Semua akun PO reviewer harus punya SEQ 161 di role Retina-nya. Kirim ke R3 team (format R3TINA,
ACLID diganti R3 team):

```sql
-- SYSROLE prod untuk PO belum diverifikasi ('PO' di dev, 'Production Operations' di role 6-roles). Cek dulu.
INSERT INTO R3TINA.ROLEACL (ACLID, SYSNAME, SYSROLE, SEQ_ROLE) VALUES ('{ACLID_161}', 'PHANTOM', '<SYSROLE PO prod>', NULL);
INSERT INTO R3TINA.ACL (ACLID, URLPATH, COMPONENTID, HIDDEN, READONLY, DISABLED, SEQ, PAGE)
VALUES ('{ACLID_161}', 'Action Plan Approval', 'Action Plan Approval', 0, 0, 0, 161, 'Review Action Plan');
```

- Pastikan `permissions` id 161 ada di DB prod (kalau tidak ada, SEQ di-drop diam-diam oleh `/users/permissions`).
- Pastikan custom config `action_plan_review_permission_id` = 161 di prod (kalau tidak ada, default kode = 161).

## Verifikasi

1. User logout lalu login lagi (cache ACL Redis `PHI:RETINA:<user>` diisi ulang saat login).
2. `GET /api/v1/users/permissions` → ada key `"161"`.
3. `GET /api/v1/my-task-list` → `action_plan_review` berisi plan `waiting_review`
   (dev: `0086/WO/SDA1/2026`, `0087/WO/SDA1/2026`, well A-INDANA-PEP).
4. `GET /api/v1/well-surveilence/action-plans/approvals/need-action?stage=review` → 200 dan berisi plan yang sama.
