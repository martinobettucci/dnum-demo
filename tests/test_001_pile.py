"""SPEC-001 — Pile Supabase auto-hébergée et passerelle unique (CA-002-1, 2, 3, 6, 7, 11)."""
import re, uuid

import pytest
import requests

from conftest import APP_URL, TIMEOUT, compte_admin, email_unique, login, signup

FICHIERS_SERVIS = ["/", "/app.js", "/config.js", "/style.css"]
JWT_RE = re.compile(r"eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+")


def servi(path):
    return requests.get(APP_URL + path, timeout=TIMEOUT)


# --- SPEC-001.4 : page d'accueil -------------------------------------------------------------
@pytest.mark.spec("SPEC-001.4")
def test_accueil_repond_200_en_html():
    r = servi("/")
    assert r.status_code == 200
    assert "text/html" in r.headers.get("Content-Type", "")


# --- SPEC-001.5 : santé des services derrière la passerelle -----------------------------------
@pytest.mark.spec("SPEC-001.5")
def test_sante_auth_200(anon_key):
    r = requests.get(APP_URL + "/auth/v1/health", headers={"apikey": anon_key}, timeout=TIMEOUT)
    assert r.status_code == 200


@pytest.mark.spec("SPEC-001.5")
def test_rest_racine_pas_5xx(anon_key):
    r = requests.get(APP_URL + "/rest/v1/", headers={"apikey": anon_key}, timeout=TIMEOUT)
    assert r.status_code < 500


# --- SPEC-001.6 : relais /auth/v1 et /rest/v1 -------------------------------------------------
@pytest.mark.spec("SPEC-001.6")
def test_relais_auth_token_admin_renvoie_access_token(secrets_env, anon_key):
    r = login(anon_key, secrets_env["ADMIN_EMAIL"], secrets_env["ADMIN_PASSWORD"])
    assert r.status_code == 200
    assert r.json().get("access_token")


@pytest.mark.spec("SPEC-001.6")
def test_relais_rest_team_load_avec_jeton_admin(admin):
    r = admin.get("team_load")
    assert r.status_code == 200, r.text[:300]
    assert isinstance(r.json(), list)


# --- SPEC-001.7 : API d'administration GoTrue bloquée -----------------------------------------
@pytest.mark.spec("SPEC-001.7")
@pytest.mark.parametrize("methode,chemin", [
    ("GET", "/auth/v1/admin/users"),
    ("POST", "/auth/v1/admin/users"),
    ("GET", f"/auth/v1/admin/users/{uuid.uuid4()}"),
    ("GET", "/auth/v1/admin/audit"),
])
@pytest.mark.parametrize("cle", ["ANON_KEY", "SERVICE_ROLE_KEY"])
def test_passerelle_refuse_api_admin_gotrue_403(secrets_env, methode, chemin, cle):
    k = secrets_env[cle]
    r = requests.request(methode, APP_URL + chemin,
                         headers={"apikey": k, "Authorization": f"Bearer {k}"},
                         json={"email": email_unique(), "password": "x" * 20} if methode == "POST" else None,
                         timeout=TIMEOUT)
    assert r.status_code == 403


# --- SPEC-001.8 : aucune URL vers un autre hôte/port côté front -------------------------------
@pytest.mark.spec("SPEC-001.8")
@pytest.mark.parametrize("path", FICHIERS_SERVIS)
def test_fichier_servi_sans_url_vers_autre_port(path):
    r = servi(path)
    assert r.status_code == 200, f"{path} non servi"
    for interdit in (":9999", ":3000", ":5432", "http://auth", "http://rest", "localhost"):
        assert interdit not in r.text, f"{path} contient {interdit!r}"


@pytest.mark.spec("SPEC-001.8")
def test_front_utilise_window_location_origin():
    textes = "".join(servi(p).text for p in ("/app.js", "/config.js"))
    assert "window.location.origin" in textes or "location.origin" in textes


