# New decisions from the team doc "Phantom Fase 2" (read 24 Nov)

Source: Google Doc "Phantom Fase 2", tab of Sprint 3 SSDP. Sections:
- "Work Order Lv 0 - Overview Work Order"
- "Work Order Lv 0 - Creating Work Order" (section "Approval Flow") and the "Master Data/Config" list under "Work Order Lv 0 - Modify - Reject"
- "Work Order Lv 1 - Modal Set Approval Flow"
- "Work Order Lv 1 - Approve & Create Disposition"
- "WO Lv 2 - Overview Work Order"
- 2 comments on "Layer 1" / "Layer 2" (20 Nov)

---

## 1. Who selects the approval flow

**The requestor selects the flow for the requestor department only.**
- In Create Work Order, the requestor selects one approval flow from the list in Data Config ("Approval Route").
  - If the flow does not exist, the requestor must make it first in "Approval Route".
- The flow has these steps:
  - Step 1 = Senior / Asst. Manager of the requestor department.
  - Step 2 = Manager of the requestor department.
- Before, the flow also had step 3 (the Senior of the target department). The team doc removes it: "jadinya gaada, pakai modal di level 1".

**The target department selects its own flow later.**
- The target department uses the new "Set Approval Flow" window on the WO Details page.
- When: the WO status is "Waiting Approval".
- Who can do it, both conditions:
  - a user of the department that the requestor selected in "Request To", and
  - a user who has the permission "set approval at level 1".
- The user selects one flow from Data Config. The window shows the approvers of each step. The flow is mandatory.
- On Submit, the system saves the flow on the WO and shows "Set work order approval flow succeed". Then the page shows the buttons "Modify" and "Reject".
- Use of this flow: the approval of a **Modify** and of a **Reject** in the target department.

**What changes for us**
- Our old proposal: the system finds the flow automatically (rules by department and category). Replaced: **people select the flow by hand.**
- The system does not copy all approvers at submit:
  - At submit, it copies the requestor department approvers.
  - When the target department sets its flow, it copies the target department approvers.

## 2. How the approval route is set up in Data Config

- One route category for each department: "Work Order - {Department}".
- Each route has 3 levels, and each level has 2 layers:
  - Level 0 (requestor): Layer 1 (approver 1, 2, 3, …) and Layer 2 (approver 1, …).
  - Level 1: Layer 1 and Layer 2.
  - Level 2: Layer 1 and Layer 2. The doc calls Level 2 "Target Department". Check this, because the MoM calls Level 2 the **transfer** department.

**The system does not check the position (comments of 20 Nov)**
- The system lets the admin select **any position** and **any department** as an approver.
- The rule is only an SOP (a work rule):
  - Layer 1 = Senior / Asst. Manager.
  - Layer 2 = Manager.
- Reasons in the comment:
  - Retina data can have errors.
  - It makes the system less complex.

**What changes for us**
- The system does not need a permission for each Layer to find the approvers. The route holds the names of the approvers.
- We still need a permission for "set approval at level 1" (and for create / read WO).
- Open: can the system skip Layer 1 when the requestor is a Senior? With no position check, the system cannot know this. Proposal: no automatic skip. The admin makes a route without Layer 1 for that case.

## 3. Schedule type for each department (WO Type Mapping)

Minimum: fixed in the code. Better: configurable.
- **Simple schedule:** WLI, Field PHSS, Field PEP RAM, Field PEP PE, PO Zona, Drilling.
- **Detailed schedule:** Project, OSF.

So the department sets the schedule type. The user does not select it.

## 4. Request To, Function and Category (Create Work Order)

| Request To | Shows | Function → Category |
|---|---|---|
| Drilling | no Category, no Function | – |
| OSF Z9 | Category | Heavy Equipment, AFA / Modification, Maintenance, "Inception" (= Inspection?), Others |
| PHSS Field | Category + Function | WO/WS and Facility Maintenance: Maintenance Field, Choke Adjustment, Well Test, Sonolog / BJP Update, Artificial Lift Update |
| PO Z9 | Category | Choke Adjustment, Artificial Lift Update, Artificial Lift Installation, Well Test |
| Project Z9 | Category | RTWS Installation, "Gas List" (= Gas Lift?) Installation, Plant Upgrading, Artificial Lift Installation, Facility Upgrade |
| Sangasanga / Sangatta / Tanjung Field | Category + Function | RAM: Maintenance Field, Modification · PE: Choke Adjustment, Sonolog / BJP Update, Artificial Lift Update, Updating Well Data · Production: (text cut in the export) |
| SDA 1 Z9, SDA 2 Z9 | no Category, no Function | – |
| WLI Z9 | Category | (text cut in the export) |

Other form rules:
- Urgency: Regular / High Priority.
- Attachments: max 5 files, 10 MB each. Formats: PDF, DOC, DOCX, XLS, XLSX, JPG, PNG.

## 5. Overview page

- 6 cards:
  - Total WO
  - Received WO
  - In Review
  - Submit WO
  - Rejected WO
  - Draft WO
- 2 tabs: Incoming Work Order and Outgoing Work Order.
- The "+ Create Work Order" button shows only on the Outgoing tab.
- Search: the table filters when the user types or presses Enter.
- Table, 11 columns:
  - Description (filter)
  - Status (filter)
  - Action ("Detail")
  - Recipient (filter)
  - Category (filter)
  - Field (filter)
  - Start Date (sort)
  - End Date (sort)
  - Created Date (sort)
  - Approve Date (sort; "-" when empty)
  - Remarks ("-" when empty)
- The Lv 2 "Overview Work Order" text is a copy of the Lv 0 text. There is no separate overview for the transfer department.

