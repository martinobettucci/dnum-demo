#!/usr/bin/env python3
"""Seed du compte administrateur (ADR-003, ADR-012, SPEC-003.4/.5/.6/.10/.11/.12).

Exécuté par ./dev dans le service one-shot `seed` (image python:3.13.1-slim, réseau interne de la
pile), via l'API d'administration GoTrue INTERNE ($GOTRUE_URL, défaut http://auth:9999).

Comportement (ADR-012, création seule) :
  - compte $ADMIN_EMAIL absent      → création (e-mail confirmé, mot de passe = $ADMIN_PASSWORD) ; seule écriture du script ;
  - compte existant, e-mail confirmé → aucune écriture (le mot de passe de la base fait foi) ;
  - compte existant, e-mail non confirmé → rc≠0, message sans secret, aucune modification (correction manuelle).

La promotion du profil (role='admin', is_active=true) est faite ensuite par `db.sh promote-admin`.
N'affiche jamais de secret, ni l'e-mail complet (masqué : « a***@d*** »), ni le détail d'une exception
ou d'une réponse HTTP. Ne lit ni n'écrit le fichier de secrets. Bibliothèque standard uniquement.
"""
import json, os, sys, time, urllib.error, urllib.request

URL = os.environ.get("GOTRUE_URL", "http://auth:9999").rstrip("/")
KEY = os.environ["SERVICE_ROLE_KEY"]
EMAIL = os.environ["ADMIN_EMAIL"].strip().lower()
PASSWORD = os.environ["ADMIN_PASSWORD"]
HDR = {"Authorization": f"Bearer {KEY}", "apikey": KEY, "Content-Type": "application/json"}


def masque(email):
    """Identifiant pour les logs : « jean@exemple.org » → « j***@e*** ». Jamais l'adresse complète."""
    local, _, domaine = email.partition("@")
    if not local or not domaine:
        return "***"
    return f"{local[:1]}***@{domaine[:1]}***"


def appel(methode, chemin, corps=None):
    """Appel à l'API GoTrue. Seuls GET (lecture) et POST (création, branche « absent ») sont employés."""
    req = urllib.request.Request(URL + chemin, method=methode, headers=HDR,
                                 data=json.dumps(corps).encode() if corps is not None else None)
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            return r.status, json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        return e.code, {}


def attendre():
    for _ in range(60):
        try:
            with urllib.request.urlopen(URL + "/health", timeout=3) as r:
                if r.status == 200:
                    return
        except Exception:
            pass
        time.sleep(1)
    sys.exit("seed : GoTrue injoignable")


def chercher():
    page = 1
    while True:
        code, data = appel("GET", f"/admin/users?page={page}&per_page=200")
        if code != 200:
            sys.exit(f"seed : liste des comptes refusée (HTTP {code})")
        users = data.get("users", [])
        for u in users:
            if (u.get("email") or "").lower() == EMAIL:
                return u
        if len(users) < 200:
            return None
        page += 1


def main():
    attendre()
    u = chercher()
    if u is None:
        # Seule branche qui écrit : compte absent → création.
        code, _ = appel("POST", "/admin/users", {
            "email": EMAIL, "password": PASSWORD, "email_confirm": True,
            "user_metadata": {"display_name": "Administrateur"}})
        if code not in (200, 201):
            sys.exit(f"seed : création du compte administrateur refusée (HTTP {code})")
        print(f"seed : compte administrateur créé (admin : {masque(EMAIL)})")
        return
    # Compte existant : aucune écriture (ADR-012, SPEC-003.10). Un compte non confirmé est refusé (SPEC-003.11).
    if not (u.get("email_confirmed_at") or u.get("confirmed_at")):
        sys.exit("seed : compte administrateur existant sans e-mail confirmé ; correction manuelle requise "
                 "(aucune modification effectuée)")
    print(f"seed : compte administrateur existant, inchangé (admin : {masque(EMAIL)})")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as e:
        # Aucun détail de l'exception : son message peut contenir un corps de réponse ou une valeur.
        sys.exit(f"seed : erreur inattendue ({type(e).__name__}) ; détail non affiché")
