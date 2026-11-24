# Action Plan Approval Flow (from whiteboard image)

Drawn from the whiteboard image added to `10-StatusFlow.md`. The flow is kept as drawn, including the
points that differ from the written decisions in `02-changes.md` (noted under the chart).

```mermaid
flowchart TD
    SSDP["SSDP submit"] --> PO["PO review"]
    PO --> A1{"Approve?"}

    A1 -- "Y" --> M1{"Modify?"}
    M1 -- "N" --> PROCEED(["proceed"])
    M1 -- "Y" --> MA["Modify Action Plan"]

    MA --> S1["Send to Manager 1"]
    S1 --> AP1{"Approved?"}
    AP1 -- "Y" --> S2["Send to Manager 2"]
    AP1 -- "N" --> MA
    S2 --> AP2{"Approved?"}
    AP2 -- "Y" --> S3["Send to SSDP"]
    AP2 -- "N" --> MA
    S3 --> AP3{"Approved?"}
    AP3 -- "Y" --> PROCEED
    AP3 -- "N" --> MA

    A1 -- "N" --> RJ["Reject"]
    RJ --> R1["Send to Manager 1"]
    R1 --> OK1{"OK?"}
    OK1 -- "Y" --> R2["Send to Manager 2"]
    OK1 -- "N" --> ASK["Ask PO to Modify"]
    R2 --> OK2{"OK?"}
    OK2 -- "Y" --> REJ(["Action Plan Rejected"])
    OK2 -- "N" --> ASK
    ASK -- "A connector" --> M1
```

## How the code maps the whiteboard (Design A, 18 Nov 2026)

- **Send to Manager 1 / Manager 2:** the manager levels of the approval route (Data Config).
- **Send to SSDP:** the plan's SSDP creator, appended by the backend as the last Modify level. Answers with `approval/approve` (Y)
  or `approval/reject` (N), like the managers, without the 162 / 163 privilege.
- **Approved? = Y at SSDP:** the proposal is applied and the plan is `approved` (proceed).
- **Approved? = N at any level (SSDP included):** the plan goes back to the PO as `waiting_review` (need_review); the proposal is dropped.
- **Reject lane:** managers only. OK? = Y is `approval/reject`; after the last level the plan is
  `rejected` (Action Plan Rejected, terminal). OK? = N is `approval/modify` (Ask PO to Modify) → `waiting_review`.

## Still different from the image

- **PO options after a return:** the image allows only "Modify Action Plan" after a Modify-lane N, and Modify? (modify or proceed)
  after Ask PO to Modify (connector A). The code returns to `waiting_review`, where the PO can approve, modify or reject
  (kept on purpose, 18 Nov; concurrent PO decisions are race-safe).
