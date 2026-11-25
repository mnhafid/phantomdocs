# Four SYSROLE types per department (proposal, not yet created)

Part of [PHI-2119](README.md). Replaces the Leader / Member / Guest / Approval split in
[04-SYSROLES-TO-CREATE.md](04-SYSROLES-TO-CREATE.md) (D16) with four types. Draft seq lists are in
[10-four-type-sysrole-acl.csv](10-four-type-sysrole-acl.csv). Status: **proposal, needs approval before anything is created in Retina.**

## The four types

| Type | Name pattern | Holds |
|---|---|---|
| **Guest (View)** | `{Dept} - Read - Guest` | Every read-class seq of the department's modules. No write, no approval, no access/config seqs. |
| **Modify** | `{Dept} - Modify - Member` | Guest + the department's modify seqs (create, update, delete, submit, etc.). No approval, no access/config seqs. |
| **Approval** | `{Dept} - Approval - Member` | Guest + the department's approval seqs (for example Project Approval, Contract Approval, Work Order Approval, and SDA Action Plan approve/reject). No modify. |
| **Admin** | `{Dept} - Admin - Leader` | Modify + data configuration seqs: Custom Configuration (128–131). User, Role, Approval Route and approver seqs are **not** in Admin; they stay with Super Admin as today. |

Admin uses level `Leader`, so it is a regulator under D14. GM and SM are Leader too (D23), as Super Admin is today.

## Access seqs (Super Admin only)

| Group | Seqs | Why it stays with Super Admin |
|---|---|---|
| User | 1 Read, 2 Set User Role, 3 Update, 4 Create | Assigns roles and edits users |
| Role | 5 Read, 6 Update, 7 Delete, 8 Create, 9 Read Permissions, 10 Set Permissions | Changes what every role can do |
| Approval Route | 119 Read, 120 Update, 121 Delete, 122 Create | Changes who approves what |
| Approver updates | 117 Update Project Approver, 118 Update Contract Approver, 123 Update Work Order Approver | Changes approvers |

**Current state, from the existing CSV:** every department's Modify and Leader sets already contain most of these.
Projects `Modify - Member` holds User 1–4, Role 5–10 and Custom Configuration, so a plain Member can assign roles
and set permissions today. The four-type split removes these from Guest, Modify and Approval.

## Numbers per department (from the existing CSV plus the 162/163 SDA addition)

| Department | Guest | Modify | Approval | Admin | Notes |
|---|---|---|---|---|---|
| Projects | 26 | 116 | 30 | 120 | Approval adds Project, Contract and Work Order approvals |
| Operations & Surface Facilities | 26 | 116 | 30 | 120 | Admin adds Custom Configuration only |
| Production Operations | 16 | 61 | 20 | 65 | No Project Approval (54), no Project modules. Approval includes 161 (PO review) |
| Subsurface Development Area 1 | 1 (153, PHSS) | 4 | 3 | 8 | Approval = 153 + 162 + 163. Admin adds 128–131 (new grant) |
| Subsurface Development Area 2 | 1 (155, PEP) | 4 | 3 | 8 | Approval = 155 + 162 + 163. Admin adds 128–131 (new grant) |

Approval for SDA uses 153 (SDA1, PHSS) or 155 (SDA2, PEP) as the read seq, plus 162/163.

Totals: 20 SYSROLEs, the same count as before. Full seq lists are in the CSV.

## Changes from today's dev data

1. **SDA dev ACL does not match the CSV.** Dev data from the request summary:
   - SDA1 (dev) holds 155 and 156, which are the PEP seqs for SDA2. The CSV has 154.
   - SDA2 (dev) holds 153 and 154, which are the PHSS seqs for SDA1. The CSV has 156.
   - Both hold 128, 138, 140 and 159, which are not in the CSV. Seq 128 is Custom Configuration Read.
   
   This looks like a data error that crosses departments. Check before adding anything else.
2. **The SDA request uses names without a level** (`Subsurface Development Area 1`). D1 requires `Department - name - level`. The request must target the new names above.
3. **The request SQL is not runnable.** Lines 2 to 4 are garbled: broken column lists and a missing VALUES tuple. The column list (ACLID, URLPATH, COMPONENTID, HIDDEN, READONLY, DISABLED, SEQ, PAGE) also does not match the R3 ACL sample rows (ACLID, SYSNAME, SYSROLE, URLPATH, COMPONENTID, PAGE, SEQ_ACL). The R3 team should write the insert.
4. **Seq 162 and 163 existence.** The summary says they exist in dev, but also says they "must not exist yet". Confirm they exist before creating roles that depend on them.

## Decisions (answered)

| # | Decision | Answer |
|---|---|---|
| 1 | Admin scope | Data configuration only (128–131). Super Admin keeps User, Role and approval-route access, as today. |
| 2 | Regulator | Admin is level `Leader`. GM and SM are Leader too, as Super Admin is today. |
| 3 | Naming | `Read - Guest`, as in D16. |
| 4 | SDA Guest | 153 for SDA1 (PHSS), 155 for SDA2 (PEP). |

## Open

1. **Action Plan 162/163 in other departments.** The request only grants them to SDA. Confirm whether Projects, Operations or Production approvers need them.
2. **Five seqs without a privilege name** (138, 140, 141, 142, 144) stay out of every set, as in 04-SYSROLES-TO-CREATE.md.

## Action Plan permissions 161, 162, 163

All three are in group 30 "Action Plan Approval" (`seed_action_plan_approval.sql`). The API reads them from the caller's Retina ACL.

| Seq | Name | What it does |
|---|---|---|
| **161** | Review Action Plan | PO review pool. The holder reviews a plan in `waiting_review`: approve, modify or reject. The config `action_plan_review_permission_id` is 161. Dev holds it on the `PO` SYSROLE (`phi.po`, `r3test.po`). It is a PO reviewer permission, not an approver one. |
| **162** | Approve Action Plan | Approves the pending level of a **Modify** round. The SSDP creator's own last Modify level is exempt. |
| **163** | Reject Action Plan | Rejects the pending level of a Modify or Reject round, and gates the approve-reject and approve-modify endpoints. |

**Why 162 and 163 are approval-class.** They are the decision seqs for approvers at each level. So they go in the
`Approval - Member` SYSROLE, not `Modify - Member`. Decision 6 from the earlier draft is answered by this.

**Where 161 goes (approved).** It is a reviewer seq for the PO pool, so it belongs with the department that reviews Action Plans. Dev uses SYSROLE `PO` (prod name unverified; the release note says `Production Operations`). Proposal: add 161 to `Production Operations - Approval - Member`. The PO users (`r3test.po`, `phi.po`) then hold it through that SYSROLE, with no separate role.

## Order of work (after approval)

1. Update `04-SYSROLES-TO-CREATE.md` and D16 (four types replace four).
2. Check and fix the SDA dev ACL mismatch.
3. R3 team creates the 20 SYSROLEs and their seqs, using the approved CSV.
4. Verify with `GET /api/v1/users/permissions` for one user per type.
5. Backend: update the regulator and department tests that name `Modify - Leader` (D14, D23).
