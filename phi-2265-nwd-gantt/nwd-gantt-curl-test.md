# PHI-2265 — `GET /api/v1/projects/nwd`: happy-path curl test

Status: **run 2026-10-30 — 13/13 PASS** (see section 3; 100-project SQL timing in section 4). Branch `feat/phi-2265-nwd-gantt` (worktree `.worktrees/phi-2265-nwd-gantt`).
The parameter values below were picked from the dev DB (`185.250.38.82 / phantomdb`) on 2026-10-30, so
each case should return data.

## 0. Prerequisites

### 0.1 Run the API from the worktree

```bash
cd .worktrees/phi-2265-nwd-gantt/src-be
cp ../../../src-be/WebApi/appsettings.json WebApi/   # gitignored; already copied once
dotnet build WebApi/WebApi.csproj
cd WebApi
Quartz__Enabled=false dotnet run --no-build --no-launch-profile --urls http://127.0.0.1:5099
```

### 0.2 Token

```bash
TOKEN='<TOKEN>'
BASE='http://127.0.0.1:5099/api/v1/projects/nwd'
```

### 0.3 Test data: assign rigs (dev DB, one time)

No real DLC/FL project on dev has a rig yet. The 4 backfilled ones are old drafts without tasks and
with the legacy category text "New Well Development", so they never match `category=newwelldevelopment`.
Without this step the DLC/FL cases return `data: []`.

Until the `project-rig-id` branch ships, the rig is set directly in SQL. `rig_name` is copied
because that is the invariant the API keeps.

```sql
-- Check first: all six must have rig_id = NULL and rig_name = NULL (otherwise adjust the rollback).
SELECT project_no, rig_id, rig_name FROM projects
WHERE id IN ('946a2ca9-7aff-4af0-b6ba-915de08b9a4a','0baa1943-8b82-4a0a-bee7-85735b27cd43',
             'b053720d-a266-4422-a770-c0acd7468786','92aa86ca-3984-4d29-aed4-70811044ecc2',
             'c40c41f1-3544-49e4-b179-4019c13cc097','961581ee-b68a-426d-ba46-4734b6e054d4');

-- ELANG-03 (PHSS): two DLC in-progress projects with overlapping dates (multi-track stacking)
UPDATE projects SET rig_id = 'b1721661-390a-4478-b842-e46e84efce4f', rig_name = 'ELANG-03 (1000 HP)'
WHERE id IN ('946a2ca9-7aff-4af0-b6ba-915de08b9a4a',   -- PRBN231        14-08-2026 .. 13-09-2026
             '0baa1943-8b82-4a0a-bee7-85735b27cd43');  -- PN28082026001  07-08-2026 .. 30-09-2026

-- BKY-04 (PHSS): FL in-progress
UPDATE projects SET rig_id = '4efc41c1-72e4-486f-8a2e-0f0ef2ccc873', rig_name = 'BKY-04 (1000 HP)'
WHERE id = 'b053720d-a266-4422-a770-c0acd7468786';     -- PRD12313

-- Rig Chevron 12 (PEP): one DLC in-progress + two DLC on hold that are in the approval queue
UPDATE projects SET rig_id = '1c059f46-4613-4bb2-8a73-012470c51b74', rig_name = 'Rig Chevron 12'
WHERE id IN ('92aa86ca-3984-4d29-aed4-70811044ecc2',   -- WBS271026001 in progress
             'c40c41f1-3544-49e4-b179-4019c13cc097',   -- WBS301026002 on hold (approval)
             '961581ee-b68a-426d-ba46-4734b6e054d4');  -- WBS261026021 on hold (approval)
```

Rollback after the test:

```sql
UPDATE projects SET rig_id = NULL, rig_name = NULL
WHERE id IN ('946a2ca9-7aff-4af0-b6ba-915de08b9a4a','0baa1943-8b82-4a0a-bee7-85735b27cd43',
             'b053720d-a266-4422-a770-c0acd7468786','92aa86ca-3984-4d29-aed4-70811044ecc2',
             'c40c41f1-3544-49e4-b179-4019c13cc097','961581ee-b68a-426d-ba46-4734b6e054d4');
```

## 1. Happy-path cases

Response shape for every case: `{ process_time, status: "success", code, message: "Get NWD gantt succeed", data: [row...] }`.
A row is `{ id, type, rig_name?, rig_capacity?, area?, tasks: [card...] }`. A card is
`{ id, project_no, project_description, start_date, end_date, status, progress, perizinan, land_acquisition, site_preparation }`.

