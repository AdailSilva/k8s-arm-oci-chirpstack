#!/bin/bash
# =====================================================================
#  Backup do banco do ChirpStack Manager para ESTA máquina, direto do pod
#  do PostgreSQL (não depende da API estar no ar).
#
#  Uso: ./03.back-up_api-chirpstack-manager-backend_script.sh [pasta_destino]
#  Gera chirpstack-manager_database_AAAA-MM-DD_HH-MM-SS.backup (pg_dump
#  formato custom), o mesmo formato que a tela Backup & Restauração aceita.
# =====================================================================
set -euo pipefail

NS=chirpstack-manager
POD=chirpstack-manager-postgres-0
DESTINO=${1:-~/Backups/chirpstack-manager}
ARQ="$DESTINO/chirpstack-manager_database_$(date +%Y-%m-%d_%H-%M-%S).backup"

mkdir -p "$DESTINO"
echo "Gerando backup de $NS/$POD em $ARQ ..."

# As credenciais vêm das variáveis do próprio container (POSTGRES_USER / POSTGRES_DB).
kubectl -n "$NS" exec "$POD" -- sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=custom --compress=6' > "$ARQ.parcial"

if [ ! -s "$ARQ.parcial" ] || [ "$(head -c 5 "$ARQ.parcial")" != "PGDMP" ]; then
    rm -f "$ARQ.parcial"
    echo "ERRO: o arquivo gerado não é um dump válido."
    exit 1
fi
mv "$ARQ.parcial" "$ARQ"
echo "Backup concluído: $ARQ ($(du -h "$ARQ" | cut -f1))"
