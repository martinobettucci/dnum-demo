#!/usr/bin/env bash
# POLICY: DB-rls-privileges-statique
# REF: SPEC-002.1 | SPEC-002 §5-6 | ADR-005 | CA-002-11
# QUAND: always
# Analyse statique des migrations (le runner n'accède pas à db) :
#  - chaque table créée dans public a « enable row level security » ET « force row level security » ;
#  - aucun GRANT de privilège table/fonction (select, insert, update, delete, all, execute…) à anon ;
#  - chaque fonction de public voit son EXECUTE révoqué de PUBLIC et de anon (par fonction ou
#    « on all functions in schema public »), car Postgres et l'image Supabase l'accordent par défaut.
python3 -I - <<'PY'
import pathlib, re, sys
d = pathlib.Path("/workspace/app/db/migrations")
fs = sorted(d.glob("*.sql")) if d.is_dir() else []
if not fs:
    print("aucune migration app/db/migrations/*.sql à analyser"); sys.exit(1)
sql = "\n".join(re.sub(r"--[^\n]*", "", p.read_text(errors="replace")) for p in fs).lower()
# Retire les corps de fonctions ($$ … $$ / $tag$ … $tag$) pour n'analyser que le DDL.
ddl = re.sub(r"\$(\w*)\$.*?\$\1\$", " ", sql, flags=re.S)
stmts = [s.strip() for s in ddl.split(";")]
bad = []
def objets_public(kind):
    pat = rf"create\s+{kind}\s+(?:if\s+not\s+exists\s+)?(?:\"?(\w+)\"?\.)?\"?(\w+)\"?\s*\("
    return sorted({n for sch, n in re.findall(pat, ddl) if sch in ("", "public")})
tables = objets_public("table")
for t in tables:
    tre = rf"alter\s+table\s+(?:only\s+)?(?:public\.)?\"?{t}\"?\s+"
    if not re.search(tre + r"enable\s+row\s+level\s+security", ddl):
        bad.append(f"{t} : RLS non activée")
    if not re.search(tre + r"force\s+row\s+level\s+security", ddl):
        bad.append(f"{t} : RLS non forcée")
for s in stmts:
    g = re.search(r"(?:^|\s)grant\s+(.*?)\s+on\s+.*\bto\b(.*)$", s, re.S)
    if (s.startswith("grant") or s.startswith("alter default privileges")) and g and \
       re.search(r"\banon\b", g.group(2)) and \
       re.search(r"\b(select|insert|update|delete|truncate|references|trigger|all|execute)\b", g.group(1)):
        bad.append("grant à anon : " + re.sub(r"\s+", " ", s)[:120])
funcs = objets_public(r"(?:or\s+replace\s+)?function")
revokes = [(i, s) for i, s in enumerate(stmts)
           if re.match(r"(revoke|alter\s+default\s+privileges\b.*\brevoke)\b", s, re.S)
           and re.search(r"\b(execute|all)\b", s)]
def revoque(f, role):
    """Révocation effective : explicite APRÈS la (dernière) création, ou par défaut AVANT la première."""
    cre = [i for i, s in enumerate(stmts)
           if re.search(rf"create\s+(or\s+replace\s+)?function\s+(public\.)?\"?{f}\"?\s*\(", s)] or [0]
    for i, s in revokes:
        if not re.search(rf"\bfrom\b[^;]*\b{role}\b", s):
            continue
        if s.startswith("alter") and re.search(r"\bon\s+functions\b", s) and i < min(cre):
            return True
        if re.search(rf"on\s+(function\s+(public\.)?\"?{f}\"?\b|all\s+functions\s+in\s+schema\s+public\b)", s) \
           and i > max(cre):
            return True
    return False
for f in funcs:
    for role in ("public", "anon"):
        if not revoque(f, role):
            bad.append(f"fonction public.{f} : EXECUTE non révoqué de {role}")
if bad:
    print(f"{len(bad)} écart(s) RLS/privilèges : " + " ; ".join(bad)); sys.exit(1)
print(f"{len(tables)} table(s) public à RLS activée et forcée, aucun grant à anon, EXECUTE révoqué de PUBLIC/anon sur {len(funcs)} fonction(s) public")
PY
