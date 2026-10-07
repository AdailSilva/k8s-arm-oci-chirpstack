#!/bin/bash
# ==============================================================
#  BACKUP - ChirpStack v3 (chirpstack_ns / chirpstack_as)
#  PostgreSQL rodando em pod no Kubernetes (namespace chirpstack-v3)
#
#  O pg_dump e executado DENTRO do pod (kubectl exec), usando o
#  binario da propria imagem do PostgreSQL. Assim a versao do dump
#  sempre bate com a do servidor e o .backup pode ser lido pelo
#  pg_restore do pod (o que nao acontece com dumps do pg_dump 16 local).
#
#  Gera dois arquivos por banco, na pasta do alvo:
#    <banco>_<AAAAMMDD_HHMMSS>.backup   formato custom (pg_restore)
#    <banco>_<AAAAMMDD_HHMMSS>.sql      plain SQL     (psql)
#  Ambos sao compativeis com restore_chirpstack-v3_k8s.sh.
#
#  Uso:
#    ./backup_chirpstack-v3_k8s.sh ns     (chirpstack_ns)
#    ./backup_chirpstack-v3_k8s.sh as     (chirpstack_as)
#    ./backup_chirpstack-v3_k8s.sh all    (os dois)
#
#  Opcoes (variaveis de ambiente):
#    KUBE_CONTEXT=nome        usa um contexto especifico do kubeconfig
#    PG_PORT=nnnn             forca a porta do PostgreSQL dentro do pod
#                             (padrao: ns=5432, as=5433)
#    FORMATS="backup sql"     formatos gerados (padrao: os dois)
#    RETENTION_DAYS=30        apaga backups/logs do alvo com mais de N dias
#                             (padrao: 0 = nao apaga nada)
#    PG_WAIT_TIMEOUT=60       segundos aguardando o PostgreSQL aceitar conexoes
# ==============================================================

set -uo pipefail

# --------------------------------------------------------------
# CONFIGURACOES GERAIS
# --------------------------------------------------------------
NAMESPACE="chirpstack-v3"
KUBE_CONTEXT="${KUBE_CONTEXT:-}"
FORMATS="${FORMATS:-backup sql}"
RETENTION_DAYS="${RETENTION_DAYS:-0}"
PG_WAIT_TIMEOUT="${PG_WAIT_TIMEOUT:-60}"
PG_PORT_OVERRIDE="${PG_PORT:-}"
BASE_BACKUP_DIR="/home/adailsilva/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/backups"

SCRIPT_NAME="$(basename "$0")"

usage() {
    echo "Uso: ./${SCRIPT_NAME} <ns|as|all>"
    echo ""
    echo "  ns  -> chirpstack_ns (chirpstack-v3-ns-postgresql-deployment, porta 5432)"
    echo "  as  -> chirpstack_as (chirpstack-v3-as-postgresql-deployment, porta 5433)"
    echo "  all -> os dois"
}

KUBECTL=(kubectl)
[ -n "${KUBE_CONTEXT}" ] && KUBECTL+=(--context "${KUBE_CONTEXT}")

if ! command -v kubectl >/dev/null 2>&1; then
    echo "ERRO: kubectl nao encontrado no PATH."
    exit 1
fi
CURRENT_CONTEXT="${KUBE_CONTEXT:-$(kubectl config current-context 2>/dev/null)}"

# --------------------------------------------------------------
# CONFIGURACOES POR ALVO (ns | as)
# --------------------------------------------------------------
set_target() {
    case "$1" in
        ns)
            PG_DEPLOYMENT="chirpstack-v3-ns-postgresql-deployment"
            PG_DB="chirpstack_ns"
            PG_USER="chirpstack_ns"
            PG_PASSWORD="chirpstack_ns"
            PG_PORT="${PG_PORT_OVERRIDE:-5432}"
            BACKUP_DIR="${BASE_BACKUP_DIR}/chirpstack_ns"
            ;;
        as)
            PG_DEPLOYMENT="chirpstack-v3-as-postgresql-deployment"
            PG_DB="chirpstack_as"
            PG_USER="chirpstack_as"
            PG_PASSWORD="chirpstack_as"
            PG_PORT="${PG_PORT_OVERRIDE:-5433}"
            BACKUP_DIR="${BASE_BACKUP_DIR}/chirpstack_as"
            ;;
    esac
}

