"""SPEC-004 — Piles dev / service, persistance, sauvegarde (CA-002-1, CA-002-33, CA-002-36).

Persistance (SPEC-004.3) en deux temps, pilotés par le fichier
iterations/<CURRENT>/tests/persistance-<pile>.json (aucun mot de passe en clair dedans) :
  1. passe A (`./dev test`) : `..._persistance_ecrire` crée un jeu marqué et l'enregistre ;
  2. le responsable applicatif fait `./dev deploy` SANS reset (ou `teardown` + `deploy`) ;
  3. passe B (`./dev test`) : `..._persistance_relire` retrouve le jeu (il « skip » tant
     qu'aucun déploiement n'a eu lieu après l'écriture), puis `..._ecrire` en pose un nouveau.
Sauvegarde/restauration (SPEC-004.8, Could) : même mécanisme avec DEVENV_PILE=service,
le responsable applicatif intercalant backup → reset → deploy → restore entre les deux passes.
"""
import datetime, hashlib, hmac, json, uuid

import pytest

from conftest import PILE, WORKSPACE, compte_admin, connecter, extrait, signup

ITER = (WORKSPACE / "iterations" / "CURRENT").read_text().strip() \
    if (WORKSPACE / "iterations" / "CURRENT").exists() else "000"
FICHIER = WORKSPACE / "iterations" / ITER / "tests" / f"persistance-{PILE}.json"


def empreinte(valeur):
    """Empreinte tronquée non réversible (comparer sans stocker la valeur)."""
    return hashlib.sha256(valeur.encode()).hexdigest()[:16]


def mdp_derive(secrets_env, email):
    """Mot de passe du compte persistant dérivé d'un secret hors git : rien en clair sur disque."""
    return "P-" + hmac.new(secrets_env["POSTGRES_PASSWORD"].encode(), email.encode(),
                           hashlib.sha256).hexdigest()[:24]


def derniers_deploiements():
    log = WORKSPACE / ".devenv" / "deploy.log"
    dates = []
    if log.exists():
        for ligne in log.read_text().splitlines():
            try:
                dates.append(json.loads(ligne)["date"])
            except (ValueError, KeyError):
                pass
    return dates


def maintenant():
    """Même format que `now` de ./dev (UTC) : comparable en chaîne avec deploy.log."""
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S+00:00")


def lire_jeu():
    return json.loads(FICHIER.read_text()) if FICHIER.exists() else None


# --- SPEC-004.1 --------------------------------------------------------------------------------
@pytest.mark.spec("SPEC-004.1")
def test_app_url_par_defaut_sert_la_pile(app_url):
    import requests
    assert requests.get(app_url + "/", timeout=5).status_code == 200


# --- SPEC-004.3 (relire AVANT écrire : ordre du fichier) ------------------------------------------
@pytest.mark.spec("SPEC-004.3")
@pytest.mark.spec("SPEC-003.5")
def test_persistance_relire(secrets_env, anon_key, admin):
    """CA-002-33 : le jeu écrit avant redéploiement est toujours là ; mot de passe admin inchangé."""
    jeu = lire_jeu()
    if not jeu:
        pytest.skip(f"aucun jeu marqué ({FICHIER.name}) : passe d'écriture non encore faite")
    if jeu.get("verifie_le"):
        pytest.skip("jeu déjà vérifié : un nouveau jeu sera écrit par la passe d'écriture")
    if not [d for d in derniers_deploiements() if d > jeu["ecrit_le_deploy"]]:
        pytest.skip("aucun ./dev deploy depuis l'écriture du jeu marqué")
    # mot de passe admin non régénéré (la connexion admin a réussi via la fixture `admin`)
    mot_de_passe_inchange = empreinte(secrets_env["ADMIN_PASSWORD"]) == jeu["admin_empreinte"]
    assert mot_de_passe_inchange, "ADMIN_PASSWORD a changé depuis l'écriture du jeu"
    admin_email = secrets_env["ADMIN_EMAIL"]
    nb_admin = len(compte_admin(admin, email=admin_email))
    assert nb_admin == 1, f"{nb_admin} compte(s) pour ADMIN_EMAIL"
    if jeu["membre_email"] != admin_email:
        acteur = connecter(anon_key, jeu["membre_email"], mdp_derive(secrets_env, jeu["membre_email"]))
        assert acteur.id == jeu["membre_id"]
        assert acteur.status()["is_active"] is True, "activation perdue"
    else:
        acteur = admin
    t = acteur.task(jeu["task_id"])
    assert t["title"] == jeu["task_title"]
    assert abs(float(t["logged_hours"]) - jeu["logged_hours"]) < 0.001, "temps logué perdu"
    if jeu.get("proposal_id"):
        assert acteur.rows("help_proposals", id=f"eq.{jeu['proposal_id']}"), "proposition perdue"
    jeu["verifie_le"] = maintenant()
    FICHIER.write_text(json.dumps(jeu, ensure_ascii=False, indent=2))


