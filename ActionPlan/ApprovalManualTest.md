# Action Plan Approval — Manual Test Scenarios (PHI-2243)

_2026-11-06. Run the top of the stack: `feat/phi-2242-action-plan-al-whc` (worktree `.worktrees/phi-2242-ap-al-whc`), on top of #1432 and #1409.
Order follows the priority: 1 Approval Route · 2 User permission · 3 CRUD · 4 Notification._

## 0. Setup (once)

### 0.1 Database (shared dev DB — your call)
1. Migration `20261102150929_AddActionPlanApproval` (or the DDL in `approval-route-action-plan.md` item 1).
2. Seeds from the **db worktree**: `DataAccess/Database/seed_action_plan_approval.sql` and `seed_action_plan_custom_configs.sql`.
3. Check: `SELECT id, name, permission_group_id FROM permissions WHERE id BETWEEN 161 AND 163;` → 3 rows, group 30.

### 0.2 Privileges 161 / 162 / 163 for the mock users
The API gates read the caller's **Retina ACL**. On dev (mock login) that ACL comes from `mock_auth_sessions` (stage `session`,
`$.roleInformation.role[*].acl`). This appends the SEQs to **every role** of the test users (DBeaver; idempotent):

```sql
UPDATE m
SET payload = JSON_MODIFY(m.payload, CONCAT('append $.roleInformation.role[', r.[key], '].acl'),
        JSON_QUERY(CONCAT('{"COMPONENTID":"PHANTOM_Action_Plan_Approval","URLPATH":"Action Plan Approval","HIDDEN":0,"READONLY":0,"DISABLED":0,"PAGE":"', s.page, '","SEQ":', s.seq, '}')))
FROM mock_auth_sessions m
CROSS APPLY OPENJSON(m.payload, '$.roleInformation.role') r
CROSS APPLY (VALUES (161, 'Review Action Plan'), (162, 'Approve Action Plan'), (163, 'Reject Action Plan')) s (seq, page)
WHERE m.stage = 'session'
  AND m.username IN ('phi.po', 'phi.superadmin', 'phi.sda1', 'phi.generalmanager')
  AND NOT (s.seq = 161 AND m.username IN ('phi.sda1', 'phi.generalmanager'))
  AND JSON_QUERY(r.value, '$.acl') NOT LIKE CONCAT('%"SEQ": ', s.seq, '}%')
  AND JSON_QUERY(r.value, '$.acl') NOT LIKE CONCAT('%"SEQ":', s.seq, '}%');
```
> SQL Server updates a row once per statement: **run it until it reports 0 rows** (each run appends the next missing SEQ / role).
> The ACL is cached in Redis (`PHI:RETINA:<username>`): flush those keys or wait for the TTL before testing.

**Check (must pass before anything else):** `GET /api/v1/users/permissions` per user:

| User | Department | Must contain |
|---|---|---|
| `phi.po` | Production Operations | 161, 162, 163 |
| `phi.superadmin` | Project (Super Admin) | 161, 162, 163 |
| `phi.generalmanager` | Project (GM) | 162, 163 |
| `phi.sda1` | Subsurface Development Area 1 | 162, 163 |
| `phi.sda2` | Subsurface Development Area 2 | none (negative tests) |

If a user misses them, the ACL resolver picked another role / SYSROLE for that user — tell me which one.

