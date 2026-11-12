#!/usr/bin/env bash
# =============================================================================
# force_deploy.sh — Force Deploy dos projetos ChirpStack + Homepage
#                  Repositório: AdailSilva/k8s-arm-oci-chirpstack
# -----------------------------------------------------------------------------
# Em vez de alterar os Dockerfiles, grava/atualiza o arquivo ".force-deploy"
# em cada diretório de projeto com data/hora e um ID único. Como o arquivo
# muda a cada execução, o paths-filter do workflow detecta alteração em todos
# os diretórios e dispara o build + deploy de cada job.
#
# Uso:
#   ./force_deploy.sh                    # todos os projetos
#   ./force_deploy.sh homepage consumer  # apenas os que contêm "homepage" ou "consumer"
#   ./force_deploy.sh --no-push          # gera commit, mas não faz push
#   ./force_deploy.sh --dry-run          # só mostra o que seria feito
# =============================================================================
set -euo pipefail

PROJECTS=(
  "00.homepage/app_chirpstack_homepage_frontend"
  "05.chirpstack_consumer/api_chirpstack_consumer_backend"
  "05.chirpstack_consumer/app_chirpstack_consumer_frontend"
)

TRIGGER_FILE=".force-deploy"
DEPLOY_BRANCH="master"
PUSH=true
DRY_RUN=false
FILTERS=()

for arg in "$@"; do
  case "$arg" in
    --no-push) PUSH=false ;;
    --dry-run) DRY_RUN=true ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) FILTERS+=("$arg") ;;
  esac
done

# --- Vai para a raiz do repositório -----------------------------------------
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "❌ Execute dentro do repositório Git."; exit 1; }
cd "$REPO_ROOT"

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CURRENT_BRANCH" != "$DEPLOY_BRANCH" ]]; then
  echo "⚠️  Branch atual: '$CURRENT_BRANCH' (o pipeline dispara em '$DEPLOY_BRANCH')."
  read -r -p "Continuar mesmo assim? [s/N] " ans
  [[ "$ans" =~ ^[sS]$ ]] || exit 1
fi

# --- Seleção dos projetos ----------------------------------------------------
SELECTED=()
for p in "${PROJECTS[@]}"; do
  if [[ ${#FILTERS[@]} -eq 0 ]]; then
    SELECTED+=("$p")
  else
    for f in "${FILTERS[@]}"; do
      [[ "$p" == *"$f"* ]] && { SELECTED+=("$p"); break; }
    done
  fi
done

[[ ${#SELECTED[@]} -gt 0 ]] || { echo "❌ Nenhum projeto corresponde ao filtro."; exit 1; }

# --- Gera os arquivos de gatilho ---------------------------------------------
TIMESTAMP="$(TZ=America/Fortaleza date '+%Y-%m-%d %H:%M:%S %z')"
DEPLOY_ID="$(date +%s)-$RANDOM"
AUTHOR="$(git config user.name || echo desconhecido)"
FILES=()

echo "🚀 Force Deploy — $TIMESTAMP (id: $DEPLOY_ID)"
for p in "${SELECTED[@]}"; do
  if [[ ! -d "$p" ]]; then
    echo "   ⚠️  Ignorado (diretório não existe): $p"; continue
  fi
  FILE="$p/$TRIGGER_FILE"
  FILES+=("$FILE")
  echo "   ✔ $FILE"
  $DRY_RUN && continue
  cat > "$FILE" <<CONTENT
# Arquivo gerado automaticamente por force_deploy.sh
# Qualquer alteração aqui dispara o pipeline (paths-filter) deste projeto.
# Não editar manualmente.
project=$p
deploy_at=$TIMESTAMP
deploy_id=$DEPLOY_ID
author=$AUTHOR
CONTENT
done

[[ ${#FILES[@]} -gt 0 ]] || { echo "❌ Nenhum arquivo gerado."; exit 1; }
$DRY_RUN && { echo "ℹ️  Dry-run: nada foi alterado."; exit 0; }

# --- Commit apenas dos arquivos de gatilho (não leva outras alterações) ------
git add -- "${FILES[@]}"
git commit -m "Force Deploy" -m "deploy_id: $DEPLOY_ID | $TIMESTAMP" -- "${FILES[@]}"

# --- Push ---------------------------------------------------------------------
# O pipeline deste repositório não faz commit de volta no master (só cria as
# tags Git de versão, uma por projeto), mas outra pessoa/máquina pode ter
# enviado commits. Por isso: pull --rebase antes do push, com até 3
# tentativas. --autostash protege alterações locais não commitadas.
if $PUSH; then
  for tentativa in 1 2 3; do
    echo "🔄 Sincronizando com origin/$CURRENT_BRANCH (tentativa $tentativa/3)..."
    if ! git pull --rebase --autostash origin "$CURRENT_BRANCH"; then
      git rebase --abort 2>/dev/null || true
      echo "❌ Conflito ao sincronizar com origin/$CURRENT_BRANCH."
      echo "   O commit 'Force Deploy' continua local. Resolva e rode:"
      echo "   git pull --rebase origin $CURRENT_BRANCH && git push origin $CURRENT_BRANCH"
      exit 1
    fi
    if git push origin "$CURRENT_BRANCH"; then
      echo "✅ Push enviado — acompanhe em GitHub → Actions."
      exit 0
    fi
    echo "⚠️  Push rejeitado (o remoto mudou de novo). Tentando outra vez em 5s..."
    sleep 5
  done
  echo "❌ Push não concluído após 3 tentativas. Rode: git pull --rebase origin $CURRENT_BRANCH && git push origin $CURRENT_BRANCH"
  exit 1
else
  echo "✅ Commit criado (sem push). Rode: git push origin $CURRENT_BRANCH"
fi
