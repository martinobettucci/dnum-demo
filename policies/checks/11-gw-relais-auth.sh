#!/usr/bin/env bash
# POLICY: GW-relais-auth
# REF: SPEC-001.5 | SPEC-001.6 | CA-002-3
# QUAND: deployed
# La passerelle relaie /auth/v1/* vers GoTrue : GET $APP_URL/auth/v1/health → 200, réponse JSON
# (et non la page HTML du front servie en repli).
python3 -I - <<'PY'
import os, sys
sys.path.append("/workspace/policies/lib")
import requests, devsecrets as sec
k = sec.load().get("ANON_KEY")
h = {"apikey": k} if k else {}
try:
    r = requests.get(os.environ["APP_URL"] + "/auth/v1/health", headers=h, timeout=5)
except requests.RequestException as e:
    print(f"GET /auth/v1/health : erreur {type(e).__name__}"); sys.exit(1)
ct = r.headers.get("Content-Type", "")
try:
    j = r.json()
except ValueError:
    j = None
if r.status_code == 200 and "json" in ct and isinstance(j, dict):
    print(f"GET /auth/v1/health → 200 JSON (relayé à GoTrue{', ' + str(j.get('version')) if j.get('version') else ''})"); sys.exit(0)
print(f"GET /auth/v1/health → {r.status_code} {ct or 'sans Content-Type'} : non relayé à GoTrue"); sys.exit(1)
PY
