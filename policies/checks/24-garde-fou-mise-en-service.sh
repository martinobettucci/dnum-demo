#!/usr/bin/env bash
# POLICY: GARDE-FOU-mise-en-service
# REF: SPEC-004.6 | ADR-004 | CLAUDE.md §5
# QUAND: always
# tools/guards/guard.py, nourri d'entrées JSON simulées (copie isolée dans /tmp, aucun effet sur
# le dépôt) : ./dev deploy|teardown|reset|backup|restore (avec ou sans pile) → refus (exit 2) pour
# developpeur, action, testeur, policy, principal ; autorisé (exit 0) pour responsable-applicatif ;
# ./dev policies et ./dev test restent autorisés au developpeur ; observation ne peut pas écrire.
G=/workspace/tools/guards/guard.py
[ -f "$G" ] || { echo "tools/guards/guard.py absent"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/tools/guards" && cp "$G" "$T/tools/guards/guard.py"
run() { # agent outil json_input → code retour du garde-fou
  printf '{"agent_type":"%s","session_id":"policy-sim","tool_name":"%s","tool_input":%s}' "$1" "$2" "$3" \
    | env -u DEVENV_GUARD_DEBUG python3 -I "$T/tools/guards/guard.py" >/dev/null 2>&1; echo $?
}
bash_in() { printf '{"command":"%s"}' "$1"; }
bad=(); n=0
RESERVEES=("./dev deploy" "./dev teardown" "./dev reset" "./dev backup" "./dev restore"
           "./dev deploy service" "./dev teardown service" "./dev reset service --confirmer-destruction"
           "./dev backup service" "./dev restore service .devenv/backups/service/x.dump"
           "cd /home/spark-docker/devenv && ./dev backup dev")
for cmd in "${RESERVEES[@]}"; do
  for ag in developpeur action testeur policy principal; do
    n=$((n+1)); c=$(run "$ag" Bash "$(bash_in "$cmd")"); [ "$c" = 2 ] || bad+=("$ag « $cmd »→$c")
  done
  n=$((n+1)); c=$(run responsable-applicatif Bash "$(bash_in "$cmd")"); [ "$c" = 0 ] || bad+=("responsable-applicatif « $cmd »→$c")
done
for cmd in "./dev policies" "./dev test" "./dev status"; do
  n=$((n+1)); c=$(run developpeur Bash "$(bash_in "$cmd")"); [ "$c" = 0 ] || bad+=("developpeur « $cmd »→$c")
done
n=$((n+1)); c=$(run observation Write '{"file_path":"/tmp/x","content":"x"}'); [ "$c" = 2 ] || bad+=("observation Write→$c")
if [ ${#bad[@]} -eq 0 ]; then
  echo "garde-fou conforme sur $n cas simulés (deploy/teardown/reset/backup/restore réservés au responsable-applicatif)"
else
  echo "garde-fou non conforme (${#bad[@]}/$n cas) : ${bad[*]}"; exit 1
fi
