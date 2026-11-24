# Sheet change log — "Phantom PHI Mapping" (2026-10-12)

Approved by the owner in chat. Rollback values below.

## Method column (E): PUT / DELETE → POST (the .NET routes are all POST)

- Was **PUT**: E4 E5 E9 E13 E16 E21 E26 E42 E50 E75 E76 E77 E80 E85 E91 E97 E102 E108 E120 E121 E126 E135 E141 E146 E147 E149 E155 E167 E172 E179 E195 E203 E209 E214 E227 E244 E254 E264 E273 E283 E288 E291
- Was **DELETE**: E10 E17 E22 E27 E41 E51 E68 E74 E81 E86 E92 E117 E127 E136 E142 E148 E156 E164 E168 E173 E180 E249 E255 E265 E284 E289 E292 E293

## Priviledge ID column (G): PHSS / PEP split (153–156)

| Rows | Was | Now |
|---|---|---|
| PHSS reads G186 G188 G189 G191 G205 G206 G207 G224 G226 G228 G229 G230 | 137 | 153 |
| PHSS writes G208 G210 G225 G227 G231 | 139 | 154 |
| PHSS write G209 (Update PHSS Action Plan Draft) | 137 (was wrong) | 154 |
| PEP reads G187 G190 G192 G199 G200 G201 G217 G219 G220 G221 G222 | 137 | 155 |
| PEP writes G202 G203 G204 G218 G223 | 139 | 156 |

## Shared {type} routes split into PHSS / PEP rows (2026-10-12, second change)

Before: rows 193–198, 232, 233 were single shared rows on `:type` with 137 (GET) / 139 (POST):
193 Read Tubing-Casing (GET 137), 194 Upsert Tubing-Casing (POST 139), 195 Update EUR Monitoring (POST 139),
196 Read Decline (GET 137), 197 Read Panel (GET 137), 198 Read Schematic (GET 137),
232 Read Histories Chart (GET 137), 233 Validate Well ID (GET 137).

After: each became a PHSS row (`:type` → `phss`, 153 / 154) with a PEP row inserted under it
(`:type` → `pep`, 155 / 156). Rows below 193 shifted down (+6 after 198, +8 after 233).
Row 185 `/well-surveillance/dropdowns/:type` stays shared: there `type` is a dropdown category.
Rollback: delete the 8 inserted PEP rows and restore the originals above.

## 2026-10-12 — split `:type` routes into PHSS / PEP rows

8 rows inserted (194, 196, 198, 200, 202, 204, 239, 241). Each original `:type` row (193, 195, 197,
199, 201, 203, 238, 240) is now the PHSS row (`phss`, GET 153 / POST 154); the inserted row below it is
the PEP row (`pep`, GET 155 / POST 156). Verified by read-back. `dropdowns/:type` (row 185) stays shared.
Rollback: delete the 8 inserted rows, restore `:type` in column D and 137/139 in column G.

## 2026-10-12 — rows for 5 code routes missing from the sheet

10 rows inserted at 242–251 (PHSS / PEP pairs, all GET, 153 / 155): histories chart rtws, mtu,
sonolog; well alert (`/wells/{wa}/:well_detail_id/alert`); choke-update-info. Verified by read-back.
Rollback: delete rows 242–251.

## 2026-10-14 — sheet restored by the owner; new IDs moved to column H "New Priviligie"

The owner restored "Phantom PHI Mapping" to its original state (G = 137/139, `:type` rows, PUT/DELETE
methods, no inserted rows) and added column H "New Priviligie". Column G is the current ID, H the new
one. Filled H186:H210 and H217:H233 (42 cells; verified by read-back):
`/phss` GET 153, write 154 · `/pep` GET 155, write 156 · `:type` rows "153 (PHSS) / 155 (PEP)" (GET) or
"154 (PHSS) / 156 (PEP)" (POST/PUT) · H209 Update PHSS Action Plan Draft = 154 (G says 137).
Shared rows (overview card, dropdowns, well-zone, /wells/all, action-plan calendar, EUR, compressor)
left empty = unchanged. Rollback: clear H186:H233.
Note: rbac-permission-changes.xlsx tabs "Sheet - Privilege IDs" / "Sheet - Methods" describe the
2026-10-12 edits that the owner has since reverted.

## 2026-10-14 — endpoints from "Mapping PO and SDA" missing in "Phantom PHI Mapping" added

