#!/usr/bin/env bash
# POLICY: GW-relais-rest
# REF: SPEC-001.5 | SPEC-001.6 | CA-002-3
# QUAND: deployed
# La passerelle relaie /rest/v1/* vers PostgREST : GET $APP_URL/rest/v1/ (clé anon) → code < 500,
# ≠ 404, réponse JSON (OpenAPI ou erreur PostgREST), et non la page HTML du front.
python3 -I - <<'PY'
import os, sys
sys.path.append("/workspace/policies/lib")
import requests, devsecrets as sec
k = sec.load().get("ANON_KEY")
h = {"apikey": k, "Authorization": f"Bearer {k}"} if k else {}
try:
    r = requests.get(os.environ["APP_URL"] + "/rest/v1/", headers=h, timeout=5)
except requests.RequestException as e:
    print(f"GET /rest/v1/ : erreur {type(e).__name__}"); sys.exit(1)
ct = r.headers.get("Content-Type", "")
if r.status_code < 500 and r.status_code != 404 and "json" in ct:
    print(f"GET /rest/v1/ → {r.status_code} {ct.split(';')[0]} (relayé à PostgREST)"); sys.exit(0)
print(f"GET /rest/v1/ → {r.status_code} {ct or 'sans Content-Type'} : non relayé à PostgREST"); sys.exit(1)
PY
