# Action Plan PEP SRP: E2E scenario curl per step (PHI-2494 / 2495)

> Local only (`docs/` is not in git). Tokens are never written here: set them in the shell first.

Run 2026-11-19 18:24, local API (`http://localhost:5091/api/v1`) on the dev DB. Your own run can use `http://localhost:5071/api/v1`. Branch `feat/phi-2494-ap-srp-esp`.
**38 of 50 matched the expected result.**

Each flow runs from the WO number to the final status. Flows: Approve, Modify, Reject, for Installation Schedule and for Installation Update.

| Role | User |
|---|---|
| SSDP submitter, last Modify level (creator) | phi.sda1 |
| PO reviewer | phi.po |
| Manager level 1 (route in the review payload) | phi.superadmin |

## Setup

```bash
API=http://localhost:5071/api/v1
SSDP=<access_token of phi.sda1 from mock_auth_sessions, stage=token>      # PEP submitter, creator = last Modify level
SSDP2=<access_token of phi.sda2 from mock_auth_sessions, stage=token>     # PHSS submitter
PO=<access_token of phi.po from mock_auth_sessions, stage=token>          # PO review pool (161)
MGR=<access_token of phi.superadmin from mock_auth_sessions, stage=token> # Manager level (162 / 163)
```

## Summary

| # | Case | Result |
|---|---|---|
| 1 | Next WO number (SSDP) | PASS |
| 2 | SSDP submits | PASS |
| 3 | PO sees the plan in need-action (review) | PASS |
| 4 | PO gets the request notification | FAIL |
| 5 | PO approves | PASS |
| 6 | Detail shows approved | PASS |
| 7 | SSDP gets the result notification | FAIL |
| 8 | Next WO number (SSDP) | PASS |
| 9 | SSDP submits | PASS |
| 10 | PO sees the plan in need-action (review) | PASS |
| 11 | PO gets the request notification | FAIL |
| 12 | PO modifies (manager → SSDP creator) | PASS |
| 13 | Modification diff | PASS |
| 14 | Manager level 1 approves | PASS |
| 15 | SSDP creator (last level) approves → proposal applied | PASS |
| 16 | Detail shows the applied proposal | PASS |
| 17 | SSDP gets the result notification | FAIL |
| 18 | Next WO number (SSDP) | PASS |
| 19 | SSDP submits | PASS |
| 20 | PO sees the plan in need-action (review) | PASS |
| 21 | PO gets the request notification | FAIL |
| 22 | PO rejects (reject round) | PASS |
| 23 | Manager agrees → rejected | PASS |
| 24 | Detail shows rejected | PASS |
| 25 | SSDP gets the result notification | FAIL |
| 26 | Next WO number (SSDP) | PASS |
| 27 | SSDP submits | PASS |
| 28 | PO sees the plan in need-action (review) | PASS |
| 29 | PO gets the request notification | FAIL |
| 30 | PO approves | PASS |
| 31 | Detail shows approved | PASS |
| 32 | SSDP gets the result notification | FAIL |
| 33 | Next WO number (SSDP) | PASS |
| 34 | SSDP submits | PASS |
| 35 | PO sees the plan in need-action (review) | PASS |
| 36 | PO gets the request notification | FAIL |
| 37 | PO modifies (manager → SSDP creator) | PASS |
| 38 | Modification diff | PASS |
| 39 | Manager level 1 approves | PASS |
| 40 | SSDP creator (last level) approves → proposal applied | PASS |
| 41 | Detail shows the applied proposal | PASS |
| 42 | SSDP gets the result notification | FAIL |
| 43 | Next WO number (SSDP) | PASS |
| 44 | SSDP submits | PASS |
| 45 | PO sees the plan in need-action (review) | PASS |
| 46 | PO gets the request notification | FAIL |
| 47 | PO rejects (reject round) | PASS |
| 48 | Manager agrees → rejected | PASS |
| 49 | Detail shows rejected | PASS |
| 50 | SSDP gets the result notification | FAIL |

## Installation Schedule

### SRP Installation Schedule — Approve

#### 1. Next WO number (SSDP)

```bash
curl -s -X GET "$API/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, `data.wo_number` = `NNNN/WO/{short}/{year}` → set `WO`

**Actual:** HTTP 200

```json
{
  "data": {
    "sequence_number": "0072",
    "wo_number": "0072/WO/SDA1/2026"
  },
  "status": "success",
  "code": "00",
  "message": "Get next work order number succeed"
}
```

`WO=0072/WO/SDA1/2026`
**Result:** PASS

#### 2. SSDP submits

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "bdd3c526-ca9c-4b08-bf6f-cf445d1d557f",
  "start_date": "2027-03-01",
  "end_date": "2027-03-03",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "sucker_rod_pump",
    "assigned_department": "Production Operations",
    "pump_type": "Insert Pump",
    "pump_brand": "Weatherford",
    "stroke_length": 86,
    "spmfreq": 8.5,
    "prime_mover_name": "Gas Engine G3306",
    "power": 40,
    "owned_by": "rental",
    "contract_number": "CTR-PO/2026/021",
    "asset_number": "AST-DROP",
    "production": 120,
    "pressure": 150
  },
  "wo_number": "'"$WO"'"
}'
```

**Expected:** HTTP 200, `data.approval_status` = `waiting_review`, `data.work_order_number` = `$WO`

**Actual:** HTTP 200

```json
{
  "data": {
    "id": "fd029981-4a9f-488d-8af6-e350a247d9de",
    "record_state": "submitted",
    "approval_status": "waiting_review",
    "work_order_number": "0072/WO/SDA1/2026"
  },
  "status": "success",
  "code": "00",
  "message": "Submit action plan PEP succeed"
}
```

`PLAN=fd029981-4a9f-488d-8af6-e350a247d9de`
**Result:** PASS

#### 3. PO sees the plan in need-action (review)

```bash
curl -s -X GET "$API/well-surveilence/action-plans/approvals/need-action?stage=review&source=pep&action_plan_type=artificial_lift&page_size=500" \
  -H "Authorization: Bearer $PO"
```

**Expected:** HTTP 200, the list holds `$PLAN`

**Actual:** HTTP 200

```json
{
  "data": {
    "items": [
      {
        "id": "7a6d7ae6-1a23-4a0c-b307-611449196bcc",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "1bad4d3a-b752-4b3f-ae0f-21c1ef321f71",
          "name": "A-INDANA-PEP"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0007/WO/SDA1/2026",
        "cycle_no": null,
        "path": null,
        "current_level": null,
        "total_level": null,
        "start_date": "16-11-2026",
        "end_date": "18-11-2026",
        "pic": null,
        "pic_ids": [
          {
            "id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
            "name": "R3 Test amin"
          }
        ],
        "submitted_by": {
          "id": "0b000000-0000-0000-0000-000000000407",
          "full_name": "PHI SDA 1"
        },
        "submitted_at": "06-11-2026 15:25:13",
        "decided_by": null,
        "waiting_since": "06-11-2026 15:25:13",
        "current_level_sla_days": 3,
        "current_level_due_at": "11-11-2026 15:25:13",
        "current_level_status": "delayed"
      },
      {
        "id": "63cffc30-e2cc-4a47-8ac3-47504313fe99",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "a8ca5725-d2e0-4846-8cc2-880213b43e1c",
          "name": "DEMOBD-INJ"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0059/WO/SDA1/2026",
        "cycle_no": 1,
        "path": "reject",
        "current_level": null,
        "total_level": null,
        "start_date": "26-11-2026",
        "end_date": "28-11-2026",
        "pic": null,
        "pic_ids": [
          {
            "id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
            "name": "R3 Test amin"
          }
        ],
        "submitted_by": {
          "id": "0b000000-0000-0000-0000-000000000407",
          "full_name": "PHI SDA 1"
        },
        "submitted_at": "19-11-2026 10:13:45",
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "waiting_since": "19-11-2026 10:13:51",
        "current_level_sla_days": 3,
        "current_level_due_at": "24-11-2026 10:13:51",
        "current_level_status": "on_track"
      },
      {
        "id": "5dccdacd-6fed-4324-8c95-adc9374b8c1b",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "73b8447a-a53d-4b84-844c-ad12e7e4f856",
          "name": "DEMOBD-P2"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0060/WO/SDA1/2026",
        "cycle_no": 1,
        "path": "reject",
        "current_level": null,
        "total_level": null,
        "start_date": "26-11-2026",
        "end_date": "28-11-2026",
        "pic": null,
        "pic_ids": [
          {
            "id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
            "name": "R3 Test amin"
          }
        ],
        "submitted_by": {
          "id": "0b000000-0000-0000-0000-000000000407",
          "full_name": "PHI SDA 1"
        },
        "submitted_at": "19-11-2026 10:14:00",
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "waiting_since": "19-11-2026 10:14:10",
        "current_level_sla_days": 3,
        "current_level_due_at": "24-11-2026 10:14:10",
        "current_level_status": "on_track"
      },
      "... 5 more"
    ],
    "page": 1,
    "page_size": 500,
    "total": 8
  },
  "status": "success",
  "code": "00",
  "message": "Get action plan need action succeed"
}
```

**Result:** PASS

#### 4. PO gets the request notification

```bash
curl -s -X GET "$API/notifications/mine?page=1&page_size=10" \
  -H "Authorization: Bearer $PO"
```

**Expected:** HTTP 200, a notification names `$WO` ("Artificial Lift Request"). Needs the `phantom_iac_action_plan_*` rows in `notification_templates` (seed_action_plan_approval.sql). Without them the API logs "Notification template ... not found" and stages nothing, so this step fails. This is the same for WHC; it is not an SRP/ESP defect.

**Actual:** HTTP 200

```json
{
  "data": {
    "list": [
      {
        "id": "1acd32ae-16b3-4414-9f43-11af94c84d7c",
        "title": "Action Plan Rejected by Manager",
        "message": "WO Number 0052/WO/SDA1/2026 Action Plan rejected",
        "has_read": false,
        "created_at": "19-11-2026 10:10:06",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=2e82b888-b9da-40b2-b097-5e7894f7774d&action_plan_id=89703f53-ea03-45ba-ae78-2ac926eef9b3",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=2e82b888-b9da-40b2-b097-5e7894f7774d&action_plan_id=89703f53-ea03-45ba-ae78-2ac926eef9b3",
        "category": "Approval",
        "color_code": "danger"
      },
      {
        "id": "c82db0a2-37c8-41ff-ab6e-7790f9f0bf99",
        "title": "Action Plan Rejected by Manager",
        "message": "WO Number 0034/WO/SDA1/2026 Action Plan rejected",
        "has_read": false,
        "created_at": "16-11-2026 15:54:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=0dc94bc8-eccd-426e-ba59-90d876a59b89&action_plan_id=6f574ea5-6f02-45e6-b52f-e024c88f5731",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=0dc94bc8-eccd-426e-ba59-90d876a59b89&action_plan_id=6f574ea5-6f02-45e6-b52f-e024c88f5731",
        "category": "Approval",
        "color_code": "danger"
      },
      {
        "id": "cdb7fd52-bb2d-4091-9bb4-30ae6bb24d0f",
        "title": "Well Test Request",
        "message": "WO Number 0031/WO/SDA1/2026 Well Test need Approval.",
        "has_read": false,
        "created_at": "10-11-2026 19:35:33",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=f1000000-0000-4000-8000-000000000001&action_plan_id=849d007c-619c-4c25-893f-6cefeee38d6b",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=f1000000-0000-4000-8000-000000000001&action_plan_id=849d007c-619c-4c25-893f-6cefeee38d6b",
        "category": "Request",
        "color_code": "warning"
      },
      "... 7 more"
    ],
    "count": 4108
  },
  "status": "success",
  "code": "",
  "message": "Get Notifications succeed"
}
```

**Result:** FAIL — response has no `0072/WO/SDA1/2026`

#### 5. PO approves

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/$PLAN/review" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "approve",
  "remarks": "OK, jalankan sesuai jadwal",
  "execution_department_id": "Production Operations",
  "execution_pic_id": "0b000000-0000-0000-0000-000000000406"
}'
```

**Expected:** HTTP 200, `data.approval_status` = `approved`, `data.path` = `approve`

**Actual:** HTTP 200

```json
{
  "data": {
    "action_plan_id": "fd029981-4a9f-488d-8af6-e350a247d9de",
    "source": "pep",
    "work_order_number": "0072/WO/SDA1/2026",
    "approval_status": "approved",
    "cycle_no": 1,
    "path": "approve",
    "current_level": null,
    "total_levels": null
  },
  "status": "success",
  "code": "00",
  "message": "Review action plan succeed"
}
```

**Result:** PASS

#### 6. Detail shows approved

```bash
curl -s -X GET "$API/well-surveilence/action-plans/pep/$PLAN" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, `data.approval_status` = `approved`, `data.artificial_lift.method` = `sucker_rod_pump`

