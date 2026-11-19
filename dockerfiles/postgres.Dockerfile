FROM pgvector/pgvector:pg16
COPY dockerfiles/postgres/backup-once.sh /usr/local/bin/agro-backup-once
COPY dockerfiles/postgres/start-with-backup.sh /usr/local/bin/agro-start
COPY dockerfiles/postgres/evidence.sh /usr/local/bin/agro-evidence
COPY dockerfiles/postgres/restore.sh /docker-entrypoint-initdb.d/10-restore.sh
RUN apt-get update && apt-get install -y --no-install-recommends util-linux \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i 's/\r$//' /usr/local/bin/agro-* /docker-entrypoint-initdb.d/10-restore.sh \
    && chmod +x /usr/local/bin/agro-* /docker-entrypoint-initdb.d/10-restore.sh
ENTRYPOINT ["/usr/local/bin/agro-start"]