### 0.3 Run the API + shell helpers
```bash
cd .worktrees/phi-2242-ap-al-whc/src-be/WebApi && dotnet run   # http://localhost:5071
```
```bash
API=http://localhost:5071/api/v1
PW='<PhantomDbConnection password from appsettings.json>'
tok() { sqlcmd -S 185.250.38.82 -U phantom_dev_user -P "$PW" -d phantomdb -C -h -1 -W -y 0 \
  -Q "SET NOCOUNT ON; SELECT TOP 1 payload FROM mock_auth_sessions WHERE stage='token' AND username='$1';" \
  | python3 -c "import sys,json;print(json.loads(sys.stdin.read().strip())['access_token'])"; }
SSDP=$(tok phi.sda1)          # submitter (SDA1 -> WO .../WO/SDA1/...) and level-3 SSDP approver
PO=$(tok phi.po)              # PO reviewer (161) and level 1
MGR2=$(tok phi.superadmin)    # level 2 (+ creates the routes)
GM=$(tok phi.generalmanager)  # 162/163 but never put on a level
NOPRIV=$(tok phi.sda2)        # no 161/162/163
PO_ID=0b000000-0000-0000-0000-000000000406
MGR2_ID=0b000000-0000-0000-0000-000000000409
SSDP_ID=0b000000-0000-0000-0000-000000000407
FIELD_PIC_ID=a5ce36a8-4bd8-456b-b8b9-d8b438025676   # r3test.amin, Production Operations (execution PIC)
OSF_USER_ID=0b000000-0000-0000-0000-000000000405    # phi.osf (wrong department for the PIC check)
WELL_A=2d9549dd-fcfc-4e1d-83da-893144b49889; WELL_B=553295e4-9d78-4332-a426-ec2046876d6f; WELL_C=e4a99b01-7a81-415f-828e-0372d142c0a3
START=$(date -v+10d +%d-%m-%Y); END=$(date -v+12d +%d-%m-%Y); NEWEND=$(date -v+15d +%d-%m-%Y); YEAR=$(date +%Y)
post() { curl -s -X POST "$API$2" -H "Authorization: Bearer $1" -H 'Content-Type: application/json' -d "$3" | python3 -m json.tool; }
get()  { curl -s "$API$2" -H "Authorization: Bearer $1" | python3 -m json.tool; }
wt()   { echo "{\"action_plan_type\":\"well_test\",\"well_id\":\"$1\",\"start_date\":\"$START\",\"end_date\":\"$2\",\"pic_ids\":[\"$FIELD_PIC_ID\"],\"well_test\":{\"well_test_action\":\"schedule\",\"well_test_type\":\"production_test\",\"assigned_department\":\"Production Operations\",\"contract_number\":\"CTR-PO/2026/001\"}}"; }
lvl()  { echo "[{\"level\":1,\"user_id\":[\"$PO_ID\"]},{\"level\":2,\"user_id\":[\"$MGR2_ID\"]},{\"level\":3,\"user_id\":[\"$SSDP_ID\"]}]"; }
lvl2() { echo "[{\"level\":1,\"user_id\":[\"$PO_ID\"]},{\"level\":2,\"user_id\":[\"$MGR2_ID\"]}]"; }
P=/well-surveilence/action-plans/pep
```
If a submit answers "… already exists" for a well, an old well test sits on it — use another PEP well
(`SELECT TOP 10 id, well_name FROM wells WHERE working_area='pep' AND deleted_at IS NULL`).

---

## 1. Approval Route

| # | Scenario | Call | Expect |
|---|---|---|---|
| R1 | Unknown action plan category | create `action_plan_pep_well_test_modify` | 400, lists the 4 categories |
| R2 | Create PEP Well Test route (3 levels) | create `Action_Plan_PEP_Well_Test` | 200, stored as `action_plan_pep_well_test` |
| R3 | Create PHSS Artificial Lift route | create `action_plan_phss_artificial_lift` | 200 |
| R4 | PO sees Data Config's routes | `/approval-routes/all` as PO | both routes listed |
| R5 | Prefill on a plan (after S3.4) | `GET $P/$A/approval-route` | `category: action_plan_pep_well_test`, levels 1/2/3 with `user_id[]`, `sla_days` 2 / 2 / 3 (default) |
| R6 | Prefill without a route | a PEP artificial-lift plan (no route created) | `levels: []` |

