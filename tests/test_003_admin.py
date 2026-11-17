"""SPEC-003 — Compte administrateur initial et secrets (CA-002-2, CA-002-4, CA-002-33).
Aucune valeur secrète n'apparaît dans les messages d'assertion : les assertions ne comparent que des
booléens ou entiers calculés hors de l'assert (pytest réaffiche sinon les sous-expressions)."""
import base64, hashlib, hmac, json, re, stat

import pytest

from conftest import SECRETS_FILE, WORKSPACE, compte_admin, extrait, jwt_payload, login, masquer
from stub_gotrue import StubGoTrue, compte, environnement_factice, lancer_seed

CLES = ["POSTGRES_PASSWORD", "JWT_SECRET", "ANON_KEY", "SERVICE_ROLE_KEY",
        "ADMIN_EMAIL", "ADMIN_PASSWORD"]
CLES_NON_PUBLIQUES = ("ADMIN_PASSWORD", "JWT_SECRET", "POSTGRES_PASSWORD", "SERVICE_ROLE_KEY", "ANON_KEY")


def b64url_decode(s):
    return base64.urlsafe_b64decode(s + "=" * (-len(s) % 4))


# --- SPEC-003.1 --------------------------------------------------------------------------------
@pytest.mark.spec("SPEC-003.1")
@pytest.mark.parametrize("cle", CLES, ids=CLES)  # ids = noms de variables, jamais valeurs
def test_fichier_secrets_contient_la_cle(secrets_env, cle):
    presente = bool(secrets_env.get(cle))
    assert presente, f"{cle} absente ou vide"


@pytest.mark.spec("SPEC-003.1")
def test_jwt_secret_au_moins_40_caracteres(secrets_env):
    longueur = len(secrets_env["JWT_SECRET"])
    assert longueur >= 40, f"longueur {longueur}"


@pytest.mark.spec("SPEC-003.1")
def test_mot_de_passe_admin_genere_20_alphanumeriques(secrets_env):
    """CA-002-4 (≥ 16 exigé par le CA, ≥ 20 par la spec)."""
    pw = secrets_env["ADMIN_PASSWORD"]
    longueur = len(pw)
    alphanumerique = re.fullmatch(r"[A-Za-z0-9]+", pw) is not None
    assert longueur >= 20, f"longueur {longueur}"
    assert alphanumerique, "alphabet non alphanumérique"


@pytest.mark.spec("SPEC-003.1")
def test_droits_fichier_0600_et_repertoire_0700():
    mode_fichier = stat.S_IMODE(SECRETS_FILE.stat().st_mode)
    mode_repertoire = stat.S_IMODE(SECRETS_FILE.parent.stat().st_mode)
    assert mode_fichier == 0o600, f"mode fichier {oct(mode_fichier)}"
    assert mode_repertoire == 0o700, f"mode répertoire {oct(mode_repertoire)}"


# --- SPEC-003.2 --------------------------------------------------------------------------------
@pytest.mark.spec("SPEC-003.2")
@pytest.mark.parametrize("cle,role", [("ANON_KEY", "anon"), ("SERVICE_ROLE_KEY", "service_role")],
                         ids=["ANON_KEY", "SERVICE_ROLE_KEY"])
def test_cle_est_un_jwt_hs256_signe_par_jwt_secret(secrets_env, cle, role):
    jeton = secrets_env[cle]
    parties = jeton.split(".")
    nb_parties = len(parties)
    assert nb_parties == 3, f"{cle} n'est pas un JWT ({nb_parties} segments)"
    entete = json.loads(b64url_decode(parties[0]))
    alg = entete.get("alg")
    assert alg == "HS256", f"alg {alg!r}"
    attendu = hmac.new(secrets_env["JWT_SECRET"].encode(), f"{parties[0]}.{parties[1]}".encode(),
                       hashlib.sha256).digest()
    signature_ok = hmac.compare_digest(attendu, b64url_decode(parties[2]))
    assert signature_ok, f"signature {cle} invalide"
    role_obtenu = jwt_payload(jeton).get("role")
    assert role_obtenu == role, f"{cle} : role {role_obtenu!r}, attendu {role!r}"


# --- SPEC-003.3 (part [T] : .devenv ignoré) ------------------------------------------------------
@pytest.mark.spec("SPEC-003.3")
def test_gitignore_contient_devenv():
    lignes = [l.strip() for l in (WORKSPACE / ".gitignore").read_text().splitlines()]
    assert any(l in (".devenv/", ".devenv", "/.devenv/", "/.devenv") for l in lignes)


# --- SPEC-003.4 --------------------------------------------------------------------------------
@pytest.mark.spec("SPEC-003.4")
def test_connexion_admin_200(secrets_env, anon_key):
    r = login(anon_key, secrets_env["ADMIN_EMAIL"], secrets_env["ADMIN_PASSWORD"])
    assert r.status_code == 200, f"connexion admin → {r.status_code}"


@pytest.mark.spec("SPEC-003.4")
def test_admin_my_status_actif_et_admin(admin):
    st = admin.status()
    assert st["is_active"] is True
    assert st["role"] == "admin"


