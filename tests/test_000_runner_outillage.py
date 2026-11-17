"""Outillage de l'image du runner : git, curl et bash épinglés (SPEC-000.2, ADR-015, CLAUDE.md §1).

Deux vérifications, toutes deux sans Docker et sans secret :

1. `test_paquet_installee_dans_le_runner_a_la_version_epinglee` (**premier test du module**) :
   exécuté dans le conteneur runner, dont l'image est précisément celle à prouver, il interroge
   la base dpkg locale (`dpkg-query -W -f='${Version}' <paquet>`, subprocess sans shell) et compare
   la version installée à celle lue dans `tools/runner/Dockerfile`. Hors runner (dpkg-query absent),
   il est ignoré avec une raison explicite ; un écart ou un paquet absent fait échouer le test.
2. `test_paquet_runner_installe_en_version_epinglee` : vérification **statique** du Dockerfile
   (analyse structurelle : instructions, lignes de continuation, segments `&&`, arguments de
   `apt-get install` via `shlex`). Elle prouve que le Dockerfile déclare chaque paquet en version exacte.

Les versions sont lues dans ce Dockerfile et jamais recopiées ici.
"""
import pathlib
import re
import shlex
import shutil
import subprocess

import pytest

RACINE = pathlib.Path(__file__).resolve().parents[1]
DOCKERFILE_RUNNER = RACINE / "tools" / "runner" / "Dockerfile"
PAQUETS_ATTENDUS = ("git", "curl", "bash")
# Version Debian exacte : [epoch:]amont-révision. La révision (après le dernier « - ») est obligatoire.
RE_VERSION_DEBIAN = re.compile(r"^(\d+:)?[0-9][A-Za-z0-9.+~:-]*-[A-Za-z0-9.+~]+$")


@pytest.fixture(autouse=True)
def _skip_si_pile_arretee():
    """Surcharge de tests/conftest.py : cette vérification est statique, elle ne dépend pas de la pile."""
    yield


# --------------------------------------------------------------------------- premier test : image runner (SPEC-000.2)
@pytest.mark.spec("SPEC-000.2")
@pytest.mark.parametrize("paquet", PAQUETS_ATTENDUS)
def test_paquet_installee_dans_le_runner_a_la_version_epinglee(paquet):
    """Dans le conteneur runner, dpkg-query donne pour git, curl et bash la version épinglée dans tools/runner/Dockerfile."""
    if shutil.which("dpkg-query") is None:
        pytest.skip(
            "dpkg-query absent : exécution hors conteneur runner (Debian) ; "
            "la version installée ne peut pas être interrogée ici"
        )
    attendue = version_epinglee_dockerfile(paquet)
    resultat = subprocess.run(
        ["dpkg-query", "-W", "-f=${Version}", paquet],
        capture_output=True,
        text=True,
        timeout=30,
    )
    assert resultat.returncode == 0, (
        f"{paquet} non installé dans ce conteneur (dpkg-query rc={resultat.returncode}) : "
        f"{resultat.stderr.strip()}"
    )
    installee = resultat.stdout.strip()
    assert installee == attendue, (
        f"{paquet} : version installée « {installee} » ≠ version épinglée « {attendue} » "
        "(tools/runner/Dockerfile)"
    )


def version_epinglee_dockerfile(paquet):
    """Version exacte de `paquet` lue dans tools/runner/Dockerfile ; échec explicite si absente ou non épinglée."""
    assert DOCKERFILE_RUNNER.is_file(), "tools/runner/Dockerfile introuvable"
    texte = DOCKERFILE_RUNNER.read_text(encoding="utf-8")
    paquets = []
    for mot, args in instructions(texte):
        if mot == "RUN":
            paquets += paquets_apt_installes(args)
    present, version = epinglage(paquets, paquet)
    assert present, f"{paquet} absent de l'instruction `apt-get install` du Dockerfile du runner"
    assert version is not None, f"{paquet} installé sans version exacte (`{paquet}=<version>` attendu)"
    return version


# --------------------------------------------------------------------------- analyse statique du Dockerfile
def instructions(texte):
    """Analyse minimale d'un Dockerfile : liste de (MOT_CLE, arguments), continuations `\\` jointes."""
    lignes, courante = [], ""
    for brute in texte.splitlines():
        ligne = brute.strip()
        if not courante and (not ligne or ligne.startswith("#")):
            continue
        if ligne.endswith("\\"):
            courante += ligne[:-1] + " "
            continue
        lignes.append(courante + ligne)
        courante = ""
    if courante:
        lignes.append(courante)
    resultat = []
    for ligne in lignes:
        mot, _, args = ligne.partition(" ")
        resultat.append((mot.upper(), args.strip()))
    return resultat


def paquets_apt_installes(args_run):
    """Jetons (`nom` ou `nom=version`) passés à `apt-get install` dans une instruction RUN."""
    paquets = []
    for segment in args_run.split("&&"):
        jetons = shlex.split(segment)
        if "apt-get" in jetons and "install" in jetons:
            apres = jetons[jetons.index("install") + 1:]
            paquets += [j for j in apres if not j.startswith("-")]
    return paquets


def epinglage(paquets, nom):
    """(présent, version) pour `nom` ; version = None si le paquet est installé sans `=version`."""
    for jeton in paquets:
        n, sep, version = jeton.partition("=")
        if n == nom:
            return True, (version if sep else None)
    return False, None


@pytest.mark.spec("SPEC-000.2")
@pytest.mark.parametrize("paquet", PAQUETS_ATTENDUS)
def test_paquet_runner_installe_en_version_epinglee(paquet):
    """git, curl et bash sont installés par `apt-get install` dans tools/runner/Dockerfile, en version exacte lue dans ce fichier."""
    version = version_epinglee_dockerfile(paquet)
    assert RE_VERSION_DEBIAN.match(version), (
        f"{paquet} : version « {version} » non conforme à une version Debian exacte (amont-révision)"
    )
