# 08-ScenarioTest — curl per step (Well Test + Artificial Lift)

> **Contains live dev tokens.** Local only: this file is listed in `.git/info/exclude`. Do not share or commit it.

## Setup

Run the API from the approval worktree:
```bash
cd /Users/hafidhidayatullah/Stuffs/Grounds/OceanInovasi/phi/phiDev/.worktrees/phi-2243-ap-approval/src-be/WebApi && dotnet run   # http://localhost:5071
```

| Role in the scenario | User | Id |
|---|---|---|
| SSDP (PEP submitter, level 3) | phi.sda1 | `0b000000-0000-0000-0000-000000000407` |
| PO reviewer + Manager level 1 | phi.po | `0b000000-0000-0000-0000-000000000406` |
| Manager level 2 | phi.superadmin | `0b000000-0000-0000-0000-000000000409` |
| SSDP (PHSS submitter) | phi.sda2 | `0b000000-0000-0000-0000-000000000408` |
| Execution PIC (not an approver) | r3test.amin | `a5ce36a8-4bd8-456b-b8b9-d8b438025676` |

Tokens are the mock tokens from `mock_auth_sessions` (no expiry). Every test uses its own well with no action plan yet (dev DB, 2026-11-16).
Plan ids are only known after submit: after each submit, set the variable (e.g. `WT1=<data.id>`) and the next curls use `$WT1`.

## Level actions

| Round | Level action | Endpoint | Result |
|---|---|---|---|
| Modify | approve | `…/{id}/approval/approve` | next level; last level applies the proposal → `approved` |
| Modify | reject the modify | `…/{id}/approval/reject` | `modify_returned`, PO pool gets "modify rejected" |
| Reject | approve to reject | `…/{id}/approval/reject` | next level; last level → `modify_returned`, PO pool + SSDP creator get "Action Plan Rejected by Manager" |
| Reject | reject the reject (ask PO to modify) | `…/{id}/approval/modify` | `modify_returned`, PO pool gets "reject rejected" |
| Reject | approve | `…/{id}/approval/approve` | 400 |

> Test #3 in `08-ScenarioTest.md` expects "Action Plan reject rejected" for the PO pool. The code sends "Action Plan Rejected by Manager" to the PO pool and the SSDP creator (your earlier instruction). The curls below expect the code's copy.


## Request bodies

Every request body follows the Bruno PR [phi-phantom-collections #176](https://github.com/oceaninov/phi-phantom-collections/pull/176) (`feat/action-plan-approval`, head `7fde611`):

| Request | PR file | Notes |
|---|---|---|
| Submit well test / artificial lift | `Submit Action Plan PEP - WO & Approval Status.yml`, `Submit Action Plan PEP - Artificial Lift.yml` | `wo_number` comes from `GET …/next-wo-number` (step before each submit). PHSS well test has no `planned_duration_hours` / `tank_number` / `start_date_time` / `end_date_time` |
| PO approve / modify / reject | `Review Action Plan.yml` (examples Approve, Modify PEP well test, Modify PHSS artificial lift WHC, Reject, Modify from modify_returned) | `proposed` has no `action_plan_type`, `well_id`, `ownership` like the PR |
| Level approve / reject | `Approve Action Plan Level.yml`, `Reject Action Plan Level.yml` | |
| Level modify (ask PO to modify) | not in the PR yet (new endpoint) | `{ "remarks": … }` |

> Like the PR, `proposed` leaves out `ownership` (and `notes` for artificial lift). The final approval writes the proposal as the whole plan, so `ownership` becomes empty and shows in `modification-diff`.


## A. Well Test — PEP

### Well Test PEP — Test #1: PO approve

**1. SSDP make action plan and submit**

```bash
curl "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: data.wo_number NNNN/WO/SDA1|SDA2/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "well_test",
  "draft_id": null,
  "well_id": "bc22c105-c39b-461c-b64a-1dbed5a85a5d",
  "wo_number": "'"$WO"'",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "well test submit",
  "ownership": "Pertamina EP",
  "well_test": {
    "well_test_action": "schedule",
    "assigned_department": "Production Operations",
    "contract_number": "CTR-PO/2026/001",
    "well_test_type": "production_test",
    "planned_duration_hours": 24.0,
    "tank_number": "T-01",
    "start_date_time": "2026-11-26T08:00:00",
    "end_date_time": "2026-11-26T16:00:00"
  }
}'
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set WT1=<data.id>

WT1=<data.id from the submit response>
```

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Well Test Request" — "WO Number <wo> Well Test need Approval."

```

```bash
curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $WT1
```

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $WT1 listed
```

**3. PO will approve**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT1/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "approve",
  "remarks": "OK, jalankan sesuai jadwal",
  "execution_department_id": "Production Operations",
  "execution_pic_id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
}'
# expect: approval_status approved
```

![[Screenshot 2026-11-16 at 15.11.39.png]]

**4. Action plan change status show on list of action plan**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/bc22c105-c39b-461c-b64a-1dbed5a85a5d/action-plans/pep" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $WT1 with approval_status approved, progress = date status (not routing)

curl "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT1" -H "Authorization: Bearer <TOKEN>.po"
# expect: approval_status approved

```

![[Screenshot 2026-11-16 at 15.51.48.png]]
![[Screenshot 2026-11-16 at 15.51.52.png]]

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: "Well Test In Progress"

```
![[Screenshot 2026-11-16 at 15.19.13.png]]

```bash

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $WT1 gone from action_plan_review
```

![[Screenshot 2026-11-16 at 15.52.08.png]]


---

### Well Test PEP — Test #2: PO modify → Mgr 1 → Mgr 2 → SSDP approve

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: data.wo_number NNNN/WO/SDA1|SDA2/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "well_test",
  "draft_id": null,
  "well_id": "04170a12-f3ad-491c-a36b-b972f1574479",
  "wo_number": "'"$WO"'",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "well test submit",
  "ownership": "Pertamina EP",
  "well_test": {
    "well_test_action": "schedule",
    "assigned_department": "Production Operations",
    "contract_number": "CTR-PO/2026/001",
    "well_test_type": "production_test",
    "planned_duration_hours": 24.0,
    "tank_number": "T-01",
    "start_date_time": "2026-11-26T08:00:00",
    "end_date_time": "2026-11-26T16:00:00"
  }
}'
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set WT2=<data.id>

WT2=<data.id from the submit response>
```

![[Screenshot 2026-11-16 at 15.52.11.png]]
![[Screenshot 2026-11-16 at 15.52.17.png]]

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Well Test Request" — "WO Number <wo> Well Test need Approval."

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $WT2

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $WT2 listed
```

![[Screenshot 2026-11-16 at 15.52.20.png]]
![[Screenshot 2026-11-16 at 15.52.27.png]]
![[Screenshot 2026-11-16 at 15.52.32.png]]

**3. PO will modify and add approval route**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT2/approval-route" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: prefill levels from Data Config (optional)

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT2/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "modify",
  "remarks": "Geser jadwal, durasi jadi 12 jam",
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000406"
      ],
      "sla_days": 2
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ],
      "sla_days": 3
    },
    {
      "level": 3,
      "user_id": [
        "0b000000-0000-0000-0000-000000000407"
      ],
      "sla_days": 2
    }
  ],
  "execution_department_id": "Production Operations",
  "execution_pic_id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
  "proposed": {
    "start_date": "26-11-2026",
    "end_date": "01-12-2026",
    "pic_ids": [
      "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
    ],
    "notes": "jadwal digeser oleh PO",
    "well_test": {
      "well_test_action": "schedule",
      "assigned_department": "Production Operations",
      "contract_number": "CTR-PO/2026/001",
      "well_test_type": "production_test",
      "planned_duration_hours": 12.0,
      "tank_number": "T-01",
      "start_date_time": "26-11-2026 08:00:00",
      "end_date_time": "26-11-2026 20:00:00"
    }
  }
}'
# expect: approval_status modify_in_approval, current_level 1, total_levels 3
```

