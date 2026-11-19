#!/usr/bin/env bash
set -euo pipefail
if [ -s /backup/latest.sql ]; then
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --file /backup/latest.sql >/dev/null
  echo 'Snapshot do Azure Files restaurado no PostgreSQL.'
fi
