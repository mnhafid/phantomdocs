# Action Plan Approval: integration test requests and responses

Run 2026-11-09 11:34, local API on the dev DB, scheduler off. Code: stack top `0a0aa09e` plus the staged WO counter and Retina permission changes. **57 of 58 matched the expected result.** Section 9 was run later for the new test user, from `4430bbda` plus the same staged changes: **13 of 13 matched**.

Cases 17 to 20 were re-run and case 72 added after the review #1432 fix that gives a WO number only to plans that need approval: **5 of 5 matched**, so case 20 now passes. Cases 18 and 19 now use a well test, because a choke no longer reads `wo_number`. Plans created: E2 `339275df-7ed2-46ba-b891-374de2a0e59b`, F2 `f35dca2d-072e-46b1-94e9-062eb05cc534`. No case is failing.

Long arrays in responses are cut to 3 items, and each cut is noted under its response. Tokens are never stored.

## Setup

```bash
API=http://localhost:5071/api/v1
SSDP=<access_token of phi.sda1 from mock_auth_sessions, stage=token>
PO=<access_token of phi.po from mock_auth_sessions, stage=token>
MGR2=<access_token of phi.superadmin from mock_auth_sessions, stage=token>
GM=<access_token of phi.generalmanager from mock_auth_sessions, stage=token>
NOPRIV=<access_token of phi.sda2 from mock_auth_sessions, stage=token>
APPROVER=<access_token of phi.approver from mock_auth_sessions, stage=token>
```

Plans created: A `a9d58d43-39b7-4c0b-8a91-330e08a84874`, B `2e9a1e64-8526-464d-891f-f3fa1a1484f4`, C `7ec4f1c8-ac77-4ac6-93d6-ddd5cf3b31ca`, D `6c182d7c-60ca-407d-856b-a45f7f844326`, E `7f7d1d08-3a61-49ea-819e-64a9a6c2a10c`, G `a9f52a84-8719-45ad-ae85-3e534085bb49`

### Test user `phi.approver`

One dev user that can read, modify, review, approve and reject Action Plans on PEP and PHSS.

| Field | Value |
|---|---|
| Username | `phi.approver` |
| User id | `0b000000-0000-0000-0000-00000000040a` |
| Department | Subsurface Development Area 1, so submit gets a WO number (`SDA1`) |
| Role | 1116, Subsurface Development Area 1 |
| Read | 153 Read PHSS Wells, 155 Read PEP Wells |
| Modify | 154 Modify PHSS Wells, 156 Modify PEP Wells |
| Approval | 161 Review, 162 Approve, 163 Reject |

It is not on any approval route. To approve a level, it must be named in that level's `approvers` when the plan is reviewed (case 66), or added to the route in Data Config.

Get the token (the password from `WebApi/appsettings.json` goes in `SQLCMDPASSWORD`):

```bash
APPROVER=$(sqlcmd -S 185.250.38.82 -U phantom_dev_user -d phantomdb -C -h -1 -W -y 0 \
  -Q "SET NOCOUNT ON; SELECT payload FROM mock_auth_sessions WHERE stage='token' AND username='phi.approver';" \
  | python3 -c "import sys,json;print(json.loads(sys.stdin.read().strip())['access_token'])")
```

## Summary

| # | Case | User | Call | Expected | Actual | Result |
|---|---|---|---|---|---|---|
| 1 | Next WO number (SDA1) | phi.sda1 | `GET …/next-wo-number` | 200 | 200 | PASS |
| 2 | Next WO number, department has no short name | phi.po | `GET …/next-wo-number` | 400 | 400 | PASS |
| 3 | Users by permission 70 (casbin) | phi.po | `GET /users/by-permission/70` | 200 | 200 | PASS |
| 4 | Users by permission 161 (Action Plan) | phi.po | `GET /users/by-permission/161` | 200 | 200 | PASS |
| 5 | Users by permission, unknown id | phi.po | `GET /users/by-permission/9999` | 500 | 500 | PASS |
| 6 | Current user permissions | phi.po | `GET /users/permissions` | 200 | 200 | PASS |
| 7 | Create route, unknown action plan category | phi.superadmin | `POST /approval-routes` | 400 | 400 | PASS |
| 8 | Create route, title already used | phi.superadmin | `POST /approval-routes` | 400/409 | 409 | PASS |
| 9 | Create route, PHSS Well Test | phi.superadmin | `POST /approval-routes` | 200 | 200 | PASS |
| 10 | List action plan routes | phi.po | `GET /approval-routes/all` | 200 | 200 | PASS |
| 11 | Submit well test without assigned_department | phi.sda1 | `POST …/pep/submit` | 400 | 400 | PASS |
| 12 | Submit well test (plan A) | phi.sda1 | `POST …/pep/submit` | 200 | 200 | PASS |
| 13 | Submit well test (plan C) | phi.sda1 | `POST …/pep/submit` | 200 | 200 | PASS |
| 14 | Submit artificial lift WHC installation (plan B) | phi.sda1 | `POST …/pep/submit` | 200 | 200 | PASS |
| 15 | Submit artificial lift WHC installation (plan D) | phi.sda1 | `POST …/pep/submit` | 200 | 200 | PASS |
| 16 | Next WO number | phi.sda1 | `GET …/next-wo-number` | 200 | 200 | PASS |
| 17 | Submit choke, auto-approved, no WO number (plan E2) | phi.sda1 | `POST …/pep/submit` | 200 | 200 | PASS |
| 18 | Submit with a WO number already used | phi.sda1 | `POST …/pep/submit` | 400 | 400 | PASS |
| 19 | Submit with a badly formatted WO number | phi.sda1 | `POST …/pep/submit` | 400 | 400 | PASS |
| 20 | Submit choke by a user outside the WO short-name config (plan F2) | phi.po | `POST …/pep/submit` | 200 | 200 | PASS |
| 21 | Plan detail | phi.sda1 | `GET …/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874` | 200 | 200 | PASS |
| 22 | Plan list | phi.sda1 | `GET /well-surveilence/e8175ae8-0cd3-4a16-b1de-c8d8f77fa1f4/action-plans/pep` | 200 | 200 | PASS |
| 23 | Approval route prefill | phi.po | `GET …/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/approval-route` | 200 | 200 | PASS |
| 24 | Need action, stage=review | phi.po | `GET …/approvals/need-action` | 200 | 200 | PASS |
| 25 | Need action, stage=review, user without 161 | phi.sda2 | `GET …/approvals/need-action` | 403 | 403 | PASS |
| 26 | My task list | phi.po | `GET /my-task-list` | 200 | 200 | PASS |
| 27 | My approval list | phi.po | `GET /my-approval-list` | 200 | 200 | PASS |
| 28 | My task badge | phi.po | `GET /my-task-badge` | 200 | 200 | PASS |
| 29 | Review without 161 | phi.sda2 | `POST …/pep/2e9a1e64-8526-464d-891f-f3fa1a1484f4/review` | 403 | 403 | PASS |
| 30 | Review approve (plan B) | phi.po | `POST …/pep/2e9a1e64-8526-464d-891f-f3fa1a1484f4/review` | 200 | 200 | PASS |
| 31 | Review a plan that is already approved | phi.po | `POST …/pep/2e9a1e64-8526-464d-891f-f3fa1a1484f4/review` | 400 | 400 | PASS |
| 32 | Review modify changing method (plan D) | phi.po | `POST …/pep/6c182d7c-60ca-407d-856b-a45f7f844326/review` | 400 | 400 | PASS |
| 33 | Review modify (plan D) | phi.po | `POST …/pep/6c182d7c-60ca-407d-856b-a45f7f844326/review` | 200 | 200 | PASS |
| 34 | Review modify (plan A, new end date) | phi.po | `POST …/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/review` | 200 | 200 | PASS |
| 35 | Review reject without remarks (plan C) | phi.po | `POST …/pep/7ec4f1c8-ac77-4ac6-93d6-ddd5cf3b31ca/review` | 400 | 400 | PASS |
| 36 | Review reject (plan C) | phi.po | `POST …/pep/7ec4f1c8-ac77-4ac6-93d6-ddd5cf3b31ca/review` | 200 | 200 | PASS |
| 37 | Need action, stage=approval | phi.po | `GET …/approvals/need-action` | 200 | 200 | PASS |
| 38 | Approve by a user not on the pending level | phi.generalmanager | `POST …/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/approval/approve` | 403 | 403 | PASS |
| 39 | Approve without 162 | phi.sda2 | `POST …/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/approval/approve` | 403 | 403 | PASS |
| 40 | Modify: approve L1 (plan A) | phi.po | `POST …/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/approval/approve` | 200 | 200 | PASS |
| 41 | Approve L1 again by the same user | phi.po | `POST …/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/approval/approve` | 400/403 | 403 | PASS |
| 42 | Modify: approve L2 (plan A) | phi.superadmin | `POST …/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/approval/approve` | 200 | 200 | PASS |
| 43 | Modify: approve L3, proposal applied (plan A) | phi.sda1 | `POST …/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/approval/approve` | 200 | 200 | PASS |
| 44 | Detail after Modify: end_date changed (plan A) | phi.sda1 | `GET …/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874` | 200 | 200 | PASS |
| 45 | Modification diff (plan A) | phi.po | `GET …/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/modification-diff` | 200 | 200 | PASS |
| 46 | Approval history (plan A) | phi.po | `GET …/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/approval-history` | 200 | 200 | PASS |
| 47 | Reject: approve L1 (plan C) | phi.po | `POST …/pep/7ec4f1c8-ac77-4ac6-93d6-ddd5cf3b31ca/approval/approve` | 200 | 200 | PASS |
| 48 | Reject: approve L2, plan rejected (plan C) | phi.superadmin | `POST …/pep/7ec4f1c8-ac77-4ac6-93d6-ddd5cf3b31ca/approval/approve` | 200 | 200 | PASS |
| 49 | Level reject, back to PO (plan D) | phi.po | `POST …/pep/6c182d7c-60ca-407d-856b-a45f7f844326/approval/reject` | 200 | 200 | PASS |
| 50 | Review approve while modify_returned (plan D) | phi.po | `POST …/pep/6c182d7c-60ca-407d-856b-a45f7f844326/review` | 400 | 400 | PASS |
| 51 | Approval history (plan D) | phi.po | `GET …/pep/6c182d7c-60ca-407d-856b-a45f7f844326/approval-history` | 200 | 200 | PASS |
| 52 | Unknown plan | phi.po | `GET …/pep/00000000-0000-0000-0000-000000000001/approval-history` | 404 | 404 | PASS |
| 53 | Submit well test (PHSS plan G) | phi.sda2 | `POST …/phss/submit` | 200 | 200 | PASS |
| 54 | PHSS detail | phi.sda2 | `GET …/phss/a9f52a84-8719-45ad-ae85-3e534085bb49` | 200 | 200 | PASS |
| 55 | PHSS approval route prefill | phi.po | `GET …/phss/a9f52a84-8719-45ad-ae85-3e534085bb49/approval-route` | 200 | 200 | PASS |
| 56 | PHSS review approve | phi.po | `POST …/phss/a9f52a84-8719-45ad-ae85-3e534085bb49/review` | 200 | 200 | PASS |
| 57 | PHSS approval history | phi.po | `GET …/phss/a9f52a84-8719-45ad-ae85-3e534085bb49/approval-history` | 200 | 200 | PASS |
| 58 | Parallel submit: 5 PEP + 5 PHSS, same department (SDA1) | phi.sda1 | `POST …/{pep|phss}/submit` | 200 | 200 | PASS |
| 59 | Current user permissions | phi.approver | `GET /users/permissions` | 200 | 200 | PASS |
| 60 | Modify: submit PEP well test (plan H) | phi.approver | `POST …/pep/submit` | 200 | 200 | PASS |
| 61 | Modify: submit PHSS well test (plan I) | phi.approver | `POST …/phss/submit` | 200 | 200 | PASS |
| 62 | Read: PEP plan list | phi.approver | `GET /well-surveilence/cb09c057-dd3f-4bef-a9a3-8a91190ea8e1/action-plans/pep` | 200 | 200 | PASS |
| 63 | Read: PEP plan detail, can review (plan H) | phi.approver | `GET …/pep/944010e4-abaa-4850-9923-9dde72f2ba8c` | 200 | 200 | PASS |
| 64 | Read: PHSS plan detail, can review (plan I) | phi.approver | `GET …/phss/da6ff3a6-61c0-4c9e-bd96-2a7660bf56e7` | 200 | 200 | PASS |
| 65 | Need action, stage=review | phi.approver | `GET …/approvals/need-action` | 200 | 200 | PASS |
| 66 | Review modify, phi.approver on level 1 (plan H) | phi.approver | `POST …/pep/944010e4-abaa-4850-9923-9dde72f2ba8c/review` | 200 | 200 | PASS |
| 67 | Read: detail, can approve level 1 (plan H) | phi.approver | `GET …/pep/944010e4-abaa-4850-9923-9dde72f2ba8c` | 200 | 200 | PASS |
| 68 | Approve level 1 (plan H) | phi.approver | `POST …/pep/944010e4-abaa-4850-9923-9dde72f2ba8c/approval/approve` | 200 | 200 | PASS |
| 69 | Approve level 2, proposal applied (plan H) | phi.superadmin | `POST …/pep/944010e4-abaa-4850-9923-9dde72f2ba8c/approval/approve` | 200 | 200 | PASS |
| 70 | Detail after approval: end_date changed (plan H) | phi.approver | `GET …/pep/944010e4-abaa-4850-9923-9dde72f2ba8c` | 200 | 200 | PASS |
| 71 | Review approve (plan I) | phi.approver | `POST …/phss/da6ff3a6-61c0-4c9e-bd96-2a7660bf56e7/review` | 200 | 200 | PASS |
| 72 | Submit well test by a user outside the WO short-name config | phi.po | `POST …/pep/submit` | 400 | 400 | PASS |

