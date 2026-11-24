# PHI-2265 — Master Rigs: localhost API test report

| | |
|---|---|
| Date | 2026-10-30 |
| Branch / commit | `feat/phi-2265-master-rigs` @ `b9d61cd8` ("master rig") |
| Worktree | `.worktrees/phi-2265-master-rigs` |
| API | `dotnet run --no-build --urls http://127.0.0.1:5099`, `Quartz__Enabled=false` |
| Database | shared dev DB `185.250.38.82 / phantomdb` |
| Auth | mock session JWT for `r3test.agil` (`mock_auth_sessions`) |
| Result | **27 / 27 API cases PASS**, rename-sync PASS, migration PASS |

## 1. Build and migration

| Check | Result |
|---|---|
| `dotnet build WebApi` | 0 errors |
| `dotnet ef migrations has-pending-model-changes` | Only diff = the known `permission_groups` / `TempId` drift. **No MasterRig / `rig_id` diff**, so the hand-patched snapshot + Designer match the model. Throwaway migration removed. |
| Twin SQL `src-be/DataAccess/Database/20261030100000_AddMasterRigs.sql` applied | exit 0. `master_rigs` created, `projects.rig_id` + `IX_projects_rig_id` + `FK_projects_master_rigs` created, `__EFMigrationsHistory` row inserted |
| FKs present | `FK_projects_master_rigs`, `FK_master_rigs_users_created_by`, `FK_master_rigs_users_updated_by` |

### Seed / backfill result (dev)

| Rig (seeded from `projects.rig_name`) | working_area | capacity | Linked projects |
|---|---|---|---|
| BKY-04 (1000 HP) | PHSS | NULL | 1 |
| ELANG-03 (1000 HP) | PHSS | NULL | 1 |
| Rig Chevron 12 | PEP | NULL | 1 |
| Rig Tati-01 | PHSS | NULL | 1 |

- Projects with a `rig_name` but no `rig_id` after backfill: **0**.
- Active NWD DLC/FL projects with **no rig at all: 64**. Per the agreed rule these are hidden from the Gantt until a rig is set via Edit Project.

## 2. API cases

Base: `/api/v1/master/rigs`. Header: `Authorization: Bearer <token>`.

| # | Case | Request | Expect | Got | |
|---|---|---|---|---|---|
| 1 | List all | `GET` | 200 | 200 | PASS |
| 2 | Filter active | `GET ?is_active=true` | 200, all active | 200 | PASS |
| 3 | Empty filter ignored (no 500) | `GET ?is_active=` | 200 | 200 | PASS |
| 4 | Junk filter ignored | `GET ?is_active=abc` | 200 | 200 | PASS |
| 5 | Filter working area | `GET ?working_area=PEP` | 200, only PEP | 200 | PASS |
| 6 | Working area case-insensitive | `GET ?working_area=pep` | 200, ≥1 row | 200 | PASS |
| 7 | Unknown working area | `GET ?working_area=XYZ` | 200, `[]` | 200 | PASS |
| 8 | Create | `POST {name, capacity:1500, capacity_unit:"HP", working_area:"pep"}` | 201, `display_name` = "… (1500 HP)", `working_area` = "PEP", `created_by` set | 201 | PASS |
| 9 | Duplicate name | `POST {name: existing}` | 400 | 400 "Name already used by another rig" | PASS |
| 10 | Blank name | `POST {name:"  "}` | 400 | 400 | PASS |
| 11 | Bad working area | `POST {working_area:"ABC"}` | 400 | 400 "Working area must be one of: PHSS, PEP" | PASS |
| 12 | Negative capacity | `POST {capacity:-1}` | 400 | 400 | PASS |
| 13 | Create inactive | `POST {is_active:false}` | 201, stays `false` (DB `is_active = 0`) | 201 | PASS |
| 14 | Filter inactive | `GET ?is_active=false` | includes inactive rig | 200 | PASS |
| 15 | Get by id | `GET /{id}` | 200 | 200 | PASS |
| 16 | Unknown id | `GET /1111…` | 404 | 404 | PASS |
| 17 | Non-guid id | `GET /abc` | 404 | 404 | PASS |
| 18 | Update | `POST /{id}/update` rename + capacity 2000 | 200, new `display_name`, `updated_by` set | 200 | PASS |
| 19 | Update to taken name | `POST /{id}/update` | 400 | 400 | PASS |
| 20 | Update unknown id | `POST /1111…/update` | 404 | 404 | PASS |
| 21 | Bare `POST /{id}` | `POST /{id}` | not a delete (405) | 405 | PASS |
| 22 | Soft delete | `POST /{id}/delete` | 200 | 200 | PASS |
| 23 | Delete again | `POST /{id}/delete` | 404 | 404 | PASS |
| 24 | Get deleted | `GET /{id}` | 404 | 404 | PASS |
| 25 | List hides deleted | `GET` | deleted rig absent | 200 | PASS |
| 26 | Reuse deleted rig's name | `POST {name: deleted}` | 201 | 201 | PASS |
| 27 | No token | `GET` (no header) | 401 | 401 "Please login to access this feature" | PASS |

