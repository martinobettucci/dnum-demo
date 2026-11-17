#!/usr/bin/env bash
# POLICY: STACK-points-accroche
# REF: SPEC-004.11 | SPEC-004.12 | SPEC-004.13 | SPEC-004.14 | ADR-006 §3 | CA-002-1 | CA-002-2
# QUAND: always
# Statique sur stack/compose.yml (équivalent de docker compose config, sans docker dans le runner) :
#  - migrate : profil deploy, image supabase/postgres:15.8.1.060, entrypoint bash /ops/db.sh, montages
#    ../tools/deploy:/ops:ro et ../app/db/migrations:/migrations:ro, env_file longue (path ${DEVENV_SECRETS},
#    required: false), aucun port, aucune politique restart ;
#  - seed : profil deploy, image python:3.13.1-slim, command python3 /ops/seed.py, montage ../tools/deploy:/ops:ro,
#    env_file longue (path ${DEVENV_SECRETS}, required: false), aucun port, aucune politique restart ;
#  - healthchecks sur db (pg_isready), auth (/health), app (/) ; rest sans healthcheck (image sans shell) ;
#  - volume nommé db-data déclaré au niveau racine.
python3 -I - <<'PY'
import pathlib, re, sys
sys.path.append("/workspace/policies/lib")
import compose

f = pathlib.Path("/workspace/stack/compose.yml")
if not f.is_file():
    print("stack/compose.yml absent"); sys.exit(1)
svcs = compose.load(f)
bad = []

def env_file_longue(svc):
    brut = [ln.strip() for ln in svc.get("env_file", [])]
    return any(re.fullmatch(r"-?\s*path:\s*\$\{DEVENV_SECRETS\}", ln) for ln in brut) \
        and any(re.fullmatch(r"required:\s*false", ln) for ln in brut)

def one_shot(nom, image, attendu_entree):
    svc = svcs.get(nom)
    if svc is None:
        bad.append(f"service {nom} absent"); return
    if compose.scalar(svc, "image") != image:
        bad.append(f"{nom} image={compose.scalar(svc, 'image')} (attendu {image})")
    if compose.items(svc, "profiles") != ["deploy"]:
        bad.append(f"{nom} : profil deploy absent")
    if "ports" in svc:
        bad.append(f"{nom} publie des ports")
    if "restart" in svc:
        bad.append(f"{nom} : politique restart interdite")
    if not env_file_longue(svc):
        bad.append(f"{nom} : env_file pas en forme longue path ${{DEVENV_SECRETS}} required: false")
    if attendu_entree == "entrypoint":
        if compose.items(svc, "entrypoint") != ["bash", "/ops/db.sh"]:
            bad.append(f"{nom} : entrypoint attendu bash /ops/db.sh")
    else:
        if compose.items(svc, "command") != ["python3", "/ops/seed.py"]:
            bad.append(f"{nom} : command attendu python3 /ops/seed.py")
    montages = compose.items(svc, "volumes")
    if "../tools/deploy:/ops:ro" not in montages:
        bad.append(f"{nom} : montage ../tools/deploy:/ops:ro absent")
    return svc

one_shot("migrate", "supabase/postgres:15.8.1.060", "entrypoint")
mig = svcs.get("migrate")
if mig is not None and "../app/db/migrations:/migrations:ro" not in compose.items(mig, "volumes"):
    bad.append("migrate : montage ../app/db/migrations:/migrations:ro absent")
one_shot("seed", "python:3.13.1-slim", "command")

for nom in ("db", "auth", "app"):
    svc = svcs.get(nom)
    if svc is None or "healthcheck" not in svc:
        bad.append(f"healthcheck absent sur {nom}")
db = svcs.get("db")
if db is not None and "pg_isready" not in " ".join(db.get("healthcheck", [])):
    bad.append("db : healthcheck pg_isready attendu")
if db is not None and "db-data:/var/lib/postgresql/data" not in compose.items(db, "volumes"):
    bad.append("db : volume db-data non monté")
racine = f.read_text()
if not re.search(r"^volumes:\s*\n(?:[ \t]+\S.*\n?)*?[ \t]+db-data:", racine, re.M):
    bad.append("volume nommé db-data non déclaré à la racine")
if bad:
    print("points d'accroche non conformes : " + " ; ".join(bad)); sys.exit(1)
print("migrate et seed conformes (profil deploy, images, montages, env_file longue required: false, sans port ni restart) ; healthchecks db, auth, app ; volume db-data")
PY
