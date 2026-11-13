#!/usr/bin/env bash
# =============================================================================
# sync_terraform_state.sh — Terraform/OpenTofu compartilhado entre os 5 repositórios
# -----------------------------------------------------------------------------
# Os 5 repositórios (Standart, ChirpStack, CSLab, 3T Sensors e ASE Soluções)
# descrevem o MESMO cluster e têm os MESMOS arquivos .tf. O state é local e
# copiado à mão: aplique em UM repositório e copie o state para os outros 4.
# Arquivo idêntico nos 5 repositórios, ao lado do force_deploy.sh.
#
# Uso (na raiz de qualquer um dos repositórios):
#   ./sync_terraform_state.sh importar   # traz para o state os repositórios OCIR que já existem
#   ./sync_terraform_state.sh plan       # plano completo (com refresh)
#   ./sync_terraform_state.sh apply      # aplica (pede confirmação)
#   ./sync_terraform_state.sh refresh    # só atualiza o state com a OCI (apply -refresh-only)
#   ./sync_terraform_state.sh copiar     # copia o state DESTE repositório para os outros 4
#   ./sync_terraform_state.sh conferir   # plan sem refresh nos 5: todos devem dar "No changes"
#   ./sync_terraform_state.sh tudo       # importar + apply + copiar + conferir
#
# Opções:
#   --parallelism=N   paralelismo do tofu/terraform (padrão 1)
#   --dry-run         em "copiar": só mostra o que seria copiado
#   --forcar          em "copiar": copia mesmo que algum destino tenha state MAIS NOVO
#   --raiz=DIR        pasta que contém os 5 repositórios (padrão: a pasta acima deste)
# =============================================================================
set -euo pipefail

REPOS=(
  "01.k8s-on-arm-oci-always-free_standart"
  "03.k8s-on-arm-oci-always-free_chirpstack"
  "04.k8s-on-arm-oci-always-free_cslab"
  "05.k8s-on-arm-oci-always-free_3t_sensors"
  "06.k8s-on-arm-oci-always-free_ase_solucoes"
)
ARQUIVOS_STATE=("terraform.tfstate" "terraform.tfstate.backup")
MODULO_OCIR="module.oci-infra_ci_cd"
TF_OCIR="oci_artifacts_container_repository/oci_artifacts_container_repository.tf"

ACAO=""
PARALLELISM=1
DRY_RUN=false
FORCAR=false
RAIZ=""

for arg in "$@"; do
  case "$arg" in
    --parallelism=*) PARALLELISM="${arg#*=}" ;;
    --dry-run)       DRY_RUN=true ;;
    --forcar)        FORCAR=true ;;
    --raiz=*)        RAIZ="${arg#*=}" ;;
    -h|--help)       sed -n '2,25p' "$0"; exit 0 ;;
    -*)              echo "❌ Opção desconhecida: $arg"; exit 1 ;;
    *)               ACAO="$arg" ;;
  esac
done
[ -n "$ACAO" ] || { sed -n '2,25p' "$0"; exit 1; }

# --- Raiz do repositório e pasta dos 5 repositórios ---------------------------
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$AQUI"
[ -f main.tf ] || { echo "❌ main.tf não encontrado em $AQUI — rode na raiz do repositório."; exit 1; }
ESTE="$(basename "$AQUI")"
RAIZ="${RAIZ:-$(dirname "$AQUI")}"

# --- tofu ou terraform --------------------------------------------------------
if command -v tofu >/dev/null 2>&1; then TF=tofu
elif command -v terraform >/dev/null 2>&1; then TF=terraform
else echo "❌ Nem tofu nem terraform no PATH."; exit 1; fi

# --- OCI CLI (o runner instala em /home/ubuntu/bin) ----------------------------
achar_oci() {
  local c
  for c in "${OCI_CLI:-}" "$(command -v oci 2>/dev/null || true)" "$HOME/bin/oci" /home/ubuntu/bin/oci; do
    [ -n "$c" ] && [ -x "$c" ] && { echo "$c"; return 0; }
  done
  return 1
}

serial_de() {   # serial do state (0 se não existir)
  [ -f "$1" ] || { echo 0; return; }
  sed -n 's/^[[:space:]]*"serial":[[:space:]]*\([0-9]*\).*/\1/p' "$1" | head -1
}
lineage_de() {
  [ -f "$1" ] || { echo ""; return; }
  sed -n 's/^[[:space:]]*"lineage":[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -1
}

