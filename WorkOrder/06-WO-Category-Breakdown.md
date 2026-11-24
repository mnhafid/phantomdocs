# Work Order: category breakdown

19 Nov 2026. Sources:
- **Prototype** `S4gBiq…` (`CAT_DEPT`, `CAT_FUNC`, `CAT_EXTRA`, `NO_CAT`, `ACP_KIND`, `DETAIL_DEPT`, `FIN_DOC_CATS`)
- **Figma** › Work Order › Detail Schedule and Simple Schedule, which give the project class
- **Knowledge Documents** §7 master data
- **Current system** (AL / WT action plan)
- **MoM**
- **Team doc "PRD Phantom Fase 2"** (read 24 Nov): the Request To, Function and Category lists of the Create Work Order form. See `11-TeamDoc-Decisions-24Nov.md`.

**Update 24 Nov:** this file now follows the decisions of 24 Nov (`00-Decision-Log.md`, entries TD1–TD16):
- The team doc lists are the current lists. A category that is only in the Figma is marked "Figma only".
- The **department** sets the schedule type. The user does not select it.
- The approvers are found by **permission**, in the department of the Level. The system does not check the position.

## Request To list (team doc, 24 Nov)
| Request To | The form shows | Schedule |
|---|---|---|
| Drilling | no Category, no Function | simple |
| OSF Z9 | Category | detailed |
| PHSS Field | Category + Function (WO/WS, Facility Maintenance) | simple |
| PO Z9 | Category | simple (PO Zona) |
| Project Z9 | Category | detailed |
| Sangasanga Field | Category + Function (RAM, PE, Production) | simple (PEP RAM / PEP PE) |
| Sangatta Field | Category + Function (RAM, PE, Production) | simple (PEP RAM / PEP PE) |
| Tanjung Field | Category + Function (RAM, PE, Production) | simple (PEP RAM / PEP PE) |
| SDA 1 Z9 | no Category, no Function | not in the schedule list (see Q04) |
| SDA 2 Z9 | no Category, no Function | not in the schedule list (see Q04) |
| WLI Z9 | Category | simple |

Schedule type for each department (decided 24 Nov): **simple** = WLI, Field PHSS, Field PEP RAM, Field PEP PE, PO Zona, Drilling. **Detailed** = Project, OSF. It is fixed in the code first. It can become a configuration later.

Key for the fields:
- **AP:** the Action Plan child (D1). The kind codes are `ch` choke, `wt` well test, `so` sonolog, `up` AL update, `in` AL installation, `pp` description-type.
- **Appr:** target-side approval under D4. ✔ means approval is needed; – means auto-approved (the WO skips all approval steps, R1).
- **Sched:** `detail` is the project-based schedule, `simple` is the simple schedule. A WO project uses no `.mpp`: the PIC makes both kinds in the app (grid or Excel).
- **Class:** the Figma's Budget Type → Project Category → Class.
- **Finish:** what the Finish pop-up asks for (D7 makes it required).
- **Well upd:** what the Requestor updates on the well after Finish (Figma).

## 1. Projects Z9 (detail schedule)
- **RTWS Installation**
  - AP: –
  - Appr: ?
  - Sched: detail
  - Class (Figma): ABI BD → NWD → RTWS
  - Finish: time parameter (MoM)
  - Well upd: –
  - Source: all
- **Gas Lift Installation**
  - AP: –
  - Appr: ?
  - Sched: detail
  - Class (Figma): ABI BD → NWD → Gas Lift
  - Finish: Gas Lift schedule (MoM)
  - Well upd: –
  - Source: all
- **Plant Upgrading**
  - AP: –
  - Appr: ?
  - Sched: detail
  - Class (Figma): ABI BD → Fasprod → Fasprod
  - Finish: ?
  - Well upd: –
  - Source: all
- **Compressor Relocation**
  - AP: –
  - Appr: ?
  - Sched: detail
  - Class (Figma): ABI BD → Fasprod → Fasprod
  - Finish: ?
  - Well upd: –
  - Source: **Figma only**