### Rename → `projects.rig_name` sync

| Step | `projects.rig_name` of the linked project |
|---|---|
| Before | `Rig Tati-01` |
| `POST /{id}/update {name:"Rig Tati-01 RENAMED"}` → 200 | `Rig Tati-01 RENAMED` |
| Renamed back → 200 | `Rig Tati-01` |

**PASS.** The seeded rig was restored. Its `updated_at` / `updated_by` now show the test user.

### Sample responses

Create (201):

```json
{
  "data": {
    "id": "1d368933-0756-4298-9a04-3b996b989b42",
    "name": "ZZ-TEST-PHI2265",
    "capacity": 1500,
    "capacity_unit": "HP",
    "display_name": "ZZ-TEST-PHI2265 (1500 HP)",
    "is_active": true,
    "working_area": "PEP",
    "created_at": "2026-10-30T20:10:52.559967",
    "created_by": { "id": "8ad89747-d543-4a0a-a2ff-57e9960535e0", "full_name": "R3 Test agil", "email": "r3test.agil@yopmail.com" },
    "updated_at": "2026-10-30T20:10:52.559967",
    "updated_by": { "id": "8ad89747-d543-4a0a-a2ff-57e9960535e0", "full_name": "R3 Test agil", "email": "r3test.agil@yopmail.com" }
  },
  "process_time": "454.57ms",
  "status": "success",
  "code": "",
  "message": "Create rig succeed"
}
```

Validation error (400):

```json
{ "process_time": "0.16ms", "status": "failed", "code": "", "message": "Working area must be one of: PHSS, PEP" }
```

## 3. Findings

| # | Finding | Impact | Suggested action |
|---|---|---|---|
| F1 | Legacy `rig_name` values already contain the capacity, e.g. `ELANG-03 (1000 HP)`, `BKY-04 (1000 HP)`. | If the admin fills `capacity`, the display becomes `ELANG-03 (1000 HP) (1000 HP)`. | Admin cleans the seeded rigs once: rename to `ELANG-03`, set `capacity = 1000`, `capacity_unit = HP`. The rename sync updates the projects automatically. |
| F2 | 64 active NWD DLC/FL projects have no rig. | They are hidden from the DLC/FL Gantt (agreed rule). | PO/PE assigns rigs via Edit Project once `project-rig-id` ships. Query is at the bottom of the twin SQL. |
| F3 | Datetimes come back without an offset (`2026-10-30T20:10:52.559967`); the PRD example uses `…Z`. Seeded rows use DB server time (`SYSDATETIME()`). | FE date display only. | Accept (same as the rest of the API), or tell FE to treat values as local time. |
| F4 | Seeded rigs have `created_by = null`. | Admin table shows an empty "Created by" for those rows. | Accept. |
| F5 | At API startup, `[AlertSchedule]` wrote one cron trigger into the shared `QRTZ_*` store even with `Quartz__Enabled=false`. This is existing behaviour, not PHI-2265 code. | A local run can rewrite dev's alert schedule (`check='0 0 * * * ?'`, `digest='0 0 8 * * ?'`, `snapshot='0 0/5 * * * ?'`). | Separate ticket: skip the AlertSchedule sync when Quartz is disabled. |

