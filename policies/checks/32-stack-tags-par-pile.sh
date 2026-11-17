#!/usr/bin/env bash
# POLICY: STACK-tags-par-pile
# REF: SPEC-004.16 | ADR-008 | CA-002-2 | CA-002-36
# QUAND: always
# Statique (analyse de stack/compose.yml et stack/compose.service.yml) :
#  - chaque service construit (build:) de compose.yml porte image devenv/<service>:dev ;
#  - chaque image de la surcouche service porte devenv/<service>:service, sans build: ;
#  - aucune paire nom:tag construite n'est utilisée par les deux piles.
python3 -I - <<'PY'
import pathlib, sys
sys.path.append("/workspace/policies/lib")
import compose

base_f = pathlib.Path("/workspace/stack/compose.yml")
sur_f = pathlib.Path("/workspace/stack/compose.service.yml")
for f in (base_f, sur_f):
    if not f.is_file():
        print(f"{f.name} absent"); sys.exit(1)
bad, base_imgs, sur_imgs = [], set(), set()
for nom, svc in compose.load(base_f).items():
    if "build" not in svc:
        continue
    img = compose.scalar(svc, "image")
    attendu = f"devenv/{nom}:dev"
    if img != attendu:
        bad.append(f"compose.yml : {nom} image={img} (attendu {attendu})")
    if img:
        base_imgs.add(img)
for nom, svc in compose.load(sur_f).items():
    img = compose.scalar(svc, "image")
    if "build" in svc:
        bad.append(f"compose.service.yml : {nom} redéfinit build:")
    if img is None:
        continue
    attendu = f"devenv/{nom}:service"
    if img != attendu:
        bad.append(f"compose.service.yml : {nom} image={img} (attendu {attendu})")
    sur_imgs.add(img)
if not sur_imgs:
    bad.append("compose.service.yml : aucune image au tag service")
communes = base_imgs & sur_imgs
if communes:
    bad.append("paire nom:tag commune aux deux piles : " + ", ".join(sorted(communes)))
if bad:
    print("tags d'images non conformes à la pile : " + " ; ".join(bad)); sys.exit(1)
print("images construites : " + ", ".join(sorted(base_imgs)) + " (dev) ; surcouche : " + ", ".join(sorted(sur_imgs)) + " (service) ; aucune collision")
PY