- **Facility Upgrade**
  - AP: –
  - Appr: ?
  - Sched: detail
  - Class (Figma): ?
  - Finish: ?
  - Well upd: –
  - Source: prototype `CAT_EXTRA`, Knowledge Documents and the **team doc (Project Z9)**. A Figma note lists it under "OSF Projects". **Conflict:** the user said "Use Figma" (Q08), but the newer team doc puts it in Project Z9 (see K4)
- **Artificial Lift Installation**
  - AP: `in`
  - Appr: ✔
  - Sched: detail (the department sets it: Project = detailed)
  - Class (Figma): –
  - Finish: Post-Installation Result
  - Well upd: AL parameter
  - Source: prototype `CAT_EXTRA` and the **team doc** (Project Z9 and PO Z9). The Figma shows it on PO only
- **Flowline Installation**
  - AP: –
  - Appr: ?
  - Sched: detail
  - Class (Figma): ABI BD → NWD → Flowline
  - Source: **Figma only** (23 Nov)

## 2. OSF Z9 (detail schedule)
- **Heavy Equipment**
  - AP: –
  - Appr: ?
  - Sched: detail
  - Class (Figma): ABI NBD / ABO → Fasprod → HE
  - Finish: ?
  - Source: all
- **AFA / Modification**
  - AP: –
  - Appr: ?
  - Sched: detail
  - Class (Figma): → AFA
  - Finish: ?
  - Source: all
- **Maintenance**
  - AP: –
  - Appr: ?
  - Sched: detail
  - Class (Figma): → Maintenance
  - Finish: ?
  - Source: all
- **Inspection**
  - AP: –
  - Appr: ?
  - Sched: detail
  - Class (Figma): → Inspection
  - Finish: Summary Inspection Document, Recommendation Document (if any)
  - Source: all. The team doc writes "Inception": this is a typo for Inspection
- **Others**
  - AP: –
  - Appr: ?
  - Sched: detail
  - Class (Figma): ABO → Fasprod → Others
  - Finish: ?
  - Source: team doc + Figma
- **Rig Inspection**
  - AP: –
  - Appr: ?
  - Sched: detail
  - Class (Figma): → Rig Inspection
  - Finish: ?
  - Source: **Figma only**. Add it (answer to Q06: "Yes")
- **Study**
  - AP: –
  - Appr: ?
  - Sched: detail
  - Class (Figma): → Study
  - Finish: document
  - Source: **Figma only**. Add it (answer to Q06: "Yes")

## 3. WLI Z9 (simple schedule)
- **Well Service**
  - AP: –
  - Appr: ?
  - Sched: simple
  - Class (Figma): ABO → Well Service
  - Well upd: status / AL / EUR
  - Source: all
- **PCTGL**
  - AP: –
  - Appr: ?
  - Sched: simple
  - Class (Figma): ABI BD → PCTGL
  - Well upd: status / AL / EUR
  - Source: all (PCTGL is the correct name)
- **Well Intervention**
  - AP: –
  - Appr: ?
  - Sched: simple
  - Class (Figma): Workover? → ABI BD / ABI NBD → Workover
  - Well upd: status / AL / EUR
  - Source: all
- **Fracturing**
  - AP: –
  - Appr: ?
  - Sched: simple
  - Class (Figma): ABO → Workover
  - Well upd: status / AL / EUR
  - Source: **Figma only**. Add it (answer to Q06: "Yes")
- Note: the team doc export cuts the WLI Z9 category list. Check it in the team doc.

## 4. PHSS Field (simple schedule). Function: WO/WS or Facility Maintenance
The team doc gives the **same** category list for both functions. So the Function stays on the form, but it does not change the PHSS categories.
- **Maintenance Field**
  - AP: `pp`
  - Appr: –
  - Sched: simple
  - Class (Figma): ABO → Maintenance
  - Finish: Desc / Timeline / Gain / LPO / Remarks
  - Well upd: –