```bash
post "$MGR2" /approval-routes '{"title":"x","description":"x","category":"action_plan_pep_well_test_modify","approvers":[{"level":1,"users":[{"id":"'$PO_ID'"}]}]}'
post "$MGR2" /approval-routes '{"title":"Action Plan Well Test - PEP","description":"PO Mgr 1 > Mgr 2 > SSDP 1","category":"Action_Plan_PEP_Well_Test",
 "approvers":[{"level":1,"sla_days":2,"users":[{"id":"'$PO_ID'"}]},{"level":2,"sla_days":2,"users":[{"id":"'$MGR2_ID'"}]},{"level":3,"users":[{"id":"'$SSDP_ID'"}]}]}'
post "$MGR2" /approval-routes '{"title":"Action Plan Artificial Lift - PHSS","description":"PO Mgr 1 > Mgr 2 > SSDP 2","category":"action_plan_phss_artificial_lift",
 "approvers":[{"level":1,"users":[{"id":"'$PO_ID'"}]},{"level":2,"users":[{"id":"'$MGR2_ID'"}]}]}'
get "$PO" "/approval-routes/all?status=active&category=action_plan_pep_well_test|action_plan_phss_artificial_lift"
get "$PO" $P/$A/approval-route      # after S3.4
```

## 2. User permission (Retina ACL 161 / 162 / 163)

Run U1–U2 after S3.4, U3–U5 after S3.10.

| # | Scenario | Expect |
|---|---|---|
| U1 | `phi.sda2` (no 161) reviews plan A | 403 "You are not allowed to review action plans" |
| U2 | `phi.sda2` opens the review inbox | 403 |
| U3 | `phi.sda2` (no 162) approves plan B | 403 "You are not allowed to approve action plans" |
| U4 | `phi.generalmanager` (162, not on the level) approves B | 403 "You are not an approver of level 1 …" |
| U5 | `phi.generalmanager` approval inbox | 200, `items: []` |

```bash
post "$NOPRIV" $P/$A/review '{"decision":"approve","execution_department_id":"Production Operations","execution_pic_id":"'$FIELD_PIC_ID'"}'
get  "$NOPRIV" "/well-surveilence/action-plans/approvals/need-action?stage=review"
post "$NOPRIV" $P/$B/approval/approve '{}'
post "$GM"     $P/$B/approval/approve '{}'
get  "$GM"     "/well-surveilence/action-plans/approvals/need-action?stage=approval"
```

## 3. CRUD for action plan

### 3a. Submit + WO number
| # | Scenario | Expect |
|---|---|---|
| S3.1 | Next WO number as SSDP | `{ sequence_number: "000N", wo_number: "000N/WO/SDA1/<year>" }` |
| S3.2 | Next WO as PO (no WO mapping) | 400 "Department 'Production Operations' has no work order short name …" |
| S3.3a | Choke with `wo_number` = previewed | 200 `approved`, that WO |
| S3.3b | Same `wo_number` again | 400 "… already used, please get the next work order number again" |
| S3.3c | `wo_number` of SDA2 | 400 "wo_number must be NNNN/WO/SDA1/<year>" |
| S3.3d | Well test without `well_test.assigned_department` | 400 "assigned_department (Assign to) is required …" |
| S3.4 | Well tests A, B, C (no `wo_number`) | each `waiting_review`, WO numbers run on |

```bash
get "$SSDP" /well-surveilence/action-plans/next-wo-number
get "$PO"   /well-surveilence/action-plans/next-wo-number
WO=<data.wo_number of the first call>
post "$SSDP" $P/submit '{"action_plan_type":"choke","well_id":"'$WELL_A'","wo_number":"'$WO'","start_date":"'$START'","end_date":"'$END'","choke":{"gas":10,"oil":20}}'
post "$SSDP" $P/submit '{"action_plan_type":"choke","well_id":"'$WELL_B'","wo_number":"'$WO'","start_date":"'$START'","end_date":"'$END'","choke":{"gas":10,"oil":20}}'
post "$SSDP" $P/submit '{"action_plan_type":"choke","well_id":"'$WELL_B'","wo_number":"0999/WO/SDA2/'$YEAR'","start_date":"'$START'","end_date":"'$END'","choke":{"gas":10,"oil":20}}'
post "$SSDP" $P/submit '{"action_plan_type":"well_test","well_id":"'$WELL_A'","start_date":"'$START'","end_date":"'$END'","well_test":{"well_test_action":"schedule"}}'
post "$SSDP" $P/submit "$(wt $WELL_A $END)"   # -> A
post "$SSDP" $P/submit "$(wt $WELL_B $END)"   # -> B
post "$SSDP" $P/submit "$(wt $WELL_C $END)"   # -> C
A=<id>; B=<id>; C=<id>
```

