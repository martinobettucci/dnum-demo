#!/usr/bin/env bash
# POLICY: DB-migrations-versionnees
# REF: SPEC-001.13 | SPEC-002 | CA-002-1 | CA-002-33
# QUAND: always
# app/db/migrations/ contient au moins une migration ; tous les fichiers sont NNN_<sujet>.sql
# (sujet en [a-z0-9_]), numérotés sans doublon ni trou à partir de 001, non vides ;
# les tables contractuelles profiles, tasks, time_entries, help_proposals y sont créées ;
# aucune migration ne crée/modifie de table du schéma auth (seul le trigger on_auth_user_created est admis).
python3 -I - <<'PY'
import pathlib, re, sys
d = pathlib.Path("/workspace/app/db/migrations")
if not d.is_dir():
    print("app/db/migrations/ absent"); sys.exit(1)
fs = sorted(p for p in d.iterdir() if p.is_file() and not p.name.startswith(".")
            and not p.name.lower().startswith("readme"))
if not fs:
    print("app/db/migrations/ vide"); sys.exit(1)
bad, nums = [], []
for p in fs:
    m = re.fullmatch(r"(\d{3})_[a-z0-9_]+\.sql", p.name)
    if not m:
        bad.append(f"nom non conforme : {p.name}")
        continue
    nums.append(int(m.group(1)))
    if not p.read_text(errors="replace").strip():
        bad.append(f"migration vide : {p.name}")
if len(set(nums)) != len(nums):
    bad.append("numéros en doublon")
if nums and sorted(set(nums)) != list(range(1, max(nums) + 1)):
    bad.append(f"numérotation non continue depuis 001 : {sorted(nums)}")
sql = "\n".join(re.sub(r"--[^\n]*", "", p.read_text(errors="replace")) for p in fs).lower()
for t in ("profiles", "tasks", "time_entries", "help_proposals"):
    if not re.search(rf"create\s+table\s+(if\s+not\s+exists\s+)?(public\.)?\"?{t}\"?\s*\(", sql):
        bad.append(f"table public.{t} non créée")
if re.search(r"(create|alter|drop)\s+table\s+(if\s+(not\s+)?exists\s+)?auth\.", sql):
    bad.append("une migration crée/modifie/supprime une table du schéma auth")
if bad:
    print("migrations non conformes : " + " ; ".join(bad)); sys.exit(1)
print(f"{len(fs)} migration(s) versionnée(s) 001→{max(nums):03d}, tables contractuelles créées, schéma auth intact")
PY