# =============================================================================
acao_importar() {
  echo ">> Importando repositórios OCIR que já existem na OCI ($ESTE)"
  local OCI TENANCY NOME END OCID NO_STATE
  OCI="$(achar_oci)" || { echo "❌ OCI CLI não encontrado (defina OCI_CLI=/caminho/do/oci)."; exit 1; }
  TENANCY="$(sed -n 's/^tenancy[[:space:]]*=[[:space:]]*//p' ~/.oci/config | head -1)"
  [ -n "$TENANCY" ] || { echo "❌ 'tenancy=' não encontrado em ~/.oci/config."; exit 1; }
  NO_STATE="$($TF state list 2>/dev/null || true)"

  for NOME in $(sed -n 's/^resource "oci_artifacts_container_repository" "\([^"]*\)".*/\1/p' "$TF_OCIR"); do
    END="${MODULO_OCIR}.oci_artifacts_container_repository.${NOME}"
    if grep -qx "$END" <<<"$NO_STATE"; then
      echo "   ok       $NOME"
      continue
    fi
    # Erro do OCI CLI aparece (não é escondido): é a causa mais comum de import que não acontece.
    OCID="$("$OCI" artifacts container repository list --compartment-id "$TENANCY" \
              --compartment-id-in-subtree true --display-name "$NOME" --all \
              --query 'data.items[0].id' --raw-output)"
    if [ -n "$OCID" ] && [ "$OCID" != "null" ]; then
      echo "   importar $NOME -> $OCID"
      $TF import -input=false "$END" "$OCID"
    else
      echo "   criar    $NOME (não existe na OCI — o apply cria)"
    fi
  done
}

acao_plan()    { $TF plan  -parallelism="$PARALLELISM"; }
acao_apply()   { $TF apply -parallelism="$PARALLELISM"; }
acao_refresh() { $TF apply -refresh-only -parallelism="$PARALLELISM"; }

acao_copiar() {
  local origem="$AQUI/terraform.tfstate" s_origem l_origem d destino s_dest l_dest bloqueio=false
  [ -f "$origem" ] || { echo "❌ $origem não existe."; exit 1; }
  s_origem="$(serial_de "$origem")"; l_origem="$(lineage_de "$origem")"
  echo ">> Origem: $ESTE (serial $s_origem, lineage ${l_origem:0:8})"

  # Conferência antes de copiar qualquer coisa
  for d in "${REPOS[@]}"; do
    [ "$d" = "$ESTE" ] && continue
    destino="$RAIZ/$d"
    if [ ! -d "$destino" ]; then echo "   ⚠️  $d: pasta não encontrada em $RAIZ — pulando"; continue; fi
    s_dest="$(serial_de "$destino/terraform.tfstate")"; l_dest="$(lineage_de "$destino/terraform.tfstate")"
    if [ -n "$l_dest" ] && [ "$l_dest" != "$l_origem" ]; then
      echo "   ❌ $d: lineage diferente (${l_dest:0:8}) — não é o mesmo state."; bloqueio=true
    elif [ "${s_dest:-0}" -gt "${s_origem:-0}" ]; then
      echo "   ❌ $d: state MAIS NOVO lá (serial $s_dest > $s_origem) — aplicaram por lá?"; bloqueio=true
    else
      echo "   ok  $d (serial $s_dest -> $s_origem)"
    fi
  done
  if $bloqueio && ! $FORCAR; then
    echo "❌ Nada copiado. Confira o repositório indicado; para copiar mesmo assim, use --forcar."
    exit 1
  fi
  $DRY_RUN && { echo ">> --dry-run: nada copiado."; return 0; }

  for d in "${REPOS[@]}"; do
    [ "$d" = "$ESTE" ] && continue
    destino="$RAIZ/$d"; [ -d "$destino" ] || continue
    for f in "${ARQUIVOS_STATE[@]}"; do
      [ -f "$AQUI/$f" ] && cp -p "$AQUI/$f" "$destino/$f"
    done
    echo "   copiado -> $d"
  done
  echo ">> State sincronizado. Os arquivos estão no .gitignore: nada vai para o Git."
}

acao_conferir() {
  # Sem refresh: compara os .tf com o state (rápido e sem tocar na OCI).
  # Arquivos e state iguais nos 5 => "No changes" nos 5.
  local d destino rc falhas=0
  echo ">> Conferindo os 5 repositórios (plan -refresh=false)"
  for d in "${REPOS[@]}"; do
    destino="$RAIZ/$d"; [ -d "$destino" ] || { echo "   ⚠️  $d: não encontrado"; continue; }
    rc=0
    (cd "$destino" && $TF plan -refresh=false -lock=false -detailed-exitcode -input=false >/dev/null 2>&1) || rc=$?
    case "$rc" in
      0) echo "   ok        $d (No changes, serial $(serial_de "$destino/terraform.tfstate"))" ;;
      2) echo "   ⚠️  muda  $d — rode '$TF plan' lá para ver"; falhas=$((falhas+1)) ;;
      *) echo "   ❌ erro   $d — rode '$TF plan' lá (falta '$TF init'?)"; falhas=$((falhas+1)) ;;
    esac
  done
  [ "$falhas" -eq 0 ] || exit 1
}

case "$ACAO" in
  importar) acao_importar ;;
  plan)     acao_plan ;;
  apply)    acao_apply ;;
  refresh)  acao_refresh ;;
  copiar)   acao_copiar ;;
  conferir) acao_conferir ;;
  tudo)     acao_importar; acao_apply; acao_copiar; acao_conferir ;;
  *)        echo "❌ Ação desconhecida: $ACAO"; sed -n '2,25p' "$0"; exit 1 ;;
esac
