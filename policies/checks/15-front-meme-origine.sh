#!/usr/bin/env bash
# POLICY: FRONT-meme-origine
# REF: SPEC-001.8 | SPEC-001.10 | ADR-002 | CA-002-2 | CA-002-3
# QUAND: deployed
# Fichiers servis /, /app.js, /config.js, /style.css : 200, les trois derniers ne sont pas la page
# HTML de repli ; aucun ne contient :9999, :3000, :5432, http://auth, http://rest, localhost ;
# /config.js contient ANON_KEY de .devenv/secrets/dev.env et aucun autre JWT ; la valeur de
# SERVICE_ROLE_KEY et JWT_SECRET n'apparaît dans aucun fichier servi. Valeurs jamais affichées.
python3 -I - <<'PY'
import os, re, sys
sys.path.append("/workspace/policies/lib")
import requests, devsecrets as sec
U = os.environ["APP_URL"]
s = sec.load()
bad, corps = [], {}
for p in ("/", "/app.js", "/config.js", "/style.css"):
    try:
        r = requests.get(U + p, timeout=5)
    except requests.RequestException as e:
        bad.append(f"{p} : erreur {type(e).__name__}"); continue
    ct = r.headers.get("Content-Type", "")
    if r.status_code != 200:
        bad.append(f"{p} → {r.status_code}"); continue
    if p != "/" and "text/html" in ct:
        bad.append(f"{p} servi en text/html (repli du front ?)")
    corps[p] = r.text
    for motif in (":9999", ":3000", ":5432", "http://auth", "http://rest", "localhost"):
        if motif in r.text:
            bad.append(f"{p} contient « {motif} »")
    for k in ("SERVICE_ROLE_KEY", "JWT_SECRET", "POSTGRES_PASSWORD", "ADMIN_PASSWORD"):
        if s.get(k) and s[k] in r.text:
            bad.append(f"{p} contient la valeur de {k}")
cfg = corps.get("/config.js", "")
jwts = set(re.findall(r"eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+", cfg))
if "/config.js" in corps:
    if not s.get("ANON_KEY"):
        bad.append("ANON_KEY introuvable dans .devenv/secrets/dev.env : comparaison impossible")
    elif jwts != {s["ANON_KEY"]}:
        bad.append(f"/config.js : {len(jwts)} JWT dont ANON_KEY={'oui' if s['ANON_KEY'] in jwts else 'non'} (attendu : ANON_KEY seule)")
for p in ("/", "/app.js", "/style.css"):
    if re.search(r"eyJ[A-Za-z0-9_-]{10,}\.eyJ", corps.get(p, "")):
        bad.append(f"{p} contient un JWT en dur")
if bad:
    print("front non conforme : " + " ; ".join(bad)); sys.exit(1)
print("4 fichiers servis sans URL d'autre hôte/port ; /config.js = ANON_KEY seule ; aucune clé service/secret servi")
PY
