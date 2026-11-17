#!/usr/bin/env bash
# POLICY: FRONT-audit-npm
# REF: SPEC-001.15 (b)(c) | ADR-010 | CA-002-2
# QUAND: always
# Audit des dépendances npm de app/web via tools/bin/npm audit --json (aucun docker run direct ici).
#  - échec si un identifiant GHSA n'est pas listé dans ADR-010 (attendus : GHSA-67mh-4wv8-2f99 esbuild,
#    GHSA-8r88-6cj9-9fh5 auth-js) ; échec si un paquet hors esbuild / auth-js / supabase-js apparaît ;
#    échec si un avis est de sévérité haute ou critique ;
#  - registre injoignable, sortie illisible, npm/docker absent : statut « non exécutée » = échec (jamais « réussie ») ;
#  - GHSA-8r88-6cj9-9fh5 (auth-js) reste BLOQUANT pour ./dev deploy service tant que structure n'a pas tranché
#    (mandat du chef de projet, itération 002 tour 2) : voir BLOQUE_AUTHJS ci-dessous.
#  - contrôles complémentaires, non bloquants : serve / watch / context( dans app/web/build.mjs (ADR-010 cas C).
BLOQUE_AUTHJS="oui"   # passer à "non" seulement sur décision de structure (ADR-010 voie 1, policy 28)
ROOT=/workspace
if [ ! -f "$ROOT/app/web/package-lock.json" ]; then
  echo "audit npm non exécutée : app/web/package-lock.json absent"; exit 1
fi
AUDIT=$(cd "$ROOT/app/web" && timeout 100 "$ROOT/tools/bin/npm" audit --json 2>/dev/null) || true
export AUDIT BLOQUE_AUTHJS
python3 -I - <<'PY'
import json, os, pathlib, re, sys
GHSA = re.compile(r"GHSA-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}")
LISTES = {
    "GHSA-67mh-4wv8-2f99": "esbuild, cas A (ADR-010)",
    "GHSA-8r88-6cj9-9fh5": "auth-js, cas A voie 1 (ADR-010)",
}
PAQUETS = {"esbuild", "@supabase/auth-js", "@supabase/supabase-js"}
def non_executee(msg):
    print("audit npm non exécutée (échec, pas « réussie ») : " + msg); sys.exit(1)
try:
    data = json.loads(os.environ.get("AUDIT", "").strip() or "null")
except ValueError:
    non_executee("tools/bin/npm n'a rendu aucune sortie JSON (registre injoignable ou docker absent du conteneur)")
if not isinstance(data, dict) or "error" in data or not isinstance(data.get("vulnerabilities"), dict):
    non_executee("npm n'a pas rendu de rapport d'audit")
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
if "GHSA-8r88-6cj9-9fh5" in ids and os.environ.get("BLOQUE_AUTHJS") == "oui":
    bad.append("GHSA-8r88-6cj9-9fh5 (auth-js) bloquant pour deploy service tant que structure n'a pas tranché")
mjs = pathlib.Path("/workspace/app/web/build.mjs")
if mjs.is_file():
    code = re.sub(r"//[^\n]*", "", mjs.read_text(errors="replace"))
    if re.search(r"\b(serve|watch)\b|\bcontext\s*\(", code):
        notes.append("ATTENTION : serve/watch/context( dans build.mjs, réévaluer GHSA-67mh-4wv8-2f99 (ADR-010 cas C)")
else:
    notes.append("build.mjs absent")
if bad:
    print("audit npm non conforme : " + " ; ".join(bad) + (" ; " + " ; ".join(notes) if notes else "")); sys.exit(1)
trouves = ", ".join(f"{i} ({LISTES[i]})" for i in sorted(ids)) or "aucun avis"
msg = f"npm audit : {len(vulns)} paquet(s) remonté(s), avis listés : {trouves} ; aucun haut ni critique ; C2 (metafile) non vérifiée"
print(msg + (" ; " + " ; ".join(notes) if notes else ""))
PY
