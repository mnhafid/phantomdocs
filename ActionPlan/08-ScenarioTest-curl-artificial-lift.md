# 08-ScenarioTest — Artificial Lift (WHC installation) curl per step

> **Contains live dev tokens.** Local only (`.git/info/exclude`). Do not share or commit it.

## Setup

Run the API:
```bash
cd /Users/hafidhidayatullah/Stuffs/Grounds/OceanInovasi/phi/phiDev/.worktrees/phi-2243-ap-approval/src-be/WebApi && dotnet run   # http://localhost:5071
```

| Role | User | Id |
|---|---|---|
| SSDP PEP submitter + level 3 approver | phi.sda1 | `0b000000-0000-0000-0000-000000000407` |
| SSDP PHSS submitter | phi.sda2 | `0b000000-0000-0000-0000-000000000408` |
| PO reviewer + Manager level 1 | phi.po | `0b000000-0000-0000-0000-000000000406` |
| Manager level 2 | phi.superadmin | `0b000000-0000-0000-0000-000000000409` |

- Needs approval: `artificial_lift` with `method = well_head_compressor` **and** `activity_type = installation`. Everything else is auto-approved.
- PO approve: execution department / PIC **optional** for artificial lift.
- Modify may not change `activity_type`, `method`, `wo_number`, `action_plan_type`, `well_id`; `action_mode` and the other fields may change.
- Every test has its own well (PEP) or its own date window (PHSS shares 4 wells), so `installation_schedule` plans never overlap.
- After each submit set the variable from `data.id` (e.g. `AL1=<id>`); the next curls use `$AL1`.
- WHC field rules (`whc_type`, `compression_type`, `owned_by`, production ≤ compression type) are enforced only with commit `70ef1047` (`phi-2242-ap-al-whc`). In `phi-2243-ap-approval` they are accepted but not stored; the approval flow is the same.

## Level actions

| Round | Level action | Endpoint | Result |
|---|---|---|---|
| Modify | approve | `…/{id}/approval/approve` | next level; last level applies the proposal → `approved` |
| Modify | reject the modify | `…/{id}/approval/reject` | `modify_returned`, PO pool gets "modify rejected" |
| Reject | approve to reject | `…/{id}/approval/reject` | next level; last level → `modify_returned`, PO pool + SSDP creator get "Action Plan Rejected by Manager" |
| Reject | reject the reject (ask PO to modify) | `…/{id}/approval/modify` | `modify_returned`, PO pool gets "reject rejected" |
| Reject | approve | `…/{id}/approval/approve` | 400 |


## Request bodies