### 3b. List / detail / inbox
| # | Scenario | Expect |
|---|---|---|
| S3.5 | List of well A (default) | every submitted plan: the choke (`approved`, `progress` = date status) and A (`waiting_review`, `progress: routing`); items carry `approval_status`, `work_order_number` |
| S3.6 | Same list with `approval_status=waiting_review` | plan A |
| S3.7 | Detail of A | `approval_status: waiting_review`, `requires_approval: true`, `work_order_number`, `assigned_department`, `well_test.contract_number = CTR-PO/2026/001`, `execution_pic: null`; as PO `can_review: true`, `can_approve: false`, `can_reject: false`; as `phi.sda2` all three false |
| S3.8 | Review inbox as PO | A, B, C, `current_level_sla_days: 3`, `current_level_status`, `assigned_department` |

```bash
get "$PO" "/well-surveilence/$WELL_A/action-plans/pep"
get "$PO" "/well-surveilence/$WELL_A/action-plans/pep?approval_status=waiting_review"
get "$PO" $P/$A
get "$PO" "/well-surveilence/action-plans/approvals/need-action?stage=review"
```

### 3c. Flow 1 — PO approve (plan A)
| # | Scenario | Expect |
|---|---|---|
| S3.9a | Approve without assignment | 400 "execution_department_id is required to approve a well test" |
| S3.9b | PIC from another department | 400 "… is not an active user of department …" |
| S3.9c | Approve with PO department + PO PIC | 200 `approved`; detail `execution_pic` = r3test.amin; list `progress` is now the date status, not `routing` |

```bash
post "$PO" $P/$A/review '{"decision":"approve"}'
post "$PO" $P/$A/review '{"decision":"approve","execution_department_id":"Production Operations","execution_pic_id":"'$OSF_USER_ID'"}'
post "$PO" $P/$A/review '{"decision":"approve","execution_department_id":"Production Operations","execution_pic_id":"'$FIELD_PIC_ID'"}'
get  "$PO" $P/$A
```

### 3d. Flow 2 — PO modify through 3 levels (plan B)
| # | Scenario | Expect |
|---|---|---|
| S3.10a | Modify a well test without assignment | 400 "execution_department_id is required …" |
| S3.10b | Modify changing the action type | 400 "proposed may not change action_plan_type" |
| S3.10 | Modify end date + assignment | `modify_in_approval`, `current_level 1`, `total_levels 3` |
| S3.11 | Approval inbox: PO (L1) sees B; `phi.superadmin` (L2) not yet | |
| S3.12 | Detail of B before the last level | `end_date` unchanged; `approval: { cycle_no: 1, path: modify, current_level: 1, total_levels: 3 }`; as PO `can_approve` + `can_reject` true, `can_review` false; as `phi.generalmanager` all false |
| S3.13 | L1 → L2 → L3 approve | `current_level` 2, 3, then `approved` |
| S3.14 | Detail, diff, history | `end_date` = NEWEND, `execution_pic` set; diff `changes`: `end_date`, `execution_department_id`, `execution_pic_id`; history + diff dates are `dd-MM-yyyy HH:mm:ss` |