![[Screenshot 2026-11-16 at 15.52.35.png]]
![[Screenshot 2026-11-16 at 15.52.40.png]]

**4. Manager level 1 will approve**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Modify Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $WT2 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT2/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: current_level 2
```

![[Screenshot 2026-11-16 at 15.52.43.png]]
![[Screenshot 2026-11-16 at 15.52.47.png]]
![[Screenshot 2026-11-16 at 15.52.51.png]]

**5. Manager level 2 will approve**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: "Modify Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: $WT2 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT2/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.superadmin" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: current_level 3
```

![[Screenshot 2026-11-16 at 15.53.00.png]]
![[Screenshot 2026-11-16 at 15.53.04.png]]
![[Screenshot 2026-11-16 at 15.53.10.png]]

**6. SSDP will approve**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: "Modify Action Plan" — "… has been modified by Production Operations and requires your approval."

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: $WT2 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT2/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: approval_status approved
```

![[Screenshot 2026-11-16 at 15.53.16.png]]
![[Screenshot 2026-11-16 at 15.53.20.png]]
![[Screenshot 2026-11-16 at 15.53.26.png]]

**7. Proceed and status action plan**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT2" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: approved, end_date 01-12-2026, well_test.planned_duration_hours 12

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT2/modification-diff" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: changes listed

curl -s "http://localhost:5071/api/v1/well-surveilence/04170a12-f3ad-491c-a36b-b972f1574479/action-plans/pep" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $WT2 approved

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: "Well Test In Progress"
```

![[Screenshot 2026-11-16 at 15.53.31.png]]
![[Screenshot 2026-11-16 at 15.53.33.png]]
![[Screenshot 2026-11-16 at 15.53.37.png]]
![[Screenshot 2026-11-16 at 15.53.41.png]]

---

### Well Test PEP — Test #3: PO reject → Mgr 1 and Mgr 2 approve to reject → back to PO

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: data.wo_number NNNN/WO/SDA1|SDA2/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "well_test",
  "draft_id": null,
  "well_id": "0dc94bc8-eccd-426e-ba59-90d876a59b89",
  "wo_number": "'"$WO"'",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "well test submit",
  "ownership": "Pertamina EP",
  "well_test": {
    "well_test_action": "schedule",
    "assigned_department": "Production Operations",
    "contract_number": "CTR-PO/2026/001",
    "well_test_type": "production_test",
    "planned_duration_hours": 24.0,
    "tank_number": "T-01",
    "start_date_time": "2026-11-26T08:00:00",
    "end_date_time": "2026-11-26T16:00:00"
  }
}'
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set WT3=<data.id>

WT3=<data.id from the submit response>
```

![[Screenshot 2026-11-16 at 15.53.43.png]]
![[Screenshot 2026-11-16 at 15.53.48.png]]

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Well Test Request" — "WO Number <wo> Well Test need Approval."

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $WT3

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $WT3 listed
```

![[Screenshot 2026-11-16 at 15.53.51.png]]
![[Screenshot 2026-11-16 at 15.53.58.png]]
![[Screenshot 2026-11-16 at 15.54.02.png]]

**3. PO will reject and add approval route**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT3/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "reject",
  "remarks": "Sumur sedang workover, tidak bisa well test",
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000406"
      ],
      "sla_days": 2
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ],
      "sla_days": 3
    }
  ]
}'
# expect: approval_status reject_in_approval, current_level 1
```

![[Screenshot 2026-11-16 at 15.54.07.png]]

**4. Manager level 1 will approve to reject**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Reject Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $WT3 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT3/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: 400 — approve is not allowed in a reject round

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT3/approval/reject" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Durasi terlalu pendek, mohon dimodifikasi"
}'
# expect: reject_in_approval, current_level 2
```

![[Screenshot 2026-11-16 at 15.54.09.png]]
![[Screenshot 2026-11-16 at 15.54.14.png]]
![[Screenshot 2026-11-16 at 15.54.17.png]]
![[Screenshot 2026-11-16 at 15.54.21.png]]

**5. Manager level 2 will approve to reject**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: "Reject Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: $WT3 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT3/approval/reject" \
  -H "Authorization: Bearer <TOKEN>.superadmin" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Durasi terlalu pendek, mohon dimodifikasi"
}'
# expect: approval_status modify_returned
```

![[Screenshot 2026-11-16 at 15.54.27.png]]
![[Screenshot 2026-11-16 at 15.54.31.png]]
![[Screenshot 2026-11-16 at 15.54.36.png]]

**6. Proceed and status action plan to modify to PO**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT3" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: modify_returned

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $WT3 back in the PO review inbox

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Action Plan Rejected by Manager" — "WO Number <wo> Action Plan rejected" (whole PO pool)

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: same "Action Plan Rejected by Manager" for the SSDP creator

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT3/approval-history" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: reject cycle outcome rejected
```

![[Screenshot 2026-11-16 at 15.54.40.png]]
![[Screenshot 2026-11-16 at 15.54.45.png]]
![[Screenshot 2026-11-16 at 15.54.48.png]]
![[Screenshot 2026-11-16 at 15.54.51.png]]
![[Screenshot 2026-11-16 at 15.54.54.png]]

---

### Well Test PEP — Test #4: PO reject → Mgr 1 rejects the reject (ask PO to modify)

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: data.wo_number NNNN/WO/SDA1|SDA2/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "well_test",
  "draft_id": null,
  "well_id": "4264ebb9-f367-455a-a2e3-877ebeeef953",
  "wo_number": "'"$WO"'",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "well test submit",
  "ownership": "Pertamina EP",
  "well_test": {
    "well_test_action": "schedule",
    "assigned_department": "Production Operations",
    "contract_number": "CTR-PO/2026/001",
    "well_test_type": "production_test",
    "planned_duration_hours": 24.0,
    "tank_number": "T-01",
    "start_date_time": "2026-11-26T08:00:00",
    "end_date_time": "2026-11-26T16:00:00"
  }
}'
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set WT4=<data.id>

WT4=<data.id from the submit response>
```

![[Screenshot 2026-11-16 at 15.54.57.png]]
![[Screenshot 2026-11-16 at 15.55.01.png]]

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Well Test Request" — "WO Number <wo> Well Test need Approval."

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $WT4

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $WT4 listed
```

![[Screenshot 2026-11-16 at 15.55.04.png]]
![[Screenshot 2026-11-16 at 15.55.11.png]]
![[Screenshot 2026-11-16 at 15.55.16.png]]

**3. PO will reject and add approval route**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT4/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "reject",
  "remarks": "Sumur sedang workover, tidak bisa well test",
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000406"
      ],
      "sla_days": 2
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ],
      "sla_days": 3
    }
  ]
}'
# expect: reject_in_approval
```

![[Screenshot 2026-11-16 at 15.55.20.png]]

**4. Manager level 1 will reject the rejected by PO**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Reject Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $WT4 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT4/approval/modify" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Jangan ditolak, mohon dimodifikasi"
}'
# expect: approval_status modify_returned
```

![[Screenshot 2026-11-16 at 15.55.23.png]]
![[Screenshot 2026-11-16 at 15.55.27.png]]
![[Screenshot 2026-11-16 at 15.55.31.png]]

