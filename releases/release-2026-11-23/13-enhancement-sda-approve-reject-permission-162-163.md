# 13 — Enhancement: permission 162 / 163 (Approve / Reject Action Plan) untuk SDA 1 dan SDA 2

- **Ticket / PR:** PHI-2243 (Action Plan approval), tanpa perubahan kode
- **Dicatat:** 25 Nov 2026
- **Status:** dev selesai (data mock); prod menunggu R3 team (Retina)

## Alasan

`r3test.sda1` adalah satu-satunya approver di approval route. Dia memanggil
`POST /well-surveilence/action-plans/pep/7e8fac57-e8d5-4de5-977a-fd1ff0dec2dc/approval/reject` dan mendapat
"You are not allowed to reject action plans". Plan ada di `reject_in_approval`, level 1 dari 1.

Penyebab: `LoadForLevelDecisionAsync` memeriksa permission sebelum memeriksa approver.
`approval/reject` dan `approval/modify` memerlukan 163, dan `approval/approve` memerlukan 162.
Pengecualian SSDP creator hanya berlaku untuk level terakhir ronde Modify, tidak untuk ronde Reject.
ACL sda1 tidak berisi 162 dan 163: `[128, 137, 138, 139, 140, 153, 155, 156, 159]`.

## Perubahan

### Dev (sudah dilakukan, 25 Nov 2026)

`mock_auth_sessions` stage `session`: 2 baris ACL ditambahkan ke tiap user (format sama dengan `phi.po`):

```json
{"COMPONENTID":"PHANTOM_Action_Plan_Approval","URLPATH":"Action Plan Approval","HIDDEN":0,"READONLY":0,"DISABLED":0,"PAGE":"Approve Action Plan","SEQ":162}
{"COMPONENTID":"PHANTOM_Action_Plan_Approval","URLPATH":"Action Plan Approval","HIDDEN":0,"READONLY":0,"DISABLED":0,"PAGE":"Reject Action Plan","SEQ":163}
```

| User | Row id | SYSROLE (dev) | ACL sesudah |
|---|---|---|---|
| `r3test.sda1` | `b5ff07d0-13c2-43e9-9018-6601f42585b9` | Subsurface Development Area 1 | 128, 137, 138, 139, 140, 153, 155, 156, 159, **162, 163** |
| `r3test.sda2` | `27ce1416-841c-4330-b1b7-2699f1382da8` | Subsurface Development Area 2 | 128, 137, 138, 139, 140, 153, 154, 155, 159, **162, 163** |

Backup payload lama: scratchpad sesi `mock_backup_sda/<row id>.json` (bisa hilang saat scratchpad dibersihkan).

### Prod (langkah deploy, R3 team)

Tambah SEQ 162 dan 163 ke role Retina SDA 1 dan SDA 2. Format sama dengan
`docs/ActionPlan/approval-route-action-plan.md` (bagian RETINA insert):

```sql
-- {ACLID_SDA1} / {ACLID_SDA2} = ROLEACL.ACLID yang SUDAH ADA untuk role itu:
--   SELECT ACLID, SYSROLE FROM R3TINA.ROLEACL WHERE SYSNAME = 'PHANTOM';
-- SYSROLE dev: 'Subsurface Development Area 1' / 'Subsurface Development Area 2'. Nama prod belum diverifikasi.
INSERT INTO R3TINA.ACL (ACLID, URLPATH, COMPONENTID, HIDDEN, READONLY, DISABLED, SEQ, PAGE) VALUES({ACLID_SDA1},'Action Plan Approval','Action Plan Approval',0,0,0,162,'Approve Action Plan');
INSERT INTO R3TINA.ACL (ACLID, URLPATH, COMPONENTID, HIDDEN, READONLY, DISABLED, SEQ, PAGE) VALUES({ACLID_SDA1},'Action Plan Approval','Action Plan Approval',0,0,0,163,'Reject Action Plan');
INSERT INTO R3TINA.ACL (ACLID, URLPATH, COMPONENTID, HIDDEN, READONLY, DISABLED, SEQ, PAGE) VALUES({ACLID_SDA2},'Action Plan Approval','Action Plan Approval',0,0,0,162,'Approve Action Plan');
INSERT INTO R3TINA.ACL (ACLID, URLPATH, COMPONENTID, HIDDEN, READONLY, DISABLED, SEQ, PAGE) VALUES({ACLID_SDA2},'Action Plan Approval','Action Plan Approval',0,0,0,163,'Reject Action Plan');
COMMIT;
```

- Pastikan `permissions` id 162 dan 163 ada di DB prod (group 30, dari `seed_action_plan_approval.sql`).
  Kalau tidak ada, `/users/permissions` membuang SEQ itu tanpa error.

## Verifikasi

1. sda1 / sda2 logout lalu login lagi (cache ACL Redis `PHI:RETINA:<user>` diisi ulang saat login).
2. `GET /api/v1/users/permissions` → ada key `"162"` dan `"163"`.
3. Ulangi `approval/reject` untuk plan `7e8fac57…` sebagai sda1 → 200, plan `rejected` (level 1 = level terakhir).
4. Kalau hasilnya "You are not an approver of level 1": sda1 tidak ada di `action_plan_approvers` level 1 cycle itu.