```bash
post "$PO" $P/$B/review '{"decision":"modify","proposed":'"$(wt $WELL_B $NEWEND)"',"approvers":'"$(lvl)"'}'
post "$PO" $P/$B/review '{"decision":"modify","proposed":{"action_plan_type":"choke"},"approvers":'"$(lvl)"',"execution_department_id":"Production Operations","execution_pic_id":"'$FIELD_PIC_ID'"}'
post "$PO" $P/$B/review '{"decision":"modify","remarks":"extend 3 days","proposed":'"$(wt $WELL_B $NEWEND)"',"approvers":'"$(lvl)"',"execution_department_id":"Production Operations","execution_pic_id":"'$FIELD_PIC_ID'"}'
get  "$PO"   "/well-surveilence/action-plans/approvals/need-action?stage=approval"
get  "$MGR2" "/well-surveilence/action-plans/approvals/need-action?stage=approval"
get  "$PO"   $P/$B
post "$PO"   $P/$B/approval/approve '{"remarks":"ok L1"}'
post "$MGR2" $P/$B/approval/approve '{}'
post "$SSDP" $P/$B/approval/approve '{}'
get  "$PO"   $P/$B
get  "$PO"   $P/$B/modification-diff
get  "$PO"   $P/$B/approval-history
```

### 3e. Flow 3 — returned, then reject (plan C)
| # | Scenario | Expect |
|---|---|---|
| S3.15a | Approvers with a gap / same user on 2 levels | 400 |
| S3.15 | Modify (3 levels) | `modify_in_approval` |
| S3.16 | L1 rejects **without remarks** (optional) | `modify_returned` |
| S3.17 | PO tries to approve the original | 400 (only modify / reject now) |
| S3.18 | PO rejects (remarks mandatory) with 2 levels | `reject_in_approval`, `cycle_no 2` |
| S3.19 | L1, L2 approve | `rejected` |
| S3.20 | History | cycle 1 modify → returned; cycle 2 reject → rejected, `previous_cycle_id` = cycle 1 |
| S3.21 | Submit a new well test on well C | 200 `waiting_review` (a rejected plan no longer blocks) |

```bash
post "$PO" $P/$C/review '{"decision":"reject","remarks":"x","approvers":[{"level":1,"user_id":["'$PO_ID'"]},{"level":3,"user_id":["'$MGR2_ID'"]}]}'
post "$PO" $P/$C/review '{"decision":"reject","remarks":"x","approvers":[{"level":1,"user_id":["'$PO_ID'"]},{"level":2,"user_id":["'$PO_ID'"]}]}'
post "$PO" $P/$C/review '{"decision":"modify","proposed":'"$(wt $WELL_C $NEWEND)"',"approvers":'"$(lvl)"',"execution_department_id":"Production Operations","execution_pic_id":"'$FIELD_PIC_ID'"}'
post "$PO" $P/$C/approval/reject '{}'
post "$PO" $P/$C/review '{"decision":"approve","execution_department_id":"Production Operations","execution_pic_id":"'$FIELD_PIC_ID'"}'
post "$PO" $P/$C/review '{"decision":"reject","remarks":"not needed","approvers":'"$(lvl2)"'}'
post "$PO"   $P/$C/approval/approve '{}'
post "$MGR2" $P/$C/approval/approve '{"remarks":"confirm reject"}'
get  "$PO"   $P/$C/approval-history
post "$SSDP" $P/submit "$(wt $WELL_C $END)"
```

### 3f. My Task / My Approval / Badge
| # | Scenario | Expect |
|---|---|---|
| M1 | My task list as PO after S3.4 | section `action_plan_review` holds A, B, C with `well_test_action`, `activity_type`, `assigned_department`, `due_date`, `days_overdue`; dates `dd-MM-yyyy` |
| M2 | My task list as `phi.sda2` (no 161) | `action_plan_review` empty |
| M3 | My approval list as PO after S3.10 (L1) | `action_plan_approval` holds B, `current_level: 1` |
| M4 | My approval list as `phi.superadmin` after S3.10 | B is not there until L1 approves |
| M5 | `approval_type=action_plan_review` on the list | only that section is filled |
| M6 | Badge as PO before and after S3.9c | the action plan count goes down by 1 |

```bash
get "$PO"     /my-task-list
get "$NOPRIV" /my-task-list
get "$PO"     /my-approval-list
get "$MGR2"   /my-approval-list
get "$PO"     "/my-approval-list?approval_type=action_plan_review"
get "$PO"     /my-task-badge
```

