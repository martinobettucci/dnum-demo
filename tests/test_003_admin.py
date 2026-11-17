"""SPEC-003 — Compte administrateur initial et secrets (CA-002-2, CA-002-4, CA-002-33).
Aucune valeur secrète n'apparaît dans les messages d'assertion."""
import base64, hashlib, hmac, json, re, stat

import pytest

from conftest import SECRETS_FILE, WORKSPACE, compte_admin, jwt_payload, login

CLES = ["POSTGRES_PASSWORD", "JWT_SECRET", "ANON_KEY", "SERVICE_ROLE_KEY",
        "ADMIN_EMAIL", "ADMIN_PASSWORD"]


def b64url_decode(s):
    return base64.urlsafe_b64decode(s + "=" * (-len(s) % 4))


# --- SPEC-003.1 --------------------------------------------------------------------------------
@pytest.mark.spec("SPEC-003.1")
@pytest.mark.parametrize("cle", CLES)
def test_fichier_secrets_contient_la_cle(secrets_env, cle):
    assert secrets_env.get(cle), f"{cle} absente ou vide"


@pytest.mark.spec("SPEC-003.1")
def test_jwt_secret_au_moins_40_caracteres(secrets_env):
    assert len(secrets_env["JWT_SECRET"]) >= 40, f"longueur {len(secrets_env['JWT_SECRET'])}"


@pytest.mark.spec("SPEC-003.1")
def test_mot_de_passe_admin_genere_20_alphanumeriques(secrets_env):
    """CA-002-4 (≥ 16 exigé par le CA, ≥ 20 par la spec)."""
    pw = secrets_env["ADMIN_PASSWORD"]
    assert len(pw) >= 20, f"longueur {len(pw)}"
    assert re.fullmatch(r"[A-Za-z0-9]+", pw), "alphabet non alphanumérique"


@pytest.mark.spec("SPEC-003.1")
def test_droits_fichier_0600_et_repertoire_0700():
    assert stat.S_IMODE(SECRETS_FILE.stat().st_mode) == 0o600, oct(SECRETS_FILE.stat().st_mode)
    assert stat.S_IMODE(SECRETS_FILE.parent.stat().st_mode) == 0o700


# --- SPEC-003.2 --------------------------------------------------------------------------------
@pytest.mark.spec("SPEC-003.2")
@pytest.mark.parametrize("cle,role", [("ANON_KEY", "anon"), ("SERVICE_ROLE_KEY", "service_role")])
def test_cle_est_un_jwt_hs256_signe_par_jwt_secret(secrets_env, cle, role):
    jeton = secrets_env[cle]
    parties = jeton.split(".")
    assert len(parties) == 3, f"{cle} n'est pas un JWT"
    entete = json.loads(b64url_decode(parties[0]))
    assert entete.get("alg") == "HS256"
    attendu = hmac.new(secrets_env["JWT_SECRET"].encode(), f"{parties[0]}.{parties[1]}".encode(),
                       hashlib.sha256).digest()
    assert hmac.compare_digest(attendu, b64url_decode(parties[2])), f"signature {cle} invalide"
    assert jwt_payload(jeton).get("role") == role


# --- SPEC-003.3 (part [T] : .devenv ignoré) ------------------------------------------------------
@pytest.mark.spec("SPEC-003.3")
def test_gitignore_contient_devenv():
    lignes = [l.strip() for l in (WORKSPACE / ".gitignore").read_text().splitlines()]
    assert any(l in (".devenv/", ".devenv", "/.devenv/", "/.devenv") for l in lignes)


# --- SPEC-003.4 --------------------------------------------------------------------------------
@pytest.mark.spec("SPEC-003.4")
def test_connexion_admin_200(secrets_env, anon_key):
    r = login(anon_key, secrets_env["ADMIN_EMAIL"], secrets_env["ADMIN_PASSWORD"])
    assert r.status_code == 200


@pytest.mark.spec("SPEC-003.4")
def test_admin_my_status_actif_et_admin(admin):
    st = admin.status()
    assert st["is_active"] is True
    assert st["role"] == "admin"


@pytest.mark.spec("SPEC-003.4")
def test_connexion_admin_mauvais_mot_de_passe_refusee(secrets_env, anon_key):
    r = login(anon_key, secrets_env["ADMIN_EMAIL"], secrets_env["ADMIN_PASSWORD"] + "x")
    assert 400 <= r.status_code < 500


# --- SPEC-003.5 --------------------------------------------------------------------------------
@pytest.mark.spec("SPEC-003.5")
def test_un_seul_compte_admin_email_actif_admin(admin, secrets_env):
    rows = compte_admin(admin, email=secrets_env["ADMIN_EMAIL"])
    assert len(rows) == 1, f"{len(rows)} compte(s) pour ADMIN_EMAIL"
    assert rows[0]["is_active"] is True and rows[0]["role"] == "admin"


@pytest.mark.spec("SPEC-003.5")
def test_un_seul_administrateur(admin):
    """Gestion d'un seul admin (hors périmètre §4) : aucun autre compte n'a le rôle admin."""
    r = admin.rpc("admin_list_accounts")
    assert r.status_code == 200
    assert [x["id"] for x in r.json() if x["role"] == "admin"] == [admin.id]


# --- SPEC-003.9 (seed : aucun compte autre que ADMIN_EMAIL hors comptes de test) -----------------
@pytest.mark.spec("SPEC-003.9")
def test_seul_admin_email_hors_comptes_de_test(admin, secrets_env):
    """Hors comptes de test (e-mail en @test.invalid, SPEC-006 §1), la liste admin ne contient que
    ADMIN_EMAIL. Ne dépend pas de l'ordre des tests : les comptes de test sont filtrés."""
    r = admin.rpc("admin_list_accounts")
    assert r.status_code == 200, f"admin_list_accounts → {r.status_code} {r.text[:300]}"
    admin_email = secrets_env["ADMIN_EMAIL"].lower()
    hors_test = sorted({(x.get("email") or "").lower() for x in r.json()
                        if not (x.get("email") or "").lower().endswith("@test.invalid")})
    assert hors_test == [admin_email], f"comptes hors @test.invalid : {len(hors_test)} (attendu : ADMIN_EMAIL seul)"


# --- SPEC-003.6 (part [T] : aucun secret dans le journal de déploiement) ------------------------
@pytest.mark.spec("SPEC-003.6")
def test_deploy_log_sans_secret(secrets_env):
    log = WORKSPACE / ".devenv" / "deploy.log"
    if not log.exists():
        pytest.skip("deploy.log absent")
    txt = log.read_text(errors="replace")
    for cle in ("ADMIN_PASSWORD", "JWT_SECRET", "POSTGRES_PASSWORD", "SERVICE_ROLE_KEY", "ANON_KEY"):
        assert secrets_env[cle] not in txt, f"valeur de {cle} présente dans deploy.log"