**5. Proceed and status action plan to modify to PO**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT4" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: modify_returned

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "WO Number <wo> Action Plan reject rejected."

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $WT4 back in the PO review inbox
```

![[Screenshot 2026-11-16 at 15.55.36.png]]
![[Screenshot 2026-11-16 at 15.55.39.png]]
![[Screenshot 2026-11-16 at 15.55.43.png]]

---

### Well Test PEP — Test #5: PO reject → Mgr 1 approves to reject → Mgr 2 rejects the reject

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: data.wo_number NNNN/WO/SDA1|SDA2/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "well_test",
  "draft_id": null,
  "well_id": "e4a99b01-7a81-415f-828e-0372d142c0a3",
  "wo_number": "'"$WO"'",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "well test submit",
  "ownership": "Pertamina EP",
  "well_test": {
    "well_test_action": "schedule",
    "assigned_department": "Production Operations",
    "contract_number": "CTR-PO/2026/001",
    "well_test_type": "production_test",
    "planned_duration_hours": 24.0,
    "tank_number": "T-01",
    "start_date_time": "2026-11-26T08:00:00",
    "end_date_time": "2026-11-26T16:00:00"
  }
}'
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set WT5=<data.id>

WT5=<data.id from the submit response>
```

![[Screenshot 2026-11-16 at 15.55.46.png]]
![[Screenshot 2026-11-16 at 15.55.50.png]]

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Well Test Request" — "WO Number <wo> Well Test need Approval."

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $WT5

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $WT5 listed
```

![[Screenshot 2026-11-16 at 15.55.54.png]]
![[Screenshot 2026-11-16 at 15.56.00.png]]
![[Screenshot 2026-11-16 at 15.56.05.png]]

**3. PO will reject and add approval route**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT5/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "reject",
  "remarks": "Sumur sedang workover, tidak bisa well test",
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000406"
      ],
      "sla_days": 2
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ],
      "sla_days": 3
    }
  ]
}'
# expect: reject_in_approval
```

![[Screenshot 2026-11-16 at 15.56.10.png]]

**4. Manager level 1 will approve to reject**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $WT5 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT5/approval/reject" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Durasi terlalu pendek, mohon dimodifikasi"
}'
# expect: reject_in_approval, current_level 2
```

![[Screenshot 2026-11-16 at 15.56.14.png]]
![[Screenshot 2026-11-16 at 15.56.19.png]]

**5. Manager level 2 will reject the rejected by PO**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: "Reject Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: $WT5 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT5/approval/modify" \
  -H "Authorization: Bearer <TOKEN>.superadmin" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Jangan ditolak, mohon dimodifikasi"
}'
# expect: approval_status modify_returned
```

![[Screenshot 2026-11-16 at 15.56.23.png]]
![[Screenshot 2026-11-16 at 15.56.27.png]]
![[Screenshot 2026-11-16 at 15.56.31.png]]

**6. Proceed and status action plan to modify**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: modify_returned

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "WO Number <wo> Action Plan reject rejected."
```

![[Screenshot 2026-11-16 at 15.56.36.png]]
![[Screenshot 2026-11-16 at 15.56.39.png]]

---

### Well Test PEP — Test #6: PO modify → Mgr 1 approves → Mgr 2 rejects the modify

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: data.wo_number NNNN/WO/SDA1|SDA2/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "well_test",
  "draft_id": null,
  "well_id": "d2966a2d-bc03-4e72-8ab5-beb6dacda0bd",
  "wo_number": "'"$WO"'",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "well test submit",
  "ownership": "Pertamina EP",
  "well_test": {
    "well_test_action": "schedule",
    "assigned_department": "Production Operations",
    "contract_number": "CTR-PO/2026/001",
    "well_test_type": "production_test",
    "planned_duration_hours": 24.0,
    "tank_number": "T-01",
    "start_date_time": "2026-11-26T08:00:00",
    "end_date_time": "2026-11-26T16:00:00"
  }
}'
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set WT6=<data.id>

WT6=<data.id from the submit response>
```

![[Screenshot 2026-11-16 at 15.56.41.png]]
![[Screenshot 2026-11-16 at 15.56.46.png]]

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Well Test Request" — "WO Number <wo> Well Test need Approval."

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $WT6

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $WT6 listed
```

![[Screenshot 2026-11-16 at 15.56.49.png]]
![[Screenshot 2026-11-16 at 15.56.56.png]]
![[Screenshot 2026-11-16 at 15.57.01.png]]

**3. PO will modify and add approval route**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT6/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "modify",
  "remarks": "Geser jadwal, durasi jadi 12 jam",
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000406"
      ],
      "sla_days": 2
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ],
      "sla_days": 3
    },
    {
      "level": 3,
      "user_id": [
        "0b000000-0000-0000-0000-000000000407"
      ],
      "sla_days": 2
    }
  ],
  "execution_department_id": "Production Operations",
  "execution_pic_id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
  "proposed": {
    "start_date": "26-11-2026",
    "end_date": "01-12-2026",
    "pic_ids": [
      "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
    ],
    "notes": "jadwal digeser oleh PO",
    "well_test": {
      "well_test_action": "schedule",
      "assigned_department": "Production Operations",
      "contract_number": "CTR-PO/2026/001",
      "well_test_type": "production_test",
      "planned_duration_hours": 12.0,
      "tank_number": "T-01",
      "start_date_time": "26-11-2026 08:00:00",
      "end_date_time": "26-11-2026 20:00:00"
    }
  }
}'
# expect: modify_in_approval
```

![[Screenshot 2026-11-16 at 15.57.06.png]]

**4. Manager level 1 will approve**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $WT6 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT6/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: current_level 2
```

![[Screenshot 2026-11-16 at 15.57.11.png]]
![[Screenshot 2026-11-16 at 15.57.16.png]]

**5. Manager level 2 will reject the modify by PO**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: "Modify Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: $WT6 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT6/approval/reject" \
  -H "Authorization: Bearer <TOKEN>.superadmin" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Durasi terlalu pendek, mohon dimodifikasi"
}'
# expect: approval_status modify_returned
```

![[Screenshot 2026-11-16 at 15.57.19.png]]
![[Screenshot 2026-11-16 at 15.57.23.png]]
![[Screenshot 2026-11-16 at 15.57.28.png]]

**6. Proceed and status action plan to modify to PO**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT6" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: modify_returned, end_date still 28-11-2026 (live data not changed)

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "WO Number <wo> Action Plan modify rejected."
```

![[Screenshot 2026-11-16 at 15.57.32.png]]
![[Screenshot 2026-11-16 at 15.57.35.png]]

---

### Well Test PEP — Test #7: back to PO (plan $WT6 from Test #6), modify again → approved

**1. Action plan is back to PO (modify_returned)**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT6" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: modify_returned

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $WT6 listed
```

![[Screenshot 2026-11-16 at 15.57.39.png]]
![[Screenshot 2026-11-16 at 15.57.44.png]]

