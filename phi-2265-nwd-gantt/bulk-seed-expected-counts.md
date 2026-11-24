# PHI-2265 — Bulk seed: expected Gantt counts per filter

Seed: `src-be/DataAccess/Database/seed_phi_2265_nwd_gantt_bulk.sql` (worktree `phi-2265-nwd-gantt`), **applied to dev 2026-10-31**.
400 projects = 100 per sub-category (DLC, FL, GL, RTWS), `project_no` `SEED-BULK-<SUB>-001..100`. Each card runs 30–240 days, starting anywhere from 2024-01-01 to 2030-12-31, so some end in 2031.
Even-numbered projects are PHSS and odd-numbered are PEP. The zone alternates ABI/BD and ABO in pairs. DLC/FL go on SEED-RIG-01..03 (PHSS) or 04..05 (PEP); GL/RTWS go on an area of the same working area.

The counts below are **SEED-BULK cards only**. Real projects and the SEED-NWD seed may appear in the same response, so filter on `project_no LIKE SEED-BULK-%` when counting.
A card is counted in a year when its span overlaps that year (start ≤ 31 Dec and end ≥ 1 Jan).

## Check result (API on localhost:5071, 2026-10-31)

**256 calls** (4 sub-categories × 2 working areas × 2 zones × 2 tabs × years 2024–2031). **0 mismatches.** Every count matched, with no duplicate cards and HTTP 200 on every call.
Response time: p50 806 ms, p95 1077 ms, max 1767 ms.

## Status mix

| Sub | finished | in progress | on hold | draft | canceled |
|---|---|---|---|---|---|
| DLC | 28 | 25 | 14 | 26 | 7 |
| FL | 32 | 33 | 13 | 15 | 7 |
| GL | 23 | 36 | 16 | 20 | 5 |
| RTWS | 34 | 24 | 23 | 14 | 5 |

Overview tab = `status=in progress|finished`. Draft tab = `status=draft|canceled`. On-hold bulk projects have no approval process, so they show in neither tab.

## Expected cards — Overview tab

| Sub | Working area | Zone | 2024 | 2025 | 2026 | 2027 | 2028 | 2029 | 2030 | 2031 |
|---|---|---|---|---|---|---|---|---|---|---|
| DLC | PHSS | ABI/BD | 2 | 3 | 3 | 3 | 2 | 1 | 1 | 0 |
| DLC | PHSS | ABO | 1 | 4 | 6 | 4 | 4 | 3 | 2 | 0 |
| DLC | PEP | ABI/BD | 2 | 2 | 3 | 0 | 1 | 2 | 1 | 0 |
| DLC | PEP | ABO | 3 | 5 | 2 | 1 | 1 | 6 | 2 | 0 |
| FL | PHSS | ABI/BD | 2 | 5 | 3 | 0 | 2 | 4 | 3 | 0 |
| FL | PHSS | ABO | 4 | 9 | 5 | 4 | 2 | 0 | 2 | 0 |
| FL | PEP | ABI/BD | 2 | 4 | 4 | 2 | 2 | 3 | 3 | 0 |
| FL | PEP | ABO | 2 | 5 | 2 | 2 | 4 | 3 | 2 | 0 |
| GL | PHSS | ABI/BD | 1 | 1 | 4 | 3 | 4 | 3 | 3 | 0 |
| GL | PHSS | ABO | 3 | 6 | 4 | 2 | 1 | 5 | 1 | 0 |
| GL | PEP | ABI/BD | 3 | 2 | 2 | 3 | 2 | 1 | 5 | 3 |
| GL | PEP | ABO | 2 | 6 | 4 | 3 | 3 | 4 | 1 | 0 |
| RTWS | PHSS | ABI/BD | 1 | 4 | 2 | 3 | 2 | 3 | 3 | 0 |
| RTWS | PHSS | ABO | 4 | 4 | 1 | 1 | 4 | 3 | 2 | 0 |
| RTWS | PEP | ABI/BD | 4 | 4 | 5 | 0 | 1 | 1 | 3 | 1 |
| RTWS | PEP | ABO | 5 | 5 | 5 | 2 | 1 | 0 | 0 | 0 |

## Expected cards — Draft tab

| Sub | Working area | Zone | 2024 | 2025 | 2026 | 2027 | 2028 | 2029 | 2030 | 2031 |
|---|---|---|---|---|---|---|---|---|---|---|
| DLC | PHSS | ABI/BD | 0 | 1 | 2 | 2 | 2 | 3 | 4 | 1 |
| DLC | PHSS | ABO | 1 | 1 | 0 | 3 | 2 | 1 | 0 | 0 |
| DLC | PEP | ABI/BD | 0 | 1 | 2 | 4 | 1 | 2 | 3 | 0 |
| DLC | PEP | ABO | 0 | 1 | 2 | 3 | 4 | 1 | 0 | 0 |
| FL | PHSS | ABI/BD | 1 | 2 | 2 | 1 | 2 | 0 | 0 | 0 |
| FL | PHSS | ABO | 1 | 1 | 0 | 1 | 2 | 2 | 2 | 0 |
| FL | PEP | ABI/BD | 0 | 1 | 2 | 2 | 2 | 1 | 2 | 1 |
| FL | PEP | ABO | 1 | 0 | 0 | 0 | 0 | 1 | 4 | 2 |
| GL | PHSS | ABI/BD | 1 | 1 | 0 | 2 | 2 | 2 | 2 | 1 |
| GL | PHSS | ABO | 0 | 0 | 0 | 0 | 3 | 3 | 1 | 1 |
| GL | PEP | ABI/BD | 0 | 1 | 0 | 1 | 0 | 4 | 1 | 0 |
| GL | PEP | ABO | 1 | 2 | 2 | 2 | 2 | 1 | 2 | 0 |
| RTWS | PHSS | ABI/BD | 1 | 2 | 1 | 0 | 0 | 2 | 2 | 1 |
| RTWS | PHSS | ABO | 1 | 0 | 0 | 0 | 1 | 2 | 1 | 0 |
| RTWS | PEP | ABI/BD | 0 | 0 | 0 | 3 | 1 | 1 | 0 | 0 |
| RTWS | PEP | ABO | 1 | 1 | 1 | 0 | 1 | 1 | 2 | 2 |

## Example

```bash
curl -s -G 'http://localhost:5071/api/v1/projects/nwd' -H "Authorization: Bearer $TOKEN" \
  --data-urlencode 'working_area=PHSS' --data-urlencode 'zone=ABI/BD' --data-urlencode 'sub_category=DLC' \
  --data-urlencode 'year=2028' --data-urlencode 'status=in progress|finished'
```

Expected: 2 SEED-BULK cards (row above, DLC / PHSS / ABI/BD / 2028).

## Cleanup

See the commented DELETE block at the end of the seed file (ids `5eed0000-0000-0000-0010..0013-*`).
