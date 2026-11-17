"""Outillage commun des tests automatiques (testeur).

- Base : APP_URL (défaut http://app) ; Auth = $APP_URL/auth/v1 ; REST = $APP_URL/rest/v1.
- Secrets : /workspace/.devenv/secrets/<pile>.env (pile = DEVENV_PILE, défaut « dev »),
  lus en lecture seule, jamais affichés (aucune valeur dans les messages d'assertion).
- Isolation : chaque test crée ses comptes (e-mail unique t-<uuid>@test.invalid) par
  /auth/v1/signup, et les fait activer par l'admin via la RPC admin_set_active.
  Aucune dépendance à des données préexistantes hors compte admin : rejouable sur base non vide.
- Pile non démarrée ⇒ tous les tests sont « skip » (SPEC-006 §1).
"""
import base64, json, os, pathlib, re, uuid
from urllib.parse import urlsplit

import pytest
import requests

APP_URL = os.environ.get("APP_URL", "http://app").rstrip("/")
PILE = os.environ.get("DEVENV_PILE", "dev")
WORKSPACE = pathlib.Path(os.environ.get("WORKSPACE", "/workspace"))
SECRETS_FILE = WORKSPACE / ".devenv" / "secrets" / f"{PILE}.env"
TIMEOUT = 10
MOT_DE_PASSE_TEST = "Test-" + uuid.uuid4().hex[:16]  # propre à la session, jamais persisté


def pytest_configure(config):
    config.addinivalue_line("markers", "spec(id): identifiant de la spécification couverte")
    config.addinivalue_line("markers", "could: exigence « Could » (non bloquante pour la recette)")


# --------------------------------------------------------------------------- débit (SPEC-001.14, ADR-006 §1)
# Plafond d'inscriptions par passe de `./dev test` (SPEC-006 §1) : au-delà, saisir l'architecte.
PLAFOND_INSCRIPTIONS_PAR_PASSE = 220

# Relevé de toutes les réponses reçues de /auth/v1/* pendant la passe : (méthode, chemin, statut).
# Alimenté par l'encapsulation de Session.send : couvre aussi les appels directs de requests.
RELEVES_AUTH = []

_send_original = requests.sessions.Session.send


def _send_releve(self, request, **kwargs):
    reponse = _send_original(self, request, **kwargs)
    chemin = urlsplit(request.url).path
    if chemin.startswith("/auth/v1/"):
        RELEVES_AUTH.append((request.method, chemin, reponse.status_code))
    return reponse


requests.sessions.Session.send = _send_releve


def pytest_collection_modifyitems(config, items):
    """test_aucune_reponse_429 doit voir les réponses de toutes les autres suites : il s'exécute en dernier."""
    dernier = [i for i in items if i.name == "test_aucune_reponse_429"]
    items[:] = [i for i in items if i not in dernier] + dernier


# --------------------------------------------------------------------------- pile démarrée ?
_PILE_UP = None


def pile_demarree():
    global _PILE_UP
    if _PILE_UP is None:
        try:
            requests.get(APP_URL + "/", timeout=3)
            _PILE_UP = True
        except requests.RequestException:
            _PILE_UP = False
    return _PILE_UP


@pytest.fixture(autouse=True)
def _skip_si_pile_arretee():
    if not pile_demarree():
        pytest.skip(f"pile non démarrée ({APP_URL} injoignable)")


@pytest.fixture
def app_url():
    return APP_URL


# --------------------------------------------------------------------------- secrets
def lire_env(path):
    vals = {}
    for ligne in pathlib.Path(path).read_text().splitlines():
        ligne = ligne.strip()
        if not ligne or ligne.startswith("#") or "=" not in ligne:
            continue
        k, v = ligne.split("=", 1)
        k = k.strip().removeprefix("export ").strip()
        v = v.strip()
        if len(v) >= 2 and v[0] == v[-1] and v[0] in "'\"":
            v = v[1:-1]
        vals[k] = v
    return vals