# --- SPEC-001.9 : CSP ------------------------------------------------------------------------
@pytest.mark.spec("SPEC-001.9")
def test_csp_default_et_connect_src_self():
    csp = servi("/").headers.get("Content-Security-Policy", "")
    assert "default-src 'self'" in csp, csp
    assert "connect-src 'self'" in csp, csp


# --- SPEC-001.10 : clé anon seule exposée -----------------------------------------------------
@pytest.mark.spec("SPEC-001.10")
def test_config_js_expose_la_cle_anon_courante_et_aucune_autre(secrets_env):
    txt = servi("/config.js").text
    assert secrets_env["ANON_KEY"] in txt, "ANON_KEY courante absente de /config.js"
    autres = {m for m in JWT_RE.findall(txt) if m != secrets_env["ANON_KEY"]}
    assert not autres, f"{len(autres)} autre(s) JWT dans /config.js"


@pytest.mark.spec("SPEC-001.10")
@pytest.mark.parametrize("path", FICHIERS_SERVIS)
def test_cle_service_role_absente_des_fichiers_servis(secrets_env, path):
    txt = servi(path).text
    assert secrets_env["SERVICE_ROLE_KEY"] not in txt
    assert secrets_env["JWT_SECRET"] not in txt


# --- SPEC-001.11 : configuration GoTrue -------------------------------------------------------
@pytest.mark.spec("SPEC-001.11")
def test_inscription_ouvre_une_session_immediate(anon_key):
    r = signup(anon_key, email_unique(), "Motdepasse-1234", "Inscrit immédiat")
    assert r.status_code in (200, 201), r.text[:300]
    assert r.json().get("access_token"), "pas de session : confirmation e-mail encore exigée ?"


@pytest.mark.spec("SPEC-001.11")
def test_inscription_mot_de_passe_7_caracteres_refusee_422_sans_compte(anon_key, admin):
    email = email_unique()
    r = signup(anon_key, email, "Ab1-xyz", "Trop court")
    assert r.status_code == 422, r.text[:300]
    assert compte_admin(admin, email=email) == []


@pytest.mark.spec("SPEC-001.11")
def test_inscription_mot_de_passe_8_caracteres_acceptee(anon_key):
    r = signup(anon_key, email_unique(), "Ab1-xyzw", "Huit car")
    assert r.status_code in (200, 201), r.text[:300]


@pytest.mark.spec("SPEC-001.11")
def test_inscription_email_deja_utilise_refusee_sans_doublon(anon_key, admin):
    email = email_unique()
    assert signup(anon_key, email, "Motdepasse-1234", "Premier").status_code in (200, 201)
    r = signup(anon_key, email, "Autre-motdepasse-9", "Second")
    assert 400 <= r.status_code < 500, f"{r.status_code} {r.text[:300]}"
    assert len(compte_admin(admin, email=email)) == 1


# --- SPEC-001.12 : PostgREST n'expose que public ----------------------------------------------
@pytest.mark.spec("SPEC-001.12")
@pytest.mark.parametrize("fonction", ["is_active_member", "is_admin"])
def test_fonctions_private_non_exposees_404(admin, fonction):
    r = admin.rpc(fonction)
    assert r.status_code == 404, f"{r.status_code} {r.text[:200]}"


@pytest.mark.spec("SPEC-001.12")
def test_schema_private_non_accessible_par_profil(admin):
    r = admin.get("schema_migrations", headers={"Accept-Profile": "private"})
    assert 400 <= r.status_code < 500, f"{r.status_code} {r.text[:200]}"


# --- SPEC-001.13 : présence des objets du schéma via l'API ------------------------------------
@pytest.mark.spec("SPEC-001.13")
@pytest.mark.parametrize("objet", ["profiles", "tasks", "time_entries", "help_proposals",
                                   "task_summary", "team_load"])
def test_objets_du_schema_presents_via_api(admin, objet):
    r = admin.get(objet, params={"limit": 1})
    assert r.status_code == 200, f"{objet} → {r.status_code} {r.text[:200]}"