### H1 — Overview tab, DLC, PHSS ABI/BD, 2026 (rows per rig)

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PHSS' --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=DLC' --data-urlencode 'year=2026' \
  --data-urlencode 'status=in progress|finished'
```

Expect: HTTP 200. One row `type: "rig_name"`, `rig_name: "ELANG-03 (1000 HP)"`, no `rig_capacity` (capacity is NULL).
It has 2 cards, `PN28082026001` then `PRBN231` (sorted by start date: 07-08-2026, then 14-08-2026), and their
dates overlap. Each card has all 3 indicators as one of `completed|on_time|on_hold|late_start`.
`PRBN231` has progress 0, so its status is `on_hold` unless an indicator is `late_start`.

### H2 — Overview tab, FL, PHSS ABI/BD, 2026

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PHSS' --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=FL' --data-urlencode 'year=2026' \
  --data-urlencode 'status=in progress|finished'
```

Expect: one row `BKY-04 (1000 HP)` with card `PRD12313` (12-08-2026 .. 11-09-2026, progress 0.24 → `on_time` unless red).

### H3 — Overview tab, DLC, PEP ABI/BD, 2026

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PEP' --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=DLC' --data-urlencode 'year=2026' \
  --data-urlencode 'status=in progress|finished'
```

Expect: one row `Rig Chevron 12` with card `WBS271026001` only. The two on-hold projects on the same rig
are not in this tab.

### H4 — Approval tab, DLC, PEP ABI/BD, 2026

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PEP' --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=DLC' --data-urlencode 'year=2026' \
  --data-urlencode 'need_approval=true'
```

Expect: one row `Rig Chevron 12` with the two on-hold cards `WBS261026021` and `WBS301026002`, and **not**
`WBS271026001` (in progress). `status` is ignored when `need_approval=true`.

### H5 — Approval tab, "need my approval"

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PEP' --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=DLC' --data-urlencode 'year=2026' \
  --data-urlencode 'need_approval=true' --data-urlencode 'need_my_approval=true'
```

Expect: HTTP 200. The cards are the subset of H4 where `r3test.agil` is the approver at the current level,
so `data: []` is a valid result. Compare with `GET /api/v1/projects/need-approval?need_my_approval=true`.

### H6 — Overview tab, GL, PHSS ABI/BD, 2026 (rows per area)

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PHSS' --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=GL' --data-urlencode 'year=2026' \
  --data-urlencode 'status=in progress|finished'
```

Expect: rows `type: "area"` with an `area` name and no `rig_name`, including card `PRBD1234`.
No rig setup needed.

### H7 — Draft tab, GL, PHSS ABI/BD, 2026

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PHSS' --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=GL' --data-urlencode 'year=2026' \
  --data-urlencode 'status=draft|canceled'
```

Expect: an area row with card `CNTES1012`. Its card span runs into 2027, and `end_date` shows the real 2027 date
(the FE clips the bar, not the API).

### H8 — Cross-year: same as H7 with `year=2027`

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PHSS' --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=GL' --data-urlencode 'year=2027' \
  --data-urlencode 'status=draft|canceled'
```

Expect: `CNTES1012` is still returned, because the span overlaps 2027.

### H9 — RTWS, Overview PHSS ABO and Draft PEP ABO

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PHSS' --data-urlencode 'zone=ABO' \
  --data-urlencode 'sub_category=RTWS' --data-urlencode 'year=2026' \
  --data-urlencode 'status=in progress|finished'

curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PEP' --data-urlencode 'zone=ABO' \
  --data-urlencode 'sub_category=RTWS' --data-urlencode 'year=2026' \
  --data-urlencode 'status=draft|canceled'
```

Expect: card `PN04092026001` (first) and `PN280702026001` (second), each in an area row.

### H10 — Keyword narrows to the matching card only

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PHSS' --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=DLC' --data-urlencode 'year=2026' \
  --data-urlencode 'status=in progress|finished' --data-urlencode 'keyword=PRBN231'
```

Expect: row `ELANG-03 (1000 HP)` with **only** card `PRBN231` (H1 had 2).

### H11 — Summary-card filter `overview_status`

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PHSS' --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=DLC' --data-urlencode 'year=2026' \
  --data-urlencode 'status=draft|canceled' --data-urlencode 'overview_status=on_going'