## 1. Lookups

### 1. Next WO number (SDA1)

User `phi.sda1`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer $SSDP"
```

Response 200:

```json
{
  "data": {
    "sequence_number": "0014",
    "wo_number": "0014/WO/SDA1/2026"
  },
  "process_time": "463.99ms",
  "status": "success",
  "code": "00",
  "message": "Get next work order number succeed"
}
```

### 2. Next WO number, department has no short name

User `phi.po`. Expected 400, actual 400: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer $PO"
```

Response 400:

```json
{
  "error_data": {
    "title": "Failed",
    "description": "Department 'Production Operations' has no work order short name in work_order_department_short_names",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "process_time": "277.77ms",
  "status": "failed",
  "code": "01",
  "message": "Department 'Production Operations' has no work order short name in work_order_department_short_names"
}
```

### 3. Users by permission 70 (casbin)

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/users/by-permission/70" \
  -H "Authorization: Bearer $PO"
```

Response 200:

```json
{
  "data": [
    {
      "id": "0b000000-0000-0000-0000-000000000313",
      "full_name": "R3 Test PO",
      "email": "r3test.po@yopmail.com",
      "status": "active",
      "zone": null,
      "working_area": null,
      "department": "Production Operations",
      "role": {
        "id": 1102,
        "name": "Production Operations"
      }
    },
    {
      "id": "0b000000-0000-0000-0000-000000000321",
      "full_name": "R3 Test SM SSDP",
      "email": "r3test.sm.ssdp@yopmail.com",
      "status": "active",
      "zone": null,
      "working_area": null,
      "department": "Production Operations",
      "role": {
        "id": 1105,
        "name": "regulator of production operations"
      }
    },
    {
      "id": "0b000000-0000-0000-0000-000000000322",
      "full_name": "R3 Test SM PnP",
      "email": "r3test.sm.pnp@yopmail.com",
      "status": "active",
      "zone": null,
      "working_area": null,
      "department": "Subsurface Development Area 2",
      "role": {
        "id": 1103,
        "name": "Project"
      }
    }
  ],
  "process_time": "797.17ms",
  "status": "success",
  "code": "",
  "message": "Get users by permission succeed"
}
```

_Arrays cut to 3 items; original sizes: 31._

### 4. Users by permission 161 (Action Plan)

User `phi.po`. Expected 200, actual 200: **PASS**

Reads Retina Global Query 135. Dev uses the mock Retina, which has no 135 rows for this permission, so the list is empty.

```bash
curl -X GET "$API/users/by-permission/161" \
  -H "Authorization: Bearer $PO"
```

Response 200:

```json
{
  "data": [],
  "process_time": "610.43ms",
  "status": "success",
  "code": "",
  "message": "Get users by permission succeed"
}
```

### 5. Users by permission, unknown id

User `phi.po`. Expected 500, actual 500: **PASS**

```bash
curl -X GET "$API/users/by-permission/9999" \
  -H "Authorization: Bearer $PO"
```

Response 500:

```json
{
  "error_data": {
    "title": "Failed",
    "description": "Permission not found",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "process_time": "72.31ms",
  "status": "failed",
  "code": "",
  "message": "Permission not found"
}
```

### 6. Current user permissions

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/users/permissions" \
  -H "Authorization: Bearer $PO"
```

Response 200:

```json
{
  "data": {
    "128": [
      "17"
    ],
    "137": [
      "19"
    ],
    "153": [
      "19"
    ],
    "155": [
      "19"
    ],
    "138": [
      "20"
    ],
    "140": [
      "20"
    ],
    "159": [
      "28"
    ],
    "161": [
      "30"
    ],
    "162": [
      "30"
    ],
    "163": [
      "30"
    ]
  },
  "process_time": "392.64ms",
  "status": "success",
  "code": "",
  "message": "Get user permissions succeed"
}
```

## 2. Approval route

### 7. Create route, unknown action plan category

User `phi.superadmin`. Expected 400, actual 400: **PASS**

```bash
curl -X POST "$API/approval-routes" \
  -H "Authorization: Bearer $MGR2" \
  -H 'Content-Type: application/json' \
  -d '{
  "title": "IT invalid",
  "description": "PO Mgr 1 > Mgr 2 > SSDP 1",
  "category": "action_plan_pep_well_test_modify",
  "approvers": [
    {
      "level": 1,
      "sla_days": 2,
      "users": [
        {
          "id": "0b000000-0000-0000-0000-000000000406"
        }
      ]
    },
    {
      "level": 2,
      "sla_days": 3,
      "users": [
        {
          "id": "0b000000-0000-0000-0000-000000000409"
        }
      ]
    },
    {
      "level": 3,
      "sla_days": 2,
      "users": [
        {
          "id": "0b000000-0000-0000-0000-000000000407"
        }
      ]
    }
  ]
}'
```

Response 400:

```json
{
  "process_time": "10.55ms",
  "status": "failed",
  "code": "",
  "message": "Category: an action plan route must be one of action_plan_pep_well_test, action_plan_pep_artificial_lift, action_plan_phss_well_test, action_plan_phss_artificial_lift."
}
```

### 8. Create route, title already used

User `phi.superadmin`. Expected 400/409, actual 409: **PASS**

```bash
curl -X POST "$API/approval-routes" \
  -H "Authorization: Bearer $MGR2" \
  -H 'Content-Type: application/json' \
  -d '{
  "title": "Action Plan Well Test - PEP",
  "description": "PO Mgr 1 > Mgr 2 > SSDP 1",
  "category": "action_plan_pep_well_test",
  "approvers": [
    {
      "level": 1,
      "sla_days": 2,
      "users": [
        {
          "id": "0b000000-0000-0000-0000-000000000406"
        }
      ]
    },
    {
      "level": 2,
      "sla_days": 3,
      "users": [
        {
          "id": "0b000000-0000-0000-0000-000000000409"
        }
      ]
    },
    {
      "level": 3,
      "sla_days": 2,
      "users": [
        {
          "id": "0b000000-0000-0000-0000-000000000407"
        }
      ]
    }
  ]
}'
```

Response 409:

```json
{
  "error_data": {
    "title": "Failed",
    "description": "Title \"Action Plan Well Test - PEP\" already used by another approval route",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "process_time": "96.69ms",
  "status": "failed",
  "code": "",
  "message": "Title \"Action Plan Well Test - PEP\" already used by another approval route"
}
```

### 9. Create route, PHSS Well Test

User `phi.superadmin`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/approval-routes" \
  -H "Authorization: Bearer $MGR2" \
  -H 'Content-Type: application/json' \
  -d '{
  "title": "Action Plan Well Test - PHSS",
  "description": "PO Mgr 1 > Mgr 2 > SSDP 1",
  "category": "action_plan_phss_well_test",
  "approvers": [
    {
      "level": 1,
      "sla_days": 2,
      "users": [
        {
          "id": "0b000000-0000-0000-0000-000000000406"
        }
      ]
    },
    {
      "level": 2,
      "sla_days": 3,
      "users": [
        {
          "id": "0b000000-0000-0000-0000-000000000409"
        }
      ]
    },
    {
      "level": 3,
      "sla_days": 2,
      "users": [
        {
          "id": "0b000000-0000-0000-0000-000000000407"
        }
      ]
    }
  ]
}'
```

Response 200:

```json
{
  "process_time": "1006.13ms",
  "status": "success",
  "code": "00",
  "message": "Create approval route succeed"
}
```

### 10. List action plan routes

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/approval-routes/all?status=active&category=action_plan_pep_well_test|action_plan_pep_artificial_lift|action_plan_phss_artificial_lift" \
  -H "Authorization: Bearer $PO"
```

Response 200:

```json
{
  "data": [
    {
      "id": "351af63b-b175-425e-8235-be752cdeb419",
      "status": "active",
      "title": "Action Plan Artificial Lift - PEP",
      "description": "PO Mgr 1 > Mgr 2 > SSDP 1",
      "category": "action_plan_pep_artificial_lift",
      "department_id": "Project",
      "tenant_id": "00000000-0000-0000-0000-000000000000",
      "created_at": "09-11-2026 11:10:29",
      "created_by": {
        "id": "0b000000-0000-0000-0000-000000000409",
        "full_name": "PHI Super Admin",
        "status": "active",
        "email": "phi.superadmin@yopmail.com"
      },
      "updated_at": "09-11-2026 11:10:29",
      "updated_by": {
        "id": "0b000000-0000-0000-0000-000000000409",
        "full_name": "PHI Super Admin",
        "status": "active",
        "email": "phi.superadmin@yopmail.com"
      },
      "users": [
        {
          "level": 1,
          "sla_days": 2,
          "users": [
            {
              "id": "0b000000-0000-0000-0000-000000000406",
              "full_name": "PHI PO",
              "status": "active",
              "email": "phi.po@yopmail.com",
              "role": "Production Operations"
            }
          ]
        },
        {
          "level": 2,
          "sla_days": 3,
          "users": [
            {
              "id": "0b000000-0000-0000-0000-000000000409",
              "full_name": "PHI Super Admin",
              "status": "active",
              "email": "phi.superadmin@yopmail.com",
              "role": "regulator of project"
            }
          ]
        },
        {
          "level": 3,
          "sla_days": 2,
          "users": [
            {
              "id": "0b000000-0000-0000-0000-000000000407",
              "full_name": "PHI SDA 1",
              "status": "active",
              "email": "phi.sda1@yopmail.com",
              "role": "Subsurface Development Area 1"
            }
          ]
        }
      ],
      "spk_value_threshold": null,
      "levels": null
    },
    {
      "id": "7d0bd363-37c4-42ba-9e7a-39feb02244a1",
      "status": "active",
      "title": "Action Plan Artificial Lift - PHSS",
      "description": "PO Mgr 1 > Mgr 2 > SSDP 2",
      "category": "action_plan_phss_artificial_lift",
      "department_id": "Project",
      "tenant_id": "00000000-0000-0000-0000-000000000000",
      "created_at": "06-11-2026 15:22:45",
      "created_by": {
        "id": "0b000000-0000-0000-0000-000000000409",
        "full_name": "PHI Super Admin",
        "status": "active",
        "email": "phi.superadmin@yopmail.com"
      },
      "updated_at": "06-11-2026 15:22:45",
      "updated_by": {
        "id": "0b000000-0000-0000-0000-000000000409",
        "full_name": "PHI Super Admin",
        "status": "active",
        "email": "phi.superadmin@yopmail.com"
      },
      "users": [
        {
          "level": 1,
          "sla_days": null,
          "users": [
            {
              "id": "0b000000-0000-0000-0000-000000000406",
              "full_name": "PHI PO",
              "status": "active",
              "email": "phi.po@yopmail.com",
              "role": "Production Operations"
            }
          ]
        },
        {
          "level": 2,
          "sla_days": null,
          "users": [
            {
              "id": "0b000000-0000-0000-0000-000000000409",
              "full_name": "PHI Super Admin",
              "status": "active",
              "email": "phi.superadmin@yopmail.com",
              "role": "regulator of project"
            }
          ]
        }
      ],
      "spk_value_threshold": null,
      "levels": null
    },
    {
      "id": "cbb996ac-7377-4a4c-8ff1-80c7f68d077c",
      "status": "active",
      "title": "Action Plan Well Test - PEP",
      "description": "PO Mgr 1 > Mgr 2 > SSDP 1",
      "category": "action_plan_pep_well_test",
      "department_id": "Project",
      "tenant_id": "00000000-0000-0000-0000-000000000000",
      "created_at": "06-11-2026 15:22:43",
      "created_by": {
        "id": "0b000000-0000-0000-0000-000000000409",
        "full_name": "PHI Super Admin",
        "status": "active",
        "email": "phi.superadmin@yopmail.com"
      },
      "updated_at": "06-11-2026 15:22:43",
      "updated_by": {
        "id": "0b000000-0000-0000-0000-000000000409",
        "full_name": "PHI Super Admin",
        "status": "active",
        "email": "phi.superadmin@yopmail.com"
      },
      "users": [
        {
          "level": 1,
          "sla_days": 2,
          "users": [
            {
              "id": "0b000000-0000-0000-0000-000000000406",
              "full_name": "PHI PO",
              "status": "active",
              "email": "phi.po@yopmail.com",
              "role": "Production Operations"
            }
          ]
        },
        {
          "level": 2,
          "sla_days": 2,
          "users": [
            {
              "id": "0b000000-0000-0000-0000-000000000409",
              "full_name": "PHI Super Admin",
              "status": "active",
              "email": "phi.superadmin@yopmail.com",
              "role": "regulator of project"
            }
          ]
        },
        {
          "level": 3,
          "sla_days": null,
          "users": [
            {
              "id": "0b000000-0000-0000-0000-000000000407",
              "full_name": "PHI SDA 1",
              "status": "active",
              "email": "phi.sda1@yopmail.com",
              "role": "Subsurface Development Area 1"
            }
          ]
        }
      ],
      "spk_value_threshold": null,
      "levels": null
    }
  ],
  "process_time": "459.59ms",
  "status": "success",
  "code": "00",
  "message": "Get all approval routes succeed"
}
```

