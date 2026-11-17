#!/usr/bin/env bash
# POLICY: DEV-sortie-url
# REF: SPEC-004.17 | SPEC-004.15 | ADR-007 | CA-002-1
# QUAND: always
# Statique sur le fichier ./dev (SPEC-004.17) :
#  (d) le fichier ne contient ni 127.0.0.1, ni localhost, ni 0.0.0.0 (donc aucune sortie n'en contient) ;
#  (a) APP_LAN_IP est exporté sur la même ligne que APP_PORT (avant tout appel à docker compose) ;
#  (c) la ligne finale de sortie utilise http://${APP_LAN_IP}:${APP_PORT}/.
python3 -I - <<'PY'
import pathlib, re, sys
f = pathlib.Path("/workspace/dev")
if not f.is_file():
    print("dev absent"); sys.exit(1)
texte = f.read_text(errors="replace")
bad = []
for i, ln in enumerate(texte.splitlines(), 1):
    if re.search(r"127\.0\.0\.1|localhost|0\.0\.0\.0", ln):
        bad.append(f"dev ligne {i} contient une adresse interdite")
exp = [i for i, ln in enumerate(texte.splitlines(), 1)
       if re.search(r"\bexport\b", ln) and re.search(r"\bAPP_PORT=", ln) and re.search(r"\bAPP_LAN_IP=", ln)]
if not exp:
    bad.append("APP_LAN_IP non exporté sur la ligne de APP_PORT")
if "http://${APP_LAN_IP}:${APP_PORT}/" not in texte:
    bad.append("sortie de deploy : URL http://${APP_LAN_IP}:${APP_PORT}/ absente")
if bad:
    print("sortie de ./dev non conforme : " + " ; ".join(bad)); sys.exit(1)
print(f"./dev sans 127.0.0.1, localhost ni 0.0.0.0 ; APP_LAN_IP exporté avec APP_PORT (ligne {exp[0]}) ; sortie http://${{APP_LAN_IP}}:${{APP_PORT}}/")
PY