## 6. Approve and disposition (target department)

- Approve: a confirmation window says that the requestor gets a notification. After Approve:
  - The status becomes Approved.
  - Approve, Reject and Modify disappear.
  - "Transfer Work Order" and "Create Disposition" appear.
- Create Disposition window:
  - Work Type (mandatory). The allowed values depend on the department:
    - ABI/BD: only Projects and PO.
    - ABI/NBD: only OSF.
    - ABO Routine and ABO Non Routine: all departments.
  - Assign PIC Member (internal, mandatory).
  - Notes (optional).
- Send Disposition → status "Project Preparation", and the button "Create Project" appears.

---

## 7. Points to ask the team
1. **Wrong tab?** The "Set Approval Flow" text starts at the **Outgoing** tab. The target department sees the WO in the **Incoming** tab.
2. **Level 2 name:** the Data Config list calls Level 2 the "Target Department". The MoM calls it the department that gets a transferred WO. Which one is correct?
3. **The Approve button:** after Set Approval Flow, the page shows "Modify" and "Reject". Does "Approve" also show?
4. **Requestor is a Senior:** can Layer 1 of the requestor department be skipped? The system has no position check now.
5. **Copied text:** "Approve & Create Disposition" (second copy) and "Approve & Transfer Work Order" have the Set Approval Flow text pasted in. They have no content of their own yet.
6. **Spelling:** "Inception" (OSF) is probably "Inspection". "Gas List" (Project) is probably "Gas Lift".
7. **Category lists:** WLI Z9 and the Production function are cut in the export. Check them in the doc.

## 8. Effect on our earlier work
- `07-WO-Approval-Route-Enhancement.md`: the automatic route search is replaced by manual selection (requestor for Level 0, the target department for Level 1). Keep the "copy approvers at the start of each step" idea.
- `09-WO-Permission-Level-Plan.md`: Layer permissions are not needed to find approvers. Keep only Read / Create / Process WO and a new "Set Approval Flow (Level 1)" permission.
- PR #1523 comment, problem 5: one part is now wrong. The requestor **does** select the flow, but only for the requestor department. Still valid:
  - the target department approvers are copied later (when it sets its flow), and
  - the unique index `(work_order_id, user_id)` blocks one person in two steps.
- Question "does the department or the category set the schedule type": answered. The department sets it.
- Question "how does the system find the Layer of a user": answered. It does not. The route holds the names, and the position is an SOP only.

---

## 9. Answers from the user (24 Nov)
1. **Tab:** "Set Approval Flow" is available from **both** tabs (Incoming and Outgoing).
2. **Level 2 name:** follow **Data Config**. Level 2 = "Target Department". The MoM meaning ("the department that gets a transferred WO") is replaced. Still to confirm: what Level 1 means with this naming.
3. **Approve button:** **no**. After Set Approval Flow, the page shows only Modify and Reject.
4. **Requestor is a Senior:** the system does not skip a step. **Another Senior** reviews the WO. The approver is found by **permission ID**: every user who has the permission can review.
5. **Copied text:** the user asks what to decide. See §10.
6. **Spelling:** yes, these are typos. "Inception" = **Inspection**. "Gas List" = **Gas Lift**.

## 10. What to decide for the two empty sections
**"Approve & Create Disposition" (second copy):** it is a copy of the first section. Decide: delete it, or use it for another case (for example the disposition in the Level 2 department).

**"Approve & Transfer Work Order":** it has no content. Decide:
1. Who can transfer, and from which status (Approved only?).
2. Which departments the user can select (all, or a list for each department).
3. Does the user select a sub-unit (Send to Field: PE / PO / RAM / WO-WS)?
4. Are notes mandatory?
5. After the transfer: the status, and who sets the approval flow of the receiving department (the same "Set Approval Flow" window?).
6. Can the receiving department transfer again? Earlier decision: no, it can only make a disposition.

## 11. More answers from the user (24 Nov)

**Level names (replaces answer 2 in §9):**
- Level 0 = the requestor department.
- Level 1 = the target department (Request To).
- Level 2 = the assigned department (only if needed, after a Transfer).

**Approvers:** the route holds a **permission ID**. Every user with that permission can review.

**Transfer Work Order:**
1. Who: a user with the transfer permission (the same model as approval).
2. Departments: a **list** for each department.
3. Sub-unit: **yes**, the user also selects a sub-unit (Send to Field: PE / PO / RAM / WO-WS).
4. Notes: **not** mandatory.
5. After the transfer: the assigned department uses the same **"Set Approval Flow"** window to select its own flow.
6. Transfer again: **no**. The assigned department can only make a disposition.

**Still open:**
- "Approve & Create Disposition" (second copy): delete it, or use it for the Level 2 disposition?
- The status after a transfer.
- Does the permission apply in every department, or only in the department of the Level? Proposal: only in the department of the Level. Example: a PO Senior with the permission must not review an OSF WO.

**Backend rule (user, 24 Nov):** the permission ID is used only to **list** users (`GET /users/by-permission/{id}`). The backend does **not** check it to allow or block an action.
- Note: `GetUsersByPermissionAsync` reads casbin, or Retina for a fixed list of ids (161, 162, 163). A new WO permission that is only in Retina must be added to that list (`IsRetinaOnlyPermissionAsync`, `UsersService.cs:560`).

## 12. Last open points, answered (24 Nov)
1. The second "Approve & Create Disposition" section: **delete it**.
2. The status after a Transfer: **Waiting Approval**.
3. A permission counts **only in the department of its Level**. The list of users by permission must be filtered by that department (today `/users/by-permission/{id}` has no department filter).

All questions in this file are now answered.