**Actual:** HTTP 200

```json
{
  "data": {
    "id": "fd029981-4a9f-488d-8af6-e350a247d9de",
    "action_plan_type": "artificial_lift",
    "status": "on_schedule",
    "start_date": "01-03-2027",
    "end_date": "03-03-2027",
    "notes": "SRP/ESP curl test",
    "ownership": "Pertamina EP",
    "pic": null,
    "pic_ids": [
      {
        "id": "AEC27CB5-3374-4DEB-BB51-304F686531F8",
        "name": "PHI SDA 1",
        "email": "phi.sda1@yopmail.com"
      }
    ],
    "created_at": "19-11-2026 18:24:29",
    "created_by": {
      "id": "0B000000-0000-0000-0000-000000000407",
      "full_name": "PHI SDA 1"
    },
    "updated_at": "19-11-2026 18:24:38",
    "updated_by": {
      "id": "0B000000-0000-0000-0000-000000000406",
      "full_name": "PHI PO"
    },
    "choke": null,
    "sonolog": null,
    "well_test": null,
    "artificial_lift": {
      "activity_type": "installation",
      "action_mode": "installation_schedule",
      "method": "sucker_rod_pump",
      "prime_mover": 0,
      "power": 40.0,
      "bean": 0,
      "thp": 0,
      "flowline_pressure": 0,
      "casing_pressure": 0,
      "separator_pressure": 0,
      "spmfreq": 8.5,
      "pump_size": 0,
      "pump_displacement": 0,
      "pump_efficiency": 0,
      "stroke_length": 86.0,
      "pump_intake_depth": 0,
      "submerging": 0,
      "production": 120.0,
      "pressure": 150.0,
      "ownership": "Pertamina EP",
      "whc_type": null,
      "compression_type": null,
      "owned_by": "rental",
      "contract_number": "CTR-PO/2026/021",
      "asset_number": null,
      "cost_allocation": null,
      "pump_type": "Insert Pump",
      "pump_brand": "Weatherford",
      "prime_mover_name": "Gas Engine G3306",
      "frequency": null,
      "electric_current": null
    },
    "others": null,
    "approval_status": "approved",
    "requires_approval": true,
    "work_order_number": "0072/WO/SDA1/2026",
    "assigned_department": "Production Operations",
    "execution_department_id": "Production Operations",
    "execution_pic": {
      "id": "0B000000-0000-0000-0000-000000000406",
      "name": "PHI PO",
      "email": "phi.po@yopmail.com"
    },
    "can_review": false,
    "can_approve": false,
    "can_reject": false,
    "approval": {
      "cycle_no": 1,
      "path": "approve",
      "current_level": null,
      "total_levels": null
    }
  },
  "status": "success",
  "code": "00",
  "message": "Get action plan PEP detail succeed"
}
```

**Result:** PASS

#### 7. SSDP gets the result notification

```bash
curl -s -X GET "$API/notifications/mine?page=1&page_size=10" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, a notification names `$WO`. Needs the `phantom_iac_action_plan_*` rows in `notification_templates` (seed_action_plan_approval.sql). Without them the API logs "Notification template ... not found" and stages nothing, so this step fails. This is the same for WHC; it is not an SRP/ESP defect.

**Actual:** HTTP 200

```json
{
  "data": {
    "list": [
      {
        "id": "90608b8a-fc0c-4d82-a79c-30af617a94f9",
        "title": "EUR Threshold Reached",
        "message": "<div style=\"width: 100%\"><span style=\"color: #e7000b\">QA55E21</span> <span style=\"color: #62748e\">reached 95% of EUR.</span></div>",
        "has_read": false,
        "created_at": "19-11-2026 18:02:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=b9d8f33e-1161-46de-8811-72a29989c7fc",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=b9d8f33e-1161-46de-8811-72a29989c7fc",
        "category": "Alert",
        "color_code": "danger"
      },
      {
        "id": "bcd1cc86-2c2f-47a1-9bcc-08ee00407665",
        "title": "EUR Exceeded",
        "message": "<div style=\"width: 100%\"><span><span style=\"color: #e7000b\">WELL-TEST-PEP-01-QA</span> <span style=\"color: #62748e\">exceeded 2843.52% of EUR.</span></span></div>",
        "has_read": false,
        "created_at": "19-11-2026 18:02:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=73a376d4-846f-44bb-9937-5060531a6635",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=73a376d4-846f-44bb-9937-5060531a6635",
        "category": "Alert",
        "color_code": "danger"
      },
      {
        "id": "550a6a5e-8bb8-4f3a-9a4c-1b233bd5c3dd",
        "title": "EUR Exceeded",
        "message": "<div style=\"width: 100%\"><span><span style=\"color: #e7000b\">WELLY-BDK-TEST-FORCASE1</span> <span style=\"color: #62748e\">exceeded 1274.66% of EUR.</span></span></div>",
        "has_read": false,
        "created_at": "19-11-2026 18:02:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=ce935186-e285-451b-bb69-5747f19b31b6",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=ce935186-e285-451b-bb69-5747f19b31b6",
        "category": "Alert",
        "color_code": "danger"
      },
      "... 7 more"
    ],
    "count": 206524
  },
  "status": "success",
  "code": "",
  "message": "Get Notifications succeed"
}
```

**Result:** FAIL — response has no `0072/WO/SDA1/2026`

### SRP Installation Schedule — Modify

#### 8. Next WO number (SSDP)

```bash
curl -s -X GET "$API/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, `data.wo_number` = `NNNN/WO/{short}/{year}` → set `WO`

**Actual:** HTTP 200

```json
{
  "data": {
    "sequence_number": "0073",
    "wo_number": "0073/WO/SDA1/2026"
  },
  "status": "success",
  "code": "00",
  "message": "Get next work order number succeed"
}
```

`WO=0073/WO/SDA1/2026`
**Result:** PASS

#### 9. SSDP submits

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "bdd3c526-ca9c-4b08-bf6f-cf445d1d557f",
  "start_date": "2027-03-08",
  "end_date": "2027-03-10",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "sucker_rod_pump",
    "assigned_department": "Production Operations",
    "pump_type": "Insert Pump",
    "pump_brand": "Weatherford",
    "stroke_length": 86,
    "spmfreq": 8.5,
    "prime_mover_name": "Gas Engine G3306",
    "power": 40,
    "owned_by": "rental",
    "contract_number": "CTR-PO/2026/021",
    "asset_number": "AST-DROP",
    "production": 120,
    "pressure": 150
  },
  "wo_number": "'"$WO"'"
}'
```

**Expected:** HTTP 200, `data.approval_status` = `waiting_review`, `data.work_order_number` = `$WO`

**Actual:** HTTP 200

```json
{
  "data": {
    "id": "35ff8b30-e9fd-49bc-bf4e-8dac8796fc1e",
    "record_state": "submitted",
    "approval_status": "waiting_review",
    "work_order_number": "0073/WO/SDA1/2026"
  },
  "status": "success",
  "code": "00",
  "message": "Submit action plan PEP succeed"
}
```

`PLAN=35ff8b30-e9fd-49bc-bf4e-8dac8796fc1e`
**Result:** PASS

#### 10. PO sees the plan in need-action (review)

```bash
curl -s -X GET "$API/well-surveilence/action-plans/approvals/need-action?stage=review&source=pep&action_plan_type=artificial_lift&page_size=500" \
  -H "Authorization: Bearer $PO"
```

**Expected:** HTTP 200, the list holds `$PLAN`

**Actual:** HTTP 200

```json
{
  "data": {
    "items": [
      {
        "id": "7a6d7ae6-1a23-4a0c-b307-611449196bcc",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "1bad4d3a-b752-4b3f-ae0f-21c1ef321f71",
          "name": "A-INDANA-PEP"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0007/WO/SDA1/2026",
        "cycle_no": null,
        "path": null,
        "current_level": null,
        "total_level": null,
        "start_date": "16-11-2026",
        "end_date": "18-11-2026",
        "pic": null,
        "pic_ids": [
          {
            "id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
            "name": "R3 Test amin"
          }
        ],
        "submitted_by": {
          "id": "0b000000-0000-0000-0000-000000000407",
          "full_name": "PHI SDA 1"
        },
        "submitted_at": "06-11-2026 15:25:13",
        "decided_by": null,
        "waiting_since": "06-11-2026 15:25:13",
        "current_level_sla_days": 3,
        "current_level_due_at": "11-11-2026 15:25:13",
        "current_level_status": "delayed"
      },
      {
        "id": "63cffc30-e2cc-4a47-8ac3-47504313fe99",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "a8ca5725-d2e0-4846-8cc2-880213b43e1c",
          "name": "DEMOBD-INJ"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0059/WO/SDA1/2026",
        "cycle_no": 1,
        "path": "reject",
        "current_level": null,
        "total_level": null,
        "start_date": "26-11-2026",
        "end_date": "28-11-2026",
        "pic": null,
        "pic_ids": [
          {
            "id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
            "name": "R3 Test amin"
          }
        ],
        "submitted_by": {
          "id": "0b000000-0000-0000-0000-000000000407",
          "full_name": "PHI SDA 1"
        },
        "submitted_at": "19-11-2026 10:13:45",
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "waiting_since": "19-11-2026 10:13:51",
        "current_level_sla_days": 3,
        "current_level_due_at": "24-11-2026 10:13:51",
        "current_level_status": "on_track"
      },
      {
        "id": "5dccdacd-6fed-4324-8c95-adc9374b8c1b",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "73b8447a-a53d-4b84-844c-ad12e7e4f856",
          "name": "DEMOBD-P2"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0060/WO/SDA1/2026",
        "cycle_no": 1,
        "path": "reject",
        "current_level": null,
        "total_level": null,
        "start_date": "26-11-2026",
        "end_date": "28-11-2026",
        "pic": null,
        "pic_ids": [
          {
            "id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
            "name": "R3 Test amin"
          }
        ],
        "submitted_by": {
          "id": "0b000000-0000-0000-0000-000000000407",
          "full_name": "PHI SDA 1"
        },
        "submitted_at": "19-11-2026 10:14:00",
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "waiting_since": "19-11-2026 10:14:10",
        "current_level_sla_days": 3,
        "current_level_due_at": "24-11-2026 10:14:10",
        "current_level_status": "on_track"
      },
      "... 5 more"
    ],
    "page": 1,
    "page_size": 500,
    "total": 8
  },
  "status": "success",
  "code": "00",
  "message": "Get action plan need action succeed"
}
```

**Result:** PASS

#### 11. PO gets the request notification

```bash
curl -s -X GET "$API/notifications/mine?page=1&page_size=10" \
  -H "Authorization: Bearer $PO"
```

**Expected:** HTTP 200, a notification names `$WO` ("Artificial Lift Request"). Needs the `phantom_iac_action_plan_*` rows in `notification_templates` (seed_action_plan_approval.sql). Without them the API logs "Notification template ... not found" and stages nothing, so this step fails. This is the same for WHC; it is not an SRP/ESP defect.

**Actual:** HTTP 200

```json
{
  "data": {
    "list": [
      {
        "id": "1acd32ae-16b3-4414-9f43-11af94c84d7c",
        "title": "Action Plan Rejected by Manager",
        "message": "WO Number 0052/WO/SDA1/2026 Action Plan rejected",
        "has_read": false,
        "created_at": "19-11-2026 10:10:06",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=2e82b888-b9da-40b2-b097-5e7894f7774d&action_plan_id=89703f53-ea03-45ba-ae78-2ac926eef9b3",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=2e82b888-b9da-40b2-b097-5e7894f7774d&action_plan_id=89703f53-ea03-45ba-ae78-2ac926eef9b3",
        "category": "Approval",
        "color_code": "danger"
      },
      {
        "id": "c82db0a2-37c8-41ff-ab6e-7790f9f0bf99",
        "title": "Action Plan Rejected by Manager",
        "message": "WO Number 0034/WO/SDA1/2026 Action Plan rejected",
        "has_read": false,
        "created_at": "16-11-2026 15:54:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=0dc94bc8-eccd-426e-ba59-90d876a59b89&action_plan_id=6f574ea5-6f02-45e6-b52f-e024c88f5731",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=0dc94bc8-eccd-426e-ba59-90d876a59b89&action_plan_id=6f574ea5-6f02-45e6-b52f-e024c88f5731",
        "category": "Approval",
        "color_code": "danger"
      },
      {
        "id": "cdb7fd52-bb2d-4091-9bb4-30ae6bb24d0f",
        "title": "Well Test Request",
        "message": "WO Number 0031/WO/SDA1/2026 Well Test need Approval.",
        "has_read": false,
        "created_at": "10-11-2026 19:35:33",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=f1000000-0000-4000-8000-000000000001&action_plan_id=849d007c-619c-4c25-893f-6cefeee38d6b",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=f1000000-0000-4000-8000-000000000001&action_plan_id=849d007c-619c-4c25-893f-6cefeee38d6b",
        "category": "Request",
        "color_code": "warning"
      },
      "... 7 more"
    ],
    "count": 4108
  },
  "status": "success",
  "code": "",
  "message": "Get Notifications succeed"
}
```

**Result:** FAIL — response has no `0073/WO/SDA1/2026`

#### 12. PO modifies (manager → SSDP creator)

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/$PLAN/review" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "modify",
  "remarks": "Ubah parameter pompa",
  "proposed": {
    "start_date": "2027-03-08",
    "end_date": "2027-03-10",
    "pic_ids": [
      "0b000000-0000-0000-0000-000000000407"
    ],
    "notes": "SRP/ESP curl test",
    "ownership": "Pertamina EP",
    "artificial_lift": {
      "activity_type": "installation",
      "action_mode": "installation_schedule",
      "method": "sucker_rod_pump",
      "assigned_department": "Production Operations",
      "pump_type": "Insert Pump",
      "pump_brand": "Lufkin",
      "stroke_length": 100,
      "spmfreq": 8.5,
      "prime_mover_name": "Gas Engine G3306",
      "power": 40,
      "owned_by": "rental",
      "contract_number": "CTR-PO/2026/021",
      "asset_number": "AST-DROP",
      "production": 120,
      "pressure": 150
    }
  },
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ]
    }
  ]
}'
```