# --------------------------------------------------------------------------- masquage des secrets
# Règle : aucune valeur secrète dans un message d'assertion, un repr, un id de test ni une sortie.
# Les assertions ne manipulent que des booléens / entiers calculés hors assert ; ce qui sort des
# tests (corps de réponse, rapport junit, sections capturées) passe par masquer().
CLES_SECRETES = re.compile(r"PASSWORD|SECRET|KEY|TOKEN", re.IGNORECASE)
JWT_MASQUE = re.compile(r"eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+")
MOTIFS_MASQUES = (re.compile(r"Test-[0-9a-f]{16}"), re.compile(r"P-[0-9a-f]{24}"))


def valeurs_secretes():
    """Valeurs à masquer : secrets du fichier (clés PASSWORD/SECRET/KEY/TOKEN) et mot de passe de session."""
    vals = {MOT_DE_PASSE_TEST}
    if SECRETS_FILE.is_file():
        try:
            env = lire_env(SECRETS_FILE)
        except OSError:
            env = {}
        vals |= {v for k, v in env.items() if CLES_SECRETES.search(k) and len(v) >= 8}
    return sorted(vals, key=len, reverse=True)


def masquer(texte):
    """Remplace les secrets, les JWT et les mots de passe dérivés par des marqueurs."""
    texte = str(texte)
    for v in valeurs_secretes():
        texte = texte.replace(v, "<secret masqué>")
    texte = JWT_MASQUE.sub("<jwt masqué>", texte)
    for motif in MOTIFS_MASQUES:
        texte = motif.sub("<mot de passe masqué>", texte)
    return texte


def extrait(r, n=300):
    """Début du corps d'une réponse, masqué, pour les messages d'assertion."""
    return masquer(r.text[:n])


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """Filet de sécurité : rapport (junit.xml, terminal) et sections capturées sont masqués."""
    outcome = yield
    rapport = outcome.get_result()
    if rapport.failed and rapport.longrepr is not None:
        rapport.longrepr = masquer(rapport.longrepr)
    rapport.sections = [(titre, masquer(contenu)) for titre, contenu in rapport.sections]


@pytest.fixture(scope="session")
def secrets_env():
    assert SECRETS_FILE.is_file(), f"fichier de secrets absent : {SECRETS_FILE} (SPEC-003.1)"
    return lire_env(SECRETS_FILE)


@pytest.fixture(scope="session")
def anon_key(secrets_env):
    # Pas d'assert sur secrets_env.get(...) : pytest réaffiche le dictionnaire entier dans l'explication.
    cle = secrets_env.get("ANON_KEY")
    if not cle:
        pytest.fail("ANON_KEY absente du fichier de secrets", pytrace=False)
    return cle


def jwt_payload(token):
    seg = token.split(".")[1]
    return json.loads(base64.urlsafe_b64decode(seg + "=" * (-len(seg) % 4)))