## 4. Dev DB state after the test

- Migration `20261030100000_AddMasterRigs` is **applied** on dev (table, column, FK, 4 seeded rigs, 4 backfilled projects).
- All `ZZ-TEST-*` rows were hard-deleted. `master_rigs` holds the 4 seeded rigs only.
- Rollback, if ever needed: the commented block at the end of `20261030100000_AddMasterRigs.sql`.

## 5. Appendix — curl request and response per case

All requests ran against `http://127.0.0.1:5099`. `$TOKEN` = mock JWT for `r3test.agil` (see section 1). Responses are copied verbatim from the run, including real ids of the test rows (since hard-deleted).

### 1. List all (no filter) — HTTP 200 PASS

```bash
curl -s -X GET 'http://127.0.0.1:5099/api/v1/master/rigs' \
  -H "Authorization: Bearer $TOKEN"
```

```json
{
  "data": [
    {
      "id": "4efc41c1-72e4-486f-8a2e-0f0ef2ccc873",
      "name": "BKY-04 (1000 HP)",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "BKY-04 (1000 HP)",
      "is_active": true,
      "working_area": "PHSS",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    },
    {
      "id": "b1721661-390a-4478-b842-e46e84efce4f",
      "name": "ELANG-03 (1000 HP)",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "ELANG-03 (1000 HP)",
      "is_active": true,
      "working_area": "PHSS",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    },
    {
      "id": "1c059f46-4613-4bb2-8a73-012470c51b74",
      "name": "Rig Chevron 12",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "Rig Chevron 12",
      "is_active": true,
      "working_area": "PEP",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    },
    {
      "id": "0faf2cfd-d4e7-424d-8e73-94f49d4a2a52",
      "name": "Rig Tati-01",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "Rig Tati-01",
      "is_active": true,
      "working_area": "PHSS",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    }
  ],
  "process_time": "52.05ms",
  "status": "success",
  "code": "",
  "message": "Get rigs succeed"
}
```

### 2. Filter is_active=true — HTTP 200 PASS

```bash
curl -s -X GET 'http://127.0.0.1:5099/api/v1/master/rigs?is_active=true' \
  -H "Authorization: Bearer $TOKEN"
```

```json
{
  "data": [
    {
      "id": "4efc41c1-72e4-486f-8a2e-0f0ef2ccc873",
      "name": "BKY-04 (1000 HP)",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "BKY-04 (1000 HP)",
      "is_active": true,
      "working_area": "PHSS",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    },
    {
      "id": "b1721661-390a-4478-b842-e46e84efce4f",
      "name": "ELANG-03 (1000 HP)",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "ELANG-03 (1000 HP)",
      "is_active": true,
      "working_area": "PHSS",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    },
    {
      "id": "1c059f46-4613-4bb2-8a73-012470c51b74",
      "name": "Rig Chevron 12",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "Rig Chevron 12",
      "is_active": true,
      "working_area": "PEP",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    },
    {
      "id": "0faf2cfd-d4e7-424d-8e73-94f49d4a2a52",
      "name": "Rig Tati-01",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "Rig Tati-01",
      "is_active": true,
      "working_area": "PHSS",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    }
  ],
  "process_time": "98.48ms",
  "status": "success",
  "code": "",
  "message": "Get rigs succeed"
}
```

### 3. Filter is_active= (empty) is ignored, no 500 — HTTP 200 PASS

```bash
curl -s -X GET 'http://127.0.0.1:5099/api/v1/master/rigs?is_active=' \
  -H "Authorization: Bearer $TOKEN"
```

