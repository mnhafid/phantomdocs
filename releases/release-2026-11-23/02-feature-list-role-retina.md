# 02 — Feature: list role dari Retina (SYSROLE)

- **Ticket / PR:** PHI-2119 (list-role), PR belum dibuat
- **Dicatat:** 20 Nov 2026
- **Status:** BE + FE staged, belum commit, belum build/test. Ikut release ini atau tidak: belum dikonfirmasi user.

## Alasan

Halaman Role Management (FE) menampilkan role dari tabel lokal `roles` (`GET /v1/roles`).
Role yang dipakai untuk ACL sekarang adalah SYSROLE di Retina. Halaman harus menampilkan role Retina.

Sumber data: Retina global query **169** (`globalQueryRest/query`, `PARAM 1 = "ALL"`). Query ini
mengembalikan satu baris per ACL (SYSROLE × page): contoh dev = 1253 baris, 21 SYSROLE.
Satu SYSROLE bisa punya lebih dari satu ACLID (contoh: `Team Member - Project Control` = 682 dan 686).

## Perubahan

### BE — worktree `.worktrees/phi-2119-list-role`, branch `feat/PHI-2119-list-role` (base `origin/phi-dev` 3fd29233)

- Baru: `src-be/Logics/Services/Roles/RetinaRolesService.cs` (`IRetinaRolesService`, `RetinaRoleFilter`, `RetinaRoleDto`).
  - Panggil `IR3DataManagementService.GetGlobalQuery` (tanpa cache, supaya error Retina tidak ter-cache sampai 18:00).
  - Group baris per SYSROLE (case-insensitive), dedupe `ACLID` dan `SEQ_ACL`, sort nama, filter `?search=`.
- Endpoint baru `GET /api/v1/roles/retina` di `RolesEndpoint.cs` (`MapGetRetinaRoles`).
- Register `IRetinaRolesService` di `AppServiceSetup.cs`.
- Response item: `{ sys_role, sys_name, acl_ids[], seq_acls[] }`.
- Service terpisah dari `RolesService` supaya DI di `RolePermissionCacheInvalidationTests` tidak rusak.

### FE — worktree `phantom-fe/.worktrees/retina-roles-list`, branch `feat/retina-roles-list` (base lokal `origin/phantom-dev` c81ac26a, fetch gagal)

- `models/Role.model.ts`: `RetinaRole`, `ParamsRetinaRoleList`, `ResponseRetinaRoleList`.
- `services/role.service.ts` + `stores/role.ts`: `getRetinaRoles()`.
- `pages/Role/List/Index.vue`: tabel Name / Privileges (jumlah SEQ) / ACL ID, read-only.
- `pages/Role/List/TableHeader.vue`: tombol Add Role dihapus.
- **Tidak** diubah: `UserManagement/RoleSelect.vue` (masih `GET /v1/roles`, karena menyimpan `role_id` lokal).
- `ModalAddRole.vue`, `ModalEditRole.vue`, route `role.permission` masih ada tetapi tidak dibuka dari list lagi.

## Langkah deploy

- **SQL prod:** tidak ada.
- **Config:** tidak ada. Query ID 169 hard-coded di `RetinaRolesService` (seperti query 135 di `UsersService`).
- **Retina:** client-id app harus boleh memanggil global query 169 di prod. Cek ke R3 team bahwa query 169 ada di prod dan isinya sama.
- **Dev (mock auth saja):** isi row `mock_auth_sessions` (`username='169:ALL'`, `stage='global_query'`).
  Tanpa row ini endpoint mengembalikan list kosong. SQL (idempoten, aman untuk DBeaver):
  `/private/tmp/claude-501/-Users-hafidhidayatullah-Stuffs-Grounds-OceanInovasi-phi-phiDev/aa85f1d6-4133-4530-9148-b2a7c2bbaac1/scratchpad/seed_mock_retina_sysrole_169.sql`
  (scratchpad bisa terhapus; dibuat dari `~/Downloads/GLOBAL-QUERY-R3TINAGETSYSROLE.yml`). **Belum dijalankan:** DB dev tidak bisa diakses (VPN).
- Deploy FE dan BE bersamaan: FE baru memanggil `/v1/roles/retina`, yang belum ada di BE lama.

## Verifikasi

1. `GET /api/v1/roles/retina` → 200, satu item per SYSROLE, tidak ada nama dobel.
2. `GET /api/v1/roles/retina?search=team` → hanya role yang namanya mengandung "team".
3. FE: login (dev mock: `phi.superadmin`, password apa saja) → Role Management menampilkan role Retina, tanpa tombol Add/Edit/Delete.
4. User Management → pilih role masih menampilkan role lokal (tidak berubah).

## Catatan

- Run BE lokal di `phi-dev` menulis ke store Quartz `QRTZ_*` yang dipakai dev deployed (guard belum di-merge).
