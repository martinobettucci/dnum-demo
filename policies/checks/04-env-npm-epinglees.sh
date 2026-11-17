#!/usr/bin/env bash
# POLICY: ENV-npm-epinglees
# REF: ENV | ADR-002 | SPEC-006 §3.2 | CA-002-2
# QUAND: always
# app/web/package.json : versions exactes (ni ^, ~, *, x, latest, plage, URL) ;
# @supabase/supabase-js = 2.47.10 (package.json et package-lock.json) ; package-lock.json présent ;
# app/Dockerfile installe par « npm ci » (jamais « npm install »).
python3 -I - <<'PY'
import json, pathlib, re, sys
web = pathlib.Path("/workspace/app/web")
pj, pl, df = web / "package.json", web / "package-lock.json", pathlib.Path("/workspace/app/Dockerfile")
bad = []
if not pj.is_file():
    print("app/web/package.json absent"); sys.exit(1)
try:
    pkg = json.loads(pj.read_text())
except ValueError as e:
    print(f"app/web/package.json illisible : {e}"); sys.exit(1)
EXACT = re.compile(r"^\d+\.\d+\.\d+(-[0-9A-Za-z.\-]+)?$")
deps = {}
for sect in ("dependencies", "devDependencies", "optionalDependencies", "peerDependencies"):
    for k, v in (pkg.get(sect) or {}).items():
        deps[k] = v
        if not EXACT.match(str(v)):
            bad.append(f"{sect}.{k}={v}")
sb = deps.get("@supabase/supabase-js")
if sb != "2.47.10":
    bad.append(f"@supabase/supabase-js={sb} (attendu 2.47.10)")
if not pl.is_file():
    bad.append("package-lock.json absent")
else:
    try:
        lock = json.loads(pl.read_text())
        v = (lock.get("packages", {}).get("node_modules/@supabase/supabase-js") or {}).get("version")
        if v != "2.47.10":
            bad.append(f"lock @supabase/supabase-js={v} (attendu 2.47.10)")
    except ValueError as e:
        bad.append(f"package-lock.json illisible : {e}")
if df.is_file():
    t = df.read_text()
    if re.search(r"\bnpm\s+(install|i)\b", t):
        bad.append("app/Dockerfile utilise « npm install »")
    if not re.search(r"\bnpm\s+ci\b", t):
        bad.append("app/Dockerfile n'exécute pas « npm ci »")
if bad:
    print("dépendances npm non conformes : " + " ; ".join(bad)); sys.exit(1)
print(f"{len(deps)} dépendance(s) npm à version exacte, supabase-js 2.47.10 (package.json + lock), npm ci")
PY
