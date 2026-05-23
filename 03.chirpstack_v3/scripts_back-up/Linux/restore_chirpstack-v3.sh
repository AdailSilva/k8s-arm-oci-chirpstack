#!/bin/bash
# ==============================================================
#  RESTORE - chirpstack_ns/as - PostgreSQL 16
#
#  Uso:
#    ./restore_chirpstack-v3.sh arquivo.backup   (formato custom - pg_restore)
#    ./restore_chirpstack-v3.sh arquivo.sql      (plain SQL - psql)
#
#  Se nenhum arquivo for informado, lista os disponiveis em BACKUP_DIR.
# ==============================================================

set -uo pipefail

# --------------------------------------------------------------
# CONFIGURACOES
# --------------------------------------------------------------
PG_HOST="localhost"
PG_PORT="5432"
PG_DB="chirpstack_ns"
#PG_DB="chirpstack_as"
#PG_USER="postgres"
PG_USER="chirpstack_ns"
#PG_USER="chirpstack_as"
export PGPASSWORD="chirpstack_ns"
#export PGPASSWORD="chirpstack_as"
BACKUP_DIR="/home/adailsilva/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/backups/chirpstack_ns/"
#BACKUP_DIR="/home/adailsilva/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/backups/chirpstack_as/"
PG_RESTORE="$(command -v pg_restore || echo "/usr/lib/postgresql/16/bin/pg_restore")"
PSQL="$(command -v psql || echo "/usr/lib/postgresql/16/bin/psql")"

# --------------------------------------------------------------
# TIMESTAMP
# --------------------------------------------------------------
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DATE_LABEL=$(date +"%Y-%m-%d %H:%M:%S")

# --------------------------------------------------------------
# LOG FILE
# --------------------------------------------------------------
mkdir -p "${BACKUP_DIR}"
LOG_FILE="${BACKUP_DIR}/restore_${TIMESTAMP}.log"

# --------------------------------------------------------------
# SUB-ROTINA DE LOG
# --------------------------------------------------------------
log() {
    local msg="$1"
    echo "[${DATE_LABEL}] ${msg}" | tee -a "${LOG_FILE}"
}

# --------------------------------------------------------------
# FUNCAO DE SAIDA COM ERRO
# --------------------------------------------------------------
finalizar_erro() {
    log ""
    log "============================================================"
    log " STATUS FINAL: FALHA"
    log " Log: ${LOG_FILE}"
    log "============================================================"
    exit 99
}

