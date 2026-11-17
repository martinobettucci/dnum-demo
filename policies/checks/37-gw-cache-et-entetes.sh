#!/usr/bin/env bash
# POLICY: GW-cache-et-entetes
# REF: SPEC-001.9 | ADR-002 | CA-002-3 | incident de recette itération 002 (navigateur client jamais rechargé)
# QUAND: deployed
# Lecture seule : GET uniquement, sur $APP_URL/, /app.js, /config.js, /style.css, /vendor/supabase.js.
# Pour chacun : statut 200 ; Cache-Control contient la directive no-cache ; présence de
# Content-Security-Policy, X-Content-Type-Options (valeur nosniff) et Referrer-Policy.
python3 -I - <<'PY'
import os, sys
import requests

U = os.environ["APP_URL"]
CHEMINS = ("/", "/app.js", "/config.js", "/style.css", "/vendor/supabase.js")
bad = []
for p in CHEMINS:
    try:
        r = requests.get(U + p, timeout=5)
    except requests.RequestException as e:
        bad.append(f"{p} : erreur {type(e).__name__}"); continue
    h = {k.lower(): v for k, v in r.headers.items()}
    if r.status_code != 200:
        bad.append(f"{p} → {r.status_code}"); continue
    directives = [d.strip().lower() for d in h.get("cache-control", "").split(",")]
    if "no-cache" not in directives:
        bad.append(f"{p} : Cache-Control « {h.get('cache-control', 'absent')} » (no-cache attendu)")
    if not h.get("content-security-policy"):
        bad.append(f"{p} : Content-Security-Policy absente")
    if h.get("x-content-type-options", "").strip().lower() != "nosniff":
        bad.append(f"{p} : X-Content-Type-Options « {h.get('x-content-type-options', 'absent')} » (nosniff attendu)")
    if not h.get("referrer-policy"):
        bad.append(f"{p} : Referrer-Policy absente")
if bad:
    print("en-têtes non conformes : " + " ; ".join(bad)); sys.exit(1)
print("5 fichiers servis en 200 : Cache-Control no-cache ; CSP, X-Content-Type-Options nosniff, Referrer-Policy présents")
PY