## 3. Submit

### 11. Submit well test without assigned_department

User `phi.sda1`. Expected 400, actual 400: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "well_test",
  "well_id": "e8175ae8-0cd3-4a16-b1de-c8d8f77fa1f4",
  "start_date": "19-11-2026",
  "end_date": "21-11-2026",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "well_test": {
    "well_test_action": "schedule",
    "well_test_type": "production_test",
    "contract_number": "CTR-PO/2026/001"
  }
}'
```

Response 400:

```json
{
  "process_time": "670.67ms",
  "status": "failed",
  "code": "01",
  "message": "assigned_department (Assign to) is required for a plan that needs approval"
}
```

### 12. Submit well test (plan A)

User `phi.sda1`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "well_test",
  "well_id": "e8175ae8-0cd3-4a16-b1de-c8d8f77fa1f4",
  "start_date": "19-11-2026",
  "end_date": "21-11-2026",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "well_test": {
    "well_test_action": "schedule",
    "well_test_type": "production_test",
    "assigned_department": "Production Operations",
    "contract_number": "CTR-PO/2026/001"
  }
}'
```

Response 200:

```json
{
  "data": {
    "id": "a9d58d43-39b7-4c0b-8a91-330e08a84874",
    "record_state": "submitted",
    "approval_status": "waiting_review",
    "work_order_number": "0014/WO/SDA1/2026"
  },
  "process_time": "1597.06ms",
  "status": "success",
  "code": "00",
  "message": "Submit action plan PEP succeed"
}
```

### 13. Submit well test (plan C)

User `phi.sda1`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "well_test",
  "well_id": "69556699-730b-44b5-82ee-575db818ec14",
  "start_date": "19-11-2026",
  "end_date": "21-11-2026",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "well_test": {
    "well_test_action": "schedule",
    "well_test_type": "production_test",
    "assigned_department": "Production Operations",
    "contract_number": "CTR-PO/2026/001"
  }
}'
```

Response 200:

```json
{
  "data": {
    "id": "7ec4f1c8-ac77-4ac6-93d6-ddd5cf3b31ca",
    "record_state": "submitted",
    "approval_status": "waiting_review",
    "work_order_number": "0015/WO/SDA1/2026"
  },
  "process_time": "1329.72ms",
  "status": "success",
  "code": "00",
  "message": "Submit action plan PEP succeed"
}
```

### 14. Submit artificial lift WHC installation (plan B)

User `phi.sda1`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "well_id": "71b6a7c1-a2d8-401e-9357-6334d4206304",
  "start_date": "19-11-2026",
  "end_date": "21-11-2026",
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
}'
```

Response 200:

```json
{
  "data": {
    "id": "2e9a1e64-8526-464d-891f-f3fa1a1484f4",
    "record_state": "submitted",
    "approval_status": "waiting_review",
    "work_order_number": "0016/WO/SDA1/2026"
  },
  "process_time": "1995.61ms",
  "status": "success",
  "code": "00",
  "message": "Submit action plan PEP succeed"
}
```

### 15. Submit artificial lift WHC installation (plan D)

User `phi.sda1`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "artificial_lift",
  "well_id": "f1000000-0000-4000-8000-000000000002",
  "start_date": "19-11-2026",
  "end_date": "21-11-2026",
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
}'
```

Response 200:

```json
{
  "data": {
    "id": "6c182d7c-60ca-407d-856b-a45f7f844326",
    "record_state": "submitted",
    "approval_status": "waiting_review",
    "work_order_number": "0017/WO/SDA1/2026"
  },
  "process_time": "1209.98ms",
  "status": "success",
  "code": "00",
  "message": "Submit action plan PEP succeed"
}
```

### 16. Next WO number

User `phi.sda1`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/next-wo-number" \
  -H "Authorization: Bearer $SSDP"
```

Response 200:

```json
{
  "data": {
    "sequence_number": "0018",
    "wo_number": "0018/WO/SDA1/2026"
  },
  "process_time": "362.35ms",
  "status": "success",
  "code": "00",
  "message": "Get next work order number succeed"
}
```

### 17. Submit choke, auto-approved, no WO number (plan E2)

User `phi.sda1`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "choke",
  "well_id": "065b271a-5ea4-434b-a895-5b18924409cc",
  "start_date": "19-11-2026",
  "end_date": "21-11-2026",
  "choke": {
    "gas": 10,
    "oil": 20
  }
}'
```

Response 200:

```json
{
  "data": {
    "id": "339275df-7ed2-46ba-b891-374de2a0e59b",
    "record_state": "submitted",
    "approval_status": "approved",
    "work_order_number": null
  },
  "process_time": "1793.63ms",
  "status": "success",
  "code": "00",
  "message": "Submit action plan PEP succeed"
}
```

### 18. Submit with a WO number already used

User `phi.sda1`. Expected 400, actual 400: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "well_test",
  "well_id": "881e6392-ecd8-4d5a-b745-569051b2b8fa",
  "start_date": "19-11-2026",
  "end_date": "21-11-2026",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "well_test": {
    "well_test_action": "schedule",
    "well_test_type": "production_test",
    "assigned_department": "Production Operations",
    "contract_number": "CTR-PO/2026/001"
  },
  "wo_number": "0030/WO/SDA1/2026"
}'
```

Response 400:

```json
{
  "process_time": "1509.98ms",
  "status": "failed",
  "code": "01",
  "message": "wo_number 0030/WO/SDA1/2026 is already used, please get the next work order number again"
}
```

### 19. Submit with a badly formatted WO number

User `phi.sda1`. Expected 400, actual 400: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "well_test",
  "well_id": "881e6392-ecd8-4d5a-b745-569051b2b8fa",
  "start_date": "19-11-2026",
  "end_date": "21-11-2026",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "well_test": {
    "well_test_action": "schedule",
    "well_test_type": "production_test",
    "assigned_department": "Production Operations",
    "contract_number": "CTR-PO/2026/001"
  },
  "wo_number": "ABC-123"
}'
```

Response 400:

```json
{
  "process_time": "947.60ms",
  "status": "failed",
  "code": "01",
  "message": "wo_number must be NNNN/WO/SDA1/2026"
}
```

### 20. Submit choke by a user outside the WO short-name config (plan F2)

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "choke",
  "well_id": "881e6392-ecd8-4d5a-b745-569051b2b8fa",
  "start_date": "19-11-2026",
  "end_date": "21-11-2026",
  "choke": {
    "gas": 10,
    "oil": 20
  }
}'
```

Response 200:

```json
{
  "data": {
    "id": "f35dca2d-072e-46b1-94e9-062eb05cc534",
    "record_state": "submitted",
    "approval_status": "approved",
    "work_order_number": null
  },
  "process_time": "1104.12ms",
  "status": "success",
  "code": "00",
  "message": "Submit action plan PEP succeed"
}
```

## 4. Read

### 21. Plan detail

User `phi.sda1`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874" \
  -H "Authorization: Bearer $SSDP"
