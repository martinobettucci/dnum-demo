"""Lecture des secrets de la pile (lecture seule). Ne jamais afficher les valeurs retournées."""
import pathlib


def load(pile="dev"):
    f = pathlib.Path(f"/workspace/.devenv/secrets/{pile}.env")
    if not f.is_file():
        return {}
    out = {}
    for ln in f.read_text(errors="replace").splitlines():
        if "=" in ln and not ln.lstrip().startswith("#"):
            k, v = ln.split("=", 1)
            out[k.strip()] = v.strip().strip("\"'")
    return out
