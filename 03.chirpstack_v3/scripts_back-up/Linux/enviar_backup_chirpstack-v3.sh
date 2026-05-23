#!/bin/bash
# ==============================================================
#  ENVIO DE BACKUP DIARIO - chirpstack_ns/as
#  Requer: OpenSSH client + chave SSH configurada
#  Destino: Servidor REMOTO NA INTERNET
#  Como usar: Execute apos o backup_chirpstack-v3.sh
#             OU integre chamando este script no final do outro
# ==============================================================

set -uo pipefail

# ==============================================================
#  CONFIGURACOES - EDITE AQUI
# ==============================================================

# --- Origem (deve ser o mesmo do backup_chirpstack-v3.sh) ---
BACKUP_DIR="/home/adailsilva/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/backups/chirpstack_ns/"
#BACKUP_DIR="/home/adailsilva/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/backups/chirpstack_as/"
PG_DB="chirpstack_ns"
#PG_DB="chirpstack_as"

# --- Destino Remoto (servidor na internet) ---
SSH_USER="seu_usuario"
SSH_HOST="seu.servidor.com.br"
SSH_PORT="22"
#   DICA DE SEGURANCA: troque a porta 22 por outra (ex: 2222) no servidor
#   para reduzir ataques de forca bruta automatizados
REMOTE_DIR="/home/seu_usuario/backups/chirpstack-v3"
SSH_KEY="${HOME}/.ssh/id_ed25519"
#   RECOMENDADO para internet: ed25519 e mais seguro e moderno que rsa

# --- Timeout de conexao (segundos) - importante para internet ---
CONNECT_TIMEOUT=30

# --- Retencao remota (0 = nao apagar nada) ---
RETENTION_DAYS=30

# --- Enviar apenas os arquivos gerados HOJE? ---
#   1 = sim (mais rapido, ideal para cron diario)
#   0 = nao (reenvia tudo, util para recuperacao)
ONLY_TODAY=1

# ==============================================================

# TIMESTAMP
DATE_LABEL=$(date +"%Y-%m-%d %H:%M:%S")
TODAY=$(date +"%Y%m%d")

LOG_FILE="${BACKUP_DIR}/envio_${TODAY}.log"

mkdir -p "${BACKUP_DIR}"

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
    log " STATUS FINAL: FALHA CRITICA"
    log " Log: ${LOG_FILE}"
    log "============================================================"
    exit 99
}

# ==============================================================

log "============================================================"
log " Iniciando envio de backup: ${PG_DB}"
log " Destino: ${SSH_USER}@${SSH_HOST}:${REMOTE_DIR}"
log "============================================================"

# --- Verificar OpenSSH ---
if ! command -v ssh &>/dev/null; then
    log "ERRO: OpenSSH nao encontrado."
    log "  Instale com: sudo apt install openssh-client"
    finalizar_erro
fi

# --- Verificar chave SSH ---
if [ ! -f "${SSH_KEY}" ]; then
    log "ERRO: Chave SSH nao encontrada em ${SSH_KEY}"
    log "  Gere com: ssh-keygen -t ed25519 -C backup_chirpstack-v3"
    log "  Copie ao servidor: ssh-copy-id -p ${SSH_PORT} ${SSH_USER}@${SSH_HOST}"
    log "  Ou manualmente: adicione id_ed25519.pub ao ~/.ssh/authorized_keys no servidor"
    finalizar_erro
fi

# --- Verificar conectividade com o servidor ---
log ""
log "Testando conexao com ${SSH_HOST}:${SSH_PORT}..."
if ! ssh \
    -i "${SSH_KEY}" \
    -p "${SSH_PORT}" \
    -o ConnectTimeout="${CONNECT_TIMEOUT}" \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=accept-new \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    "${SSH_USER}@${SSH_HOST}" "echo OK" &>/dev/null; then
    log "ERRO: Nao foi possivel conectar ao servidor."
    log "  Verifique: host, porta, usuario e se a chave publica esta no servidor."
    finalizar_erro
