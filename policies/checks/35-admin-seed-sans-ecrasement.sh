#!/usr/bin/env bash
# POLICY: ADMIN-seed-sans-ecrasement
# REF: SPEC-003.10 | SPEC-003.12 | ADR-012 | CA-002-4 | CA-002-33
# QUAND: always
# Statique (ast Python, aucune exécution de seed.py, aucun réseau, aucun docker, aucune création de compte).
#  - SPEC-003.10 : tools/deploy/seed.py n'emploie aucune méthode PUT/PATCH/DELETE ; seul GET et POST sont appelés
#    via appel() ; chaque POST (création de compte) est dans la seule branche « if u is None » ; aucune migration
#    (app/db/migrations/*.sql) ni tools/deploy/db.sh n'écrit dans auth.users (UPDATE, DELETE, encrypted_password =).
#  - SPEC-003.12 : seed.py ne lit ni n'écrit le fichier de secrets : hors docstring et commentaires, aucun
#    identifiant, chaîne ou importation contenant « secret » ou « .devenv », aucun appel open/read_text/write_text.
# Code 0 = respectée ; 1 = violée (ou seed.py absent) ; sortie : une ligne. N'affiche jamais de valeur de secret.
python3 -I - <<'PY'
import ast, pathlib, re, sys

ws = pathlib.Path("/workspace")
seed = ws / "tools/deploy/seed.py"
if not seed.is_file():
    print("tools/deploy/seed.py absent : SPEC-003.5/.10/.12 non vérifiables"); sys.exit(1)
tree = ast.parse(seed.read_text(encoding="utf-8"), filename="seed.py")
bad = []

# Docstrings : exclues de l'analyse (les commentaires ne figurent pas dans l'AST).
docs = set()
for n in ast.walk(tree):
    if isinstance(n, (ast.Module, ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)) and n.body:
        p = n.body[0]
        if isinstance(p, ast.Expr) and isinstance(p.value, ast.Constant) and isinstance(p.value.value, str):
            docs.add(id(p.value))

parent = {}
for p in ast.walk(tree):
    for c in ast.iter_child_nodes(p):
        parent[c] = p

def dans_branche_absent(noeud):
    """Vrai si noeud se trouve dans le corps de « if u is None » (compte absent)."""
    enfant = noeud
    while enfant in parent:
        p = parent[enfant]
        if (isinstance(p, ast.If) and enfant in p.body and isinstance(p.test, ast.Compare)
                and isinstance(p.test.left, ast.Name) and p.test.left.id == "u"
                and len(p.test.ops) == 1 and isinstance(p.test.ops[0], ast.Is)
                and isinstance(p.test.comparators[0], ast.Constant) and p.test.comparators[0].value is None):
            return True
        enfant = p
    return False

# SPEC-003.10 — méthodes HTTP : aucun PUT/PATCH/DELETE littéral ; appels appel() en GET/POST seulement.
for n in ast.walk(tree):
    if isinstance(n, ast.Constant) and isinstance(n.value, str) and id(n) not in docs:
        if n.value.strip().upper() in ("PUT", "PATCH", "DELETE"):
            bad.append(f"méthode {n.value.strip().upper()} ligne {n.lineno}")

appels = [n for n in ast.walk(tree)
          if isinstance(n, ast.Call) and isinstance(n.func, ast.Name) and n.func.id == "appel"]
if not appels:
    bad.append("aucun appel appel() : API GoTrue non identifiable")
for c in appels:
    if not c.args or not (isinstance(c.args[0], ast.Constant) and isinstance(c.args[0].value, str)):
        bad.append(f"appel() ligne {c.lineno} sans méthode littérale"); continue
    m = c.args[0].value.upper()
    if m not in ("GET", "POST"):
        bad.append(f"appel {m} ligne {c.lineno} (seuls GET et POST sont admis)")
    if m == "POST" and not dans_branche_absent(c):
        bad.append(f"POST ligne {c.lineno} hors de la branche « if u is None »")

# SPEC-003.10 — migrations et db.sh : aucune écriture sur auth.users.
SQL_ECRITURE = re.compile(
    r"\b(update\s+(only\s+)?auth\.users|delete\s+from\s+(only\s+)?auth\.users|encrypted_password\s*=)", re.I)
a_lire = sorted((ws / "app/db/migrations").glob("*.sql")) + [ws / "tools/deploy/db.sh"]
for f in a_lire:
    if not f.is_file():
        continue
    for i, ln in enumerate(f.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        if ln.lstrip().startswith(("--", "#")):
            continue
        if SQL_ECRITURE.search(ln):
            bad.append(f"{f.relative_to(ws)}:{i} écrit dans auth.users")

# SPEC-003.12 — seed.py ne touche pas au fichier de secrets (hors docstring et commentaires).
MOT = re.compile(r"secret|\.devenv", re.I)
for n in ast.walk(tree):
    if id(n) in docs:
        continue
    if isinstance(n, ast.Constant) and isinstance(n.value, str) and MOT.search(n.value):
        bad.append(f"chaîne vers les secrets ligne {n.lineno}")
    elif isinstance(n, ast.Name) and MOT.search(n.id):
        bad.append(f"identifiant « {n.id} » ligne {n.lineno}")
    elif isinstance(n, ast.Name) and n.id == "open":
        bad.append(f"open() ligne {n.lineno}")
    elif isinstance(n, ast.Attribute) and MOT.search(n.attr):
        bad.append(f"attribut « {n.attr} » ligne {n.lineno}")
    elif isinstance(n, ast.Attribute) and n.attr in ("open", "read_text", "write_text", "read_bytes", "write_bytes"):
        bad.append(f"accès fichier « {n.attr} » ligne {n.lineno}")
    elif isinstance(n, ast.alias) and MOT.search(n.name):
        bad.append(f"importation « {n.name} »")

if bad:
    print("non conforme : " + " ; ".join(sorted(set(bad))))
    sys.exit(1)
print("seed.py : aucun PUT/PATCH/DELETE, POST /admin/users seulement si compte absent, aucun accès au fichier de secrets ; "
      "migrations et db.sh n'écrivent pas dans auth.users")
PY
