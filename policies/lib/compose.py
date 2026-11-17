"""Analyse minimale (par indentation) des fichiers compose, sans dépendance (pas de PyYAML).

Utilisé par les policies : `sys.path.append("/workspace/policies/lib"); import compose`
(append, jamais insert(0) : ne pas masquer la bibliothèque standard).
Ne lit que la section `services:` ; suffisant pour les clés image / build / ports / profiles.
"""
import pathlib
import re

TAG_EXACT = re.compile(r"^(v?\d+\.\d+\.\d+[0-9A-Za-z.\-_]*|.*@sha256:[0-9a-f]{64})$")


def _sans_commentaire(raw):
    if raw.lstrip().startswith("#"):
        return ""
    return re.sub(r"\s+#.*$", "", raw).rstrip()


def load(path):
    """Retourne {service: {cle: [lignes]}} ; la 1re ligne est la valeur en ligne (éventuelle)."""
    svcs, in_services, svc_ind, key_ind, cur, curkey = {}, False, None, None, None, None
    for raw in pathlib.Path(path).read_text().splitlines():
        line = _sans_commentaire(raw)
        if not line.strip():
            continue
        ind = len(line) - len(line.lstrip())
        txt = line.strip()
        if ind == 0:
            in_services = txt.startswith("services:")
            cur = svc_ind = None
            continue
        if not in_services:
            continue
        if svc_ind is None:
            svc_ind = ind
        if ind == svc_ind:
            cur = txt.split(":", 1)[0].strip().strip("\"'")
            svcs[cur], key_ind, curkey = {}, None, None
            continue
        if ind < svc_ind or cur is None:
            continue
        if key_ind is None:
            key_ind = ind
        if ind == key_ind and not txt.startswith("-"):
            k, _, v = txt.partition(":")
            curkey = k.strip()
            svcs[cur][curkey] = [v.strip()] if v.strip() else []
        elif curkey:
            svcs[cur][curkey].append(txt)
    return svcs


def unquote(s):
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in "\"'":
        return s[1:-1]
    return s


def scalar(svc, key):
    v = svc.get(key)
    return unquote(v[0]) if v else None


def items(svc, key):
    """Éléments d'une liste courte (`[a, b]` ou `- a`). Les éléments dict restent bruts."""
    out = []
    for ln in svc.get(key, []):
        if ln.startswith("["):
            body = ln.strip("[]")
            out += [unquote(m.group(0)) for m in re.finditer(r'"[^"]*"|\'[^\']*\'|[^,\s][^,]*', body)]
        elif ln.startswith("-"):
            out.append(unquote(ln[1:]))
        else:
            out.append(ln)
    return [o.strip() for o in out if o.strip()]


def image_epinglee(ref):
    """Vrai si la référence d'image porte un tag exact (x.y.z…) ou un digest."""
    if "$" in ref:
        return False
    if "@" in ref:
        return bool(TAG_EXACT.match(ref))
    tag = ref.rsplit(":", 1)[1] if ":" in ref else ""
    if "/" in tag:  # le « : » était un port de registre, pas un tag
        return False
    return tag != "latest" and bool(TAG_EXACT.match(tag))


def fichiers(stack="/workspace/stack"):
    return sorted(p for p in pathlib.Path(stack).glob("*.yml")) + sorted(pathlib.Path(stack).glob("*.yaml"))