Every request body follows the Bruno PR [phi-phantom-collections #176](https://github.com/oceaninov/phi-phantom-collections/pull/176) (`feat/action-plan-approval`, head `7fde611`):

| Request | PR file | Notes |
|---|---|---|
| Submit well test / artificial lift | `Submit Action Plan PEP - WO & Approval Status.yml`, `Submit Action Plan PEP - Artificial Lift.yml` | `wo_number` comes from `GET …/next-wo-number` (step before each submit). PHSS well test has no `planned_duration_hours` / `tank_number` / `start_date_time` / `end_date_time` |
| PO approve / modify / reject | `Review Action Plan.yml` (examples Approve, Modify PEP well test, Modify PHSS artificial lift WHC, Reject, Modify from modify_returned) | `proposed` has no `action_plan_type`, `well_id`, `ownership` like the PR |
| Level approve / reject | `Approve Action Plan Level.yml`, `Reject Action Plan Level.yml` | |
| Level modify (ask PO to modify) | not in the PR yet (new endpoint) | `{ "remarks": … }` |

> Like the PR, `proposed` leaves out `ownership` (and `notes` for artificial lift). The final approval writes the proposal as the whole plan, so `ownership` becomes empty and shows in `modification-diff`.


## A. Artificial Lift — PEP (submitter phi.sda1)

### Artificial Lift PEP — Test #1: PO approve

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: data.wo_number NNNN/WO/SDA{'1' if src=='pep' else '2'}/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "2614f6a1-a9e6-409b-b17c-544b512c97b7",
  "wo_number": "'"$WO"'",
  "start_date": "2026-12-14",
  "end_date": "2026-12-16",
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

**4. Action plan change status show on list of action plan**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/2614f6a1-a9e6-409b-b17c-544b512c97b7/action-plans/pep" \
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

---

### Artificial Lift PEP — Test #2: PO modify → Mgr 1 → Mgr 2 → SSDP approve

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: data.wo_number NNNN/WO/SDA{'1' if src=='pep' else '2'}/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "2acffaeb-17db-4eb5-9871-b209baabf50c",
  "wo_number": "'"$WO"'",
  "start_date": "2026-12-21",
  "end_date": "2026-12-23",
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
    "start_date": "21-12-2026",
    "end_date": "26-12-2026",
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

**7. Proceed and status action plan**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL2" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: approved, end_date 26-12-2026, artificial_lift.production 0.5

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL2/modification-diff" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: changes listed

curl -s "http://localhost:5071/api/v1/well-surveilence/2acffaeb-17db-4eb5-9871-b209baabf50c/action-plans/pep" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $AL2 approved

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: "Artificial Lift In Progress"
```

---

### Artificial Lift PEP — Test #3: PO reject → Mgr 1 and Mgr 2 approve to reject → back to PO

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: data.wo_number NNNN/WO/SDA{'1' if src=='pep' else '2'}/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "1dc3c689-16a0-4a0e-a73f-995d7f59ceac",
  "wo_number": "'"$WO"'",
  "start_date": "2026-12-28",
  "end_date": "2026-12-30",
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

---

### Artificial Lift PEP — Test #4: PO reject → Mgr 1 rejects the reject (ask PO to modify)

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: data.wo_number NNNN/WO/SDA{'1' if src=='pep' else '2'}/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "224f2b7b-59d4-4a62-98e7-628b10b5bd04",
  "wo_number": "'"$WO"'",
  "start_date": "2027-01-04",
  "end_date": "2027-01-06",
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

---

### Artificial Lift PEP — Test #5: PO reject → Mgr 1 approves to reject → Mgr 2 rejects the reject

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: data.wo_number NNNN/WO/SDA{'1' if src=='pep' else '2'}/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "bdd3c526-ca9c-4b08-bf6f-cf445d1d557f",
  "wo_number": "'"$WO"'",
  "start_date": "2027-01-11",
  "end_date": "2027-01-13",
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

**6. Proceed and status action plan to modify**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: modify_returned

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "WO Number <wo> Action Plan reject rejected."
```

---

### Artificial Lift PEP — Test #6: PO modify → Mgr 1 approves → Mgr 2 rejects the modify

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: data.wo_number NNNN/WO/SDA{'1' if src=='pep' else '2'}/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "1d6f882e-7f3e-4ce1-a5af-cb45b8f8533a",
  "wo_number": "'"$WO"'",
  "start_date": "2027-01-18",
  "end_date": "2027-01-20",
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
    "start_date": "18-01-2027",
    "end_date": "23-01-2027",
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

**6. Proceed and status action plan to modify to PO**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL6" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: modify_returned, end_date still 20-01-2027 (live data not changed)

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "WO Number <wo> Action Plan modify rejected."
```

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
    "start_date": "18-01-2027",
    "end_date": "23-01-2027",
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

**5. Proceed and status action plan**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL6" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: approved

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL6/approval-history" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: 2 cycles; cycle_no 2 with previous_cycle_id = cycle 1
```

---

## B. Artificial Lift — PHSS (submitter phi.sda2)

### Artificial Lift PHSS — Test #1: PO approve

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda2"
# expect: data.wo_number NNNN/WO/SDA{'1' if src=='pep' else '2'}/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/submit" \
  -H "Authorization: Bearer <TOKEN>.sda2" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "369a3c3a-831a-4283-a52f-4ad5654e1b54",
  "wo_number": "'"$WO"'",
  "start_date": "2027-02-08",
  "end_date": "2027-02-10",
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

**4. Action plan change status show on list of action plan**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/369a3c3a-831a-4283-a52f-4ad5654e1b54/action-plans/phss" \
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

---

### Artificial Lift PHSS — Test #2: PO modify → Mgr 1 → Mgr 2 → SSDP approve

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda2"
# expect: data.wo_number NNNN/WO/SDA{'1' if src=='pep' else '2'}/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/submit" \
  -H "Authorization: Bearer <TOKEN>.sda2" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "2ae63735-0fe4-4b5f-b100-a86fec8044e9",
  "wo_number": "'"$WO"'",
  "start_date": "2027-02-15",
  "end_date": "2027-02-17",
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
    "start_date": "15-02-2027",
    "end_date": "20-02-2027",
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

**7. Proceed and status action plan**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL2" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: approved, end_date 20-02-2027, artificial_lift.production 0.5

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL2/modification-diff" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: changes listed

curl -s "http://localhost:5071/api/v1/well-surveilence/2ae63735-0fe4-4b5f-b100-a86fec8044e9/action-plans/phss" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PAL2 approved

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda2"
# expect: "Artificial Lift In Progress"
```

---

### Artificial Lift PHSS — Test #3: PO reject → Mgr 1 and Mgr 2 approve to reject → back to PO

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda2"
# expect: data.wo_number NNNN/WO/SDA{'1' if src=='pep' else '2'}/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/submit" \
  -H "Authorization: Bearer <TOKEN>.sda2" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "8cfb701c-7ae5-4f7d-8bcf-96b7b9c85cb8",
  "wo_number": "'"$WO"'",
  "start_date": "2027-02-22",
  "end_date": "2027-02-24",
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
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set PAL3=<data.id>

PAL3=<data.id from the submit response>
```

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Artificial Lift Request" — "WO Number <wo> Artificial Lift need Approval."

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $PAL3

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PAL3 listed
```

**3. PO will reject and add approval route**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL3/review" \
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

**4. Manager level 1 will approve to reject**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Reject Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PAL3 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL3/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: 400 — approve is not allowed in a reject round

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL3/approval/reject" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Durasi terlalu pendek, mohon dimodifikasi"
}'
# expect: reject_in_approval, current_level 2
```

**5. Manager level 2 will approve to reject**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: "Reject Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: $PAL3 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL3/approval/reject" \
  -H "Authorization: Bearer <TOKEN>.superadmin" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Durasi terlalu pendek, mohon dimodifikasi"
}'
# expect: approval_status modify_returned
```

**6. Proceed and status action plan to modify to PO**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL3" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: modify_returned

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PAL3 back in the PO review inbox

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Action Plan Rejected by Manager" — "WO Number <wo> Action Plan rejected" (whole PO pool)

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda2"
# expect: same "Action Plan Rejected by Manager" for the SSDP creator

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL3/approval-history" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: reject cycle outcome rejected
```

