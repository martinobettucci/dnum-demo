#!/usr/bin/env bash
# POLICY: STACK-ports
# REF: SPEC-001.3 | ADR-001 | CA-002-1 | CA-002-3
# QUAND: always
# Dans stack/*.yml, seul le service app publie des ports (clé ports:) ; chaque publication a une
# adresse hôte explicite, 127.0.0.1 ou ${APP_LAN_IP:-<ip>} / 10.77.0.25, jamais 0.0.0.0, :: ni vide.
# stack/compose.yml publie app à la fois sur 127.0.0.1 et sur ${APP_LAN_IP:-10.77.0.25}.
python3 -I - <<'PY'
import pathlib, re, sys
sys.path.append("/workspace/policies/lib")
import compose
SHORT = re.compile(r"^(?P<ip>\$\{[^}]*\}|\[[^\]]*\]|[0-9.]+):(?P<hote>\$\{[^}]*\}|[0-9\-]+):(?P<ct>[0-9\-]+)(/\w+)?$")
def ip_ok(ip):
    if ip in ("127.0.0.1", "10.77.0.25"):
        return True
    m = re.fullmatch(r"\$\{APP_LAN_IP:?-([0-9.]+)\}", ip)
    return bool(m) and m.group(1) not in ("0.0.0.0", "")
bad, vus = [], {}
fs = compose.fichiers()
if not fs:
    print("aucun fichier stack/*.yml"); sys.exit(1)
for f in fs:
    for nom, svc in compose.load(f).items():
        if "ports" not in svc:
            continue
        if nom != "app":
            bad.append(f"{f.name} : {nom} publie des ports")
            continue
        brut = " ".join(svc["ports"])
        if re.search(r"\b(published|target)\s*:", brut):  # syntaxe longue
            ips = re.findall(r"host_ip\s*:\s*[\"']?([^\"'\s,}]+)", brut)
            if len(ips) < len(re.findall(r"\btarget\s*:", brut)) or not all(ip_ok(i) for i in ips):
                bad.append(f"{f.name} : app ports (syntaxe longue) sans host_ip admis")
            vus.setdefault(f.name, set()).update(ips)
            continue
        for p in compose.items(svc, "ports"):
            m = SHORT.match(p)
            if not m:
                bad.append(f"{f.name} : app « {p} » sans adresse hôte explicite (=0.0.0.0)")
            elif not ip_ok(m.group("ip")):
                bad.append(f"{f.name} : app « {p} » adresse non admise")
            else:
                vus.setdefault(f.name, set()).add(m.group("ip"))
ips = vus.get("compose.yml", set())
if "127.0.0.1" not in ips:
    bad.append("compose.yml : app non publié sur 127.0.0.1")
if not any(i.startswith("${APP_LAN_IP") or i == "10.77.0.25" for i in ips):
    bad.append("compose.yml : app non publié sur ${APP_LAN_IP:-10.77.0.25}")
if bad:
    print("ports non conformes : " + " ; ".join(bad)); sys.exit(1)
print("seul app publie des ports, sur " + ", ".join(sorted(ips)) + " (jamais 0.0.0.0)")
PY