```

Expect: a subset of H1 (in-progress projects not behind plan; a project with negative variance moves to `overview_status=delay`), even though `status` says draft:
`overview_status` supersedes `status`, the same rule as `GET /projects`.

### H12 — Year with no data

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PHSS' --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=DLC' --data-urlencode 'year=2020' \
  --data-urlencode 'status=in progress|finished'
```

Expect: HTTP 200, `data: []`. The FE shows "No Gantt data available".

## 2. Known data issue to watch

`PNP3121` (DLC, PHSS ABI/BD, in progress) has `vwProjectSummary.actual_weight_itd = 25127.67`. That is not
on the 0–100 scale, so if it gets a rig its card returns `progress: 25127.67` and status `completed`. That is a
data or rollup problem, not a Gantt bug. It is left out of the setup on purpose.

## 3. Results (run 2026-10-30 22:13 WIB)

API: `feat/phi-2265-nwd-gantt` built from the worktree and run on `127.0.0.1:5099` with `Quartz__Enabled=false` against the dev DB (rig setup from 0.3 applied).
Times: **HTTP** = curl `time_total` (includes auth middleware). **EF Gantt SQL** = sum of the Gantt's own `Executed DbCommand` durations from the API log for that request (matched by `X-Journey-Id`). Each SQL round trip to the dev DB costs about 42 ms of network latency at minimum.

| # | Case | Expect | Got | HTTP | Time | EF Gantt SQL (main / spans / milestones / progress / areas) | |
|---|---|---|---|---|---|---|---|
| H1 | Overview DLC PHSS ABI/BD 2026 (rows per rig, overlap) | 1 rig row ELANG-03 with PN28082026001, PRBN231 (overlapping) | ELANG-03 (1000 HP): PN28082026001, PRBN231 | 200 | 2045 ms | 1492 ms (575 / 50 / 44 / 823) | PASS |
| H2 | Overview FL PHSS ABI/BD 2026 | BKY-04 with PRD12313 | BKY-04 (1000 HP): PRD12313 | 200 | 649 ms | 223 ms (68 / 43 / 60 / 52) | PASS |
| H3 | Overview DLC PEP ABI/BD 2026 | Rig Chevron 12 with WBS271026001 only | Rig Chevron 12: WBS271026001 | 200 | 826 ms | 243 ms (47 / 49 / 63 / 84) | PASS |
| H4 | Approval tab DLC PEP ABI/BD 2026 | Rig Chevron 12 with the 2 on-hold cards only | Rig Chevron 12: WBS261026021, WBS301026002 | 200 | 1166 ms | 705 ms (545 / 50 / 50 / 60) | PASS |
| H5 | Approval tab + need_my_approval | subset of H4 ([] allowed) | [] | 200 | 1241 ms | 472 ms (472) | PASS |
| H6 | Overview GL PHSS ABI/BD 2026 (rows per area) | area row with PRBD1234 | Badak: PRBD1234 | 200 | 1546 ms | 1095 ms (912 / 43 / 43 / 45 / 52) | PASS |
| H7 | Draft GL PHSS ABI/BD 2026 | area row with CNTES1012 | Lempake: CNTES1012 | 200 | 860 ms | 321 ms (56 / 64 / 44 / 110 / 47) | PASS |
| H8 | Cross-year: Draft GL PHSS ABI/BD 2027 | CNTES1012 still shown in 2027 | Lempake: CNTES1012 | 200 | 641 ms | 238 ms (55 / 42 / 42 / 51 / 48) | PASS |
| H9a | Overview RTWS PHSS ABO 2026 | PN04092026001 | Mutiara: PN04092026001 | 200 | 786 ms | 343 ms (58 / 45 / 84 / 99 / 57) | PASS |
| H9b | Draft RTWS PEP ABO 2026 | PN280702026001 | Anggana: PN280702026001 | 200 | 739 ms | 287 ms (52 / 63 / 65 / 52 / 55) | PASS |
| H10 | Keyword PRBN231 (DLC PHSS) | ELANG-03 with only PRBN231 | ELANG-03 (1000 HP): PRBN231 | 200 | 1405 ms | 967 ms (819 / 47 / 46 / 55) | PASS |
| H11 | overview_status=on_going supersedes status | in-progress DLC not behind plan (both are behind plan → []) | [] | 200 | 1315 ms | 694 ms (694) | PASS |
| H12 | Year with no data (2020) | data: [] | [] | 200 | 494 ms | 72 ms (72) | PASS |