**2. PO cannot approve**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT6/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "approve",
  "remarks": "OK, jalankan sesuai jadwal",
  "execution_department_id": "Production Operations",
  "execution_pic_id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
}'
# expect: 400 "decision must be modify | reject while the action plan is modify_returned"
```

![[Screenshot 2026-11-16 at 15.57.47.png]]

**3. PO will modify again and add approval route**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT6/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "modify",
  "remarks": "Revisi sesuai catatan Manager 2",
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000406"
      ],
      "sla_days": 2
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ],
      "sla_days": 3
    },
    {
      "level": 3,
      "user_id": [
        "0b000000-0000-0000-0000-000000000407"
      ],
      "sla_days": 2
    }
  ],
  "execution_department_id": "Production Operations",
  "execution_pic_id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
  "proposed": {
    "start_date": "26-11-2026",
    "end_date": "01-12-2026",
    "pic_ids": [
      "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
    ],
    "notes": "jadwal digeser oleh PO",
    "well_test": {
      "well_test_action": "schedule",
      "assigned_department": "Production Operations",
      "contract_number": "CTR-PO/2026/001",
      "well_test_type": "production_test",
      "planned_duration_hours": 12.0,
      "tank_number": "T-01",
      "start_date_time": "26-11-2026 08:00:00",
      "end_date_time": "26-11-2026 20:00:00"
    }
  }
}'
# expect: modify_in_approval, cycle_no 2
```

![[Screenshot 2026-11-16 at 15.57.53.png]]

**4. Manager level 1, Manager level 2, SSDP will approve**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT6/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: current_level 2

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT6/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.superadmin" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: current_level 3

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT6/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: approved
```

![[Screenshot 2026-11-16 at 15.57.59.png]]
![[Screenshot 2026-11-16 at 15.58.04.png]]
![[Screenshot 2026-11-16 at 15.58.10.png]]

**5. Proceed and status action plan**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT6" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: approved

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT6/approval-history" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: 2 cycles; cycle_no 2 with previous_cycle_id = cycle 1
```

![[Screenshot 2026-11-16 at 15.58.15.png]]
![[Screenshot 2026-11-16 at 15.58.18.png]]

---

## B. Artificial Lift (WHC installation) — PEP

### Artificial Lift PEP — Test #1: PO approve

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: data.wo_number NNNN/WO/SDA1|SDA2/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "f943ee13-a930-4b98-9750-05b5890376d2",
  "wo_number": "'"$WO"'",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "WHC installation",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "well_head_compressor",
    "assigned_department": "Production Operations",
    "whc_type": "mobile",
    "compression_type": 1,
    "owned_by": "rental",
    "contract_number": "CTR-PO/2026/014",
    "cost_allocation": "WBS-Z9-0042",
    "production": 0.8
  }
}'
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set AL1=<data.id>

AL1=<data.id from the submit response>
```

![[Screenshot 2026-11-16 at 15.58.20.png]]
![[Screenshot 2026-11-16 at 15.58.25.png]]

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Artificial Lift Request" — "WO Number <wo> Artificial Lift need Approval."

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $AL1

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $AL1 listed
```

![[Screenshot 2026-11-16 at 15.58.29.png]]
![[Screenshot 2026-11-16 at 16.01.14.png]]
![[Screenshot 2026-11-16 at 16.01.23.png]]

**3. PO will approve**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL1/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "approve",
  "remarks": "OK, jalankan sesuai jadwal",
  "execution_department_id": "Production Operations",
  "execution_pic_id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
}'
# expect: approval_status approved
```

![[Screenshot 2026-11-16 at 16.01.30.png]]

**4. Action plan change status show on list of action plan**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/f943ee13-a930-4b98-9750-05b5890376d2/action-plans/pep" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $AL1 with approval_status approved, progress = date status (not routing)

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL1" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: approval_status approved

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: "Artificial Lift In Progress"

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $AL1 gone from action_plan_review
```

![[Screenshot 2026-11-16 at 16.01.35.png]]
![[Screenshot 2026-11-16 at 16.01.42.png]]
![[Screenshot 2026-11-16 at 16.18.33.png]]
![[Screenshot 2026-11-16 at 16.02.34.png]]

---

### Artificial Lift PEP — Test #2: PO modify → Mgr 1 → Mgr 2 → SSDP approve

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: data.wo_number NNNN/WO/SDA1|SDA2/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "cf1c600a-158d-4a1f-b334-7ada6bdaeba6",
  "wo_number": "'"$WO"'",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "WHC installation",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "well_head_compressor",
    "assigned_department": "Production Operations",
    "whc_type": "mobile",
    "compression_type": 1,
    "owned_by": "rental",
    "contract_number": "CTR-PO/2026/014",
    "cost_allocation": "WBS-Z9-0042",
    "production": 0.8
  }
}'
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set AL2=<data.id>

AL2=<data.id from the submit response>
```

![[Screenshot 2026-11-16 at 16.02.37.png]]
![[Screenshot 2026-11-16 at 16.02.46.png]]

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Artificial Lift Request" — "WO Number <wo> Artificial Lift need Approval."

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $AL2

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $AL2 listed
```

![[Screenshot 2026-11-16 at 16.03.03.png]]
![[Screenshot 2026-11-16 at 16.03.18.png]]
![[Screenshot 2026-11-16 at 16.03.24.png]]

**3. PO will modify and add approval route**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL2/approval-route" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: prefill levels from Data Config (optional)

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL2/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "modify",
  "remarks": "Production disesuaikan",
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000406"
      ],
      "sla_days": 2
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ],
      "sla_days": 3
    },
    {
      "level": 3,
      "user_id": [
        "0b000000-0000-0000-0000-000000000407"
      ],
      "sla_days": 2
    }
  ],
  "proposed": {
    "start_date": "26-11-2026",
    "end_date": "01-12-2026",
    "pic_ids": [
      "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
    ],
    "artificial_lift": {
      "activity_type": "installation",
      "action_mode": "installation_schedule",
      "method": "well_head_compressor",
      "assigned_department": "Production Operations",
      "whc_type": "mobile",
      "compression_type": 1,
      "owned_by": "rental",
      "contract_number": "CTR-PO/2026/014",
      "cost_allocation": "WBS-Z9-0042",
      "production": 0.5
    }
  }
}'
# expect: approval_status modify_in_approval, current_level 1, total_levels 3
```

![[Screenshot 2026-11-16 at 16.03.33.png]]
![[Screenshot 2026-11-16 at 16.03.40.png]]

**4. Manager level 1 will approve**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Modify Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $AL2 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL2/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: current_level 2
```

![[Screenshot 2026-11-16 at 16.03.47.png]]
![[Screenshot 2026-11-16 at 16.03.54.png]]
![[Screenshot 2026-11-16 at 16.04.00.png]]

**5. Manager level 2 will approve**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: "Modify Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: $AL2 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL2/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.superadmin" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: current_level 3
```

![[Screenshot 2026-11-16 at 16.18.37.png]]
![[Screenshot 2026-11-16 at 16.04.45.png]]
![[Screenshot 2026-11-16 at 16.04.57.png]]

**6. SSDP will approve**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: "Modify Action Plan" — "WO Number <wo> Artificial Lift Installation has been modified by Production Operations."

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: $AL2 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL2/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: approval_status approved
```

![[Screenshot 2026-11-16 at 16.05.24.png]]
![[Screenshot 2026-11-16 at 16.05.30.png]]
![[Screenshot 2026-11-16 at 16.05.37.png]]

**7. Proceed and status action plan**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL2" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: approved, end_date 01-12-2026, artificial_lift.production 0.5

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL2/modification-diff" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: changes listed