# --------------------------------------------------------------------------- client API
class Api:
    """Client minimal Auth + REST passant par la passerelle (même origine)."""

    def __init__(self, anon_key, token=None, bearer_anon=True):
        self.anon_key = anon_key
        self.token = token
        self.bearer_anon = bearer_anon
        self.s = requests.Session()
        self.id = jwt_payload(token)["sub"] if token else None
        self.email = None
        self.password = None
        self.display_name = None

    def __repr__(self):
        # Jamais de jeton ni de mot de passe dans un repr (messages d'assertion, journaux)
        return f"<Api compte={self.id or 'anonyme'}>"

    def headers(self, extra=None):
        h = {"apikey": self.anon_key, "Content-Type": "application/json"}
        if self.token:
            h["Authorization"] = f"Bearer {self.token}"
        elif self.bearer_anon:
            h["Authorization"] = f"Bearer {self.anon_key}"
        h.update(extra or {})
        return h

    # REST
    def get(self, path, params=None, headers=None):
        return self.s.get(f"{APP_URL}/rest/v1/{path}", params=params,
                          headers=self.headers(headers), timeout=TIMEOUT)

    def post(self, path, body, headers=None):
        return self.s.post(f"{APP_URL}/rest/v1/{path}", json=body,
                           headers=self.headers({"Prefer": "return=representation", **(headers or {})}),
                           timeout=TIMEOUT)

    def patch(self, path, params, body):
        return self.s.patch(f"{APP_URL}/rest/v1/{path}", params=params, json=body,
                            headers=self.headers({"Prefer": "return=representation"}), timeout=TIMEOUT)

    def delete(self, path, params):
        return self.s.delete(f"{APP_URL}/rest/v1/{path}", params=params,
                             headers=self.headers({"Prefer": "return=representation"}), timeout=TIMEOUT)

    def rpc(self, name, **args):
        return self.s.post(f"{APP_URL}/rest/v1/rpc/{name}", json=args,
                           headers=self.headers(), timeout=TIMEOUT)

    # Lectures pratiques (assertion d'un succès HTTP)
    def rows(self, path, **params):
        r = self.get(path, params=params)
        assert r.status_code == 200, f"GET {path} → {r.status_code} {extrait(r, 300)}"
        return r.json()

    def task(self, task_id):
        rows = self.rows("task_summary", id=f"eq.{task_id}")
        assert len(rows) == 1, f"task_summary id={task_id} : {len(rows)} ligne(s)"
        return rows[0]

    def load(self, user_id):
        rows = self.rows("team_load", user_id=f"eq.{user_id}")
        return rows[0] if rows else None

    def status(self):
        r = self.rpc("my_status")
        assert r.status_code == 200, f"my_status → {r.status_code} {extrait(r, 300)}"
        return un(r.json())

    def create_task(self, title=None, estimate=1, **extra):
        body = {"title": title or f"t-{uuid.uuid4().hex[:8]}", "estimate_hours": estimate,
                "assignee_id": self.id, **extra}
        r = self.post("tasks", body)
        assert r.status_code == 201, f"création de tâche → {r.status_code} {extrait(r, 300)}"
        return r.json()[0]

    def log(self, task_id, minutes, **extra):
        r = self.post("time_entries", {"task_id": task_id, "minutes": minutes, **extra})
        assert r.status_code == 201, f"saisie de temps → {r.status_code} {extrait(r, 300)}"
        return r.json()[0]

    def set_status(self, task_id, status):
        r = self.patch("tasks", {"id": f"eq.{task_id}"}, {"status": status})
        assert r.status_code == 200 and len(r.json()) == 1, f"PATCH status → {r.status_code} {extrait(r, 300)}"


def un(data):
    """Une RPC peut renvoyer un objet ou une liste d'une ligne."""
    if isinstance(data, list):
        assert len(data) == 1, f"une ligne attendue, reçu {len(data)}"
        return data[0]
    return data


def refus(r):
    """Refus explicite : statut 4xx (jamais 2xx, jamais 5xx)."""
    return 400 <= r.status_code < 500


def sans_effet(r):
    """Refus, ou réponse 2xx sans aucune ligne (RLS qui masque)."""
    if refus(r):
        return True
    if 200 <= r.status_code < 300:
        if r.status_code == 204 or not r.content:
            return True
        try:
            return r.json() in ([], None)
        except ValueError:
            return False
    return False


def nombre_total(r):
    """Total renvoyé par PostgREST avec Prefer: count=exact (Content-Range: a-b/N ou */N)."""
    cr = r.headers.get("Content-Range", "")
    assert "/" in cr, f"Content-Range absent ou invalide : {cr!r}"
    return int(cr.split("/")[1])


def email_unique():
    return f"t-{uuid.uuid4()}@test.invalid"


def signup(anon_key, email, password, display_name):
    return requests.post(f"{APP_URL}/auth/v1/signup",
                         json={"email": email, "password": password,
                               "data": {"display_name": display_name}},
                         headers={"apikey": anon_key, "Content-Type": "application/json"},
                         timeout=TIMEOUT)


def login(anon_key, email, password):
    return requests.post(f"{APP_URL}/auth/v1/token", params={"grant_type": "password"},
                         json={"email": email, "password": password},
                         headers={"apikey": anon_key, "Content-Type": "application/json"},
                         timeout=TIMEOUT)


