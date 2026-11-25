# Work Order: status flow and approval route flow

Made on 24 Nov from the decisions in `00-Decision-Log.md` and `11-TeamDoc-Decisions-24Nov.md`.

Words:
- **Level 0** = requestor department.
- **Level 1** = target department (Request To).
- **Level 2** = assigned department (only after a Transfer).
- **Layer 1** = Senior / Asst. Manager. **Layer 2** = Manager. The system does not check the position. Every user who has the permission of the layer, in the department of the Level, can act.

Not in these charts:
- The Study flow (study review / study approval).
- The urgent rule: 2 × 24 h per layer, then the WO goes to the next layer.

---

## 1. Work Order status flow

```mermaid
flowchart TD
    START(["Create Work Order<br/>requestor selects the Level 0 approval flow"]) --> DRAFT
    DRAFT["Draft"] -->|"Submit"| CAT{"Category needs approval?"}
    CAT -->|"No: skip all approval"| APPROVED
    CAT -->|"Yes"| L0S

    subgraph LV0["Level 0 - requestor department"]
        L0S["Waiting Approval<br/>Layer 1 Senior"]
        L0M["Waiting Approval<br/>Layer 2 Manager"]
        L0S -->|"Approve<br/>or Modify + Approve in one step"| L0M
    end
    L0S -->|"Reject"| REJECTED
    L0M -->|"Reject"| REJECTED
    L0M -->|"Approve<br/>or Modify + Approve in one step"| L1W

    subgraph LV1["Level 1 - target department, same steps at Level 2"]
        L1W["Waiting Approval<br/>Layer 1 Senior"]
        SET["Set Approval Flow<br/>select the Level 1 flow<br/>buttons: Modify and Reject only"]
        MODR["Modification Review<br/>Layer 2 Manager of the target dept"]
        MODV["Modification Review<br/>Layer 2 Manager of the requestor dept"]
        REJR["Rejection Review<br/>Layer 2 Manager of the target dept"]
        REJV["Rejection Review<br/>Layer 2 Manager of the requestor dept"]
        NOREJ["Waiting Approval<br/>Layer 1 Senior, Reject button hidden<br/>only Approve or Modify"]

        L1W -->|"Set Approval Flow"| SET
        SET -->|"Modify<br/>change kept as a proposal"| MODR
        SET -->|"Reject"| REJR
        MODR -->|"Approve"| MODV
        MODR -->|"Reject<br/>proposal dropped"| L1W
        REJR -->|"No, Cancel"| L1W
        REJR -->|"Yes, Reject"| REJV
        REJV -->|"Refuse the rejection"| NOREJ
        NOREJ -->|"Modify"| MODR
    end

    L1W -->|"Approve"| APPROVED
    NOREJ -->|"Approve"| APPROVED
    MODV -->|"OK: copy the proposal into the WO"| APPROVED
    MODV -->|"Not OK: proposal dropped, old values kept"| APPROVED
    REJV -->|"Accept the rejection"| REJECTED

    APPROVED["Approved<br/>Layer 1 Senior of the target dept"]
    APPROVED -->|"Transfer Work Order<br/>Level 1 only: permission,<br/>department from the list + sub-unit, notes optional"| L2W["Waiting Approval<br/>Level 2 - assigned department<br/>same steps as Level 1, no second Transfer"]
    L2W -->|"Approve"| APPROVED2["Approved at Level 2"]
    APPROVED -->|"Create Disposition<br/>Work Type + PIC + notes"| PREP
    APPROVED2 -->|"Create Disposition"| PREP

    PREP["Project Preparation<br/>PIC makes the project"]
    PREP -->|"Create Project<br/>detail: Project, OSF<br/>simple: WLI, PHSS, PEP RAM, PEP PE, PO Zona, Drilling"| PAPP{"Action Plan WO?"}
    PAPP -->|"No"| PROJAPP["Project Approval"]
    PAPP -->|"Yes: skip project approval<br/>Action Plan + simple project"| ONGO
    PROJAPP -->|"Approved"| ONGO["On Going"]
    PROJAPP -->|"Rejected"| PREP
    ONGO -->|"Finish<br/>all schedules of the WO finish"| DONE(["Completed"])

    REJECTED(["Rejected - FINAL<br/>requestor makes a new WO with a new number"])

    classDef final fill:#fde2e2,stroke:#c62828,color:#000
    classDef wait fill:#fff4d6,stroke:#b26a00,color:#000
    classDef ok fill:#e3f6e8,stroke:#2e7d32,color:#000
    class REJECTED final
    class DRAFT,L0S,L0M,L1W,SET,MODR,MODV,REJR,REJV,NOREJ,L2W wait
    class APPROVED,APPROVED2,PREP,PROJAPP,ONGO,DONE ok
```

