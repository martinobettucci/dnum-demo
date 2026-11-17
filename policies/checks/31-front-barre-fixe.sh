#!/usr/bin/env bash
# POLICY: FRONT-barre-fixe
# REF: SPEC-005.6 | CA-002-37 (proposé, tour 3)
# QUAND: always
# Statique sur app/web/style.css (commentaires CSS retirés) :
#  - .entete : position: sticky ou fixed, avec top: 0 ;
#  - html : scroll-padding-top non nul (un élément reçu par Tab reste visible sous la barre) ;
#  - .lien-evitement:focus : z-index strictement supérieur à celui de .entete (le lien reste au-dessus).
# La vérification de rendu (défilement, 1280×800) reste [C].
python3 -I - <<'PY'
import pathlib, re, sys
f = pathlib.Path("/workspace/app/web/style.css")
if not f.is_file():
    print("app/web/style.css absent : contrôle impossible (échec)"); sys.exit(1)
css = re.sub(r"/\*.*?\*/", " ", f.read_text(errors="replace"), flags=re.S)

def declarations(selecteur):
    """Déclarations fusionnées (dans l'ordre du fichier) des règles dont la liste de sélecteurs contient selecteur."""
    out = {}
    for sels, corps in re.findall(r"([^{}]+)\{([^{}]*)\}", css):
        if selecteur in [s.strip() for s in sels.split(",")]:
            for k, v in re.findall(r"([a-z-]+)\s*:\s*([^;]+)", corps):
                out[k.strip().lower()] = v.strip().lower()
    return out

bad = []
entete = declarations(".entete")
if not entete:
    bad.append("règle .entete absente")
else:
    if entete.get("position") not in ("sticky", "fixed"):
        bad.append(f".entete position={entete.get('position', 'absent')} (attendu sticky ou fixed)")
    if entete.get("top") not in ("0", "0px"):
        bad.append(f".entete top={entete.get('top', 'absent')} (attendu 0)")
html = declarations("html")
spt = html.get("scroll-padding-top", "0")
if re.fullmatch(r"0(px|rem|em)?", spt) or spt == "":
    bad.append(f"html scroll-padding-top={spt} (attendu non nul)")
focus = declarations(".lien-evitement:focus")
if not focus:
    bad.append("règle .lien-evitement:focus absente")
else:
    try:
        z_focus = int(focus.get("z-index", "x"))
    except ValueError:
        z_focus = None
    try:
        z_barre = int(entete.get("z-index", "0"))
    except ValueError:
        z_barre = None
    if z_focus is None or z_barre is None or z_focus <= z_barre:
        bad.append(f".lien-evitement:focus z-index={focus.get('z-index', 'absent')} n'est pas supérieur à celui de .entete")
if bad:
    print("barre fixe non conforme : " + " ; ".join(bad)); sys.exit(1)
print(f"barre .entete {entete['position']} en haut (top: 0), scroll-padding-top {spt} sur html, lien d'évitement au-dessus (z-index {z_focus} > {z_barre})")
PY
