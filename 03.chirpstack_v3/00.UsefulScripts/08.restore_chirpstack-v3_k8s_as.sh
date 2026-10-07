#!/bin/bash
# ==============================================================
#  RESTORE - ChirpStack v3 (chirpstack_ns / chirpstack_as)
#  PostgreSQL rodando em pod no Kubernetes (namespace chirpstack-v3)
#
#  O restore e executado DENTRO do pod (kubectl exec), usando o
#  pg_restore/psql da propria imagem do PostgreSQL. Assim nao ha
#  problema de versao do client local nem necessidade de port-forward.
#
#  Uso:
#    ./restore_chirpstack-v3_k8s.sh <ns|as> arquivo.backup   (custom - pg_restore)
#    ./restore_chirpstack-v3_k8s.sh <ns|as> arquivo.sql      (plain  - psql)
#    ./restore_chirpstack-v3_k8s.sh <ns|as>                  (lista os backups)
#
#  Opcoes (variaveis de ambiente):
#    ASSUME_YES=1             nao pede confirmacao antes de dropar o banco
#    SCALE_DOWN_APP=0         nao escala o servidor ChirpStack para 0 durante o restore
#    KUBE_CONTEXT=nome        usa um contexto especifico do kubeconfig
#    PG_PORT=nnnn             forca a porta do PostgreSQL dentro do pod
#                             (padrao: ns=5432, as=5433)
#    PG_ADMIN_USER=postgres   superusuario usado no DROP/CREATE DATABASE
#    PG_ADMIN_PASSWORD=...    senha do superusuario (padrao: postgres)
#    PG_WAIT_TIMEOUT=120      segundos aguardando o PostgreSQL aceitar conexoes
#
#  Notas:
#    - DROP/CREATE DATABASE sao feitos com o superusuario (PG_ADMIN_USER),
#      entao o usuario da aplicacao nao precisa de CREATEDB. O role da
#      aplicacao e criado automaticamente se nao existir (pod recem-criado).
#    - Dumps .sql gerados por pg_dump mais novo (ex.: 16) com --clean --create
#      sao filtrados na hora: DROP/CREATE DATABASE, ALTER SCHEMA public OWNER
#      e COMMENT ON EXTENSION sao removidos (incompativeis com PG 14 / sem
#      superusuario). O arquivo original nao e alterado.
#    - Arquivos .backup gerados por pg_dump 16+ (formato 1.15) nao abrem no
#      pg_restore 14 do pod; o script avisa e sugere usar o .sql.
#
#  Exemplo:
#    ./restore_chirpstack-v3_k8s.sh ns chirpstack_ns_20260518_182447.sql
#    ASSUME_YES=1 ./restore_chirpstack-v3_k8s.sh as chirpstack_as_20260518_182914.sql
# ==============================================================

set -uo pipefail

# --------------------------------------------------------------
# CONFIGURACOES GERAIS
# --------------------------------------------------------------
NAMESPACE="chirpstack-v3"
PG_CONTAINER=""                  # preencha se o pod tiver mais de um container
KUBE_CONTEXT="${KUBE_CONTEXT:-}"
ASSUME_YES="${ASSUME_YES:-0}"
SCALE_DOWN_APP="${SCALE_DOWN_APP:-1}"
APP_WAIT_TIMEOUT=180             # segundos
PG_WAIT_TIMEOUT="${PG_WAIT_TIMEOUT:-120}"
PG_PORT="${PG_PORT:-}"
PG_ADMIN_USER="${PG_ADMIN_USER:-postgres}"
PG_ADMIN_PASSWORD="${PG_ADMIN_PASSWORD:-postgres}"
BASE_BACKUP_DIR="/home/adailsilva/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/backups"

SCRIPT_NAME="$(basename "$0")"

usage() {
    echo "Uso: ./${SCRIPT_NAME} <ns|as> [arquivo.backup|arquivo.sql]"
    echo ""
    echo "  ns -> chirpstack_ns (chirpstack-v3-ns-postgresql-deployment)"
    echo "  as -> chirpstack_as (chirpstack-v3-as-postgresql-deployment)"
    echo ""
    echo "  Sem arquivo: lista os backups disponiveis do alvo."
}

