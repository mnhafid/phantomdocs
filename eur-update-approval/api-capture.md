# Approval Route — "Add New Route" API capture

Source: https://phantom-web.inproms.com/ipms/approval-route, captured 2026-10-20 with the Chrome extension
(network log) + the page's JS bundles (`ModalCreate.*.js`, `Index.*.js`, `approval-route.*.js`). Save was not clicked
in the browser; the POST shape comes from the bundle.

## Calls per step

| Step | API call |
|---|---|
| Open "Add New Route" | none (lazy JS chunks only) |
| Open Approval Category dropdown | none — categories hardcoded in FE |
| Pick a category | `GET /api/v1/users/by-permission/{permissionId}` → FE keeps `status === "active"` |
| Type in approver search | none — client-side filter |
| Save | `POST /api/v1/approval-routes` |
| Save (E-Sign only) | `POST /api/v1/approval-routes/spk-e-sign` |

Related: list `GET /v1/approval-routes`, detail `GET /v1/approval-routes/{id}`,
edit `POST /v1/approval-routes/{id}/update` (body + `status`), delete `POST /v1/approval-routes/{id}` (soft).

## Category → permission → handler

| Label | `category` | Permission | FE handler |
|---|---|---|---|
| Contract Monitoring Flow | `contract` | 63 Contract Approval | Contract (`sla_days`) |
| Project Monitoring Flow | `project` | 54 Project Approval | Project (`sla_days`) |
| Project Rebaseline | `project_rebaseline` | 54 | Default `T` |
| SPK Monitoring Flow | `spk` | 58 Work Order Approval | SPK (`spk_value_treshold`) |
| SPK Monitoring Flow - E-Sign | `spk_esign` | — (`GET /v1/approval-routes/spk-eligible-approvers?exclude_user_ids=`) | E-Sign (levels/paraf_slots) |
| SPK Progress Approval | `spk_boq_progress` | 70 Work Order BoQ Progress Approval | Default `T` |
| **Update EUR PHSS** (new) | `eur_update_phss` | 154 Modify PHSS Wells | Default `T` |
| **Update EUR PEP** (new) | `eur_update_pep` | 156 Modify PEP Wells | Default `T` |

## Default handler payload (`POST /api/v1/approval-routes`)

```json
{
  "title": "Update EUR PHSS",
  "description": "…",
  "category": "eur_update_phss",
  "approvers": [
    { "level": 1, "users": [{ "id": "<guid>", "full_name": "…", "email": "…" }] },
    { "level": 2, "users": [{ "id": "<guid>", "full_name": "…", "email": "…" }] }
  ]
}
```