**Expected:** HTTP 200, `data.approval_status` = `modify_in_approval`, `data.current_level` = `1`, `data.total_levels` = `2`

**Actual:** HTTP 200

```json
{
  "data": {
    "action_plan_id": "35ff8b30-e9fd-49bc-bf4e-8dac8796fc1e",
    "source": "pep",
    "work_order_number": "0073/WO/SDA1/2026",
    "approval_status": "modify_in_approval",
    "cycle_no": 1,
    "path": "modify",
    "current_level": 1,
    "total_levels": 2
  },
  "status": "success",
  "code": "00",
  "message": "Review action plan succeed"
}
```

**Result:** PASS

#### 13. Modification diff

```bash
curl -s -X GET "$API/well-surveilence/action-plans/pep/$PLAN/modification-diff" \
  -H "Authorization: Bearer $PO"
```

**Expected:** HTTP 200, `data.changes[].field` = ['artificial_lift.pump_brand', 'artificial_lift.stroke_length'] (nothing else changes)

**Actual:** HTTP 200

```json
{
  "data": {
    "cycle_id": "5a61b27b-dae2-4717-8cfe-15c98204823b",
    "cycle_no": 1,
    "applied_at": null,
    "changes": [
      {
        "field": "artificial_lift.pump_brand",
        "original": "Weatherford",
        "proposed": "Lufkin"
      },
      {
        "field": "artificial_lift.stroke_length",
        "original": 86.0,
        "proposed": 100
      }
    ],
    "original": {
      "action_plan_type": "artificial_lift",
      "draft_id": null,
      "well_id": "bdd3c526-ca9c-4b08-bf6f-cf445d1d557f",
      "start_date": "08-03-2027",
      "end_date": "10-03-2027",
      "pic_id": null,
      "pic_ids": [
        "0b000000-0000-0000-0000-000000000407"
      ],
      "notes": "SRP/ESP curl test",
      "ownership": "Pertamina EP",
      "wo_number": null,
      "choke": null,
      "sonolog": null,
      "well_test": null,
      "artificial_lift": {
        "activity_type": "installation",
        "action_mode": "installation_schedule",
        "method": "sucker_rod_pump",
        "prime_mover": null,
        "power": 40.0,
        "bean": null,
        "thp": null,
        "flowline_pressure": null,
        "casing_pressure": null,
        "separator_pressure": null,
        "spmfreq": 8.5,
        "pump_size": null,
        "pump_displacement": null,
        "pump_efficiency": null,
        "stroke_length": 86.0,
        "pump_intake_depth": null,
        "submerging": null,
        "production": 120.0,
        "pressure": 150.0,
        "ownership": null,
        "assigned_department": "Production Operations",
        "whc_type": null,
        "compression_type": null,
        "owned_by": "rental",
        "contract_number": "CTR-PO/2026/021",
        "asset_number": null,
        "cost_allocation": null,
        "pump_type": "Insert Pump",
        "pump_brand": "Weatherford",
        "prime_mover_name": "Gas Engine G3306",
        "frequency": null,
        "electric_current": null
      },
      "others": null,
      "execution_department_id": null,
      "execution_pic_id": null
    },
    "proposed": {
      "action_plan_type": "artificial_lift",
      "draft_id": null,
      "well_id": "bdd3c526-ca9c-4b08-bf6f-cf445d1d557f",
      "start_date": "08-03-2027",
      "end_date": "10-03-2027",
      "pic_id": null,
      "pic_ids": [
        "0b000000-0000-0000-0000-000000000407"
      ],
      "notes": "SRP/ESP curl test",
      "ownership": "Pertamina EP",
      "wo_number": null,
      "choke": null,
      "sonolog": null,
      "well_test": null,
      "artificial_lift": {
        "activity_type": "installation",
        "action_mode": "installation_schedule",
        "method": "sucker_rod_pump",
        "prime_mover": null,
        "power": 40,
        "bean": null,
        "thp": null,
        "flowline_pressure": null,
        "casing_pressure": null,
        "separator_pressure": null,
        "spmfreq": 8.5,
        "pump_size": null,
        "pump_displacement": null,
        "pump_efficiency": null,
        "stroke_length": 100,
        "pump_intake_depth": null,
        "submerging": null,
        "production": 120,
        "pressure": 150,
        "ownership": null,
        "assigned_department": "Production Operations",
        "whc_type": null,
        "compression_type": null,
        "owned_by": "rental",
        "contract_number": "CTR-PO/2026/021",
        "asset_number": null,
        "cost_allocation": null,
        "pump_type": "Insert Pump",
        "pump_brand": "Lufkin",
        "prime_mover_name": "Gas Engine G3306",
        "frequency": null,
        "electric_current": null
      },
      "others": null,
      "execution_department_id": null,
      "execution_pic_id": null
    }
  },
  "status": "success",
  "code": "00",
  "message": "Get action plan modification diff succeed"
}
```

**Result:** PASS

#### 14. Manager level 1 approves

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/$PLAN/approval/approve" \
  -H "Authorization: Bearer $MGR" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "OK"
}'
```

**Expected:** HTTP 200, `data.approval_status` = `modify_in_approval`, `data.current_level` = `2`

**Actual:** HTTP 200

```json
{
  "data": {
    "action_plan_id": "35ff8b30-e9fd-49bc-bf4e-8dac8796fc1e",
    "source": "pep",
    "work_order_number": "0073/WO/SDA1/2026",
    "approval_status": "modify_in_approval",
    "cycle_no": 1,
    "path": "modify",
    "current_level": 2,
    "total_levels": 2
  },
  "status": "success",
  "code": "00",
  "message": "Approve action plan succeed"
}
```

**Result:** PASS

#### 15. SSDP creator (last level) approves → proposal applied

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/$PLAN/approval/approve" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "OK"
}'
```

**Expected:** HTTP 200, `data.approval_status` = `approved`

**Actual:** HTTP 200

```json
{
  "data": {
    "action_plan_id": "35ff8b30-e9fd-49bc-bf4e-8dac8796fc1e",
    "source": "pep",
    "work_order_number": "0073/WO/SDA1/2026",
    "approval_status": "approved",
    "cycle_no": 1,
    "path": "modify",
    "current_level": null,
    "total_levels": 2
  },
  "status": "success",
  "code": "00",
  "message": "Approve action plan succeed"
}
```

**Result:** PASS

#### 16. Detail shows the applied proposal

```bash
curl -s -X GET "$API/well-surveilence/action-plans/pep/$PLAN" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, `data.approval_status` = `approved`, `data.artificial_lift.pump_brand` = `Lufkin`, `data.artificial_lift.stroke_length` = `100`

**Actual:** HTTP 200

```json
{
  "data": {
    "id": "35ff8b30-e9fd-49bc-bf4e-8dac8796fc1e",
    "action_plan_type": "artificial_lift",
    "status": "on_schedule",
    "start_date": "08-03-2027",
    "end_date": "10-03-2027",
    "notes": "SRP/ESP curl test",
    "ownership": "Pertamina EP",
    "pic": null,
    "pic_ids": [
      {
        "id": "4C3237E3-AAC7-41E0-A53A-68F74D47E20B",
        "name": "PHI SDA 1",
        "email": "phi.sda1@yopmail.com"
      }
    ],
    "created_at": "19-11-2026 18:24:46",
    "created_by": {
      "id": "0B000000-0000-0000-0000-000000000407",
      "full_name": "PHI SDA 1"
    },
    "updated_at": "19-11-2026 18:24:54",
    "updated_by": {
      "id": "0B000000-0000-0000-0000-000000000407",
      "full_name": "PHI SDA 1"
    },
    "choke": null,
    "sonolog": null,
    "well_test": null,
    "artificial_lift": {
      "activity_type": "installation",
      "action_mode": "installation_schedule",
      "method": "sucker_rod_pump",
      "prime_mover": 0,
      "power": 40.0,
      "bean": 0,
      "thp": 0,
      "flowline_pressure": 0,
      "casing_pressure": 0,
      "separator_pressure": 0,
      "spmfreq": 8.5,
      "pump_size": 0,
      "pump_displacement": 0,
      "pump_efficiency": 0,
      "stroke_length": 100.0,
      "pump_intake_depth": 0,
      "submerging": 0,
      "production": 120.0,
      "pressure": 150.0,
      "ownership": "Pertamina EP",
      "whc_type": null,
      "compression_type": null,
      "owned_by": "rental",
      "contract_number": "CTR-PO/2026/021",
      "asset_number": null,
      "cost_allocation": null,
      "pump_type": "Insert Pump",
      "pump_brand": "Lufkin",
      "prime_mover_name": "Gas Engine G3306",
      "frequency": null,
      "electric_current": null
    },
    "others": null,
    "approval_status": "approved",
    "requires_approval": true,
    "work_order_number": "0073/WO/SDA1/2026",
    "assigned_department": "Production Operations",
    "execution_department_id": null,
    "execution_pic": null,
    "can_review": false,
    "can_approve": false,
    "can_reject": false,
    "approval": {
      "cycle_no": 1,
      "path": "modify",
      "current_level": null,
      "total_levels": 2
    }
  },
  "status": "success",
  "code": "00",
  "message": "Get action plan PEP detail succeed"
}
```

**Result:** PASS

#### 17. SSDP gets the result notification

```bash
curl -s -X GET "$API/notifications/mine?page=1&page_size=10" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, a notification names `$WO`. Needs the `phantom_iac_action_plan_*` rows in `notification_templates` (seed_action_plan_approval.sql). Without them the API logs "Notification template ... not found" and stages nothing, so this step fails. This is the same for WHC; it is not an SRP/ESP defect.

**Actual:** HTTP 200

```json
{
  "data": {
    "list": [
      {
        "id": "403ae9bb-5830-46fb-a2e9-0a8d801511c0",
        "title": "EUR Threshold Exceeded",
        "message": "<div style=\"width: 100%\"><span><span style=\"color: #e7000b\">QA57P22</span> <span style=\"color: #62748e\">exceeded 95% of EUR.</span></span></div>",
        "has_read": false,
        "created_at": "19-11-2026 18:02:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=68925d0d-c448-4333-b0ca-de75c0f5aa83",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=68925d0d-c448-4333-b0ca-de75c0f5aa83",
        "category": "Alert",
        "color_code": "danger"
      },
      {
        "id": "dd0b7bb8-62dd-4b57-9ff5-035ac96dfca6",
        "title": "EUR Threshold Exceeded",
        "message": "<div style=\"width: 100%\"><span><span style=\"color: #e7000b\">QSIWFA</span> <span style=\"color: #62748e\">exceeded 95% of EUR.</span></span></div>",
        "has_read": false,
        "created_at": "19-11-2026 18:02:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=7b1198d5-8bcd-4069-a0f0-96aec42fd994",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=7b1198d5-8bcd-4069-a0f0-96aec42fd994",
        "category": "Alert",
        "color_code": "danger"
      },
      {
        "id": "550a6a5e-8bb8-4f3a-9a4c-1b233bd5c3dd",
        "title": "EUR Exceeded",
        "message": "<div style=\"width: 100%\"><span><span style=\"color: #e7000b\">WELLY-BDK-TEST-FORCASE1</span> <span style=\"color: #62748e\">exceeded 1274.66% of EUR.</span></span></div>",
        "has_read": false,
        "created_at": "19-11-2026 18:02:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=ce935186-e285-451b-bb69-5747f19b31b6",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=ce935186-e285-451b-bb69-5747f19b31b6",
        "category": "Alert",
        "color_code": "danger"
      },
      "... 7 more"
    ],
    "count": 206524
  },
  "status": "success",
  "code": "",
  "message": "Get Notifications succeed"
}
```