```

Response 200:

```json
{
  "data": {
    "id": "a9d58d43-39b7-4c0b-8a91-330e08a84874",
    "action_plan_type": "well_test",
    "status": "upcoming",
    "start_date": "19-11-2026",
    "end_date": "21-11-2026",
    "notes": "",
    "ownership": null,
    "pic": null,
    "pic_ids": [
      {
        "id": "58D0062C-ABDE-4924-AB59-B0F47E76A775",
        "name": "R3 Test amin",
        "email": "r3test.amin@yopmail.com"
      }
    ],
    "created_at": "09-11-2026 11:32:35",
    "created_by": {
      "id": "0B000000-0000-0000-0000-000000000407",
      "full_name": "PHI SDA 1"
    },
    "updated_at": "09-11-2026 11:32:35",
    "updated_by": {
      "id": "0B000000-0000-0000-0000-000000000407",
      "full_name": "PHI SDA 1"
    },
    "choke": null,
    "sonolog": null,
    "well_test": {
      "gas": 0,
      "oil": 0,
      "well_test_action": "schedule",
      "contract_id": "",
      "contract_number": "CTR-PO/2026/001",
      "contract_no": "",
      "contract_title": "",
      "contractor": null,
      "well_test_type": {
        "id": "production_test",
        "name": "Regular Well Test"
      },
      "planned_duration_hours": 0,
      "actual_planned_hours": 0,
      "tank_number": "",
      "start_date_time": "",
      "end_date_time": "",
      "u_press": 0,
      "chp": 0,
      "choke": 0,
      "whfp": 0,
      "flp": 0,
      "gi": 0,
      "liquid": 0,
      "water": 0,
      "bsw": 0,
      "sand": 0
    },
    "artificial_lift": null,
    "others": null,
    "approval_status": "waiting_review",
    "requires_approval": true,
    "work_order_number": "0014/WO/SDA1/2026",
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
  "process_time": "1089.61ms",
  "status": "success",
  "code": "00",
  "message": "Get action plan PEP detail succeed"
}
```

### 22. Plan list

User `phi.sda1`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/e8175ae8-0cd3-4a16-b1de-c8d8f77fa1f4/action-plans/pep?view=ongoing&page=1&page_size=10" \
  -H "Authorization: Bearer $SSDP"
```

Response 200:

```json
{
  "data": {
    "list": [
      {
        "id": "a9d58d43-39b7-4c0b-8a91-330e08a84874",
        "action_plan_type": "well_test",
        "well_test_action": "schedule",
        "action_mode": null,
        "status": "upcoming",
        "start_date": "19-11-2026",
        "end_date": "21-11-2026",
        "ownership": null,
        "pic": null,
        "pic_ids": [
          {
            "id": "A5CE36A8-4BD8-456B-B8B9-D8B438025676",
            "name": "R3 Test amin"
          }
        ],
        "approval_status": "waiting_review",
        "work_order_number": "0014/WO/SDA1/2026",
        "progress": "routing"
      }
    ],
    "count": 1
  },
  "process_time": "707.58ms",
  "status": "success",
  "code": "00",
  "message": "Get action plan PEP list succeed"
}
```

### 23. Approval route prefill

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/approval-route" \
  -H "Authorization: Bearer $PO"
```

Response 200:

```json
{
  "data": {
    "category": "action_plan_pep_well_test",
    "route_id": "cbb996ac-7377-4a4c-8ff1-80c7f68d077c",
    "title": "Action Plan Well Test - PEP",
    "levels": [
      {
        "level": 1,
        "user_id": [
          "0b000000-0000-0000-0000-000000000406"
        ],
        "sla_days": 2,
        "approvers": [
          {
            "id": "0b000000-0000-0000-0000-000000000406",
            "full_name": "PHI PO"
          }
        ]
      },
      {
        "level": 2,
        "user_id": [
          "0b000000-0000-0000-0000-000000000409"
        ],
        "sla_days": 2,
        "approvers": [
          {
            "id": "0b000000-0000-0000-0000-000000000409",
            "full_name": "PHI Super Admin"
          }
        ]
      },
      {
        "level": 3,
        "user_id": [
          "0b000000-0000-0000-0000-000000000407"
        ],
        "sla_days": 3,
        "approvers": [
          {
            "id": "0b000000-0000-0000-0000-000000000407",
            "full_name": "PHI SDA 1"
          }
        ]
      }
    ]
  },
  "process_time": "846.27ms",
  "status": "success",
  "code": "00",
  "message": "Get action plan approval route succeed"
}
```

### 24. Need action, stage=review

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/approvals/need-action?stage=review&page=1&page_size=10" \
  -H "Authorization: Bearer $PO"
```

Response 200:

```json
{
  "data": {
    "items": [
      {
        "id": "fd558192-c25d-45a4-be28-2d0b48bddfd1",
        "source": "pep",
        "action_plan_type": "well_test",
        "well_test_action": "schedule",
        "activity_type": null,
        "well": {
          "id": "6e23e1dc-98f4-45a2-954b-466955af8cda",
          "name": "AE-WELL-BARU-0002"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0005/WO/SDA1/2026",
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
        "submitted_at": "06-11-2026 15:25:03",
        "decided_by": null,
        "waiting_since": "06-11-2026 15:25:03",
        "current_level_sla_days": 3,
        "current_level_due_at": "11-11-2026 15:25:03",
        "current_level_status": "on_track"
      },
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
        "current_level_status": "on_track"
      },
      {
        "id": "fc470e8d-abb3-46f9-b33e-7b294a73f46a",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "c326ae00-a049-47fd-95c6-11adcd170531",
          "name": "WF-PRD08"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "modify_returned",
        "work_order_number": "0012/WO/SDA1/2026",
        "cycle_no": 1,
        "path": "modify",
        "current_level": null,
        "total_level": null,
        "start_date": "19-11-2026",
        "end_date": "21-11-2026",
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
        "submitted_at": "09-11-2026 11:10:39",
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "waiting_since": "09-11-2026 11:11:54",
        "current_level_sla_days": 3,
        "current_level_due_at": "12-11-2026 11:11:54",
        "current_level_status": "on_track"
      }
    ],
    "page": 1,
    "page_size": 10,
    "total": 7
  },
  "process_time": "2302.25ms",
  "status": "success",
  "code": "00",
  "message": "Get action plan need action succeed"
}
```

_Arrays cut to 3 items; original sizes: 7._

### 25. Need action, stage=review, user without 161

User `phi.sda2`. Expected 403, actual 403: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/approvals/need-action?stage=review" \
  -H "Authorization: Bearer $NOPRIV"
```

Response 403:

```json
{
  "error_data": {
    "title": "Failed",
    "description": "You are not allowed to review action plans",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "process_time": "1181.04ms",
  "status": "failed",
  "code": "01",
  "message": "You are not allowed to review action plans"
}
```

### 26. My task list

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/my-task-list" \
  -H "Authorization: Bearer $PO"
```

Response 200:

```json
{
  "data": {
    "project_task_summary": [],
    "project_approval": {
      "on_track": [],
      "near_due": [],
      "delayed": []
    },
    "contract_approval": {
      "on_track": [],
      "near_due": [],
      "delayed": []
    },
    "spk_approval": {
      "on_track": [
        {
          "spk_id": "17f8ba31-4e09-4ee2-b079-41ba19669873",
          "spk_no": "009/SPK/CN-QAHIGH-1793328704164/PPZ9/2026",
          "spk_title": "E2E PHI-2262 Tiered 1793350099556",
          "approval_category": "spk_esign",
          "approval_process_id": "df7b1f7a-2486-4592-a4c2-3be84811a862",
          "due_date": "2026-11-20",
          "days_overdue": 0,
          "current_level_due_date": "2026-11-02"
        },
        {
          "spk_id": "b5e06136-7c73-4499-9e91-c90ed90143ac",
          "spk_no": "008/SPK/CN-QAHIGH-1793328704164/PPZ9/2026",
          "spk_title": "E2E PHI-2262 Tiered 1793349940624",
          "approval_category": "spk_esign",
          "approval_process_id": "f03d500f-1e14-4c86-8863-007cff49978d",
          "due_date": "2026-11-20",
          "days_overdue": 0,
          "current_level_due_date": "2026-11-02"
        }
      ],
      "near_due": [],
      "delayed": []
    },
    "spk_boq_progress_approval": {
      "on_track": [],
      "near_due": [],
      "delayed": []
    },
    "project_rebaseline_approval": {
      "on_track": [],
      "near_due": [],
      "delayed": []
    },
    "eur_update_approval": {
      "on_track": [],
      "near_due": [],
      "delayed": []
    },
    "action_plan_review": {
      "on_track": [
        {
          "action_plan_id": "fd558192-c25d-45a4-be28-2d0b48bddfd1",
          "source": "pep",
          "action_plan_type": "well_test",
          "well_test_action": "schedule",
          "activity_type": null,
          "work_order_number": "0005/WO/SDA1/2026",
          "well_id": "6e23e1dc-98f4-45a2-954b-466955af8cda",
          "well_name": "AE-WELL-BARU-0002",
          "approval_status": "waiting_review",
          "path": null,
          "cycle_no": null,
          "current_level": null,
          "total_levels": null,
          "requested_by": "PHI SDA 1",
          "assigned_department": "Production Operations",
          "submitted_at": "06-11-2026",
          "waiting_since": "06-11-2026",
          "due_date": "11-11-2026",
          "days_overdue": 0
        },
        {
          "action_plan_id": "7a6d7ae6-1a23-4a0c-b307-611449196bcc",
          "source": "pep",
          "action_plan_type": "artificial_lift",
          "well_test_action": null,
          "activity_type": "installation",
          "work_order_number": "0007/WO/SDA1/2026",
          "well_id": "1bad4d3a-b752-4b3f-ae0f-21c1ef321f71",
          "well_name": "A-INDANA-PEP",
          "approval_status": "waiting_review",
          "path": null,
          "cycle_no": null,
          "current_level": null,
          "total_levels": null,
          "requested_by": "PHI SDA 1",
          "assigned_department": "Production Operations",
          "submitted_at": "06-11-2026",
          "waiting_since": "06-11-2026",
          "due_date": "11-11-2026",
          "days_overdue": 0
        },
        {
          "action_plan_id": "fc470e8d-abb3-46f9-b33e-7b294a73f46a",
          "source": "pep",
          "action_plan_type": "artificial_lift",
          "well_test_action": null,
          "activity_type": "installation",
          "work_order_number": "0012/WO/SDA1/2026",
          "well_id": "c326ae00-a049-47fd-95c6-11adcd170531",
          "well_name": "WF-PRD08",
          "approval_status": "modify_returned",
          "path": "modify",
          "cycle_no": 1,
          "current_level": null,
          "total_levels": null,
          "requested_by": "PHI SDA 1",
          "assigned_department": "Production Operations",
          "submitted_at": "09-11-2026",
          "waiting_since": "09-11-2026",
          "due_date": "12-11-2026",
          "days_overdue": 0
        }
      ],
      "near_due": [],
      "delayed": []
    },
    "action_plan_approval": {
      "on_track": [],
      "near_due": [],
      "delayed": []
    }
  },
  "process_time": "4957.06ms",
  "status": "success",
  "code": "",
  "message": "Get my task list succeed"
}
```

_Arrays cut to 3 items; original sizes: 7._

### 27. My approval list

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/my-approval-list?approval_type=action_plan_review|action_plan_approval" \
  -H "Authorization: Bearer $PO"
```

Response 200:

```json
{
  "data": {
    "project_approval": {
      "on_track": [],
      "near_due": [],
      "delayed": []
    },
    "contract_approval": {
      "on_track": [],
      "near_due": [],
      "delayed": []
    },
    "spk_approval": {
      "on_track": [],
      "near_due": [],
      "delayed": []
    },
    "spk_boq_progress_approval": {
      "on_track": [],
      "near_due": [],
      "delayed": []
    },
    "project_rebaseline_approval": {
      "on_track": [],
      "near_due": [],
      "delayed": []
    },
    "eur_update_approval": {
      "on_track": [],
      "near_due": [],
      "delayed": []
    },
    "action_plan_review": {
      "on_track": [
        {
          "action_plan_id": "fd558192-c25d-45a4-be28-2d0b48bddfd1",
          "source": "pep",
          "action_plan_type": "well_test",
          "well_test_action": "schedule",
          "activity_type": null,
          "work_order_number": "0005/WO/SDA1/2026",
          "well_id": "6e23e1dc-98f4-45a2-954b-466955af8cda",
          "well_name": "AE-WELL-BARU-0002",
          "approval_status": "waiting_review",
          "path": null,
          "cycle_no": null,
          "current_level": null,
          "total_levels": null,
          "requested_by": "PHI SDA 1",
          "assigned_department": "Production Operations",
          "submitted_at": "06-11-2026",
          "waiting_since": "06-11-2026",
          "due_date": "11-11-2026",
          "days_overdue": 0
        },
        {
          "action_plan_id": "7a6d7ae6-1a23-4a0c-b307-611449196bcc",
          "source": "pep",
          "action_plan_type": "artificial_lift",
          "well_test_action": null,
          "activity_type": "installation",
          "work_order_number": "0007/WO/SDA1/2026",
          "well_id": "1bad4d3a-b752-4b3f-ae0f-21c1ef321f71",
          "well_name": "A-INDANA-PEP",
          "approval_status": "waiting_review",
          "path": null,
          "cycle_no": null,
          "current_level": null,
          "total_levels": null,
          "requested_by": "PHI SDA 1",
          "assigned_department": "Production Operations",
          "submitted_at": "06-11-2026",
          "waiting_since": "06-11-2026",
          "due_date": "11-11-2026",
          "days_overdue": 0
        },
        {
          "action_plan_id": "fc470e8d-abb3-46f9-b33e-7b294a73f46a",
          "source": "pep",
          "action_plan_type": "artificial_lift",
          "well_test_action": null,
          "activity_type": "installation",
          "work_order_number": "0012/WO/SDA1/2026",
          "well_id": "c326ae00-a049-47fd-95c6-11adcd170531",
          "well_name": "WF-PRD08",
          "approval_status": "modify_returned",
          "path": "modify",
          "cycle_no": 1,
          "current_level": null,
          "total_levels": null,
          "requested_by": "PHI SDA 1",
          "assigned_department": "Production Operations",
          "submitted_at": "09-11-2026",
          "waiting_since": "09-11-2026",
          "due_date": "12-11-2026",
          "days_overdue": 0
        }
      ],
      "near_due": [],
      "delayed": []
    },
    "action_plan_approval": {
      "on_track": [],
      "near_due": [],
      "delayed": []
    }
  },
  "process_time": "2894.20ms",
  "status": "success",
  "code": "",
  "message": "Get my approval list succeed"
}
```

_Arrays cut to 3 items; original sizes: 7._

### 28. My task badge

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/my-task-badge" \
  -H "Authorization: Bearer $PO"
```

Response 200:

```json
{
  "data": {
    "color": "green",
    "task_count": 9,
    "has_approvals": true
  },
  "process_time": "3419.94ms",
  "status": "success",
  "code": "",
  "message": "Get my task badge succeed"
}
```

## 5. PO review

### 29. Review without 161

User `phi.sda2`. Expected 403, actual 403: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/2e9a1e64-8526-464d-891f-f3fa1a1484f4/review" \
  -H "Authorization: Bearer $NOPRIV" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "approve",
  "execution_department_id": "Production Operations",
  "execution_pic_id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
}'
```

Response 403:

```json
{
  "error_data": {
    "title": "Failed",
    "description": "You are not allowed to review action plans",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "process_time": "449.89ms",
  "status": "failed",
  "code": "01",
  "message": "You are not allowed to review action plans"
}
```

### 30. Review approve (plan B)

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/2e9a1e64-8526-464d-891f-f3fa1a1484f4/review" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "approve",
  "execution_department_id": "Production Operations",
  "execution_pic_id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
}'
```

Response 200:

```json
{
  "data": {
    "action_plan_id": "2e9a1e64-8526-464d-891f-f3fa1a1484f4",
    "source": "pep",
    "work_order_number": "0016/WO/SDA1/2026",
    "approval_status": "approved",
    "cycle_no": 1,
    "path": "approve",
    "current_level": null,
    "total_levels": null
  },
  "process_time": "1367.32ms",
  "status": "success",
  "code": "00",
  "message": "Review action plan succeed"
}
```

### 31. Review a plan that is already approved

User `phi.po`. Expected 400, actual 400: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/2e9a1e64-8526-464d-891f-f3fa1a1484f4/review" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "approve",
  "execution_department_id": "Production Operations",
  "execution_pic_id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
}'
```

Response 400:

```json
{
  "error_data": {
    "title": "Failed",
    "description": "The action plan is approved; it cannot be reviewed",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "process_time": "556.71ms",
  "status": "failed",
  "code": "01",
  "message": "The action plan is approved; it cannot be reviewed"
}
```

### 32. Review modify changing method (plan D)

User `phi.po`. Expected 400, actual 400: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/6c182d7c-60ca-407d-856b-a45f7f844326/review" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "modify",
  "remarks": "change method",
  "proposed": {
    "action_plan_type": "artificial_lift",
    "well_id": "f1000000-0000-4000-8000-000000000002",
    "start_date": "19-11-2026",
    "end_date": "21-11-2026",
    "pic_ids": [
      "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
    ],
    "artificial_lift": {
      "activity_type": "installation",
      "action_mode": "installation_schedule",
      "method": "esp",
      "assigned_department": "Production Operations",
      "whc_type": "mobile",
      "compression_type": 1,
      "owned_by": "rental",
      "contract_number": "CTR-PO/2026/014",
      "cost_allocation": "WBS-Z9-0042",
      "production": 0.5
    }
  },
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000406"
      ]
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ]
    },
    {
      "level": 3,
      "user_id": [
        "0b000000-0000-0000-0000-000000000407"
      ]
    }
  ]
}'
```

Response 400:

```json
{
  "error_data": {
    "title": "Failed",
    "description": "proposed may not change artificial_lift.method",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "process_time": "682.74ms",
  "status": "failed",
  "code": "01",
  "message": "proposed may not change artificial_lift.method"
}
```

### 33. Review modify (plan D)

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/6c182d7c-60ca-407d-856b-a45f7f844326/review" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "modify",
  "remarks": "raise production",
  "proposed": {
    "action_plan_type": "artificial_lift",
    "well_id": "f1000000-0000-4000-8000-000000000002",
    "start_date": "19-11-2026",
    "end_date": "21-11-2026",
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
      "production": 0.9
    }
  },
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000406"
      ]
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ]
    },
    {
      "level": 3,
      "user_id": [
        "0b000000-0000-0000-0000-000000000407"
      ]
    }
  ]
}'
```

Response 200:

```json
{
  "data": {
    "action_plan_id": "6c182d7c-60ca-407d-856b-a45f7f844326",
    "source": "pep",
    "work_order_number": "0017/WO/SDA1/2026",
    "approval_status": "modify_in_approval",
    "cycle_no": 1,
    "path": "modify",
    "current_level": 1,
    "total_levels": 3
  },
  "process_time": "2581.95ms",
  "status": "success",
  "code": "00",
  "message": "Review action plan succeed"
}
```

### 34. Review modify (plan A, new end date)

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/review" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "modify",
  "remarks": "extend 3 days",
  "proposed": {
    "action_plan_type": "well_test",
    "well_id": "e8175ae8-0cd3-4a16-b1de-c8d8f77fa1f4",
    "start_date": "19-11-2026",
    "end_date": "24-11-2026",
    "pic_ids": [
      "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
    ],
    "well_test": {
      "well_test_action": "schedule",
      "well_test_type": "production_test",
      "assigned_department": "Production Operations",
      "contract_number": "CTR-PO/2026/001"
    }
  },
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000406"
      ]
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ]
    },
    {
      "level": 3,
      "user_id": [
        "0b000000-0000-0000-0000-000000000407"
      ]
    }
  ],
  "execution_department_id": "Production Operations",
  "execution_pic_id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
}'
```

