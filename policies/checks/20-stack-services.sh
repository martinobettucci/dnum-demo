#!/usr/bin/env bash
# POLICY: STACK-services
# REF: SPEC-001.1 | SPEC-001.2 | ADR-001 | CA-002-1
# QUAND: always
# stack/compose.yml définit db, auth, rest, app ; seuls services admis en plus : migrate, seed,
# runner, client. Aucun Studio, Kong, Realtime, Storage, Meta, SMTP (ni par nom, ni par image).
# Images contractuelles : db=supabase/postgres:15.8.1.060, auth=supabase/gotrue:v2.170.0,
# rest=postgrest/postgrest:v12.2.8.
python3 -I - <<'PY'
import pathlib, re, sys
sys.path.append("/workspace/policies/lib")
import compose
f = pathlib.Path("/workspace/stack/compose.yml")
if not f.is_file():
    print("stack/compose.yml absent"); sys.exit(1)
svcs = compose.load(f)
REQUIS = {"db", "auth", "rest", "app"}
ADMIS = REQUIS | {"migrate", "seed", "runner", "client"}
IMAGES = {"db": "supabase/postgres:15.8.1.060", "auth": "supabase/gotrue:v2.170.0",
          "rest": "postgrest/postgrest:v12.2.8"}
INTERDIT = re.compile(r"studio|kong|realtime|storage|postgres-meta|pg-meta|\bmeta\b|inbucket|mailpit|smtp|imgproxy|supavisor|analytics|logflare|vector|edge-runtime", re.I)
bad = []
manquants = REQUIS - svcs.keys()
if manquants:
    bad.append("services manquants : " + ", ".join(sorted(manquants)))
for nom, svc in svcs.items():
    img = compose.scalar(svc, "image") or ""
    if nom not in ADMIS:
        bad.append(f"service non prévu : {nom}")
    if INTERDIT.search(nom) or INTERDIT.search(img):
        bad.append(f"composant exclu : {nom} ({img or 'sans image'})")
for nom, attendu in IMAGES.items():
    if nom in svcs and compose.scalar(svcs[nom], "image") != attendu:
        bad.append(f"{nom} image={compose.scalar(svcs[nom], 'image')} (attendu {attendu})")
# Surcouches (ex. compose.service.yml) : pas de composant exclu ni de service non prévu.
for g in compose.fichiers():
    if g.name == "compose.yml":
        continue
    for nom, svc in compose.load(g).items():
        img = compose.scalar(svc, "image") or ""
        if nom not in ADMIS or INTERDIT.search(nom) or INTERDIT.search(img):
            bad.append(f"{g.name} : service non admis {nom} ({img})")
if bad:
    print("compose non conforme : " + " ; ".join(bad)); sys.exit(1)
print("services : " + ", ".join(sorted(svcs)) + " — conformes (images db/auth/rest contractuelles, aucun composant exclu)")
PY
