#!/usr/bin/env bash
# POLICY: FRONT-messages-tour3
# REF: SPEC-005.7 | SPEC-005.33 | SPEC-005.40 | SPEC-005.60 | SPEC-005.62 | SPEC-005.63 | CA-002-27 | CA-002-28 | CA-002-34 | CA-002-38 | CA-002-39
# QUAND: always
# Statique sur app/web/src/app.js (commentaires JS retirés avant contrôle) :
#  - textes exacts M-1 à M-6 (SPEC-005, « Messages exacts (tour 3) ») ; {nom}, {titre}, {terme} vérifiés par gabarit
#    (une expression ${...} à leur place) ;
#  - libellés « Confirmer la désactivation », « Annuler », « Rechercher dans les comptes en attente »,
#    « Rechercher dans les comptes actifs » ;
#  - absence de l'ancien texte « Proposition envoyée. » ;
#  - absence de confirm(, alert( (SPEC-005.63 : pas de fenêtre native) ;
#  - absence de innerHTML, outerHTML, insertAdjacentHTML (SPEC-005.7 : texte inséré en textContent).
python3 -I - <<'PY'
import pathlib, re, sys
f = pathlib.Path("/workspace/app/web/src/app.js")
if not f.is_file():
    print("app/web/src/app.js absent : contrôle impossible (échec)"); sys.exit(1)
def sans_commentaires(t):
    t = re.sub(r"/\*.*?\*/", " ", t, flags=re.S)
    return re.sub(r"(^|\s)//[^\n]*", r"\1", t)
code = sans_commentaires(f.read_text(errors="replace"))

def gabarit(texte):
    parties = re.split(r"\{(?:nom|titre|terme)\}", texte)
    return re.compile(r"\$\{[^{}]*\}".join(re.escape(p) for p in parties))
MESSAGES = {
    "M-1": "Proposition envoyée à {nom} pour la tâche « {titre} ».",
    "M-2": "Demande d'aide envoyée à {nom} pour la tâche « {titre} ».",
    "M-3": "Désactiver le compte de {nom} ? Cette personne ne verra plus les données de l'équipe.",
    "M-4": "Le compte de {nom} est désactivé.",
    "M-5": "Aucun compte en attente ne correspond à « {terme} ».",
    "M-6": "Aucun compte actif ne correspond à « {terme} ».",
}
LIBELLES = ["Confirmer la désactivation", "Annuler",
            "Rechercher dans les comptes en attente", "Rechercher dans les comptes actifs"]
bad = []
for cle, texte in MESSAGES.items():
    if not gabarit(texte).search(code):
        bad.append(f"{cle} absent ou différent")
for lib in LIBELLES:
    if lib not in code:
        bad.append(f"libellé absent : « {lib} »")
if "Proposition envoyée." in code:
    bad.append("ancien texte « Proposition envoyée. » encore présent")
if re.search(r"\bconfirm\s*\(", code):
    bad.append("confirm( présent (SPEC-005.63)")
if re.search(r"\balert\s*\(", code):
    bad.append("alert( présent")
m = re.search(r"innerHTML|outerHTML|insertAdjacentHTML", code)
if m:
    bad.append(f"{m.group(0)} présent (texte inséré en textContent, SPEC-005.7)")
if bad:
    print("textes d'entraide/administration non conformes : " + " ; ".join(bad)); sys.exit(1)
print("M-1 à M-6 exacts (gabarits), 4 libellés présents, ancien texte absent, aucun confirm( ni alert(, aucun innerHTML")
PY