# ==============================================================
# VERIFICAR ARGUMENTO
# ==============================================================
if [ -z "${1:-}" ]; then
    log "Nenhum arquivo informado. Arquivos disponiveis em ${BACKUP_DIR}:"
    log ""
    echo ""
    echo "Arquivos .backup:"
    ls -t "${BACKUP_DIR}"/*.backup 2>/dev/null | xargs -I{} basename {} || echo "  Nenhum encontrado."
    echo ""
    echo "Arquivos .sql:"
    ls -t "${BACKUP_DIR}"/*.sql 2>/dev/null | xargs -I{} basename {} || echo "  Nenhum encontrado."
    echo ""
    echo "Uso: ./restore_chirpstack-v3.sh nome_do_arquivo.backup"
    echo "     ./restore_chirpstack-v3.sh nome_do_arquivo.sql"
    exit 1
fi

# --------------------------------------------------------------
# ARQUIVO INFORMADO
# --------------------------------------------------------------
INPUT_FILE="$1"

# Se nao tiver caminho completo, assume BACKUP_DIR
if [ ! -f "${INPUT_FILE}" ]; then
    INPUT_FILE="${BACKUP_DIR}/$(basename "$1")"
fi

# Verificar se o arquivo existe
if [ ! -f "${INPUT_FILE}" ]; then
    echo "ERRO: Arquivo nao encontrado: ${INPUT_FILE}"
    exit 1
fi

# Detectar extensao
EXT="${INPUT_FILE##*.}"
EXT=".${EXT}"

# ==============================================================
# LOG INICIAL
# ==============================================================
log "============================================================"
log " Iniciando restore: ${PG_DB}"
log " Host: ${PG_HOST}:${PG_PORT}"
log " Usuario: ${PG_USER}"
log " Arquivo: ${INPUT_FILE}"
log " Extensao detectada: ${EXT}"
log "============================================================"

# ==============================================================
# VERIFICAR BINARIOS
# ==============================================================
if [ ! -x "${PG_RESTORE}" ]; then
    log "ERRO: pg_restore nao encontrado em ${PG_RESTORE}"
    log "  Instale com: sudo apt install postgresql-client-16"
    finalizar_erro
fi

if [ ! -x "${PSQL}" ]; then
    log "ERRO: psql nao encontrado em ${PSQL}"
    log "  Instale com: sudo apt install postgresql-client-16"
    finalizar_erro
fi

# ==============================================================
# DROPAR E RECRIAR O BANCO
# ==============================================================
log ""
log "Dropando banco existente (se houver)..."

if ! ${PSQL} \
    --host="${PG_HOST}" \
    --port="${PG_PORT}" \
    --username="${PG_USER}" \
    --no-password \
    --dbname=postgres \
    -c "DROP DATABASE IF EXISTS ${PG_DB};" >> "${LOG_FILE}" 2>&1; then
    log "  AVISO: Nao foi possivel dropar o banco. Pode estar em uso."
    log "  Encerre todas as conexoes e tente novamente."
    log "  Dica: SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='${PG_DB}';"
    finalizar_erro
fi
log "  OK - Banco dropado."

log ""
log "Criando banco vazio..."

if ! ${PSQL} \
    --host="${PG_HOST}" \
    --port="${PG_PORT}" \
    --username="${PG_USER}" \
    --no-password \
    --dbname=postgres \
    -c "CREATE DATABASE ${PG_DB} TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE 'C' LC_CTYPE 'C';" >> "${LOG_FILE}" 2>&1; then
    log "  ERRO: Nao foi possivel criar o banco."
    finalizar_erro
fi
log "  OK - Banco criado."

# ==============================================================
# RESTORE - FORMATO CUSTOM (.backup) via pg_restore
# ==============================================================
STATUS=0

if [ "${EXT}" = ".backup" ]; then
    log ""
    log "Formato: CUSTOM - usando pg_restore..."

    ${PG_RESTORE} \
        --host="${PG_HOST}" \
        --port="${PG_PORT}" \
        --username="${PG_USER}" \
        --dbname="${PG_DB}" \
        --no-password \
        --verbose \
        "${INPUT_FILE}" >> "${LOG_FILE}" 2>&1 || STATUS=$?

# ==============================================================
# RESTORE - FORMATO PLAIN SQL (.sql) via psql
# ==============================================================
elif [ "${EXT}" = ".sql" ]; then
    log ""
    log "Formato: PLAIN SQL - usando psql..."

    ${PSQL} \
        --host="${PG_HOST}" \
        --port="${PG_PORT}" \
        --username="${PG_USER}" \
        --dbname="${PG_DB}" \
        --no-password \
        --file="${INPUT_FILE}" >> "${LOG_FILE}" 2>&1 || STATUS=$?

# ==============================================================
# EXTENSAO NAO RECONHECIDA
# ==============================================================
else
    log "ERRO: Extensao nao reconhecida: ${EXT}"
    log "Use .backup (pg_restore) ou .sql (psql)."
    finalizar_erro
fi

# ==============================================================
# VERIFICAR STATUS DO RESTORE
# ==============================================================
log ""
if [ "${STATUS}" -eq 0 ]; then
    log "  OK - Restore concluido com sucesso."
else
    log "  AVISO: Restore finalizado com codigo: ${STATUS}"
    log "  Verifique o log para detalhes: ${LOG_FILE}"
fi

# ==============================================================
# RESUMO FINAL
# ==============================================================
log ""
log "============================================================"
log " STATUS FINAL: SUCESSO"
log " Banco restaurado: ${PG_DB}"
log " Log: ${LOG_FILE}"
log "============================================================"
exit 0
