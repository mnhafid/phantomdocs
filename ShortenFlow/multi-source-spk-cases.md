# [SHORTENFLOW] Multi Source SPK — test data and executed results

Executed 2026-09-07 18:53 against `http://0.0.0.0:5071` (worktree `shortenflow-multi-source-spk` build) on the dev DB, as `r3test.agil`. Fixture: [multi-source-spk-data.sql](multi-source-spk-data.sql) (loaded fresh before this run). Only the **submit / draft / reset** steps were executed. Create SPK (012–014) and every input-progress case (015–019) are data only, per instruction.

## Fixture ids


## Summary

| Case | Title | HTTP per step | Expected |
|---|---|---|---|
| 001 | One task, multiple contract BoQ via select manual (same contract) | 200 / 200 | submit 200, 200; v2 list shows 3 rows for T001, MSX.1.1. volume 6 |
| 002 | One task, multiple contract BoQ via bulk upload (different contract) | 200 / 200 | submit 200, 200; v2 list shows 4 rows, 2 with contract X and 2 with contract Y |
| 003 | Multiple contract BoQ after reset | 200 / 200 / 200 / 200 | submit 200, 200; reset 200; submit 200; v2 shows MSY.1.3. and MSX.1.2. only |
| 004 | Submit with insufficient estimated cost | 400 | 400 "Estimated cost insufficient : remaining 5000000"; no row written |
| 005 | Save as draft with insufficient estimated cost | 200 / 200 | draft save 200 (differs from the sheet by decision Q11); draft read returns the payload |
| 006 | Select approve-inactive contract (Z, ended 30-06-2026) | 400 | 400 "Contract Invalid : contract ended on 30-06-2026" |
| 007 | Select draft contract (D) | 400 | 400 "Contract Invalid : status is draft" |
| 008 | Select on-hold contract (H) | 400 | 400 "Contract Invalid : status is on hold" |
| 009 | Select finished contract (F) | 400 | 400 "Contract Invalid : status is finished" |
| 010 | Multiple contract BoQ, save to draft | 200 / 200 | draft save 200; draft read 200 with contract_name of X and both rows |
| 011 | Create multiple contract BoQ from saved draft | 200 / 200 / 200 | draft 200; submit 200; draft read returns data null (consumed) |
| 012 | Create SPK with SPK BoQ, same contract — submit prep only | 200 | submit 200; then by hand: picker eligible_for_spk=true&contract_id=X shows T012, Create SPK links both rows |
| 013 | Create SPK with SPK BoQ, different contract — submit prep only | 200 / 200 | submit 200, 200; then by hand: Create SPK on Y links MSY.1.1. and MSY.1.3., spk_value 220,000,000 |
| 014 | Create SPK with insufficient contract value — submit prep only | 200 | submit 200; then by hand: Create SPK fails "Contract value remaining not sufficient to create new SPK" |
| 015-019 | Input progress with several SPKs — data only, NOT executed | 200 / 200 | submit 200, 200; everything after that is by hand |

- Project: `5f000001-0000-4000-8000-000000000004`
- Contract X: `5f000001-0000-4000-8000-000000000002`
- Contract Y: `5f000001-0000-4000-8000-000000000005`
- Contract Z: `5f000001-0000-4000-8000-000000000008`
- Contract D: `5f000001-0000-4000-8000-00000000000b`
- Contract H: `5f000001-0000-4000-8000-00000000000e`
- Contract F: `5f000001-0000-4000-8000-000000000011`
- Contract S: `5f000001-0000-4000-8000-000000000014`
- Task T001: `5f000001-0000-4000-8000-000000000301`
- Task T002: `5f000001-0000-4000-8000-000000000302`
- Task T003: `5f000001-0000-4000-8000-000000000303`
- Task T004: `5f000001-0000-4000-8000-000000000304`
- Task T005: `5f000001-0000-4000-8000-000000000305`
- Task T006: `5f000001-0000-4000-8000-000000000306`
- Task T007: `5f000001-0000-4000-8000-000000000307`
- Task T008: `5f000001-0000-4000-8000-000000000308`
- Task T009: `5f000001-0000-4000-8000-000000000309`
- Task T010: `5f000001-0000-4000-8000-000000000310`
- Task T011: `5f000001-0000-4000-8000-000000000311`
- Task T012: `5f000001-0000-4000-8000-000000000312`
- Task T013: `5f000001-0000-4000-8000-000000000313`
- Task T014: `5f000001-0000-4000-8000-000000000314`
- Task T015: `5f000001-0000-4000-8000-000000000315`

Unit ids used in payloads: Lot=`006dd80b-1994-40cb-94b1-7a39d66f12e5`, m=`d7190ea2-d2c1-407a-b45f-6e710bb3e8cc`, m3=`bf0e706b-7fcd-4761-bb2f-3352181e6760`, Set=`60f87a3e-e1f6-4ef5-86b4-e19e584a2451`, Unit=`d93aef0a-2efc-47ac-8322-b95774bcfbe9`


## Case 001 — One task, multiple contract BoQ via select manual (same contract)

- Type: Positif · Task: `5f000001-0000-4000-8000-000000000301`
- Notes: Two submits on contract X. Second submit re-picks MSX.1.1. with a new volume and adds MSX.2.1.: expect the first row updated in place, MSX.1.2. kept, MSX.2.1. added (3 rows).
- Expected: submit 200, 200; v2 list shows 3 rows for T001, MSX.1.1. volume 6