@pytest.mark.spec("SPEC-003.4")
def test_connexion_admin_mauvais_mot_de_passe_refusee(secrets_env, anon_key):
    r = login(anon_key, secrets_env["ADMIN_EMAIL"], secrets_env["ADMIN_PASSWORD"] + "x")
    assert 400 <= r.status_code < 500, f"statut {r.status_code}"


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
    assert r.status_code == 200, f"admin_list_accounts → {r.status_code}"
    ids_admin = [x["id"] for x in r.json() if x["role"] == "admin"]
    assert ids_admin == [admin.id], f"{len(ids_admin)} compte(s) admin (attendu : celui de l'admin)"


# --- SPEC-003.9 (seed : aucun compte autre que ADMIN_EMAIL hors comptes de test) -----------------
@pytest.mark.spec("SPEC-003.9")
def test_seul_admin_email_hors_comptes_de_test(admin, secrets_env):
    """Hors comptes de test (e-mail en @test.invalid, SPEC-006 §1), la liste admin ne contient que
    ADMIN_EMAIL. Ne dépend pas de l'ordre des tests : les comptes de test sont filtrés."""
    r = admin.rpc("admin_list_accounts")
    assert r.status_code == 200, f"admin_list_accounts → {r.status_code} {extrait(r, 300)}"
    admin_email = secrets_env["ADMIN_EMAIL"].lower()
    hors_test = sorted({(x.get("email") or "").lower() for x in r.json()
                        if not (x.get("email") or "").lower().endswith("@test.invalid")})
    nb_hors_test = len(hors_test)
    seul_admin = hors_test == [admin_email]
    assert seul_admin, f"comptes hors @test.invalid : {nb_hors_test} (attendu : ADMIN_EMAIL seul)"


# --- SPEC-003.6 (part [T] : aucun secret dans le journal de déploiement) ------------------------
@pytest.mark.spec("SPEC-003.6")
def test_deploy_log_sans_secret(secrets_env):
    log = WORKSPACE / ".devenv" / "deploy.log"
    if not log.exists():
        pytest.skip("deploy.log absent")
    txt = log.read_text(errors="replace")
    # Seuls les NOMS des variables fuitées sortent dans le message, jamais leurs valeurs.
    fuites = [cle for cle in CLES_NON_PUBLIQUES if secrets_env.get(cle) and secrets_env[cle] in txt]
    assert not fuites, f"valeur(s) de secret présente(s) dans deploy.log : {', '.join(fuites)}"


# --- SPEC-003.10 (ADR-012) : seed sur compte existant, GoTrue joué par un stub local -------------
# Aucun deploy ni reset : seed.py est lancé directement contre 127.0.0.1 (stub_gotrue.py).
# Les valeurs passées au seed sont factices (environnement_factice) ; les assertions ne portent que sur
# des codes retour, des compteurs et des listes de (méthode, chemin).

@pytest.mark.spec("SPEC-003.10")
def test_seed_compte_existant_confirme_rc0_sans_aucune_ecriture():
    """Compte ADMIN_EMAIL existant et confirmé : seed rc=0, aucune requête hors GET /health et
    GET /admin/users (donc aucun POST, PUT, PATCH, DELETE)."""
    env = environnement_factice()
    with StubGoTrue([compte(env["email"], confirme=True)]) as stub:
        res = lancer_seed(stub.url, env)
        lu_comptes = ("GET", "/admin/users") in stub.requetes
        ecritures = len(stub.ecritures())
        hors = len(stub.hors_attendu())
    assert res.returncode == 0, f"seed rc={res.returncode} : {masquer(res.stderr[:300])}"
    assert lu_comptes, "le seed n'a pas interrogé GET /admin/users"
    assert ecritures == 0, f"{ecritures} requête(s) d'écriture reçue(s) par le stub"
    assert hors == 0, f"{hors} requête(s) hors GET /health et GET /admin/users"


@pytest.mark.spec("SPEC-003.10")
def test_seed_rejoue_n_fois_sur_compte_existant_sans_ecriture():
    """N déploiements successifs sans reset : aucune écriture cumulée, rc=0 à chaque passage."""
    env = environnement_factice()
    rc_successifs = []
    with StubGoTrue([compte(env["email"], confirme=True)]) as stub:
        for _ in range(3):
            rc_successifs.append(lancer_seed(stub.url, env).returncode)
        ecritures = len(stub.ecritures())
    assert rc_successifs == [0, 0, 0], f"codes retour successifs : {rc_successifs}"
    assert ecritures == 0, f"{ecritures} écriture(s) cumulée(s) sur 3 passages"


@pytest.mark.spec("SPEC-003.10")
def test_seed_compte_absent_cree_par_post_seul_sans_put_ni_patch_ni_delete():
    """Témoin positif : la seule écriture admise est le POST /admin/users de la branche « compte absent »
    (ADR-012, point 1). Sans cela, le stub ne prouverait pas qu'il détecte les écritures."""
    env = environnement_factice()
    with StubGoTrue([]) as stub:
        res = lancer_seed(stub.url, env)
        ecritures = stub.ecritures()
    assert res.returncode == 0, f"seed rc={res.returncode} : {masquer(res.stderr[:300])}"
    nb_post = sum(1 for m, p in ecritures if m == "POST" and p == "/admin/users")
    nb_autres = len(ecritures) - nb_post
    assert nb_post == 1, f"{nb_post} POST /admin/users (attendu : 1)"
    assert nb_autres == 0, f"{nb_autres} écriture(s) autre(s) que la création"