Response 200:

```json
{
  "data": {
    "action_plan_id": "a9d58d43-39b7-4c0b-8a91-330e08a84874",
    "source": "pep",
    "work_order_number": "0014/WO/SDA1/2026",
    "approval_status": "modify_in_approval",
    "cycle_no": 1,
    "path": "modify",
    "current_level": 1,
    "total_levels": 3
  },
  "process_time": "2265.22ms",
  "status": "success",
  "code": "00",
  "message": "Review action plan succeed"
}
```

### 35. Review reject without remarks (plan C)

User `phi.po`. Expected 400, actual 400: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/7ec4f1c8-ac77-4ac6-93d6-ddd5cf3b31ca/review" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "reject",
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000406"
      ]
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ]
    }
  ]
}'
```

Response 400:

```json
{
  "error_data": {
    "title": "Failed",
    "description": "remarks is required",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "process_time": "506.01ms",
  "status": "failed",
  "code": "01",
  "message": "remarks is required"
}
```

### 36. Review reject (plan C)

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/7ec4f1c8-ac77-4ac6-93d6-ddd5cf3b31ca/review" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "reject",
  "remarks": "not needed",
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-000000000406"
      ]
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ]
    }
  ]
}'
```

Response 200:

```json
{
  "data": {
    "action_plan_id": "7ec4f1c8-ac77-4ac6-93d6-ddd5cf3b31ca",
    "source": "pep",
    "work_order_number": "0015/WO/SDA1/2026",
    "approval_status": "reject_in_approval",
    "cycle_no": 1,
    "path": "reject",
    "current_level": 1,
    "total_levels": 2
  },
  "process_time": "1693.65ms",
  "status": "success",
  "code": "00",
  "message": "Review action plan succeed"
}
```

## 6. Level decisions

### 37. Need action, stage=approval

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/approvals/need-action?stage=approval&page=1&page_size=10" \
  -H "Authorization: Bearer $PO"
```

Response 200:

```json
{
  "data": {
    "items": [
      {
        "id": "6c182d7c-60ca-407d-856b-a45f7f844326",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "f1000000-0000-4000-8000-000000000002",
          "name": "WF-PROD-01"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "modify_in_approval",
        "work_order_number": "0017/WO/SDA1/2026",
        "cycle_no": 1,
        "path": "modify",
        "current_level": 1,
        "total_level": 3,
        "start_date": "19-11-2026",
        "end_date": "21-11-2026",
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
        "submitted_at": "09-11-2026 11:32:41",
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "waiting_since": "09-11-2026 11:33:23",
        "current_level_sla_days": 2,
        "current_level_due_at": "11-11-2026 11:33:23",
        "current_level_status": "on_track"
      },
      {
        "id": "a9d58d43-39b7-4c0b-8a91-330e08a84874",
        "source": "pep",
        "action_plan_type": "well_test",
        "well_test_action": "schedule",
        "activity_type": null,
        "well": {
          "id": "e8175ae8-0cd3-4a16-b1de-c8d8f77fa1f4",
          "name": "AUTO-BU-PEP-20261030061555"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "modify_in_approval",
        "work_order_number": "0014/WO/SDA1/2026",
        "cycle_no": 1,
        "path": "modify",
        "current_level": 1,
        "total_level": 3,
        "start_date": "19-11-2026",
        "end_date": "21-11-2026",
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
        "submitted_at": "09-11-2026 11:32:35",
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "waiting_since": "09-11-2026 11:33:26",
        "current_level_sla_days": 2,
        "current_level_due_at": "11-11-2026 11:33:26",
        "current_level_status": "on_track"
      },
      {
        "id": "7ec4f1c8-ac77-4ac6-93d6-ddd5cf3b31ca",
        "source": "pep",
        "action_plan_type": "well_test",
        "well_test_action": "schedule",
        "activity_type": null,
        "well": {
          "id": "69556699-730b-44b5-82ee-575db818ec14",
          "name": "AUTO-BU-PEP-20261031040503"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "reject_in_approval",
        "work_order_number": "0015/WO/SDA1/2026",
        "cycle_no": 1,
        "path": "reject",
        "current_level": 1,
        "total_level": 2,
        "start_date": "19-11-2026",
        "end_date": "21-11-2026",
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
        "submitted_at": "09-11-2026 11:32:37",
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "waiting_since": "09-11-2026 11:33:30",
        "current_level_sla_days": 2,
        "current_level_due_at": "11-11-2026 11:33:30",
        "current_level_status": "on_track"
      }
    ],
    "page": 1,
    "page_size": 10,
    "total": 3
  },
  "process_time": "1555.39ms",
  "status": "success",
  "code": "00",
  "message": "Get action plan need action succeed"
}
```

### 38. Approve by a user not on the pending level

User `phi.generalmanager`. Expected 403, actual 403: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/approval/approve" \
  -H "Authorization: Bearer $GM" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "x"
}'
```

Response 403:

```json
{
  "error_data": {
    "title": "Failed",
    "description": "You are not an approver of level 1 for this action plan",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "process_time": "1409.24ms",
  "status": "failed",
  "code": "01",
  "message": "You are not an approver of level 1 for this action plan"
}
```

### 39. Approve without 162

User `phi.sda2`. Expected 403, actual 403: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/approval/approve" \
  -H "Authorization: Bearer $NOPRIV" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "x"
}'
```

Response 403:

```json
{
  "error_data": {
    "title": "Failed",
    "description": "You are not allowed to approve action plans",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "process_time": "579.66ms",
  "status": "failed",
  "code": "01",
  "message": "You are not allowed to approve action plans"
}
```

### 40. Modify: approve L1 (plan A)

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/approval/approve" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "ok L1"
}'
```

Response 200:

```json
{
  "data": {
    "action_plan_id": "a9d58d43-39b7-4c0b-8a91-330e08a84874",
    "source": "pep",
    "work_order_number": "0014/WO/SDA1/2026",
    "approval_status": "modify_in_approval",
    "cycle_no": 1,
    "path": "modify",
    "current_level": 2,
    "total_levels": 3
  },
  "process_time": "1868.22ms",
  "status": "success",
  "code": "00",
  "message": "Approve action plan succeed"
}
```

### 41. Approve L1 again by the same user

User `phi.po`. Expected 400/403, actual 403: **PASS**

The reviewer expects 400 "already decided". The pending level has moved to L2, so this user is no longer an approver of it.

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/approval/approve" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "again"
}'
```

Response 403:

```json
{
  "error_data": {
    "title": "Failed",
    "description": "You are not an approver of level 2 for this action plan",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "process_time": "654.02ms",
  "status": "failed",
  "code": "01",
  "message": "You are not an approver of level 2 for this action plan"
}
```

### 42. Modify: approve L2 (plan A)

User `phi.superadmin`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/approval/approve" \
  -H "Authorization: Bearer $MGR2" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "ok L2"
}'
```

Response 200:

```json
{
  "data": {
    "action_plan_id": "a9d58d43-39b7-4c0b-8a91-330e08a84874",
    "source": "pep",
    "work_order_number": "0014/WO/SDA1/2026",
    "approval_status": "modify_in_approval",
    "cycle_no": 1,
    "path": "modify",
    "current_level": 3,
    "total_levels": 3
  },
  "process_time": "1948.36ms",
  "status": "success",
  "code": "00",
  "message": "Approve action plan succeed"
}
```

### 43. Modify: approve L3, proposal applied (plan A)

User `phi.sda1`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/approval/approve" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "ok L3"
}'
```

Response 200:

```json
{
  "data": {
    "action_plan_id": "a9d58d43-39b7-4c0b-8a91-330e08a84874",
    "source": "pep",
    "work_order_number": "0014/WO/SDA1/2026",
    "approval_status": "approved",
    "cycle_no": 1,
    "path": "modify",
    "current_level": null,
    "total_levels": 3
  },
  "process_time": "2586.39ms",
  "status": "success",
  "code": "00",
  "message": "Approve action plan succeed"
}
```

### 44. Detail after Modify: end_date changed (plan A)

User `phi.sda1`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874" \
  -H "Authorization: Bearer $SSDP"
```

Response 200:

```json
{
  "data": {
    "id": "a9d58d43-39b7-4c0b-8a91-330e08a84874",
    "action_plan_type": "well_test",
    "status": "upcoming",
    "start_date": "19-11-2026",
    "end_date": "24-11-2026",
    "notes": "",
    "ownership": null,
    "pic": null,
    "pic_ids": [
      {
        "id": "58D0062C-ABDE-4924-AB59-B0F47E76A775",
        "name": "R3 Test amin",
        "email": "r3test.amin@yopmail.com"
      }
    ],
    "created_at": "09-11-2026 11:32:35",
    "created_by": {
      "id": "0B000000-0000-0000-0000-000000000407",
      "full_name": "PHI SDA 1"
    },
    "updated_at": "09-11-2026 11:33:44",
    "updated_by": {
      "id": "0B000000-0000-0000-0000-000000000407",
      "full_name": "PHI SDA 1"
    },
    "choke": null,
    "sonolog": null,
    "well_test": {
      "gas": 0,
      "oil": 0,
      "well_test_action": "schedule",
      "contract_id": "",
      "contract_number": "CTR-PO/2026/001",
      "contract_no": "",
      "contract_title": "",
      "contractor": null,
      "well_test_type": {
        "id": "production_test",
        "name": "Regular Well Test"
      },
      "planned_duration_hours": 0,
      "actual_planned_hours": 0,
      "tank_number": "",
      "start_date_time": "",
      "end_date_time": "",
      "u_press": 0,
      "chp": 0,
      "choke": 0,
      "whfp": 0,
      "flp": 0,
      "gi": 0,
      "liquid": 0,
      "water": 0,
      "bsw": 0,
      "sand": 0
    },
    "artificial_lift": null,
    "others": null,
    "approval_status": "approved",
    "requires_approval": true,
    "work_order_number": "0014/WO/SDA1/2026",
    "assigned_department": "Production Operations",
    "execution_department_id": "Production Operations",
    "execution_pic": {
      "id": "A5CE36A8-4BD8-456B-B8B9-D8B438025676",
      "name": "R3 Test amin",
      "email": "r3test.amin@yopmail.com"
    },
    "can_review": false,
    "can_approve": false,
    "can_reject": false,
    "approval": {
      "cycle_no": 1,
      "path": "modify",
      "current_level": null,
      "total_levels": 3
    }
  },
  "process_time": "1182.65ms",
  "status": "success",
  "code": "00",
  "message": "Get action plan PEP detail succeed"
}
```

### 45. Modification diff (plan A)

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/modification-diff" \
  -H "Authorization: Bearer $PO"
```

Response 200:

```json
{
  "data": {
    "cycle_id": "353a2f24-0796-4eac-b3d9-95258a5e2847",
    "cycle_no": 1,
    "applied_at": "09-11-2026 11:33:44",
    "changes": [
      {
        "field": "end_date",
        "original": "21-11-2026",
        "proposed": "24-11-2026"
      },
      {
        "field": "execution_department_id",
        "original": null,
        "proposed": "Production Operations"
      },
      {
        "field": "execution_pic_id",
        "original": null,
        "proposed": "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
      }
    ],
    "original": {
      "action_plan_type": "well_test",
      "draft_id": null,
      "well_id": "e8175ae8-0cd3-4a16-b1de-c8d8f77fa1f4",
      "start_date": "19-11-2026",
      "end_date": "21-11-2026",
      "pic_id": null,
      "pic_ids": [
        "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
      ],
      "notes": null,
      "ownership": null,
      "wo_number": null,
      "choke": null,
      "sonolog": null,
      "well_test": {
        "well_test_action": "schedule",
        "contract_id": null,
        "contract_number": "CTR-PO/2026/001",
        "assigned_department": "Production Operations",
        "well_test_type": "production_test",
        "planned_duration_hours": null,
        "actual_duration_hours": null,
        "tank_number": null,
        "gas": null,
        "oil": null,
        "u_press": null,
        "chp": null,
        "choke": null,
        "whfp": null,
        "flp": null,
        "gi": null,
        "liquid": null,
        "water": null,
        "bsw": null,
        "sand": null,
        "start_date_time": null,
        "end_date_time": null
      },
      "artificial_lift": null,
      "others": null,
      "execution_department_id": null,
      "execution_pic_id": null
    },
    "proposed": {
      "action_plan_type": "well_test",
      "draft_id": null,
      "well_id": "e8175ae8-0cd3-4a16-b1de-c8d8f77fa1f4",
      "start_date": "19-11-2026",
      "end_date": "24-11-2026",
      "pic_id": null,
      "pic_ids": [
        "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
      ],
      "notes": null,
      "ownership": null,
      "wo_number": null,
      "choke": null,
      "sonolog": null,
      "well_test": {
        "well_test_action": "schedule",
        "contract_id": null,
        "contract_number": "CTR-PO/2026/001",
        "assigned_department": "Production Operations",
        "well_test_type": "production_test",
        "planned_duration_hours": null,
        "actual_duration_hours": null,
        "tank_number": null,
        "gas": null,
        "oil": null,
        "u_press": null,
        "chp": null,
        "choke": null,
        "whfp": null,
        "flp": null,
        "gi": null,
        "liquid": null,
        "water": null,
        "bsw": null,
        "sand": null,
        "start_date_time": null,
        "end_date_time": null
      },
      "artificial_lift": null,
      "others": null,
      "execution_department_id": "Production Operations",
      "execution_pic_id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
    }
  },
  "process_time": "205.80ms",
  "status": "success",
  "code": "00",
  "message": "Get action plan modification diff succeed"
}
```

### 46. Approval history (plan A)

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/pep/a9d58d43-39b7-4c0b-8a91-330e08a84874/approval-history" \
  -H "Authorization: Bearer $PO"
```

Response 200:

```json
{
  "data": {
    "action_plan_id": "a9d58d43-39b7-4c0b-8a91-330e08a84874",
    "source": "pep",
    "work_order_number": "0014/WO/SDA1/2026",
    "approval_status": "approved",
    "cycles": [
      {
        "cycle_id": "353a2f24-0796-4eac-b3d9-95258a5e2847",
        "cycle_no": 1,
        "path": "modify",
        "previous_cycle_id": null,
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "decided_at": "09-11-2026 11:33:26",
        "remarks": "extend 3 days",
        "outcome": "approved",
        "closed_at": "09-11-2026 11:33:44",
        "levels": [
          {
            "level": 1,
            "approvers": [
              {
                "id": "0b000000-0000-0000-0000-000000000406",
                "full_name": "PHI PO"
              }
            ],
            "sla_days": 2,
            "started_at": "09-11-2026 11:33:26",
            "due_at": "11-11-2026 11:33:26",
            "closed_at": "09-11-2026 11:33:38",
            "outcome": "approved"
          },
          {
            "level": 2,
            "approvers": [
              {
                "id": "0b000000-0000-0000-0000-000000000409",
                "full_name": "PHI Super Admin"
              }
            ],
            "sla_days": 2,
            "started_at": "09-11-2026 11:33:38",
            "due_at": "11-11-2026 11:33:38",
            "closed_at": "09-11-2026 11:33:42",
            "outcome": "approved"
          },
          {
            "level": 3,
            "approvers": [
              {
                "id": "0b000000-0000-0000-0000-000000000407",
                "full_name": "PHI SDA 1"
              }
            ],
            "sla_days": 3,
            "started_at": "09-11-2026 11:33:42",
            "due_at": "12-11-2026 11:33:42",
            "closed_at": "09-11-2026 11:33:44",
            "outcome": "approved"
          }
        ],
        "logs": [
          {
            "level": 0,
            "action": "initiate",
            "remarks": "extend 3 days",
            "created_at": "09-11-2026 11:33:26",
            "created_by": {
              "id": "0b000000-0000-0000-0000-000000000406",
              "full_name": "PHI PO"
            }
          },
          {
            "level": 1,
            "action": "approve",
            "remarks": "ok L1",
            "created_at": "09-11-2026 11:33:38",
            "created_by": {
              "id": "0b000000-0000-0000-0000-000000000406",
              "full_name": "PHI PO"
            }
          },
          {
            "level": 2,
            "action": "approve",
            "remarks": "ok L2",
            "created_at": "09-11-2026 11:33:42",
            "created_by": {
              "id": "0b000000-0000-0000-0000-000000000409",
              "full_name": "PHI Super Admin"
            }
          }
        ]
      }
    ]
  },
  "process_time": "747.05ms",
  "status": "success",
  "code": "00",
  "message": "Get action plan approval history succeed"
}
```

_Arrays cut to 3 items; original sizes: 4._

### 47. Reject: approve L1 (plan C)

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/7ec4f1c8-ac77-4ac6-93d6-ddd5cf3b31ca/approval/approve" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "agree"
}'
```

Response 200:

```json
{
  "data": {
    "action_plan_id": "7ec4f1c8-ac77-4ac6-93d6-ddd5cf3b31ca",
    "source": "pep",
    "work_order_number": "0015/WO/SDA1/2026",
    "approval_status": "reject_in_approval",
    "cycle_no": 1,
    "path": "reject",
    "current_level": 2,
    "total_levels": 2
  },
  "process_time": "1782.83ms",
  "status": "success",
  "code": "00",
  "message": "Approve action plan succeed"
}
```

### 48. Reject: approve L2, plan rejected (plan C)

User `phi.superadmin`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/7ec4f1c8-ac77-4ac6-93d6-ddd5cf3b31ca/approval/approve" \
  -H "Authorization: Bearer $MGR2" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "agree"
}'
```

Response 200:

```json
{
  "data": {
    "action_plan_id": "7ec4f1c8-ac77-4ac6-93d6-ddd5cf3b31ca",
    "source": "pep",
    "work_order_number": "0015/WO/SDA1/2026",
    "approval_status": "rejected",
    "cycle_no": 1,
    "path": "reject",
    "current_level": null,
    "total_levels": 2
  },
  "process_time": "2084.31ms",
  "status": "success",
  "code": "00",
  "message": "Approve action plan succeed"
}
```

### 49. Level reject, back to PO (plan D)

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/6c182d7c-60ca-407d-856b-a45f7f844326/approval/reject" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "needs rework"
}'
```

Response 200:

```json
{
  "data": {
    "action_plan_id": "6c182d7c-60ca-407d-856b-a45f7f844326",
    "source": "pep",
    "work_order_number": "0017/WO/SDA1/2026",
    "approval_status": "modify_returned",
    "cycle_no": 1,
    "path": "modify",
    "current_level": null,
    "total_levels": 3
  },
  "process_time": "1683.21ms",
  "status": "success",
  "code": "00",
  "message": "Reject action plan succeed"
}
```

### 50. Review approve while modify_returned (plan D)

User `phi.po`. Expected 400, actual 400: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/6c182d7c-60ca-407d-856b-a45f7f844326/review" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "approve",
  "execution_department_id": "Production Operations",
  "execution_pic_id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
}'
```