**How to read it**
- **Level 0:** a Modify by the Senior or the Manager of the requestor department changes the WO and approves it in one step. The requestor gets a notification only.
- **Level 1:**
  - Approve does not need an approval flow.
  - Modify and Reject need the target department's flow first ("Set Approval Flow").
- **A modification in the target department:** the change stays a proposal until both Managers agree. If the requestor Manager refuses it, the WO becomes Approved with the old values.
- **A Reject from the target department needs two confirmations:** first the target Manager, then the requestor Manager. If the requestor Manager refuses the rejection, the WO goes back to the target Senior with the Reject button hidden.
- **Level 2:** the WO gets Level 2 only after a Transfer. The steps are the same as Level 1, but the assigned department cannot transfer again.

---

## 2. Approval route flow (who approves, and when the system finds them)

```mermaid
flowchart TD
    subgraph CFG["Data Config - Approval Route"]
        R["Route category: Work Order - Department<br/>Level 0 / 1 / 2, each with Layer 1 and Layer 2<br/>each layer holds a permission ID"]
    end

    subgraph S0["Level 0 - at Create Work Order"]
        A0["Requestor selects a flow<br/>only Level 0 steps"] --> C0["Submit: copy the Level 0 steps to the WO"]
        C0 --> U0["List the approvers:<br/>GET /users/by-permission/id<br/>filtered by the requestor department"]
    end

    subgraph S1["Level 1 - Set Approval Flow window"]
        A1["Target dept user selects a flow<br/>status Waiting Approval, Incoming or Outgoing tab"] --> C1["Copy the Level 1 steps to the WO"]
        C1 --> U1["List the approvers by permission ID<br/>filtered by the target department"]
    end

    subgraph S2["Level 2 - only after a Transfer"]
        T["Transfer: status goes back to Waiting Approval"] --> A2["Assigned dept user selects a flow<br/>same Set Approval Flow window"]
        A2 --> C2["Copy the Level 2 steps to the WO"]
        C2 --> U2["List the approvers by permission ID<br/>filtered by the assigned department"]
    end

    R -.->|"flows to select"| A0
    R -.-> A1
    R -.-> A2
    U0 --> NEXT1["WO goes to Level 1"] --> A1
    U1 -->|"Senior approves, then Transfer"| T

    NOTE["Backend rule: the permission ID is used only to LIST users.<br/>The backend does not check it on Approve / Modify / Reject."]
    U0 -.-> NOTE
    U1 -.-> NOTE
    U2 -.-> NOTE
```

---

## 3. Status of one approval step

Each copied step (Level + Layer) on a WO moves through these states.

```mermaid
stateDiagram-v2
    [*] --> NotStarted: flow copied to the WO
    NotStarted --> Skipped: category has no approval
    NotStarted --> Pending: previous step done (Received Date)
    Pending --> Approved: Approve
    Pending --> Modified: Modify (Level 0 = modify and approve in one step)
    Pending --> Rejected: Reject
    Pending --> Returned: No, Cancel / proposal dropped
    Pending --> Bypassed: urgent WO, 2 x 24 h passed
    Approved --> [*]
    Modified --> [*]
    Rejected --> [*]
    Returned --> Pending: same step acts again
    Bypassed --> [*]
    Skipped --> [*]
```

- Received Date = the time the step goes to **Pending**. Action Date = the time it leaves Pending. Duration = the difference, compared with the SLA.
- **Bypassed** is from the urgent rule in the MoM. Check whether the team still wants it.