- **Choke Adjustment**
  - AP: `ch`
  - Appr: –
  - Sched: simple
  - Class (Figma): ABO → Operation / Well Related Action
  - Finish: Choke Adjustment Result
  - Well upd: choke
- **Well Test**
  - AP: `wt`
  - Appr: ✔
  - Sched: simple
  - Class (Figma): same
  - Finish: Well Test Result
  - Well upd: MTU
- **Sonolog / BJP Update**
  - AP: `so`
  - Appr: –
  - Sched: simple
  - Class (Figma): same
  - Finish: ?
  - Well upd: sonolog. Built for PEP only today. The team doc lists it for PHSS, so we build it for PHSS too
- **Artificial Lift Update**
  - AP: `up`
  - Appr: –
  - Sched: simple
  - Class (Figma): same
  - Finish: ?
  - Well upd: AL parameter

## 5. PEP fields: Tanjung / Sangatta / Sangasanga (simple schedule, categories by Function)
- **RAM – Maintenance Field**
  - AP: `pp`
  - Appr: –
  - Class (Figma): ABO → Maintenance
  - Finish: Desc / Timeline / Gain / LPO / Remarks
  - Well upd: –
- **RAM – Modification**
  - AP: `pp`
  - Appr: –
  - Class (Figma): ABO → Maintenance
  - Finish: same
  - Well upd: –
- **PE – Choke Adjustment**
  - AP: `ch`
  - Appr: –
  - Class (Figma): "New Action Process" ABO → Well Action
  - Finish: Choke Result
  - Well upd: choke
- **PE – Sonolog / BJP Update**
  - AP: `so`
  - Appr: –
  - Class (Figma): ABO → Well Action
  - Finish: ?
  - Well upd: sonolog
- **PE – Artificial Lift Update**
  - AP: `up`
  - Appr: –
  - Class (Figma): ABO → Well Action
  - Finish: ?
  - Well upd: AL parameter
- **PE – Updating Well Data**
  - AP: **none**
  - Appr: –
  - Class (Figma): ABO → Updating Data
  - Finish: ?
  - Well upd: well data
- **Production – Well Test**
  - AP: `wt`
  - Appr: ✔
  - Class (Figma): ABO → Well Test
  - Finish: Well Test Result
  - Well upd: MTU
- **Production – Plant Performance Study**
  - AP: **none**
  - Appr: –
  - Class (Figma): ABO → Study
  - Finish: **document** (`FIN_DOC_CATS`)
  - Well upd: –
- Note: the team doc export cuts the Production category list. Check it in the team doc.
- **Production – Artificial Lift Update**
  - AP: `up`
  - Appr: –
  - Class (Figma): ABO → AL Update Data
  - Finish: ?
  - Well upd: AL parameter

## 6. PO Z9 (simple schedule)
- **Choke Adjustment**
  - AP: `ch`
  - Appr: –
  - Class (Figma): ABO → Well Action
  - Finish: Choke Result
  - Well upd: choke
- **Artificial Lift Update**
  - AP: `up`
  - Appr: –
  - Class (Figma): ABO → Well Action
  - Finish: ?
  - Well upd: AL parameter
- **Artificial Lift Installation (WHC)**
  - AP: `in`
  - Appr: ✔
  - Class (Figma): ABO → Artificial Lift Install
  - Finish: Post-Installation Result
  - Well upd: AL parameter
- **Well Test (MTU)**
  - AP: `wt`
  - Appr: ✔
  - Class (Figma): ABO → Well Test
  - Finish: Well Test Result
  - Well upd: MTU

## 7. No category
- **Drilling**
  - The form shows no Category and no Function (team doc).
  - Schedule: **simple** (decided 24 Nov).
  - Figma (23 Nov): "Drilling New Well" → ABI BD → simple schedule → class "ABI BD → Drilling".
- **SDA 1 Z9, SDA 2 Z9**
  - The form shows no Category and no Function (team doc). Today SDA only *creates* plans and never receives them. What a WO to SDA means is still open (Q04)
- **Every other Request To**
  - Rule: "Others": no AP, no schedule (`schedKind` = null)

## Approval flow by category

