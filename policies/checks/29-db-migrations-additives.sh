#!/usr/bin/env bash
# POLICY: DB-migrations-additives
# REF: SPEC-004.18 | SPEC-004.12 | ADR-011 | ADR-015 | CA-002-33
# QUAND: always
# Statique sur app/db/migrations/ (ADR-011, décision 1 à 4) :
#  (a) fichiers NNN >= 006 : aucun DROP, TRUNCATE, DELETE (hors « on delete », « for delete », GRANT/REVOKE),
#      RENAME, ALTER ... TYPE, CONCURRENTLY, CREATE TABLE sans IF NOT EXISTS ;
#  (b) CREATE INDEX / TABLE / SCHEMA... avec IF NOT EXISTS ; CREATE FUNCTION / VIEW / TRIGGER avec OR REPLACE ;
#      ADD COLUMN avec IF NOT EXISTS, sans NOT NULL sans DEFAULT ; chaque CREATE POLICY dans un bloc DO
#      gardé par pg_policies et IF NOT EXISTS ;
#  (c) 001 à 005 identiques, par sha256, à leur version dans la référence git dae9044 (ADR-015 §4-§5, ADR-013 D-3) :
#      lecture seule uniquement, par « git cat-file -e » puis « git show dae9044:<chemin> » ; aucun git status, diff,
#      add, rm ou checkout, index non touché (dépôt monté en lecture seule). Si git ou la référence est indisponible :
#      « non exécutée », donc échec (jamais « réussie »).
python3 -I - <<'PY'
import hashlib, pathlib, re, shutil, subprocess, sys
d = pathlib.Path("/workspace/app/db/migrations")
if not d.is_dir():
    print("app/db/migrations absent : migrations non vérifiables"); sys.exit(1)
fs = sorted(p for p in d.iterdir() if p.is_file() and re.fullmatch(r"\d{3}_[a-z0-9_]+\.sql", p.name))
par_num = {}
for p in fs:
    par_num.setdefault(int(p.name[:3]), p)
bad, suivantes = [], []
for n in range(1, 6):
    if n not in par_num:
        bad.append(f"migration {n:03d} figée absente")
for n, p in sorted(par_num.items()):
    if n >= 6:
        suivantes.append(p)

def nettoie(t):
    t = re.sub(r"/\*.*?\*/", " ", t, flags=re.S)
    t = re.sub(r"--[^\n]*", " ", t)
    return t.lower()

INTERDITS = [
    (r"\bdrop\b", "DROP"),
    (r"\btruncate\b", "TRUNCATE"),
    (r"\brename\b", "RENAME"),
    (r"\balter\s+column\s+[\w\"]+\s+(set\s+data\s+)?type\b", "ALTER ... TYPE"),
    (r"\bconcurrently\b", "CONCURRENTLY"),
]
for p in suivantes:
    t = nettoie(p.read_text(errors="replace"))
    nom = p.name
    for motif, lib in INTERDITS:
        if re.search(motif, t):
            bad.append(f"{nom} : {lib} interdit")
    sans = re.sub(r"\bon\s+delete\b|\bfor\s+delete\b", " ", t)
    hors_droits = [s for s in sans.split(";") if not re.match(r"\s*(grant|revoke)\b", s)]
    if re.search(r"\bdelete\b", ";".join(hors_droits)):
        bad.append(f"{nom} : DELETE interdit")
    for m in re.finditer(r"\bcreate\s+(or\s+replace\s+)?((?:temp(?:orary)?|unlogged|unique|recursive|materialized)\s+)*"
                         r"(table|index|function|view|trigger|policy|schema|sequence|extension|type|role|domain)\b"
                         r"(\s+if\s+not\s+exists\b)?", t):
        orr, kind, ine = bool(m.group(1)), m.group(3), bool(m.group(4))
        if kind == "policy":
            continue  # traitée plus bas (bloc DO gardé)
        if kind in ("function", "view", "trigger"):
            if not orr:
                bad.append(f"{nom} : CREATE {kind} sans OR REPLACE")
        elif not ine:
            bad.append(f"{nom} : CREATE {kind} sans IF NOT EXISTS")
    for m in re.finditer(r"\badd\s+column\s+(?!if\s+not\s+exists\b)", t):
        bad.append(f"{nom} : ADD COLUMN sans IF NOT EXISTS")
        break
    for seg in re.split(r"\badd\s+column\s+", t)[1:]:
        seg = re.split(r";", seg)[0]
        seg = re.sub(r",\s*$", "", seg)
        if re.search(r"\bnot\s+null\b", seg) and not re.search(r"\bdefault\b", seg):
            bad.append(f"{nom} : colonne ajoutée NOT NULL sans DEFAULT")
            break
    for m in re.finditer(r"\bcreate\s+policy\b", t):
        dedans = False
        for b in re.finditer(r"\$(\w*)\$(.*?)\$\1\$", t, re.S):
            if b.start() <= m.start() < b.end():
                avant = t[max(0, b.start() - 12):b.start()]
                dedans = bool(re.search(r"\bdo\s*$", avant)) and "pg_policies" in b.group(2) \
                    and bool(re.search(r"not\s+exists", b.group(2)))
                break
        if not dedans:
            bad.append(f"{nom} : CREATE POLICY hors bloc DO gardé par pg_policies")
            break

# (c) 001 à 005 identiques par sha256 à la référence dae9044 (ADR-015 §4-§5). Lecture seule.
REF = "dae9044"
def sha(b):
    return hashlib.sha256(b).hexdigest()
if shutil.which("git") is None:
    bad.append(f"001–005 : git absent du conteneur runner, comparaison à {REF} non exécutée")
else:
    existe = subprocess.run(["git", "-C", "/workspace", "cat-file", "-e", f"{REF}^{{commit}}"], capture_output=True)
    if existe.returncode != 0:
        bad.append(f"001–005 : référence {REF} introuvable (non exécutée)")
    else:
        for n in range(1, 6):
            if n not in par_num:
                continue
            p = par_num[n]
            r = subprocess.run(["git", "-C", "/workspace", "show", f"{REF}:app/db/migrations/{p.name}"],
                               capture_output=True)
            if r.returncode != 0:
                bad.append(f"{p.name} : absent de la référence {REF} (non exécutée)")
            elif sha(r.stdout) != sha(p.read_bytes()):
                bad.append(f"{p.name} modifié par rapport à {REF} (figé, ADR-011)")

if bad:
    print("migrations non additives ou non vérifiables : " + " ; ".join(bad)); sys.exit(1)
pas = f"{len(suivantes)} migration(s) >= 006 additives et idempotentes" if suivantes else "aucune migration >= 006 à contrôler"
print(f"{pas} ; 001 à 005 identiques à la référence {REF}")
PY
