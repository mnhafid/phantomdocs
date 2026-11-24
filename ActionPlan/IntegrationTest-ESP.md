# Action Plan PEP ESP: integration test requests and responses (PHI-2496)

> Local only (`docs/` is not in git). Tokens are never written here: set them in the shell first.

Run 2026-11-19 18:24, local API (`http://localhost:5091/api/v1`) on the dev DB. Your own run can use `http://localhost:5071/api/v1`. Branch `feat/phi-2494-ap-srp-esp`.
**20 of 20 matched the expected result.**

One case for each rule of the `electric_submersible_pump` installation. Installation Schedule and Installation Update each get a valid submit and a detail read. The Validation section sends one broken field per case; a rejected submit stores nothing and uses no WO number.

Wells: schedule `434bf19b-8972-447e-a5fa-7ca96c509e52`, update `95de18f3-0b19-4312-b8a1-7094ecf209cc`.

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
| 2 | Submit ESP installation schedule | PASS |
| 3 | Detail of the installation schedule plan | PASS |
| 4 | Next WO number (SSDP) | PASS |
| 5 | Submit ESP installation update | PASS |
| 6 | Detail of the installation update plan | PASS |
| 7 | frequency missing | PASS |
| 8 | frequency = null | PASS |
| 9 | electric_current missing | PASS |
| 10 | frequency negative | PASS |
| 11 | electric_current negative | PASS |
| 12 | owned_by missing | PASS |
| 13 | owned_by = leased | PASS |
| 14 | production missing | PASS |
| 15 | pressure negative | PASS |
| 16 | activity_type adjustment | PASS |
| 17 | installation with action_mode adjustment_update | PASS |
| 18 | assigned_department missing | PASS |
| 19 | pic_ids empty | PASS |
| 20 | PHSS submit with electric_submersible_pump | PASS |

## Installation Schedule

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
    "sequence_number": "0078",
    "wo_number": "0078/WO/SDA1/2026"
  },
  "status": "success",
  "code": "00",
  "message": "Get next work order number succeed"
}
```

`WO=0078/WO/SDA1/2026`
**Result:** PASS

#### 2. Submit ESP installation schedule

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "434bf19b-8972-447e-a5fa-7ca96c509e52",
  "start_date": "2027-01-04",
  "end_date": "2027-01-06",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "electric_submersible_pump",
    "assigned_department": "Production Operations",
    "frequency": 0,
    "electric_current": 0,
    "owned_by": "owned",
    "asset_number": "AST-ESP-0007",
    "contract_number": "CTR-DROP",
    "stroke_length": 86,
    "pump_type": "should-drop",
    "production": 300,
    "pressure": 180
  },
  "wo_number": "'"$WO"'"
}'
```

**Expected:** HTTP 200, `data.approval_status` = `waiting_review`, `data.record_state` = `submitted`, `data.work_order_number` = `$WO`

**Actual:** HTTP 200

```json
{
  "data": {
    "id": "e25bf7cd-b681-4542-8212-f82036649349",
    "record_state": "submitted",
    "approval_status": "waiting_review",
    "work_order_number": "0078/WO/SDA1/2026"
  },
  "status": "success",
  "code": "00",
  "message": "Submit action plan PEP succeed"
}
```

`PLAN_S=e25bf7cd-b681-4542-8212-f82036649349`
**Result:** PASS

#### 3. Detail of the installation schedule plan