### The two flows
- **Multi-level approval**
  - **Who approves:** each layer of the route holds a **permission ID**. Every user who has that permission, in the department of the Level, can act. The system does not check the position. "Layer 1 = Senior / Asst. Manager, Layer 2 = Manager" is a work rule (SOP) only.
  - **Who selects the flow:** each department selects its own flow by hand from Data Config ("Work Order - {Department}").
  - Requestor department (Level 0), flow selected by the requestor in Create Work Order:
    - **Layer 1 (Senior):** approves, or modifies and approves in one step, or rejects. **No skip:** if the requestor is a Senior, another Senior reviews.
    - **Layer 2 (Manager):** the same actions. After that, the WO goes to the target department.
    - A reject here is final.
  - Target department (Level 1):
    - The Senior can **Approve** at once.
    - For **Modify** or **Reject**, the Senior first selects the target flow in "Set Approval Flow". Then only Modify and Reject show.
    - **Modify lane:** the target Manager approves, then the requestor Manager checks (X4). If the requestor Manager refuses, the change is dropped and the WO is Approved with the old values (X5).
    - **Reject lane:** the target Manager confirms ("Yes, Reject / No, Cancel"), then the requestor Manager accepts or refuses the rejection. If it is refused, the WO goes back to the target Senior with the Reject button hidden (D3b).
  - Optional transfer (Level 1 only): a user with the transfer permission selects a department from the list and a sub-unit. The status goes back to Waiting Approval. The assigned department (Level 2) selects its own flow and runs the same steps. It cannot transfer again.
  - After approval: Disposition → PIC.
  - Urgency SLA (2 × 24 h per layer) applies at every level (G1).
- **No approval (auto-approved)**
  - Submit → Approved at once. The WO skips **all** approval steps, also the requestor department steps (R1, decided 20 Nov).
  - The target Senior goes straight to Disposition or Transfer.
  - The WO still gets a WO number and notifications (Q24, proposal: yes).

### Multi-level approval
- **Well Test** (`wt`)
  - Request To: PHSS Field, PEP Production, PO Z9 (MTU)
  - Basis: D4. Approval is required today.
- **Artificial Lift Installation** (`in`)
  - Request To: PO Z9 (WHC), Project Z9 (team doc lists both)
  - Basis: D4. Approval is required today.
- **Project-based categories**: proposed (K5), because these create a Project with budget / RKAP
  - Project Z9: RTWS Installation, Gas Lift Installation, Plant Upgrading, Facility Upgrade, Compressor Relocation (Figma only), Flowline Installation (Figma only)
  - OSF Z9: Heavy Equipment, AFA / Modification, Maintenance, Inspection, Others, Rig Inspection (Figma only), Study (Figma only)
  - WLI Z9: Well Service, PCTGL, Well Intervention, Fracturing (Figma only)
  - Basis: the prototype and Figma run every WO through L1 → L2 → target review. D4 does not cover these, because they are not Action Plans today.

### No approval (auto-approved)
- **Choke Adjustment** (`ch`): PHSS Field, PEP PE, PO Z9
- **Sonolog / BJP Update** (`so`): PHSS Field, PEP PE
- **Artificial Lift Update** (`up`): PHSS Field, PEP PE, PEP Production, PO Z9
- **Maintenance Field** (`pp`): PHSS Field, PEP RAM
- **Modification** (`pp`): PEP RAM
- Basis: D4. These Action Plan kinds are auto-approved today.

### Not decided
- **Updating Well Data** (PEP PE) and **Plant Performance Study** (PEP Production): no Action Plan and no Project (K7)
- **Drilling, SDA 1 Z9, SDA 2 Z9:** no category. Does a WO to them need approval?
- Closed 20 Nov: "no approval" skips **all** steps, also the requestor department steps (R1).

## Project class list (Figma, checked 23 Nov)
Source: Figma "PHI - Latest Design", page "Work Order". Find "Class:" gives 35 flow nodes. The Figma writes each class as **Budget Type → Project Category → Class**.

