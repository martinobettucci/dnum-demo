#!/usr/bin/env bash
# POLICY: ENV-secrets-valeurs-absentes
# REF: SPEC-003.3 | SPEC-003.6 | SPEC-003.7 | SPEC-006 §1 | CA-002-2
# QUAND: always
# Les valeurs de .devenv/secrets/*.env (≥ 8 caractères) n'apparaissent dans aucun fichier du dépôt
# hors .git, .devenv, node_modules — iterations/ COMPRISES (rapports de tests, mise-en-service.md,
# journaux : jamais de secret). ADMIN_PASSWORD n'apparaît pas dans .devenv/deploy.log.
# Non applicable (77) tant qu'aucun fichier de secrets n'existe. N'affiche jamais une valeur.
python3 -I - <<'PY'
import os, pathlib, sys
ws = pathlib.Path("/workspace")
envs = sorted((ws / ".devenv/secrets").glob("*.env")) if (ws / ".devenv/secrets").is_dir() else []
if not envs:
    print("aucun fichier .devenv/secrets/*.env : rien à comparer"); sys.exit(77)
vals = {}  # valeur -> "fichier:CLE"
for e in envs:
    for ln in e.read_text(errors="replace").splitlines():
        if "=" not in ln or ln.lstrip().startswith("#"):
            continue
        k, v = ln.split("=", 1)
        v = v.strip().strip("\"'")
        if len(v) >= 8 and "@" not in v:  # ADMIN_EMAIL n'est pas un secret
            vals.setdefault(v.encode(), f"{e.name}:{k.strip()}")
EXCL = {".git", ".devenv", "node_modules"}
hits, n = [], 0
def fichiers():
    for d, dirs, files in os.walk(ws):
        dirs[:] = [x for x in dirs if x not in EXCL]
        for f in files:
            yield pathlib.Path(d) / f
for p in fichiers():
    rel = p.relative_to(ws)
    if not p.is_file() or p.suffix == ".png":
        continue
    try:
        if p.stat().st_size > 5_000_000:
            continue
        data = p.read_bytes()
    except OSError:
        continue
    n += 1
    for v, src in vals.items():
        if v in data:
            hits.append(f"{rel} contient {src}")
log = ws / ".devenv/deploy.log"
if log.is_file():
    data = log.read_bytes()
    for v, src in vals.items():
        if src.endswith(":ADMIN_PASSWORD") and v in data:
            hits.append(f".devenv/deploy.log contient {src}")
if hits:
    print(f"{len(hits)} fuite(s) de secret : " + " ; ".join(sorted(set(hits)))); sys.exit(1)
print(f"{len(vals)} valeur(s) secrète(s) de {len(envs)} fichier(s) absentes de {n} fichiers (iterations/ comprises) et de deploy.log")
PY