Response 400:

```json
{
  "error_data": {
    "title": "Failed",
    "description": "decision must be modify | reject while the action plan is modify_returned",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "process_time": "475.89ms",
  "status": "failed",
  "code": "01",
  "message": "decision must be modify | reject while the action plan is modify_returned"
}
```

### 51. Approval history (plan D)

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/pep/6c182d7c-60ca-407d-856b-a45f7f844326/approval-history" \
  -H "Authorization: Bearer $PO"
```

Response 200:

```json
{
  "data": {
    "action_plan_id": "6c182d7c-60ca-407d-856b-a45f7f844326",
    "source": "pep",
    "work_order_number": "0017/WO/SDA1/2026",
    "approval_status": "modify_returned",
    "cycles": [
      {
        "cycle_id": "6fe53e11-0c64-4b61-811b-0ed43a90f883",
        "cycle_no": 1,
        "path": "modify",
        "previous_cycle_id": null,
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "decided_at": "09-11-2026 11:33:23",
        "remarks": "raise production",
        "outcome": "returned",
        "closed_at": "09-11-2026 11:33:57",
        "levels": [
          {
            "level": 1,
            "approvers": [
              {
                "id": "0b000000-0000-0000-0000-000000000406",
                "full_name": "PHI PO"
              }
            ],
            "sla_days": 2,
            "started_at": "09-11-2026 11:33:23",
            "due_at": "11-11-2026 11:33:23",
            "closed_at": "09-11-2026 11:33:57",
            "outcome": "rejected"
          },
          {
            "level": 2,
            "approvers": [
              {
                "id": "0b000000-0000-0000-0000-000000000409",
                "full_name": "PHI Super Admin"
              }
            ],
            "sla_days": 3,
            "started_at": null,
            "due_at": null,
            "closed_at": null,
            "outcome": null
          },
          {
            "level": 3,
            "approvers": [
              {
                "id": "0b000000-0000-0000-0000-000000000407",
                "full_name": "PHI SDA 1"
              }
            ],
            "sla_days": 2,
            "started_at": null,
            "due_at": null,
            "closed_at": null,
            "outcome": null
          }
        ],
        "logs": [
          {
            "level": 0,
            "action": "initiate",
            "remarks": "raise production",
            "created_at": "09-11-2026 11:33:23",
            "created_by": {
              "id": "0b000000-0000-0000-0000-000000000406",
              "full_name": "PHI PO"
            }
          },
          {
            "level": 1,
            "action": "reject",
            "remarks": "needs rework",
            "created_at": "09-11-2026 11:33:57",
            "created_by": {
              "id": "0b000000-0000-0000-0000-000000000406",
              "full_name": "PHI PO"
            }
          }
        ]
      }
    ]
  },
  "process_time": "590.67ms",
  "status": "success",
  "code": "00",
  "message": "Get action plan approval history succeed"
}
```

### 52. Unknown plan

User `phi.po`. Expected 404, actual 404: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/pep/00000000-0000-0000-0000-000000000001/approval-history" \
  -H "Authorization: Bearer $PO"
```

Response 404:

```json
{
  "error_data": {
    "title": "Failed",
    "description": "Action plan not found",
    "icon": "https://storage.googleapis.com/phi-dev-bucket/assets/failed-icon.png",
    "primary_text": "OK",
    "secondary_text": "",
    "primary_link": "",
    "secondary_link": "",
    "dismissed_link": ""
  },
  "process_time": "87.80ms",
  "status": "failed",
  "code": "01",
  "message": "Action plan not found"
}
```

## 7. PHSS

### 53. Submit well test (PHSS plan G)

User `phi.sda2`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/phss/submit" \
  -H "Authorization: Bearer $NOPRIV" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "well_test",
  "well_id": "41c3dff6-79d5-4128-b7e8-151f4342b2e9",
  "start_date": "19-11-2026",
  "end_date": "21-11-2026",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "well_test": {
    "well_test_action": "schedule",
    "well_test_type": "production_test",
    "assigned_department": "Production Operations",
    "contract_number": "CTR-PO/2026/001"
  }
}'
```

Response 200:

```json
{
  "data": {
    "id": "a9f52a84-8719-45ad-ae85-3e534085bb49",
    "record_state": "submitted",
    "approval_status": "waiting_review",
    "work_order_number": "0004/WO/SDA2/2026"
  },
  "process_time": "1772.49ms",
  "status": "success",
  "code": "00",
  "message": "Submit action plan PHSS succeed"
}
```

### 54. PHSS detail

User `phi.sda2`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/phss/a9f52a84-8719-45ad-ae85-3e534085bb49" \
  -H "Authorization: Bearer $NOPRIV"
```

Response 200:

```json
{
  "data": {
    "id": "a9f52a84-8719-45ad-ae85-3e534085bb49",
    "action_plan_type": "well_test",
    "status": "upcoming",
    "start_date": "19-11-2026",
    "end_date": "21-11-2026",
    "notes": "",
    "ownership": null,
    "pic": null,
    "pic_ids": [
      {
        "id": "A32116DA-873C-427E-BDA1-34F4F7D16D3D",
        "name": "R3 Test amin",
        "email": "r3test.amin@yopmail.com"
      }
    ],
    "created_at": "09-11-2026 11:34:03",
    "created_by": {
      "id": "0B000000-0000-0000-0000-000000000408",
      "full_name": "PHI SDA 2"
    },
    "updated_at": "09-11-2026 11:34:03",
    "updated_by": {
      "id": "0B000000-0000-0000-0000-000000000408",
      "full_name": "PHI SDA 2"
    },
    "choke": null,
    "well_test": {
      "gas": 0,
      "oil": 0,
      "well_test_action": "schedule",
      "contract_id": "",
      "contract_number": "CTR-PO/2026/001",
      "contract_no": "",
      "contract_title": "",
      "contractor": null,
      "well_test_type": {
        "id": "production_test",
        "name": "Regular Well Test"
      },
      "u_press": 0,
      "chp": 0,
      "choke": 0,
      "whfp": 0,
      "flp": 0,
      "gi": 0,
      "liquid": 0,
      "water": 0,
      "bsw": 0,
      "sand": 0
    },
    "artificial_lift": null,
    "others": null,
    "approval_status": "waiting_review",
    "requires_approval": true,
    "work_order_number": "0004/WO/SDA2/2026",
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
  "process_time": "1260.14ms",
  "status": "success",
  "code": "00",
  "message": "Get action plan PHSS detail succeed"
}
```

