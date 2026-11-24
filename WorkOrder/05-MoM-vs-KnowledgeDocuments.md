# Work Order: MoM recap vs our Knowledge Documents

19 Nov 2026 · Source: Google Doc "Recap MOM PHI (Phantom)" (Work Order parts), compared with `04-KnowledgeDocuments-WorkOrder.md`.

> **Status 24 Nov.** This file records the comparison of 19 Nov. Do not change the rows. The decisions after 19 Nov change these rows (see `00-Decision-Log.md`):
> - **M4 (approval from config):** changed. The requestor selects the Level 0 flow in Create WO. The target department and the assigned department select their own flow in "Set Approval Flow". Every flow comes from Data Config.
> - **G3 (skip rule for a Senior requestor):** removed. No step is skipped. Another Senior reviews the WO. The system does not check the position.
> - **M014 "position validator":** not needed. Each layer holds a permission ID. The backend uses it only to list users, in the department of the Level.
> - **M9 (Transfer fields):** the user also selects a sub-unit. Notes are optional. The departments come from a list for each department.
> - **X1 (WO number format):** the format comes from `custom_configurations`.
> - **X2 (requestor-side Modify):** the approver edits and approves in one step. The requestor gets a notification only.
> - **X3 (requestor-side Reject):** final. No re-submit.
> - **X4 (who verifies a modification):** the Manager of the requestor department.
> - **X5 (requester declines the modification):** the system drops the proposal. The WO goes to Approved with the old values.
> - **X6 (rejection not approved):** the WO goes back to the target Senior. The Reject button is hidden, so the Senior can only Approve or Modify.
> - **X8 (Finish parameters):** required.
> - **X10 (Request To values):** an 11-department list (team doc). "Level 1 / Level 2" are the Level names: 0 = requestor, 1 = target, 2 = assigned (only after a Transfer).
> - **X11 (Drilling):** a simple schedule (WO Type Mapping).
> - **X12 (Action Plan route):** the AP uses the route of the WO.
> - **X14 (schedule upload):** no `.mpp` for a WO project. Both schedule types are built in the app (grid or Excel).
> - **Still open:** X9 (WO close / requestor verification), X13 (AL entry point 1), and the urgent 2 × 24 h rule (G1: check with the team).

The MoM parts used:
- **MoM 9:** "9. Work Order & Action Plan Ownership".
- **22 Okt:** KOM Sprint 2. This covers the WHC ticket, the Gaslift PHSS flow, the department list and the WO number.
- **M002 / M009:** AL parameters and AL notification.
- **M014:** "Work Order".
- **6 Nov:** MoM Sprint 3. This covers approval workflow, disposition, the Project Monitoring link, and Simple and Detail schedule.
- **19 Nov:** "Regarding Work Order Module", a Q&A with Ardi, Atina and Naya.

Legend: ✅ match · ➕ gap, now added to the Knowledge Documents · ⚠️ conflict with a user decision or the Figma, which needs an answer · ❓ still open in the MoM too.

**Deadline:** the 19 Nov MoM lists Work Order as an item that must be ready for the PHANTOM launch on **4 Dec 2026**.

---

