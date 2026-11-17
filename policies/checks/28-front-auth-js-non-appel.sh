#!/usr/bin/env bash
# POLICY: FRONT-auth-js-non-appel
# REF: SPEC-001.15 (e) | ADR-010 (voie 1) | CA-002-2
# QUAND: always
# Condition de ./dev deploy service (ADR-010 voie 1). Aucune occurrence dans app/web/src de :
#   .admin.  /  auth.admin  (API admin d'auth-js)
#   getUserById, updateUserById, deleteUser   (GHSA-8r88-6cj9-9fh5)
#   listFactors, deleteFactor                 (MFA, même avis)
# Les commentaires JS sont retirés avant la recherche (une simple mention dans un commentaire n'est pas un appel).
# Recherche impossible (dossier absent) : « non exécutée », donc échec, jamais « réussie ».
python3 -I - <<'PY'
import pathlib, re, sys
src = pathlib.Path("/workspace/app/web/src")
if not src.is_dir():
    print("recherche non exécutée (échec) : app/web/src absent"); sys.exit(1)
fichiers = sorted(p for p in src.rglob("*") if p.is_file())
if not fichiers:
    print("recherche non exécutée (échec) : app/web/src vide"); sys.exit(1)
MOTIF = re.compile(r"\.admin\.|\bauth\.admin\b|\b(getUserById|updateUserById|deleteUser|listFactors|deleteFactor)\b")
def sans_commentaires(t):
    t = re.sub(r"/\*.*?\*/", " ", t, flags=re.S)
    return re.sub(r"(^|\s)//[^\n]*", r"\1", t)
trouves = []
for p in fichiers:
    code = sans_commentaires(p.read_text(errors="replace"))
    for i, ln in enumerate(code.splitlines(), 1):
        m = MOTIF.search(ln)
        if m:
            trouves.append(f"{p.relative_to(src)}:{i} « {m.group(0)} »")
if trouves:
    print(f"{len(trouves)} appel(s) d'auth-js visé(s) par GHSA-8r88-6cj9-9fh5 : " + " ; ".join(trouves)); sys.exit(1)
print(f"aucun appel à .admin., getUserById, updateUserById, deleteUser, listFactors ni deleteFactor dans {len(fichiers)} fichier(s) de app/web/src")
PY