**Result:** FAIL — response has no `0073/WO/SDA1/2026`

### SRP Installation Schedule — Reject

#### 18. Next WO number (SSDP)

```bash
curl -s -X GET "$API/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, `data.wo_number` = `NNNN/WO/{short}/{year}` → set `WO`

**Actual:** HTTP 200

```json
{
  "data": {
    "sequence_number": "0074",
    "wo_number": "0074/WO/SDA1/2026"
  },
  "status": "success",
  "code": "00",
  "message": "Get next work order number succeed"
}
```

`WO=0074/WO/SDA1/2026`
**Result:** PASS

#### 19. SSDP submits

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "bdd3c526-ca9c-4b08-bf6f-cf445d1d557f",
  "start_date": "2027-03-15",
  "end_date": "2027-03-17",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "sucker_rod_pump",
    "assigned_department": "Production Operations",
    "pump_type": "Insert Pump",
    "pump_brand": "Weatherford",
    "stroke_length": 86,
    "spmfreq": 8.5,
    "prime_mover_name": "Gas Engine G3306",
    "power": 40,
    "owned_by": "rental",
    "contract_number": "CTR-PO/2026/021",
    "asset_number": "AST-DROP",
    "production": 120,
    "pressure": 150
  },
  "wo_number": "'"$WO"'"
}'
```

**Expected:** HTTP 200, `data.approval_status` = `waiting_review`, `data.work_order_number` = `$WO`

**Actual:** HTTP 200

```json
{
  "data": {
    "id": "9898531c-6232-4396-9937-1a95b1108eeb",
    "record_state": "submitted",
    "approval_status": "waiting_review",
    "work_order_number": "0074/WO/SDA1/2026"
  },
  "status": "success",
  "code": "00",
  "message": "Submit action plan PEP succeed"
}
```

`PLAN=9898531c-6232-4396-9937-1a95b1108eeb`
**Result:** PASS

#### 20. PO sees the plan in need-action (review)

```bash
curl -s -X GET "$API/well-surveilence/action-plans/approvals/need-action?stage=review&source=pep&action_plan_type=artificial_lift&page_size=500" \
  -H "Authorization: Bearer $PO"
```

**Expected:** HTTP 200, the list holds `$PLAN`

**Actual:** HTTP 200

```json
{
  "data": {
    "items": [
      {
        "id": "7a6d7ae6-1a23-4a0c-b307-611449196bcc",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "1bad4d3a-b752-4b3f-ae0f-21c1ef321f71",
          "name": "A-INDANA-PEP"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0007/WO/SDA1/2026",
        "cycle_no": null,
        "path": null,
        "current_level": null,
        "total_level": null,
        "start_date": "16-11-2026",
        "end_date": "18-11-2026",
        "pic": null,
        "pic_ids": [
          {
            "id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
            "name": "R3 Test amin"
          }
        ],
        "submitted_by": {
          "id": "0b000000-0000-0000-0000-000000000407",
          "full_name": "PHI SDA 1"
        },
        "submitted_at": "06-11-2026 15:25:13",
        "decided_by": null,
        "waiting_since": "06-11-2026 15:25:13",
        "current_level_sla_days": 3,
        "current_level_due_at": "11-11-2026 15:25:13",
        "current_level_status": "delayed"
      },
      {
        "id": "63cffc30-e2cc-4a47-8ac3-47504313fe99",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "a8ca5725-d2e0-4846-8cc2-880213b43e1c",
          "name": "DEMOBD-INJ"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0059/WO/SDA1/2026",
        "cycle_no": 1,
        "path": "reject",
        "current_level": null,
        "total_level": null,
        "start_date": "26-11-2026",
        "end_date": "28-11-2026",
        "pic": null,
        "pic_ids": [
          {
            "id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
            "name": "R3 Test amin"
          }
        ],
        "submitted_by": {
          "id": "0b000000-0000-0000-0000-000000000407",
          "full_name": "PHI SDA 1"
        },
        "submitted_at": "19-11-2026 10:13:45",
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "waiting_since": "19-11-2026 10:13:51",
        "current_level_sla_days": 3,
        "current_level_due_at": "24-11-2026 10:13:51",
        "current_level_status": "on_track"
      },
      {
        "id": "5dccdacd-6fed-4324-8c95-adc9374b8c1b",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "73b8447a-a53d-4b84-844c-ad12e7e4f856",
          "name": "DEMOBD-P2"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0060/WO/SDA1/2026",
        "cycle_no": 1,
        "path": "reject",
        "current_level": null,
        "total_level": null,
        "start_date": "26-11-2026",
        "end_date": "28-11-2026",
        "pic": null,
        "pic_ids": [
          {
            "id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
            "name": "R3 Test amin"
          }
        ],
        "submitted_by": {
          "id": "0b000000-0000-0000-0000-000000000407",
          "full_name": "PHI SDA 1"
        },
        "submitted_at": "19-11-2026 10:14:00",
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "waiting_since": "19-11-2026 10:14:10",
        "current_level_sla_days": 3,
        "current_level_due_at": "24-11-2026 10:14:10",
        "current_level_status": "on_track"
      },
      "... 5 more"
    ],
    "page": 1,
    "page_size": 500,
    "total": 8
  },
  "status": "success",
  "code": "00",
  "message": "Get action plan need action succeed"
}
```

**Result:** PASS

#### 21. PO gets the request notification

```bash
curl -s -X GET "$API/notifications/mine?page=1&page_size=10" \
  -H "Authorization: Bearer $PO"
```

**Expected:** HTTP 200, a notification names `$WO` ("Artificial Lift Request"). Needs the `phantom_iac_action_plan_*` rows in `notification_templates` (seed_action_plan_approval.sql). Without them the API logs "Notification template ... not found" and stages nothing, so this step fails. This is the same for WHC; it is not an SRP/ESP defect.

**Actual:** HTTP 200

```json
{
  "data": {
    "list": [
      {
        "id": "1acd32ae-16b3-4414-9f43-11af94c84d7c",
        "title": "Action Plan Rejected by Manager",
        "message": "WO Number 0052/WO/SDA1/2026 Action Plan rejected",
        "has_read": false,
        "created_at": "19-11-2026 10:10:06",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=2e82b888-b9da-40b2-b097-5e7894f7774d&action_plan_id=89703f53-ea03-45ba-ae78-2ac926eef9b3",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=2e82b888-b9da-40b2-b097-5e7894f7774d&action_plan_id=89703f53-ea03-45ba-ae78-2ac926eef9b3",
        "category": "Approval",
        "color_code": "danger"
      },
      {
        "id": "c82db0a2-37c8-41ff-ab6e-7790f9f0bf99",
        "title": "Action Plan Rejected by Manager",
        "message": "WO Number 0034/WO/SDA1/2026 Action Plan rejected",
        "has_read": false,
        "created_at": "16-11-2026 15:54:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=0dc94bc8-eccd-426e-ba59-90d876a59b89&action_plan_id=6f574ea5-6f02-45e6-b52f-e024c88f5731",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=0dc94bc8-eccd-426e-ba59-90d876a59b89&action_plan_id=6f574ea5-6f02-45e6-b52f-e024c88f5731",
        "category": "Approval",
        "color_code": "danger"
      },
      {
        "id": "cdb7fd52-bb2d-4091-9bb4-30ae6bb24d0f",
        "title": "Well Test Request",
        "message": "WO Number 0031/WO/SDA1/2026 Well Test need Approval.",
        "has_read": false,
        "created_at": "10-11-2026 19:35:33",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=f1000000-0000-4000-8000-000000000001&action_plan_id=849d007c-619c-4c25-893f-6cefeee38d6b",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=f1000000-0000-4000-8000-000000000001&action_plan_id=849d007c-619c-4c25-893f-6cefeee38d6b",
        "category": "Request",
        "color_code": "warning"
      },
      "... 7 more"
    ],
    "count": 4108
  },
  "status": "success",
  "code": "",
  "message": "Get Notifications succeed"
}
```

**Result:** FAIL — response has no `0074/WO/SDA1/2026`

#### 22. PO rejects (reject round)

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/$PLAN/review" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "reject",
  "remarks": "Unit pompa tidak tersedia",
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ]
    }
  ]
}'
```

**Expected:** HTTP 200, `data.approval_status` = `reject_in_approval`

**Actual:** HTTP 200

```json
{
  "data": {
    "action_plan_id": "9898531c-6232-4396-9937-1a95b1108eeb",
    "source": "pep",
    "work_order_number": "0074/WO/SDA1/2026",
    "approval_status": "reject_in_approval",
    "cycle_no": 1,
    "path": "reject",
    "current_level": 1,
    "total_levels": 1
  },
  "status": "success",
  "code": "00",
  "message": "Review action plan succeed"
}
```

**Result:** PASS

#### 23. Manager agrees → rejected

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/$PLAN/approval/reject" \
  -H "Authorization: Bearer $MGR" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
```

**Expected:** HTTP 200, `data.approval_status` = `rejected`

**Actual:** HTTP 200

```json
{
  "data": {
    "action_plan_id": "9898531c-6232-4396-9937-1a95b1108eeb",
    "source": "pep",
    "work_order_number": "0074/WO/SDA1/2026",
    "approval_status": "rejected",
    "cycle_no": 1,
    "path": "reject",
    "current_level": null,
    "total_levels": 1
  },
  "status": "success",
  "code": "00",
  "message": "Reject action plan succeed"
}
```

**Result:** PASS

#### 24. Detail shows rejected

```bash
curl -s -X GET "$API/well-surveilence/action-plans/pep/$PLAN" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, `data.approval_status` = `rejected`

**Actual:** HTTP 200

```json
{
  "data": {
    "id": "9898531c-6232-4396-9937-1a95b1108eeb",
    "action_plan_type": "artificial_lift",
    "status": "on_schedule",
    "start_date": "15-03-2027",
    "end_date": "17-03-2027",
    "notes": "SRP/ESP curl test",
    "ownership": "Pertamina EP",
    "pic": null,
    "pic_ids": [
      {
        "id": "E31E9B7A-AE06-41E5-BE0F-97E85D3B4EA3",
        "name": "PHI SDA 1",
        "email": "phi.sda1@yopmail.com"
      }
    ],
    "created_at": "19-11-2026 18:24:58",
    "created_by": {
      "id": "0B000000-0000-0000-0000-000000000407",
      "full_name": "PHI SDA 1"
    },
    "updated_at": "19-11-2026 18:25:03",
    "updated_by": {
      "id": "0B000000-0000-0000-0000-000000000409",
      "full_name": "PHI Super Admin"
    },
    "choke": null,
    "sonolog": null,
    "well_test": null,
    "artificial_lift": {
      "activity_type": "installation",
      "action_mode": "installation_schedule",
      "method": "sucker_rod_pump",
      "prime_mover": 0,
      "power": 40.0,
      "bean": 0,
      "thp": 0,
      "flowline_pressure": 0,
      "casing_pressure": 0,
      "separator_pressure": 0,
      "spmfreq": 8.5,
      "pump_size": 0,
      "pump_displacement": 0,
      "pump_efficiency": 0,
      "stroke_length": 86.0,
      "pump_intake_depth": 0,
      "submerging": 0,
      "production": 120.0,
      "pressure": 150.0,
      "ownership": "Pertamina EP",
      "whc_type": null,
      "compression_type": null,
      "owned_by": "rental",
      "contract_number": "CTR-PO/2026/021",
      "asset_number": null,
      "cost_allocation": null,
      "pump_type": "Insert Pump",
      "pump_brand": "Weatherford",
      "prime_mover_name": "Gas Engine G3306",
      "frequency": null,
      "electric_current": null
    },
    "others": null,
    "approval_status": "rejected",
    "requires_approval": true,
    "work_order_number": "0074/WO/SDA1/2026",
    "assigned_department": "Production Operations",
    "execution_department_id": null,
    "execution_pic": null,
    "can_review": false,
    "can_approve": false,
    "can_reject": false,
    "approval": {
      "cycle_no": 1,
      "path": "reject",
      "current_level": null,
      "total_levels": 1
    }
  },
  "status": "success",
  "code": "00",
  "message": "Get action plan PEP detail succeed"
}
```

**Result:** PASS

#### 25. SSDP gets the result notification

```bash
curl -s -X GET "$API/notifications/mine?page=1&page_size=10" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, a notification names `$WO`. Needs the `phantom_iac_action_plan_*` rows in `notification_templates` (seed_action_plan_approval.sql). Without them the API logs "Notification template ... not found" and stages nothing, so this step fails. This is the same for WHC; it is not an SRP/ESP defect.

**Actual:** HTTP 200

