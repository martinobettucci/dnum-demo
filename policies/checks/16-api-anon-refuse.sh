#!/usr/bin/env bash
# POLICY: API-anon-refuse
# REF: SPEC-002.1 | SPEC-002.2 | SPEC-001.12 | CA-002-11
# QUAND: deployed
# Avec la seule clé anon (apikey + Bearer anon), via $APP_URL/rest/v1 :
#  - GET profiles, tasks, time_entries, help_proposals, task_summary, team_load → 401/403 ou [] ;
#  - POST / PATCH / DELETE sur les 4 tables → 401/403 (aucun privilège anon ; un 2xx ou une erreur
#    de contrainte 4xx prouverait que le privilège existe) ;
#  - RPC my_status, admin_list_accounts, admin_set_active, reassign_task, offer_help, request_help,
#    respond_proposal → 401/403 (EXECUTE non accordé à anon) ;
#  - RPC de private (is_admin, is_active_member) → 404 (schéma non exposé).
# Les écritures visent un uuid inexistant et Prefer: return=minimal ; refusées, elles n'ont aucun effet.
python3 -I - <<'PY'
import os, sys
sys.path.append("/workspace/policies/lib")
import requests, devsecrets as sec
k = sec.load().get("ANON_KEY")
if not k:
    print("ANON_KEY absente de .devenv/secrets/dev.env : vérification impossible"); sys.exit(1)
R = os.environ["APP_URL"] + "/rest/v1"
H = {"apikey": k, "Authorization": f"Bearer {k}", "Content-Type": "application/json",
     "Prefer": "return=minimal"}
Z = "00000000-0000-0000-0000-000000000000"
bad, n = [], 0
def req(m, path, **kw):
    global n
    n += 1
    try:
        return requests.request(m, R + path, headers=H, timeout=5, **kw)
    except requests.RequestException as e:
        bad.append(f"{m} {path} : erreur {type(e).__name__}"); return None
def corps(r):
    try:
        return r.json()
    except ValueError:
        return "non-JSON"
for t in ("profiles", "tasks", "time_entries", "help_proposals", "task_summary", "team_load"):
    r = req("GET", f"/{t}?select=*&limit=1")
    if r is not None and not (r.status_code in (401, 403) or (r.status_code == 200 and corps(r) == [])):
        j = corps(r)
        bad.append(f"GET {t}→{r.status_code}" + (f" ({len(j)} ligne(s))" if isinstance(j, list) else ""))
for t in ("profiles", "tasks", "time_entries", "help_proposals"):
    for m, path, body in (("POST", f"/{t}", {}), ("PATCH", f"/{t}?id=eq.{Z}", {"id": Z}),
                          ("DELETE", f"/{t}?id=eq.{Z}", None)):
        r = req(m, path, json=body) if body is not None else req(m, path)
        if r is not None and r.status_code not in (401, 403):
            bad.append(f"{m} {t}→{r.status_code}")
RPC = {"my_status": {}, "admin_list_accounts": {}, "admin_set_active": {"p_user": Z, "p_active": True},
       "reassign_task": {"p_task": Z, "p_to": Z}, "offer_help": {"p_task": Z},
       "request_help": {"p_task": Z, "p_to": Z}, "respond_proposal": {"p_id": Z, "p_accept": True}}
for f, body in RPC.items():
    r = req("POST", f"/rpc/{f}", json=body)
    if r is not None and r.status_code not in (401, 403):
        bad.append(f"rpc {f}→{r.status_code}")
for f in ("is_admin", "is_active_member"):
    r = req("POST", f"/rpc/{f}", json={})
    if r is not None and r.status_code != 404:
        bad.append(f"rpc {f} (private)→{r.status_code}, attendu 404")
if bad:
    print(f"{len(bad)}/{n} accès anon non refusés : " + " ; ".join(bad)); sys.exit(1)
print(f"{n} requêtes avec la seule clé anon : lectures vides ou refusées, écritures et RPC refusées (401/403), private non exposé")
PY