@pytest.mark.could
@pytest.mark.spec("SPEC-004.8")
def test_restauration_service_restitue_le_jeu_marque():
    """Couvert par test_persistance_relire exécuté avec DEVENV_PILE=service après
    backup → reset → deploy → restore (voir docstring du module)."""
    if PILE != "service":
        pytest.skip("à exécuter avec DEVENV_PILE=service")
    jeu = lire_jeu()
    assert jeu and jeu.get("verifie_le"), "jeu marqué non restitué/vérifié sur la pile service"


@pytest.mark.spec("SPEC-004.3")
def test_persistance_ecrire(secrets_env, anon_key, admin, fabrique):
    jeu = lire_jeu()
    if jeu and not jeu.get("verifie_le"):
        pytest.skip(f"jeu marqué en attente de relecture après redéploiement ({FICHIER.name})")
    marque = f"persist-{datetime.datetime.now():%Y%m%d-%H%M%S}-{uuid.uuid4().hex[:6]}"
    proposal_id = None
    if PILE == "service":           # SPEC-003.9 : aucun compte de test en pile service
        acteur, email = admin, secrets_env["ADMIN_EMAIL"]
    else:
        email = f"persist-{uuid.uuid4()}@test.invalid"
        r = signup(anon_key, email, mdp_derive(secrets_env, email), marque)
        assert r.status_code in (200, 201), extrait(r, 200)
        acteur = connecter(anon_key, email, mdp_derive(secrets_env, email))
        fabrique.activer(acteur.id)
    t = acteur.create_task(title=marque, estimate=8)
    acteur.log(t["id"], 75)
    if PILE != "service":
        aide = fabrique(actif=True)
        r = aide.rpc("offer_help", p_task=t["id"])
        assert 200 <= r.status_code < 300, extrait(r, 200)
        proposal_id = r.json() if isinstance(r.json(), str) else r.json()[0]
    FICHIER.parent.mkdir(parents=True, exist_ok=True)
    FICHIER.write_text(json.dumps({
        "pile": PILE, "ecrit_le": maintenant(),
        "ecrit_le_deploy": maintenant(),
        "membre_email": email, "membre_id": acteur.id,
        "task_id": t["id"], "task_title": marque, "logged_hours": 1.25,
        "proposal_id": proposal_id,
        "admin_empreinte": empreinte(secrets_env["ADMIN_PASSWORD"]),
    }, ensure_ascii=False, indent=2))


# --- SPEC-004.7 / 004.8 (Could) ----------------------------------------------------------------
@pytest.mark.could
@pytest.mark.spec("SPEC-004.7")
def test_pile_service_repond_avec_ses_propres_secrets(admin, secrets_env):
    if PILE != "service":
        pytest.skip("à exécuter avec DEVENV_PILE=service (APP_URL de la pile service)")
    assert admin.status()["role"] == "admin"
    dev = WORKSPACE / ".devenv" / "secrets" / "dev.env"
    if dev.exists():
        from conftest import lire_env
        partage = lire_env(dev).get("JWT_SECRET") == secrets_env["JWT_SECRET"]
        assert not partage, "pile service et pile dev partagent le même JWT_SECRET"


