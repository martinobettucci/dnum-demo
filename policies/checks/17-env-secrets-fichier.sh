#!/usr/bin/env bash
# POLICY: ENV-secrets-fichier
# REF: SPEC-003.1 | SPEC-003.2 | ADR-003 | CA-002-4
# QUAND: deployed
# Pile déployée ⇒ .devenv/secrets/dev.env existe (répertoire 0700, fichier 0600) avec
# POSTGRES_PASSWORD, JWT_SECRET (≥ 40), ANON_KEY, SERVICE_ROLE_KEY, ADMIN_EMAIL,
# ADMIN_PASSWORD (≥ 20, alphanumérique) ; ANON_KEY / SERVICE_ROLE_KEY = JWT HS256 signés par
# JWT_SECRET, de rôle anon / service_role. Aucune valeur affichée.
python3 -I - <<'PY'
import base64, hashlib, hmac, json, pathlib, stat, sys
d = pathlib.Path("/workspace/.devenv/secrets"); f = d / "dev.env"
if not f.is_file():
    print(".devenv/secrets/dev.env absent alors que la pile est déployée"); sys.exit(1)
bad = []
md, mf = stat.S_IMODE(d.stat().st_mode), stat.S_IMODE(f.stat().st_mode)
if md != 0o700: bad.append(f"répertoire {oct(md)} (attendu 0o700)")
if mf != 0o600: bad.append(f"fichier {oct(mf)} (attendu 0o600)")
s = {}
for ln in f.read_text(errors="replace").splitlines():
    if "=" in ln and not ln.lstrip().startswith("#"):
        k, v = ln.split("=", 1); s[k.strip()] = v.strip().strip("\"'")
for k in ("POSTGRES_PASSWORD", "JWT_SECRET", "ANON_KEY", "SERVICE_ROLE_KEY", "ADMIN_EMAIL", "ADMIN_PASSWORD"):
    if not s.get(k): bad.append(f"{k} manquant")
if s.get("JWT_SECRET") and len(s["JWT_SECRET"]) < 40: bad.append("JWT_SECRET < 40 car.")
ap = s.get("ADMIN_PASSWORD", "")
if ap and (len(ap) < 20 or not ap.isalnum() or not ap.isascii()): bad.append("ADMIN_PASSWORD < 20 car. ou non alphanumérique")
def b64(x): return base64.urlsafe_b64decode(x + "=" * (-len(x) % 4))
def jwt_ok(tok, role):
    try:
        h, p, sig = tok.split(".")
        if json.loads(b64(h)).get("alg") != "HS256": return "alg ≠ HS256"
        attendu = hmac.new(s["JWT_SECRET"].encode(), f"{h}.{p}".encode(), hashlib.sha256).digest()
        if not hmac.compare_digest(attendu, b64(sig)): return "signature invalide"
        r = json.loads(b64(p)).get("role")
        return None if r == role else f"role={r}"
    except Exception as e:
        return f"JWT illisible ({type(e).__name__})"
if s.get("JWT_SECRET"):
    for k, role in (("ANON_KEY", "anon"), ("SERVICE_ROLE_KEY", "service_role")):
        if s.get(k):
            e = jwt_ok(s[k], role)
            if e: bad.append(f"{k} : {e}")
if bad:
    print("fichier de secrets non conforme : " + " ; ".join(bad)); sys.exit(1)
print(".devenv/secrets/dev.env : droits 0700/0600, 6 clés présentes, longueurs conformes, ANON_KEY/SERVICE_ROLE_KEY signées HS256")
PY