---

### Artificial Lift PHSS — Test #4: PO reject → Mgr 1 rejects the reject (ask PO to modify)

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda2"
# expect: data.wo_number NNNN/WO/SDA{'1' if src=='pep' else '2'}/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/submit" \
  -H "Authorization: Bearer <TOKEN>.sda2" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "be8f8bec-f7ee-4214-a0ff-4e3db17564bd",
  "wo_number": "'"$WO"'",
  "start_date": "2027-03-01",
  "end_date": "2027-03-03",
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
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set PAL4=<data.id>

PAL4=<data.id from the submit response>
```

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Artificial Lift Request" — "WO Number <wo> Artificial Lift need Approval."

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $PAL4

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PAL4 listed
```

**3. PO will reject and add approval route**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL4/review" \
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

**4. Manager level 1 will reject the rejected by PO**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Reject Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PAL4 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL4/approval/modify" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Jangan ditolak, mohon dimodifikasi"
}'
# expect: approval_status modify_returned
```

**5. Proceed and status action plan to modify to PO**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL4" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: modify_returned

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "WO Number <wo> Action Plan reject rejected."

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PAL4 back in the PO review inbox
```

---

### Artificial Lift PHSS — Test #5: PO reject → Mgr 1 approves to reject → Mgr 2 rejects the reject

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda2"
# expect: data.wo_number NNNN/WO/SDA{'1' if src=='pep' else '2'}/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/submit" \
  -H "Authorization: Bearer <TOKEN>.sda2" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "369a3c3a-831a-4283-a52f-4ad5654e1b54",
  "wo_number": "'"$WO"'",
  "start_date": "2027-03-08",
  "end_date": "2027-03-10",
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
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set PAL5=<data.id>

PAL5=<data.id from the submit response>
```

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Artificial Lift Request" — "WO Number <wo> Artificial Lift need Approval."

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $PAL5

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PAL5 listed
```

**3. PO will reject and add approval route**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL5/review" \
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

**4. Manager level 1 will approve to reject**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PAL5 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL5/approval/reject" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Durasi terlalu pendek, mohon dimodifikasi"
}'
# expect: reject_in_approval, current_level 2
```

**5. Manager level 2 will reject the rejected by PO**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: "Reject Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: $PAL5 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL5/approval/modify" \
  -H "Authorization: Bearer <TOKEN>.superadmin" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Jangan ditolak, mohon dimodifikasi"
}'
# expect: approval_status modify_returned
```

**6. Proceed and status action plan to modify**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: modify_returned

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "WO Number <wo> Action Plan reject rejected."
```

---

### Artificial Lift PHSS — Test #6: PO modify → Mgr 1 approves → Mgr 2 rejects the modify

**1. SSDP make action plan and submit**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer <TOKEN>.sda2"
# expect: data.wo_number NNNN/WO/SDA{'1' if src=='pep' else '2'}/2026 → set WO=<data.wo_number> (used once, by the submit below)

WO=<data.wo_number>

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/submit" \
  -H "Authorization: Bearer <TOKEN>.sda2" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "2ae63735-0fe4-4b5f-b100-a86fec8044e9",
  "wo_number": "'"$WO"'",
  "start_date": "2027-03-15",
  "end_date": "2027-03-17",
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
# expect: data.approval_status waiting_review, data.work_order_number = $WO → set PAL6=<data.id>

PAL6=<data.id from the submit response>
```

