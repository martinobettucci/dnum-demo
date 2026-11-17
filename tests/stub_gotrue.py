"""Stub GoTrue local pour SPEC-003.10 (et SPEC-003.11) — ADR-012.

Objectif : exécuter `tools/deploy/seed.py` directement (sans `deploy`, sans `reset`, sans pile) contre un
serveur HTTP joué sur 127.0.0.1, et compter les requêtes reçues.

- `GET /health`                → 200 (attente du seed) ;
- `GET /admin/users`           → liste fournie par le test ;
- `POST /admin/users`          → 201 (seule écriture admise, branche « compte absent ») ;
- toute autre requête (dont PUT/PATCH/DELETE) → 405, et elle reste enregistrée dans `requetes`.

Règles de masquage (conftest.py) : les valeurs passées au seed sont FACTICES et générées ici ; elles ne
sortent jamais dans un message d'assertion, un repr ou un identifiant de test. Aucune valeur du fichier
de secrets n'est lue. Bibliothèque standard uniquement, hors pytest.
"""
import json, os, pathlib, subprocess, sys, threading, uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit

SEED = pathlib.Path(__file__).resolve().parents[1] / "tools" / "deploy" / "seed.py"
ECRITURES = ("POST", "PUT", "PATCH", "DELETE")
LECTURES_ATTENDUES = {("GET", "/health"), ("GET", "/admin/users")}


def environnement_factice():
    """Valeurs factices, propres à un appel de test (jamais celles de la pile)."""
    return {
        "email": f"admin-{uuid.uuid4().hex[:12]}@test.invalid",
        "password": "Factice-" + uuid.uuid4().hex,
        "cle": "factice-" + uuid.uuid4().hex,
    }


def compte(email, confirme=True, champ="email_confirmed_at"):
    """Entrée de GET /admin/users. `champ` choisit le champ de confirmation (ADR-012, repli confirmed_at)."""
    c = {"id": str(uuid.uuid4()), "aud": "authenticated", "email": email, "user_metadata": {}}
    if confirme:
        c[champ] = "2026-11-17T00:00:00Z"
    return c


class StubGoTrue:
    """Serveur GoTrue joué. Utilisé comme gestionnaire de contexte."""

    def __init__(self, utilisateurs):
        self.utilisateurs = list(utilisateurs)
        self.requetes = []  # (méthode, chemin sans query)
        self._srv = ThreadingHTTPServer(("127.0.0.1", 0), self._gestionnaire())
        self._fil = threading.Thread(target=self._srv.serve_forever, daemon=True)

    @property
    def url(self):
        return f"http://127.0.0.1:{self._srv.server_address[1]}"

    def ecritures(self):
        """Requêtes d'écriture reçues (POST, PUT, PATCH, DELETE)."""
        return [(m, p) for m, p in self.requetes if m in ECRITURES]

    def hors_attendu(self):
        """Requêtes reçues autres que GET /health et GET /admin/users (SPEC-003.10)."""
        return [(m, p) for m, p in self.requetes
                if (m, p) not in LECTURES_ATTENDUES and m not in ECRITURES]

    def __enter__(self):
        self._fil.start()
        return self

    def __exit__(self, *exc):
        self._srv.shutdown()
        self._srv.server_close()
        return False

    def _gestionnaire(self):
        stub = self

        class Gestionnaire(BaseHTTPRequestHandler):
            def log_message(self, *args):  # silence : rien sur stderr
                pass

            def _repondre(self, code, corps):
                donnees = json.dumps(corps).encode()
                self.send_response(code)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(donnees)))
                self.end_headers()
                self.wfile.write(donnees)

            def _traiter(self):
                chemin = urlsplit(self.path).path
                stub.requetes.append((self.command, chemin))
                if self.command == "GET" and chemin == "/health":
                    return self._repondre(200, {"status": "ok"})
                if self.command == "GET" and chemin == "/admin/users":
                    return self._repondre(200, {"users": stub.utilisateurs, "aud": "authenticated"})
                if self.command == "POST" and chemin == "/admin/users":
                    self.rfile.read(int(self.headers.get("Content-Length") or 0))
                    return self._repondre(201, {"id": str(uuid.uuid4()), "aud": "authenticated"})
                return self._repondre(405, {"error": "stub : requête non prévue"})

            do_GET = do_POST = do_PUT = do_PATCH = do_DELETE = _traiter

        return Gestionnaire


def lancer_seed(url, env):
    """Exécute tools/deploy/seed.py avec l'environnement minimal (GOTRUE_URL pointant sur le stub)."""
    environnement = {
        "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
        "GOTRUE_URL": url,
        "SERVICE_ROLE_KEY": env["cle"],
        "ADMIN_EMAIL": env["email"],
        "ADMIN_PASSWORD": env["password"],
    }
    return subprocess.run([sys.executable, str(SEED)], env=environnement,
                          capture_output=True, text=True, timeout=120)
