#!/usr/bin/env bash
# POLICY: FRONT-audit-npm
# REF: SPEC-001.15 (b)(c) | ADR-010 | CA-002-2
# QUAND: always
# Audit des dépendances npm de app/web, lu depuis iterations/002/policies/audit-npm.json.
# Ce fichier est la sortie de `tools/bin/npm audit --json` lancée dans app/web HORS runner (agent action) :
# le runner n'a ni Docker ni Node. Cette policy ne fait aucun appel réseau et ne lance aucun conteneur.
#  - échec si le fichier est absent, vide, non JSON, sans rapport d'audit, ou antérieur à app/web/package-lock.json ;
#  - échec si un identifiant GHSA n'est pas listé dans ADR-010 (attendus : GHSA-67mh-4wv8-2f99 esbuild,
#    GHSA-8r88-6cj9-9fh5 auth-js) ; échec si un paquet hors esbuild / auth-js / supabase-js apparaît ;
#    échec si un avis est de sévérité haute ou critique ;
#  - GHSA-8r88-6cj9-9fh5 (auth-js) : cas A, voie 1 (ADR-010, SPEC-001.15 (b)(d)(e)). Non bloquant pour
#    ./dev deploy service, sous condition de la policy 28 FRONT-auth-js-non-appel (SPEC-001.15 (e)).
# Ligne 13 : BLOQUE_AUTHJS="non" sur décision de structure (ADR-010 voie 1). Passer à "oui" rétablit le blocage
#    de deploy service et impose la réévaluation de ADR-010 (SPEC-001.15 (d)).
#  - contrôle complémentaire, non bloquant : serve / watch / context( dans app/web/build.mjs (ADR-010 cas C).
BLOQUE_AUTHJS="non"
export BLOQUE_AUTHJS
python3 -I - <<'PY'
import json, os, pathlib, re, sys
ROOT = pathlib.Path("/workspace")
LOCK = ROOT / "app/web/package-lock.json"
AUDIT_PATH = ROOT / "iterations/002/policies/audit-npm.json"
MJS = ROOT / "app/web/build.mjs"
BLOQUE_AUTHJS = os.environ.get("BLOQUE_AUTHJS", "non")
GHSA = re.compile(r"GHSA-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}")
LISTES = {
    "GHSA-67mh-4wv8-2f99": "esbuild, cas A (ADR-010)",
    "GHSA-8r88-6cj9-9fh5": "auth-js, cas A voie 1 (ADR-010)",
}
PAQUETS = {"esbuild", "@supabase/auth-js", "@supabase/supabase-js"}
def non_executee(msg):
    print("audit npm non exécutée (échec, pas « réussie ») : " + msg); sys.exit(1)
if not LOCK.is_file():
    non_executee("app/web/package-lock.json absent")
if not AUDIT_PATH.is_file():
    non_executee("iterations/002/policies/audit-npm.json absent (sortie de tools/bin/npm audit --json à produire hors runner)")
if AUDIT_PATH.stat().st_size == 0:
    non_executee("iterations/002/policies/audit-npm.json vide")
if AUDIT_PATH.stat().st_mtime < LOCK.stat().st_mtime:
    non_executee("iterations/002/policies/audit-npm.json antérieur à app/web/package-lock.json : audit à relancer")
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
if MJS.is_file():
    code = re.sub(r"//[^\n]*", "", MJS.read_text(errors="replace"))
    if re.search(r"\b(serve|watch)\b|\bcontext\s*\(", code):
        notes.append("ATTENTION : serve/watch/context( dans build.mjs, réévaluer GHSA-67mh-4wv8-2f99 (ADR-010 cas C)")
else:
    notes.append("build.mjs absent")
if bad:
    print("audit npm non conforme : " + " ; ".join(bad) + (" ; " + " ; ".join(notes) if notes else "")); sys.exit(1)
trouves = ", ".join(f"{i} ({LISTES[i]})" for i in sorted(ids)) or "aucun avis"
msg = f"npm audit (audit-npm.json) : {len(vulns)} paquet(s) remonté(s), avis listés : {trouves} ; aucun haut ni critique ; C2 (metafile) non vérifiée"
print(msg + (" ; " + " ; ".join(notes) if notes else ""))
PY