def connecter(anon_key, email, password):
    r = login(anon_key, email, password)
    assert r.status_code == 200, f"connexion {email} → {r.status_code} {extrait(r, 200)}"
    api = Api(anon_key, r.json()["access_token"])
    api.email, api.password = email, password
    return api


# --------------------------------------------------------------------------- fixtures comptes
@pytest.fixture(scope="session")
def admin(secrets_env, anon_key):
    for k in ("ADMIN_EMAIL", "ADMIN_PASSWORD"):
        if not secrets_env.get(k):
            pytest.fail(f"{k} absent du fichier de secrets", pytrace=False)
    r = login(anon_key, secrets_env["ADMIN_EMAIL"], secrets_env["ADMIN_PASSWORD"])
    assert r.status_code == 200, f"connexion admin → {r.status_code} (SPEC-003.4)"
    api = Api(anon_key, r.json()["access_token"])
    api.email = secrets_env["ADMIN_EMAIL"]
    return api


@pytest.fixture(scope="session")
def anon(anon_key):
    return Api(anon_key)


class Fabrique:
    """Crée des comptes de test uniques, actifs ou non (activation par l'admin)."""

    def __init__(self, anon_key, admin):
        self.anon_key, self.admin, self.n = anon_key, admin, 0

    def __call__(self, actif=True, nom=None):
        if PILE == "service":
            pytest.skip("SPEC-003.9 : aucun compte de test dans la pile service")
        self.n += 1
        email = email_unique()
        nom = nom or f"Testeur {self.n} {email[2:10]}"
        r = signup(self.anon_key, email, MOT_DE_PASSE_TEST, nom)
        assert r.status_code in (200, 201), f"signup → {r.status_code} {extrait(r, 300)}"
        token = r.json().get("access_token")
        assert token, "signup sans session immédiate (SPEC-001.11 : autoconfirm attendu)"
        api = Api(self.anon_key, token)
        api.email, api.password, api.display_name = email, MOT_DE_PASSE_TEST, nom
        if actif:
            self.activer(api.id)
        return api

    def activer(self, user_id, actif=True):
        r = self.admin.rpc("admin_set_active", p_user=user_id, p_active=actif)
        assert 200 <= r.status_code < 300, f"admin_set_active → {r.status_code} {extrait(r, 300)}"


@pytest.fixture(scope="session")
def fabrique(anon_key, admin):
    return Fabrique(anon_key, admin)


@pytest.fixture
def membre(fabrique):
    return fabrique(actif=True)


@pytest.fixture
def collegue(fabrique):
    return fabrique(actif=True)


@pytest.fixture
def tiers(fabrique):
    return fabrique(actif=True)


@pytest.fixture
def inactif(fabrique):
    return fabrique(actif=False)


def compte_admin(admin, user_id=None, email=None):
    r = admin.rpc("admin_list_accounts")
    assert r.status_code == 200, f"admin_list_accounts → {r.status_code} {extrait(r, 300)}"
    rows = r.json()
    if user_id:
        rows = [x for x in rows if x.get("id") == user_id]
    if email:
        rows = [x for x in rows if (x.get("email") or "").lower() == email.lower()]
    return rows


@pytest.fixture(scope="session")
def jeu(fabrique):
    """Jeu de données existant (tâche, temps, proposition) que les comptes anonymes et
    non activés ne doivent PAS voir : rend les assertions « zéro ligne » significatives."""
    a = fabrique(actif=True, nom="Jeu A")
    b = fabrique(actif=True, nom="Jeu B")
    t = a.create_task(title=f"jeu-{uuid.uuid4().hex[:8]}", estimate=3)
    e = a.log(t["id"], 30)
    r = b.rpc("offer_help", p_task=t["id"])
    assert 200 <= r.status_code < 300, f"offer_help (jeu) → {r.status_code} {extrait(r, 300)}"
    return {"a": a, "b": b, "task": t, "entry": e, "proposal": un(r.json()) if r.content else None}