```json
{
  "data": {
    "list": [
      {
        "id": "eab0a3d7-39a1-410a-b7e0-1785b8842bf6",
        "title": "EUR Threshold Reached",
        "message": "<div style=\"width: 100%\"><span style=\"color: #e7000b\">TCL022A</span> <span style=\"color: #62748e\">reached 95% of EUR.</span></div>",
        "has_read": false,
        "created_at": "19-11-2026 18:02:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=0a1e7000-0000-0000-0000-0000000d0009",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=0a1e7000-0000-0000-0000-0000000d0009",
        "category": "Alert",
        "color_code": "danger"
      },
      {
        "id": "90608b8a-fc0c-4d82-a79c-30af617a94f9",
        "title": "EUR Threshold Reached",
        "message": "<div style=\"width: 100%\"><span style=\"color: #e7000b\">QA55E21</span> <span style=\"color: #62748e\">reached 95% of EUR.</span></div>",
        "has_read": false,
        "created_at": "19-11-2026 18:02:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=b9d8f33e-1161-46de-8811-72a29989c7fc",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=b9d8f33e-1161-46de-8811-72a29989c7fc",
        "category": "Alert",
        "color_code": "danger"
      },
      {
        "id": "bcd1cc86-2c2f-47a1-9bcc-08ee00407665",
        "title": "EUR Exceeded",
        "message": "<div style=\"width: 100%\"><span><span style=\"color: #e7000b\">WELL-TEST-PEP-01-QA</span> <span style=\"color: #62748e\">exceeded 2843.52% of EUR.</span></span></div>",
        "has_read": false,
        "created_at": "19-11-2026 18:02:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=73a376d4-846f-44bb-9937-5060531a6635",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=73a376d4-846f-44bb-9937-5060531a6635",
        "category": "Alert",
        "color_code": "danger"
      },
      "... 7 more"
    ],
    "count": 206524
  },
  "status": "success",
  "code": "",
  "message": "Get Notifications succeed"
}
```

**Result:** FAIL — response has no `0074/WO/SDA1/2026`

## Installation Update

### SRP Installation Update — Approve

#### 26. Next WO number (SSDP)

```bash
curl -s -X GET "$API/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, `data.wo_number` = `NNNN/WO/{short}/{year}` → set `WO`

**Actual:** HTTP 200

```json
{
  "data": {
    "sequence_number": "0075",
    "wo_number": "0075/WO/SDA1/2026"
  },
  "status": "success",
  "code": "00",
  "message": "Get next work order number succeed"
}
```

`WO=0075/WO/SDA1/2026`
**Result:** PASS

#### 27. SSDP submits

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "e1609af4-3368-4338-8456-535f6dd2e0f7",
  "start_date": "2027-04-05",
  "end_date": "2027-04-07",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_update",
    "method": "sucker_rod_pump",
    "assigned_department": "Production Operations",
    "pump_type": "Insert Pump",
    "pump_brand": "Weatherford",
    "stroke_length": 86,
    "spmfreq": 8.5,
    "prime_mover_name": "Gas Engine G3306",
    "power": 40,
    "owned_by": "rental",
    "contract_number": "CTR-PO/2026/021",
    "asset_number": "AST-DROP",
    "production": 120,
    "pressure": 150
  },
  "wo_number": "'"$WO"'"
}'
```

**Expected:** HTTP 200, `data.approval_status` = `waiting_review`, `data.work_order_number` = `$WO`

**Actual:** HTTP 200

```json
{
  "data": {
    "id": "2f4ebf12-c203-45b8-b2b7-81376d9cfd08",
    "record_state": "submitted",
    "approval_status": "waiting_review",
    "work_order_number": "0075/WO/SDA1/2026"
  },
  "status": "success",
  "code": "00",
  "message": "Submit action plan PEP succeed"
}
```

`PLAN=2f4ebf12-c203-45b8-b2b7-81376d9cfd08`
**Result:** PASS

#### 28. PO sees the plan in need-action (review)

```bash
curl -s -X GET "$API/well-surveilence/action-plans/approvals/need-action?stage=review&source=pep&action_plan_type=artificial_lift&page_size=500" \
  -H "Authorization: Bearer $PO"
```

**Expected:** HTTP 200, the list holds `$PLAN`

**Actual:** HTTP 200

```json
{
  "data": {
    "items": [
      {
        "id": "7a6d7ae6-1a23-4a0c-b307-611449196bcc",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "1bad4d3a-b752-4b3f-ae0f-21c1ef321f71",
          "name": "A-INDANA-PEP"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0007/WO/SDA1/2026",
        "cycle_no": null,
        "path": null,
        "current_level": null,
        "total_level": null,
        "start_date": "16-11-2026",
        "end_date": "18-11-2026",
        "pic": null,
        "pic_ids": [
          {
            "id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
            "name": "R3 Test amin"
          }
        ],
        "submitted_by": {
          "id": "0b000000-0000-0000-0000-000000000407",
          "full_name": "PHI SDA 1"
        },
        "submitted_at": "06-11-2026 15:25:13",
        "decided_by": null,
        "waiting_since": "06-11-2026 15:25:13",
        "current_level_sla_days": 3,
        "current_level_due_at": "11-11-2026 15:25:13",
        "current_level_status": "delayed"
      },
      {
        "id": "63cffc30-e2cc-4a47-8ac3-47504313fe99",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "a8ca5725-d2e0-4846-8cc2-880213b43e1c",
          "name": "DEMOBD-INJ"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0059/WO/SDA1/2026",
        "cycle_no": 1,
        "path": "reject",
        "current_level": null,
        "total_level": null,
        "start_date": "26-11-2026",
        "end_date": "28-11-2026",
        "pic": null,
        "pic_ids": [
          {
            "id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
            "name": "R3 Test amin"
          }
        ],
        "submitted_by": {
          "id": "0b000000-0000-0000-0000-000000000407",
          "full_name": "PHI SDA 1"
        },
        "submitted_at": "19-11-2026 10:13:45",
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "waiting_since": "19-11-2026 10:13:51",
        "current_level_sla_days": 3,
        "current_level_due_at": "24-11-2026 10:13:51",
        "current_level_status": "on_track"
      },
      {
        "id": "5dccdacd-6fed-4324-8c95-adc9374b8c1b",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "73b8447a-a53d-4b84-844c-ad12e7e4f856",
          "name": "DEMOBD-P2"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0060/WO/SDA1/2026",
        "cycle_no": 1,
        "path": "reject",
        "current_level": null,
        "total_level": null,
        "start_date": "26-11-2026",
        "end_date": "28-11-2026",
        "pic": null,
        "pic_ids": [
          {
            "id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
            "name": "R3 Test amin"
          }
        ],
        "submitted_by": {
          "id": "0b000000-0000-0000-0000-000000000407",
          "full_name": "PHI SDA 1"
        },
        "submitted_at": "19-11-2026 10:14:00",
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "waiting_since": "19-11-2026 10:14:10",
        "current_level_sla_days": 3,
        "current_level_due_at": "24-11-2026 10:14:10",
        "current_level_status": "on_track"
      },
      "... 5 more"
    ],
    "page": 1,
    "page_size": 500,
    "total": 8
  },
  "status": "success",
  "code": "00",
  "message": "Get action plan need action succeed"
}
```

**Result:** PASS

#### 29. PO gets the request notification

```bash
curl -s -X GET "$API/notifications/mine?page=1&page_size=10" \
  -H "Authorization: Bearer $PO"
```

**Expected:** HTTP 200, a notification names `$WO` ("Artificial Lift Request"). Needs the `phantom_iac_action_plan_*` rows in `notification_templates` (seed_action_plan_approval.sql). Without them the API logs "Notification template ... not found" and stages nothing, so this step fails. This is the same for WHC; it is not an SRP/ESP defect.

**Actual:** HTTP 200

```json
{
  "data": {
    "list": [
      {
        "id": "1acd32ae-16b3-4414-9f43-11af94c84d7c",
        "title": "Action Plan Rejected by Manager",
        "message": "WO Number 0052/WO/SDA1/2026 Action Plan rejected",
        "has_read": false,
        "created_at": "19-11-2026 10:10:06",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=2e82b888-b9da-40b2-b097-5e7894f7774d&action_plan_id=89703f53-ea03-45ba-ae78-2ac926eef9b3",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=2e82b888-b9da-40b2-b097-5e7894f7774d&action_plan_id=89703f53-ea03-45ba-ae78-2ac926eef9b3",
        "category": "Approval",
        "color_code": "danger"
      },
      {
        "id": "c82db0a2-37c8-41ff-ab6e-7790f9f0bf99",
        "title": "Action Plan Rejected by Manager",
        "message": "WO Number 0034/WO/SDA1/2026 Action Plan rejected",
        "has_read": false,
        "created_at": "16-11-2026 15:54:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=0dc94bc8-eccd-426e-ba59-90d876a59b89&action_plan_id=6f574ea5-6f02-45e6-b52f-e024c88f5731",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=0dc94bc8-eccd-426e-ba59-90d876a59b89&action_plan_id=6f574ea5-6f02-45e6-b52f-e024c88f5731",
        "category": "Approval",
        "color_code": "danger"
      },
      {
        "id": "cdb7fd52-bb2d-4091-9bb4-30ae6bb24d0f",
        "title": "Well Test Request",
        "message": "WO Number 0031/WO/SDA1/2026 Well Test need Approval.",
        "has_read": false,
        "created_at": "10-11-2026 19:35:33",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=f1000000-0000-4000-8000-000000000001&action_plan_id=849d007c-619c-4c25-893f-6cefeee38d6b",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=f1000000-0000-4000-8000-000000000001&action_plan_id=849d007c-619c-4c25-893f-6cefeee38d6b",
        "category": "Request",
        "color_code": "warning"
      },
      "... 7 more"
    ],
    "count": 4108
  },
  "status": "success",
  "code": "",
  "message": "Get Notifications succeed"
}
```

**Result:** FAIL — response has no `0075/WO/SDA1/2026`

#### 30. PO approves

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/$PLAN/review" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "approve",
  "remarks": "OK, jalankan sesuai jadwal",
  "execution_department_id": "Production Operations",
  "execution_pic_id": "0b000000-0000-0000-0000-000000000406"
}'
```

**Expected:** HTTP 200, `data.approval_status` = `approved`, `data.path` = `approve`

**Actual:** HTTP 200

```json
{
  "data": {
    "action_plan_id": "2f4ebf12-c203-45b8-b2b7-81376d9cfd08",
    "source": "pep",
    "work_order_number": "0075/WO/SDA1/2026",
    "approval_status": "approved",
    "cycle_no": 1,
    "path": "approve",
    "current_level": null,
    "total_levels": null
  },
  "status": "success",
  "code": "00",
  "message": "Review action plan succeed"
}
```

**Result:** PASS

#### 31. Detail shows approved

```bash
curl -s -X GET "$API/well-surveilence/action-plans/pep/$PLAN" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, `data.approval_status` = `approved`, `data.artificial_lift.method` = `sucker_rod_pump`

**Actual:** HTTP 200

```json
{
  "data": {
    "id": "2f4ebf12-c203-45b8-b2b7-81376d9cfd08",
    "action_plan_type": "artificial_lift",
    "status": "on_schedule",
    "start_date": "05-04-2027",
    "end_date": "07-04-2027",
    "notes": "SRP/ESP curl test",
    "ownership": "Pertamina EP",
    "pic": null,
    "pic_ids": [
      {
        "id": "809819E6-A03A-4504-A2AC-6116847FD6A9",
        "name": "PHI SDA 1",
        "email": "phi.sda1@yopmail.com"
      }
    ],
    "created_at": "19-11-2026 18:25:07",
    "created_by": {
      "id": "0B000000-0000-0000-0000-000000000407",
      "full_name": "PHI SDA 1"
    },
    "updated_at": "19-11-2026 18:25:11",
    "updated_by": {
      "id": "0B000000-0000-0000-0000-000000000406",
      "full_name": "PHI PO"
    },
    "choke": null,
    "sonolog": null,
    "well_test": null,
    "artificial_lift": {
      "activity_type": "installation",
      "action_mode": "installation_update",
      "method": "sucker_rod_pump",
      "prime_mover": 0,
      "power": 40.0,
      "bean": 0,
      "thp": 0,
      "flowline_pressure": 0,
      "casing_pressure": 0,
      "separator_pressure": 0,
      "spmfreq": 8.5,
      "pump_size": 0,
      "pump_displacement": 0,
      "pump_efficiency": 0,
      "stroke_length": 86.0,
      "pump_intake_depth": 0,
      "submerging": 0,
      "production": 120.0,
      "pressure": 150.0,
      "ownership": "Pertamina EP",
      "whc_type": null,
      "compression_type": null,
      "owned_by": "rental",
      "contract_number": "CTR-PO/2026/021",
      "asset_number": null,
      "cost_allocation": null,
      "pump_type": "Insert Pump",
      "pump_brand": "Weatherford",
      "prime_mover_name": "Gas Engine G3306",
      "frequency": null,
      "electric_current": null
    },
    "others": null,
    "approval_status": "approved",
    "requires_approval": true,
    "work_order_number": "0075/WO/SDA1/2026",
    "assigned_department": "Production Operations",
    "execution_department_id": "Production Operations",
    "execution_pic": {
      "id": "0B000000-0000-0000-0000-000000000406",
      "name": "PHI PO",
      "email": "phi.po@yopmail.com"
    },
    "can_review": false,
    "can_approve": false,
    "can_reject": false,
    "approval": {
      "cycle_no": 1,
      "path": "approve",
      "current_level": null,
      "total_levels": null
    }
  },
  "status": "success",
  "code": "00",
  "message": "Get action plan PEP detail succeed"
}
```

