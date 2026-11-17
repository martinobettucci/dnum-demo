#!/usr/bin/env bash
# POLICY: FRONT-bundle-servi-egal-source
# REF: ADR-006 §2 | SPEC-001.8 | CA-002-2 | incident de recette itération 002 (bundle servi ≠ bundle construit)
# QUAND: deployed
# Lecture seule. Comparaison par empreintes sha256 uniquement (jamais par recherche dans le bundle minifié).
#  - GET $APP_URL/build-sha256.txt : fichier d'empreintes écrit au build dans l'image (format « <sha256>  <chemin> »,
#    chemins app.js et vendor/supabase.js). Absent, non servi (repli HTML de la passerelle) ou illisible : violée.
#  - GET $APP_URL/app.js et GET $APP_URL/vendor/supabase.js : sha256 des octets SERVIS == empreinte du build.
# Le runner ne joint pas l'adresse LAN de l'hôte (ADR-007, SPEC-006 §5) : la pile est interrogée par APP_URL.
python3 -I - <<'PY'
import hashlib, os, re, sys
import requests

U = os.environ["APP_URL"]
ATTENDUS = ("app.js", "vendor/supabase.js")

def get(chemin):
    try:
        return requests.get(U + chemin, timeout=5)
    except requests.RequestException as e:
        print(f"GET {chemin} : erreur {type(e).__name__}"); sys.exit(1)

# 1. Empreintes du build, servies par la passerelle.
r = get("/build-sha256.txt")
ct = r.headers.get("Content-Type", "")
if r.status_code != 200 or "text/html" in ct:
    print(f"/build-sha256.txt absent ou non servi (statut {r.status_code}, Content-Type « {ct or 'absent'} », "
          "repli HTML possible) : empreintes du build non vérifiables, à produire par build.mjs dans dist/")
    sys.exit(1)
ligne = re.compile(r"^([0-9a-f]{64})\s+\*?(\S+)\s*$")
empreintes = {}
for ln in r.text.splitlines():
    if not ln.strip():
        continue
    m = ligne.match(ln)
    if not m:
        print("/build-sha256.txt : ligne mal formée (attendu « <sha256>  <chemin> ») : fichier non conforme"); sys.exit(1)
    chemin = re.sub(r"^(\./|/)?(dist/)?", "", m.group(2))
    empreintes[chemin] = m.group(1)
manquants = [c for c in ATTENDUS if c not in empreintes]
if manquants:
    print(f"/build-sha256.txt : empreinte absente pour {', '.join(manquants)}"); sys.exit(1)

# 2. Octets servis, comparés aux empreintes du build.
bad = []
for chemin in ATTENDUS:
    rc = get("/" + chemin)
    if rc.status_code != 200:
        bad.append(f"/{chemin} → {rc.status_code}"); continue
    servi = hashlib.sha256(rc.content).hexdigest()
    if servi != empreintes[chemin]:
        bad.append(f"/{chemin} servi {servi[:12]} ≠ build {empreintes[chemin][:12]}")
if bad:
    print("bundle servi différent du build : " + " ; ".join(bad)); sys.exit(1)
print("app.js et vendor/supabase.js servis : sha256 identiques à /build-sha256.txt (build)")
PY
