import json, sys, urllib.request, urllib.error
it, action, args = sys.argv[1], sys.argv[2], sys.argv[3:]
req = urllib.request.Request("http://127.0.0.1:9000", json.dumps(
    {"iter": it, "action": action, "args": args}).encode(), {"Content-Type": "application/json"})
try: print(urllib.request.urlopen(req).read().decode())
except urllib.error.HTTPError as e: print(e.read().decode()); sys.exit(1)
