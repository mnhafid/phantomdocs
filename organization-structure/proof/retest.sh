#!/usr/bin/env bash
# Retest org-structure endpoints with curl (same requests as Bruno "Organization Structure" + "SSDP/Auth").
# Usage: retest.sh [base_url] [out.md]   — needs curl + jq; mock Retina login accepts any password.
set -u
BASE=${1:-http://127.0.0.1:5072}
OUT=${2:-retest-curl.md}
TMP=$(mktemp -d)
PASS=0; TOTAL=0; ROWS=""; DETAIL=""

# req <case> <expected status> <method> <path> [json body] [user] [jq check -> "true"/"false"]
req() {
  local case=$1 expect=$2 method=$3 path=$4 body=${5:-} user=${6:-} check=${7:-}
  local args=(-sS -v -X "$method" "$BASE$path" -H 'Accept: application/json')
  local shown="curl -X $method '$BASE$path' -H 'Accept: application/json'"
  if [[ -n $user ]]; then
    args+=(-H "Authorization: Bearer $(cat "$TMP/tok_$user")")
    shown+=" -H \"Authorization: Bearer \$TOKEN_$(echo "$user" | tr '.-' '__')\""
  fi
  if [[ -n $body ]]; then
    args+=(-H 'Content-Type: application/json' --data "$body")
    shown+=" -H 'Content-Type: application/json' --data '$body'"
  fi
  local status
  status=$(curl "${args[@]}" -o "$TMP/body" -w '%{http_code}' 2>"$TMP/verbose")
  local ok=false note=""
  if [[ $status == "$expect" ]]; then
    ok=true
    if [[ -n $check ]]; then
      [[ $(jq -r "$check" "$TMP/body" 2>/dev/null) == true ]] || ok=false
      note=$(jq -c "$check" "$TMP/body" 2>/dev/null)
    fi
  fi
  TOTAL=$((TOTAL + 1)); $ok && PASS=$((PASS + 1))
  local res; $ok && res=PASS || res=FAIL
  echo "$res $status $method $path [$case]"
  ROWS+="| $TOTAL | $case | \`$method $path\` | $expect | $status | $res |"$'\n'
  DETAIL+="## $TOTAL. $case — $res"$'\n\n'"\`\`\`bash"$'\n'"$shown"$'\n'"\`\`\`"$'\n\n'
  DETAIL+="**Request**"$'\n\n'"\`\`\`http"$'\n'"$(sed -n 's/^> //p' "$TMP/verbose" | tr -d '\r')"$'\n'
  [[ -n $body ]] && DETAIL+="$(jq . <<<"$body")"$'\n'
  DETAIL+="\`\`\`"$'\n\n'"**Response**"$'\n\n'"\`\`\`http"$'\n'"$(sed -n 's/^< //p' "$TMP/verbose" | tr -d '\r')"$'\n'
  DETAIL+="$(jq . "$TMP/body" 2>/dev/null || cat "$TMP/body")"$'\n'"\`\`\`"$'\n\n'
}

login() {  # login <user> <expected department>
  req "login $1" 200 POST /api/v1/auth/login "{\"username\":\"$1\",\"password\":\"any-password\"}" "" \
    ".data.department == \"$2\""
  jq -r '.data.access_token // empty' "$TMP/body" > "$TMP/tok_$1"
  jq -r '.data.refresh_token // empty' "$TMP/body" > "$TMP/ref_$1"
}

Q='?page=1&page_size=1'

# 1. logins — department "" = whitelisted (Senior Manager / General Manager / SuperAdmin) picks it
login r3test.sda1 "Subsurface Development Area 1"
login r3test.sda2 "Subsurface Development Area 2"
login r3test.po "Production Operations"
login r3test.sm.ssdp ""
login r3test.sm.pnp ""
login r3test.superadmin ""
login r3test.gm ""

# 2. profile + permissions
req "profile sda1" 200 GET /api/v1/users/profile "" r3test.sda1 '.data.organisation.division == "SSDP"'

# 2b. /users/permissions — map of privilege id -> [privilege group ids], from Retina (mock on dev)
NONEMPTY='(.data | type == "object" and length > 0)'
for u in r3test.sda1 r3test.sda2 r3test.po r3test.sm.ssdp r3test.sm.pnp r3test.superadmin r3test.gm; do
  req "permissions $u" 200 GET /api/v1/users/permissions "" "$u" "$NONEMPTY"
done
req "permissions without token" 401 GET /api/v1/users/permissions

# 2c. TS-32..TS-34, TS-36 — new PHSS / PEP privileges (FE guard reads these ids). Exact sets, by role.
IDS() { echo "(.data | keys | map(tonumber) | sort) == $1"; }
HAS() { echo "((.data | keys | map(tonumber)) as \$x | ($1 - \$x | length == 0))"; }
GRP='(.data["153"] // ["19"])[0] == "19" and (.data["154"] // ["19"])[0] == "19" and (.data["155"] // ["19"])[0] == "19" and (.data["156"] // ["19"])[0] == "19" and (.data["138"] // ["20"])[0] == "20" and (.data["140"] // ["20"])[0] == "20"'
req "TS-32 permissions SDA 1 = view+modify PHSS" 200 GET /api/v1/users/permissions "" r3test.sda1 "$(IDS '[137,138,139,140,153,154]') and $GRP"
req "TS-33 permissions SDA 2 = view+modify PEP" 200 GET /api/v1/users/permissions "" r3test.sda2 "$(IDS '[137,138,139,140,155,156]') and $GRP"
req "TS-34 permissions PO = view only" 200 GET /api/v1/users/permissions "" r3test.po "$(IDS '[137,140,153,155]') and $GRP"
req "TS-36 permissions SuperAdmin has 153-158" 200 GET /api/v1/users/permissions "" r3test.superadmin \
  "$(HAS '[153,154,155,156,157,158]') and .data[\"157\"][0] == \"26\" and .data[\"158\"][0] == \"26\" and $GRP"

# 3. working area: SDA 1 = PHSS, SDA 2 = PEP, PO = both
req "sda1 PHSS wells" 200 GET "/api/v1/wells/phss$Q" "" r3test.sda1
req "sda1 PEP wells (hidden)" 404 GET "/api/v1/wells/pep$Q" "" r3test.sda1
req "sda2 PEP wells" 200 GET "/api/v1/wells/pep$Q" "" r3test.sda2
req "sda2 PHSS wells (hidden)" 404 GET "/api/v1/wells/phss$Q" "" r3test.sda2
req "po PHSS wells" 200 GET "/api/v1/wells/phss$Q" "" r3test.po
req "po PEP wells" 200 GET "/api/v1/wells/pep$Q" "" r3test.po
req "sda1 eur-monitoring PHSS" 200 GET "/api/v1/well-surveillance/wells/phss/eur-monitoring$Q" "" r3test.sda1
req "sda1 eur-monitoring PEP (hidden)" 404 GET "/api/v1/well-surveillance/wells/pep/eur-monitoring$Q" "" r3test.sda1

# 4. senior manager picks a department (ends back on SDA 2, the test user's starting state)
req "sm.ssdp department options" 200 GET /api/v1/users/me/department/options "" r3test.sm.ssdp
req "sm.ssdp choose SDA 1" 200 POST /api/v1/users/me/department '{"department":"Subsurface Development Area 1"}' r3test.sm.ssdp \
  '.data.organisation.division == "SSDP" and .data.role.id == 1114'
req "sm.ssdp profile after pick" 200 GET /api/v1/users/profile "" r3test.sm.ssdp \
  '.data.organisation.department == "Subsurface Development Area 1"'
req "sm.ssdp PHSS wells after SDA 1 pick" 200 GET "/api/v1/wells/phss$Q" "" r3test.sm.ssdp
req "sm.ssdp PEP wells after SDA 1 pick (hidden)" 404 GET "/api/v1/wells/pep$Q" "" r3test.sm.ssdp
req "sm.ssdp choose SDA 2 (restore)" 200 POST /api/v1/users/me/department '{"department":"Subsurface Development Area 2"}' r3test.sm.ssdp
req "sm.ssdp PEP wells after SDA 2 pick" 200 GET "/api/v1/wells/pep$Q" "" r3test.sm.ssdp

# 4b. privileges follow the picked department (t108). Only indana has a per-role mock Retina row
#     ("r3test.indana|regulator of Subsurface Development Area 1"), so this flow uses indana.
login r3test.indana ""
req "permissions indana (no department picked)" 200 GET /api/v1/users/permissions "" r3test.indana "$NONEMPTY"
INDANA_N=$(jq '.data | length' "$TMP/body")
req "indana choose SDA 1" 200 POST /api/v1/users/me/department '{"department":"Subsurface Development Area 1"}' r3test.indana \
  '.data.role.id == 1114'
req "TS-35 permissions indana after SDA 1 pick = SDA 1 set" 200 GET /api/v1/users/permissions "" r3test.indana \
  "$(IDS '[137,138,139,140,153,154]')"
req "indana choose SDA 2" 200 POST /api/v1/users/me/department '{"department":"Subsurface Development Area 2"}' r3test.indana \
  '.data.role.id == 1115'
req "TS-35 permissions indana after SDA 2 pick = SDA 2 set" 200 GET /api/v1/users/permissions "" r3test.indana \
  "$(IDS '[137,138,139,140,155,156]')"
req "indana choose PO" 200 POST /api/v1/users/me/department '{"department":"Production Operations"}' r3test.indana \
  '.data.role.id == 1105'
req "TS-35 permissions indana after PO pick = PO set (view only)" 200 GET /api/v1/users/permissions "" r3test.indana \
  "$(IDS '[137,140,153,155]')"
req "indana choose OSF (restore)" 200 POST /api/v1/users/me/department '{"department":"Operation & Surface Facilities"}' r3test.indana \
  '.data.role.id == 1108'
req "permissions indana after OSF pick (back to full set)" 200 GET /api/v1/users/permissions "" r3test.indana \
  "(.data | length) == $INDANA_N"

# 4c. TS-38 ACL per SYSROLE: sm.pnp holds Retina SYSROLEs Project / OSF / PO; the picked department picks one.
req "TS-38 sm.pnp choose Production Operations" 200 POST /api/v1/users/me/department '{"department":"Production Operations"}' r3test.sm.pnp
req "TS-38 permissions sm.pnp after PO pick = view EUR + Well only" 200 GET /api/v1/users/permissions "" r3test.sm.pnp \
  "$(IDS '[137,140,153,155]')"
req "TS-38 sm.pnp choose Operation & Surface Facilities" 200 POST /api/v1/users/me/department '{"department":"Operation & Surface Facilities"}' r3test.sm.pnp
req "TS-38 permissions sm.pnp after OSF pick = compressor set" 200 GET /api/v1/users/permissions "" r3test.sm.pnp \
  "$(IDS '[141,142,144]')"
req "TS-38 sm.pnp choose SDA 1 (holds no such SYSROLE)" 200 POST /api/v1/users/me/department '{"department":"Subsurface Development Area 1"}' r3test.sm.pnp
req "TS-38 permissions sm.pnp, no matching SYSROLE = Data Config only" 200 GET /api/v1/users/permissions "" r3test.sm.pnp \
  "$(IDS '[159]')"
req "TS-38 sm.pnp choose Production Operations (restore)" 200 POST /api/v1/users/me/department '{"department":"Production Operations"}' r3test.sm.pnp

# 5. refresh keeps the organisation block
req "refresh sda1" 200 POST /api/v1/auth/refresh "{\"refresh_token\":\"$(cat "$TMP/ref_r3test.sda1")\"}" "" \
  '.data.organisation.division == "SSDP"'

{
  echo "# Retest with curl — organization structure ($(date +%F))"
  echo
  echo "Base URL \`$BASE\`. Generated by \`proof/retest.sh\`. JWTs are shortened to their first 16 chars + length."
  echo
  echo "**Result: $PASS/$TOTAL passed.**"
  echo
  echo "| # | Case | Request | Expected | Got | Result |"
  echo "|---|---|---|---|---|---|"
  printf '%s' "$ROWS"
  echo
  printf '%s' "$DETAIL"
} | perl -pe 's/(eyJ[\w-]{13})[\w-]*\.[\w-]+\.[\w-]+/$1…(jwt)/g' > "$OUT"
rm -rf "$TMP"
echo "$PASS/$TOTAL passed -> $OUT"