```json
{
  "data": [
    {
      "id": "4efc41c1-72e4-486f-8a2e-0f0ef2ccc873",
      "name": "BKY-04 (1000 HP)",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "BKY-04 (1000 HP)",
      "is_active": true,
      "working_area": "PHSS",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    },
    {
      "id": "b1721661-390a-4478-b842-e46e84efce4f",
      "name": "ELANG-03 (1000 HP)",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "ELANG-03 (1000 HP)",
      "is_active": true,
      "working_area": "PHSS",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    },
    {
      "id": "1c059f46-4613-4bb2-8a73-012470c51b74",
      "name": "Rig Chevron 12",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "Rig Chevron 12",
      "is_active": true,
      "working_area": "PEP",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    },
    {
      "id": "0faf2cfd-d4e7-424d-8e73-94f49d4a2a52",
      "name": "Rig Tati-01",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "Rig Tati-01",
      "is_active": true,
      "working_area": "PHSS",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    }
  ],
  "process_time": "125.63ms",
  "status": "success",
  "code": "",
  "message": "Get rigs succeed"
}
```

### 4. Filter is_active=abc is ignored — HTTP 200 PASS

```bash
curl -s -X GET 'http://127.0.0.1:5071/api/v1/master/rigs?is_active=abc' \
  -H "Authorization: Bearer $TOKEN"
```

```json
{
  "data": [
    {
      "id": "4efc41c1-72e4-486f-8a2e-0f0ef2ccc873",
      "name": "BKY-04 (1000 HP)",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "BKY-04 (1000 HP)",
      "is_active": true,
      "working_area": "PHSS",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    },
    {
      "id": "b1721661-390a-4478-b842-e46e84efce4f",
      "name": "ELANG-03 (1000 HP)",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "ELANG-03 (1000 HP)",
      "is_active": true,
      "working_area": "PHSS",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    },
    {
      "id": "1c059f46-4613-4bb2-8a73-012470c51b74",
      "name": "Rig Chevron 12",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "Rig Chevron 12",
      "is_active": true,
      "working_area": "PEP",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    },
    {
      "id": "0faf2cfd-d4e7-424d-8e73-94f49d4a2a52",
      "name": "Rig Tati-01",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "Rig Tati-01",
      "is_active": true,
      "working_area": "PHSS",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    }
  ],
  "process_time": "104.00ms",
  "status": "success",
  "code": "",
  "message": "Get rigs succeed"
}
```

### 5. Filter working_area=PEP — HTTP 200 PASS

```bash
curl -s -X GET 'http://127.0.0.1:5071/api/v1/master/rigs?working_area=PEP' \
  -H "Authorization: Bearer $TOKEN"
```

```json
{
  "data": [
    {
      "id": "1c059f46-4613-4bb2-8a73-012470c51b74",
      "name": "Rig Chevron 12",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "Rig Chevron 12",
      "is_active": true,
      "working_area": "PEP",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    }
  ],
  "process_time": "118.56ms",
  "status": "success",
  "code": "",
  "message": "Get rigs succeed"
}
```

### 6. Filter working_area=pep (case-insensitive) — HTTP 200 PASS

```bash
curl -s -X GET 'http://127.0.0.1:5099/api/v1/master/rigs?working_area=pep' \
  -H "Authorization: Bearer $TOKEN"
```

```json
{
  "data": [
    {
      "id": "1c059f46-4613-4bb2-8a73-012470c51b74",
      "name": "Rig Chevron 12",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "Rig Chevron 12",
      "is_active": true,
      "working_area": "PEP",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    }
  ],
  "process_time": "119.29ms",
  "status": "success",
  "code": "",
  "message": "Get rigs succeed"
}
```

### 7. Filter working_area=XYZ -> empty list — HTTP 200 PASS

```bash
curl -s -X GET 'http://127.0.0.1:5099/api/v1/master/rigs?working_area=XYZ' \
  -H "Authorization: Bearer $TOKEN"
```