### 55. PHSS approval route prefill

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/phss/a9f52a84-8719-45ad-ae85-3e534085bb49/approval-route" \
  -H "Authorization: Bearer $PO"
```

Response 200:

```json
{
  "data": {
    "category": "action_plan_phss_well_test",
    "route_id": "32d7fb61-abda-4a62-be66-78a1f2b252e2",
    "title": "Action Plan Well Test - PHSS",
    "levels": [
      {
        "level": 1,
        "user_id": [
          "0b000000-0000-0000-0000-000000000406"
        ],
        "sla_days": 2,
        "approvers": [
          {
            "id": "0b000000-0000-0000-0000-000000000406",
            "full_name": "PHI PO"
          }
        ]
      },
      {
        "level": 2,
        "user_id": [
          "0b000000-0000-0000-0000-000000000409"
        ],
        "sla_days": 3,
        "approvers": [
          {
            "id": "0b000000-0000-0000-0000-000000000409",
            "full_name": "PHI Super Admin"
          }
        ]
      },
      {
        "level": 3,
        "user_id": [
          "0b000000-0000-0000-0000-000000000407"
        ],
        "sla_days": 2,
        "approvers": [
          {
            "id": "0b000000-0000-0000-0000-000000000407",
            "full_name": "PHI SDA 1"
          }
        ]
      }
    ]
  },
  "process_time": "414.17ms",
  "status": "success",
  "code": "00",
  "message": "Get action plan approval route succeed"
}
```

### 56. PHSS review approve

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/phss/a9f52a84-8719-45ad-ae85-3e534085bb49/review" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "approve",
  "execution_department_id": "Production Operations",
  "execution_pic_id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
}'
```

Response 200:

```json
{
  "data": {
    "action_plan_id": "a9f52a84-8719-45ad-ae85-3e534085bb49",
    "source": "phss",
    "work_order_number": "0004/WO/SDA2/2026",
    "approval_status": "approved",
    "cycle_no": 1,
    "path": "approve",
    "current_level": null,
    "total_levels": null
  },
  "process_time": "1541.45ms",
  "status": "success",
  "code": "00",
  "message": "Review action plan succeed"
}
```

### 57. PHSS approval history

User `phi.po`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/phss/a9f52a84-8719-45ad-ae85-3e534085bb49/approval-history" \
  -H "Authorization: Bearer $PO"
```

Response 200:

```json
{
  "data": {
    "action_plan_id": "a9f52a84-8719-45ad-ae85-3e534085bb49",
    "source": "phss",
    "work_order_number": "0004/WO/SDA2/2026",
    "approval_status": "approved",
    "cycles": [
      {
        "cycle_id": "d61fc653-a248-409b-a321-29c07153a242",
        "cycle_no": 1,
        "path": "approve",
        "previous_cycle_id": null,
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "decided_at": "09-11-2026 11:34:09",
        "remarks": null,
        "outcome": "approved",
        "closed_at": "09-11-2026 11:34:09",
        "levels": [],
        "logs": []
      }
    ]
  },
  "process_time": "666.67ms",
  "status": "success",
  "code": "00",
  "message": "Get action plan approval history succeed"
}
```

## 8. Concurrent WO numbers

### 58. Parallel submit: 5 PEP + 5 PHSS, same department (SDA1)

User `phi.sda1`. Expected 200, actual 200: **PASS**

Sent in parallel, no `wo_number`. The response below is a summary of all requests.

```bash
curl -X POST "$API/well-surveilence/action-plans/{pep|phss}/submit" \
  -H "Authorization: Bearer $SSDP" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "choke",
  "well_id": "<a different well per request>",
  "start_date": "19-11-2026",
  "end_date": "21-11-2026",
  "choke": {
    "gas": 10,
    "oil": 20
  }
}'
```

Response 200:

```json
{
  "requests": 10,
  "results": [
    {
      "source": "pep",
      "status": 200,
      "result": "0019/WO/SDA1/2026"
    },
    {
      "source": "phss",
      "status": 200,
      "result": "0028/WO/SDA1/2026"
    },
    {
      "source": "pep",
      "status": 200,
      "result": "0023/WO/SDA1/2026"
    }
  ],
  "issued": 10,
  "distinct": 10
}
```

_Arrays cut to 3 items; original sizes: 10._

## 9. Test user phi.approver

Plans created: H `944010e4-abaa-4850-9923-9dde72f2ba8c` (PEP), I `da6ff3a6-61c0-4c9e-bd96-2a7660bf56e7` (PHSS).

### 59. Current user permissions

User `phi.approver`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/users/permissions" \
  -H "Authorization: Bearer $APPROVER"
```

Response 200:

```json
{
  "data": {
    "128": [
      "17"
    ],
    "137": [
      "19"
    ],
    "139": [
      "19"
    ],
    "153": [
      "19"
    ],
    "154": [
      "19"
    ],
    "155": [
      "19"
    ],
    "156": [
      "19"
    ],
    "138": [
      "20"
    ],
    "140": [
      "20"
    ],
    "159": [
      "28"
    ],
    "161": [
      "30"
    ],
    "162": [
      "30"
    ],
    "163": [
      "30"
    ]
  },
  "process_time": "500.40ms",
  "status": "success",
  "code": "",
  "message": "Get user permissions succeed"
}
```

### 60. Modify: submit PEP well test (plan H)

User `phi.approver`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $APPROVER" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "well_test",
  "well_id": "cb09c057-dd3f-4bef-a9a3-8a91190ea8e1",
  "start_date": "19-11-2026",
  "end_date": "21-11-2026",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "well_test": {
    "well_test_action": "schedule",
    "well_test_type": "production_test",
    "assigned_department": "Production Operations",
    "contract_number": "CTR-PO/2026/001"
  }
}'
```

Response 200:

```json
{
  "data": {
    "id": "944010e4-abaa-4850-9923-9dde72f2ba8c",
    "record_state": "submitted",
    "approval_status": "waiting_review",
    "work_order_number": "0029/WO/SDA1/2026"
  },
  "process_time": "1774.67ms",
  "status": "success",
  "code": "00",
  "message": "Submit action plan PEP succeed"
}
```

### 61. Modify: submit PHSS well test (plan I)

User `phi.approver`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/phss/submit" \
  -H "Authorization: Bearer $APPROVER" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "well_test",
  "well_id": "7b486d72-9a5c-4c08-a268-019895a915c6",
  "start_date": "19-11-2026",
  "end_date": "21-11-2026",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "well_test": {
    "well_test_action": "schedule",
    "well_test_type": "production_test",
    "assigned_department": "Production Operations",
    "contract_number": "CTR-PO/2026/001"
  }
}'
```

Response 200:

```json
{
  "data": {
    "id": "da6ff3a6-61c0-4c9e-bd96-2a7660bf56e7",
    "record_state": "submitted",
    "approval_status": "waiting_review",
    "work_order_number": "0030/WO/SDA1/2026"
  },
  "process_time": "1439.24ms",
  "status": "success",
  "code": "00",
  "message": "Submit action plan PHSS succeed"
}
```

### 62. Read: PEP plan list

User `phi.approver`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/cb09c057-dd3f-4bef-a9a3-8a91190ea8e1/action-plans/pep?view=ongoing&page=1&page_size=10" \
  -H "Authorization: Bearer $APPROVER"
```

Response 200:

```json
{
  "data": {
    "list": [
      {
        "id": "944010e4-abaa-4850-9923-9dde72f2ba8c",
        "action_plan_type": "well_test",
        "well_test_action": "schedule",
        "action_mode": null,
        "status": "upcoming",
        "start_date": "19-11-2026",
        "end_date": "21-11-2026",
        "ownership": null,
        "pic": null,
        "pic_ids": [
          {
            "id": "A5CE36A8-4BD8-456B-B8B9-D8B438025676",
            "name": "R3 Test amin"
          }
        ],
        "approval_status": "waiting_review",
        "work_order_number": "0029/WO/SDA1/2026",
        "progress": "routing"
      }
    ],
    "count": 1
  },
  "process_time": "1065.16ms",
  "status": "success",
  "code": "00",
  "message": "Get action plan PEP list succeed"
}
```

### 63. Read: PEP plan detail, can review (plan H)

User `phi.approver`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/pep/944010e4-abaa-4850-9923-9dde72f2ba8c" \
  -H "Authorization: Bearer $APPROVER"
```

Response 200:

```json
{
  "data": {
    "id": "944010e4-abaa-4850-9923-9dde72f2ba8c",
    "action_plan_type": "well_test",
    "status": "upcoming",
    "start_date": "19-11-2026",
    "end_date": "21-11-2026",
    "notes": "",
    "ownership": null,
    "pic": null,
    "pic_ids": [
      {
        "id": "C95F325F-4FDB-420E-AC52-E54DC332AF2B",
        "name": "R3 Test amin",
        "email": "r3test.amin@yopmail.com"
      }
    ],
    "created_at": "09-11-2026 13:28:16",
    "created_by": {
      "id": "0B000000-0000-0000-0000-00000000040A",
      "full_name": "PHI Approver"
    },
    "updated_at": "09-11-2026 13:28:16",
    "updated_by": {
      "id": "0B000000-0000-0000-0000-00000000040A",
      "full_name": "PHI Approver"
    },
    "choke": null,
    "sonolog": null,
    "well_test": {
      "gas": 0,
      "oil": 0,
      "well_test_action": "schedule",
      "contract_id": "",
      "contract_number": "CTR-PO/2026/001",
      "contract_no": "",
      "contract_title": "",
      "contractor": null,
      "well_test_type": {
        "id": "production_test",
        "name": "Regular Well Test"
      },
      "planned_duration_hours": 0,
      "actual_planned_hours": 0,
      "tank_number": "",
      "start_date_time": "",
      "end_date_time": "",
      "u_press": 0,
      "chp": 0,
      "choke": 0,
      "whfp": 0,
      "flp": 0,
      "gi": 0,
      "liquid": 0,
      "water": 0,
      "bsw": 0,
      "sand": 0
    },
    "artificial_lift": null,
    "others": null,
    "approval_status": "waiting_review",
    "requires_approval": true,
    "work_order_number": "0029/WO/SDA1/2026",
    "assigned_department": "Production Operations",
    "execution_department_id": null,
    "execution_pic": null,
    "can_review": true,
    "can_approve": false,
    "can_reject": false,
    "approval": {
      "cycle_no": null,
      "path": null,
      "current_level": null,
      "total_levels": null
    }
  },
  "process_time": "1287.95ms",
  "status": "success",
  "code": "00",
  "message": "Get action plan PEP detail succeed"
}
```

### 64. Read: PHSS plan detail, can review (plan I)

User `phi.approver`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/phss/da6ff3a6-61c0-4c9e-bd96-2a7660bf56e7" \
  -H "Authorization: Bearer $APPROVER"
```

Response 200:

```json
{
  "data": {
    "id": "da6ff3a6-61c0-4c9e-bd96-2a7660bf56e7",
    "action_plan_type": "well_test",
    "status": "upcoming",
    "start_date": "19-11-2026",
    "end_date": "21-11-2026",
    "notes": "",
    "ownership": null,
    "pic": null,
    "pic_ids": [
      {
        "id": "AC80FB7E-4A89-47EA-8713-637B65BCDE1B",
        "name": "R3 Test amin",
        "email": "r3test.amin@yopmail.com"
      }
    ],
    "created_at": "09-11-2026 13:28:18",
    "created_by": {
      "id": "0B000000-0000-0000-0000-00000000040A",
      "full_name": "PHI Approver"
    },
    "updated_at": "09-11-2026 13:28:18",
    "updated_by": {
      "id": "0B000000-0000-0000-0000-00000000040A",
      "full_name": "PHI Approver"
    },
    "choke": null,
    "well_test": {
      "gas": 0,
      "oil": 0,
      "well_test_action": "schedule",
      "contract_id": "",
      "contract_number": "CTR-PO/2026/001",
      "contract_no": "",
      "contract_title": "",
      "contractor": null,
      "well_test_type": {
        "id": "production_test",
        "name": "Regular Well Test"
      },
      "u_press": 0,
      "chp": 0,
      "choke": 0,
      "whfp": 0,
      "flp": 0,
      "gi": 0,
      "liquid": 0,
      "water": 0,
      "bsw": 0,
      "sand": 0
    },
    "artificial_lift": null,
    "others": null,
    "approval_status": "waiting_review",
    "requires_approval": true,
    "work_order_number": "0030/WO/SDA1/2026",
    "assigned_department": "Production Operations",
    "execution_department_id": null,
    "execution_pic": null,
    "can_review": true,
    "can_approve": false,
    "can_reject": false,
    "approval": {
      "cycle_no": null,
      "path": null,
      "current_level": null,
      "total_levels": null
    }
  },
  "process_time": "1150.66ms",
  "status": "success",
  "code": "00",
  "message": "Get action plan PHSS detail succeed"
}
```

### 65. Need action, stage=review

User `phi.approver`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/approvals/need-action?stage=review&page=1&page_size=10" \
  -H "Authorization: Bearer $APPROVER"
```

