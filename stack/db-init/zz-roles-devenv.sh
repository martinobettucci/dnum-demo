#!/bin/bash
# Mots de passe des rôles de service, depuis un volume vide (SPEC-004.14, ADR-006 §3).
# L'image supabase/postgres ne fixe que le mot de passe de supabase_admin (depuis POSTGRES_PASSWORD) ;
# authenticator (PostgREST) et supabase_auth_admin (GoTrue) sont créés sans mot de passe.
# Monté en fichier unique dans /docker-entrypoint-initdb.d : exécuté une seule fois, après les scripts
# de l'image (ordre lexical : « zz » vient en dernier). Ne contient aucune valeur secrète : il lit
# POSTGRES_PASSWORD depuis l'environnement du conteneur.
set -euo pipefail
psql -v ON_ERROR_STOP=1 --no-password --no-psqlrc -U supabase_admin -d postgres \
  -v pw="${POSTGRES_PASSWORD:?POSTGRES_PASSWORD absent}" <<'SQL'
ALTER ROLE authenticator WITH PASSWORD :'pw';
ALTER ROLE supabase_auth_admin WITH PASSWORD :'pw';
SQL