Every endpoint marked "Not in Phantom PHI Mapping" (plus rtws/mtu/sonolog, alert, choke-update-info, which
the restored sheet lacks) checked against merged phi-dev code (path + method from the Map* calls; all
behind R3ComponentFilter). Added 21 rows (G = privilege today, H = new privilege):
- Well Monitoring (rows 234–247): PHSS/PEP well zone detail (137 → 153/155), PHSS/PEP well status
  (139 → 154/156), histories chart rtws/mtu/sonolog, well alert, choke-update-info (137 → 153/155 by
  type), well-zone remarks read / timeline (137) and add / update / delete (139, all POST in code).
- Well Monitoring EUR (rows 256–260): eur/highlight (140), alert-notification-setting GET (140) / POST
  (138), decline-rate template GET (140), decline-rate import POST (138).
- NEW group 26 "Unit Conversion" (rows 331–332): GET 157, POST 158 (new privileges; not in DB/Retina).
Skipped: /notifications/unread and /my-task-badge — login-only, no privilege.
"Phantom PHI - NEW" numbering (137 = Area, 207+ = wells) conflicts with the current scheme — not reused.
First attempt put the EUR rows inside the Compressor block (row miscount) — deleted and re-added; verified.
Rollback: delete rows 331–332, 256–260, 234–247 (bottom first).

## 2026-10-14 — URL Group (column B) split by working area

Sheet had shifted +1 row (owner edits; EUR rows now labelled "Eur" at A257). Well Monitoring block is rows
185–256. Unmerged B185:B256 (one merged "/well-surveillance" cell) and set B per row: "PHSS" when the URL
has a `phss` segment (20 rows), "PEP" for `pep` (18), "/well-surveillance" for every other row (34,
incl. `:type` / `:workingArea` and shared routes). Verified by read-back: every PHSS row has H 153/154,
every PEP row 155/156. Rollback: write "/well-surveillance" in B185, clear B186:B256, merge B185:B256.

## 2026-10-14 — URL Group = real path; Well block regrouped (shared → PHSS → PEP → EUR)

Replaced the PHSS / PEP labels in B with real path prefixes taken from each URL: the path up to the
`phss` / `pep` segment (e.g. `/wells/phss`, `/well-surveillance/wells/pep`,
`/well-surveilence/action-plans/phss`), else the first segment (`/well-surveillance`,
`/well-zone-assignments`, `/well-zones`, `/wells`, `/eur`, `/eur-cumprod`). Rewrote B185:H256 (I:Z empty,
A unchanged) in a new order: shared group-19 rows 185–213 (grouped by URL group), PHSS 214–233, PEP
234–251, group-20 EUR 252–256. Same 72 rows, values unchanged except B (script-checked); Group ID 19 stays
on row 185 and 20 on row 252. Rollback: previous order is in the 2026-10-14 read-back
(scratchpad well_block.json).

## 2026-10-14 — combined "153 (PHSS) / 155 (PEP)" rows split into separate PHSS and PEP rows

The 13 shared `:type` / `:workingArea` rows (tubing-casing GET/POST, update EUR monitoring, decline,
panel, schematic, histories chart, validate-id, chart rtws/mtu/sonolog, well alert, choke-update-info)
each became a PHSS row and a PEP row: URL `:type`/`:workingArea` → `phss`/`pep`, name gets PHSS/PEP,
H a single id (153/154 or 155/156), G unchanged (137/139), B the real path. Inserted 13 rows and
rewrote B185:H269: shared 185–200 (16), PHSS 201–233 (33), PEP 234–264 (31), group-20 EUR 265–269.
Script-checked (every PHSS row 153/154, every PEP row 155/156, shared rows no H; Group ID 19 on 185,
20 on 265); search for "(PHSS) /" in the sheet returns nothing. The owner's "Eur" block now starts at 270.
Rollback: delete the 13 rows and restore the previous order (scratchpad well_block_BH.json).

## 2026-10-14 — View (GET) / Modify (POST) only; repair of a whole-spreadsheet Find & replace