### 3g. Active = approved (alerts, widgets, well panel)
Only an `approved` plan counts as active. Auto-approved plans count at once.

| # | Scenario | Expect |
|---|---|---|
| W1 | Highlight / upcoming / event after S3.4 | A, B, C are not there |
| W2 | Same calls after S3.9c | A is there; B, C are not |
| W3 | Same calls after S3.13 | B is there, with the applied `end_date` |
| W4 | Same calls after S3.19 | rejected C is not there |
| W5 | Well panel action plan count of well B, before and after S3.13 | goes up by 1 only after the last level |
| W6 | Action plan alert | a plan still in approval raises no alert; check after the next alert run, once it is approved |

```bash
get "$PO" /wells/action-plans/highlight
get "$PO" /wells/action-plans/upcoming
get "$PO" /wells/action-plans/event
```

### 3h. Artificial lift WHC fields (submit and Modify)
Create the `action_plan_pep_artificial_lift` route first if R6 is done. A rule failure answers 400 and writes nothing.

| # | Scenario | Expect |
|---|---|---|
| H1 | WHC installation, rental, valid | 200 `waiting_review` (an approval trigger) |
| H2 | `whc_type: "x"` | 400 "artificial_lift.whc_type must be mobile or permanent" |
| H3 | `owned_by` missing | 400 "artificial_lift.owned_by must be rental or owned" |
| H4 | `compression_type: 2` | 400 "artificial_lift.compression_type must be 1 or 0.5" |
| H5 | `compression_type: 0.5`, `production: 0.8` | 400 "artificial_lift.production must be between 0 and the compression type (0.5)" |
| H6 | `production` missing | 200, detail `production: 0` |
| H7 | `rental` with `asset_number` | `asset_number` dropped, `contract_number` kept |
| H8 | `owned` with `contract_number` | `contract_number` dropped, `asset_number` kept |
| H9 | `pressure` sent | dropped, not stored |
| H10 | Method `pump`, WHC fields sent | auto-approved, WHC fields cleared |
| H11 | PO Modify of H1 with `production: 0.9`, no execution fields | `modify_in_approval` (assignment optional for AL); after the last level detail `production: 0.9` |
| H12 | PO Modify of H1 with `compression_type: 2` | 400, same rule as submit |
| H13 | PO Modify of H1 changing `method` | 400 "proposed may not change artificial_lift.method" |

```bash
al() { echo "{\"action_plan_type\":\"artificial_lift\",\"well_id\":\"$1\",\"start_date\":\"$START\",\"end_date\":\"$END\",\"pic_ids\":[\"$FIELD_PIC_ID\"],\"artificial_lift\":{\"activity_type\":\"installation\",\"action_mode\":\"installation_schedule\",\"method\":\"well_head_compressor\",\"assigned_department\":\"Production Operations\",$2}}"; }
RENTAL='"whc_type":"mobile","compression_type":1,"owned_by":"rental","contract_number":"CTR-PO/2026/014","cost_allocation":"WBS-Z9-0042"'
post "$SSDP" $P/submit "$(al $WELL_A "$RENTAL,\"production\":0.5")"   # -> H
post "$SSDP" $P/submit "$(al $WELL_B '"whc_type":"x","compression_type":1,"owned_by":"rental"')"
post "$SSDP" $P/submit "$(al $WELL_B '"whc_type":"mobile","compression_type":1')"
post "$SSDP" $P/submit "$(al $WELL_B '"whc_type":"mobile","compression_type":2,"owned_by":"rental"')"
post "$SSDP" $P/submit "$(al $WELL_B '"whc_type":"mobile","compression_type":0.5,"owned_by":"rental","production":0.8')"
post "$SSDP" $P/submit "$(al $WELL_C '"whc_type":"permanent","compression_type":0.5,"owned_by":"owned","contract_number":"dropped","asset_number":"AST-01","pressure":100')"
post "$PO"   $P/$H/review '{"decision":"modify","proposed":'"$(al $WELL_A "$RENTAL,\"production\":0.9")"',"approvers":'"$(lvl)"'}'
```
If a submit answers "… already exists" or overlaps, use another PEP well (see 0.3).