# --------------------------------------------------------------
# LOG
# --------------------------------------------------------------
log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a "${LOG_FILE}"
}

# --------------------------------------------------------------
# EXECUTAR COMANDO DENTRO DO POD DO POSTGRESQL
# --------------------------------------------------------------
pod_raw() {
    "${KUBECTL[@]}" exec -i -n "${NAMESPACE}" "${PG_POD}" "${CONTAINER_ARGS[@]}" -- "$@"
}

pod_exec() {
    "${KUBECTL[@]}" exec -i -n "${NAMESPACE}" "${PG_POD}" "${CONTAINER_ARGS[@]}" -- \
        env PGUSER="${PG_USER}" PGPASSWORD="${PG_PASSWORD}" PGPORT="${PG_PORT}" "$@"
}

pod_psql() {
    pod_exec psql --dbname="$1" -v ON_ERROR_STOP=1 -tA -c "$2" < /dev/null
}

# ==============================================================
# BACKUP DE UM ALVO
#   retorno: 0 = sucesso, 1 = falha
# ==============================================================
backup_target() {
    set_target "$1"

    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    mkdir -p "${BACKUP_DIR}"
    LOG_FILE="${BACKUP_DIR}/backup_${timestamp}.log"

    # ---- Pod e container ----------------------------------------
    if ! "${KUBECTL[@]}" get deployment "${PG_DEPLOYMENT}" -n "${NAMESPACE}" >> "${LOG_FILE}" 2>&1; then
        log "ERRO: deployment ${PG_DEPLOYMENT} nao encontrado no namespace ${NAMESPACE}."
        return 1
    fi

    local pg_label
    pg_label=$("${KUBECTL[@]}" get deployment "${PG_DEPLOYMENT}" -n "${NAMESPACE}" \
        -o jsonpath='{.spec.selector.matchLabels.app}' 2>/dev/null)
    PG_POD=""
    if [ -n "${pg_label}" ]; then
        PG_POD=$("${KUBECTL[@]}" get pods -n "${NAMESPACE}" -l "app=${pg_label}" \
            --field-selector=status.phase=Running \
            -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    fi
    [ -z "${PG_POD}" ] && PG_POD="deployment/${PG_DEPLOYMENT}"

    local pg_container
    pg_container=$("${KUBECTL[@]}" get deployment "${PG_DEPLOYMENT}" -n "${NAMESPACE}" \
        -o jsonpath='{.spec.template.spec.containers[0].name}' 2>/dev/null)
    CONTAINER_ARGS=()
    [ -n "${pg_container}" ] && CONTAINER_ARGS=(-c "${pg_container}")

    log "============================================================"
    log " Iniciando backup: ${PG_DB}"
    log " Contexto:   ${CURRENT_CONTEXT}"
    log " Namespace:  ${NAMESPACE}"
    log " Pod:        ${PG_POD} (container: ${pg_container:-padrao})"
    log " Usuario:    ${PG_USER}"
    log " Porta:      ${PG_PORT}"
    log " Destino:    ${BACKUP_DIR}"
    log "============================================================"

    # ---- Versao ---------------------------------------------------
    local pg_version
    if ! pg_version=$(pod_raw pg_dump --version < /dev/null 2>> "${LOG_FILE}"); then
        log "ERRO: nao foi possivel executar pg_dump dentro do pod ${PG_POD}."
        return 1
    fi
    log "Versao no pod: ${pg_version}"

    # ---- Conexao --------------------------------------------------
    local ready=0
    for _ in $(seq 1 "$((PG_WAIT_TIMEOUT / 3))"); do
        if pod_psql "${PG_DB}" "SELECT 1;" > /dev/null 2>> "${LOG_FILE}"; then
            ready=1
            break
        fi
        tail -n 5 "${LOG_FILE}" | grep -q 'Stale file handle' && break
        sleep 3
    done

    if [ "${ready}" != "1" ]; then
        log "ERRO: nao foi possivel conectar em ${PG_DB} (porta ${PG_PORT})."
        if tail -n 20 "${LOG_FILE}" | grep -q 'Stale file handle'; then
            log "      'Stale file handle': o volume NFS (FSS) do pod ficou invalido."
            log "      Recrie o pod (scale 0 -> 1) e verifique os dados no FSS."
        else
            log "      Veja: kubectl logs -n ${NAMESPACE} deploy/${PG_DEPLOYMENT}"
        fi
        return 1
    fi

    local tables
    tables=$(pod_psql "${PG_DB}" "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>> "${LOG_FILE}")
    log "  OK - conectado. Tabelas no schema public: ${tables:-?}"
    if [ "${tables:-0}" -eq 0 ]; then
        log "  AVISO: o banco esta sem tabelas - o backup sera de um banco vazio."
    fi

    # ---- Dumps ----------------------------------------------------
    local failed=0 step=0 total
    total=$(echo "${FORMATS}" | wc -w)

    for fmt in ${FORMATS}; do
        step=$((step + 1))
        local out="${BACKUP_DIR}/${PG_DB}_${timestamp}.${fmt}"
        local tmp="${out}.part"
        local status=0
        log ""

        case "${fmt}" in
            backup)
                log "[${step}/${total}] Gerando .backup (formato custom)..."
                pod_exec pg_dump --dbname="${PG_DB}" --format=custom --verbose \
                    < /dev/null > "${tmp}" 2>> "${LOG_FILE}" || status=$?
                ;;
            sql)
                log "[${step}/${total}] Gerando .sql (plain SQL)..."
                pod_exec pg_dump --dbname="${PG_DB}" --format=plain --verbose \
                    < /dev/null > "${tmp}" 2>> "${LOG_FILE}" || status=$?
                ;;
            *)
                log "AVISO: formato desconhecido '${fmt}' - ignorado (use backup e/ou sql)."
                continue
                ;;
        esac

        if [ "${status}" -ne 0 ] || [ ! -s "${tmp}" ]; then
            log "  ERRO: pg_dump falhou (codigo ${status}). Veja o log."
            rm -f "${tmp}"
            failed=1
            continue
        fi

        # Validacao do arquivo gerado
        if [ "${fmt}" = "backup" ]; then
            if ! pod_raw pg_restore --list < "${tmp}" > /dev/null 2>> "${LOG_FILE}"; then
                log "  ERRO: o .backup gerado nao passou no pg_restore --list."
                rm -f "${tmp}"
                failed=1
                continue
            fi
        else
            if ! tail -n 20 "${tmp}" | grep -q 'PostgreSQL database dump complete'; then
                log "  ERRO: o .sql gerado esta incompleto (sem marcador de fim)."
                rm -f "${tmp}"
                failed=1
                continue
            fi
        fi

        mv -f "${tmp}" "${out}"
        log "  OK - $(stat -c %s "${out}") bytes - ${out}"
    done

    # ---- Retencao -------------------------------------------------
    if [ "${failed}" -eq 0 ] && [ "${RETENTION_DAYS}" -gt 0 ]; then
        log ""
        log "Retencao: removendo arquivos de ${PG_DB} com mais de ${RETENTION_DAYS} dia(s)..."
        find "${BACKUP_DIR}" -maxdepth 1 -type f \
            \( -name "${PG_DB}_*.backup" -o -name "${PG_DB}_*.sql" -o -name 'backup_*.log' \) \
            -mtime +"${RETENTION_DAYS}" -print -delete 2>> "${LOG_FILE}" | while read -r f; do
            log "  removido: $(basename "${f}")"
        done
    fi

    log ""
    log "============================================================"
    if [ "${failed}" -eq 0 ]; then
        log " STATUS FINAL: SUCESSO"
    else
        log " STATUS FINAL: FALHA"
    fi
    log " Log: ${LOG_FILE}"
    log "============================================================"
    return "${failed}"
}

# ==============================================================
# MAIN
# ==============================================================
case "${1:-}" in
    ns|as) TARGETS=("$1") ;;
    all)   TARGETS=(ns as) ;;
    -h|--help) usage; exit 0 ;;
    *)
        echo "ERRO: informe o alvo 'ns', 'as' ou 'all'."
        echo ""
        usage
        exit 1
        ;;
esac

EXIT_CODE=0
for t in "${TARGETS[@]}"; do
    backup_target "${t}" || EXIT_CODE=99
    [ "${#TARGETS[@]}" -gt 1 ] && echo ""
done
exit "${EXIT_CODE}"