fi
log "  Conexao OK."

# --- Criar diretorio remoto se nao existir ---
log ""
log "Verificando diretorio remoto..."
if ! ssh \
    -i "${SSH_KEY}" \
    -p "${SSH_PORT}" \
    -o BatchMode=yes \
    "${SSH_USER}@${SSH_HOST}" "mkdir -p ${REMOTE_DIR}" &>/dev/null; then
    log "AVISO: Nao foi possivel criar/verificar o diretorio remoto. Continuando..."
fi

# --- Selecionar arquivos para envio ---
log ""
if [ "${ONLY_TODAY}" -eq 1 ]; then
    log "Buscando arquivos de hoje (${TODAY})..."
    PATTERN="*${TODAY}*"
else
    log "Buscando todos os arquivos de backup..."
    PATTERN="*${PG_DB}*"
fi

COUNT=0
ERRORS=0

# --- Funcao de envio ---
enviar_arquivo() {
    local filepath="$1"
    local filename
    filename=$(basename "${filepath}")

    COUNT=$((COUNT + 1))
    log ""
    log "[${filename}] Enviando..."

    if scp \
        -i "${SSH_KEY}" \
        -P "${SSH_PORT}" \
        -o BatchMode=yes \
        -o StrictHostKeyChecking=accept-new \
        -o ConnectTimeout="${CONNECT_TIMEOUT}" \
        -o ServerAliveInterval=30 \
        "${filepath}" \
        "${SSH_USER}@${SSH_HOST}:${REMOTE_DIR}/" >> "${LOG_FILE}" 2>&1; then
        log "  OK - Enviado com sucesso."
    else
        log "  ERRO - Falha ao enviar ${filename}"
        ERRORS=$((ERRORS + 1))
    fi
}

# --- Enviar arquivos .backup ---
while IFS= read -r -d '' file; do
    enviar_arquivo "${file}"
done < <(find "${BACKUP_DIR}" -maxdepth 1 -name "${PATTERN}.backup" -print0 2>/dev/null)

# --- Enviar arquivos .sql ---
while IFS= read -r -d '' file; do
    enviar_arquivo "${file}"
done < <(find "${BACKUP_DIR}" -maxdepth 1 -name "${PATTERN}.sql" -print0 2>/dev/null)

if [ "${COUNT}" -eq 0 ]; then
    log ""
    log "AVISO: Nenhum arquivo encontrado para enviar com o padrao '${PATTERN}'."
    log "  Verifique se o backup_chirpstack-v3.sh foi executado antes deste script."
    finalizar_erro
fi

# --- Limpeza remota de arquivos antigos ---
if [ "${RETENTION_DAYS}" -gt 0 ]; then
    log ""
    log "Limpando backups remotos com mais de ${RETENTION_DAYS} dia(s)..."
    ssh \
        -i "${SSH_KEY}" \
        -p "${SSH_PORT}" \
        -o BatchMode=yes \
        "${SSH_USER}@${SSH_HOST}" \
        "find ${REMOTE_DIR} -maxdepth 1 \( -name '*.backup' -o -name '*.sql' \) -mtime +${RETENTION_DAYS} -delete 2>/dev/null; echo 'Limpeza OK'" >> "${LOG_FILE}" 2>&1
    log "  Limpeza remota concluida."
fi

# --- Resumo ---
log ""
log "============================================================"
log " Arquivos processados : ${COUNT}"
log " Erros               : ${ERRORS}"

if [ "${ERRORS}" -eq 0 ]; then
    log " STATUS FINAL: SUCESSO"
elif [ "${ERRORS}" -eq "${COUNT}" ]; then
    log " STATUS FINAL: FALHA - todos os envios falharam"
else
    log " STATUS FINAL: PARCIAL - alguns envios falharam"
fi

log " Log: ${LOG_FILE}"
log "============================================================"
exit 0