H1 was the first request after start-up: its 575 ms main query and 823 ms progress query include SQL plan compilation. Warm requests take about 50–70 ms per Gantt statement.
H11 check: the same filters with `overview_status=delay` return both cards (`PN28082026001` on_time 19.76%, `PRBN231` on_hold 0%), which confirms they were left out of `on_going` for being behind plan.

### Responses

#### H1 — Overview DLC PHSS ABI/BD 2026 (rows per rig, overlap) — HTTP 200, 2045 ms

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PHSS' \
  --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=DLC' \
  --data-urlencode 'year=2026' \
  --data-urlencode 'status=in progress|finished'
```

```json
{
  "data": [
    {
      "id": "b1721661-390a-4478-b842-e46e84efce4f",
      "type": "rig_name",
      "rig_name": "ELANG-03 (1000 HP)",
      "tasks": [
        {
          "id": "0baa1943-8b82-4a0a-bee7-85735b27cd43",
          "project_no": "PN28082026001",
          "project_description": "QA TEST Vendor Via Project",
          "start_date": "07-08-2026",
          "end_date": "30-09-2026",
          "status": "on_time",
          "progress": 19.758812615955474,
          "perizinan": "on_hold",
          "land_acquisition": "on_hold",
          "site_preparation": "on_hold"
        },
        {
          "id": "946a2ca9-7aff-4af0-b6ba-915de08b9a4a",
          "project_no": "PRBN231",
          "project_description": "Paribasa NWD Testing",
          "start_date": "14-08-2026",
          "end_date": "13-09-2026",
          "status": "on_hold",
          "progress": 0,
          "perizinan": "on_hold",
          "land_acquisition": "on_hold",
          "site_preparation": "on_hold"
        }
      ]
    }
  ],
  "process_time": "1504.80ms",
  "status": "success",
  "code": "",
  "message": "Get NWD gantt succeed"
}
```

#### H2 — Overview FL PHSS ABI/BD 2026 — HTTP 200, 649 ms

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PHSS' \
  --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=FL' \
  --data-urlencode 'year=2026' \
  --data-urlencode 'status=in progress|finished'
```

```json
{
  "data": [
    {
      "id": "4efc41c1-72e4-486f-8a2e-0f0ef2ccc873",
      "type": "rig_name",
      "rig_name": "BKY-04 (1000 HP)",
      "tasks": [
        {
          "id": "b053720d-a266-4422-a770-c0acd7468786",
          "project_no": "PRD12313",
          "project_description": "Paribasa PHSS NWD Delay",
          "start_date": "12-08-2026",
          "end_date": "11-09-2026",
          "status": "on_time",
          "progress": 0.23919722540786417,
          "perizinan": "on_hold",
          "land_acquisition": "on_hold",
          "site_preparation": "on_hold"
        }
      ]
    }
  ],
  "process_time": "232.80ms",
  "status": "success",
  "code": "",
  "message": "Get NWD gantt succeed"
}
```

#### H3 — Overview DLC PEP ABI/BD 2026 — HTTP 200, 826 ms

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PEP' \
  --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=DLC' \
  --data-urlencode 'year=2026' \
  --data-urlencode 'status=in progress|finished'
```

```json
{
  "data": [
    {
      "id": "1c059f46-4613-4bb2-8a73-012470c51b74",
      "type": "rig_name",
      "rig_name": "Rig Chevron 12",
      "tasks": [
        {
          "id": "92aa86ca-3984-4d29-aed4-70811044ecc2",
          "project_no": "WBS271026001",
          "project_description": "PROJECT-Automation Project NWD PEP ABI/BD 1793094920208",
          "start_date": "07-09-2026",
          "end_date": "04-10-2026",
          "status": "on_hold",
          "progress": 0,
          "perizinan": "on_hold",
          "land_acquisition": "on_hold",
          "site_preparation": "on_hold"
        }
      ]
    }
  ],
  "process_time": "246.95ms",
  "status": "success",
  "code": "",
  "message": "Get NWD gantt succeed"
}
```

#### H4 — Approval tab DLC PEP ABI/BD 2026 — HTTP 200, 1166 ms

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PEP' \
  --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=DLC' \
  --data-urlencode 'year=2026' \
  --data-urlencode 'need_approval=true'
```

