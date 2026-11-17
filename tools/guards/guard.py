#!/usr/bin/env python3
"""Garde-fou PreToolUse : fait respecter les rôles de CLAUDE.md.

- Seul `responsable-applicatif` met en service / arrête / détruit la pile.
- `client` : uniquement tools/client/client.sh, et ne lit que ses captures.
- `observation`, `reaction` : lecture seule.
Exit 2 = refus (le message sur stderr est renvoyé à l'agent).
"""
import json, os, re, sys, datetime, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
data = json.load(sys.stdin)
agent = data.get("agent_type") or "principal"
tool = data.get("tool_name", "")
inp = data.get("tool_input", {}) or {}

if os.environ.get("DEVENV_GUARD_DEBUG") or (ROOT / ".devenv/guard-debug").exists():
    log = ROOT / ".devenv/guard.log"
    log.parent.mkdir(exist_ok=True)
    with log.open("a") as f:
        f.write(json.dumps({"t": datetime.datetime.now().isoformat(), "agent": agent,
                            "keys": sorted(data.keys()), "tool": tool}) + "\n")

def deny(msg):
    print(f"[garde-fou devenv] Refusé pour l'agent '{agent}' : {msg}", file=sys.stderr)
    sys.exit(2)

# --- Un seul chef de projet (verrou .devenv/chef-de-projet.lock) ---------------
def session_alive(sid):
    for d in pathlib.Path("/proc").glob("[0-9]*"):
        try:
            if sid.encode() in (d / "cmdline").read_bytes(): return True
        except OSError: pass
    return False

if agent == "chef-de-projet":
    lock = ROOT / ".devenv/chef-de-projet.lock"
    sid = data.get("session_id", "")
    holder = json.loads(lock.read_text()) if lock.exists() else None
    if holder and holder.get("session_id") != sid and session_alive(holder["session_id"]):
        deny(f"un seul chef de projet : la session « {holder.get('nom','?')} » ({holder['session_id']}) "
             "tient déjà ce rôle. Relancez cette session avec un autre rôle : claude --agent <role>.")
    if not holder or holder.get("session_id") != sid:
        lock.parent.mkdir(exist_ok=True)
        lock.write_text(json.dumps({"session_id": sid, "nom": "session " + sid[:12],
                                    "depuis": datetime.datetime.now().isoformat(timespec="seconds")}))

READ_ONLY = {"observation", "reaction"}
WRITE_TOOLS = {"Write", "Edit", "NotebookEdit", "MultiEdit"}
STACK_RE = re.compile(
    r"(\./dev\s+(deploy|teardown|reset)\b"
    r"|tools/ops/(deploy|teardown|reset)\.sh"
    r"|docker(-compose|\s+compose)\b[^\n]*\b(up|down|start|stop|restart|kill|rm)\b"
    r"|docker\s+(run|start|stop|restart|kill|rm|volume\s+rm|system\s+prune|container\s+(rm|stop|kill)))")

if agent in READ_ONLY and (tool in WRITE_TOOLS or tool == "Bash"):
    deny("agent en lecture seule (boucle AOPR).")

if tool == "Bash":
    cmd = inp.get("command", "")
    if agent == "client":
        if not re.fullmatch(r"\s*(\./)?tools/client/client\.sh(\s+[^;&|`$<>\n]*)?\s*", cmd):
            deny("le client n'utilise que le clavier et la souris : tools/client/client.sh <action>.")
    elif STACK_RE.search(cmd) and agent != "responsable-applicatif":
        deny("la mise en service (démarrer/arrêter/détruire la pile) est réservée au "
             "responsable-applicatif. Adressez la demande au chef de projet.")

if agent == "client" and tool in {"Read", "Glob", "Grep"} | WRITE_TOOLS:
    p = inp.get("file_path") or inp.get("path") or ""
    if tool in WRITE_TOOLS or not re.search(r"(^|/)iterations/\d{3}/client/[^/]+\.png$", p):
        deny("le client ne voit que ses captures d'écran (iterations/NNN/client/*.png).")

sys.exit(0)