### Detail schedule (PRJ), lane "Detail Schedule for: PRJ"
- Flowline Installation → **ABI BD → NWD → Flowline** (new on 23 Nov)
- RTWS Installation → **ABI BD → NWD → RTWS**
- Gas Lift Installation → **ABI BD → NWD → Gas lift**
- Plant Upgrading → **ABI BD → Fasprod → Fasprod**
- Compressor Relocation → **ABI BD → Fasprod → Fasprod**

### Detail schedule (OSF)
The OSF lane asks "ABI NBD?" after "New Project Creation Process". The budget type then sets the class.
- Heavy Equipment → **ABI NBD → Fasprod → HE**, or **ABO → Fasprod → HE**
- AFA → **ABI NBD → Fasprod → AFA**, or **ABO → Fasprod → AFA**
- Maintenance → **ABI NBD → Fasprod → Maintenance**, or **ABO → Fasprod → Maintenance**
- Others → **ABO → Fasprod → Others** (new on 23 Nov)
- Study → **ABO → Fasprod → Study**. Finish asks for the Engineering / Result Documents.
- Inspection → **ABI NBD → Fasprod → Inspection**, or **ABO → Fasprod → Inspection**. Finish asks for the Summary Inspection Document and a Recommendation Document (if any).
- Rig Inspection → **ABO → Fasprod → Rig Inspection**

### Simple schedule (WLI)
- Well Service → **ABO → Well Service**
- PCTGL → **ABI BD → PCTGL** (an older Figma version wrote "PCTOL"; PCTGL is correct)
- Well Intervention / Workover → **ABI BD → WORKOVER**, or **ABI NBD → WORKOVER**
- Fracturing → **ABO → WORKOVER**

### Simple schedule (PHSS, PEP RAM)
- Maintenance → **ABO → Maintenance**
- Operation Field → **ABO → Operation / Well Related Action**
- Modification → **ABO → Modification**

### Simple schedule (PEP PE, Production) — "New Action Process"
- Well Action (Choke, Sonolog, AL Update) → **ABO → Well Action**
- Updating Well Data → **ABO → Updating Data**
- Well Test / MTU → **ABO → Well Test**
- Plant Performance Study → **ABO → Study**. Finish asks for the attached documents.
- AL Update → **ABO → Artificial Lift Update Data**

### Simple schedule (PO Zona) — "New Action Process"
- Well Action → **ABO → Well Action**
- AL Installation → **ABO → Artificial Lift Install**
- Well Test → **ABO → Well Test**

### Simple schedule (Drilling), new on 23 Nov
- Drilling New Well → ABI BD → "New Project Creation Process – Simple Schedule" → **ABI BD → Drilling**

### What this shows
- **Project Category values** in the Figma: NWD, Fasprod, PCTGL, WORKOVER, Well Service, Drilling, Maintenance, Operation / Well Related Action, Modification, Well Action, Updating Data, Well Test, Study, Artificial Lift Update Data, Artificial Lift Install.
- **Classes under a category:**
  - NWD → Flowline, RTWS, Gas lift.
  - Fasprod → Fasprod, HE, AFA, Maintenance, Others, Study, Inspection, Rig Inspection.
- **Budget type:** for OSF, the budget type (ABI NBD or ABO) changes the class. In all other lanes, the category sets one budget type.
- **Project Details (Figma sample):** Project Category = "Fasprod". Project Number / AFE = "5422/WO/PROJECT/2026" (the WO number).