# --------------------------------------------------------------
# CONFIGURACOES POR ALVO (ns | as)
# --------------------------------------------------------------
TARGET="${1:-}"
case "${TARGET}" in
    ns)
        PG_DEPLOYMENT="chirpstack-v3-ns-postgresql-deployment"
        PG_DB="chirpstack_ns"
        PG_USER="chirpstack_ns"
        PG_PASSWORD="chirpstack_ns"
        PG_DEFAULT_PORT="5432"
        APP_DEPLOYMENT="chirpstack-v3-network-server-deployment"
        BACKUP_DIR="${BASE_BACKUP_DIR}/chirpstack_ns"
        ;;
    as)
        PG_DEPLOYMENT="chirpstack-v3-as-postgresql-deployment"
        PG_DB="chirpstack_as"
        PG_USER="chirpstack_as"
        PG_PASSWORD="chirpstack_as"
        PG_DEFAULT_PORT="5433"
        APP_DEPLOYMENT="chirpstack-v3-application-server-deployment"
        BACKUP_DIR="${BASE_BACKUP_DIR}/chirpstack_as"
        ;;
    -h|--help)
        usage; exit 0 ;;
    *)
        echo "ERRO: informe o alvo 'ns' ou 'as' como primeiro argumento."
        echo ""
        usage
        exit 1
        ;;
esac
shift
PG_PORT="${PG_PORT:-${PG_DEFAULT_PORT}}"

# --------------------------------------------------------------
# KUBECTL
# --------------------------------------------------------------
KUBECTL=(kubectl)
[ -n "${KUBE_CONTEXT}" ] && KUBECTL+=(--context "${KUBE_CONTEXT}")

CONTAINER_ARGS=()
[ -n "${PG_CONTAINER}" ] && CONTAINER_ARGS=(-c "${PG_CONTAINER}")

# --------------------------------------------------------------
# LOG FILE
# --------------------------------------------------------------
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
mkdir -p "${BACKUP_DIR}"
LOG_FILE="${BACKUP_DIR}/restore_${TIMESTAMP}.log"

# --------------------------------------------------------------
# SUB-ROTINA DE LOG
# --------------------------------------------------------------
log() {
    local msg="$1"
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] ${msg}" | tee -a "${LOG_FILE}"
}

# --------------------------------------------------------------
# ESTADO DO APP (para voltar a escala mesmo em caso de erro)
# --------------------------------------------------------------
APP_ORIGINAL_REPLICAS=""
APP_LABEL=""

restore_app_scale() {
    [ -z "${APP_ORIGINAL_REPLICAS}" ] && return 0
    local replicas="${APP_ORIGINAL_REPLICAS}"
    APP_ORIGINAL_REPLICAS=""

    log ""
    log "Voltando ${APP_DEPLOYMENT} para ${replicas} replica(s)..."
    if "${KUBECTL[@]}" scale deployment "${APP_DEPLOYMENT}" -n "${NAMESPACE}" \
        --replicas="${replicas}" >> "${LOG_FILE}" 2>&1; then
        if [ "${replicas}" -gt 0 ]; then
            if "${KUBECTL[@]}" rollout status deployment "${APP_DEPLOYMENT}" -n "${NAMESPACE}" \
                --timeout="${APP_WAIT_TIMEOUT}s" >> "${LOG_FILE}" 2>&1; then
                log "  OK - ${APP_DEPLOYMENT} pronto."
            else
                log "  AVISO: ${APP_DEPLOYMENT} nao ficou pronto em ${APP_WAIT_TIMEOUT}s. Verifique:"
                log "    kubectl get pods -n ${NAMESPACE}"
            fi
        else
            log "  OK - escala restaurada."
        fi
    else
        log "  ERRO: nao foi possivel reescalar. Rode manualmente:"
        log "    kubectl scale deployment ${APP_DEPLOYMENT} -n ${NAMESPACE} --replicas=${replicas}"
    fi
}

trap restore_app_scale EXIT
trap 'log "Interrompido."; exit 130' INT TERM