```bash
curl -s -X GET "$API/well-surveilence/action-plans/pep/$PLAN_S" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, `data.artificial_lift.method` = `electric_submersible_pump`, `data.artificial_lift.action_mode` = `installation_schedule`, `data.artificial_lift.owned_by` = `owned`, `data.artificial_lift.contract_number` = `None`, `data.artificial_lift.asset_number` = `AST-ESP-0007`, `data.artificial_lift.frequency` = `0`, `data.artificial_lift.electric_current` = `0`, `data.artificial_lift.pump_type` = `None`, `data.artificial_lift.stroke_length` = `0`

**Actual:** HTTP 200

```json
{
  "data": {
    "id": "e25bf7cd-b681-4542-8212-f82036649349",
    "action_plan_type": "artificial_lift",
    "status": "on_schedule",
    "start_date": "04-01-2027",
    "end_date": "06-01-2027",
    "notes": "SRP/ESP curl test",
    "ownership": "Pertamina EP",
    "pic": null,
    "pic_ids": [
      {
        "id": "5A8D273D-FB6D-4F60-9953-0BEB4BE8EAD3",
        "name": "PHI SDA 1",
        "email": "phi.sda1@yopmail.com"
      }
    ],
    "created_at": "19-11-2026 18:25:35",
    "created_by": {
      "id": "0B000000-0000-0000-0000-000000000407",
      "full_name": "PHI SDA 1"
    },
    "updated_at": "19-11-2026 18:25:35",
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
      "method": "electric_submersible_pump",
      "prime_mover": 0,
      "power": 0,
      "bean": 0,
      "thp": 0,
      "flowline_pressure": 0,
      "casing_pressure": 0,
      "separator_pressure": 0,
      "spmfreq": 0,
      "pump_size": 0,
      "pump_displacement": 0,
      "pump_efficiency": 0,
      "stroke_length": 0,
      "pump_intake_depth": 0,
      "submerging": 0,
      "production": 300.0,
      "pressure": 180.0,
      "ownership": "Pertamina EP",
      "whc_type": null,
      "compression_type": null,
      "owned_by": "owned",
      "contract_number": null,
      "asset_number": "AST-ESP-0007",
      "cost_allocation": null,
      "pump_type": null,
      "pump_brand": null,
      "prime_mover_name": null,
      "frequency": 0.0,
      "electric_current": 0.0
    },
    "others": null,
    "approval_status": "waiting_review",
    "requires_approval": true,
    "work_order_number": "0078/WO/SDA1/2026",
    "assigned_department": "Production Operations",
    "execution_department_id": null,
    "execution_pic": null,
    "can_review": false,
    "can_approve": false,
    "can_reject": false,
    "approval": {
      "cycle_no": null,
      "path": null,
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

## Installation Update

#### 4. Next WO number (SSDP)

```bash
curl -s -X GET "$API/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, `data.wo_number` = `NNNN/WO/{short}/{year}` → set `WO`

**Actual:** HTTP 200

```json
{
  "data": {
    "sequence_number": "0079",
    "wo_number": "0079/WO/SDA1/2026"
  },
  "status": "success",
  "code": "00",
  "message": "Get next work order number succeed"
}
```

`WO=0079/WO/SDA1/2026`
**Result:** PASS

#### 5. Submit ESP installation update

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "95de18f3-0b19-4312-b8a1-7094ecf209cc",
  "start_date": "2027-01-04",
  "end_date": "2027-01-06",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_update",
    "method": "electric_submersible_pump",
    "assigned_department": "Production Operations",
    "frequency": 50,
    "electric_current": 32.5,
    "owned_by": "rental",
    "asset_number": "AST-DROP",
    "contract_number": "CTR-ESP-2026-01",
    "stroke_length": 86,
    "pump_type": "should-drop",
    "production": 300,
    "pressure": 180
  },
  "wo_number": "'"$WO"'"
}'
```

**Expected:** HTTP 200, `data.approval_status` = `waiting_review`, `data.record_state` = `submitted`, `data.work_order_number` = `$WO`

**Actual:** HTTP 200

```json
{
  "data": {
    "id": "d962f8c1-8d39-4aa3-a818-5be48f8b66f1",
    "record_state": "submitted",
    "approval_status": "waiting_review",
    "work_order_number": "0079/WO/SDA1/2026"
  },
  "status": "success",
  "code": "00",
  "message": "Submit action plan PEP succeed"
}
```

`PLAN_U=d962f8c1-8d39-4aa3-a818-5be48f8b66f1`
**Result:** PASS

#### 6. Detail of the installation update plan

```bash
curl -s -X GET "$API/well-surveilence/action-plans/pep/$PLAN_U" \
  -H "Authorization: Bearer $SSDP"
```

**Expected:** HTTP 200, `data.artificial_lift.method` = `electric_submersible_pump`, `data.artificial_lift.action_mode` = `installation_update`, `data.artificial_lift.owned_by` = `rental`, `data.artificial_lift.contract_number` = `CTR-ESP-2026-01`, `data.artificial_lift.asset_number` = `None`, `data.artificial_lift.frequency` = `50`, `data.artificial_lift.electric_current` = `32.5`, `data.artificial_lift.pump_type` = `None`, `data.artificial_lift.stroke_length` = `0`

**Actual:** HTTP 200

```json
{
  "data": {
    "id": "d962f8c1-8d39-4aa3-a818-5be48f8b66f1",
    "action_plan_type": "artificial_lift",
    "status": "on_schedule",
    "start_date": "04-01-2027",
    "end_date": "06-01-2027",
    "notes": "SRP/ESP curl test",
    "ownership": "Pertamina EP",
    "pic": null,
    "pic_ids": [
      {
        "id": "3D2EE9EB-74A9-47A3-B847-D9DCAB1DE3DD",
        "name": "PHI SDA 1",
        "email": "phi.sda1@yopmail.com"
      }
    ],
    "created_at": "19-11-2026 18:25:38",
    "created_by": {
      "id": "0B000000-0000-0000-0000-000000000407",
      "full_name": "PHI SDA 1"
    },
    "updated_at": "19-11-2026 18:25:38",
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
      "method": "electric_submersible_pump",
      "prime_mover": 0,
      "power": 0,
      "bean": 0,
      "thp": 0,
      "flowline_pressure": 0,
      "casing_pressure": 0,
      "separator_pressure": 0,
      "spmfreq": 0,
      "pump_size": 0,
      "pump_displacement": 0,
      "pump_efficiency": 0,
      "stroke_length": 0,
      "pump_intake_depth": 0,
      "submerging": 0,
      "production": 300.0,
      "pressure": 180.0,
      "ownership": "Pertamina EP",
      "whc_type": null,
      "compression_type": null,
      "owned_by": "rental",
      "contract_number": "CTR-ESP-2026-01",
      "asset_number": null,
      "cost_allocation": null,
      "pump_type": null,
      "pump_brand": null,
      "prime_mover_name": null,
      "frequency": 50.0,
      "electric_current": 32.5
    },
    "others": null,
    "approval_status": "waiting_review",
    "requires_approval": true,
    "work_order_number": "0079/WO/SDA1/2026",
    "assigned_department": "Production Operations",
    "execution_department_id": null,
    "execution_pic": null,
    "can_review": false,
    "can_approve": false,
    "can_reject": false,
    "approval": {
      "cycle_no": null,
      "path": null,
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

## Validation (each case is a 400, nothing stored)

#### 7. frequency missing

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "434bf19b-8972-447e-a5fa-7ca96c509e52",
  "start_date": "2027-02-01",
  "end_date": "2027-02-03",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "electric_submersible_pump",
    "assigned_department": "Production Operations",
    "electric_current": 0,
    "owned_by": "owned",
    "asset_number": "AST-ESP-0007",
    "contract_number": "CTR-DROP",
    "stroke_length": 86,
    "pump_type": "should-drop",
    "production": 300,
    "pressure": 180
  }
}'
```

**Expected:** HTTP 400, `message` = `artificial_lift.frequency is required`

**Actual:** HTTP 400

```json
{
  "error_data": {
    "title": "Failed",
    "description": "artificial_lift.frequency is required",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "status": "failed",
  "code": "01",
  "message": "artificial_lift.frequency is required"
}
```

**Result:** PASS

#### 8. frequency = null

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "434bf19b-8972-447e-a5fa-7ca96c509e52",
  "start_date": "2027-02-01",
  "end_date": "2027-02-03",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "electric_submersible_pump",
    "assigned_department": "Production Operations",
    "frequency": null,
    "electric_current": 0,
    "owned_by": "owned",
    "asset_number": "AST-ESP-0007",
    "contract_number": "CTR-DROP",
    "stroke_length": 86,
    "pump_type": "should-drop",
    "production": 300,
    "pressure": 180
  }
}'
```

**Expected:** HTTP 400, `message` = `artificial_lift.frequency is required`

**Actual:** HTTP 400

```json
{
  "error_data": {
    "title": "Failed",
    "description": "artificial_lift.frequency is required",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "status": "failed",
  "code": "01",
  "message": "artificial_lift.frequency is required"
}
```

**Result:** PASS

#### 9. electric_current missing

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "434bf19b-8972-447e-a5fa-7ca96c509e52",
  "start_date": "2027-02-01",
  "end_date": "2027-02-03",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "electric_submersible_pump",
    "assigned_department": "Production Operations",
    "frequency": 0,
    "owned_by": "owned",
    "asset_number": "AST-ESP-0007",
    "contract_number": "CTR-DROP",
    "stroke_length": 86,
    "pump_type": "should-drop",
    "production": 300,
    "pressure": 180
  }
}'
```

**Expected:** HTTP 400, `message` = `artificial_lift.electric_current is required`

**Actual:** HTTP 400

```json
{
  "error_data": {
    "title": "Failed",
    "description": "artificial_lift.electric_current is required",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "status": "failed",
  "code": "01",
  "message": "artificial_lift.electric_current is required"
}
```

**Result:** PASS

#### 10. frequency negative

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "434bf19b-8972-447e-a5fa-7ca96c509e52",
  "start_date": "2027-02-01",
  "end_date": "2027-02-03",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "electric_submersible_pump",
    "assigned_department": "Production Operations",
    "frequency": -1,
    "electric_current": 0,
    "owned_by": "owned",
    "asset_number": "AST-ESP-0007",
    "contract_number": "CTR-DROP",
    "stroke_length": 86,
    "pump_type": "should-drop",
    "production": 300,
    "pressure": 180
  }
}'
```

**Expected:** HTTP 400, `message` = `artificial_lift.frequency must be 0 or more`

**Actual:** HTTP 400

```json
{
  "error_data": {
    "title": "Failed",
    "description": "artificial_lift.frequency must be 0 or more",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "status": "failed",
  "code": "01",
  "message": "artificial_lift.frequency must be 0 or more"
}
```

**Result:** PASS

#### 11. electric_current negative

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "434bf19b-8972-447e-a5fa-7ca96c509e52",
  "start_date": "2027-02-01",
  "end_date": "2027-02-03",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "electric_submersible_pump",
    "assigned_department": "Production Operations",
    "frequency": 0,
    "electric_current": -0.5,
    "owned_by": "owned",
    "asset_number": "AST-ESP-0007",
    "contract_number": "CTR-DROP",
    "stroke_length": 86,
    "pump_type": "should-drop",
    "production": 300,
    "pressure": 180
  }
}'
```

**Expected:** HTTP 400, `message` = `artificial_lift.electric_current must be 0 or more`

**Actual:** HTTP 400

```json
{
  "error_data": {
    "title": "Failed",
    "description": "artificial_lift.electric_current must be 0 or more",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "status": "failed",
  "code": "01",
  "message": "artificial_lift.electric_current must be 0 or more"
}
```

**Result:** PASS

#### 12. owned_by missing

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "434bf19b-8972-447e-a5fa-7ca96c509e52",
  "start_date": "2027-02-01",
  "end_date": "2027-02-03",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "electric_submersible_pump",
    "assigned_department": "Production Operations",
    "frequency": 0,
    "electric_current": 0,
    "asset_number": "AST-ESP-0007",
    "contract_number": "CTR-DROP",
    "stroke_length": 86,
    "pump_type": "should-drop",
    "production": 300,
    "pressure": 180
  }
}'
```

**Expected:** HTTP 400, `message` = `artificial_lift.owned_by must be rental or owned`

**Actual:** HTTP 400

```json
{
  "error_data": {
    "title": "Failed",
    "description": "artificial_lift.owned_by must be rental or owned",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "status": "failed",
  "code": "01",
  "message": "artificial_lift.owned_by must be rental or owned"
}
```

**Result:** PASS

#### 13. owned_by = leased

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "434bf19b-8972-447e-a5fa-7ca96c509e52",
  "start_date": "2027-02-01",
  "end_date": "2027-02-03",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "electric_submersible_pump",
    "assigned_department": "Production Operations",
    "frequency": 0,
    "electric_current": 0,
    "owned_by": "leased",
    "asset_number": "AST-ESP-0007",
    "contract_number": "CTR-DROP",
    "stroke_length": 86,
    "pump_type": "should-drop",
    "production": 300,
    "pressure": 180
  }
}'
```

**Expected:** HTTP 400, `message` = `artificial_lift.owned_by must be rental or owned`

**Actual:** HTTP 400

```json
{
  "error_data": {
    "title": "Failed",
    "description": "artificial_lift.owned_by must be rental or owned",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "status": "failed",
  "code": "01",
  "message": "artificial_lift.owned_by must be rental or owned"
}
```

**Result:** PASS

#### 14. production missing

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "434bf19b-8972-447e-a5fa-7ca96c509e52",
  "start_date": "2027-02-01",
  "end_date": "2027-02-03",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "electric_submersible_pump",
    "assigned_department": "Production Operations",
    "frequency": 0,
    "electric_current": 0,
    "owned_by": "owned",
    "asset_number": "AST-ESP-0007",
    "contract_number": "CTR-DROP",
    "stroke_length": 86,
    "pump_type": "should-drop",
    "pressure": 180
  }
}'
```

**Expected:** HTTP 400, `message` = `artificial_lift.production is required`

**Actual:** HTTP 400

```json
{
  "error_data": {
    "title": "Failed",
    "description": "artificial_lift.production is required",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "status": "failed",
  "code": "01",
  "message": "artificial_lift.production is required"
}
```

**Result:** PASS

#### 15. pressure negative

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "434bf19b-8972-447e-a5fa-7ca96c509e52",
  "start_date": "2027-02-01",
  "end_date": "2027-02-03",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "electric_submersible_pump",
    "assigned_department": "Production Operations",
    "frequency": 0,
    "electric_current": 0,
    "owned_by": "owned",
    "asset_number": "AST-ESP-0007",
    "contract_number": "CTR-DROP",
    "stroke_length": 86,
    "pump_type": "should-drop",
    "production": 300,
    "pressure": -1
  }
}'
```

**Expected:** HTTP 400, `message` = `artificial_lift.pressure must be 0 or more`

**Actual:** HTTP 400

```json
{
  "error_data": {
    "title": "Failed",
    "description": "artificial_lift.pressure must be 0 or more",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "status": "failed",
  "code": "01",
  "message": "artificial_lift.pressure must be 0 or more"
}
```

**Result:** PASS

#### 16. activity_type adjustment

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "434bf19b-8972-447e-a5fa-7ca96c509e52",
  "start_date": "2027-02-01",
  "end_date": "2027-02-03",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "adjustment",
    "action_mode": "adjustment_schedule",
    "method": "electric_submersible_pump",
    "assigned_department": "Production Operations",
    "frequency": 0,
    "electric_current": 0,
    "owned_by": "owned",
    "asset_number": "AST-ESP-0007",
    "contract_number": "CTR-DROP",
    "stroke_length": 86,
    "pump_type": "should-drop",
    "production": 300,
    "pressure": 180
  }
}'
```

**Expected:** HTTP 400, `message` = `artificial_lift.activity_type must be installation for method electric_submersible_pump`

**Actual:** HTTP 400

```json
{
  "error_data": {
    "title": "Failed",
    "description": "artificial_lift.activity_type must be installation for method electric_submersible_pump",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "status": "failed",
  "code": "01",
  "message": "artificial_lift.activity_type must be installation for method electric_submersible_pump"
}
```

**Result:** PASS

#### 17. installation with action_mode adjustment_update

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "434bf19b-8972-447e-a5fa-7ca96c509e52",
  "start_date": "2027-02-01",
  "end_date": "2027-02-03",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "adjustment_update",
    "method": "electric_submersible_pump",
    "assigned_department": "Production Operations",
    "frequency": 0,
    "electric_current": 0,
    "owned_by": "owned",
    "asset_number": "AST-ESP-0007",
    "contract_number": "CTR-DROP",
    "stroke_length": 86,
    "pump_type": "should-drop",
    "production": 300,
    "pressure": 180
  }
}'
```

**Expected:** HTTP 400, `message` = `artificial_lift.action_mode must be installation_schedule or installation_update`

**Actual:** HTTP 400

```json
{
  "error_data": {
    "title": "Failed",
    "description": "artificial_lift.action_mode must be installation_schedule or installation_update",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "status": "failed",
  "code": "01",
  "message": "artificial_lift.action_mode must be installation_schedule or installation_update"
}
```

**Result:** PASS

#### 18. assigned_department missing

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "434bf19b-8972-447e-a5fa-7ca96c509e52",
  "start_date": "2027-02-01",
  "end_date": "2027-02-03",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "electric_submersible_pump",
    "frequency": 0,
    "electric_current": 0,
    "owned_by": "owned",
    "asset_number": "AST-ESP-0007",
    "contract_number": "CTR-DROP",
    "stroke_length": 86,
    "pump_type": "should-drop",
    "production": 300,
    "pressure": 180
  }
}'
```

**Expected:** HTTP 400, `message` = `assigned_department (Assign to) is required for a plan that needs approval`

**Actual:** HTTP 400

```json
{
  "error_data": {
    "title": "Failed",
    "description": "assigned_department (Assign to) is required for a plan that needs approval",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "status": "failed",
  "code": "01",
  "message": "assigned_department (Assign to) is required for a plan that needs approval"
}
```

**Result:** PASS

#### 19. pic_ids empty

```bash
curl -s -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "434bf19b-8972-447e-a5fa-7ca96c509e52",
  "start_date": "2027-02-01",
  "end_date": "2027-02-03",
  "pic_ids": [],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "electric_submersible_pump",
    "assigned_department": "Production Operations",
    "frequency": 0,
    "electric_current": 0,
    "owned_by": "owned",
    "asset_number": "AST-ESP-0007",
    "contract_number": "CTR-DROP",
    "stroke_length": 86,
    "pump_type": "should-drop",
    "production": 300,
    "pressure": 180
  }
}'
```

**Expected:** HTTP 400, `message` = `pic_ids needs at least one PIC for method electric_submersible_pump`

**Actual:** HTTP 400

```json
{
  "error_data": {
    "title": "Failed",
    "description": "pic_ids needs at least one PIC for method electric_submersible_pump",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "status": "failed",
  "code": "01",
  "message": "pic_ids needs at least one PIC for method electric_submersible_pump"
}
```

**Result:** PASS

#### 20. PHSS submit with electric_submersible_pump

```bash
curl -s -X POST "$API/well-surveilence/action-plans/phss/submit" \
  -H "Authorization: Bearer $SSDP2" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "draft_id": null,
  "well_id": "434bf19b-8972-447e-a5fa-7ca96c509e52",
  "start_date": "2027-02-01",
  "end_date": "2027-02-03",
  "pic_ids": [
    "0b000000-0000-0000-0000-000000000407"
  ],
  "notes": "SRP/ESP curl test",
  "ownership": "Pertamina EP",
  "artificial_lift": {
    "activity_type": "installation",
    "action_mode": "installation_schedule",
    "method": "electric_submersible_pump",
    "assigned_department": "Production Operations",
    "frequency": 0,
    "electric_current": 0,
    "owned_by": "owned",
    "asset_number": "AST-ESP-0007",
    "contract_number": "CTR-DROP",
    "stroke_length": 86,
    "pump_type": "should-drop",
    "production": 300,
    "pressure": 180
  }
}'
```

**Expected:** HTTP 400, `message` = `artificial_lift.method electric_submersible_pump is only available for PEP`

**Actual:** HTTP 400

```json
{
  "error_data": {
    "title": "Failed",
    "description": "artificial_lift.method electric_submersible_pump is only available for PEP",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "status": "failed",
  "code": "01",
  "message": "artificial_lift.method electric_submersible_pump is only available for PEP"
}
```

**Result:** PASS
