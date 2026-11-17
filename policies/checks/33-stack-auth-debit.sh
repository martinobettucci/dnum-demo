#!/usr/bin/env bash
# POLICY: STACK-auth-debit
# REF: SPEC-001.14 | ADR-006 §1 | CA-002-6 | CA-002-7 | CA-002-33
# QUAND: always
# Statique (ADR-006 §1, débit de la pile dev) :
#  - service auth de stack/compose.yml : GOTRUE_RATE_LIMIT_HEADER absent (aucun quota par IP, nginx partage l'IP) ;
#  - GOTRUE_RATE_LIMIT_EMAIL_SENT, _TOKEN_REFRESH, _VERIFY et _OTP valent 1000 ou plus ;
#  - aucune directive limit_req ni limit_conn sous app/nginx/ (commentaires ignorés).
python3 -I - <<'PY'
import pathlib, re, sys
sys.path.append("/workspace/policies/lib")
import compose

base_f = pathlib.Path("/workspace/stack/compose.yml")
nginx = pathlib.Path("/workspace/app/nginx")
if not base_f.is_file():
    print("stack/compose.yml absent"); sys.exit(1)
svc = compose.load(base_f).get("auth")
if svc is None:
    print("service auth absent de stack/compose.yml"); sys.exit(1)
env = {}
for ln in svc.get("environment", []):
    ln = ln[2:] if ln.startswith("- ") else ln
    m = re.match(r"^[\"']?([A-Za-z_][A-Za-z0-9_]*)[\"']?\s*(?::|=)\s*(.*)$", ln.strip())
    if m:
        env[m.group(1)] = compose.unquote(m.group(2).strip())
bad = []
if "GOTRUE_RATE_LIMIT_HEADER" in env:
    bad.append("GOTRUE_RATE_LIMIT_HEADER présent (quota par IP interdit, ADR-006 §1)")
SEUIL = ("GOTRUE_RATE_LIMIT_EMAIL_SENT", "GOTRUE_RATE_LIMIT_TOKEN_REFRESH",
         "GOTRUE_RATE_LIMIT_VERIFY", "GOTRUE_RATE_LIMIT_OTP")
for cle in SEUIL:
    v = env.get(cle)
    if v is None:
        bad.append(f"{cle} absent")
    elif not v.isdigit() or int(v) < 1000:
        bad.append(f"{cle}={v} (attendu >= 1000)")
if nginx.is_dir():
    for p in sorted(nginx.rglob("*")):
        if not p.is_file():
            continue
        code = re.sub(r"(^|\s)#[^\n]*", r"\1", p.read_text(errors="replace"))
        if re.search(r"\blimit_(req|conn)\w*", code):
            bad.append(f"{p.relative_to(nginx.parent)} : limit_req/limit_conn (passerelle sans limitation, SPEC-001.14)")
else:
    bad.append("app/nginx absent : absence de limitation non vérifiable")
if bad:
    print("débit d'authentification non conforme : " + " ; ".join(bad)); sys.exit(1)
print("GOTRUE_RATE_LIMIT_HEADER absent ; EMAIL_SENT, TOKEN_REFRESH, VERIFY, OTP >= 1000 ; aucun limit_req ni limit_conn sous app/nginx/")
PY
