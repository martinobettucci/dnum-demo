#!/usr/bin/env bash
# POLICY: FRONT-audit-npm
# REF: SPEC-001.15 (b)(c) | ADR-010 | ADR-014 | CA-002-2
# QUAND: always
# Audit des dépendances npm de app/web, lu depuis iterations/<NNN>/policies/ (NNN = iterations/CURRENT, ADR-014 §2-§4).
# Les deux fichiers sont produits HORS runner par `./dev audit-npm` (hôte, image node:22.12.0-alpine) :
#  - audit-npm.json      : sortie brute de `npm audit --json` ;
#  - audit-npm.meta.json : { statut, package_lock_sha256, image, date } (ADR-014 §2).
# Le runner n'a ni Docker ni Node. Cette policy ne fait aucun appel réseau et ne lance aucun conteneur.
#  - échec (« non exécutée ») si un fichier manque, est vide, non JSON, sans rapport d'audit ;
#  - échec si audit-npm.meta.json est absent, si son statut n'est pas « reussie », ou si son package_lock_sha256
#    diffère du sha256 actuel de app/web/package-lock.json (ADR-014 §3). La comparaison de dates est retirée ;
#  - échec si un identifiant GHSA n'est pas listé dans ADR-010 (attendus : GHSA-67mh-4wv8-2f99 esbuild,
#    GHSA-8r88-6cj9-9fh5 auth-js) ; échec si un paquet hors esbuild / auth-js / supabase-js apparaît ;
#    échec si un avis est de sévérité haute ou critique ;
#  - GHSA-8r88-6cj9-9fh5 (auth-js) : cas A, voie 1 (ADR-010, SPEC-001.15 (b)(d)(e)). Non bloquant pour
#    ./dev deploy service, sous condition de la policy 28 FRONT-auth-js-non-appel (SPEC-001.15 (e)).
# Ligne 17 : BLOQUE_AUTHJS="non" sur décision de structure (ADR-010 voie 1, ADR-013 D-1). Passer à "oui" rétablit le
#    blocage de deploy service et impose la réévaluation de ADR-010 (SPEC-001.15 (d)).
#  - garde esbuild (ADR-010 cas A, ADR-013 D-1) : serve, watch ou context( dans les scripts de build de app/web
#    (racine : *.mjs, *.cjs, *.js, *.ts) fait passer la policy en violée (cas C, réévaluation obligatoire) ;
#    sans occurrence, c'est une simple note.
BLOQUE_AUTHJS="non"
export BLOQUE_AUTHJS
python3 -I - <<'PY'
import hashlib, json, os, pathlib, re, sys
ROOT = pathlib.Path("/workspace")
LOCK = ROOT / "app/web/package-lock.json"
WEB = ROOT / "app/web"
BLOQUE_AUTHJS = os.environ.get("BLOQUE_AUTHJS", "non")
GHSA = re.compile(r"GHSA-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}")
LISTES = {
    "GHSA-67mh-4wv8-2f99": "esbuild, cas A (ADR-010)",
    "GHSA-8r88-6cj9-9fh5": "auth-js, cas A voie 1 (ADR-010)",
}
PAQUETS = {"esbuild", "@supabase/auth-js", "@supabase/supabase-js"}
RISQUE_ESBUILD = re.compile(r"\b(serve|watch)\b|\bcontext\s*\(")

def non_executee(msg):
    print("audit npm non exécutée (échec, pas « réussie ») : " + msg); sys.exit(1)

# Itération courante (ADR-014 §4) : lue dans iterations/CURRENT, jamais figée.
try:
    it = (ROOT / "iterations/CURRENT").read_text(encoding="utf-8").strip()
except (OSError, UnicodeDecodeError):
    non_executee("iterations/CURRENT illisible")
if not re.fullmatch(r"\d{3}", it):
    non_executee("iterations/CURRENT ne contient pas un numéro d'itération à trois chiffres")
DIR = ROOT / "iterations" / it / "policies"
AUDIT_PATH = DIR / "audit-npm.json"
META_PATH = DIR / "audit-npm.meta.json"

