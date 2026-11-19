#!/usr/bin/env bash
set -euo pipefail
# Serializa snapshot periódico, snapshot manual e encerramento do processo.
exec 9>/tmp/agro-backup.lock
flock -w 60 9
export PGPASSWORD="$POSTGRES_PASSWORD"
pg_isready -h 127.0.0.1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null
mkdir -p /backup
tmp="/backup/.snapshot-$$.sql"
trap 'rm -f "$tmp"' EXIT
pg_dump -h 127.0.0.1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists --no-owner --no-privileges --file "$tmp"
test -s "$tmp"
tail -n 10 "$tmp" | grep -Fq -- 'PostgreSQL database dump complete'
# A versão anterior continua disponível se a escrita do novo dump falhar.
if [ -s /backup/latest.sql ]; then cp /backup/latest.sql /backup/previous.sql; fi
mv "$tmp" /backup/latest.sql
date -u +'%Y-%m-%dT%H:%M:%SZ' > /backup/latest.utc
echo 'Snapshot PostgreSQL salvo no volume de backup.'
