#!/usr/bin/env python3
"""Exécute policies/checks/*.sh et écrit iterations/NNN/policies/results.json."""
import json, os, re, subprocess, sys, datetime, pathlib, urllib.request

ws = pathlib.Path("/workspace")
it = (ws / "iterations/CURRENT").read_text().strip()
out = ws / "iterations" / it / "policies"
out.mkdir(parents=True, exist_ok=True)

def deployed():
    try:
        urllib.request.urlopen(os.environ["APP_URL"], timeout=2); return True
    except Exception:
        return False

is_up = deployed()
results = []
for chk in sorted((ws / "policies/checks").glob("*.sh")):
    head = chk.read_text().splitlines()[:10]
    meta = {k: (re.search(rf"^# {k}:\s*(.*)$", "\n".join(head), re.M) or [None, ""])[1].strip()
            for k in ("POLICY", "REF", "QUAND")}
    if meta["QUAND"] == "deployed" and not is_up:
        results.append({**meta, "file": chk.name, "status": "non_applicable", "rc": 77,
                        "output": "pile non démarrée"}); continue
    p = subprocess.run(["bash", str(chk)], capture_output=True, text=True, timeout=120)
    status = {0: "respectee", 77: "non_applicable"}.get(p.returncode, "violee")
    results.append({**meta, "file": chk.name, "status": status, "rc": p.returncode,
                    "output": (p.stdout + p.stderr).strip()[-2000:]})

report = {"iteration": it, "date": datetime.datetime.now().isoformat(timespec="seconds"),
          "pile_demarree": is_up, "results": results,
          "synthese": {s: sum(r["status"] == s for r in results)
                       for s in ("respectee", "violee", "non_applicable")}}
(out / "results.json").write_text(json.dumps(report, ensure_ascii=False, indent=2))
for r in results:
    print(f"[{r['status']:>14}] {r['POLICY'] or r['file']}  ({r['REF']})  {r['output'].splitlines()[-1] if r['output'] else ''}")
print(f"→ iterations/{it}/policies/results.json  {report['synthese']}")
sys.exit(1 if report["synthese"]["violee"] else 0)
