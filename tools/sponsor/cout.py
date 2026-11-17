#!/usr/bin/env python3
"""Agrège l'usage Claude Code (transcripts JSONL) depuis le début de l'itération et le valorise."""
import json, sys, pathlib, datetime, collections

projects, iter_dir, tarifs_path = map(pathlib.Path, sys.argv[1:4])
tarifs = json.loads(tarifs_path.read_text())
start = datetime.datetime.fromisoformat((iter_dir / ".started").read_text().strip())
end_f = iter_dir / ".ended"
end = datetime.datetime.fromisoformat(end_f.read_text().strip()) if end_f.exists() else None

msgs = {}
for f in projects.rglob("*.jsonl"):
    for line in f.open(errors="ignore"):
        try: e = json.loads(line)
        except ValueError: continue
        msg = e.get("message") or {}
        u, ts = msg.get("usage"), e.get("timestamp")
        if not u or not ts: continue
        t = datetime.datetime.fromisoformat(ts.replace("Z", "+00:00"))
        if t < start or (end and t > end): continue
        msgs[msg.get("id") or e.get("uuid")] = (msg.get("model", "inconnu"), u, "subagents" in f.parts)

agg = collections.defaultdict(lambda: collections.Counter())
for model, u, sub in msgs.values():
    c = agg[model]
    c["requetes"] += 1; c["sous_agents"] += sub
    c["input"] += u.get("input_tokens", 0); c["output"] += u.get("output_tokens", 0)
    c["cache_write"] += u.get("cache_creation_input_tokens", 0); c["cache_read"] += u.get("cache_read_input_tokens", 0)

rows, total = [], 0.0
for model, c in sorted(agg.items()):
    t = next((v for k, v in tarifs.items() if not k.startswith("_") and model.startswith(k)), None)
    cost = sum(c[k] * t[k] for k in ("input", "output", "cache_write", "cache_read")) / 1e6 if t else None
    total += cost or 0
    rows.append({"modele": model, **c, "cout_usd": None if cost is None else round(cost, 4)})

now = end or datetime.datetime.now(datetime.timezone.utc)
rep = {"iteration": iter_dir.name, "debut": start.isoformat(), "fin": end.isoformat() if end else None,
       "duree_min": round((now - start).total_seconds() / 60, 1), "par_modele": rows,
       "cout_total_usd": round(total, 4), "tarifs": tarifs.get("_source")}
(iter_dir / "cout.json").write_text(json.dumps(rep, ensure_ascii=False, indent=2))
print(json.dumps(rep, ensure_ascii=False, indent=2))
