#!/bin/bash
# ==============================================================
#  BACKUP DIARIO - ChirpStack v3 (chirpstack_ns + chirpstack_as)
#  PostgreSQL 16 - via kubectl port-forward (OCI Kubernetes)
# ==============================================================
#  Uso:
#    ./backup_chirpstack-v3.sh          -> backup de ns e as
#    ./backup_chirpstack-v3.sh ns       -> somente chirpstack_ns
#    ./backup_chirpstack-v3.sh as       -> somente chirpstack_as
#
#  O script abre o port-forward de cada base, gera .backup (custom)
#  e .sql (plain) e fecha o port-forward ao final. Se a porta ja
#  estiver aberta (port-forward manual), ela e reaproveitada.
# ==============================================================

set -uo pipefail

# --------------------------------------------------------------
# CONFIGURACOES GERAIS
# --------------------------------------------------------------
K8S_NAMESPACE="chirpstack-v3"
PG_HOST="127.0.0.1"
BASE_BACKUP_DIR="/home/adailsilva/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/backups"
PG_DUMP="$(command -v pg_dump || echo "/usr/lib/postgresql/16/bin/pg_dump")"
PG_ISREADY="$(command -v pg_isready || echo "/usr/lib/postgresql/16/bin/pg_isready")"
KUBECTL="$(command -v kubectl || echo "kubectl")"
PF_TIMEOUT=30          # segundos aguardando o port-forward responder
RETENTION_DAYS=0       # 0 = nao apaga backups antigos

# --------------------------------------------------------------
# CONFIGURACAO DAS BASES
#   chave | service | porta | database | usuario | senha | diretorio
# --------------------------------------------------------------
declare -A DBS=(
    [ns]="chirpstack-v3-ns-postgresql-service|5437|chirpstack_ns|chirpstack_ns|chirpstack_ns|${BASE_BACKUP_DIR}/chirpstack_ns"
    [as]="chirpstack-v3-as-postgresql-service|5438|chirpstack_as|chirpstack_as|chirpstack_as|${BASE_BACKUP_DIR}/chirpstack_as"
)
ORDER=(ns as)

# --------------------------------------------------------------
# TIMESTAMP
# --------------------------------------------------------------
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# --------------------------------------------------------------
# CONTROLE DO PORT-FORWARD (fecha mesmo em caso de erro/Ctrl+C)
# --------------------------------------------------------------
PF_PID=""
cleanup() {
    if [ -n "${PF_PID}" ] && kill -0 "${PF_PID}" 2>/dev/null; then
        kill "${PF_PID}" 2>/dev/null
        wait "${PF_PID}" 2>/dev/null
    fi
    PF_PID=""
}
trap cleanup EXIT INT TERM

# --------------------------------------------------------------
# SUB-ROTINA DE LOG
# --------------------------------------------------------------
LOG_FILE=""
log() {
    local msg="$1"
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${msg}" | tee -a "${LOG_FILE}"
}

# --------------------------------------------------------------
# ABRIR PORT-FORWARD
# --------------------------------------------------------------
abrir_port_forward() {
    local svc="$1" port="$2"

    if "${PG_ISREADY}" -h "${PG_HOST}" -p "${port}" -q 2>/dev/null; then
        log "Port-forward: porta ${port} ja esta ativa - reaproveitando."
        return 0
    fi

    log "Port-forward: kubectl port-forward -n ${K8S_NAMESPACE} svc/${svc} ${port}:${port}"
    "${KUBECTL}" port-forward -n "${K8S_NAMESPACE}" "svc/${svc}" "${port}:${port}" >> "${LOG_FILE}" 2>&1 &
    PF_PID=$!

    local i
    for ((i = 0; i < PF_TIMEOUT; i++)); do
        if "${PG_ISREADY}" -h "${PG_HOST}" -p "${port}" -q 2>/dev/null; then
            log "  OK - port-forward ativo (PID ${PF_PID})"
            return 0
        fi
        if ! kill -0 "${PF_PID}" 2>/dev/null; then
            log "  ERRO - kubectl port-forward encerrou. Verifique o kubeconfig/contexto."
            PF_PID=""
            return 1
        fi
        sleep 1
    done

    log "  ERRO - porta ${port} nao respondeu em ${PF_TIMEOUT}s."
    cleanup
    return 1
}