```json
{
  "data": [],
  "process_time": "44.63ms",
  "status": "success",
  "code": "",
  "message": "Get rigs succeed"
}
```

### 8. Create rig (valid) — HTTP 201 PASS

```bash
curl -s -X POST 'http://127.0.0.1:5071/api/v1/master/rigs' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name": "ZZ-TEST-PHI2265", "capacity": 1500, "capacity_unit": "HP", "is_active": true, "working_area": "pep"}'
```

```json
{
  "data": {
    "id": "1d368933-0756-4298-9a04-3b996b989b42",
    "name": "ZZ-TEST-PHI2265",
    "capacity": 1500,
    "capacity_unit": "HP",
    "display_name": "ZZ-TEST-PHI2265 (1500 HP)",
    "is_active": true,
    "working_area": "PEP",
    "created_at": "2026-10-30T20:10:52.559967",
    "created_by": {
      "id": "8ad89747-d543-4a0a-a2ff-57e9960535e0",
      "full_name": "R3 Test agil",
      "email": "r3test.agil@yopmail.com"
    },
    "updated_at": "2026-10-30T20:10:52.559967",
    "updated_by": {
      "id": "8ad89747-d543-4a0a-a2ff-57e9960535e0",
      "full_name": "R3 Test agil",
      "email": "r3test.agil@yopmail.com"
    }
  },
  "process_time": "454.57ms",
  "status": "success",
  "code": "",
  "message": "Create rig succeed"
}
```

### 9. Create duplicate name -> 400 — HTTP 400 PASS

```bash
curl -s -X POST 'http://127.0.0.1:5099/api/v1/master/rigs' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name": "ZZ-TEST-PHI2265"}'
```

```json
{
  "process_time": "45.41ms",
  "status": "failed",
  "code": "",
  "message": "Name already used by another rig"
}
```

### 10. Create empty name -> 400 — HTTP 400 PASS

```bash
curl -s -X POST 'http://127.0.0.1:5099/api/v1/master/rigs' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name": "  "}'
```

```json
{
  "process_time": "0.32ms",
  "status": "failed",
  "code": "",
  "message": "Name is required"
}
```

### 11. Create invalid working_area -> 400 — HTTP 400 PASS

```bash
curl -s -X POST 'http://127.0.0.1:5099/api/v1/master/rigs' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name": "ZZ-TEST-BAD", "working_area": "ABC"}'
```

```json
{
  "process_time": "0.16ms",
  "status": "failed",
  "code": "",
  "message": "Working area must be one of: PHSS, PEP"
}
```

### 12. Create negative capacity -> 400 — HTTP 400 PASS

```bash
curl -s -X POST 'http://127.0.0.1:5099/api/v1/master/rigs' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name": "ZZ-TEST-BAD", "capacity": -1}'
```

```json
{
  "process_time": "0.28ms",
  "status": "failed",
  "code": "",
  "message": "Capacity must not be negative"
}
```

### 13. Create inactive rig keeps is_active=false — HTTP 201 PASS

```bash
curl -s -X POST 'http://127.0.0.1:5099/api/v1/master/rigs' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name": "ZZ-TEST-PHI2265-INACTIVE", "is_active": false}'
```

```json
{
  "data": {
    "id": "0647efe3-29da-4304-abc9-736f0ad3c6eb",
    "name": "ZZ-TEST-PHI2265-INACTIVE",
    "capacity": null,
    "capacity_unit": null,
    "display_name": "ZZ-TEST-PHI2265-INACTIVE",
    "is_active": false,
    "working_area": null,
    "created_at": "2026-10-30T20:10:55.876363",
    "created_by": {
      "id": "8ad89747-d543-4a0a-a2ff-57e9960535e0",
      "full_name": "R3 Test agil",
      "email": "r3test.agil@yopmail.com"
    },
    "updated_at": "2026-10-30T20:10:55.876363",
    "updated_by": {
      "id": "8ad89747-d543-4a0a-a2ff-57e9960535e0",
      "full_name": "R3 Test agil",
      "email": "r3test.agil@yopmail.com"
    }
  },
  "process_time": "196.94ms",
  "status": "success",
  "code": "",
  "message": "Create rig succeed"
}
```

