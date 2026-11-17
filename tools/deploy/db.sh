#!/usr/bin/env bash
# Opérations base de données exécutées par ./dev dans le service one-shot `migrate`
# (image supabase/postgres épinglée : psql, pg_dump, pg_restore). Ne s'exécute pas sur l'hôte.
#
#   db.sh migrate        applique app/db/migrations/NNN_<sujet>.sql (montées sur $MIGRATIONS_DIR)
#                        dans l'ordre, une transaction par fichier, journal private.schema_migrations,
#                        puis NOTIFY pgrst, 'reload schema'. Idempotent (SPEC-001.13).
#   db.sh level          affiche la dernière migration appliquée (vide si aucune).
#   db.sh promote-admin  profil de $ADMIN_EMAIL → role='admin', is_active=true (seed, SPEC-003.5).
#   db.sh dump           pg_dump -Fc données seules (auth + public) sur la sortie standard.
#   db.sh restore        vide public + auth (hors auth.schema_migrations) puis restaure le dump lu
#                        sur l'entrée standard (--disable-triggers), en une seule transaction.
#
# Connexion : variables libpq standard. Défauts : PGHOST=db PGUSER=supabase_admin PGDATABASE=postgres,
# PGPASSWORD=$POSTGRES_PASSWORD (fichier de secrets de la pile, injecté par compose).
# N'écrit jamais de secret sur la sortie.
set -euo pipefail
export PGHOST="${PGHOST:-db}" PGUSER="${PGUSER:-supabase_admin}" PGDATABASE="${PGDATABASE:-postgres}"
export PGPASSWORD="${PGPASSWORD:-${POSTGRES_PASSWORD:?POSTGRES_PASSWORD absent}}"
DIR="${MIGRATIONS_DIR:-/migrations}"
PSQL=(psql -X -v ON_ERROR_STOP=1 -q)

attendre() {
  for _ in $(seq 1 60); do pg_isready -q && return 0; sleep 1; done
  echo "db.sh : base injoignable ($PGHOST)" >&2; exit 1
}

level() {
  "${PSQL[@]}" -tA -c "select case when to_regclass('private.schema_migrations') is null then ''
                       else (select coalesce(max(version),'') from private.schema_migrations) end"
}

case "${1:-}" in
  migrate)
    attendre
    "${PSQL[@]}" <<'SQL'
create schema if not exists private;
revoke all on schema private from public;
create table if not exists private.schema_migrations (
  version    text primary key,
  name       text not null,
  checksum   text not null,
  applied_at timestamptz not null default now()
);
SQL
    shopt -s nullglob
    files=("$DIR"/[0-9][0-9][0-9]_*.sql)
    [[ ${#files[@]} -gt 0 ]] || { echo "db.sh : aucune migration dans $DIR" >&2; exit 1; }
    n=0
    for f in $(printf '%s\n' "${files[@]}" | sort); do
      base=$(basename "$f"); ver=${base%%_*}; sum=$(sha256sum "$f" | cut -d' ' -f1)
      deja=$("${PSQL[@]}" -tA -c "select checksum from private.schema_migrations where version='$ver'")
      if [[ -n $deja ]]; then
        [[ $deja == "$sum" ]] || { echo "db.sh : migration $base modifiée après application (refus ; nouvelle migration requise, ou ./dev reset en dev)" >&2; exit 1; }
        continue
      fi
      echo "migration : $base"
      "${PSQL[@]}" --single-transaction -f "$f" \
        -c "insert into private.schema_migrations(version, name, checksum) values ('$ver', '$base', '$sum')"
      n=$((n+1))
    done
    "${PSQL[@]}" -c "notify pgrst, 'reload schema'"
    echo "migrations : $n appliquée(s), niveau $(level)" ;;
  level) attendre; level ;;
  promote-admin)
    attendre
    : "${ADMIN_EMAIL:?ADMIN_EMAIL absent}"
    nb=$("${PSQL[@]}" -tA -v email="$ADMIN_EMAIL" <<'SQL' | grep -c . || true
update public.profiles p
   set role = 'admin', is_active = true, activated_at = coalesce(p.activated_at, now())
  from auth.users u
 where u.id = p.id and lower(u.email) = lower(:'email')
returning p.id;
SQL
)
    [[ $nb == 1 ]] || { echo "db.sh : profil administrateur introuvable ou multiple ($nb ligne(s))" >&2; exit 1; }
    echo "seed : profil administrateur actif (role=admin)" ;;
  dump)
    attendre
    pg_dump -Fc --data-only --schema=auth --schema=public --exclude-table-data=auth.schema_migrations ;;
  restore)
    attendre
    tables=$("${PSQL[@]}" -tA -c "select string_agg(format('%I.%I', schemaname, tablename), ', ')
      from pg_tables where schemaname = 'public' or (schemaname = 'auth' and tablename <> 'schema_migrations')")
    { echo "truncate $tables cascade;"; pg_restore --data-only --disable-triggers -f - ; } \
      | "${PSQL[@]}" --single-transaction
    echo "restauration : données auth + public restaurées" ;;
  *) echo "usage : db.sh migrate|level|promote-admin|dump|restore" >&2; exit 2 ;;
esac
