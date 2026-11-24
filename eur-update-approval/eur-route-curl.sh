#!/usr/bin/env bash
# EUR update approval route — curl smoke test (eur_update_phss / eur_update_pep).
# Usage: TOK=<bearer> ./eur-route-curl.sh [api-base]   (default: deployed dev API)
# WRITES to the target DB: creates a route, updates it, then soft-deletes it.
set -euo pipefail
A=${1:-https://phantom-api.inproms.com/api/v1}
H=(-H "Authorization: Bearer $TOK" -H "Content-Type: application/json")
APPROVER=0703c05b-bba2-42c0-8b56-22c44a3333f4   # R3 Test Vicep; swap for a 154/156 holder once roles have them

echo "== approvers: by-permission 154 (PHSS) / 156 (PEP)"
curl -s "${H[@]}" "$A/users/by-permission/154"; echo
curl -s "${H[@]}" "$A/users/by-permission/156"; echo

echo "== create eur_update_phss"
curl -s "${H[@]}" -X POST "$A/approval-routes" -d '{
  "title": "CURL TEST - Update EUR PHSS",
  "description": "curl smoke test, safe to delete",
  "category": "eur_update_phss",
  "approvers": [{ "level": 1, "users": [{ "id": "'$APPROVER'", "full_name": "R3 Test Vicep", "email": "r3test.vicep@yopmail.com" }] }]
}'; echo

ID=$(curl -s "${H[@]}" "$A/approval-routes?category=eur_update_phss" \
  | python3 -c "import sys,json;l=json.load(sys.stdin)['data']['list'];print(next(r['id'] for r in l if r['title'].startswith('CURL TEST')))")
echo "route id: $ID"

echo "== detail"
curl -s "${H[@]}" "$A/approval-routes/$ID"; echo

echo "== update -> eur_update_pep"
curl -s "${H[@]}" -X POST "$A/approval-routes/$ID/update" -d '{
  "title": "CURL TEST - Update EUR PEP",
  "description": "curl smoke test, safe to delete",
  "category": "eur_update_pep",
  "status": "active",
  "approvers": [{ "level": 1, "users": [{ "id": "'$APPROVER'", "full_name": "R3 Test Vicep", "email": "r3test.vicep@yopmail.com" }] }]
}'; echo

echo "== delete (soft)"
curl -s "${H[@]}" -X POST "$A/approval-routes/$ID"; echo