```json
{
  "data": [
    {
      "id": "1c059f46-4613-4bb2-8a73-012470c51b74",
      "type": "rig_name",
      "rig_name": "Rig Chevron 12",
      "tasks": [
        {
          "id": "961581ee-b68a-426d-ba46-4734b6e054d4",
          "project_no": "WBS261026021",
          "project_description": "PROJECT-Automation Project NWD PEP ABI/BD 1793007932585",
          "start_date": "07-09-2026",
          "end_date": "04-10-2026",
          "status": "on_hold",
          "progress": 0,
          "perizinan": "on_hold",
          "land_acquisition": "on_hold",
          "site_preparation": "on_hold"
        },
        {
          "id": "c40c41f1-3544-49e4-b179-4019c13cc097",
          "project_no": "WBS301026002",
          "project_description": "PROJECT-Automation Project NWD PEP ABI/BD 1793331520628",
          "start_date": "07-09-2026",
          "end_date": "04-10-2026",
          "status": "on_hold",
          "progress": 0,
          "perizinan": "on_hold",
          "land_acquisition": "on_hold",
          "site_preparation": "on_hold"
        }
      ]
    }
  ],
  "process_time": "714.86ms",
  "status": "success",
  "code": "",
  "message": "Get NWD gantt succeed"
}
```

#### H5 — Approval tab + need_my_approval — HTTP 200, 1241 ms

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PEP' \
  --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=DLC' \
  --data-urlencode 'year=2026' \
  --data-urlencode 'need_approval=true' \
  --data-urlencode 'need_my_approval=true'
```

```json
{
  "data": [],
  "process_time": "539.88ms",
  "status": "success",
  "code": "",
  "message": "Get NWD gantt succeed"
}
```

#### H6 — Overview GL PHSS ABI/BD 2026 (rows per area) — HTTP 200, 1546 ms

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PHSS' \
  --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=GL' \
  --data-urlencode 'year=2026' \
  --data-urlencode 'status=in progress|finished'
```

```json
{
  "data": [
    {
      "id": "82a0a208-0c99-4935-8886-846473244110",
      "type": "area",
      "area": "Badak",
      "tasks": [
        {
          "id": "ee4cca4c-409f-47be-91eb-f9e893bfa505",
          "project_no": "PRBD1234",
          "project_description": "Paribasa NWD ON Stream PHSS",
          "start_date": "12-08-2026",
          "end_date": "11-09-2026",
          "status": "on_time",
          "progress": 0.11959861270393209,
          "perizinan": "on_hold",
          "land_acquisition": "on_hold",
          "site_preparation": "on_hold"
        }
      ]
    }
  ],
  "process_time": "1109.60ms",
  "status": "success",
  "code": "",
  "message": "Get NWD gantt succeed"
}
```

#### H7 — Draft GL PHSS ABI/BD 2026 — HTTP 200, 860 ms

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PHSS' \
  --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=GL' \
  --data-urlencode 'year=2026' \
  --data-urlencode 'status=draft|canceled'
```

```json
{
  "data": [
    {
      "id": "cee60f74-526a-4928-87d0-59bc063614fd",
      "type": "area",
      "area": "Lempake",
      "tasks": [
        {
          "id": "4b56c088-1022-4105-b0e7-02f7b31b2336",
          "project_no": "CNTES1012",
          "project_description": "QA TES 12",
          "start_date": "24-08-2026",
          "end_date": "18-08-2027",
          "status": "on_hold",
          "progress": 0,
          "perizinan": "on_hold",
          "land_acquisition": "on_hold",
          "site_preparation": "on_hold"
        }
      ]
    }
  ],
  "process_time": "328.12ms",
  "status": "success",
  "code": "",
  "message": "Get NWD gantt succeed"
}
```

#### H8 — Cross-year: Draft GL PHSS ABI/BD 2027 — HTTP 200, 641 ms

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PHSS' \
  --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=GL' \
  --data-urlencode 'year=2027' \
  --data-urlencode 'status=draft|canceled'
```