### Step 1: `POST /api/v1/projects/tasks/boqs/submit`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000301",
  "contract_id": "5f000001-0000-4000-8000-000000000002",
  "spk_boqs": [
    {
      "code": "MSX.1.1.",
      "description": "Mobilisasi peralatan berat",
      "kind": "Upah",
      "unit_id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
      "volume": 4,
      "unit_price": 10000000.0,
      "total_price": 40000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000102",
      "type": "inline",
      "remarks": ""
    },
    {
      "code": "MSX.1.2.",
      "description": "Pembersihan dan perataan lahan",
      "kind": "Upah",
      "unit_id": "bf0e706b-7fcd-4761-bb2f-3352181e6760",
      "volume": 100,
      "unit_price": 150000.0,
      "total_price": 15000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000103",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `200`:
```json
{
  "process_time": "1327.00ms",
  "status": "success",
  "code": "",
  "message": "Set project task boq succeed"
}
```

### Step 2: `POST /api/v1/projects/tasks/boqs/submit`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000301",
  "contract_id": "5f000001-0000-4000-8000-000000000002",
  "spk_boqs": [
    {
      "code": "MSX.1.1.",
      "description": "Mobilisasi peralatan berat",
      "kind": "Upah",
      "unit_id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
      "volume": 6,
      "unit_price": 10000000.0,
      "total_price": 60000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000102",
      "type": "inline",
      "remarks": "volume revised"
    },
    {
      "code": "MSX.2.1.",
      "description": "Pemasangan pompa transfer 50 HP",
      "kind": "Material",
      "unit_id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
      "volume": 1,
      "unit_price": 60000000.0,
      "total_price": 60000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000105",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `200`:
```json
{
  "process_time": "1372.00ms",
  "status": "success",
  "code": "",
  "message": "Set project task boq succeed"
}
```


## Case 002 — One task, multiple contract BoQ via bulk upload (different contract)

- Type: Positif · Task: `5f000001-0000-4000-8000-000000000302`
- Notes: The upload UI ends in the same submit. Submit X lines, then Y lines: expect rows from both contracts side by side, each row carrying its own contract on v2.
- Expected: submit 200, 200; v2 list shows 4 rows, 2 with contract X and 2 with contract Y

### Step 1: `POST /api/v1/projects/tasks/boqs/submit`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000302",
  "contract_id": "5f000001-0000-4000-8000-000000000002",
  "spk_boqs": [
    {
      "code": "MSX.1.1.",
      "description": "Mobilisasi peralatan berat",
      "kind": "Upah",
      "unit_id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
      "volume": 2,
      "unit_price": 10000000.0,
      "total_price": 20000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000102",
      "type": "inline",
      "remarks": ""
    },
    {
      "code": "MSX.2.2.",
      "description": "Pemipaan 6 inch sch 40",
      "kind": "Material",
      "unit_id": "d7190ea2-d2c1-407a-b45f-6e710bb3e8cc",
      "volume": 100,
      "unit_price": 600000.0,
      "total_price": 60000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000106",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `200`:
```json
{
  "process_time": "864.00ms",
  "status": "success",
  "code": "",
  "message": "Set project task boq succeed"
}
```

### Step 2: `POST /api/v1/projects/tasks/boqs/submit`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000302",
  "contract_id": "5f000001-0000-4000-8000-000000000005",
  "spk_boqs": [
    {
      "code": "MSY.1.1.",
      "description": "Panel distribusi 400 A",
      "kind": "Material",
      "unit_id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
      "volume": 1,
      "unit_price": 80000000.0,
      "total_price": 80000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000112",
      "type": "inline",
      "remarks": ""
    },
    {
      "code": "MSY.1.2.",
      "description": "Kabel NYY 4x50 mm2",
      "kind": "Material",
      "unit_id": "d7190ea2-d2c1-407a-b45f-6e710bb3e8cc",
      "volume": 500,
      "unit_price": 80000.0,
      "total_price": 40000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000113",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `200`:
```json
{
  "process_time": "1559.00ms",
  "status": "success",
  "code": "",
  "message": "Set project task boq succeed"
}
```


## Case 003 — Multiple contract BoQ after reset

- Type: Positif · Task: `5f000001-0000-4000-8000-000000000303`
- Notes: Submit X and Y, reset contract X only, submit X again with a different line: expect Y rows untouched, old X row gone, new X row present.
- Expected: submit 200, 200; reset 200; submit 200; v2 shows MSY.1.3. and MSX.1.2. only

### Step 1: `POST /api/v1/projects/tasks/boqs/submit`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000303",
  "contract_id": "5f000001-0000-4000-8000-000000000002",
  "spk_boqs": [
    {
      "code": "MSX.1.1.",
      "description": "Mobilisasi peralatan berat",
      "kind": "Upah",
      "unit_id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
      "volume": 3,
      "unit_price": 10000000.0,
      "total_price": 30000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000102",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `200`:
```json
{
  "process_time": "795.00ms",
  "status": "success",
  "code": "",
  "message": "Set project task boq succeed"
}
```

### Step 2: `POST /api/v1/projects/tasks/boqs/submit`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000303",
  "contract_id": "5f000001-0000-4000-8000-000000000005",
  "spk_boqs": [
    {
      "code": "MSY.1.3.",
      "description": "Instalasi dan commissioning",
      "kind": "Upah",
      "unit_id": "006dd80b-1994-40cb-94b1-7a39d66f12e5",
      "volume": 1,
      "unit_price": 60000000.0,
      "total_price": 60000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000114",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `200`:
```json
{
  "process_time": "1261.00ms",
  "status": "success",
  "code": "",
  "message": "Set project task boq succeed"
}
```

### Step 3: `GET /api/v1/projects/tasks/5f000001-0000-4000-8000-000000000303/reset-boq?contract_id=5f000001-0000-4000-8000-000000000002`

Response `200`:
```json
{
  "process_time": "1624.00ms",
  "status": "success",
  "code": "",
  "message": "Reset project task BoQ succeed",
  "data": null
}
```

### Step 4: `POST /api/v1/projects/tasks/boqs/submit`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000303",
  "contract_id": "5f000001-0000-4000-8000-000000000002",
  "spk_boqs": [
    {
      "code": "MSX.1.2.",
      "description": "Pembersihan dan perataan lahan",
      "kind": "Upah",
      "unit_id": "bf0e706b-7fcd-4761-bb2f-3352181e6760",
      "volume": 200,
      "unit_price": 150000.0,
      "total_price": 30000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000103",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `200`:
```json
{
  "process_time": "942.00ms",
  "status": "success",
  "code": "",
  "message": "Set project task boq succeed"
}
```


## Case 004 — Submit with insufficient estimated cost

- Type: Negatif · Task: `5f000001-0000-4000-8000-000000000304`
- Notes: Task budget 5,000,000; cheapest line MSX.3. is 25,000,000.
- Expected: 400 "Estimated cost insufficient : remaining 5000000"; no row written

### Step 1: `POST /api/v1/projects/tasks/boqs/submit`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000304",
  "contract_id": "5f000001-0000-4000-8000-000000000002",
  "spk_boqs": [
    {
      "code": "MSX.3.",
      "description": "Dokumentasi dan as-built drawing",
      "kind": "Transport",
      "unit_id": "60f87a3e-e1f6-4ef5-86b4-e19e584a2451",
      "volume": 1,
      "unit_price": 25000000.0,
      "total_price": 25000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000107",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `400`:
```json
{
  "process_time": "436.00ms",
  "status": "failed",
  "code": "",
  "message": "Estimated cost insufficient : remaining 5000000"
}
```


## Case 005 — Save as draft with insufficient estimated cost

- Type: Negatif · Task: `5f000001-0000-4000-8000-000000000305`
- Notes: Same payload saved as a draft. DECISION Q11: the draft save is not validated, so this returns 200. The sheet expects a block; the FE has the remaining amount on the draft read to block it client-side.
- Expected: draft save 200 (differs from the sheet by decision Q11); draft read returns the payload

### Step 1: `POST /api/v1/projects/tasks/boqs/draft`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000305",
  "contract_id": "5f000001-0000-4000-8000-000000000002",
  "spk_boqs": [
    {
      "code": "MSX.3.",
      "description": "Dokumentasi dan as-built drawing",
      "kind": "Transport",
      "unit_id": "60f87a3e-e1f6-4ef5-86b4-e19e584a2451",
      "volume": 1,
      "unit_price": 25000000.0,
      "total_price": 25000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000107",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `200`:
```json
{
  "process_time": "275.00ms",
  "status": "success",
  "code": "",
  "message": "Save project task boq draft succeed"
}
```

### Step 2: `GET /api/v1/projects/tasks/boqs/draft?project_task_id=5f000001-0000-4000-8000-000000000305`

Response `200`:
```json
{
  "process_time": "540.00ms",
  "status": "success",
  "code": "",
  "message": "Get project task boq draft succeed",
  "data": {
    "project_task_id": "5f000001-0000-4000-8000-000000000305",
    "contract_id": "5f000001-0000-4000-8000-000000000002",
    "payload": {
      "project_task_id": "5f000001-0000-4000-8000-000000000305",
      "contract_id": "5f000001-0000-4000-8000-000000000002",
      "spk_boqs": [
        {
          "code": "MSX.3.",
          "description": "Dokumentasi dan as-built drawing",
          "kind": "Transport",
          "unit_id": "60f87a3e-e1f6-4ef5-86b4-e19e584a2451",
          "volume": 1,
          "unit_price": 25000000.0,
          "total_price": 25000000.0,
          "start_date": "15-09-2026",
          "end_date": "31-12-2026",
          "boq_detail_id": "5f000001-0000-4000-8000-000000000107",
          "type": "inline",
          "remarks": "",
          "unit": {
            "id": "60f87a3e-e1f6-4ef5-86b4-e19e584a2451",
            "name": "Set"
          },
          "id": "5f000001-0000-4000-8000-000000000107",
          "parent_id": ""
        }
      ]
    },
    "start_date": "15-09-2026",
    "end_date": "31-12-2026",
    "created_at": "07-09-2026 18:54:09",
    "updated_at": null,
    "contract_name": "Multi Source SPK \u2014 Kontrak X (aktif)",
    "contract_value": "2000000000",
    "spk_remaining": "2000000000",
    "contract": {
      "id": "5f000001-0000-4000-8000-000000000002",
      "contract_no": "MSSPK/X/2026",
      "contract_title": "Multi Source SPK \u2014 Kontrak X (aktif)",
      "contractor_name": "PT Multi Source SPK Fixture",
      "contract_value": "2000000000",
      "autogenerated_spk_number": true,
      "retention_percentage": "10.00"
    },
    "spk_type": null,
    "spk": null
  }
}
```


## Case 006 — Select approve-inactive contract (Z, ended 30-06-2026)

- Type: Negatif · Task: `5f000001-0000-4000-8000-000000000306`
- Notes: Contract Z is approved but its contract_end_date has passed.
- Expected: 400 "Contract Invalid : contract ended on 30-06-2026"

### Step 1: `POST /api/v1/projects/tasks/boqs/submit`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000306",
  "contract_id": "5f000001-0000-4000-8000-000000000008",
  "spk_boqs": [
    {
      "code": "MSZ.1.1.",
      "description": "Pondasi beton K-300",
      "kind": "Material",
      "unit_id": "bf0e706b-7fcd-4761-bb2f-3352181e6760",
      "volume": 10,
      "unit_price": 2500000.0,
      "total_price": 25000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000122",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `400`:
```json
{
  "process_time": "167.00ms",
  "status": "failed",
  "code": "",
  "message": "Contract Invalid : contract ended on 30-06-2026"
}
```


## Case 007 — Select draft contract (D)

- Type: Negatif · Task: `5f000001-0000-4000-8000-000000000307`
- Notes: Sheet marks it Positif but expects failure.
- Expected: 400 "Contract Invalid : status is draft"

### Step 1: `POST /api/v1/projects/tasks/boqs/submit`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000307",
  "contract_id": "5f000001-0000-4000-8000-00000000000b",
  "spk_boqs": [
    {
      "code": "MSD.1.1.",
      "description": "Pengadaan valve gate 8 inch",
      "kind": "Material",
      "unit_id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
      "volume": 1,
      "unit_price": 10000000.0,
      "total_price": 10000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000132",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `400`:
```json
{
  "process_time": "75.00ms",
  "status": "failed",
  "code": "",
  "message": "Contract Invalid : status is draft"
}
```


## Case 008 — Select on-hold contract (H)

- Type: Negatif · Task: `5f000001-0000-4000-8000-000000000308`
- Expected: 400 "Contract Invalid : status is on hold"

### Step 1: `POST /api/v1/projects/tasks/boqs/submit`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000308",
  "contract_id": "5f000001-0000-4000-8000-00000000000e",
  "spk_boqs": [
    {
      "code": "MSH.1.1.",
      "description": "Pengecatan tangki T-101",
      "kind": "Upah",
      "unit_id": "d7190ea2-d2c1-407a-b45f-6e710bb3e8cc",
      "volume": 100,
      "unit_price": 50000.0,
      "total_price": 5000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000142",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `400`:
```json
{
  "process_time": "99.00ms",
  "status": "failed",
  "code": "",
  "message": "Contract Invalid : status is on hold"
}
```


## Case 009 — Select finished contract (F)

- Type: Negatif · Task: `5f000001-0000-4000-8000-000000000309`
- Expected: 400 "Contract Invalid : status is finished"

### Step 1: `POST /api/v1/projects/tasks/boqs/submit`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000309",
  "contract_id": "5f000001-0000-4000-8000-000000000011",
  "spk_boqs": [
    {
      "code": "MSF.1.1.",
      "description": "Perbaikan jalan akses",
      "kind": "Upah",
      "unit_id": "006dd80b-1994-40cb-94b1-7a39d66f12e5",
      "volume": 1,
      "unit_price": 15000000.0,
      "total_price": 15000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000152",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `400`:
```json
{
  "process_time": "88.00ms",
  "status": "failed",
  "code": "",
  "message": "Contract Invalid : status is finished"
}
```


## Case 010 — Multiple contract BoQ, save to draft

- Type: Positif · Task: `5f000001-0000-4000-8000-000000000310`
- Notes: Draft with X and Y rows in one payload, then read it back.
- Expected: draft save 200; draft read 200 with contract_name of X and both rows

### Step 1: `POST /api/v1/projects/tasks/boqs/draft`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000310",
  "contract_id": "5f000001-0000-4000-8000-000000000002",
  "spk_boqs": [
    {
      "code": "MSX.1.1.",
      "description": "Mobilisasi peralatan berat",
      "kind": "Upah",
      "unit_id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
      "volume": 1,
      "unit_price": 10000000.0,
      "total_price": 10000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000102",
      "type": "inline",
      "remarks": ""
    },
    {
      "code": "MSY.1.1.",
      "description": "Panel distribusi 400 A",
      "kind": "Material",
      "unit_id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
      "volume": 1,
      "unit_price": 80000000.0,
      "total_price": 80000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000112",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `200`:
```json
{
  "process_time": "211.00ms",
  "status": "success",
  "code": "",
  "message": "Save project task boq draft succeed"
}
```

### Step 2: `GET /api/v1/projects/tasks/boqs/draft?project_task_id=5f000001-0000-4000-8000-000000000310`

Response `200`:
```json
{
  "process_time": "715.00ms",
  "status": "success",
  "code": "",
  "message": "Get project task boq draft succeed",
  "data": {
    "project_task_id": "5f000001-0000-4000-8000-000000000310",
    "contract_id": "5f000001-0000-4000-8000-000000000002",
    "payload": {
      "project_task_id": "5f000001-0000-4000-8000-000000000310",
      "contract_id": "5f000001-0000-4000-8000-000000000002",
      "spk_boqs": [
        {
          "code": "MSX.1.1.",
          "description": "Mobilisasi peralatan berat",
          "kind": "Upah",
          "unit_id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
          "volume": 1,
          "unit_price": 10000000.0,
          "total_price": 10000000.0,
          "start_date": "15-09-2026",
          "end_date": "31-12-2026",
          "boq_detail_id": "5f000001-0000-4000-8000-000000000102",
          "type": "inline",
          "remarks": "",
          "unit": {
            "id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
            "name": "Unit"
          },
          "id": "5f000001-0000-4000-8000-000000000102",
          "parent_id": "5f000001-0000-4000-8000-000000000101"
        },
        {
          "code": "MSY.1.1.",
          "description": "Panel distribusi 400 A",
          "kind": "Material",
          "unit_id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
          "volume": 1,
          "unit_price": 80000000.0,
          "total_price": 80000000.0,
          "start_date": "15-09-2026",
          "end_date": "31-12-2026",
          "boq_detail_id": "5f000001-0000-4000-8000-000000000112",
          "type": "inline",
          "remarks": "",
          "unit": {
            "id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
            "name": "Unit"
          },
          "id": "",
          "parent_id": ""
        }
      ]
    },
    "start_date": "15-09-2026",
    "end_date": "31-12-2026",
    "created_at": "07-09-2026 18:54:12",
    "updated_at": null,
    "contract_name": "Multi Source SPK \u2014 Kontrak X (aktif)",
    "contract_value": "2000000000",
    "spk_remaining": "2000000000",
    "contract": {
      "id": "5f000001-0000-4000-8000-000000000002",
      "contract_no": "MSSPK/X/2026",
      "contract_title": "Multi Source SPK \u2014 Kontrak X (aktif)",
      "contractor_name": "PT Multi Source SPK Fixture",
      "contract_value": "2000000000",
      "autogenerated_spk_number": true,
      "retention_percentage": "10.00"
    },
    "spk_type": null,
    "spk": null
  }
}
```


## Case 011 — Create multiple contract BoQ from saved draft

- Type: Positif · Task: `5f000001-0000-4000-8000-000000000311`
- Notes: Save a draft on X, then submit the same rows: submit consumes the draft.
- Expected: draft 200; submit 200; draft read returns data null (consumed)

### Step 1: `POST /api/v1/projects/tasks/boqs/draft`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000311",
  "contract_id": "5f000001-0000-4000-8000-000000000002",
  "spk_boqs": [
    {
      "code": "MSX.2.1.",
      "description": "Pemasangan pompa transfer 50 HP",
      "kind": "Material",
      "unit_id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
      "volume": 1,
      "unit_price": 60000000.0,
      "total_price": 60000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000105",
      "type": "inline",
      "remarks": ""
    },
    {
      "code": "MSX.2.2.",
      "description": "Pemipaan 6 inch sch 40",
      "kind": "Material",
      "unit_id": "d7190ea2-d2c1-407a-b45f-6e710bb3e8cc",
      "volume": 50,
      "unit_price": 600000.0,
      "total_price": 30000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000106",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `200`:
```json
{
  "process_time": "274.00ms",
  "status": "success",
  "code": "",
  "message": "Save project task boq draft succeed"
}
```

### Step 2: `POST /api/v1/projects/tasks/boqs/submit`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000311",
  "contract_id": "5f000001-0000-4000-8000-000000000002",
  "spk_boqs": [
    {
      "code": "MSX.2.1.",
      "description": "Pemasangan pompa transfer 50 HP",
      "kind": "Material",
      "unit_id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
      "volume": 1,
      "unit_price": 60000000.0,
      "total_price": 60000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000105",
      "type": "inline",
      "remarks": ""
    },
    {
      "code": "MSX.2.2.",
      "description": "Pemipaan 6 inch sch 40",
      "kind": "Material",
      "unit_id": "d7190ea2-d2c1-407a-b45f-6e710bb3e8cc",
      "volume": 50,
      "unit_price": 600000.0,
      "total_price": 30000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000106",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `200`:
```json
{
  "process_time": "991.00ms",
  "status": "success",
  "code": "",
  "message": "Set project task boq succeed"
}
```

### Step 3: `GET /api/v1/projects/tasks/boqs/draft?project_task_id=5f000001-0000-4000-8000-000000000311`

Response `200`:
```json
{
  "process_time": "48.00ms",
  "status": "success",
  "code": "",
  "message": "Get project task boq draft succeed",
  "data": null
}
```


## Case 012 — Create SPK with SPK BoQ, same contract — submit prep only

- Type: Positif · Task: `5f000001-0000-4000-8000-000000000312`
- Notes: Rows on X submitted here. Create SPK on contract X from T012 is done BY HAND in the UI (not executed).
- Expected: submit 200; then by hand: picker eligible_for_spk=true&contract_id=X shows T012, Create SPK links both rows

### Step 1: `POST /api/v1/projects/tasks/boqs/submit`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000312",
  "contract_id": "5f000001-0000-4000-8000-000000000002",
  "spk_boqs": [
    {
      "code": "MSX.1.1.",
      "description": "Mobilisasi peralatan berat",
      "kind": "Upah",
      "unit_id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
      "volume": 2,
      "unit_price": 10000000.0,
      "total_price": 20000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000102",
      "type": "inline",
      "remarks": ""
    },
    {
      "code": "MSX.1.2.",
      "description": "Pembersihan dan perataan lahan",
      "kind": "Upah",
      "unit_id": "bf0e706b-7fcd-4761-bb2f-3352181e6760",
      "volume": 100,
      "unit_price": 150000.0,
      "total_price": 15000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000103",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `200`:
```json
{
  "process_time": "916.00ms",
  "status": "success",
  "code": "",
  "message": "Set project task boq succeed"
}
```


## Case 013 — Create SPK with SPK BoQ, different contract — submit prep only

- Type: Positif · Task: `5f000001-0000-4000-8000-000000000313`
- Notes: Rows on X and Y submitted. Create SPK on Y from T013 must link the Y rows only (by hand).
- Expected: submit 200, 200; then by hand: Create SPK on Y links MSY.1.1. and MSY.1.3., spk_value 220,000,000

### Step 1: `POST /api/v1/projects/tasks/boqs/submit`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000313",
  "contract_id": "5f000001-0000-4000-8000-000000000002",
  "spk_boqs": [
    {
      "code": "MSX.2.1.",
      "description": "Pemasangan pompa transfer 50 HP",
      "kind": "Material",
      "unit_id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
      "volume": 1,
      "unit_price": 60000000.0,
      "total_price": 60000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000105",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `200`:
```json
{
  "process_time": "914.00ms",
  "status": "success",
  "code": "",
  "message": "Set project task boq succeed"
}
```

### Step 2: `POST /api/v1/projects/tasks/boqs/submit`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000313",
  "contract_id": "5f000001-0000-4000-8000-000000000005",
  "spk_boqs": [
    {
      "code": "MSY.1.1.",
      "description": "Panel distribusi 400 A",
      "kind": "Material",
      "unit_id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
      "volume": 1,
      "unit_price": 80000000.0,
      "total_price": 80000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000112",
      "type": "inline",
      "remarks": ""
    },
    {
      "code": "MSY.1.3.",
      "description": "Instalasi dan commissioning",
      "kind": "Upah",
      "unit_id": "006dd80b-1994-40cb-94b1-7a39d66f12e5",
      "volume": 1,
      "unit_price": 60000000.0,
      "total_price": 60000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000114",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `200`:
```json
{
  "process_time": "996.00ms",
  "status": "success",
  "code": "",
  "message": "Set project task boq succeed"
}
```


## Case 014 — Create SPK with insufficient contract value — submit prep only

- Type: Negatif · Task: `5f000001-0000-4000-8000-000000000314`
- Notes: Contract S is worth 50,000,000; its only line is 80,000,000. The submit passes (no contract-balance gate, FSD GAP-1); Create SPK on S must fail by hand.
- Expected: submit 200; then by hand: Create SPK fails "Contract value remaining not sufficient to create new SPK"

### Step 1: `POST /api/v1/projects/tasks/boqs/submit`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000314",
  "contract_id": "5f000001-0000-4000-8000-000000000014",
  "spk_boqs": [
    {
      "code": "MSS.1.1.",
      "description": "Sewa genset 500 kVA",
      "kind": "Sewa Alat",
      "unit_id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
      "volume": 4,
      "unit_price": 20000000.0,
      "total_price": 80000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000162",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `200`:
```json
{
  "process_time": "827.00ms",
  "status": "success",
  "code": "",
  "message": "Set project task boq succeed"
}
```


## Case 015-019 — Input progress with several SPKs — data only, NOT executed

- Type: Positif/Negatif · Task: `5f000001-0000-4000-8000-000000000315`
- Notes: Rows on X and Y submitted so two SPKs (one per contract) can be created by hand; progress input, approve, reject, minus and the >100% cap are exercised in the UI.
- Expected: submit 200, 200; everything after that is by hand

### Step 1: `POST /api/v1/projects/tasks/boqs/submit`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000315",
  "contract_id": "5f000001-0000-4000-8000-000000000002",
  "spk_boqs": [
    {
      "code": "MSX.1.1.",
      "description": "Mobilisasi peralatan berat",
      "kind": "Upah",
      "unit_id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
      "volume": 2,
      "unit_price": 10000000.0,
      "total_price": 20000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000102",
      "type": "inline",
      "remarks": ""
    },
    {
      "code": "MSX.3.",
      "description": "Dokumentasi dan as-built drawing",
      "kind": "Transport",
      "unit_id": "60f87a3e-e1f6-4ef5-86b4-e19e584a2451",
      "volume": 1,
      "unit_price": 25000000.0,
      "total_price": 25000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000107",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `200`:
```json
{
  "process_time": "817.00ms",
  "status": "success",
  "code": "",
  "message": "Set project task boq succeed"
}
```

### Step 2: `POST /api/v1/projects/tasks/boqs/submit`

Request:
```json
{
  "project_task_id": "5f000001-0000-4000-8000-000000000315",
  "contract_id": "5f000001-0000-4000-8000-000000000005",
  "spk_boqs": [
    {
      "code": "MSY.1.2.",
      "description": "Kabel NYY 4x50 mm2",
      "kind": "Material",
      "unit_id": "d7190ea2-d2c1-407a-b45f-6e710bb3e8cc",
      "volume": 300,
      "unit_price": 80000.0,
      "total_price": 24000000.0,
      "start_date": "15-09-2026",
      "end_date": "31-12-2026",
      "boq_detail_id": "5f000001-0000-4000-8000-000000000113",
      "type": "inline",
      "remarks": ""
    }
  ]
}
```
Response `200`:
```json
{
  "process_time": "1078.00ms",
  "status": "success",
  "code": "",
  "message": "Set project task boq succeed"
}
```


## Task BoQ list, v2, after the run

`GET /api/v2/projects/tasks/boqs?project_task_ids=<all 15 task ids>` → `200`

| Task | Rows | Row: code · description · volume · total · contract |
|---|---|---|
| T012 | 2 | MSX.1.2. · Pembersihan dan perataan lahan · vol 100 · 15000000 · MSSPK/X/2026<br>MSX.1.1. · Mobilisasi peralatan berat · vol 2 · 20000000 · MSSPK/X/2026 |
| T002 | 4 | MSX.2.2. · Pemipaan 6 inch sch 40 · vol 100 · 60000000 · MSSPK/X/2026<br>MSY.1.2. · Kabel NYY 4x50 mm2 · vol 500 · 40000000 · MSSPK/Y/2026<br>MSY.1.1. · Panel distribusi 400 A · vol 1 · 80000000 · MSSPK/Y/2026<br>MSX.1.1. · Mobilisasi peralatan berat · vol 2 · 20000000 · MSSPK/X/2026 |
| T015 | 3 | MSX.3. · Dokumentasi dan as-built drawing · vol 1 · 25000000 · MSSPK/X/2026<br>MSY.1.2. · Kabel NYY 4x50 mm2 · vol 300 · 24000000 · MSSPK/Y/2026<br>MSX.1.1. · Mobilisasi peralatan berat · vol 2 · 20000000 · MSSPK/X/2026 |
| T013 | 3 | MSY.1.1. · Panel distribusi 400 A · vol 1 · 80000000 · MSSPK/Y/2026<br>MSY.1.3. · Instalasi dan commissioning · vol 1 · 60000000 · MSSPK/Y/2026<br>MSX.2.1. · Pemasangan pompa transfer 50 HP · vol 1 · 60000000 · MSSPK/X/2026 |
| T003 | 2 | MSY.1.3. · Instalasi dan commissioning · vol 1 · 60000000 · MSSPK/Y/2026<br>MSX.1.2. · Pembersihan dan perataan lahan · vol 200 · 30000000 · MSSPK/X/2026 |
| T011 | 2 | MSX.2.2. · Pemipaan 6 inch sch 40 · vol 50 · 30000000 · MSSPK/X/2026<br>MSX.2.1. · Pemasangan pompa transfer 50 HP · vol 1 · 60000000 · MSSPK/X/2026 |
| T001 | 3 | MSX.1.2. · Pembersihan dan perataan lahan · vol 100 · 15000000 · MSSPK/X/2026<br>MSX.1.1. · Mobilisasi peralatan berat · vol 6 · 60000000 · MSSPK/X/2026<br>MSX.2.1. · Pemasangan pompa transfer 50 HP · vol 1 · 60000000 · MSSPK/X/2026 |
| T014 | 1 | MSS.1.1. · Sewa genset 500 kVA · vol 4 · 80000000 · MSSPK/S/2026 |

Full response:
```json
{
  "data": [
    {
      "contract": {
        "id": "5f000001-0000-4000-8000-000000000002",
        "contract_no": "MSSPK/X/2026",
        "contract_title": "Multi Source SPK \u2014 Kontrak X (aktif)",
        "contractor_name": "PT Multi Source SPK Fixture",
        "contract_value": "2000000000",
        "autogenerated_spk_number": true,
        "retention_percentage": "10.00"
      },
      "spk_type": null,
      "spk": null,
      "project_task_id": "5f000001-0000-4000-8000-000000000312",
      "spk_boqs": [
        {
          "id": "7786b418-303b-47af-bfa0-095b10679f12",
          "description": "Pembersihan dan perataan lahan",
          "unit": {
            "id": "bf0e706b-7fcd-4761-bb2f-3352181e6760",
            "name": "m3"
          },
          "volume": "100",
          "total_price": "15000000",
          "start_date": "15-09-2026",
          "start_date_unix": 1789405200,
          "end_date": "31-12-2026",
          "end_date_unix": 1798650000,
          "boq_details": [
            {
              "id": "fdd80647-b18c-4d5d-af76-8ff2a29af961",
              "boq": {
                "id": "5f000001-0000-4000-8000-000000000103",
                "boq_id": "5f000001-0000-4000-8000-000000000003",
                "boq_library_id": "",
                "origin_number": 1,
                "description": "Pembersihan dan perataan lahan",
                "kind": "Upah",
                "quantity": 500,
                "unit": null,
                "unit_price": "150000",
                "total": "75000000",
                "remark": null,
                "data_type": "item",
                "breakdown": "MSX.1.2.",
                "parent_id": ""
              },
              "unit": {
                "id": "bf0e706b-7fcd-4761-bb2f-3352181e6760",
                "name": "m3"
              },
              "volume": "100",
              "unit_price": "150000",
              "total_price": "15000000"
            }
          ],
          "remarks": "",
          "type": "inline",
          "actual_volume": "0",
          "physical_progress": "0",
          "progress_cost": "0",
          "spks": [],
          "contract": {
            "id": "5f000001-0000-4000-8000-000000000002",
            "contract_no": "MSSPK/X/2026",
            "contract_title": "Multi Source SPK \u2014 Kontrak X (aktif)",
            "contractor_name": "PT Multi Source SPK Fixture",
            "contract_value": "2000000000",
            "autogenerated_spk_number": true,
            "retention_percentage": "10.00"
          }
        },
        {
          "id": "081285ab-e543-4771-943e-ea5b4d79a7a8",
          "description": "Mobilisasi peralatan berat",
          "unit": {
            "id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
            "name": "Unit"
          },
          "volume": "2",
          "total_price": "20000000",
          "start_date": "15-09-2026",
          "start_date_unix": 1789405200,
          "end_date": "31-12-2026",
          "end_date_unix": 1798650000,
          "boq_details": [
            {
              "id": "c73eb75a-9008-4fe1-9cfd-72c8b614fced",
              "boq": {
                "id": "5f000001-0000-4000-8000-000000000102",
                "boq_id": "5f000001-0000-4000-8000-000000000003",
                "boq_library_id": "",
                "origin_number": 1,
                "description": "Mobilisasi peralatan berat",
                "kind": "Upah",
                "quantity": 10,
                "unit": null,
                "unit_price": "10000000",
                "total": "100000000",
                "remark": null,
                "data_type": "item",
                "breakdown": "MSX.1.1.",
                "parent_id": ""
              },
              "unit": {
                "id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
                "name": "Unit"
              },
              "volume": "2",
              "unit_price": "10000000",
              "total_price": "20000000"
            }
          ],
          "remarks": "",
          "type": "inline",
          "actual_volume": "0",
          "physical_progress": "0",
          "progress_cost": "0",
          "spks": [],
          "contract": {
            "id": "5f000001-0000-4000-8000-000000000002",
            "contract_no": "MSSPK/X/2026",
            "contract_title": "Multi Source SPK \u2014 Kontrak X (aktif)",
            "contractor_name": "PT Multi Source SPK Fixture",
            "contract_value": "2000000000",
            "autogenerated_spk_number": true,
            "retention_percentage": "10.00"
          }
        }
      ],
      "created_at": "",
      "created_by": {
        "id": "00000000-0000-0000-0000-000000000000",
        "full_name": "",
        "status": ""
      },
      "updated_at": "",
      "updated_by": {
        "id": "00000000-0000-0000-0000-000000000000",
        "full_name": "",
        "status": ""
      }
    },
    {
      "contract": {
        "id": "5f000001-0000-4000-8000-000000000005",
        "contract_no": "MSSPK/Y/2026",
        "contract_title": "Multi Source SPK \u2014 Kontrak Y (aktif)",
        "contractor_name": "PT Multi Source SPK Fixture",
        "contract_value": "1500000000",
        "autogenerated_spk_number": true,
        "retention_percentage": "10.00"
      },
      "spk_type": null,
      "spk": null,
      "project_task_id": "5f000001-0000-4000-8000-000000000302",
      "spk_boqs": [
        {
          "id": "d38529df-cb26-43ed-ae34-0f3c7511f064",
          "description": "Pemipaan 6 inch sch 40",
          "unit": {
            "id": "d7190ea2-d2c1-407a-b45f-6e710bb3e8cc",
            "name": "m"
          },
          "volume": "100",
          "total_price": "60000000",
          "start_date": "15-09-2026",
          "start_date_unix": 1789405200,
          "end_date": "31-12-2026",
          "end_date_unix": 1798650000,
          "boq_details": [
            {
              "id": "6324a8a5-90a4-469b-a78b-60867d3d2483",
              "boq": {
                "id": "5f000001-0000-4000-8000-000000000106",
                "boq_id": "5f000001-0000-4000-8000-000000000003",
                "boq_library_id": "",
                "origin_number": 1,
                "description": "Pemipaan 6 inch sch 40",
                "kind": "Material",
                "quantity": 300,
                "unit": null,
                "unit_price": "600000",
                "total": "180000000",
                "remark": null,
                "data_type": "item",
                "breakdown": "MSX.2.2.",
                "parent_id": ""
              },
              "unit": {
                "id": "d7190ea2-d2c1-407a-b45f-6e710bb3e8cc",
                "name": "m"
              },
              "volume": "100",
              "unit_price": "600000",
              "total_price": "60000000"
            }
          ],
          "remarks": "",
          "type": "inline",
          "actual_volume": "0",
          "physical_progress": "0",
          "progress_cost": "0",
          "spks": [],
          "contract": {
            "id": "5f000001-0000-4000-8000-000000000002",
            "contract_no": "MSSPK/X/2026",
            "contract_title": "Multi Source SPK \u2014 Kontrak X (aktif)",
            "contractor_name": "PT Multi Source SPK Fixture",
            "contract_value": "2000000000",
            "autogenerated_spk_number": true,
            "retention_percentage": "10.00"
          }
        },
        {
          "id": "432f87d1-bb99-49f9-adcf-48391a8b0e41",
          "description": "Kabel NYY 4x50 mm2",
          "unit": {
            "id": "d7190ea2-d2c1-407a-b45f-6e710bb3e8cc",
            "name": "m"
          },
          "volume": "500",
          "total_price": "40000000",
          "start_date": "15-09-2026",
          "start_date_unix": 1789405200,
          "end_date": "31-12-2026",
          "end_date_unix": 1798650000,
          "boq_details": [
            {
              "id": "4550b184-c732-4aaa-a2ab-909a0f773d16",
              "boq": {
                "id": "5f000001-0000-4000-8000-000000000113",
                "boq_id": "5f000001-0000-4000-8000-000000000006",
                "boq_library_id": "",
                "origin_number": 1,
                "description": "Kabel NYY 4x50 mm2",
                "kind": "Material",
                "quantity": 1200,
                "unit": null,
                "unit_price": "80000",
                "total": "96000000",
                "remark": null,
                "data_type": "item",
                "breakdown": "MSY.1.2.",
                "parent_id": ""
              },
              "unit": {
                "id": "d7190ea2-d2c1-407a-b45f-6e710bb3e8cc",
                "name": "m"
              },
              "volume": "500",
              "unit_price": "80000",
              "total_price": "40000000"
            }
          ],
          "remarks": "",
          "type": "inline",
          "actual_volume": "0",
          "physical_progress": "0",
          "progress_cost": "0",
          "spks": [],
          "contract": {
            "id": "5f000001-0000-4000-8000-000000000005",
            "contract_no": "MSSPK/Y/2026",
            "contract_title": "Multi Source SPK \u2014 Kontrak Y (aktif)",
            "contractor_name": "PT Multi Source SPK Fixture",
            "contract_value": "1500000000",
            "autogenerated_spk_number": true,
            "retention_percentage": "10.00"
          }
        },
        {
          "id": "2b317100-f781-471e-90ae-85f1c1a51d51",
          "description": "Panel distribusi 400 A",
          "unit": {
            "id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
            "name": "Unit"
          },
          "volume": "1",
          "total_price": "80000000",
          "start_date": "15-09-2026",
          "start_date_unix": 1789405200,
          "end_date": "31-12-2026",
          "end_date_unix": 1798650000,
          "boq_details": [
            {
              "id": "e9c097ac-5861-4c33-9871-f7b1b19cae14",
              "boq": {
                "id": "5f000001-0000-4000-8000-000000000112",
                "boq_id": "5f000001-0000-4000-8000-000000000006",
                "boq_library_id": "",
                "origin_number": 1,
                "description": "Panel distribusi 400 A",
                "kind": "Material",
                "quantity": 2,
                "unit": null,
                "unit_price": "80000000",
                "total": "160000000",
                "remark": null,
                "data_type": "item",
                "breakdown": "MSY.1.1.",
                "parent_id": ""
              },
              "unit": {
                "id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
                "name": "Unit"
              },
              "volume": "1",
              "unit_price": "80000000",
              "total_price": "80000000"
            }
          ],
          "remarks": "",
          "type": "inline",
          "actual_volume": "0",
          "physical_progress": "0",
          "progress_cost": "0",
          "spks": [],
          "contract": {
            "id": "5f000001-0000-4000-8000-000000000005",
            "contract_no": "MSSPK/Y/2026",
            "contract_title": "Multi Source SPK \u2014 Kontrak Y (aktif)",
            "contractor_name": "PT Multi Source SPK Fixture",
            "contract_value": "1500000000",
            "autogenerated_spk_number": true,
            "retention_percentage": "10.00"
          }
        },
        {
          "id": "e273affd-8a6d-4b04-b207-bc17ea36202b",
          "description": "Mobilisasi peralatan berat",
          "unit": {
            "id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
            "name": "Unit"
          },
          "volume": "2",
          "total_price": "20000000",
          "start_date": "15-09-2026",
          "start_date_unix": 1789405200,
          "end_date": "31-12-2026",
          "end_date_unix": 1798650000,
          "boq_details": [
            {
              "id": "29c14c5c-d9d7-4e55-92a7-bf82c5fad7f2",
              "boq": {
                "id": "5f000001-0000-4000-8000-000000000102",
                "boq_id": "5f000001-0000-4000-8000-000000000003",
                "boq_library_id": "",
                "origin_number": 1,
                "description": "Mobilisasi peralatan berat",
                "kind": "Upah",
                "quantity": 10,
                "unit": null,
                "unit_price": "10000000",
                "total": "100000000",
                "remark": null,
                "data_type": "item",
                "breakdown": "MSX.1.1.",
                "parent_id": ""
              },
              "unit": {
                "id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
                "name": "Unit"
              },
              "volume": "2",
              "unit_price": "10000000",
              "total_price": "20000000"
            }
          ],
          "remarks": "",
          "type": "inline",
          "actual_volume": "0",
          "physical_progress": "0",
          "progress_cost": "0",
          "spks": [],
          "contract": {
            "id": "5f000001-0000-4000-8000-000000000002",
            "contract_no": "MSSPK/X/2026",
            "contract_title": "Multi Source SPK \u2014 Kontrak X (aktif)",
            "contractor_name": "PT Multi Source SPK Fixture",
            "contract_value": "2000000000",
            "autogenerated_spk_number": true,
            "retention_percentage": "10.00"
          }
        }
      ],
      "created_at": "",
      "created_by": {
        "id": "00000000-0000-0000-0000-000000000000",
        "full_name": "",
        "status": ""
      },
      "updated_at": "",
      "updated_by": {
        "id": "00000000-0000-0000-0000-000000000000",
        "full_name": "",
        "status": ""
      }
    },
    {
      "contract": {
        "id": "5f000001-0000-4000-8000-000000000005",
        "contract_no": "MSSPK/Y/2026",
        "contract_title": "Multi Source SPK \u2014 Kontrak Y (aktif)",
        "contractor_name": "PT Multi Source SPK Fixture",
        "contract_value": "1500000000",
        "autogenerated_spk_number": true,
        "retention_percentage": "10.00"
      },
      "spk_type": null,
      "spk": null,
      "project_task_id": "5f000001-0000-4000-8000-000000000315",
      "spk_boqs": [
        {
          "id": "56e85449-41cd-48ca-9b0e-1a36892675c0",
          "description": "Dokumentasi dan as-built drawing",
          "unit": {
            "id": "60f87a3e-e1f6-4ef5-86b4-e19e584a2451",
            "name": "Set"
          },
          "volume": "1",
          "total_price": "25000000",
          "start_date": "15-09-2026",
          "start_date_unix": 1789405200,
          "end_date": "31-12-2026",
          "end_date_unix": 1798650000,
          "boq_details": [
            {
              "id": "79e29b77-543e-4d67-97b2-3137507eddd2",
              "boq": {
                "id": "5f000001-0000-4000-8000-000000000107",
                "boq_id": "5f000001-0000-4000-8000-000000000003",
                "boq_library_id": "",
                "origin_number": 1,
                "description": "Dokumentasi dan as-built drawing",
                "kind": "Transport",
                "quantity": 1,
                "unit": null,
                "unit_price": "25000000",
                "total": "25000000",
                "remark": null,
                "data_type": "item",
                "breakdown": "MSX.3.",
                "parent_id": ""
              },
              "unit": {
                "id": "60f87a3e-e1f6-4ef5-86b4-e19e584a2451",
                "name": "Set"
              },
              "volume": "1",
              "unit_price": "25000000",
              "total_price": "25000000"
            }
          ],
          "remarks": "",
          "type": "inline",
          "actual_volume": "0",
          "physical_progress": "0",
          "progress_cost": "0",
          "spks": [],
          "contract": {
            "id": "5f000001-0000-4000-8000-000000000002",
            "contract_no": "MSSPK/X/2026",
            "contract_title": "Multi Source SPK \u2014 Kontrak X (aktif)",
            "contractor_name": "PT Multi Source SPK Fixture",
            "contract_value": "2000000000",
            "autogenerated_spk_number": true,
            "retention_percentage": "10.00"
          }
        },
        {
          "id": "270f364f-c342-4fa0-a1c6-42487c688f5d",
          "description": "Kabel NYY 4x50 mm2",
          "unit": {
            "id": "d7190ea2-d2c1-407a-b45f-6e710bb3e8cc",
            "name": "m"
          },
          "volume": "300",
          "total_price": "24000000",
          "start_date": "15-09-2026",
          "start_date_unix": 1789405200,
          "end_date": "31-12-2026",
          "end_date_unix": 1798650000,
          "boq_details": [
            {
              "id": "35985e65-f997-4463-96be-9363db0fbbaa",
              "boq": {
                "id": "5f000001-0000-4000-8000-000000000113",
                "boq_id": "5f000001-0000-4000-8000-000000000006",
                "boq_library_id": "",
                "origin_number": 1,
                "description": "Kabel NYY 4x50 mm2",
                "kind": "Material",
                "quantity": 1200,
                "unit": null,
                "unit_price": "80000",
                "total": "96000000",
                "remark": null,
                "data_type": "item",
                "breakdown": "MSY.1.2.",
                "parent_id": ""
              },
              "unit": {
                "id": "d7190ea2-d2c1-407a-b45f-6e710bb3e8cc",
                "name": "m"
              },
              "volume": "300",
              "unit_price": "80000",
              "total_price": "24000000"
            }
          ],
          "remarks": "",
          "type": "inline",
          "actual_volume": "0",
          "physical_progress": "0",
          "progress_cost": "0",
          "spks": [],
          "contract": {
            "id": "5f000001-0000-4000-8000-000000000005",
            "contract_no": "MSSPK/Y/2026",
            "contract_title": "Multi Source SPK \u2014 Kontrak Y (aktif)",
            "contractor_name": "PT Multi Source SPK Fixture",
            "contract_value": "1500000000",
            "autogenerated_spk_number": true,
            "retention_percentage": "10.00"
          }
        },
        {
          "id": "19cc1dbe-bf4c-4695-90de-469f2486a7f9",
          "description": "Mobilisasi peralatan berat",
          "unit": {
            "id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
            "name": "Unit"
          },
          "volume": "2",
          "total_price": "20000000",
          "start_date": "15-09-2026",
          "start_date_unix": 1789405200,
          "end_date": "31-12-2026",
          "end_date_unix": 1798650000,
          "boq_details": [
            {
              "id": "0a109897-0f49-4d75-a86b-26dcd5832eb5",
              "boq": {
                "id": "5f000001-0000-4000-8000-000000000102",
                "boq_id": "5f000001-0000-4000-8000-000000000003",
                "boq_library_id": "",
                "origin_number": 1,
                "description": "Mobilisasi peralatan berat",
                "kind": "Upah",
                "quantity": 10,
                "unit": null,
                "unit_price": "10000000",
                "total": "100000000",
                "remark": null,
                "data_type": "item",
                "breakdown": "MSX.1.1.",
                "parent_id": ""
              },
              "unit": {
                "id": "d93aef0a-2efc-47ac-8322-b95774bcfbe9",
                "name": "Unit"
              },
              "volume": "2",
              "unit_price": "10000000",
              "total_price": "20000000"
            }
          ],
          "remarks": "",
          "type": "inline",
          "actual_volume": "0",
          "p
```