Owner request: only two permissions — VIEW = GET, MODIFY = POST. The owner changed PUT/DELETE → POST with a
Find & replace that ran on ALL tabs and matched inside words: "Delete…" → "POST…", "Deleted" → "POSTd",
"input" → "inPOST" (incl. URL `/wells/phss/:well_id/gas-lift-inPOSTs`).
Repaired in "Phantom PHI Mapping" only (45 cells, columns C/D/I/K; Method column E left as POST):
C11 C18 C23 C28 C52 C82 C87 C93 C181 = "Delete"; "Delete <name>" in C42 C69 C75 C118 C128 C137 C143 C149
C157 C165 C169 C174 C195 C282 C288 C298 C317 C322 C325 C335 C340 C343 C344; "Deleted the …" in K28 K42
K52 K69 K75 K93 K118; "Input" in C54 I54 K54; C221/D221 gas-lift "Inputs" / "inputs". Search for "POST "
and "POSTd" in the tab now returns nothing.
NOT repaired (owner to decide — restore via File → Version history is the clean fix): same damage in
Phantom PHI, Copy of Phantom PHI Mapping, IPMS PHI, IPMS Ocean, Phantom PHI - NEW, PHI-NEW by Method,
Mapping PO and SDA (B13 "InPOST EUR"); their PUT/DELETE methods also became POST.
View/Modify rule in the Well + EUR area (rows 185–274) now holds on every row: GET → G 137 (well) / 140
(EUR), H 153 (PHSS) / 155 (PEP); POST → G 139 / 138, H 154 / 156. Fixed G232 Update PHSS Action Plan
Draft 137 → 139 (was a view id on a write route).

## 2026-10-14 — Find & replace damage repaired in all other tabs

No version restore was done; the owner only meant to change PUT/DELETE → POST in method columns. Repaired
219 text cells (method cells untouched, they stay POST): Phantom PHI 30, IPMS PHI 30, IPMS Ocean 22, Copy of
Phantom PHI Mapping 59, Phantom PHI - NEW 47, PHI-NEW by Method 22, Mapping PO and SDA 1 (B13), Sheet3 8
(name field inside the CSV rows only). Rules: name cell "POST" → "Delete", "POST X" → "Delete X",
"POSTd" → "Deleted", "InPOST"/"inPOST" → "Input"/"input". Inferred "POST"-only name cells were read first
to confirm. Spreadsheet-wide searches for "POSTd", "nPOST", "POST " now return nothing.

## 2026-10-14 — sheet ↔ DB check (permission_groups, permissions) on "Phantom PHI Mapping"

Compared every group header (A name + F Group ID, F is merged per group) and every G/H privilege with dev DB
`permission_groups` (1–25) and `permissions` (151 rows, no duplicate ids).
- Groups 1–25: ids and names match the DB; every G privilege belongs to its group in the DB.
- Renamed A270 "Eur" → "Well Monitoring EUR" (DB name of group 20; F265:F274 already merged = 20).
- Not in the DB yet: privileges 153–156 (H, 66 rows) and group 26 "Unit Conversion" with 157/158 (rows 345–346).
- Rows 326–344 duplicate RKS Generator / Master Category / Master Clause rows 307–325 (same ids).
- DB permissions unused in the sheet: 90, 91 (Service Acceptance Delete/Create — sheet uses 89 Modify for
  all SA writes, consistent with View/Modify) and 113–116 (group 13 Project Approval Document).
- Deleted duplicate rows 326–344 (19 rows: repeats of RKS Generator 308–311, RKS Master Category 312–317,
  RKS Master Clause 318–325, plus a doubled "Delete RKS Sub-Clause"). RKS Master Clause now ends at 325;
  Unit Conversion moved to rows 326–327. Verified by read-back.

## 2026-10-14 — Working Area filter column

Inserted one column after H on "Phantom PHI Mapping" → new I "Working Area"; old I (notes) / J Action
Group / K Action Name are now J / K / L. No other values changed. I3:I327 filled by script from the D URL
path segments: `phss` → PHSS (33), `pep` → PEP (31), `:type` / `:workingArea` → PHSS & PEP (19: 18
compressor rows 275–292 + I186 `/well-surveillance/dropdowns/:type`), other rows in the Well Monitoring /
Well Monitoring EUR blocks 185–274 → Shared (25), everything else → "-" (217). I2 (blank frozen row) left empty.
Read-back: every phss row has H 153/154, every pep row H 155/156, no 153–156 elsewhere.
Basic filter set on H1:L327, not A1:L327: the API refuses a filter over any range with merges (A1:G2 header
merges + A/B/F group merges). Filtering on I still hides whole rows.
Rollback: delete column I (J/K/L shift back to I/J/K); clear the basic filter (Data → Remove filter /
`clearBasicFilter`) — there was no filter before.
- I186 (`/well-surveillance/dropdowns/:type`) set to "Shared": its `:type` is a dropdown category, not a working area. Counts now: PHSS 33, PEP 31, PHSS & PEP 18 (compressor `/:workingArea/` rows), Shared 26, "-" 217.