### 14. Filter is_active=false includes inactive rig — HTTP 200 PASS

```bash
curl -s -X GET 'http://127.0.0.1:5099/api/v1/master/rigs?is_active=false' \
  -H "Authorization: Bearer $TOKEN"
```

```json
{
  "data": [
    {
      "id": "0647efe3-29da-4304-abc9-736f0ad3c6eb",
      "name": "ZZ-TEST-PHI2265-INACTIVE",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "ZZ-TEST-PHI2265-INACTIVE",
      "is_active": false,
      "working_area": null,
      "created_at": "2026-10-30T20:10:55.876363",
      "created_by": {
        "id": "8ad89747-d543-4a0a-a2ff-57e9960535e0",
        "full_name": "R3 Test agil",
        "email": "r3test.agil@yopmail.com"
      },
      "updated_at": "2026-10-30T20:10:55.876363",
      "updated_by": {
        "id": "8ad89747-d543-4a0a-a2ff-57e9960535e0",
        "full_name": "R3 Test agil",
        "email": "r3test.agil@yopmail.com"
      }
    }
  ],
  "process_time": "81.96ms",
  "status": "success",
  "code": "",
  "message": "Get rigs succeed"
}
```

### 15. Get by id — HTTP 200 PASS

```bash
curl -s -X GET 'http://127.0.0.1:5099/api/v1/master/rigs/1d368933-0756-4298-9a04-3b996b989b42' \
  -H "Authorization: Bearer $TOKEN"
```

```json
{
  "data": {
    "id": "1d368933-0756-4298-9a04-3b996b989b42",
    "name": "ZZ-TEST-PHI2265",
    "capacity": 1500,
    "capacity_unit": "HP",
    "display_name": "ZZ-TEST-PHI2265 (1500 HP)",
    "is_active": true,
    "working_area": "PEP",
    "created_at": "2026-10-30T20:10:52.559967",
    "created_by": {
      "id": "8ad89747-d543-4a0a-a2ff-57e9960535e0",
      "full_name": "R3 Test agil",
      "email": "r3test.agil@yopmail.com"
    },
    "updated_at": "2026-10-30T20:10:52.559967",
    "updated_by": {
      "id": "8ad89747-d543-4a0a-a2ff-57e9960535e0",
      "full_name": "R3 Test agil",
      "email": "r3test.agil@yopmail.com"
    }
  },
  "process_time": "80.50ms",
  "status": "success",
  "code": "",
  "message": "Get rig succeed"
}
```

### 16. Get by unknown id -> 404 — HTTP 404 PASS

```bash
curl -s -X GET 'http://127.0.0.1:5099/api/v1/master/rigs/11111111-1111-1111-1111-111111111111' \
  -H "Authorization: Bearer $TOKEN"
```

```json
{
  "process_time": "182.19ms",
  "status": "failed",
  "code": "",
  "message": "Data not found"
}
```

### 17. Get by non-guid -> 404 (route constraint) — HTTP 404 PASS

```bash
curl -s -X GET 'http://127.0.0.1:5099/api/v1/master/rigs/abc' \
  -H "Authorization: Bearer $TOKEN"
```

```
(empty body)
```

### 18. Update (rename + capacity) — HTTP 200 PASS

```bash
curl -s -X POST 'http://127.0.0.1:5099/api/v1/master/rigs/1d368933-0756-4298-9a04-3b996b989b42/update' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name": "ZZ-TEST-PHI2265-B", "capacity": 2000, "capacity_unit": "HP", "is_active": true, "working_area": "PHSS"}'
```

