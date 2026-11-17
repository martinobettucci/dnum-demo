"""Serveur de pilotage du navigateur du client : n'expose QUE clavier, souris et capture d'écran."""
import json, os, time, pathlib
from http.server import HTTPServer, BaseHTTPRequestHandler
from playwright.sync_api import sync_playwright

APP_URL = os.environ.get("APP_URL", "http://app")
pw = sync_playwright().start()
browser = pw.chromium.launch(args=["--no-sandbox"])
page = browser.new_page(viewport={"width": 1280, "height": 800}, locale="fr-FR")
page.goto(APP_URL)  # l'application est « posée devant le client » ; ensuite clavier/souris seulement
m, k = page.mouse, page.keyboard

def act(a, args, it):
    if a == "screenshot":
        d = pathlib.Path("/iterations") / it / "client"; d.mkdir(parents=True, exist_ok=True)
        f = d / f"capture-{time.strftime('%H%M%S')}-{int(time.time()*1000)%1000:03d}.png"
        page.screenshot(path=str(f)); return f"iterations/{it}/client/{f.name}"
    if a == "move":  m.move(float(args[0]), float(args[1]), steps=5); return "ok"
    if a == "click":
        m.click(float(args[0]), float(args[1]), button=args[2] if len(args) > 2 else "left",
                click_count=int(args[3]) if len(args) > 3 else 1); return "ok"
    if a == "down":  m.down(button=args[0] if args else "left"); return "ok"
    if a == "up":    m.up(button=args[0] if args else "left"); return "ok"
    if a == "wheel": m.wheel(float(args[0]), float(args[1])); return "ok"
    if a == "type":  k.type(" ".join(args), delay=30); return "ok"
    if a == "press": k.press(args[0]); return "ok"
    if a == "wait":  time.sleep(min(int(args[0]), 10000) / 1000); return "ok"
    raise ValueError(f"action inconnue : {a}")

class H(BaseHTTPRequestHandler):
    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        try: code, msg = 200, act(body["action"], body.get("args", []), body["iter"])
        except Exception as e: code, msg = 400, f"erreur : {e}"
        self.send_response(code); self.end_headers(); self.wfile.write(msg.encode())
    def log_message(self, *a): pass

HTTPServer(("127.0.0.1", 9000), H).serve_forever()