if not LOCK.is_file():
    non_executee("app/web/package-lock.json absent")
if not META_PATH.is_file():
    non_executee(f"iterations/{it}/policies/audit-npm.meta.json absent (lancer ./dev audit-npm sur l'hôte)")
try:
    meta = json.loads(META_PATH.read_text(encoding="utf-8"))
except (ValueError, UnicodeDecodeError):
    non_executee("audit-npm.meta.json n'est pas du JSON lisible")
if not isinstance(meta, dict):
    non_executee("audit-npm.meta.json n'est pas un objet JSON")
if meta.get("statut") != "reussie":
    non_executee(f"audit-npm.meta.json : statut {str(meta.get('statut'))[:40]!r}, « reussie » attendu")
sha_lock = hashlib.sha256(LOCK.read_bytes()).hexdigest()
if meta.get("package_lock_sha256") != sha_lock:
    non_executee("package_lock_sha256 du rapport différent de app/web/package-lock.json actuel : audit à relancer")
if not AUDIT_PATH.is_file():
    non_executee(f"iterations/{it}/policies/audit-npm.json absent")
if AUDIT_PATH.stat().st_size == 0:
    non_executee(f"iterations/{it}/policies/audit-npm.json vide")
try:
    brut = AUDIT_PATH.read_text(encoding="utf-8")
    data = json.loads(brut)
except (ValueError, UnicodeDecodeError):
    non_executee("audit-npm.json n'est pas du JSON lisible")
if not isinstance(data, dict) or "error" in data or not isinstance(data.get("vulnerabilities"), dict):
    non_executee("audit-npm.json ne contient pas de rapport d'audit npm")

bad, ids, notes = [], set(), []
vulns = data["vulnerabilities"]
for nom, v in vulns.items():
    if nom not in PAQUETS:
        bad.append(f"paquet non listé dans ADR-010 : {nom}")
    if v.get("severity") in ("high", "critical"):
        bad.append(f"{nom} sévérité {v.get('severity')}")
    for via in v.get("via", []):
        if isinstance(via, dict) and via.get("severity") in ("high", "critical"):
            bad.append(f"{nom} : avis de sévérité {via.get('severity')}")
    ids.update(GHSA.findall(json.dumps(v)))
for i in sorted(ids):
    if i not in LISTES:
        bad.append(f"avis non listé dans ADR-010 : {i}")
if "GHSA-8r88-6cj9-9fh5" in ids and BLOQUE_AUTHJS == "oui":
    bad.append("GHSA-8r88-6cj9-9fh5 (auth-js) bloquant pour deploy service (ADR-010, réévaluation requise)")

# Garde esbuild (ADR-010 cas A) : scripts de build à la racine de app/web. Commentaires // et /* */ retirés.
scripts = sorted(p for p in WEB.iterdir() if p.is_file() and p.suffix in (".mjs", ".cjs", ".js", ".ts"))
if not scripts:
    notes.append("aucun script de build à la racine de app/web")
for p in scripts:
    code = re.sub(r"/\*.*?\*/", " ", p.read_text(encoding="utf-8", errors="replace"), flags=re.S)
    code = re.sub(r"//[^\n]*", "", code)
    if RISQUE_ESBUILD.search(code):
        bad.append(f"{p.name} : serve/watch/context( présent, réévaluer GHSA-67mh-4wv8-2f99 (ADR-010 cas C)")
    else:
        notes.append(f"{p.name} : aucun serve/watch/context(")

if bad:
    print("audit npm non conforme : " + " ; ".join(bad) + (" ; " + " ; ".join(notes) if notes else "")); sys.exit(1)
trouves = ", ".join(f"{i} ({LISTES[i]})" for i in sorted(ids)) or "aucun avis"
msg = (f"npm audit (iterations/{it}, statut reussie, sha256 du lock concordant) : {len(vulns)} paquet(s) remonté(s), "
       f"avis listés : {trouves} ; aucun haut ni critique")
print(msg + (" ; " + " ; ".join(notes) if notes else ""))
PY