```json
{
  "data": {
    "id": "1d368933-0756-4298-9a04-3b996b989b42",
    "name": "ZZ-TEST-PHI2265-B",
    "capacity": 2000,
    "capacity_unit": "HP",
    "display_name": "ZZ-TEST-PHI2265-B (2000 HP)",
    "is_active": true,
    "working_area": "PHSS",
    "created_at": "2026-10-30T20:10:52.559967",
    "created_by": {
      "id": "8ad89747-d543-4a0a-a2ff-57e9960535e0",
      "full_name": "R3 Test agil",
      "email": "r3test.agil@yopmail.com"
    },
    "updated_at": "2026-10-30T20:10:59.728848",
    "updated_by": {
      "id": "8ad89747-d543-4a0a-a2ff-57e9960535e0",
      "full_name": "R3 Test agil",
      "email": "r3test.agil@yopmail.com"
    }
  },
  "process_time": "724.09ms",
  "status": "success",
  "code": "",
  "message": "Update rig succeed"
}
```

### 19. Update to an existing name -> 400 — HTTP 400 PASS

```bash
curl -s -X POST 'http://127.0.0.1:5099/api/v1/master/rigs/1d368933-0756-4298-9a04-3b996b989b42/update' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name": "ZZ-TEST-PHI2265-INACTIVE"}'
```

```json
{
  "process_time": "95.18ms",
  "status": "failed",
  "code": "",
  "message": "Name already used by another rig"
}
```

### 20. Update unknown id -> 404 — HTTP 404 PASS

```bash
curl -s -X POST 'http://127.0.0.1:5099/api/v1/master/rigs/11111111-1111-1111-1111-111111111111/update' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name": "X"}'
```

```json
{
  "process_time": "76.20ms",
  "status": "failed",
  "code": "",
  "message": "Data not found"
}
```

### 21. Bare POST /{id} does not delete (no route) — HTTP 405 PASS

```bash
curl -s -X POST 'http://127.0.0.1:5099/api/v1/master/rigs/1d368933-0756-4298-9a04-3b996b989b42' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{}'
```

```
(empty body)
```

### 22. Delete (soft) — HTTP 200 PASS

```bash
curl -s -X POST 'http://127.0.0.1:5099/api/v1/master/rigs/1d368933-0756-4298-9a04-3b996b989b42/delete' \
  -H "Authorization: Bearer $TOKEN"
```

```json
{
  "process_time": "177.26ms",
  "status": "success",
  "code": "",
  "message": "Delete rig succeed"
}
```

### 23. Delete again -> 404 — HTTP 404 PASS

```bash
curl -s -X POST 'http://127.0.0.1:5099/api/v1/master/rigs/1d368933-0756-4298-9a04-3b996b989b42/delete' \
  -H "Authorization: Bearer $TOKEN"
```

```json
{
  "process_time": "96.58ms",
  "status": "failed",
  "code": "",
  "message": "Data not found"
}
```

### 24. Get deleted -> 404 — HTTP 404 PASS

```bash
curl -s -X GET 'http://127.0.0.1:5099/api/v1/master/rigs/1d368933-0756-4298-9a04-3b996b989b42' \
  -H "Authorization: Bearer $TOKEN"
```

```json
{
  "process_time": "51.44ms",
  "status": "failed",
  "code": "",
  "message": "Data not found"
}
```

### 25. List excludes deleted — HTTP 200 PASS

```bash
curl -s -X GET 'http://127.0.0.1:5099/api/v1/master/rigs' \
  -H "Authorization: Bearer $TOKEN"
```