# --------------------------------------------------------------
# FUNCAO DE SAIDA COM ERRO
# --------------------------------------------------------------
finalizar_erro() {
    restore_app_scale
    log ""
    log "============================================================"
    log " STATUS FINAL: FALHA"
    log " Log: ${LOG_FILE}"
    log "============================================================"
    exit 99
}

# --------------------------------------------------------------
# EXECUTAR COMANDO DENTRO DO POD DO POSTGRESQL
# --------------------------------------------------------------
pod_raw() {
    # Executa um comando no pod sem variaveis do PostgreSQL
    "${KUBECTL[@]}" exec -i -n "${NAMESPACE}" "${PG_POD}" "${CONTAINER_ARGS[@]}" -- "$@"
}

pod_exec_as() {
    # $1 = usuario, $2 = senha, demais = comando
    local user="$1" pass="$2"
    shift 2
    "${KUBECTL[@]}" exec -i -n "${NAMESPACE}" "${PG_POD}" "${CONTAINER_ARGS[@]}" -- \
        env PGUSER="${user}" PGPASSWORD="${pass}" PGPORT="${PG_PORT}" "$@"
}

pod_exec() {
    pod_exec_as "${PG_USER}" "${PG_PASSWORD}" "$@"
}

pod_psql() {
    # $1 = banco, $2 = comando SQL (usuario da aplicacao)
    pod_exec psql --dbname="$1" -v ON_ERROR_STOP=1 -tA -c "$2" < /dev/null
}

pod_psql_admin() {
    # $1 = banco, $2 = comando SQL (superusuario)
    pod_exec_as "${PG_ADMIN_USER}" "${PG_ADMIN_PASSWORD}" \
        psql --dbname="$1" -v ON_ERROR_STOP=1 -tA -c "$2" < /dev/null
}

