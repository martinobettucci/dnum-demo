#!/usr/bin/env bash
# POLICY: STACK-ports
# REF: SPEC-001.3 | ADR-007 | CA-002-1 | CA-002-3
# QUAND: always
# Publication unique (ADR-007, option b) : dans stack/*.yml, seul le service app publie un port, et
# exactement ${APP_LAN_IP:-10.77.0.25}:${APP_PORT}:80 (une seule adresse LAN par pile).
# Aucune publication sur 127.0.0.1, sur 0.0.0.0 ni sur une autre adresse ; aucune syntaxe longue ;
# la surcouche stack/compose.service.yml ne redéfinit pas ports (ADR-007 §2).
python3 -I - <<'PY'
import pathlib, re, sys
sys.path.append("/workspace/policies/lib")
import compose

ATTENDU = "${APP_LAN_IP:-10.77.0.25}:${APP_PORT}:80"
bad, vus = [], {}
fs = compose.fichiers()
if not fs:
    print("aucun fichier stack/*.yml"); sys.exit(1)
for f in fs:
    for nom, svc in compose.load(f).items():
        if "ports" not in svc:
            continue
        if nom != "app":
            bad.append(f"{f.name} : {nom} publie des ports")
            continue
        if f.name != "compose.yml":
            bad.append(f"{f.name} : redéfinit ports de app (ADR-007 §2)")
            continue
        brut = " ".join(svc["ports"])
        if re.search(r"\b(published|target|host_ip|mode)\s*:", brut):
            bad.append("app : publication en syntaxe longue non admise")
            continue
        publies = [compose.unquote(p) for p in compose.items(svc, "ports")]
        vus[f.name] = publies
        if publies != [ATTENDU]:
            bad.append(f"app publie {publies} (attendu exactement « {ATTENDU} »)")
if "compose.yml" not in vus:
    bad.append("compose.yml : app ne publie pas le port LAN")
if bad:
    print("ports non conformes : " + " ; ".join(bad)); sys.exit(1)
print(f"seul app publie un port : {ATTENDU} (ADR-007), aucune publication sur 127.0.0.1 ou 0.0.0.0, surcouche sans ports")
PY