curl -s "http://localhost:5071/api/v1/well-surveilence/cf1c600a-158d-4a1f-b334-7ada6bdaeba6/action-plans/pep" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $AL2 approved

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: "Artificial Lift In Progress"
```

![[Screenshot 2026-11-16 at 16.05.43.png]]
![[Screenshot 2026-11-16 at 16.05.46.png]]
![[Screenshot 2026-11-16 at 16.05.49.png]]
![[Screenshot 2026-11-16 at 16.06.17.png]]

---

### Artificial Lift PEP — Test #3: PO reject → Mgr 1 and Mgr 2 approve to reject → back to PO

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: data.wo_number NNNN/WO/SDA1|SDA2/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "4c3cc152-9e8c-44d3-af31-21a015560303",
  "wo_number": "'"$WO"'",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "WHC installation",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "well_head_compressor",
    "assigned_department": "Production Operations",
    "whc_type": "mobile",
    "compression_type": 1,
    "owned_by": "rental",
    "contract_number": "CTR-PO/2026/014",
    "cost_allocation": "WBS-Z9-0042",
    "production": 0.8
  }
}'
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set AL3=<data.id>

AL3=<data.id from the submit response>
```

![[Screenshot 2026-11-16 at 16.06.22.png]]
![[Screenshot 2026-11-16 at 16.06.30.png]]

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Artificial Lift Request" — "WO Number <wo> Artificial Lift need Approval."

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $AL3

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $AL3 listed
```

![[Screenshot 2026-11-16 at 16.18.40.png]]
![[Screenshot 2026-11-16 at 16.07.16.png]]
![[Screenshot 2026-11-16 at 16.07.21.png]]

**3. PO will reject and add approval route**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL3/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "reject",
  "remarks": "Sumur sedang workover, tidak bisa well test",
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000406"
      ],
      "sla_days": 2
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ],
      "sla_days": 3
    }
  ]
}'
# expect: approval_status reject_in_approval, current_level 1
```

![[Screenshot 2026-11-16 at 16.07.27.png]]

**4. Manager level 1 will approve to reject**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Reject Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $AL3 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL3/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: 400 — approve is not allowed in a reject round

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL3/approval/reject" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Durasi terlalu pendek, mohon dimodifikasi"
}'
# expect: reject_in_approval, current_level 2
```

![[Screenshot 2026-11-16 at 16.07.31.png]]
![[Screenshot 2026-11-16 at 16.07.35.png]]
![[Screenshot 2026-11-16 at 16.07.38.png]]
![[Screenshot 2026-11-16 at 16.07.43.png]]

**5. Manager level 2 will approve to reject**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: "Reject Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: $AL3 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL3/approval/reject" \
  -H "Authorization: Bearer <TOKEN>.superadmin" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Durasi terlalu pendek, mohon dimodifikasi"
}'
# expect: approval_status modify_returned
```

![[Screenshot 2026-11-16 at 16.08.07.png]]
![[Screenshot 2026-11-16 at 16.08.11.png]]
![[Screenshot 2026-11-16 at 16.08.16.png]]

**6. Proceed and status action plan to modify to PO**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL3" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: modify_returned

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $AL3 back in the PO review inbox

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Action Plan Rejected by Manager" — "WO Number <wo> Action Plan rejected" (whole PO pool)

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: same "Action Plan Rejected by Manager" for the SSDP creator

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL3/approval-history" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: reject cycle outcome rejected
```

![[Screenshot 2026-11-16 at 16.08.21.png]]
![[Screenshot 2026-11-16 at 16.08.26.png]]
![[Screenshot 2026-11-16 at 16.08.29.png]]
![[Screenshot 2026-11-16 at 16.08.36.png]]
![[Screenshot 2026-11-16 at 16.08.39.png]]

---

### Artificial Lift PEP — Test #4: PO reject → Mgr 1 rejects the reject (ask PO to modify)

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: data.wo_number NNNN/WO/SDA1|SDA2/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "260398ae-a128-444b-87e6-cec36168841b",
  "wo_number": "'"$WO"'",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "WHC installation",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "well_head_compressor",
    "assigned_department": "Production Operations",
    "whc_type": "mobile",
    "compression_type": 1,
    "owned_by": "rental",
    "contract_number": "CTR-PO/2026/014",
    "cost_allocation": "WBS-Z9-0042",
    "production": 0.8
  }
}'
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set AL4=<data.id>

AL4=<data.id from the submit response>
```

![[Screenshot 2026-11-16 at 16.08.42.png]]
![[Screenshot 2026-11-16 at 16.08.46.png]]

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Artificial Lift Request" — "WO Number <wo> Artificial Lift need Approval."

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $AL4

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $AL4 listed
```

![[Screenshot 2026-11-16 at 16.08.50.png]]
![[Screenshot 2026-11-16 at 16.08.58.png]]
![[Screenshot 2026-11-16 at 16.09.03.png]]

**3. PO will reject and add approval route**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL4/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "reject",
  "remarks": "Sumur sedang workover, tidak bisa well test",
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000406"
      ],
      "sla_days": 2
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ],
      "sla_days": 3
    }
  ]
}'
# expect: reject_in_approval
```

![[Screenshot 2026-11-16 at 16.09.08.png]]

**4. Manager level 1 will reject the rejected by PO**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Reject Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $AL4 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL4/approval/modify" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Jangan ditolak, mohon dimodifikasi"
}'
# expect: approval_status modify_returned
```

![[Screenshot 2026-11-16 at 16.09.11.png]]
![[Screenshot 2026-11-16 at 16.09.16.png]]
![[Screenshot 2026-11-16 at 16.09.21.png]]

**5. Proceed and status action plan to modify to PO**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL4" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: modify_returned

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "WO Number <wo> Action Plan reject rejected."

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $AL4 back in the PO review inbox
```

![[Screenshot 2026-11-16 at 16.09.25.png]]
![[Screenshot 2026-11-16 at 16.09.29.png]]
![[Screenshot 2026-11-16 at 16.09.33.png]]

---

### Artificial Lift PEP — Test #5: PO reject → Mgr 1 approves to reject → Mgr 2 rejects the reject

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: data.wo_number NNNN/WO/SDA1|SDA2/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "f2738908-2c30-4d5a-af64-9ea30771911f",
  "wo_number": "'"$WO"'",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "WHC installation",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "well_head_compressor",
    "assigned_department": "Production Operations",
    "whc_type": "mobile",
    "compression_type": 1,
    "owned_by": "rental",
    "contract_number": "CTR-PO/2026/014",
    "cost_allocation": "WBS-Z9-0042",
    "production": 0.8
  }
}'
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set AL5=<data.id>

AL5=<data.id from the submit response>
```

![[Screenshot 2026-11-16 at 16.09.36.png]]
![[Screenshot 2026-11-16 at 16.09.40.png]]

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Artificial Lift Request" — "WO Number <wo> Artificial Lift need Approval."

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $AL5

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $AL5 listed
```

![[Screenshot 2026-11-16 at 16.09.46.png]]
![[Screenshot 2026-11-16 at 16.09.53.png]]
![[Screenshot 2026-11-16 at 16.09.58.png]]

**3. PO will reject and add approval route**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL5/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "reject",
  "remarks": "Sumur sedang workover, tidak bisa well test",
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000406"
      ],
      "sla_days": 2
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ],
      "sla_days": 3
    }
  ]
}'
# expect: reject_in_approval
```

![[Screenshot 2026-11-16 at 16.10.03.png]]

**4. Manager level 1 will approve to reject**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $AL5 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL5/approval/reject" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Durasi terlalu pendek, mohon dimodifikasi"
}'
# expect: reject_in_approval, current_level 2
```

![[Screenshot 2026-11-16 at 16.10.08.png]]
![[Screenshot 2026-11-16 at 16.10.13.png]]

