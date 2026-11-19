#!/usr/bin/env bash
set -euo pipefail
docker-entrypoint.sh postgres &
db_pid=$!
backup_pid=''
shutdown() {
  if [ -n "$backup_pid" ]; then kill "$backup_pid" 2>/dev/null || true; fi
  /usr/local/bin/agro-backup-once || echo 'Não foi possível fazer snapshot final.' >&2
  kill -TERM "$db_pid" 2>/dev/null || true
  wait "$db_pid" || true
  exit 0
}
trap shutdown TERM INT
(
  until pg_isready -h 127.0.0.1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; do sleep 3; done
  while kill -0 "$db_pid" 2>/dev/null; do
    /usr/local/bin/agro-backup-once || echo 'Snapshot periódico falhou; verificar Azure Files.' >&2
    sleep "${BACKUP_INTERVAL_SECONDS:-60}"
  done
) &
backup_pid=$!
set +e
wait "$db_pid"
result=$?
kill "$backup_pid" 2>/dev/null || true
exit "$result"
