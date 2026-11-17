# POLICY: APP-repond
# REF: ENV (mise en service)
# QUAND: deployed
code=$(curl -s -o /dev/null -w '%{http_code}' "$APP_URL/")
[ "$code" = 200 ] && echo "GET / → 200" || { echo "GET / → $code"; exit 1; }