**Result:** PASS

#### 32. SSDP gets the result notification

```bash
curl -s -X GET "$API/notifications/mine?page=1&page_size=10" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, a notification names `$WO`. Needs the `phantom_iac_action_plan_*` rows in `notification_templates` (seed_action_plan_approval.sql). Without them the API logs "Notification template ... not found" and stages nothing, so this step fails. This is the same for WHC; it is not an SRP/ESP defect.

**Actual:** HTTP 200

```json
{
  "data": {
    "list": [
      {
        "id": "ec97d982-e5e1-4abf-ac0c-449b650e054e",
        "title": "EUR Exceeded",
        "message": "<div style=\"width: 100%\"><span><span style=\"color: #e7000b\">WELL_COMP_TABLE</span> <span style=\"color: #62748e\">exceeded 120000% of EUR.</span></span></div>",
        "has_read": false,
        "created_at": "19-11-2026 18:02:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=33bc8077-0225-4fbf-92c4-ca74821869f5",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=33bc8077-0225-4fbf-92c4-ca74821869f5",
        "category": "Alert",
        "color_code": "danger"
      },
      {
        "id": "d67f4468-52a7-4169-bf97-21a13374251b",
        "title": "EUR Threshold Exceeded",
        "message": "<div style=\"width: 100%\"><span><span style=\"color: #e7000b\">QSEURB</span> <span style=\"color: #62748e\">exceeded 95% of EUR.</span></span></div>",
        "has_read": false,
        "created_at": "19-11-2026 18:02:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=9c7223e8-1364-4cad-9a0b-3fab4c9aae9a",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=9c7223e8-1364-4cad-9a0b-3fab4c9aae9a",
        "category": "Alert",
        "color_code": "danger"
      },
      {
        "id": "550a6a5e-8bb8-4f3a-9a4c-1b233bd5c3dd",
        "title": "EUR Exceeded",
        "message": "<div style=\"width: 100%\"><span><span style=\"color: #e7000b\">WELLY-BDK-TEST-FORCASE1</span> <span style=\"color: #62748e\">exceeded 1274.66% of EUR.</span></span></div>",
        "has_read": false,
        "created_at": "19-11-2026 18:02:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=ce935186-e285-451b-bb69-5747f19b31b6",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=ce935186-e285-451b-bb69-5747f19b31b6",
        "category": "Alert",
        "color_code": "danger"
      },
      "... 7 more"
    ],
    "count": 206524
  },
  "status": "success",
  "code": "",
  "message": "Get Notifications succeed"
}
```

**Result:** FAIL — response has no `0075/WO/SDA1/2026`

### SRP Installation Update — Modify

#### 33. Next WO number (SSDP)

```bash
curl -s -X GET "$API/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, `data.wo_number` = `NNNN/WO/{short}/{year}` → set `WO`

**Actual:** HTTP 200

```json
{
  "data": {
    "sequence_number": "0076",
    "wo_number": "0076/WO/SDA1/2026"
  },
  "status": "success",
  "code": "00",
  "message": "Get next work order number succeed"
}
```

`WO=0076/WO/SDA1/2026`
**Result:** PASS

#### 34. SSDP submits

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "d704cd24-113b-4c1b-b845-117b3f97a08a",
  "start_date": "2027-04-05",
  "end_date": "2027-04-07",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_update",
    "method": "sucker_rod_pump",
    "assigned_department": "Production Operations",
    "pump_type": "Insert Pump",
    "pump_brand": "Weatherford",
    "stroke_length": 86,
    "spmfreq": 8.5,
    "prime_mover_name": "Gas Engine G3306",
    "power": 40,
    "owned_by": "rental",
    "contract_number": "CTR-PO/2026/021",
    "asset_number": "AST-DROP",
    "production": 120,
    "pressure": 150
  },
  "wo_number": "'"$WO"'"
}'
```

**Expected:** HTTP 200, `data.approval_status` = `waiting_review`, `data.work_order_number` = `$WO`

**Actual:** HTTP 200

```json
{
  "data": {
    "id": "702c480f-4148-427b-8cc8-5d4d57fb26bc",
    "record_state": "submitted",
    "approval_status": "waiting_review",
    "work_order_number": "0076/WO/SDA1/2026"
  },
  "status": "success",
  "code": "00",
  "message": "Submit action plan PEP succeed"
}
```

`PLAN=702c480f-4148-427b-8cc8-5d4d57fb26bc`
**Result:** PASS

#### 35. PO sees the plan in need-action (review)

```bash
curl -s -X GET "$API/well-surveilence/action-plans/approvals/need-action?stage=review&source=pep&action_plan_type=artificial_lift&page_size=500" \
  -H "Authorization: Bearer $PO"
```

**Expected:** HTTP 200, the list holds `$PLAN`

**Actual:** HTTP 200

```json
{
  "data": {
    "items": [
      {
        "id": "7a6d7ae6-1a23-4a0c-b307-611449196bcc",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "1bad4d3a-b752-4b3f-ae0f-21c1ef321f71",
          "name": "A-INDANA-PEP"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0007/WO/SDA1/2026",
        "cycle_no": null,
        "path": null,
        "current_level": null,
        "total_level": null,
        "start_date": "16-11-2026",
        "end_date": "18-11-2026",
        "pic": null,
        "pic_ids": [
          {
            "id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
            "name": "R3 Test amin"
          }
        ],
        "submitted_by": {
          "id": "0b000000-0000-0000-0000-000000000407",
          "full_name": "PHI SDA 1"
        },
        "submitted_at": "06-11-2026 15:25:13",
        "decided_by": null,
        "waiting_since": "06-11-2026 15:25:13",
        "current_level_sla_days": 3,
        "current_level_due_at": "11-11-2026 15:25:13",
        "current_level_status": "delayed"
      },
      {
        "id": "63cffc30-e2cc-4a47-8ac3-47504313fe99",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "a8ca5725-d2e0-4846-8cc2-880213b43e1c",
          "name": "DEMOBD-INJ"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0059/WO/SDA1/2026",
        "cycle_no": 1,
        "path": "reject",
        "current_level": null,
        "total_level": null,
        "start_date": "26-11-2026",
        "end_date": "28-11-2026",
        "pic": null,
        "pic_ids": [
          {
            "id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
            "name": "R3 Test amin"
          }
        ],
        "submitted_by": {
          "id": "0b000000-0000-0000-0000-000000000407",
          "full_name": "PHI SDA 1"
        },
        "submitted_at": "19-11-2026 10:13:45",
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "waiting_since": "19-11-2026 10:13:51",
        "current_level_sla_days": 3,
        "current_level_due_at": "24-11-2026 10:13:51",
        "current_level_status": "on_track"
      },
      {
        "id": "5dccdacd-6fed-4324-8c95-adc9374b8c1b",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "73b8447a-a53d-4b84-844c-ad12e7e4f856",
          "name": "DEMOBD-P2"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0060/WO/SDA1/2026",
        "cycle_no": 1,
        "path": "reject",
        "current_level": null,
        "total_level": null,
        "start_date": "26-11-2026",
        "end_date": "28-11-2026",
        "pic": null,
        "pic_ids": [
          {
            "id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
            "name": "R3 Test amin"
          }
        ],
        "submitted_by": {
          "id": "0b000000-0000-0000-0000-000000000407",
          "full_name": "PHI SDA 1"
        },
        "submitted_at": "19-11-2026 10:14:00",
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "waiting_since": "19-11-2026 10:14:10",
        "current_level_sla_days": 3,
        "current_level_due_at": "24-11-2026 10:14:10",
        "current_level_status": "on_track"
      },
      "... 5 more"
    ],
    "page": 1,
    "page_size": 500,
    "total": 8
  },
  "status": "success",
  "code": "00",
  "message": "Get action plan need action succeed"
}
```

**Result:** PASS

#### 36. PO gets the request notification

```bash
curl -s -X GET "$API/notifications/mine?page=1&page_size=10" \
  -H "Authorization: Bearer $PO"
```

**Expected:** HTTP 200, a notification names `$WO` ("Artificial Lift Request"). Needs the `phantom_iac_action_plan_*` rows in `notification_templates` (seed_action_plan_approval.sql). Without them the API logs "Notification template ... not found" and stages nothing, so this step fails. This is the same for WHC; it is not an SRP/ESP defect.

**Actual:** HTTP 200

```json
{
  "data": {
    "list": [
      {
        "id": "1acd32ae-16b3-4414-9f43-11af94c84d7c",
        "title": "Action Plan Rejected by Manager",
        "message": "WO Number 0052/WO/SDA1/2026 Action Plan rejected",
        "has_read": false,
        "created_at": "19-11-2026 10:10:06",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=2e82b888-b9da-40b2-b097-5e7894f7774d&action_plan_id=89703f53-ea03-45ba-ae78-2ac926eef9b3",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=2e82b888-b9da-40b2-b097-5e7894f7774d&action_plan_id=89703f53-ea03-45ba-ae78-2ac926eef9b3",
        "category": "Approval",
        "color_code": "danger"
      },
      {
        "id": "c82db0a2-37c8-41ff-ab6e-7790f9f0bf99",
        "title": "Action Plan Rejected by Manager",
        "message": "WO Number 0034/WO/SDA1/2026 Action Plan rejected",
        "has_read": false,
        "created_at": "16-11-2026 15:54:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=0dc94bc8-eccd-426e-ba59-90d876a59b89&action_plan_id=6f574ea5-6f02-45e6-b52f-e024c88f5731",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=0dc94bc8-eccd-426e-ba59-90d876a59b89&action_plan_id=6f574ea5-6f02-45e6-b52f-e024c88f5731",
        "category": "Approval",
        "color_code": "danger"
      },
      {
        "id": "cdb7fd52-bb2d-4091-9bb4-30ae6bb24d0f",
        "title": "Well Test Request",
        "message": "WO Number 0031/WO/SDA1/2026 Well Test need Approval.",
        "has_read": false,
        "created_at": "10-11-2026 19:35:33",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=f1000000-0000-4000-8000-000000000001&action_plan_id=849d007c-619c-4c25-893f-6cefeee38d6b",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=f1000000-0000-4000-8000-000000000001&action_plan_id=849d007c-619c-4c25-893f-6cefeee38d6b",
        "category": "Request",
        "color_code": "warning"
      },
      "... 7 more"
    ],
    "count": 4108
  },
  "status": "success",
  "code": "",
  "message": "Get Notifications succeed"
}
```

**Result:** FAIL — response has no `0076/WO/SDA1/2026`

#### 37. PO modifies (manager → SSDP creator)

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/$PLAN/review" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "modify",
  "remarks": "Ubah parameter pompa",
  "proposed": {
    "start_date": "2027-04-05",
    "end_date": "2027-04-07",
    "pic_ids": [
      "0b000000-0000-0000-0000-000000000407"
    ],
    "notes": "SRP/ESP curl test",
    "ownership": "Pertamina EP",
    "artificial_lift": {
      "activity_type": "installation",
      "action_mode": "installation_update",
      "method": "sucker_rod_pump",
      "assigned_department": "Production Operations",
      "pump_type": "Insert Pump",
      "pump_brand": "Lufkin",
      "stroke_length": 100,
      "spmfreq": 8.5,
      "prime_mover_name": "Gas Engine G3306",
      "power": 40,
      "owned_by": "rental",
      "contract_number": "CTR-PO/2026/021",
      "asset_number": "AST-DROP",
      "production": 120,
      "pressure": 150
    }
  },
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ]
    }
  ]
}'
```

**Expected:** HTTP 200, `data.approval_status` = `modify_in_approval`, `data.current_level` = `1`, `data.total_levels` = `2`

**Actual:** HTTP 200

```json
{
  "data": {
    "action_plan_id": "702c480f-4148-427b-8cc8-5d4d57fb26bc",
    "source": "pep",
    "work_order_number": "0076/WO/SDA1/2026",
    "approval_status": "modify_in_approval",
    "cycle_no": 1,
    "path": "modify",
    "current_level": 1,
    "total_levels": 2
  },
  "status": "success",
  "code": "00",
  "message": "Review action plan succeed"
}
```

**Result:** PASS

#### 38. Modification diff

