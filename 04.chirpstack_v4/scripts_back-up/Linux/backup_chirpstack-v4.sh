#!/bin/bash
# ==============================================================
#  BACKUP DIARIO - chirpstack - PostgreSQL 16
# ==============================================================

set -euo pipefail

# --------------------------------------------------------------
# CONFIGURACOES
# --------------------------------------------------------------
PG_HOST="localhost"
PG_PORT="5432"
PG_DB="chirpstack"
#PG_USER="postgres"
PG_USER="chirpstack"
export PGPASSWORD="chirpstack"
BACKUP_DIR="/home/adailsilva/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/backups/"
PG_DUMP="$(command -v pg_dump || echo "/usr/lib/postgresql/16/bin/pg_dump")"
RETENTION_DAYS=0

# --------------------------------------------------------------
# TIMESTAMP
# --------------------------------------------------------------
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DATE_LABEL=$(date +"%Y-%m-%d %H:%M:%S")

# --------------------------------------------------------------
# ARQUIVOS DE SAIDA
# --------------------------------------------------------------
FILE_BACKUP="${BACKUP_DIR}/${PG_DB}_${TIMESTAMP}.backup"
FILE_SQL="${BACKUP_DIR}/${PG_DB}_${TIMESTAMP}.sql"
LOG_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.log"

# --------------------------------------------------------------
# CRIAR DIRETORIO SE NAO EXISTIR
# --------------------------------------------------------------
mkdir -p "${BACKUP_DIR}"

# --------------------------------------------------------------
# SUB-ROTINA DE LOG
# --------------------------------------------------------------
log() {
    local msg="$1"
    echo "[${DATE_LABEL}] ${msg}" | tee -a "${LOG_FILE}"
}

# --------------------------------------------------------------
# STATUS DE SAIDA
# --------------------------------------------------------------
EXIT_CODE=0
STATUS_BACKUP=0
STATUS_SQL=0

# --------------------------------------------------------------
# LOG INICIAL
# --------------------------------------------------------------
log "============================================================"
log " Iniciando backup: ${PG_DB}"
log " Host: ${PG_HOST}:${PG_PORT}"
log " Usuario: ${PG_USER}"
log "============================================================"

# --------------------------------------------------------------
# VERIFICAR pg_dump
# --------------------------------------------------------------
if [ ! -x "${PG_DUMP}" ]; then
    log "ERRO: pg_dump nao encontrado em ${PG_DUMP}"
    log "  Instale com: sudo apt install postgresql-client-16"
    log "============================================================"
    log " STATUS FINAL: FALHA CRITICA"
    log " Log: ${LOG_FILE}"
    log "============================================================"
    exit 99
fi

VERSION=$(${PG_DUMP} --version 2>&1 | head -n1)
log "Versao: ${VERSION}"

# --------------------------------------------------------------
# BACKUP 1 - Formato CUSTOM (.backup)
# --------------------------------------------------------------
log ""
log "[1/2] Gerando .backup (formato custom)..."

if ${PG_DUMP} \
    --host="${PG_HOST}" \
    --port="${PG_PORT}" \
    --username="${PG_USER}" \
    --dbname="${PG_DB}" \
    --format=custom \
    --blobs \
    --compress=9 \
    --verbose \
    --no-password \
    --file="${FILE_BACKUP}" >> "${LOG_FILE}" 2>&1; then
    SIZE=$(stat -c%s "${FILE_BACKUP}" 2>/dev/null || echo "?")
    log "  OK - ${SIZE} bytes - ${FILE_BACKUP}"
    STATUS_BACKUP=0
else
    STATUS_BACKUP=$?
    log "  ERRO - Falha no .backup - codigo: ${STATUS_BACKUP}"
fi

# --------------------------------------------------------------
# BACKUP 2 - Formato PLAIN SQL (.sql)
# --------------------------------------------------------------
log ""
log "[2/2] Gerando .sql (plain SQL)..."

if ${PG_DUMP} \
    --host="${PG_HOST}" \
    --port="${PG_PORT}" \
    --username="${PG_USER}" \
    --dbname="${PG_DB}" \
    --format=plain \
    --blobs \
    --clean \
    --if-exists \
    --create \
    --verbose \
    --no-password \
    --file="${FILE_SQL}" >> "${LOG_FILE}" 2>&1; then
    SIZE=$(stat -c%s "${FILE_SQL}" 2>/dev/null || echo "?")
    log "  OK - ${SIZE} bytes - ${FILE_SQL}"
    STATUS_SQL=0
else
    STATUS_SQL=$?
    log "  ERRO - Falha no .sql - codigo: ${STATUS_SQL}"
fi

# --------------------------------------------------------------
# LIMPEZA DE BACKUPS ANTIGOS
# --------------------------------------------------------------
if [ "${RETENTION_DAYS}" -gt 0 ]; then
    log ""
    log "Limpando backups com mais de ${RETENTION_DAYS} dia(s)..."
    find "${BACKUP_DIR}" -name "*.backup" -mtime +${RETENTION_DAYS} -delete >> "${LOG_FILE}" 2>&1
    find "${BACKUP_DIR}" -name "*.sql"    -mtime +${RETENTION_DAYS} -delete >> "${LOG_FILE}" 2>&1
    find "${BACKUP_DIR}" -name "*.log"    -mtime +${RETENTION_DAYS} -delete >> "${LOG_FILE}" 2>&1
    log "  OK - Limpeza concluida."
fi

# --------------------------------------------------------------
# RESUMO FINAL
# --------------------------------------------------------------
log ""
log "============================================================"

if [ "${STATUS_BACKUP}" -eq 0 ] && [ "${STATUS_SQL}" -eq 0 ]; then
    log " STATUS FINAL: SUCESSO"
    EXIT_CODE=0
elif [ "${STATUS_BACKUP}" -ne 0 ] && [ "${STATUS_SQL}" -ne 0 ]; then
    log " STATUS FINAL: FALHA - ambos os arquivos falharam"
    EXIT_CODE=2
else
    log " STATUS FINAL: PARCIAL - um arquivo falhou. Verifique o log."
    EXIT_CODE=1
fi

log " Log: ${LOG_FILE}"
log "============================================================"

exit ${EXIT_CODE}