## 1. Matches (no change)
| # | Topic | MoM | Knowledge Documents |
|---|---|---|---|
| M1 | WO purpose | M014: request, give or dispose tasks between departments | §Overview |
| M2 | Incoming / Outgoing / Dashboard | M014: Incoming = assigned to the PIC, Outgoing = made by the Requestor. 19 Nov: "WO under Dashboard, for All Tenant" | WO-9.1 |
| M3 | Save as Draft / Cancel / Submit | M014: Draft → Outgoing, Cancel saves nothing, Submit → approval level 1 | WO-1.1 |
| M4 | Approval from config | 6 Nov: the reviewer comes from approval routing in data config, and the requester doesn't pick one. 19 Nov: "Approval Flow: Predefined in config" | D2, WO-2.x |
| M5 | Well Action Plan inside the WO module | M014: every Well Action Plan made or received shows in Incoming / Outgoing. 19 Nov (Ardi): "Data General WO dan Data Action Plan itu sama", and empty fields are filled in WO General | D1, WO-1.2 |
| M6 | Manager entry points | 6 Nov: Work Order Module, Personal Dashboard, Notification Center | WO-2.x entry points |
| M7 | Manager modify shows the diff | 6 Nov: changes must show before vs after | WO-4.1, WO-9.2 |
| M8 | Disposition depth | 6 Nov: "Proses disposisi dibatasi sampai dengan level 2" | WO-6.1 (Lvl 2 can't transfer) |
| M9 | Transfer and Disposition fields | 19 Nov: Transfer = Department, PIC, Notes. Disposition = Work Type, several PICs, Notes, usually sent by the Asst Manager | WO-6.1, WO-6.2 |
| M10 | Simple vs Detail schedule, reuse Project Monitoring | 6 Nov: two schedule types on the existing Project Monitoring, no new module | Flow 7 |
| M11 | Project link | 6 Nov: a project from a WO must carry the WO Number | `projects.work_order_id` |
| M12 | WBS optional, RKAP and Budget Type required | 19 Nov | Data §A |
| M13 | SSDP owns WO creation | MoM 9: SSDP creates the WO, PO is the assignee. PO suggestions never become a WO automatically | WO-1.1 |
| M14 | Approve or Reject only | 22 Okt: "Remind Me Later" dropped | – |
| M15 | Contract belongs to the receiver | 22 Okt: SSDP types the contract no. by hand, PO checks it. The contract shown is the target department's | WO-1.2 AL / WT |

## 2. Gaps: now added to the Knowledge Documents
| # | Topic | MoM | Added where |
|---|---|---|---|
| G1 | **Urgency SLA + auto-escalation** | M014: **Regular** = the SLA of each level (e.g. 14 days); after that the WO goes to the next level automatically. **High Priority** = 48 h per level, then auto-escalate. 19 Nov calls it "Regular, **Urgent**" | WO-1.1 rule, new story WO-2.5, Data: `urgency_level`, `work_order_approvers.due_at / escalated_at` |
| G2 | **Work Order Type** | 19 Nov: "Updating Parameter, Study, or New Work". M014: WO is "Multi" (Study, Project-based, Artificial Lift, Well Activities) | WO-1.1, Data `work_order_type` |
| G3 | **Skip rule covers Senior too** | M014: if the requestor is a **Senior or** Asst Manager, go straight to the Manager. A position validator is needed | WO-2.1 |
| G4 | **WO Number on Project Details** | 6 Nov: add a WO Number field to Project Details | WO-7.3 |
| G5 | **Finish checks for a WO number** | 6 Nov: on Finish Project, if the project has a WO Number → pop-up to update the WO parameters with actual results → notification "parameter updated & WO completed". Examples: RTWS = time parameter, Gas Lift = schedule, Fast Prod = time / schedule | WO-8.1 |
| G6 | **Schedule input: on the spot + Excel upload** | 6 Nov: build the schedule in the UI **or** upload Excel | WO-7.2 |
| G7 | **Cost weight not mandatory** | 6 Nov: cost weight is not required yet. Gantt / S-curve / weight needs are still to be defined | WO-7.2 (weight fallback) |
| G8 | **Receiving dept modify → first requester verifies** | 6 Nov: a modify by a later-level department goes back to the **first requester**, not to the department that transferred it | WO-4.2 |
| G9 | **Cross-dept view-only** | 22 Okt: everyone can view (except sensitive data). Create / Modify / Reject belong to the owning department only | WO-9.2 |
| G10 | **Cycle Progress per Request To** | 19 Nov: the cycle is set by Request To, like Project Approval | WO-9.2 |
| G11 | **Field values** | 19 Nov: Field = PHSS Northern, PHSS Southern. Area follows Field | WO-1.1 |

## 3. Conflicts: need an answer
| # | Topic | MoM | Our Knowledge Documents / decision | Ask |
|---|---|---|---|---|
| X1 | **WO number format** | 22 Okt: "format 4 digit/WO/**pemberi kerja**/tahun", where the code is the **requesting department**, with a "Z9" marker because PO exists in both zone 9 and the field | **D5:** `<seq>/WO/PROJECT/<year>` (literal PROJECT) | D5 goes against an agreed MoM. Keep PROJECT, or use the requester dept code (e.g. `0001/WO/SDA1/2026`, `…/PO Z9/…`)? |
| X2 | **Requestor-side Modify (L1)** | M014: Senior / Asst Man **Modify = return to the Requestor** to edit | Knowledge Documents: the approver edits and approves in one step | Which one? If returned: new status "returned to requestor", and the Requestor re-submits |
| X3 | **Requestor-side Reject** | M014: "dikembalikan ke Requestor untuk **tidak dilanjutkan**" (final) | Figma F4: re-submit allowed. D3: Rejected is final | The MoM agrees with D3. Drop the Figma re-submit note (Q6b)? |
| X4 | **Who verifies a modification** | 6 Nov: after the approval layer approves, the **first requester** (the person) gets a notification and verifies. 22 Okt: "requester dan penerima notifikasi akhir di SSDP adalah orang yang sama" | Figma / prototype: Manager Requestor (Lvl 0). Today: SSDP is the last route level | MoM = the requestor person. Answers Q4a? |
| X5 | **Requester declines the modification** | 6 Nov: send it back for **re-modify** or **continue with the old parameters** | Knowledge Documents: return to reviewer (D3) | Add the outcome "continue with previous parameters"? |
| X6 | **Rejection not approved** | 6 Nov: the options are **Continue** (as requested) or **Modify**. 22 Okt: "Jika tidak disetujui, PO harus melakukan modify" | **D3:** back to waiting_review, and the reviewer may reject again | MoM = no second reject. Keep D3, or hide Reject after a declined rejection (BR-7, which D3 removed)? |
| X7 | **Modify route levels** | 22 Okt: Manager L1 then L2. A reject at any level → back to PO. After approval → SSDP notified → ongoing | D2: from routes | ✅ fits D2. Confirm the Figma's single-layer Reject vs the 2-level Modify |
| X8 | **Finish parameters** | 6 Nov: the pop-up updates the WO parameters; "Finish Project … menjadi trigger untuk memperbarui parameter Work Order" | **D7:** Finish may skip the parameters | The MoM and Figma both expect parameters. Q7a |
| X9 | **WO close / requestor verification** | M014: the receiver updates the WO and sends verification to the requestor when the task is done. The requestor can add a new task or verify. 6 Nov: the notification says "WO selesai" | Figma: the requestor updates the well. Knowledge Documents: closes at Finish | Does the WO close at Finish (6 Nov) or after requestor verification (M014)? Q7b |
| X10 | **Request To values** | 19 Nov: "Request To: **Internal, Level 1, or Level 2**" | Knowledge Documents: Request To = 11 departments | Is this a second field (scope: internal / L1 / L2), or a renamed Request To? |
| X11 | **Drilling project flow** | 19 Nov (Ardi): add a Drilling project flow to the Figma. Project-based schedule = "locking the categories which work is RTWS". 6 Nov: Drilling is in the schedule users | Knowledge Documents: Drilling has no Category and no schedule | Add a Drilling category / flow when the Figma has it |
| X12 | **Action Plan approval route** | 19 Nov (Naya): Well Action has no route, WO has one. Option 1: the AP is sent to the WO for the route. Option 2: Well Surveillance adds the route to its form. Ocean to assess | **D1:** the WO is the parent, and the route lives on the WO | D1 = option 1. Tell PHI it is decided |
| X13 | **AL entry point 1** | M009: Action Plan install AL in Well Surveillance → **PO validates → PO makes a WO to Project** | Knowledge Documents: one WO, transfer PO → Projects | Is this a second WO (PO → Projects), or a Transfer of the same WO (number kept)? |
| X14 | **Schedule upload format** | 6 Nov: Excel upload | Detail today = `.mpp` only (Aspose) | Excel for simple only, or also replace `.mpp` for detail? |

## 4. Still open in the MoM
- **19 Nov:** "Which Work Order is Project Based Schedule?" Ardi: Figma annotation needed (the Figma now says PRJ + OSF, C6).
- **19 Nov:** Category concept "like Add SPK from Project Monitoring". The full category list is in the Figma; Well Surveillance categories are a small part of it.
- **19 Nov:** "PIC: Predefined value". From where (a department member list)?
- **6 Nov:** Gantt, S-curve and weight input still need definitions.
- **M014 Next Action:**
  - UI for the Action Plan entry point vs the dedicated WO module.
  - Which Action Plan data goes into the WO form.
  - The position validator for requestor and approval levels.
- **MoM 9:** the PO suggestion → SSDP mechanism is still to be assessed.