# --------------------------------------------------------------
# BACKUP DE UMA BASE
#   retorno: 0 sucesso | 1 parcial | 2 falha | 3 port-forward
# --------------------------------------------------------------
backup_base() {
    local key="$1"
    local svc port db user pass dir
    IFS='|' read -r svc port db user pass dir <<< "${DBS[$key]}"

    mkdir -p "${dir}"
    LOG_FILE="${dir}/backup_${TIMESTAMP}.log"
    local file_backup="${dir}/${db}_${TIMESTAMP}.backup"
    local file_sql="${dir}/${db}_${TIMESTAMP}.sql"
    local status_backup=0 status_sql=0 size

    export PGPASSWORD="${pass}"

    log "============================================================"
    log " Iniciando backup: ${db}"
    log " Namespace: ${K8S_NAMESPACE} | Service: ${svc}"
    log " Host: ${PG_HOST}:${port}"
    log " Usuario: ${user}"
    log " Destino: ${dir}"
    log " Versao: $(${PG_DUMP} --version 2>&1 | head -n1)"
    log "============================================================"

    if ! abrir_port_forward "${svc}" "${port}"; then
        log " STATUS FINAL: FALHA - sem conexao com ${db}"
        log " Log: ${LOG_FILE}"
        log "============================================================"
        return 3
    fi

    # --- BACKUP 1 - Formato CUSTOM (.backup) ---
    log ""
    log "[1/2] Gerando .backup (formato custom)..."
    if "${PG_DUMP}" \
        --host="${PG_HOST}" \
        --port="${port}" \
        --username="${user}" \
        --dbname="${db}" \
        --format=custom \
        --blobs \
        --compress=9 \
        --verbose \
        --no-password \
        --file="${file_backup}" >> "${LOG_FILE}" 2>&1; then
        size=$(stat -c%s "${file_backup}" 2>/dev/null || echo "?")
        log "  OK - ${size} bytes - ${file_backup}"
    else
        status_backup=$?
        log "  ERRO - Falha no .backup - codigo: ${status_backup}"
    fi

    # --- BACKUP 2 - Formato PLAIN SQL (.sql) ---
    log ""
    log "[2/2] Gerando .sql (plain SQL)..."
    if "${PG_DUMP}" \
        --host="${PG_HOST}" \
        --port="${port}" \
        --username="${user}" \
        --dbname="${db}" \
        --format=plain \
        --blobs \
        --clean \
        --if-exists \
        --create \
        --verbose \
        --no-password \
        --file="${file_sql}" >> "${LOG_FILE}" 2>&1; then
        size=$(stat -c%s "${file_sql}" 2>/dev/null || echo "?")
        log "  OK - ${size} bytes - ${file_sql}"
    else
        status_sql=$?
        log "  ERRO - Falha no .sql - codigo: ${status_sql}"
    fi

    cleanup
    unset PGPASSWORD

    # --- LIMPEZA DE BACKUPS ANTIGOS ---
    if [ "${RETENTION_DAYS}" -gt 0 ]; then
        log ""
        log "Limpando backups com mais de ${RETENTION_DAYS} dia(s)..."
        find "${dir}" -maxdepth 1 \( -name "*.backup" -o -name "*.sql" -o -name "*.log" \) \
            -mtime +"${RETENTION_DAYS}" -print -delete >> "${LOG_FILE}" 2>&1
        log "  OK - Limpeza concluida."
    fi

    # --- RESUMO DA BASE ---
    log ""
    log "============================================================"
    local rc
    if [ "${status_backup}" -eq 0 ] && [ "${status_sql}" -eq 0 ]; then
        log " STATUS FINAL (${db}): SUCESSO"; rc=0
    elif [ "${status_backup}" -ne 0 ] && [ "${status_sql}" -ne 0 ]; then
        log " STATUS FINAL (${db}): FALHA - ambos os arquivos falharam"; rc=2
    else
        log " STATUS FINAL (${db}): PARCIAL - um arquivo falhou. Verifique o log."; rc=1
    fi
    log " Log: ${LOG_FILE}"
    log "============================================================"
    return ${rc}
}

# --------------------------------------------------------------
# VERIFICACOES INICIAIS
# --------------------------------------------------------------
for bin in "${PG_DUMP}" "${PG_ISREADY}"; do
    if [ ! -x "${bin}" ]; then
        echo "ERRO: ${bin} nao encontrado. Instale com: sudo apt install postgresql-client-16"
        exit 99
    fi
done
if ! command -v "${KUBECTL}" >/dev/null 2>&1; then
    echo "ERRO: kubectl nao encontrado no PATH."
    exit 99
fi

# --------------------------------------------------------------
# EXECUCAO
# --------------------------------------------------------------
if [ $# -gt 0 ]; then TARGETS=("$@"); else TARGETS=("${ORDER[@]}"); fi

EXIT_CODE=0
RESUMO=()
for t in "${TARGETS[@]}"; do
    if [ -z "${DBS[$t]:-}" ]; then
        echo "ERRO: base desconhecida '${t}' (use: ns | as)"
        EXIT_CODE=2
        continue
    fi
    backup_base "${t}"
    rc=$?
    case ${rc} in
        0) RESUMO+=("${t}: SUCESSO") ;;
        1) RESUMO+=("${t}: PARCIAL") ;;
        *) RESUMO+=("${t}: FALHA") ;;
    esac
    [ "${rc}" -gt "${EXIT_CODE}" ] && EXIT_CODE=${rc}
    echo
done

echo "============================================================"
echo " RESUMO GERAL - ChirpStack v3"
for r in "${RESUMO[@]}"; do echo "   ${r}"; done
echo "============================================================"

exit ${EXIT_CODE}