```bash
curl -s -X GET "$API/well-surveilence/action-plans/pep/$PLAN/modification-diff" \
  -H "Authorization: Bearer $PO"
```

**Expected:** HTTP 200, `data.changes[].field` = ['artificial_lift.pump_brand', 'artificial_lift.stroke_length'] (nothing else changes)

**Actual:** HTTP 200

```json
{
  "data": {
    "cycle_id": "54b27205-4ce7-4e76-aa67-89eddb82abf6",
    "cycle_no": 1,
    "applied_at": null,
    "changes": [
      {
        "field": "artificial_lift.pump_brand",
        "original": "Weatherford",
        "proposed": "Lufkin"
      },
      {
        "field": "artificial_lift.stroke_length",
        "original": 86.0,
        "proposed": 100
      }
    ],
    "original": {
      "action_plan_type": "artificial_lift",
      "draft_id": null,
      "well_id": "d704cd24-113b-4c1b-b845-117b3f97a08a",
      "start_date": "05-04-2027",
      "end_date": "07-04-2027",
      "pic_id": null,
      "pic_ids": [
        "0b000000-0000-0000-0000-000000000407"
      ],
      "notes": "SRP/ESP curl test",
      "ownership": "Pertamina EP",
      "wo_number": null,
      "choke": null,
      "sonolog": null,
      "well_test": null,
      "artificial_lift": {
        "activity_type": "installation",
        "action_mode": "installation_update",
        "method": "sucker_rod_pump",
        "prime_mover": null,
        "power": 40.0,
        "bean": null,
        "thp": null,
        "flowline_pressure": null,
        "casing_pressure": null,
        "separator_pressure": null,
        "spmfreq": 8.5,
        "pump_size": null,
        "pump_displacement": null,
        "pump_efficiency": null,
        "stroke_length": 86.0,
        "pump_intake_depth": null,
        "submerging": null,
        "production": 120.0,
        "pressure": 150.0,
        "ownership": null,
        "assigned_department": "Production Operations",
        "whc_type": null,
        "compression_type": null,
        "owned_by": "rental",
        "contract_number": "CTR-PO/2026/021",
        "asset_number": null,
        "cost_allocation": null,
        "pump_type": "Insert Pump",
        "pump_brand": "Weatherford",
        "prime_mover_name": "Gas Engine G3306",
        "frequency": null,
        "electric_current": null
      },
      "others": null,
      "execution_department_id": null,
      "execution_pic_id": null
    },
    "proposed": {
      "action_plan_type": "artificial_lift",
      "draft_id": null,
      "well_id": "d704cd24-113b-4c1b-b845-117b3f97a08a",
      "start_date": "05-04-2027",
      "end_date": "07-04-2027",
      "pic_id": null,
      "pic_ids": [
        "0b000000-0000-0000-0000-000000000407"
      ],
      "notes": "SRP/ESP curl test",
      "ownership": "Pertamina EP",
      "wo_number": null,
      "choke": null,
      "sonolog": null,
      "well_test": null,
      "artificial_lift": {
        "activity_type": "installation",
        "action_mode": "installation_update",
        "method": "sucker_rod_pump",
        "prime_mover": null,
        "power": 40,
        "bean": null,
        "thp": null,
        "flowline_pressure": null,
        "casing_pressure": null,
        "separator_pressure": null,
        "spmfreq": 8.5,
        "pump_size": null,
        "pump_displacement": null,
        "pump_efficiency": null,
        "stroke_length": 100,
        "pump_intake_depth": null,
        "submerging": null,
        "production": 120,
        "pressure": 150,
        "ownership": null,
        "assigned_department": "Production Operations",
        "whc_type": null,
        "compression_type": null,
        "owned_by": "rental",
        "contract_number": "CTR-PO/2026/021",
        "asset_number": null,
        "cost_allocation": null,
        "pump_type": "Insert Pump",
        "pump_brand": "Lufkin",
        "prime_mover_name": "Gas Engine G3306",
        "frequency": null,
        "electric_current": null
      },
      "others": null,
      "execution_department_id": null,
      "execution_pic_id": null
    }
  },
  "status": "success",
  "code": "00",
  "message": "Get action plan modification diff succeed"
}
```

**Result:** PASS

#### 39. Manager level 1 approves

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/$PLAN/approval/approve" \
  -H "Authorization: Bearer $MGR" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "OK"
}'
```

**Expected:** HTTP 200, `data.approval_status` = `modify_in_approval`, `data.current_level` = `2`

**Actual:** HTTP 200

```json
{
  "data": {
    "action_plan_id": "702c480f-4148-427b-8cc8-5d4d57fb26bc",
    "source": "pep",
    "work_order_number": "0076/WO/SDA1/2026",
    "approval_status": "modify_in_approval",
    "cycle_no": 1,
    "path": "modify",
    "current_level": 2,
    "total_levels": 2
  },
  "status": "success",
  "code": "00",
  "message": "Approve action plan succeed"
}
```

**Result:** PASS

#### 40. SSDP creator (last level) approves → proposal applied

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/$PLAN/approval/approve" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "OK"
}'
```

**Expected:** HTTP 200, `data.approval_status` = `approved`

**Actual:** HTTP 200

```json
{
  "data": {
    "action_plan_id": "702c480f-4148-427b-8cc8-5d4d57fb26bc",
    "source": "pep",
    "work_order_number": "0076/WO/SDA1/2026",
    "approval_status": "approved",
    "cycle_no": 1,
    "path": "modify",
    "current_level": null,
    "total_levels": 2
  },
  "status": "success",
  "code": "00",
  "message": "Approve action plan succeed"
}
```

**Result:** PASS

#### 41. Detail shows the applied proposal

```bash
curl -s -X GET "$API/well-surveilence/action-plans/pep/$PLAN" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, `data.approval_status` = `approved`, `data.artificial_lift.pump_brand` = `Lufkin`, `data.artificial_lift.stroke_length` = `100`

**Actual:** HTTP 200

```json
{
  "data": {
    "id": "702c480f-4148-427b-8cc8-5d4d57fb26bc",
    "action_plan_type": "artificial_lift",
    "status": "on_schedule",
    "start_date": "05-04-2027",
    "end_date": "07-04-2027",
    "notes": "SRP/ESP curl test",
    "ownership": "Pertamina EP",
    "pic": null,
    "pic_ids": [
      {
        "id": "381B02F8-EEB1-4A72-AA41-4EF40384BD15",
        "name": "PHI SDA 1",
        "email": "phi.sda1@yopmail.com"
      }
    ],
    "created_at": "19-11-2026 18:25:15",
    "created_by": {
      "id": "0B000000-0000-0000-0000-000000000407",
      "full_name": "PHI SDA 1"
    },
    "updated_at": "19-11-2026 18:25:22",
    "updated_by": {
      "id": "0B000000-0000-0000-0000-000000000407",
      "full_name": "PHI SDA 1"
    },
    "choke": null,
    "sonolog": null,
    "well_test": null,
    "artificial_lift": {
      "activity_type": "installation",
      "action_mode": "installation_update",
      "method": "sucker_rod_pump",
      "prime_mover": 0,
      "power": 40.0,
      "bean": 0,
      "thp": 0,
      "flowline_pressure": 0,
      "casing_pressure": 0,
      "separator_pressure": 0,
      "spmfreq": 8.5,
      "pump_size": 0,
      "pump_displacement": 0,
      "pump_efficiency": 0,
      "stroke_length": 100.0,
      "pump_intake_depth": 0,
      "submerging": 0,
      "production": 120.0,
      "pressure": 150.0,
      "ownership": "Pertamina EP",
      "whc_type": null,
      "compression_type": null,
      "owned_by": "rental",
      "contract_number": "CTR-PO/2026/021",
      "asset_number": null,
      "cost_allocation": null,
      "pump_type": "Insert Pump",
      "pump_brand": "Lufkin",
      "prime_mover_name": "Gas Engine G3306",
      "frequency": null,
      "electric_current": null
    },
    "others": null,
    "approval_status": "approved",
    "requires_approval": true,
    "work_order_number": "0076/WO/SDA1/2026",
    "assigned_department": "Production Operations",
    "execution_department_id": null,
    "execution_pic": null,
    "can_review": false,
    "can_approve": false,
    "can_reject": false,
    "approval": {
      "cycle_no": 1,
      "path": "modify",
      "current_level": null,
      "total_levels": 2
    }
  },
  "status": "success",
  "code": "00",
  "message": "Get action plan PEP detail succeed"
}
```

**Result:** PASS

#### 42. SSDP gets the result notification

```bash
curl -s -X GET "$API/notifications/mine?page=1&page_size=10" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, a notification names `$WO`. Needs the `phantom_iac_action_plan_*` rows in `notification_templates` (seed_action_plan_approval.sql). Without them the API logs "Notification template ... not found" and stages nothing, so this step fails. This is the same for WHC; it is not an SRP/ESP defect.

**Actual:** HTTP 200

```json
{
  "data": {
    "list": [
      {
        "id": "dd0b7bb8-62dd-4b57-9ff5-035ac96dfca6",
        "title": "EUR Threshold Exceeded",
        "message": "<div style=\"width: 100%\"><span><span style=\"color: #e7000b\">QSIWFA</span> <span style=\"color: #62748e\">exceeded 95% of EUR.</span></span></div>",
        "has_read": false,
        "created_at": "19-11-2026 18:02:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=7b1198d5-8bcd-4069-a0f0-96aec42fd994",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=7b1198d5-8bcd-4069-a0f0-96aec42fd994",
        "category": "Alert",
        "color_code": "danger"
      },
      {
        "id": "bcd1cc86-2c2f-47a1-9bcc-08ee00407665",
        "title": "EUR Exceeded",
        "message": "<div style=\"width: 100%\"><span><span style=\"color: #e7000b\">WELL-TEST-PEP-01-QA</span> <span style=\"color: #62748e\">exceeded 2843.52% of EUR.</span></span></div>",
        "has_read": false,
        "created_at": "19-11-2026 18:02:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=73a376d4-846f-44bb-9937-5060531a6635",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=73a376d4-846f-44bb-9937-5060531a6635",
        "category": "Alert",
        "color_code": "danger"
      },
      {
        "id": "403ae9bb-5830-46fb-a2e9-0a8d801511c0",
        "title": "EUR Threshold Exceeded",
        "message": "<div style=\"width: 100%\"><span><span style=\"color: #e7000b\">QA57P22</span> <span style=\"color: #62748e\">exceeded 95% of EUR.</span></span></div>",
        "has_read": false,
        "created_at": "19-11-2026 18:02:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=68925d0d-c448-4333-b0ca-de75c0f5aa83",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=68925d0d-c448-4333-b0ca-de75c0f5aa83",
        "category": "Alert",
        "color_code": "danger"
      },
      "... 7 more"
    ],
    "count": 206524
  },
  "status": "success",
  "code": "",
  "message": "Get Notifications succeed"
}
```

**Result:** FAIL — response has no `0076/WO/SDA1/2026`

### SRP Installation Update — Reject

#### 43. Next WO number (SSDP)

```bash
curl -s -X GET "$API/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, `data.wo_number` = `NNNN/WO/{short}/{year}` → set `WO`

**Actual:** HTTP 200

```json
{
  "data": {
    "sequence_number": "0077",
    "wo_number": "0077/WO/SDA1/2026"
  },
  "status": "success",
  "code": "00",
  "message": "Get next work order number succeed"
}
```

`WO=0077/WO/SDA1/2026`
**Result:** PASS

#### 44. SSDP submits

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "188aa625-0cdc-4f0c-8df8-9895ae6df5d9",
  "start_date": "2027-04-05",
  "end_date": "2027-04-07",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_update",
    "method": "sucker_rod_pump",
    "assigned_department": "Production Operations",
    "pump_type": "Insert Pump",
    "pump_brand": "Weatherford",
    "stroke_length": 86,
    "spmfreq": 8.5,
    "prime_mover_name": "Gas Engine G3306",
    "power": 40,
    "owned_by": "rental",
    "contract_number": "CTR-PO/2026/021",
    "asset_number": "AST-DROP",
    "production": 120,
    "pressure": 150
  },
  "wo_number": "'"$WO"'"
}'
```

**Expected:** HTTP 200, `data.approval_status` = `waiting_review`, `data.work_order_number` = `$WO`

**Actual:** HTTP 200

```json
{
  "data": {
    "id": "d3061b55-0aec-4eb1-8401-32f9249b5bcf",
    "record_state": "submitted",
    "approval_status": "waiting_review",
    "work_order_number": "0077/WO/SDA1/2026"
  },
  "status": "success",
  "code": "00",
  "message": "Submit action plan PEP succeed"
}
```

`PLAN=d3061b55-0aec-4eb1-8401-32f9249b5bcf`
**Result:** PASS

#### 45. PO sees the plan in need-action (review)

```bash
curl -s -X GET "$API/well-surveilence/action-plans/approvals/need-action?stage=review&source=pep&action_plan_type=artificial_lift&page_size=500" \
  -H "Authorization: Bearer $PO"
```