```json
{
  "data": [
    {
      "id": "cee60f74-526a-4928-87d0-59bc063614fd",
      "type": "area",
      "area": "Lempake",
      "tasks": [
        {
          "id": "4b56c088-1022-4105-b0e7-02f7b31b2336",
          "project_no": "CNTES1012",
          "project_description": "QA TES 12",
          "start_date": "24-08-2026",
          "end_date": "18-08-2027",
          "status": "on_hold",
          "progress": 0,
          "perizinan": "on_hold",
          "land_acquisition": "on_hold",
          "site_preparation": "on_hold"
        }
      ]
    }
  ],
  "process_time": "242.90ms",
  "status": "success",
  "code": "",
  "message": "Get NWD gantt succeed"
}
```

#### H9a — Overview RTWS PHSS ABO 2026 — HTTP 200, 786 ms

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PHSS' \
  --data-urlencode 'zone=ABO' \
  --data-urlencode 'sub_category=RTWS' \
  --data-urlencode 'year=2026' \
  --data-urlencode 'status=in progress|finished'
```

```json
{
  "data": [
    {
      "id": "fffce605-6525-4e74-a50f-d931623d26bc",
      "type": "area",
      "area": "Mutiara",
      "tasks": [
        {
          "id": "9c37116d-5b28-465c-885d-eea6e8e87a47",
          "project_no": "PN04092026001",
          "project_description": "Project regression ABO PHSS",
          "start_date": "07-09-2026",
          "end_date": "04-10-2026",
          "status": "on_time",
          "progress": 20.408163265306122,
          "perizinan": "on_hold",
          "land_acquisition": "on_hold",
          "site_preparation": "on_hold"
        }
      ]
    }
  ],
  "process_time": "349.45ms",
  "status": "success",
  "code": "",
  "message": "Get NWD gantt succeed"
}
```

#### H9b — Draft RTWS PEP ABO 2026 — HTTP 200, 739 ms

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PEP' \
  --data-urlencode 'zone=ABO' \
  --data-urlencode 'sub_category=RTWS' \
  --data-urlencode 'year=2026' \
  --data-urlencode 'status=draft|canceled'
```

```json
{
  "data": [
    {
      "id": "c2ea669f-ea14-4f1e-befb-276f98cc5ec7",
      "type": "area",
      "area": "Anggana",
      "tasks": [
        {
          "id": "3c8e5822-2baf-4263-a509-57ce59c38f57",
          "project_no": "PN280702026001",
          "project_description": "Project PEP ABO",
          "start_date": "28-07-2026",
          "end_date": "31-08-2026",
          "status": "on_hold",
          "progress": 0,
          "perizinan": "on_hold",
          "land_acquisition": "on_hold",
          "site_preparation": "on_hold"
        }
      ]
    }
  ],
  "process_time": "289.47ms",
  "status": "success",
  "code": "",
  "message": "Get NWD gantt succeed"
}
```

#### H10 — Keyword PRBN231 (DLC PHSS) — HTTP 200, 1405 ms

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PHSS' \
  --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=DLC' \
  --data-urlencode 'year=2026' \
  --data-urlencode 'status=in progress|finished' \
  --data-urlencode 'keyword=PRBN231'
```

```json
{
  "data": [
    {
      "id": "b1721661-390a-4478-b842-e46e84efce4f",
      "type": "rig_name",
      "rig_name": "ELANG-03 (1000 HP)",
      "tasks": [
        {
          "id": "946a2ca9-7aff-4af0-b6ba-915de08b9a4a",
          "project_no": "PRBN231",
          "project_description": "Paribasa NWD Testing",
          "start_date": "14-08-2026",
          "end_date": "13-09-2026",
          "status": "on_hold",
          "progress": 0,
          "perizinan": "on_hold",
          "land_acquisition": "on_hold",
          "site_preparation": "on_hold"
        }
      ]
    }
  ],
  "process_time": "982.43ms",
  "status": "success",
  "code": "",
  "message": "Get NWD gantt succeed"
}
```

#### H11 — overview_status=on_going supersedes status — HTTP 200, 1315 ms

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PHSS' \
  --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=DLC' \
  --data-urlencode 'year=2026' \
  --data-urlencode 'status=draft|canceled' \
  --data-urlencode 'overview_status=on_going'
```

```json
{
  "data": [],
  "process_time": "708.72ms",
  "status": "success",
  "code": "",
  "message": "Get NWD gantt succeed"
}
```

#### H12 — Year with no data (2020) — HTTP 200, 494 ms

