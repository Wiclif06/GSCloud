#!/usr/bin/env bash
set -euo pipefail
for id in "$@"; do [[ "$id" =~ ^[0-9]+$ ]] || { echo 'IDs inválidos'; exit 2; }; done
farm="${1:-0}"; crop="${2:-0}"; sensor="${3:-0}"; activity="${4:-0}"
export PGPASSWORD="$POSTGRES_PASSWORD"
psql -h 127.0.0.1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -P pager=off -e <<SQL
SELECT current_database() AS banco, inet_server_addr() AS servidor, now() AS instante;
SELECT id,name,city,state,total_area,area_unit FROM farms WHERE id=$farm;
SELECT id,farm_id,name,crop_type,area_size,area_unit FROM crop_areas WHERE id=$crop;
SELECT id,crop_area_id,name,device_code,sensor_type,status FROM sensors WHERE id=$sensor;
SELECT id,crop_area_id,type,description,quantity,unit FROM field_activities WHERE id=$activity;
SQL
