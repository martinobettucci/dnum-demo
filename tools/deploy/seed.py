#!/usr/bin/env python3
"""Seed idempotent du compte administrateur (ADR-003, SPEC-003.4/.5/.6).

Exécuté par ./dev dans le service one-shot `seed` (image python:3.13.1-slim, réseau interne de la
pile). Assure, via l'API d'administration GoTrue INTERNE ($GOTRUE_URL, défaut http://auth:9999),
que le compte $ADMIN_EMAIL existe, e-mail confirmé, mot de passe = $ADMIN_PASSWORD.
La promotion du profil (role='admin', is_active=true) est faite ensuite par `db.sh promote-admin`.
N'affiche jamais de secret. Bibliothèque standard uniquement.
"""
import json, os, sys, time, urllib.error, urllib.request

URL = os.environ.get("GOTRUE_URL", "http://auth:9999").rstrip("/")
KEY = os.environ["SERVICE_ROLE_KEY"]
EMAIL = os.environ["ADMIN_EMAIL"].strip().lower()
PASSWORD = os.environ["ADMIN_PASSWORD"]
HDR = {"Authorization": f"Bearer {KEY}", "apikey": KEY, "Content-Type": "application/json"}


def appel(methode, chemin, corps=None):
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
        code, data = appel("POST", "/admin/users", {
            "email": EMAIL, "password": PASSWORD, "email_confirm": True,
            "user_metadata": {"display_name": "Administrateur"}})
        if code not in (200, 201):
            sys.exit(f"seed : création du compte administrateur refusée (HTTP {code})")
        print(f"seed : compte administrateur créé ({EMAIL})")
    else:
        code, _ = appel("PUT", f"/admin/users/{u['id']}", {"password": PASSWORD, "email_confirm": True})
        if code != 200:
            sys.exit(f"seed : mise à jour du compte administrateur refusée (HTTP {code})")
        print(f"seed : compte administrateur à jour ({EMAIL})")


if __name__ == "__main__":
    main()