**5. Manager level 2 will reject the rejected by PO**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: "Reject Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: $AL5 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL5/approval/modify" \
  -H "Authorization: Bearer <TOKEN>.superadmin" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Jangan ditolak, mohon dimodifikasi"
}'
# expect: approval_status modify_returned
```

![[Screenshot 2026-11-16 at 16.10.20.png]]
![[Screenshot 2026-11-16 at 16.10.24.png]]
![[Screenshot 2026-11-16 at 16.10.29.png]]

**6. Proceed and status action plan to modify**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: modify_returned

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "WO Number <wo> Action Plan reject rejected."
```

![[Screenshot 2026-11-16 at 16.10.33.png]]
![[Screenshot 2026-11-16 at 16.10.36.png]]

---

### Artificial Lift PEP — Test #6: PO modify → Mgr 1 approves → Mgr 2 rejects the modify

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: data.wo_number NNNN/WO/SDA1|SDA2/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "b19d5533-26e5-48e5-920b-d8c9c705f5f9",
  "wo_number": "'"$WO"'",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "WHC installation",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "well_head_compressor",
    "assigned_department": "Production Operations",
    "whc_type": "mobile",
    "compression_type": 1,
    "owned_by": "rental",
    "contract_number": "CTR-PO/2026/014",
    "cost_allocation": "WBS-Z9-0042",
    "production": 0.8
  }
}'
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set AL6=<data.id>

AL6=<data.id from the submit response>
```

![[Screenshot 2026-11-16 at 16.10.38.png]]
![[Screenshot 2026-11-16 at 16.10.43.png]]

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Artificial Lift Request" — "WO Number <wo> Artificial Lift need Approval."

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $AL6

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $AL6 listed
```

![[Screenshot 2026-11-16 at 16.10.47.png]]
![[Screenshot 2026-11-16 at 16.10.54.png]]
![[Screenshot 2026-11-16 at 16.10.59.png]]

**3. PO will modify and add approval route**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL6/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "modify",
  "remarks": "Production disesuaikan",
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000406"
      ],
      "sla_days": 2
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ],
      "sla_days": 3
    },
    {
      "level": 3,
      "user_id": [
        "0b000000-0000-0000-0000-000000000407"
      ],
      "sla_days": 2
    }
  ],
  "proposed": {
    "start_date": "26-11-2026",
    "end_date": "01-12-2026",
    "pic_ids": [
      "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
    ],
    "artificial_lift": {
      "activity_type": "installation",
      "action_mode": "installation_schedule",
      "method": "well_head_compressor",
      "assigned_department": "Production Operations",
      "whc_type": "mobile",
      "compression_type": 1,
      "owned_by": "rental",
      "contract_number": "CTR-PO/2026/014",
      "cost_allocation": "WBS-Z9-0042",
      "production": 0.5
    }
  }
}'
# expect: modify_in_approval
```

![[Screenshot 2026-11-16 at 16.11.04.png]]

**4. Manager level 1 will approve**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $AL6 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL6/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: current_level 2
```

![[Screenshot 2026-11-16 at 16.11.09.png]]
![[Screenshot 2026-11-16 at 16.11.14.png]]

**5. Manager level 2 will reject the modify by PO**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: "Modify Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: $AL6 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL6/approval/reject" \
  -H "Authorization: Bearer <TOKEN>.superadmin" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Durasi terlalu pendek, mohon dimodifikasi"
}'
# expect: approval_status modify_returned
```

![[Screenshot 2026-11-16 at 16.11.18.png]]
![[Screenshot 2026-11-16 at 16.11.22.png]]
![[Screenshot 2026-11-16 at 16.11.27.png]]

**6. Proceed and status action plan to modify to PO**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL6" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: modify_returned, end_date still 28-11-2026 (live data not changed)

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "WO Number <wo> Action Plan modify rejected."
```

![[Screenshot 2026-11-16 at 16.11.31.png]]
![[Screenshot 2026-11-16 at 16.11.34.png]]

---

### Artificial Lift PEP — Test #7: back to PO (plan $AL6 from Test #6), modify again → approved

**1. Action plan is back to PO (modify_returned)**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL6" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: modify_returned

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $AL6 listed
```

![[Screenshot 2026-11-16 at 16.11.39.png]]
![[Screenshot 2026-11-16 at 16.11.44.png]]

**2. PO cannot approve**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL6/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "approve",
  "remarks": "OK, jalankan sesuai jadwal",
  "execution_department_id": "Production Operations",
  "execution_pic_id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
}'
# expect: 400 "decision must be modify | reject while the action plan is modify_returned"
```

![[Screenshot 2026-11-16 at 16.11.47.png]]

**3. PO will modify again and add approval route**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL6/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "modify",
  "remarks": "Revisi sesuai catatan Manager 2",
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000406"
      ],
      "sla_days": 2
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ],
      "sla_days": 3
    },
    {
      "level": 3,
      "user_id": [
        "0b000000-0000-0000-0000-000000000407"
      ],
      "sla_days": 2
    }
  ],
  "proposed": {
    "start_date": "26-11-2026",
    "end_date": "01-12-2026",
    "pic_ids": [
      "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
    ],
    "artificial_lift": {
      "activity_type": "installation",
      "action_mode": "installation_schedule",
      "method": "well_head_compressor",
      "assigned_department": "Production Operations",
      "whc_type": "mobile",
      "compression_type": 1,
      "owned_by": "rental",
      "contract_number": "CTR-PO/2026/014",
      "cost_allocation": "WBS-Z9-0042",
      "production": 0.5
    }
  }
}'
# expect: modify_in_approval, cycle_no 2
```

![[Screenshot 2026-11-16 at 16.11.52.png]]

**4. Manager level 1, Manager level 2, SSDP will approve**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL6/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: current_level 2

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL6/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.superadmin" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: current_level 3

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL6/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: approved
```

![[Screenshot 2026-11-16 at 16.11.57.png]]
![[Screenshot 2026-11-16 at 16.12.02.png]]
![[Screenshot 2026-11-16 at 16.12.08.png]]

**5. Proceed and status action plan**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL6" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: approved

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL6/approval-history" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: 2 cycles; cycle_no 2 with previous_cycle_id = cycle 1
```

![[Screenshot 2026-11-16 at 16.12.12.png]]
![[Screenshot 2026-11-16 at 16.12.15.png]]

---

## C. Without approval — PEP

**1. SSDP make action plan without approval and submit**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "choke",
  "draft_id": null,
  "well_id": "ea453352-e480-4b0b-81f5-e78e6ddfc02c",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "no approval",
  "ownership": "Pertamina EP",
  "choke": {
    "gas": 10,
    "oil": 20
  }
}'
# expect: approved, work_order_number null

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "sonolog",
  "draft_id": null,
  "well_id": "ea453352-e480-4b0b-81f5-e78e6ddfc02c",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "no approval",
  "ownership": "Pertamina EP",
  "sonolog": {
    "fluid_level": 100,
    "pump_intake": 50
  }
}'
# expect: approved, work_order_number null

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "others",
  "draft_id": null,
  "well_id": "ea453352-e480-4b0b-81f5-e78e6ddfc02c",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "no approval",
  "ownership": "Pertamina EP",
  "others": {
    "text_1": "scenario test",
    "text_2": "no approval"
  }
}'
# expect: approved, work_order_number null

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "ea453352-e480-4b0b-81f5-e78e6ddfc02c",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "no approval",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_update",
    "method": "pump"
  }
}'
# expect: approved, work_order_number null (artificial lift that is not WHC installation)
```

![[Screenshot 2026-11-16 at 16.12.19.png]]
![[Screenshot 2026-11-16 at 16.12.22.png]]
![[Screenshot 2026-11-16 at 16.12.25.png]]
![[Screenshot 2026-11-16 at 16.12.29.png]]