# ==============================================================
# SEM ARQUIVO -> LISTAR BACKUPS
# ==============================================================
if [ -z "${1:-}" ]; then
    echo "Arquivos disponiveis em ${BACKUP_DIR}:"
    echo ""
    echo "Arquivos .backup:"
    ls -t "${BACKUP_DIR}"/*.backup 2>/dev/null | xargs -I{} basename {} || echo "  Nenhum encontrado."
    echo ""
    echo "Arquivos .sql:"
    ls -t "${BACKUP_DIR}"/*.sql 2>/dev/null | xargs -I{} basename {} || echo "  Nenhum encontrado."
    echo ""
    usage
    rm -f "${LOG_FILE}"
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

if [ ! -f "${INPUT_FILE}" ]; then
    echo "ERRO: Arquivo nao encontrado: ${INPUT_FILE}"
    rm -f "${LOG_FILE}"
    exit 1
fi

EXT=".${INPUT_FILE##*.}"
if [ "${EXT}" != ".backup" ] && [ "${EXT}" != ".sql" ]; then
    echo "ERRO: Extensao nao reconhecida: ${EXT}. Use .backup (pg_restore) ou .sql (psql)."
    rm -f "${LOG_FILE}"
    exit 1
fi

# ==============================================================
# VERIFICAR KUBECTL E CLUSTER
# ==============================================================
if ! command -v kubectl >/dev/null 2>&1; then
    log "ERRO: kubectl nao encontrado no PATH."
    finalizar_erro
fi

CURRENT_CONTEXT="${KUBE_CONTEXT:-$(kubectl config current-context 2>/dev/null)}"

if ! "${KUBECTL[@]}" get namespace "${NAMESPACE}" >> "${LOG_FILE}" 2>&1; then
    log "ERRO: namespace ${NAMESPACE} inacessivel no contexto '${CURRENT_CONTEXT}'."
    finalizar_erro
fi

if ! "${KUBECTL[@]}" get deployment "${PG_DEPLOYMENT}" -n "${NAMESPACE}" >> "${LOG_FILE}" 2>&1; then
    log "ERRO: deployment ${PG_DEPLOYMENT} nao encontrado no namespace ${NAMESPACE}."
    log "      Reaplique o manifesto do PostgreSQL antes do restore."
    finalizar_erro
fi

# --------------------------------------------------------------
# RESOLVER O POD DO POSTGRESQL (pelo selector do deployment)
# --------------------------------------------------------------
PG_LABEL=$("${KUBECTL[@]}" get deployment "${PG_DEPLOYMENT}" -n "${NAMESPACE}" \
    -o jsonpath='{.spec.selector.matchLabels.app}' 2>/dev/null)

PG_POD=""
if [ -n "${PG_LABEL}" ]; then
    PG_POD=$("${KUBECTL[@]}" get pods -n "${NAMESPACE}" -l "app=${PG_LABEL}" \
        --field-selector=status.phase=Running \
        -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
fi
[ -z "${PG_POD}" ] && PG_POD="deployment/${PG_DEPLOYMENT}"

# Container principal (evita a mensagem "Defaulted container" quando ha init containers)
if [ -z "${PG_CONTAINER}" ]; then
    PG_CONTAINER=$("${KUBECTL[@]}" get deployment "${PG_DEPLOYMENT}" -n "${NAMESPACE}" \
        -o jsonpath='{.spec.template.spec.containers[0].name}' 2>/dev/null)
    [ -n "${PG_CONTAINER}" ] && CONTAINER_ARGS=(-c "${PG_CONTAINER}")
fi

# ==============================================================
# LOG INICIAL
# ==============================================================
log "============================================================"
log " Iniciando restore: ${PG_DB}"
log " Contexto:   ${CURRENT_CONTEXT}"
log " Namespace:  ${NAMESPACE}"
log " Pod:        ${PG_POD} (container: ${PG_CONTAINER:-padrao})"
log " Usuario:    ${PG_USER} (admin: ${PG_ADMIN_USER})"
log " Arquivo:    ${INPUT_FILE} ($(du -h "${INPUT_FILE}" | cut -f1))"
log " Extensao:   ${EXT}"
log "============================================================"

# --------------------------------------------------------------
# VERSOES DENTRO DO POD
# --------------------------------------------------------------
if ! PG_VERSION=$(pod_raw pg_restore --version < /dev/null 2>> "${LOG_FILE}"); then
    log "ERRO: nao foi possivel executar pg_restore dentro do pod ${PG_POD}."
    finalizar_erro
fi
log "Versao no pod: ${PG_VERSION}"
PG_MAJOR=$(echo "${PG_VERSION}" | grep -oE '[0-9]+' | head -1)

# --------------------------------------------------------------
# .backup GERADO POR pg_dump MAIS NOVO QUE O pg_restore DO POD?
#   bytes 6-7 do cabecalho "PGDMP" = versao do formato (1.15 = pg_dump 16+)
# --------------------------------------------------------------
if [ "${EXT}" = ".backup" ]; then
    read -r _ _ _ _ _ ARCH_MAJ ARCH_MIN _ < <(od -A n -t u1 -N 8 "${INPUT_FILE}")
    log "Formato do arquivo: ${ARCH_MAJ:-?}.${ARCH_MIN:-?}"
    if [ "${ARCH_MAJ:-0}" -eq 1 ] && [ "${ARCH_MIN:-0}" -ge 15 ] && [ "${PG_MAJOR:-0}" -lt 16 ]; then
        log "ERRO: o arquivo foi gerado por pg_dump 16+ (formato 1.${ARCH_MIN}) e o"
        log "      pg_restore ${PG_MAJOR} do pod nao consegue le-lo. Use o .sql equivalente."
        finalizar_erro
    fi
fi

# ==============================================================
# AGUARDAR O POSTGRESQL ACEITAR CONEXOES (superusuario)
# ==============================================================
log ""
log "Aguardando o PostgreSQL aceitar conexoes na porta ${PG_PORT} (ate ${PG_WAIT_TIMEOUT}s)..."
PG_READY=0
for _ in $(seq 1 "$((PG_WAIT_TIMEOUT / 3))"); do
    if pod_psql_admin postgres "SELECT 1;" > /dev/null 2>> "${LOG_FILE}"; then
        PG_READY=1
        break
    fi
    # Se o erro for de NFS, nao adianta esperar
    if tail -n 5 "${LOG_FILE}" | grep -q 'Stale file handle'; then
        break
    fi
    sleep 3
done

if [ "${PG_READY}" != "1" ]; then
    log "ERRO: o PostgreSQL no pod ${PG_POD} nao aceitou conexoes."
    if tail -n 20 "${LOG_FILE}" | grep -q 'Stale file handle'; then
        log "      'Stale file handle': o volume NFS (FSS) do pod ficou invalido."
        log "      Recrie o pod: kubectl scale deployment ${PG_DEPLOYMENT} -n ${NAMESPACE} --replicas=0"
        log "                    (aguarde sumir) e depois --replicas=1"
    else
        log "      Verifique a porta (PG_PORT=${PG_PORT}), usuario/senha do admin"
        log "      (PG_ADMIN_USER / PG_ADMIN_PASSWORD) e os logs:"
        log "      kubectl logs -n ${NAMESPACE} deploy/${PG_DEPLOYMENT}"
    fi
    finalizar_erro
fi
log "  OK - conexao estabelecida (porta ${PG_PORT})."

# --------------------------------------------------------------
# ROLE DA APLICACAO (cria se o pod for novo / initdb limpo)
# --------------------------------------------------------------
ROLE_EXISTS=$(pod_psql_admin postgres "SELECT 1 FROM pg_roles WHERE rolname = '${PG_USER}';" 2>> "${LOG_FILE}")
if [ "${ROLE_EXISTS}" != "1" ]; then
    log "Role ${PG_USER} nao existe - criando..."
    if ! pod_psql_admin postgres "CREATE ROLE ${PG_USER} LOGIN PASSWORD '${PG_PASSWORD}';" >> "${LOG_FILE}" 2>&1; then
        log "  ERRO: nao foi possivel criar o role ${PG_USER}."
        finalizar_erro
    fi
    log "  OK - role criado."
fi

# ==============================================================
# CONFIRMACAO
# ==============================================================
if [ "${ASSUME_YES}" != "1" ]; then
    echo ""
    echo "ATENCAO: o banco '${PG_DB}' no pod ${PG_POD}"
    echo "         (contexto '${CURRENT_CONTEXT}', namespace ${NAMESPACE})"
    echo "         sera APAGADO e recriado a partir de $(basename "${INPUT_FILE}")."
    echo ""
    read -r -p "Digite o nome do banco (${PG_DB}) para confirmar: " CONFIRM
    if [ "${CONFIRM}" != "${PG_DB}" ]; then
        log "Cancelado pelo usuario."
        exit 1
    fi
fi

# ==============================================================
# ESCALAR O SERVIDOR CHIRPSTACK PARA 0 (libera as conexoes)
# ==============================================================
if [ "${SCALE_DOWN_APP}" = "1" ]; then
    log ""
    if "${KUBECTL[@]}" get deployment "${APP_DEPLOYMENT}" -n "${NAMESPACE}" >> "${LOG_FILE}" 2>&1; then
        REPLICAS=$("${KUBECTL[@]}" get deployment "${APP_DEPLOYMENT}" -n "${NAMESPACE}" \
            -o jsonpath='{.spec.replicas}')
        APP_LABEL=$("${KUBECTL[@]}" get deployment "${APP_DEPLOYMENT}" -n "${NAMESPACE}" \
            -o jsonpath='{.spec.selector.matchLabels.app}' 2>/dev/null)

        log "Escalando ${APP_DEPLOYMENT} de ${REPLICAS} para 0..."
        if "${KUBECTL[@]}" scale deployment "${APP_DEPLOYMENT}" -n "${NAMESPACE}" \
            --replicas=0 >> "${LOG_FILE}" 2>&1; then
            APP_ORIGINAL_REPLICAS="${REPLICAS:-1}"

            if [ -n "${APP_LABEL}" ]; then
                for _ in $(seq 1 "${APP_WAIT_TIMEOUT}"); do
                    [ -z "$("${KUBECTL[@]}" get pods -n "${NAMESPACE}" -l "app=${APP_LABEL}" -o name 2>/dev/null)" ] && break
                    sleep 1
                done
            else
                sleep 10
            fi
            log "  OK - ${APP_DEPLOYMENT} parado."
        else
            log "  AVISO: nao foi possivel escalar ${APP_DEPLOYMENT}. Seguindo mesmo assim."
        fi
    else
        log "AVISO: deployment ${APP_DEPLOYMENT} nao encontrado - pulando scale down."
        log "       Ajuste APP_DEPLOYMENT no script se o nome for outro."
    fi
else
    log "Scale down do app desativado (SCALE_DOWN_APP=0)."
fi

# ==============================================================
# DROPAR E RECRIAR O BANCO (superusuario)
# ==============================================================
log ""
log "Dropando banco existente (se houver)..."

# WITH (FORCE) encerra conexoes remanescentes (PostgreSQL 13+)
if ! pod_psql_admin postgres "DROP DATABASE IF EXISTS ${PG_DB} WITH (FORCE);" >> "${LOG_FILE}" 2>&1; then
    log "  ERRO: Nao foi possivel dropar o banco. Veja o log."
    finalizar_erro
fi
log "  OK - Banco dropado."

log ""
log "Criando banco vazio..."

if ! pod_psql_admin postgres "CREATE DATABASE ${PG_DB} OWNER ${PG_USER} TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE 'C' LC_CTYPE 'C';" >> "${LOG_FILE}" 2>&1; then
    log "  ERRO: Nao foi possivel criar o banco."
    finalizar_erro
fi
log "  OK - Banco criado."

# ==============================================================
# RESTORE (arquivo local enviado via stdin para dentro do pod)
#   Executado com o usuario da aplicacao: os objetos ficam com o dono certo.
# ==============================================================
STATUS=0
LOG_LINES_BEFORE=$(wc -l < "${LOG_FILE}")

if [ "${EXT}" = ".backup" ]; then
    log ""
    log "Formato: CUSTOM - usando pg_restore dentro do pod..."

    pod_exec pg_restore \
        --dbname="${PG_DB}" \
        --no-owner \
        --verbose \
        < "${INPUT_FILE}" >> "${LOG_FILE}" 2>&1 || STATUS=$?
else
    log ""
    log "Formato: PLAIN SQL - usando psql dentro do pod..."
    log "  (filtrando DROP/CREATE DATABASE, ALTER SCHEMA public OWNER e COMMENT ON EXTENSION)"

    sed -E \
        -e "/^DROP DATABASE (IF EXISTS )?${PG_DB};/d" \
        -e "/^CREATE DATABASE ${PG_DB} /d" \
        -e '/^ALTER SCHEMA public OWNER TO /d' \
        -e '/^COMMENT ON EXTENSION /d' \
        "${INPUT_FILE}" \
    | pod_exec psql \
        --dbname="${PG_DB}" \
        --file=- \
        >> "${LOG_FILE}" 2>&1 || STATUS=$?
fi

ERR_COUNT=$(tail -n +"$((LOG_LINES_BEFORE + 1))" "${LOG_FILE}" | grep -cE 'ERROR:|error:' || true)

# ==============================================================
# VERIFICAR STATUS DO RESTORE
# ==============================================================
log ""
if [ "${STATUS}" -eq 0 ] && [ "${ERR_COUNT}" -eq 0 ]; then
    log "  OK - Restore concluido sem erros."
else
    log "  AVISO: Restore finalizado com codigo ${STATUS} e ${ERR_COUNT} linha(s) de erro."
    log "  Verifique o log: ${LOG_FILE}"
fi

TABLES=$(pod_psql "${PG_DB}" "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>> "${LOG_FILE}")
log "  Tabelas no schema public: ${TABLES:-?}"

# ==============================================================
# VOLTAR O APP
# ==============================================================
restore_app_scale

# ==============================================================
# RESUMO FINAL
# ==============================================================
log ""
log "============================================================"
if [ "${STATUS}" -eq 0 ] && [ "${ERR_COUNT}" -eq 0 ]; then
    log " STATUS FINAL: SUCESSO"
    FINAL_EXIT=0
else
    log " STATUS FINAL: CONCLUIDO COM AVISOS"
    FINAL_EXIT=2
fi
log " Banco restaurado: ${PG_DB} (${NAMESPACE}/${PG_POD}, porta ${PG_PORT})"
log " Log: ${LOG_FILE}"
log "============================================================"
exit "${FINAL_EXIT}"