```bash
curl -s -G "$BASE" -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PHSS' \
  --data-urlencode 'zone=ABI/BD' \
  --data-urlencode 'sub_category=DLC' \
  --data-urlencode 'year=2020' \
  --data-urlencode 'status=in progress|finished'
```

```json
{
  "data": [],
  "process_time": "73.68ms",
  "status": "success",
  "code": "",
  "message": "Get NWD gantt succeed"
}
```

#### H11b — check: same as H11 with `overview_status=delay`

```json
{
  "data": [
    {
      "id": "b1721661-390a-4478-b842-e46e84efce4f",
      "type": "rig_name",
      "rig_name": "ELANG-03 (1000 HP)",
      "tasks": [
        {
          "id": "0baa1943-8b82-4a0a-bee7-85735b27cd43",
          "project_no": "PN28082026001",
          "project_description": "QA TEST Vendor Via Project",
          "start_date": "07-08-2026",
          "end_date": "30-09-2026",
          "status": "on_time",
          "progress": 19.758812615955474,
          "perizinan": "on_hold",
          "land_acquisition": "on_hold",
          "site_preparation": "on_hold"
        },
        {
          "id": "946a2ca9-7aff-4af0-b6ba-915de08b9a4a",
          "project_no": "PRBN231",
          "project_description": "Paribasa NWD Testing",
          "start_date": "14-08-2026",
          "end_date": "13-09-2026",
          "status": "on_hold",
          "progress": 0,
          "perizinan": "on_hold",
          "land_acquisition": "on_hold",
          "site_preparation": "on_hold"
        }
      ]
    }
  ],
  "process_time": "846.89ms",
  "status": "success",
  "code": "",
  "message": "Get NWD gantt succeed"
}
```

## 4. SQL / EF time with 100 projects

Dev has only 6 projects with a rig, so the API can't return 100 cards yet. Instead, the **exact SQL EF generated** for the Gantt (copied from the API log) was run in `sqlcmd` with `SET STATISTICS TIME ON`, fed **100 real project ids**. These are the projects with the most tasks: **23852 task rows** under them, out of 30,227 in total. Each statement ran 3 times. **Server** = SQL Server elapsed time. **Wall** = `sqlcmd` start to finish, including process start and login (about 500 ms of that is overhead, not query time).

| Statement | Rows | Run 1 server / wall | Run 2 server / wall | Run 3 server / wall |
|---|---|---|---|---|
| main projects query (year overlap, 100 candidates) | 71 | 563 ms / 1598 ms | 202 ms / 933 ms | 241 ms / 782 ms |
| card spans (MIN/MAX) | 100 | 161 ms / 713 ms | 159 ms / 709 ms | 228 ms / 1211 ms |
| milestones (LIKE on text) | 54 | 714 ms / 1563 ms | 405 ms / 935 ms | 366 ms / 1004 ms |
| progress (vwProjectSummary) | 99 | 723 ms / 2452 ms | 755 ms / 1960 ms | 434 ms / 1048 ms |

**Warm server total ≈ 1161 ms** for the 4 statements at 100 projects (the best of runs 2–3 each). The API adds about 4 × 42 ms of network round trip plus auth (~300 ms), so expect a cold call of about **1.5–2.5 s** and a warm one around **1–1.5 s** at 100 projects. Today the real responses are 6 projects or fewer, at 0.5–1.5 s.

Where the time goes:
- **progress (`vwProjectSummary`)** is the slowest (430–755 ms). It is a view that rolls up task weights. The project list (`GET /projects`) already pays this same cost.
- **milestones** (370–715 ms): `description` is a `text` column, so the three `LIKE`s scan every task row of those projects. `IX_project_tasks_project_id_cover` (key `project_id`, include `data_type, deleted_at, etc`) does not include `description`, `status` or `end_date`, so every row needs a lookup into the main table.
- **card spans** (160–230 ms): same index, without `start_date` / `end_date` → lookups.
- **main query** (200–560 ms): runs the MIN/MAX subqueries per candidate project for the year filter.

Possible improvements, not done in this branch (separate ticket):
1. Add `start_date, end_date, status` to the includes of `IX_project_tasks_project_id_cover`. That removes the lookups for spans, the year filter and most of the milestone read.
2. Fold the card-span MIN/MAX into the main query (one round trip less).
3. Long term: migrate `project_tasks.description` from `text` to `nvarchar(max)`, the deprecated type, which also blocks `LTRIM`/`LOWER`.