**2. No notification, no task for PO**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: nothing new for these 4 plans

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: none of these plans

curl -s "http://localhost:5071/api/v1/well-surveilence/ea453352-e480-4b0b-81f5-e78e6ddfc02c/action-plans/pep" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: 4 plans, all approved
```

![[Screenshot 2026-11-16 at 16.12.31.png]]
![[Screenshot 2026-11-16 at 16.12.38.png]]
![[Screenshot 2026-11-16 at 16.12.41.png]]

---

## D. PHSS — Test #1 and Test #2 (submitter phi.sda2)

### Well Test PHSS — Test #1: PO approve

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda2"
# expect: data.wo_number NNNN/WO/SDA1|SDA2/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/submit" \
  -H "Authorization: Bearer <TOKEN>.sda2" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "well_test",
  "draft_id": null,
  "well_id": "369a3c3a-831a-4283-a52f-4ad5654e1b54",
  "wo_number": "'"$WO"'",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "well test submit",
  "ownership": "Pertamina EP",
  "well_test": {
    "well_test_action": "schedule",
    "assigned_department": "Production Operations",
    "contract_number": "CTR-PO/2026/001",
    "well_test_type": "production_test"
  }
}'
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set PWT1=<data.id>

PWT1=<data.id from the submit response>
```

![[Screenshot 2026-11-16 at 16.12.44.png]]
![[Screenshot 2026-11-16 at 16.12.49.png]]

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Well Test Request" — "WO Number <wo> Well Test need Approval."

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $PWT1

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PWT1 listed
```

![[Screenshot 2026-11-16 at 16.12.53.png]]
![[Screenshot 2026-11-16 at 16.12.59.png]]
![[Screenshot 2026-11-16 at 16.13.04.png]]

**3. PO will approve**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PWT1/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "approve",
  "remarks": "OK, jalankan sesuai jadwal",
  "execution_department_id": "Production Operations",
  "execution_pic_id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
}'
# expect: approval_status approved
```

![[Screenshot 2026-11-16 at 16.13.08.png]]

**4. Action plan change status show on list of action plan**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/369a3c3a-831a-4283-a52f-4ad5654e1b54/action-plans/phss" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PWT1 with approval_status approved, progress = date status (not routing)

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PWT1" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: approval_status approved

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda2"
# expect: "Well Test In Progress"

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PWT1 gone from action_plan_review
```

![[Screenshot 2026-11-16 at 16.13.12.png]]
![[Screenshot 2026-11-16 at 16.13.16.png]]
![[Screenshot 2026-11-16 at 16.13.23.png]]
![[Screenshot 2026-11-16 at 16.13.30.png]]

---

### Well Test PHSS — Test #2: PO modify → Mgr 1 → Mgr 2 → SSDP approve

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda2"
# expect: data.wo_number NNNN/WO/SDA1|SDA2/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/submit" \
  -H "Authorization: Bearer <TOKEN>.sda2" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "well_test",
  "draft_id": null,
  "well_id": "2ae63735-0fe4-4b5f-b100-a86fec8044e9",
  "wo_number": "'"$WO"'",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "well test submit",
  "ownership": "Pertamina EP",
  "well_test": {
    "well_test_action": "schedule",
    "assigned_department": "Production Operations",
    "contract_number": "CTR-PO/2026/001",
    "well_test_type": "production_test"
  }
}'
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set PWT2=<data.id>

PWT2=<data.id from the submit response>
```

![[Screenshot 2026-11-16 at 16.13.33.png]]
![[Screenshot 2026-11-16 at 16.13.37.png]]

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Well Test Request" — "WO Number <wo> Well Test need Approval."

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $PWT2

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PWT2 listed
```

![[Screenshot 2026-11-16 at 16.13.41.png]]
![[Screenshot 2026-11-16 at 16.13.47.png]]
![[Screenshot 2026-11-16 at 16.13.52.png]]

**3. PO will modify and add approval route**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PWT2/approval-route" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: prefill levels from Data Config (optional)

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PWT2/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "modify",
  "remarks": "Geser jadwal, durasi jadi 12 jam",
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000406"
      ],
      "sla_days": 2
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ],
      "sla_days": 3
    },
    {
      "level": 3,
      "user_id": [
        "0b000000-0000-0000-0000-000000000407"
      ],
      "sla_days": 2
    }
  ],
  "execution_department_id": "Production Operations",
  "execution_pic_id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
  "proposed": {
    "start_date": "26-11-2026",
    "end_date": "01-12-2026",
    "pic_ids": [
      "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
    ],
    "notes": "jadwal digeser oleh PO",
    "well_test": {
      "well_test_action": "schedule",
      "assigned_department": "Production Operations",
      "contract_number": "CTR-PO/2026/001",
      "well_test_type": "production_test"
    }
  }
}'
# expect: approval_status modify_in_approval, current_level 1, total_levels 3
```

![[Screenshot 2026-11-16 at 16.13.55.png]]
![[Screenshot 2026-11-16 at 16.14.03.png]]

**4. Manager level 1 will approve**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Modify Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PWT2 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PWT2/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: current_level 2
```

![[Screenshot 2026-11-16 at 16.14.06.png]]
![[Screenshot 2026-11-16 at 16.14.10.png]]
![[Screenshot 2026-11-16 at 16.14.15.png]]

**5. Manager level 2 will approve**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: "Modify Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: $PWT2 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PWT2/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.superadmin" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: current_level 3
```

![[Screenshot 2026-11-16 at 16.14.19.png]]
![[Screenshot 2026-11-16 at 16.14.24.png]]
![[Screenshot 2026-11-16 at 16.14.29.png]]

**6. SSDP will approve**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: "Modify Action Plan" — "… has been modified by Production Operations and requires your approval."

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: $PWT2 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PWT2/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: approval_status approved
```

![[Screenshot 2026-11-16 at 16.14.34.png]]
![[Screenshot 2026-11-16 at 16.14.38.png]]
![[Screenshot 2026-11-16 at 16.14.44.png]]

**7. Proceed and status action plan**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PWT2" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: approved, end_date 01-12-2026

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PWT2/modification-diff" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: changes listed

curl -s "http://localhost:5071/api/v1/well-surveilence/2ae63735-0fe4-4b5f-b100-a86fec8044e9/action-plans/phss" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PWT2 approved

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda2"
# expect: "Well Test In Progress"
```

![[Screenshot 2026-11-16 at 16.14.48.png]]
![[Screenshot 2026-11-16 at 16.14.51.png]]
![[Screenshot 2026-11-16 at 16.14.55.png]]
![[Screenshot 2026-11-16 at 16.14.59.png]]

---

### Artificial Lift PHSS — Test #1: PO approve

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda2"
# expect: data.wo_number NNNN/WO/SDA1|SDA2/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/submit" \
  -H "Authorization: Bearer <TOKEN>.sda2" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "8cfb701c-7ae5-4f7d-8bcf-96b7b9c85cb8",
  "wo_number": "'"$WO"'",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "WHC installation",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "well_head_compressor",
    "assigned_department": "Production Operations",
    "whc_type": "mobile",
    "compression_type": 1,
    "owned_by": "rental",
    "contract_number": "CTR-PO/2026/014",
    "cost_allocation": "WBS-Z9-0042",
    "production": 0.8
  }
}'
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set PAL1=<data.id>

PAL1=<data.id from the submit response>
```

![[Screenshot 2026-11-16 at 16.15.03.png]]
![[Screenshot 2026-11-16 at 16.15.07.png]]

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Artificial Lift Request" — "WO Number <wo> Artificial Lift need Approval."

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $PAL1

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PAL1 listed
```