**2. PO will get notif on task and notif center**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "Artificial Lift Request" — "WO Number <wo> Artificial Lift need Approval."

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: section action_plan_review holds $PAL6

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PAL6 listed
```

**3. PO will modify and add approval route**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL6/review" \
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
    "start_date": "15-03-2027",
    "end_date": "20-03-2027",
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

**4. Manager level 1 will approve**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PAL6 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL6/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: current_level 2
```

**5. Manager level 2 will reject the modify by PO**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: "Modify Action Plan"

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: $PAL6 listed

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL6/approval/reject" \
  -H "Authorization: Bearer <TOKEN>.superadmin" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Durasi terlalu pendek, mohon dimodifikasi"
}'
# expect: approval_status modify_returned
```

**6. Proceed and status action plan to modify to PO**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL6" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: modify_returned, end_date still 17-03-2027 (live data not changed)

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: "WO Number <wo> Action Plan modify rejected."
```

---

### Artificial Lift PHSS — Test #7: back to PO (plan $PAL6 from Test #6), modify again → approved

**1. Action plan is back to PO (modify_returned)**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL6" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: modify_returned

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: $PAL6 listed
```

**2. PO cannot approve**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL6/review" \
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

**3. PO will modify again and add approval route**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL6/review" \
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
    "start_date": "15-03-2027",
    "end_date": "20-03-2027",
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

**4. Manager level 1, Manager level 2, SSDP will approve**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL6/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.po" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: current_level 2

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL6/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.superadmin" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: current_level 3

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL6/approval/approve" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
# expect: approved
```

**5. Proceed and status action plan**

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL6" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: approved

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/phss/$PAL6/approval-history" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: 2 cycles; cycle_no 2 with previous_cycle_id = cycle 1
```

---

## C. Artificial Lift without approval — PEP

**1. SSDP submit artificial lift that is not WHC installation**

```bash
curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "e1609af4-3368-4338-8456-535f6dd2e0f7",
  "start_date": "2026-12-07",
  "end_date": "2026-12-09",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "no approval",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "pump"
  }
}'
# expect: installation + pump → approved at once, work_order_number null

curl -s -X POST "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer <TOKEN>.sda1" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "d704cd24-113b-4c1b-b845-117b3f97a08a",
  "start_date": "2026-12-07",
  "end_date": "2026-12-09",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "notes": "no approval",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "adjustment",
    "action_mode": "adjustment_schedule",
    "method": "well_head_compressor"
  }
}'
# expect: adjustment + well_head_compressor → approved at once, work_order_number null
```

**2. No notification, no task for PO**

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: no "Artificial Lift Request" for these 2 plans

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: neither plan in action_plan_review

curl -s "http://localhost:5071/api/v1/well-surveilence/e1609af4-3368-4338-8456-535f6dd2e0f7/action-plans/pep" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: plan approved

curl -s "http://localhost:5071/api/v1/well-surveilence/d704cd24-113b-4c1b-b845-117b3f97a08a/action-plans/pep" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: plan approved
```

---

## Check on every step

```bash
curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: PO pool

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: Manager level 2

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda1"
# expect: SSDP PEP creator

curl -s "http://localhost:5071/api/v1/notifications/mine?page=1&page_size=5" \
  -H "Authorization: Bearer <TOKEN>.sda2"
# expect: SSDP PHSS creator

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: PO only while waiting_review / modify_returned

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/approvals/need-action?stage=approval" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: only on its level's turn

curl -s "http://localhost:5071/api/v1/my-task-list" \
  -H "Authorization: Bearer <TOKEN>.po"

curl -s "http://localhost:5071/api/v1/my-approval-list" \
  -H "Authorization: Bearer <TOKEN>.superadmin"

curl -s "http://localhost:5071/api/v1/my-task-badge" \
  -H "Authorization: Bearer <TOKEN>.po"
```

View only — while $AL2 waits on level 2:

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL2" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: can_approve false, can_reject false

curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL2" \
  -H "Authorization: Bearer <TOKEN>.superadmin"
# expect: can_approve true, can_reject true
```

Reject round — $AL3 after step 3: level 1 has can_approve false, can_reject true (covers approval/reject and approval/modify):

```bash
curl -s "http://localhost:5071/api/v1/well-surveilence/action-plans/pep/$AL3" \
  -H "Authorization: Bearer <TOKEN>.po"
# expect: can_approve false, can_reject true
```