## 4. Notification

Check `GET /api/v1/notifications/mine?page=1&page_size=25` (title / message) for the user after the step.
The PO pool = **every active user of Production Operations** (incl. `phi.po`).

| # | After | User | Title | Message |
|---|---|---|---|---|
| N1 | S3.4 submit | `phi.po` (PO pool) | `Well Test Request` | `WO Number <wo> Well Test need Approval.` |
| N2 | S3.3a choke (auto-approved) | anyone | — | nothing |
| N3 | S3.9c PO approve A | `phi.sda1` | `Well Test In Progress` | `… has been approved and is in progress.` |
| N4 | S3.10 modify B | `phi.po` (L1) | `Modify Action Plan` | `… before returning to SSDP department.` |
| N5 | S3.13 L1 approve | `phi.superadmin` (L2) | `Modify Action Plan` | `… before returning to SSDP department.` |
| N6 | S3.13 L2 approve | `phi.sda1` (L3) | `Modify Action Plan` | `… has been modified by Production Operations and requires your approval.` |
| N7 | S3.13 L3 approve | `phi.sda1` (submitter) | `Well Test In Progress` | |
| N8 | S3.16 L1 rejects | `phi.po` (PO pool) | `Action Plan Returned` | `… was returned by <L1 name>. Please modify or reject it.` |
| N9 | S3.18 PO reject | `phi.po` (L1) | `Reject Action Plan` | `… rejection requires your approval and remarks.` |
| N10 | S3.19 last level | `phi.sda1` and `phi.po` | `Action Plan Rejected by Manager` | `WO Number <wo> Action Plan rejected` |

Every link: `{WebBaseUrl}/well-surveillance/pep?well_id=<well>&action_plan_id=<plan>`.

```bash
for t in "$PO" "$MGR2" "$SSDP"; do get "$t" "/notifications/mine?page=1&page_size=10"; done
```

## 5. DB checks (optional)
```sql
SELECT id, approval_status, requires_approval, work_order_number, current_cycle_id, assigned_department,
       execution_department_id, execution_pic_id, approved_at, rejected_at, end_date
FROM pep_action_plan WHERE submitted_at >= CAST(GETDATE() AS date) ORDER BY submitted_at;
SELECT action_plan_id, cycle_no, path, outcome, previous_cycle_id, approval_process_id FROM action_plan_approval_cycles ORDER BY action_plan_id, cycle_no;
SELECT reference_id, approval_flow, latest_approval_level, status FROM approval_processes WHERE approval_flow LIKE 'PEP Action Plan%';
SELECT TOP 30 user_id, title, message, created_at FROM notifications WHERE created_at >= CAST(GETDATE() AS date) ORDER BY created_at DESC;
```

## Not in this build
Backend list for `assigned_department` (the FE keeps its own list). Casbin route enforcement for 161 / 162 / 163 (the API gates read the Retina ACL).

## Results, 2026-11-06 (dev DB, stack top `0a0aa09e`, local API)
- **PEP:** all 89 checks pass (R, U, S3, M, W1-W4, N, H). 3 first showed FAIL because of the test script (PIC id letter case, list key `list`) and were confirmed by reading the response.
- **PHSS:** 15 of 15 pass (WO SDA2, Modify through 3 levels, WHC, Reject, notifications). SDA2 is the submitter here.
- **Not run:** W5 (well panel count), W6 (alerts), notification links.
- **Open:** `execution_pic.id` and `pic_ids[].id` come back UPPERCASE; other ids are lowercase.
- **Dev DB:** migration applied with a scoped script; `20261104020000_ChangeBoqDetailQuantityToFloat` is still pending and was not applied.
- **Test data left on dev:** PEP plans c360044d, f544bb7e, a4e036d9, 72564b5b, fd558192, bb912a73, 7a6d7ae6, bbde3ac9 · PHSS plans 95c00a6d, 672ab55c · routes cbb996ac (PEP WT), 7d0bd363 (PHSS AL).