**Expected:** HTTP 200, the list holds `$PLAN`

**Actual:** HTTP 200

```json
{
  "data": {
    "items": [
      {
        "id": "7a6d7ae6-1a23-4a0c-b307-611449196bcc",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "1bad4d3a-b752-4b3f-ae0f-21c1ef321f71",
          "name": "A-INDANA-PEP"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0007/WO/SDA1/2026",
        "cycle_no": null,
        "path": null,
        "current_level": null,
        "total_level": null,
        "start_date": "16-11-2026",
        "end_date": "18-11-2026",
        "pic": null,
        "pic_ids": [
          {
            "id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
            "name": "R3 Test amin"
          }
        ],
        "submitted_by": {
          "id": "0b000000-0000-0000-0000-000000000407",
          "full_name": "PHI SDA 1"
        },
        "submitted_at": "06-11-2026 15:25:13",
        "decided_by": null,
        "waiting_since": "06-11-2026 15:25:13",
        "current_level_sla_days": 3,
        "current_level_due_at": "11-11-2026 15:25:13",
        "current_level_status": "delayed"
      },
      {
        "id": "63cffc30-e2cc-4a47-8ac3-47504313fe99",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "a8ca5725-d2e0-4846-8cc2-880213b43e1c",
          "name": "DEMOBD-INJ"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0059/WO/SDA1/2026",
        "cycle_no": 1,
        "path": "reject",
        "current_level": null,
        "total_level": null,
        "start_date": "26-11-2026",
        "end_date": "28-11-2026",
        "pic": null,
        "pic_ids": [
          {
            "id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
            "name": "R3 Test amin"
          }
        ],
        "submitted_by": {
          "id": "0b000000-0000-0000-0000-000000000407",
          "full_name": "PHI SDA 1"
        },
        "submitted_at": "19-11-2026 10:13:45",
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "waiting_since": "19-11-2026 10:13:51",
        "current_level_sla_days": 3,
        "current_level_due_at": "24-11-2026 10:13:51",
        "current_level_status": "on_track"
      },
      {
        "id": "5dccdacd-6fed-4324-8c95-adc9374b8c1b",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "73b8447a-a53d-4b84-844c-ad12e7e4f856",
          "name": "DEMOBD-P2"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0060/WO/SDA1/2026",
        "cycle_no": 1,
        "path": "reject",
        "current_level": null,
        "total_level": null,
        "start_date": "26-11-2026",
        "end_date": "28-11-2026",
        "pic": null,
        "pic_ids": [
          {
            "id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676",
            "name": "R3 Test amin"
          }
        ],
        "submitted_by": {
          "id": "0b000000-0000-0000-0000-000000000407",
          "full_name": "PHI SDA 1"
        },
        "submitted_at": "19-11-2026 10:14:00",
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "waiting_since": "19-11-2026 10:14:10",
        "current_level_sla_days": 3,
        "current_level_due_at": "24-11-2026 10:14:10",
        "current_level_status": "on_track"
      },
      "... 5 more"
    ],
    "page": 1,
    "page_size": 500,
    "total": 8
  },
  "status": "success",
  "code": "00",
  "message": "Get action plan need action succeed"
}
```

**Result:** PASS

#### 46. PO gets the request notification

```bash
curl -s -X GET "$API/notifications/mine?page=1&page_size=10" \
  -H "Authorization: Bearer $PO"
```

**Expected:** HTTP 200, a notification names `$WO` ("Artificial Lift Request"). Needs the `phantom_iac_action_plan_*` rows in `notification_templates` (seed_action_plan_approval.sql). Without them the API logs "Notification template ... not found" and stages nothing, so this step fails. This is the same for WHC; it is not an SRP/ESP defect.

**Actual:** HTTP 200

```json
{
  "data": {
    "list": [
      {
        "id": "1acd32ae-16b3-4414-9f43-11af94c84d7c",
        "title": "Action Plan Rejected by Manager",
        "message": "WO Number 0052/WO/SDA1/2026 Action Plan rejected",
        "has_read": false,
        "created_at": "19-11-2026 10:10:06",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=2e82b888-b9da-40b2-b097-5e7894f7774d&action_plan_id=89703f53-ea03-45ba-ae78-2ac926eef9b3",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=2e82b888-b9da-40b2-b097-5e7894f7774d&action_plan_id=89703f53-ea03-45ba-ae78-2ac926eef9b3",
        "category": "Approval",
        "color_code": "danger"
      },
      {
        "id": "c82db0a2-37c8-41ff-ab6e-7790f9f0bf99",
        "title": "Action Plan Rejected by Manager",
        "message": "WO Number 0034/WO/SDA1/2026 Action Plan rejected",
        "has_read": false,
        "created_at": "16-11-2026 15:54:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=0dc94bc8-eccd-426e-ba59-90d876a59b89&action_plan_id=6f574ea5-6f02-45e6-b52f-e024c88f5731",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=0dc94bc8-eccd-426e-ba59-90d876a59b89&action_plan_id=6f574ea5-6f02-45e6-b52f-e024c88f5731",
        "category": "Approval",
        "color_code": "danger"
      },
      {
        "id": "cdb7fd52-bb2d-4091-9bb4-30ae6bb24d0f",
        "title": "Well Test Request",
        "message": "WO Number 0031/WO/SDA1/2026 Well Test need Approval.",
        "has_read": false,
        "created_at": "10-11-2026 19:35:33",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=f1000000-0000-4000-8000-000000000001&action_plan_id=849d007c-619c-4c25-893f-6cefeee38d6b",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=f1000000-0000-4000-8000-000000000001&action_plan_id=849d007c-619c-4c25-893f-6cefeee38d6b",
        "category": "Request",
        "color_code": "warning"
      },
      "... 7 more"
    ],
    "count": 4108
  },
  "status": "success",
  "code": "",
  "message": "Get Notifications succeed"
}
```

**Result:** FAIL — response has no `0077/WO/SDA1/2026`

#### 47. PO rejects (reject round)

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/$PLAN/review" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "reject",
  "remarks": "Unit pompa tidak tersedia",
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ]
    }
  ]
}'
```

**Expected:** HTTP 200, `data.approval_status` = `reject_in_approval`

**Actual:** HTTP 200

```json
{
  "data": {
    "action_plan_id": "d3061b55-0aec-4eb1-8401-32f9249b5bcf",
    "source": "pep",
    "work_order_number": "0077/WO/SDA1/2026",
    "approval_status": "reject_in_approval",
    "cycle_no": 1,
    "path": "reject",
    "current_level": 1,
    "total_levels": 1
  },
  "status": "success",
  "code": "00",
  "message": "Review action plan succeed"
}
```

**Result:** PASS

#### 48. Manager agrees → rejected

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/$PLAN/approval/reject" \
  -H "Authorization: Bearer $MGR" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "Setuju"
}'
```

**Expected:** HTTP 200, `data.approval_status` = `rejected`

**Actual:** HTTP 200

```json
{
  "data": {
    "action_plan_id": "d3061b55-0aec-4eb1-8401-32f9249b5bcf",
    "source": "pep",
    "work_order_number": "0077/WO/SDA1/2026",
    "approval_status": "rejected",
    "cycle_no": 1,
    "path": "reject",
    "current_level": null,
    "total_levels": 1
  },
  "status": "success",
  "code": "00",
  "message": "Reject action plan succeed"
}
```

**Result:** PASS

#### 49. Detail shows rejected

```bash
curl -s -X GET "$API/well-surveilence/action-plans/pep/$PLAN" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, `data.approval_status` = `rejected`

**Actual:** HTTP 200

```json
{
  "data": {
    "id": "d3061b55-0aec-4eb1-8401-32f9249b5bcf",
    "action_plan_type": "artificial_lift",
    "status": "on_schedule",
    "start_date": "05-04-2027",
    "end_date": "07-04-2027",
    "notes": "SRP/ESP curl test",
    "ownership": "Pertamina EP",
    "pic": null,
    "pic_ids": [
      {
        "id": "BDBDF223-2FBA-461E-9D31-3AA956113AB0",
        "name": "PHI SDA 1",
        "email": "phi.sda1@yopmail.com"
      }
    ],
    "created_at": "19-11-2026 18:25:26",
    "created_by": {
      "id": "0B000000-0000-0000-0000-000000000407",
      "full_name": "PHI SDA 1"
    },
    "updated_at": "19-11-2026 18:25:32",
    "updated_by": {
      "id": "0B000000-0000-0000-0000-000000000409",
      "full_name": "PHI Super Admin"
    },
    "choke": null,
    "sonolog": null,
    "well_test": null,
    "artificial_lift": {
      "activity_type": "installation",
      "action_mode": "installation_update",
      "method": "sucker_rod_pump",
      "prime_mover": 0,
      "power": 40.0,
      "bean": 0,
      "thp": 0,
      "flowline_pressure": 0,
      "casing_pressure": 0,
      "separator_pressure": 0,
      "spmfreq": 8.5,
      "pump_size": 0,
      "pump_displacement": 0,
      "pump_efficiency": 0,
      "stroke_length": 86.0,
      "pump_intake_depth": 0,
      "submerging": 0,
      "production": 120.0,
      "pressure": 150.0,
      "ownership": "Pertamina EP",
      "whc_type": null,
      "compression_type": null,
      "owned_by": "rental",
      "contract_number": "CTR-PO/2026/021",
      "asset_number": null,
      "cost_allocation": null,
      "pump_type": "Insert Pump",
      "pump_brand": "Weatherford",
      "prime_mover_name": "Gas Engine G3306",
      "frequency": null,
      "electric_current": null
    },
    "others": null,
    "approval_status": "rejected",
    "requires_approval": true,
    "work_order_number": "0077/WO/SDA1/2026",
    "assigned_department": "Production Operations",
    "execution_department_id": null,
    "execution_pic": null,
    "can_review": false,
    "can_approve": false,
    "can_reject": false,
    "approval": {
      "cycle_no": 1,
      "path": "reject",
      "current_level": null,
      "total_levels": 1
    }
  },
  "status": "success",
  "code": "00",
  "message": "Get action plan PEP detail succeed"
}
```

**Result:** PASS

#### 50. SSDP gets the result notification

```bash
curl -s -X GET "$API/notifications/mine?page=1&page_size=10" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, a notification names `$WO`. Needs the `phantom_iac_action_plan_*` rows in `notification_templates` (seed_action_plan_approval.sql). Without them the API logs "Notification template ... not found" and stages nothing, so this step fails. This is the same for WHC; it is not an SRP/ESP defect.

**Actual:** HTTP 200

```json
{
  "data": {
    "list": [
      {
        "id": "d45063c3-b581-4b1f-87a3-3ee6f5ef1e2a",
        "title": "EUR Threshold Exceeded",
        "message": "<div style=\"width: 100%\"><span><span style=\"color: #e7000b\">QA56P22</span> <span style=\"color: #62748e\">exceeded 95% of EUR.</span></span></div>",
        "has_read": false,
        "created_at": "19-11-2026 18:02:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=da8a120a-6fc3-4fc5-a72b-530ac17c36f3",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=da8a120a-6fc3-4fc5-a72b-530ac17c36f3",
        "category": "Alert",
        "color_code": "danger"
      },
      {
        "id": "dd0b7bb8-62dd-4b57-9ff5-035ac96dfca6",
        "title": "EUR Threshold Exceeded",
        "message": "<div style=\"width: 100%\"><span><span style=\"color: #e7000b\">QSIWFA</span> <span style=\"color: #62748e\">exceeded 95% of EUR.</span></span></div>",
        "has_read": false,
        "created_at": "19-11-2026 18:02:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=7b1198d5-8bcd-4069-a0f0-96aec42fd994",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/pep?well_id=7b1198d5-8bcd-4069-a0f0-96aec42fd994",
        "category": "Alert",
        "color_code": "danger"
      },
      {
        "id": "403ae9bb-5830-46fb-a2e9-0a8d801511c0",
        "title": "EUR Threshold Exceeded",
        "message": "<div style=\"width: 100%\"><span><span style=\"color: #e7000b\">QA57P22</span> <span style=\"color: #62748e\">exceeded 95% of EUR.</span></span></div>",
        "has_read": false,
        "created_at": "19-11-2026 18:02:34",
        "created_at_label": "",
        "web_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=68925d0d-c448-4333-b0ca-de75c0f5aa83",
        "mobile_link": "https://phantom-web.inproms.com/ipms/well-surveillance/phss?well_id=68925d0d-c448-4333-b0ca-de75c0f5aa83",
        "category": "Alert",
        "color_code": "danger"
      },
      "... 7 more"
    ],
    "count": 206524
  },
  "status": "success",
  "code": "",
  "message": "Get Notifications succeed"
}
```

**Result:** FAIL — response has no `0077/WO/SDA1/2026`