## Open points on categories
- **K1**: Closed 24 Nov: the team doc lists AL Installation under PO Z9 **and** Project Z9. The department sets the schedule: Project Z9 = detailed, PO Z9 = simple.
- **K2**: Closed: add the Figma-only categories (Compressor Relocation, Rig Inspection, Study, Fracturing). User answer to Q06: "Yes".
- **K3**: Closed 24 Nov: the names are PCTGL, Choke, Inspection, Gas Lift and "Sonolog / BJP Update" (team doc). "Inception" and "Gas List" in the team doc are typos (user, 24 Nov).
- **K4**: **Facility Upgrade:** the user answered "Use Figma" (OSF). But the newer team doc (24 Nov) lists it under **Project Z9**. Confirm which one is correct.
- **K5**: **D4 for non-well categories:** does every non-AP category need target approval, or none? (Today's rule only covers WT and AL WHC.)
- **K6**: Closed 20 Nov: a well WO makes an Action Plan **and** a simple project, because SPK and contract need a project. The project approval is skipped for an Action Plan WO (P1).
- **K7**: **Categories with no AP:** Updating Well Data and Plant Performance Study have no Next step. Where does the well data or study scope go?
- **K8**: Closed 24 Nov: the team doc lists Sonolog / BJP Update for PHSS Field. Build it for PHSS.
- **K9**: Closed 24 Nov: the team doc keeps the PHSS Function on the form, with the same category list for both functions. For the PEP fields, the Function (RAM, PE, Production) changes the list.
- **K10**: **Work Order Type** (Updating Parameter / Study / New Work, MoM 19 Nov): is it derived from the category (e.g. Choke = Updating Parameter, PPS = Study, RTWS = New Work) or picked by the user?
- **K11**: **Finish fields per category:** "?" cells. The Figma shows only the Maintenance fields and the cost / RKAP cards.
- **K12**: **Storage:** a category list in `custom_configurations` per Request To / Function, holding AP kind, appr flag, class mapping and finish template? Update 24 Nov: the **schedule kind is per department** and fixed in the code first (configurable later). It is not stored per category.
- **K13**: Closed 24 Nov: the **department** sets the schedule type (simple = WLI, Field PHSS, Field PEP RAM, Field PEP PE, PO Zona, Drilling; detailed = Project, OSF). The history of this point is below.
  - **Old question:** schedule type: fixed per department or locked per category?
  - **Figma:** the lanes split by department (PRJ + OSF = Project Based; WLI / PHSS / PEP / PO = Simple). But every Category Selection box lists *both* "Masuk ke Simple Schedule" and "Masuk ke Project Based Schedule".
  - **MoM M014:** the assignee "akan membuat Schedule (Simple atau Project-based (konsep seperti Project atau OSF))", so the receiver makes one of the two.
  - **MoM 6 Nov:** "Untuk proses pembuatan project, tersedia dua pilihan: Simple Schedule / Detail Schedule". Schedule users are Drilling, WLI, Maintenance Field, Project and OSF.
  - **MoM 19 Nov (Ardi, 59:20):** "Which Work Order is Project Based Schedule?" → "It is for **locking the categories** which work is RTWS". He also asks to add a Drilling project flow to the Figma.
  - **Current decision C6** (19 Nov, from the Figma): PRJ + OSF = detail; all others = simple.
  - **Old recommendation (replaced 24 Nov):** store `schedule_kind` per category.
- **K14**: **Simple schedule cost: required and capped?**
  - **MoM 6 Nov:** cost weight is "belum diwajibkan" (not required yet).
  - **MoM 19 Nov (01:58:00):** the simple schedule is a ".mpp-looking UI" that "needs to be filled, especially on cost and percentage". Cost and percentage **cannot be over the WO budget plan**. Cost ↔ percentage auto-fill each other from the estimation cost.
  - **Knowledge Documents WO-7.2:** cost optional, weight fallback, no budget cap.
  - **Recommendation:** follow 19 Nov (the newer MoM). Cost or % is required on each row, and the total is capped by the WO estimation cost. Add this to WO-7.2 with a negative case "over budget → Submit blocked".
- **K15**: **One WO, several schedules?**
  - **MoM 19 Nov (01:22:00):** "When Finishing Work Order, all schedules under the same Work Order will be Finished too". This implies one WO can hold more than one schedule / project (for example one per disposition PIC).
  - **Knowledge Documents:** one project per WO (`projects.work_order_id`); Finish of the project closes the WO.
  - **Recommendation:** allow N projects per WO (FK already on `projects`). The WO closes when the requestor finishes the WO, which finishes all its open schedules. Ties to X9 (WO close).
