#!/usr/bin/env bash
# POLICY: ENV-images-epinglees
# REF: ENV | SPEC-001.2 | SPEC-004.16 | ADR-008 | CA-002-2
# QUAND: always
# Toute image a un tag exact (x.y.z… ou digest ; ni :latest, ni image sans tag) :
#  - chaque FROM de tout Dockerfile du dépôt (les références à une étape antérieure « AS x » sont admises) ;
#  - chaque clé image: de stack/*.yml, SAUF les images locales (nom devenv/…) qui portent le tag de leur pile
#    (ADR-008) : `devenv/<service>:dev` pour stack/compose.yml (service construit par build:), et
#    `devenv/<service>:service` pour stack/compose.service.yml (surcouche sans build:).
#    Une image construite (build:) qui ne porte pas le tag de sa pile est en violation.
python3 -I - <<'PY'
import pathlib, re, sys
sys.path.append("/workspace/policies/lib")
import compose

ws = pathlib.Path("/workspace")
EXCL = {".git", ".devenv", "iterations", "node_modules"}
PILE = {"compose.yml": "dev", "compose.service.yml": "service"}
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
    pile = PILE.get(f.name)
    for nom, svc in compose.load(f).items():
        img = compose.scalar(svc, "image")
        construit = "build" in svc
        if img is None:
            if construit:
                bad.append(f"{f.relative_to(ws)}: service {nom} construit sans image: (tag de pile absent)")
            continue
        n += 1
        if img.startswith("devenv/"):
            # Image locale : tag = pile du fichier (ADR-008), nom = service (SPEC-004.16).
            attendu = f"devenv/{nom}:{pile}" if pile else None
            if pile is None or img != attendu:
                bad.append(f"{f.relative_to(ws)}: service {nom} image: {img} (attendu {attendu or 'pile inconnue'})")
            continue
        if construit:
            bad.append(f"{f.relative_to(ws)}: service {nom} construit, image: {img} hors devenv/<service>:<pile>")
            continue
        if not compose.image_epinglee(img):
            bad.append(f"{f.relative_to(ws)}: service {nom} image: {img}")

if bad:
    print(f"{len(bad)} image(s) non conforme(s) : " + " ; ".join(bad)); sys.exit(1)
print(f"{n} références d'image (FROM + image:) vérifiées : tags exacts, images locales au tag de leur pile (ADR-008)")
PY
