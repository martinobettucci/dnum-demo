#!/usr/bin/env bash
# POLICY: GW-csp
# REF: SPEC-001.9 | ADR-002 | CA-002-3
# QUAND: deployed
# GET $APP_URL/ (HTML) porte un en-tête Content-Security-Policy unique contenant
# default-src 'self' et connect-src 'self', connect-src n'autorisant aucune autre source.
python3 -I - <<'PY'
import os, sys, requests
try:
    r = requests.get(os.environ["APP_URL"] + "/", timeout=5)
except requests.RequestException as e:
    print(f"GET / : erreur {type(e).__name__}"); sys.exit(1)
vals = [v for k, v in r.raw.headers.items() if k.lower() == "content-security-policy"] if r.raw else []
vals = vals or ([r.headers["Content-Security-Policy"]] if "Content-Security-Policy" in r.headers else [])
if not vals:
    print(f"GET / → {r.status_code} sans en-tête Content-Security-Policy"); sys.exit(1)
if len(vals) > 1:
    print(f"{len(vals)} en-têtes Content-Security-Policy (un seul attendu)"); sys.exit(1)
csp = vals[0]
dirs = {}
for part in csp.split(";"):
    toks = part.split()
    if toks:
        dirs[toks[0].lower()] = toks[1:]
bad = []
if "text/html" not in r.headers.get("Content-Type", ""):
    bad.append(f"Content-Type={r.headers.get('Content-Type')}")
if dirs.get("default-src") != ["'self'"]:
    bad.append(f"default-src={' '.join(dirs.get('default-src', ['absent']))}")
if dirs.get("connect-src") != ["'self'"]:
    bad.append(f"connect-src={' '.join(dirs.get('connect-src', ['absent']))}")
if bad:
    print("CSP non conforme : " + " ; ".join(bad)); sys.exit(1)
print("CSP présente sur / : default-src 'self', connect-src 'self' (aucune autre source)")
PY
