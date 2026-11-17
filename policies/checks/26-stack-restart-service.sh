#!/usr/bin/env bash
# POLICY: STACK-restart-service
# REF: SPEC-004.7 | ADR-009 | CA-002-36
# QUAND: always
# Analyse statique (équivalente à docker compose config avec les deux fichiers, sans docker dans le runner) :
#  - stack/compose.service.yml : restart: unless-stopped sur db, auth, rest et app ;
#  - aucune politique restart sur migrate, seed, runner, client (ni dans la surcouche, ni dans la base) ;
#  - stack/compose.yml (pile dev) : aucune clé restart ;
#  - la surcouche ne définit que ces services (pas de service supplémentaire).
python3 -I - <<'PY'
import pathlib, sys
sys.path.append("/workspace/policies/lib")
import compose

stack = pathlib.Path("/workspace/stack")
base_f, sur_f = stack / "compose.yml", stack / "compose.service.yml"
for f in (base_f, sur_f):
    if not f.is_file():
        print(f"{f.name} absent"); sys.exit(1)
RESTART_OUI = ("db", "auth", "rest", "app")
ADMIS = set(RESTART_OUI) | {"migrate", "seed", "runner", "client"}
bad = []
base = compose.load(base_f)
for nom, svc in base.items():
    if "restart" in svc:
        bad.append(f"compose.yml : politique restart sur {nom} (pile dev sans politique, ADR-009 §4)")
sur = compose.load(sur_f)
for nom in sur:
    if nom not in ADMIS:
        bad.append(f"surcouche : service non admis {nom}")
for nom in RESTART_OUI:
    if nom not in sur:
        bad.append(f"surcouche : {nom} sans restart")
        continue
    val = compose.scalar(sur[nom], "restart")
    if val != "unless-stopped":
        bad.append(f"surcouche : {nom} restart={val} (attendu unless-stopped)")
for nom in ("migrate", "seed", "runner", "client"):
    if nom in sur and "restart" in sur[nom]:
        bad.append(f"surcouche : politique restart sur {nom} (one-shot ou outil, ADR-009 §2-3)")
if bad:
    print("politiques restart non conformes : " + " ; ".join(bad)); sys.exit(1)
print("restart unless-stopped sur db, auth, rest, app (surcouche service) ; aucune politique sur migrate, seed, runner, client ; aucune dans la pile dev")
PY
