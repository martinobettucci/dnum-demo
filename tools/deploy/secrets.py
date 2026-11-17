#!/usr/bin/env python3
"""Génération idempotente des secrets d'une pile (ADR-003, SPEC-003.1/.2).

Usage : python3 tools/deploy/secrets.py <fichier.env>
- crée le répertoire (0700) et le fichier (0600) s'ils sont absents ;
- ne génère QUE les clés absentes ; une valeur existante n'est jamais réécrite ;
- ANON_KEY / SERVICE_ROLE_KEY : JWT HS256 signés par JWT_SECRET ;
- n'affiche jamais une valeur, seulement le nom des clés générées.
Bibliothèque standard uniquement (python3 de l'hôte).
"""
import base64, hashlib, hmac, json, os, secrets, string, sys, tempfile, time

ALNUM = string.ascii_letters + string.digits
ORDER = ["POSTGRES_PASSWORD", "JWT_SECRET", "ANON_KEY", "SERVICE_ROLE_KEY", "ADMIN_EMAIL", "ADMIN_PASSWORD"]
DIX_ANS = 10 * 365 * 24 * 3600


def rand(n):
    return "".join(secrets.choice(ALNUM) for _ in range(n))


def b64u(b):
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()


def jwt(role, key):
    iat = int(time.time())
    h = b64u(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
    p = b64u(json.dumps({"role": role, "iss": "supabase", "iat": iat, "exp": iat + DIX_ANS},
                        separators=(",", ":")).encode())
    s = b64u(hmac.new(key.encode(), f"{h}.{p}".encode(), hashlib.sha256).digest())
    return f"{h}.{p}.{s}"


def jwt_valide(tok, key, role):
    try:
        h, p, s = tok.split(".")
        attendu = b64u(hmac.new(key.encode(), f"{h}.{p}".encode(), hashlib.sha256).digest())
        claims = json.loads(base64.urlsafe_b64decode(p + "=" * (-len(p) % 4)))
        return hmac.compare_digest(attendu, s) and claims.get("role") == role
    except Exception:
        return False


def lire(path):
    vals = {}
    with open(path) as f:
        for ligne in f:
            ligne = ligne.strip()
            if ligne and not ligne.startswith("#") and "=" in ligne:
                k, v = ligne.split("=", 1)
                vals[k.strip()] = v.strip()
    return vals


def main():
    if len(sys.argv) != 2:
        sys.exit("usage : secrets.py <fichier.env>")
    path = os.path.abspath(sys.argv[1])
    d = os.path.dirname(path)
    os.makedirs(d, mode=0o700, exist_ok=True)
    os.chmod(d, 0o700)
    vals = lire(path) if os.path.exists(path) else {}
    nouveaux = []

    def assure(k, gen):
        if not vals.get(k):
            vals[k] = gen()
            nouveaux.append(k)

    assure("POSTGRES_PASSWORD", lambda: rand(32))
    assure("JWT_SECRET", lambda: rand(64))
    assure("ANON_KEY", lambda: jwt("anon", vals["JWT_SECRET"]))
    assure("SERVICE_ROLE_KEY", lambda: jwt("service_role", vals["JWT_SECRET"]))
    assure("ADMIN_EMAIL", lambda: "admin@dnum.lelabs.tech")
    assure("ADMIN_PASSWORD", lambda: rand(32))

    # Cohérence : on ne réécrit rien, on refuse un fichier incohérent.
    erreurs = []
    if len(vals["JWT_SECRET"]) < 40: erreurs.append("JWT_SECRET < 40 caractères")
    if len(vals["ADMIN_PASSWORD"]) < 20: erreurs.append("ADMIN_PASSWORD < 20 caractères")
    for k, role in (("ANON_KEY", "anon"), ("SERVICE_ROLE_KEY", "service_role")):
        if not jwt_valide(vals[k], vals["JWT_SECRET"], role):
            erreurs.append(f"{k} n'est pas un JWT HS256 role={role} signé par JWT_SECRET")
    if erreurs:
        sys.exit(f"secrets : {path} incohérent ({'; '.join(erreurs)}). "
                 "Corriger le fichier ou le supprimer pour régénération complète.")

    if nouveaux:
        autres = [k for k in vals if k not in ORDER]
        contenu = "# Secrets générés par ./dev (ADR-003) — NE JAMAIS COMMITER.\n" + \
                  "".join(f"{k}={vals[k]}\n" for k in ORDER + autres)
        fd, tmp = tempfile.mkstemp(dir=d, prefix=".secrets-")
        try:
            os.fchmod(fd, 0o600)
            with os.fdopen(fd, "w") as f:
                f.write(contenu)
            os.replace(tmp, path)
        except BaseException:
            if os.path.exists(tmp): os.unlink(tmp)
            raise
        print(f"secrets : {os.path.relpath(path)} — clés générées : {', '.join(nouveaux)}")
    else:
        print(f"secrets : {os.path.relpath(path)} — inchangé")
    os.chmod(path, 0o600)


if __name__ == "__main__":
    main()