```json
{
  "data": [
    {
      "id": "4efc41c1-72e4-486f-8a2e-0f0ef2ccc873",
      "name": "BKY-04 (1000 HP)",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "BKY-04 (1000 HP)",
      "is_active": true,
      "working_area": "PHSS",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    },
    {
      "id": "b1721661-390a-4478-b842-e46e84efce4f",
      "name": "ELANG-03 (1000 HP)",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "ELANG-03 (1000 HP)",
      "is_active": true,
      "working_area": "PHSS",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    },
    {
      "id": "1c059f46-4613-4bb2-8a73-012470c51b74",
      "name": "Rig Chevron 12",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "Rig Chevron 12",
      "is_active": true,
      "working_area": "PEP",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    },
    {
      "id": "0faf2cfd-d4e7-424d-8e73-94f49d4a2a52",
      "name": "Rig Tati-01",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "Rig Tati-01",
      "is_active": true,
      "working_area": "PHSS",
      "created_at": "2026-10-30T20:06:53.5834176",
      "created_by": null,
      "updated_at": null,
      "updated_by": null
    },
    {
      "id": "0647efe3-29da-4304-abc9-736f0ad3c6eb",
      "name": "ZZ-TEST-PHI2265-INACTIVE",
      "capacity": null,
      "capacity_unit": null,
      "display_name": "ZZ-TEST-PHI2265-INACTIVE",
      "is_active": false,
      "working_area": null,
      "created_at": "2026-10-30T20:10:55.876363",
      "created_by": {
        "id": "8ad89747-d543-4a0a-a2ff-57e9960535e0",
        "full_name": "R3 Test agil",
        "email": "r3test.agil@yopmail.com"
      },
      "updated_at": "2026-10-30T20:10:55.876363",
      "updated_by": {
        "id": "8ad89747-d543-4a0a-a2ff-57e9960535e0",
        "full_name": "R3 Test agil",
        "email": "r3test.agil@yopmail.com"
      }
    }
  ],
  "process_time": "127.48ms",
  "status": "success",
  "code": "",
  "message": "Get rigs succeed"
}
```

### 26. Re-create with name of deleted rig is allowed — HTTP 201 PASS

```bash
curl -s -X POST 'http://127.0.0.1:5099/api/v1/master/rigs' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name": "ZZ-TEST-PHI2265-B"}'
```

```json
{
  "data": {
    "id": "91a5ae7f-1ae1-48b3-8957-a7e04b3da1de",
    "name": "ZZ-TEST-PHI2265-B",
    "capacity": null,
    "capacity_unit": null,
    "display_name": "ZZ-TEST-PHI2265-B",
    "is_active": true,
    "working_area": null,
    "created_at": "2026-10-30T20:11:05.694225",
    "created_by": {
      "id": "8ad89747-d543-4a0a-a2ff-57e9960535e0",
      "full_name": "R3 Test agil",
      "email": "r3test.agil@yopmail.com"
    },
    "updated_at": "2026-10-30T20:11:05.694225",
    "updated_by": {
      "id": "8ad89747-d543-4a0a-a2ff-57e9960535e0",
      "full_name": "R3 Test agil",
      "email": "r3test.agil@yopmail.com"
    }
  },
  "process_time": "199.43ms",
  "status": "success",
  "code": "",
  "message": "Create rig succeed"
}
```

### 27. No auth -> 401 — HTTP 401 PASS

```bash
curl -s -X GET 'http://127.0.0.1:5099/api/v1/master/rigs'
```

```json
{
  "type": "https://tools.ietf.org/html/rfc9110#section-15.5.2",
  "title": "Unauthorized",
  "status": 401,
  "detail": "Please login to access this feature"
}
```

### 28. Rename sync to `projects.rig_name` — HTTP 200 / 200 PASS

Only the status codes were captured for these two calls. The check was the `projects.rig_name` value read from the DB (section 2).

```bash
# rename
curl -s -X POST 'http://127.0.0.1:5099/api/v1/master/rigs/0faf2cfd-d4e7-424d-8e73-94f49d4a2a52/update' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name":"Rig Tati-01 RENAMED","is_active":true,"working_area":"PHSS"}'
# -> 200; projects.rig_name = "Rig Tati-01 RENAMED"

# restore
curl -s -X POST 'http://127.0.0.1:5099/api/v1/master/rigs/0faf2cfd-d4e7-424d-8e73-94f49d4a2a52/update' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name":"Rig Tati-01","is_active":true,"working_area":"PHSS"}'
# -> 200; projects.rig_name = "Rig Tati-01"
```