![[Screenshot 2026-11-16 at 16.15.11.png]]
![[Screenshot 2026-11-16 at 16.15.17.png]]
![[Screenshot 2026-11-16 at 16.15.22.png]]

**3. PO will approve**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL1/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "approve",
  "remarks": "OK, jalankan sesuai jadwal",
  "execution_department_id": "Production Operations",
  "execution_pic_id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
}'
# expect: approval_status approved
```

![[Screenshot 2026-11-16 at 16.15.27.png]]

**4. Action plan change status show on list of action plan**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/8cfb701c-7ae5-4f7d-8bcf-96b7b9c85cb8/action-plans/phss" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PAL1 with approval_status approved, progress = date status (not routing)

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL1" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: approval_status approved

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda2"
# expect: "Artificial Lift In Progress"

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PAL1 gone from action_plan_review
```

![[Screenshot 2026-11-16 at 16.15.31.png]]
![[Screenshot 2026-11-16 at 16.15.35.png]]
![[Screenshot 2026-11-16 at 16.15.38.png]]
![[Screenshot 2026-11-16 at 16.15.44.png]]

---

### Artificial Lift PHSS — Test #2: PO modify → Mgr 1 → Mgr 2 → SSDP approve

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda2"
# expect: data.wo_number NNNN/WO/SDA1|SDA2/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/submit" \
  -H "Authorization: Bearer <TOKEN>.sda2" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "be8f8bec-f7ee-4214-a0ff-4e3db17564bd",
  "wo_number": "'"$WO"'",
  "start_date": "2026-11-26",
  "end_date": "2026-11-28",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "WHC installation",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "well_head_compressor",
    "assigned_department": "Production Operations",
    "whc_type": "mobile",
    "compression_type": 1,
    "owned_by": "rental",
    "contract_number": "CTR-PO/2026/014",
    "cost_allocation": "WBS-Z9-0042",
    "production": 0.8
  }
}'
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set PAL2=<data.id>

PAL2=<data.id from the submit response>
```

![[Screenshot 2026-11-16 at 16.15.47.png]]
![[Screenshot 2026-11-16 at 16.15.51.png]]

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Artificial Lift Request" — "WO Number <wo> Artificial Lift need Approval."

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $PAL2

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PAL2 listed
```

![[Screenshot 2026-11-16 at 16.15.55.png]]
![[Screenshot 2026-11-16 at 16.16.02.png]]
![[Screenshot 2026-11-16 at 16.16.07.png]]

**3. PO will modify and add approval route**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL2/approval-route" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: prefill levels from Data Config (optional)

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL2/review" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "modify",
  "remarks": "Production disesuaikan",
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000406"
      ],
      "sla_days": 2
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ],
      "sla_days": 3
    },
    {
      "level": 3,
      "user_id": [
        "0b000000-0000-0000-0000-000000000407"
      ],
      "sla_days": 2
    }
  ],
  "proposed": {
    "start_date": "26-11-2026",
    "end_date": "01-12-2026",
    "pic_ids": [
      "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
    ],
    "artificial_lift": {
      "activity_type": "installation",
      "action_mode": "installation_schedule",
      "method": "well_head_compressor",
      "assigned_department": "Production Operations",
      "whc_type": "mobile",
      "compression_type": 1,
      "owned_by": "rental",
      "contract_number": "CTR-PO/2026/014",
      "cost_allocation": "WBS-Z9-0042",
      "production": 0.5
    }
  }
}'
# expect: approval_status modify_in_approval, current_level 1, total_levels 3
```

![[Screenshot 2026-11-16 at 16.16.10.png]]
![[Screenshot 2026-11-16 at 16.16.15.png]]

**4. Manager level 1 will approve**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Modify Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PAL2 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL2/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: current_level 2
```

![[Screenshot 2026-11-16 at 16.16.18.png]]
![[Screenshot 2026-11-16 at 16.16.22.png]]
![[Screenshot 2026-11-16 at 16.16.27.png]]

**5. Manager level 2 will approve**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: "Modify Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: $PAL2 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL2/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.superadmin" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: current_level 3
```

![[Screenshot 2026-11-16 at 16.16.31.png]]
![[Screenshot 2026-11-16 at 16.16.35.png]]
![[Screenshot 2026-11-16 at 16.16.39.png]]

**6. SSDP will approve**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: "Modify Action Plan" — "WO Number <wo> Artificial Lift Installation has been modified by Production Operations."

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: $PAL2 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL2/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: approval_status approved
```

![[Screenshot 2026-11-16 at 16.16.43.png]]
![[Screenshot 2026-11-16 at 16.16.47.png]]
![[Screenshot 2026-11-16 at 16.16.52.png]]

**7. Proceed and status action plan**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL2" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: approved, end_date 01-12-2026, artificial_lift.production 0.5

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL2/modification-diff" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: changes listed

curl -s "http://localhost:5071/api/v1/well-surveilence/be8f8bec-f7ee-4214-a0ff-4e3db17564bd/action-plans/phss" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PAL2 approved

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda2"
# expect: "Artificial Lift In Progress"
```

![[Screenshot 2026-11-16 at 16.16.56.png]]
![[Screenshot 2026-11-16 at 16.16.59.png]]
![[Screenshot 2026-11-16 at 16.17.02.png]]
![[Screenshot 2026-11-16 at 16.17.06.png]]

---

## Check on every step

Notification (any user — swap the token):

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.superadmin"

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda1"
```

![[Screenshot 2026-11-16 at 16.17.09.png]]
![[Screenshot 2026-11-16 at 16.17.12.png]]
![[Screenshot 2026-11-16 at 16.17.16.png]]

Task — PO only while `waiting_review` / `modify_returned`; each level only on its turn:

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.superadmin"

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"

curl -s "http://localhost:5071/api/v1/my-approval-list" \
  -H "Authorization: Bearer <TOKEN>.superadmin"

curl -s "http://localhost:5071/api/v1/my-task-badge" \
  -H "Authorization: Bearer <TOKEN>.po"
```

![[Screenshot 2026-11-16 at 16.17.21.png]]
![[Screenshot 2026-11-16 at 16.17.23.png]]
![[Screenshot 2026-11-16 at 16.17.30.png]]
![[Screenshot 2026-11-16 at 16.17.38.png]]
![[Screenshot 2026-11-16 at 16.17.45.png]]

Visibility (PHI-2442) — phi.sda2 has no part in PEP plan $WT2: expect 400 "Action plan not found" and not in the list:

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT2" \
  -H "Authorization: Bearer <TOKEN>.sda2"
# expect: 400 "Action plan not found"

curl -s "http://localhost:5071/api/v1/well-surveilence/04170a12-f3ad-491c-a36b-b972f1574479/action-plans/pep" \
  -H "Authorization: Bearer <TOKEN>.sda2"
# expect: $WT2 not listed
```

![[Screenshot 2026-11-16 at 16.17.48.png]]
![[Screenshot 2026-11-16 at 16.17.52.png]]

View only (PHI-2442) — run while $WT2 waits on level 2: only Manager level 2 has can_approve / can_reject true:

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT2" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: can_approve false, can_reject false

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$WT2" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: can_approve true, can_reject true
```

![[Screenshot 2026-11-16 at 16.17.56.png]]
![[Screenshot 2026-11-16 at 16.18.00.png]]

In a reject round (e.g. $WT3 after step 3): can_approve false, can_reject true for the pending level (covers approval/reject and approval/modify).