Response 200:

```json
{
  "data": {
    "items": [
      {
        "id": "fd558192-c25d-45a4-be28-2d0b48bddfd1",
        "source": "pep",
        "action_plan_type": "well_test",
        "well_test_action": "schedule",
        "activity_type": null,
        "well": {
          "id": "6e23e1dc-98f4-45a2-954b-466955af8cda",
          "name": "AE-WELL-BARU-0002"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "waiting_review",
        "work_order_number": "0005/WO/SDA1/2026",
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
        "submitted_at": "06-11-2026 15:25:03",
        "decided_by": null,
        "waiting_since": "06-11-2026 15:25:03",
        "current_level_sla_days": 3,
        "current_level_due_at": "11-11-2026 15:25:03",
        "current_level_status": "on_track"
      },
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
        "current_level_status": "on_track"
      },
      {
        "id": "fc470e8d-abb3-46f9-b33e-7b294a73f46a",
        "source": "pep",
        "action_plan_type": "artificial_lift",
        "well_test_action": null,
        "activity_type": "installation",
        "well": {
          "id": "c326ae00-a049-47fd-95c6-11adcd170531",
          "name": "WF-PRD08"
        },
        "department": {
          "id": "Subsurface Development Area 1",
          "name": "Subsurface Development Area 1"
        },
        "assigned_department": "Production Operations",
        "approval_status": "modify_returned",
        "work_order_number": "0012/WO/SDA1/2026",
        "cycle_no": 1,
        "path": "modify",
        "current_level": null,
        "total_level": null,
        "start_date": "19-11-2026",
        "end_date": "21-11-2026",
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
        "submitted_at": "09-11-2026 11:10:39",
        "decided_by": {
          "id": "0b000000-0000-0000-0000-000000000406",
          "full_name": "PHI PO"
        },
        "waiting_since": "09-11-2026 11:11:54",
        "current_level_sla_days": 3,
        "current_level_due_at": "12-11-2026 11:11:54",
        "current_level_status": "on_track"
      }
    ],
    "page": 1,
    "page_size": 10,
    "total": 6
  },
  "process_time": "2303.45ms",
  "status": "success",
  "code": "00",
  "message": "Get action plan need action succeed"
}
```

_Arrays cut to 3 items; original sizes: 6._

### 66. Review modify, phi.approver on level 1 (plan H)

User `phi.approver`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/944010e4-abaa-4850-9923-9dde72f2ba8c/review" \
  -H "Authorization: Bearer $APPROVER" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "modify",
  "remarks": "extend 3 days",
  "proposed": {
    "action_plan_type": "well_test",
    "well_id": "cb09c057-dd3f-4bef-a9a3-8a91190ea8e1",
    "start_date": "19-11-2026",
    "end_date": "24-11-2026",
    "pic_ids": [
      "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
    ],
    "well_test": {
      "well_test_action": "schedule",
      "well_test_type": "production_test",
      "assigned_department": "Production Operations",
      "contract_number": "CTR-PO/2026/001"
    }
  },
  "approvers": [
    {
      "level": 1,
      "user_id": [
        "0b000000-0000-0000-0000-00000000040a"
      ]
    },
    {
      "level": 2,
      "user_id": [
        "0b000000-0000-0000-0000-000000000409"
      ]
    }
  ],
  "execution_department_id": "Production Operations",
  "execution_pic_id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
}'
```

Response 200:

```json
{
  "data": {
    "action_plan_id": "944010e4-abaa-4850-9923-9dde72f2ba8c",
    "source": "pep",
    "work_order_number": "0029/WO/SDA1/2026",
    "approval_status": "modify_in_approval",
    "cycle_no": 1,
    "path": "modify",
    "current_level": 1,
    "total_levels": 2
  },
  "process_time": "2968.88ms",
  "status": "success",
  "code": "00",
  "message": "Review action plan succeed"
}
```

### 67. Read: detail, can approve level 1 (plan H)

User `phi.approver`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/pep/944010e4-abaa-4850-9923-9dde72f2ba8c" \
  -H "Authorization: Bearer $APPROVER"
```

Response 200:

```json
{
  "data": {
    "id": "944010e4-abaa-4850-9923-9dde72f2ba8c",
    "action_plan_type": "well_test",
    "status": "upcoming",
    "start_date": "19-11-2026",
    "end_date": "21-11-2026",
    "notes": "",
    "ownership": null,
    "pic": null,
    "pic_ids": [
      {
        "id": "C95F325F-4FDB-420E-AC52-E54DC332AF2B",
        "name": "R3 Test amin",
        "email": "r3test.amin@yopmail.com"
      }
    ],
    "created_at": "09-11-2026 13:28:16",
    "created_by": {
      "id": "0B000000-0000-0000-0000-00000000040A",
      "full_name": "PHI Approver"
    },
    "updated_at": "09-11-2026 13:28:29",
    "updated_by": {
      "id": "0B000000-0000-0000-0000-00000000040A",
      "full_name": "PHI Approver"
    },
    "choke": null,
    "sonolog": null,
    "well_test": {
      "gas": 0,
      "oil": 0,
      "well_test_action": "schedule",
      "contract_id": "",
      "contract_number": "CTR-PO/2026/001",
      "contract_no": "",
      "contract_title": "",
      "contractor": null,
      "well_test_type": {
        "id": "production_test",
        "name": "Regular Well Test"
      },
      "planned_duration_hours": 0,
      "actual_planned_hours": 0,
      "tank_number": "",
      "start_date_time": "",
      "end_date_time": "",
      "u_press": 0,
      "chp": 0,
      "choke": 0,
      "whfp": 0,
      "flp": 0,
      "gi": 0,
      "liquid": 0,
      "water": 0,
      "bsw": 0,
      "sand": 0
    },
    "artificial_lift": null,
    "others": null,
    "approval_status": "modify_in_approval",
    "requires_approval": true,
    "work_order_number": "0029/WO/SDA1/2026",
    "assigned_department": "Production Operations",
    "execution_department_id": null,
    "execution_pic": null,
    "can_review": false,
    "can_approve": true,
    "can_reject": true,
    "approval": {
      "cycle_no": 1,
      "path": "modify",
      "current_level": 1,
      "total_levels": 2
    }
  },
  "process_time": "1544.79ms",
  "status": "success",
  "code": "00",
  "message": "Get action plan PEP detail succeed"
}
```

### 68. Approve level 1 (plan H)

User `phi.approver`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/944010e4-abaa-4850-9923-9dde72f2ba8c/approval/approve" \
  -H "Authorization: Bearer $APPROVER" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "ok L1"
}'
```

Response 200:

```json
{
  "data": {
    "action_plan_id": "944010e4-abaa-4850-9923-9dde72f2ba8c",
    "source": "pep",
    "work_order_number": "0029/WO/SDA1/2026",
    "approval_status": "modify_in_approval",
    "cycle_no": 1,
    "path": "modify",
    "current_level": 2,
    "total_levels": 2
  },
  "process_time": "2308.65ms",
  "status": "success",
  "code": "00",
  "message": "Approve action plan succeed"
}
```

### 69. Approve level 2, proposal applied (plan H)

User `phi.superadmin`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/944010e4-abaa-4850-9923-9dde72f2ba8c/approval/approve" \
  -H "Authorization: Bearer $MGR2" \
  -H 'Content-Type: application/json' \
  -d '{
  "remarks": "ok L2"
}'
```

Response 200:

```json
{
  "data": {
    "action_plan_id": "944010e4-abaa-4850-9923-9dde72f2ba8c",
    "source": "pep",
    "work_order_number": "0029/WO/SDA1/2026",
    "approval_status": "approved",
    "cycle_no": 1,
    "path": "modify",
    "current_level": null,
    "total_levels": 2
  },
  "process_time": "3577.48ms",
  "status": "success",
  "code": "00",
  "message": "Approve action plan succeed"
}
```

### 70. Detail after approval: end_date changed (plan H)

User `phi.approver`. Expected 200, actual 200: **PASS**

```bash
curl -X GET "$API/well-surveilence/action-plans/pep/944010e4-abaa-4850-9923-9dde72f2ba8c" \
  -H "Authorization: Bearer $APPROVER"
```

Response 200:

```json
{
  "data": {
    "id": "944010e4-abaa-4850-9923-9dde72f2ba8c",
    "action_plan_type": "well_test",
    "status": "upcoming",
    "start_date": "19-11-2026",
    "end_date": "24-11-2026",
    "notes": "",
    "ownership": null,
    "pic": null,
    "pic_ids": [
      {
        "id": "C95F325F-4FDB-420E-AC52-E54DC332AF2B",
        "name": "R3 Test amin",
        "email": "r3test.amin@yopmail.com"
      }
    ],
    "created_at": "09-11-2026 13:28:16",
    "created_by": {
      "id": "0B000000-0000-0000-0000-00000000040A",
      "full_name": "PHI Approver"
    },
    "updated_at": "09-11-2026 13:28:39",
    "updated_by": {
      "id": "0B000000-0000-0000-0000-000000000409",
      "full_name": "PHI Super Admin"
    },
    "choke": null,
    "sonolog": null,
    "well_test": {
      "gas": 0,
      "oil": 0,
      "well_test_action": "schedule",
      "contract_id": "",
      "contract_number": "CTR-PO/2026/001",
      "contract_no": "",
      "contract_title": "",
      "contractor": null,
      "well_test_type": {
        "id": "production_test",
        "name": "Regular Well Test"
      },
      "planned_duration_hours": 0,
      "actual_planned_hours": 0,
      "tank_number": "",
      "start_date_time": "",
      "end_date_time": "",
      "u_press": 0,
      "chp": 0,
      "choke": 0,
      "whfp": 0,
      "flp": 0,
      "gi": 0,
      "liquid": 0,
      "water": 0,
      "bsw": 0,
      "sand": 0
    },
    "artificial_lift": null,
    "others": null,
    "approval_status": "approved",
    "requires_approval": true,
    "work_order_number": "0029/WO/SDA1/2026",
    "assigned_department": "Production Operations",
    "execution_department_id": "Production Operations",
    "execution_pic": {
      "id": "A5CE36A8-4BD8-456B-B8B9-D8B438025676",
      "name": "R3 Test amin",
      "email": "r3test.amin@yopmail.com"
    },
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
  "process_time": "1260.89ms",
  "status": "success",
  "code": "00",
  "message": "Get action plan PEP detail succeed"
}
```

### 71. Review approve (plan I)

User `phi.approver`. Expected 200, actual 200: **PASS**

```bash
curl -X POST "$API/well-surveilence/action-plans/phss/da6ff3a6-61c0-4c9e-bd96-2a7660bf56e7/review" \
  -H "Authorization: Bearer $APPROVER" \
  -H 'Content-Type: application/json' \
  -d '{
  "decision": "approve",
  "execution_department_id": "Production Operations",
  "execution_pic_id": "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
}'
```

Response 200:

```json
{
  "data": {
    "action_plan_id": "da6ff3a6-61c0-4c9e-bd96-2a7660bf56e7",
    "source": "phss",
    "work_order_number": "0030/WO/SDA1/2026",
    "approval_status": "approved",
    "cycle_no": 1,
    "path": "approve",
    "current_level": null,
    "total_levels": null
  },
  "process_time": "1450.95ms",
  "status": "success",
  "code": "00",
  "message": "Review action plan succeed"
}
```

## 10. Department without a WO short name

### 72. Submit well test by a user outside the WO short-name config

User `phi.po`. Expected 400, actual 400: **PASS**

Plans that need approval still require a WO short name. Production Operations has none in `work_order_department_short_names`.

```bash
curl -X POST "$API/well-surveilence/action-plans/pep/submit" \
  -H "Authorization: Bearer $PO" \
  -H 'Content-Type: application/json' \
  -d '{
  "action_plan_type": "well_test",
  "well_id": "e6c38414-0168-4a33-a612-93d9a4d4d679",
  "start_date": "19-11-2026",
  "end_date": "21-11-2026",
  "pic_ids": [
    "a5ce36a8-4bd8-456b-b8b9-d8b438025676"
  ],
  "well_test": {
    "well_test_action": "schedule",
    "well_test_type": "production_test",
    "assigned_department": "Production Operations",
    "contract_number": "CTR-PO/2026/001"
  }
}'
```

Response 400:

```json
{
  "process_time": "721.28ms",
  "status": "failed",
  "code": "01",
  "message": "Department 'Production Operations' has no work order short name in work_order_department_short_names"
}
```
