#!/usr/bin/env bash
# POLICY: ENV-images-epinglees
# REF: ENV | SPEC-001.2 | CA-002-2
# QUAND: always
# Toute image a un tag exact (x.y.z… ou digest ; ni :latest, ni image sans tag) :
#  - chaque FROM de tout Dockerfile du dépôt (les références à une étape antérieure « AS x » sont admises) ;
#  - chaque clé image: de stack/*.yml, sauf pour un service doté de build: (image locale nommée).
python3 -I - <<'PY'
import pathlib, re, sys
sys.path.append("/workspace/policies/lib")
import compose

ws = pathlib.Path("/workspace")
EXCL = {".git", ".devenv", "iterations", "node_modules"}
bad, n = [], 0

for df in sorted(ws.rglob("Dockerfile*")):
    if EXCL & set(df.relative_to(ws).parts) or not df.is_file():
        continue
    etapes = set()
    for ln in df.read_text(errors="replace").splitlines():
        m = re.match(r"^\s*FROM\s+(?:--\S+\s+)*(\S+)(?:\s+AS\s+(\S+))?", ln, re.I)
        if not m:
            continue
        ref, alias = m.group(1), m.group(2)
        n += 1
        if not (ref.lower() in etapes or ref == "scratch" or compose.image_epinglee(ref)):
            bad.append(f"{df.relative_to(ws)}: FROM {ref}")
        if alias:
            etapes.add(alias.lower())

for f in compose.fichiers():
    for nom, svc in compose.load(f).items():
        img = compose.scalar(svc, "image")
        if img is None:
            continue
        n += 1
        if "build" in svc:
            continue
        if not compose.image_epinglee(img):
            bad.append(f"{f.relative_to(ws)}: service {nom} image: {img}")

if bad:
    print(f"{len(bad)} image(s) non épinglée(s) : " + " ; ".join(bad)); sys.exit(1)
print(f"{n} références d'image (FROM + image:) vérifiées, toutes épinglées par tag exact")
PY
