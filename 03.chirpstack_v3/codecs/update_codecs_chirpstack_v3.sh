#!/usr/bin/env bash
# =============================================================================
# Atualiza o codec (Custom JavaScript) de TODOS os device-profiles do
# ChirpStack v3, direto no PostgreSQL do Application Server.
#
# Tabela: device_profile (banco do AS)
#   payload_codec          -> 'CUSTOM_JS'
#   payload_decoder_script -> função Decode (campo "Decoder" do frontend)
#   payload_encoder_script -> função Encode (campo "Encoder" do frontend)
#
# Uso:
#   ./update_codecs_chirpstack_v3.sh                 # lista, faz backup, pede confirmação
#   DRY_RUN=1 ./update_codecs_chirpstack_v3.sh       # só lista (SELECT), não altera nada
#   FILTER='%AU915_1%' ./update_codecs_chirpstack_v3.sh   # só perfis cujo nome casa (ILIKE)
#   NAMESPACE=chirpstack ./update_codecs_chirpstack_v3.sh  # força o namespace
#   YES=1 ./update_codecs_chirpstack_v3.sh           # não pergunta (CI)
#   PGPORT=5433 ./update_codecs_chirpstack_v3.sh     # porta do Postgres do AS (padrão 5433)
#   PGDB=chirpstack_as ./update_codecs_chirpstack_v3.sh   # força o banco (senão detecta sozinho)
# =============================================================================
set -euo pipefail

POD_PREFIX="${POD_PREFIX:-chirpstack-v3-as-postgresql-deployment}"
NAMESPACE="${NAMESPACE:-}"
FILTER="${FILTER:-%}"
DRY_RUN="${DRY_RUN:-0}"
YES="${YES:-0}"

# -----------------------------------------------------------------------------
# 1. Localiza o pod do PostgreSQL do AS (o sufixo do nome muda a cada rollout)
# -----------------------------------------------------------------------------
if [[ -n "$NAMESPACE" ]]; then
  POD="$(kubectl get pods -n "$NAMESPACE" --no-headers -o custom-columns=:metadata.name \
         | grep "^${POD_PREFIX}" | head -n1 || true)"
else
  read -r NAMESPACE POD < <(kubectl get pods -A --no-headers \
         -o custom-columns=:metadata.namespace,:metadata.name \
         | awk -v p="^${POD_PREFIX}" '$2 ~ p {print $1, $2; exit}') || true
fi

if [[ -z "${POD:-}" ]]; then
  echo "ERRO: nenhum pod com prefixo '${POD_PREFIX}' encontrado." >&2
  exit 1
fi
echo ">> Pod: ${NAMESPACE}/${POD}"

# Container principal do pod (evita o aviso "Defaulted container ..." e o init container)
CONTAINER="${CONTAINER:-$(kubectl get pod -n "$NAMESPACE" "$POD" -o jsonpath='{.spec.containers[0].name}')}"

kx() { kubectl exec -n "$NAMESPACE" "$POD" -c "$CONTAINER" -- "$@"; }

# Usuário: variável do container ou "postgres"
PGUSER="${PGUSER:-$(kx printenv POSTGRES_USER 2>/dev/null || echo postgres)}"

# Porta do PostgreSQL do Application Server (seu ambiente: 5433).
# Se dentro do container ele escutar em 5432 (e 5433 for só a porta do
# Service), o script detecta e cai para 5432.
PGPORT="${PGPORT:-5433}"
if ! kx psql -U "$PGUSER" -d postgres -p "$PGPORT" -tAc 'SELECT 1' >/dev/null 2>&1; then
  if kx psql -U "$PGUSER" -d postgres -p 5432 -tAc 'SELECT 1' >/dev/null 2>&1; then
    echo ">> Porta ${PGPORT} não responde dentro do container; usando 5432."
    PGPORT=5432
  else
    echo "ERRO: não conectou no Postgres do AS (porta ${PGPORT} nem 5432). Confira PGUSER/PGPORT." >&2
    exit 1
  fi
fi

# Banco: procura, entre todos os bancos do servidor, o que tem a tabela
# device_profile COM a coluna payload_codec (assinatura do Application Server).
if [[ -z "${PGDB:-}" ]]; then
  echo ">> Procurando o banco do Application Server..."
  for db in $(kx psql -U "$PGUSER" -d postgres -p "$PGPORT" -tAc \
                "SELECT datname FROM pg_database WHERE NOT datistemplate ORDER BY datname"); do
    ok="$(kx psql -U "$PGUSER" -d "$db" -p "$PGPORT" -tAc \
          "SELECT 1 FROM information_schema.columns
            WHERE table_schema='public' AND table_name='device_profile'
              AND column_name='payload_codec' LIMIT 1" 2>/dev/null || true)"
    echo "   - ${db}: $([[ "$ok" == "1" ]] && echo 'device_profile do AS encontrada' || echo 'não')"
    if [[ "$ok" == "1" && -z "${PGDB:-}" ]]; then
      PGDB="$db"
    fi
  done
fi

if [[ -z "${PGDB:-}" ]]; then
  echo "ERRO: nenhum banco com a tabela device_profile (payload_codec) neste servidor." >&2
  echo "      Bancos existentes:" >&2
  kx psql -U "$PGUSER" -d postgres -p "$PGPORT" -tAc \
     "SELECT '        ' || datname FROM pg_database WHERE NOT datistemplate" >&2
  echo "      Rode com PGDB=<nome> se souber qual é." >&2
  exit 1
fi
echo ">> Banco: ${PGDB} (usuário ${PGUSER}, porta ${PGPORT}, container ${CONTAINER})"

psql_exec() {
  kubectl exec -i -n "$NAMESPACE" "$POD" -c "$CONTAINER" -- \
    psql -U "$PGUSER" -d "$PGDB" -p "$PGPORT" -v ON_ERROR_STOP=1 -v filter="$FILTER" "$@"
}

# -----------------------------------------------------------------------------
# 2. SELECT: todos os device-profiles e o estado atual do codec
# -----------------------------------------------------------------------------
echo
echo "== Device-profiles encontrados (filtro: ${FILTER}) =="
psql_exec <<'SQL'
SELECT device_profile_id,
       name,
       COALESCE(NULLIF(payload_codec, ''), '(nenhum)')  AS codec,
       length(payload_decoder_script)                   AS decoder_chars,
       length(payload_encoder_script)                   AS encoder_chars,
       updated_at
  FROM device_profile
 WHERE name ILIKE :'filter'
 ORDER BY name;
SQL

if [[ "$DRY_RUN" == "1" ]]; then
  echo ">> DRY_RUN=1: nada foi alterado."
  exit 0
fi

# -----------------------------------------------------------------------------
# 3. Backup dos codecs atuais (CSV local)
# -----------------------------------------------------------------------------
BACKUP="device_profile_codecs_backup_$(date +%Y%m%d_%H%M%S).csv"
psql_exec -q <<'SQL' > "$BACKUP"
COPY (
  SELECT device_profile_id, name, payload_codec,
         payload_decoder_script, payload_encoder_script, updated_at
    FROM device_profile
   ORDER BY name
) TO STDOUT WITH CSV HEADER;
SQL
echo
echo ">> Backup salvo em: ${BACKUP}"

if [[ "$YES" != "1" ]]; then
  read -r -p "Aplicar o codec ASCII em todos os perfis listados acima? [s/N] " ans
  [[ "$ans" =~ ^[sSyY]$ ]] || { echo "Cancelado."; exit 0; }
fi

# -----------------------------------------------------------------------------
# 4. UPDATE (transação única). Scripts em dollar-quoting: sem escapes de aspas.
# -----------------------------------------------------------------------------
psql_exec <<'SQL'
BEGIN;

UPDATE device_profile
   SET payload_codec = 'CUSTOM_JS',

       payload_decoder_script = $decoder$
// Codec ASCII — ChirpStack v3 (otto / ES5)
// Uplink: bytes -> { text, length, hex, fPort }
function Decode(fPort, bytes, variables) {
  if (!bytes || bytes.length === 0) {
    throw new Error("payload vazio");
  }

  var text = "";
  var hex = "";
  var nonPrintable = 0;

  for (var i = 0; i < bytes.length; i++) {
    var b = bytes[i] & 0xff;
    hex += (b < 16 ? "0" : "") + b.toString(16);

    if (b >= 0x20 && b <= 0x7e) {
      text += String.fromCharCode(b);          // ASCII imprimível
    } else if (b === 0x0a || b === 0x0d || b === 0x09) {
      text += String.fromCharCode(b);          // \n \r \t
    } else if (b === 0x00 && i === bytes.length - 1) {
      // '\0' final (string C): ignora
    } else {
      text += "?";
      nonPrintable++;
    }
  }

  var result = { text: text, length: bytes.length, hex: hex, fPort: fPort };

  if (nonPrintable > 0) {
    result.warning = nonPrintable + " byte(s) fora do ASCII imprimível substituído(s) por '?'";
  }

  return result;
}
$decoder$,

       payload_encoder_script = $encoder$
// Codec ASCII — ChirpStack v3 (otto / ES5)
// Downlink: { "text": "LED ON" } -> bytes
function Encode(fPort, obj, variables) {
  var text = obj && obj.text;

  if (typeof text !== "string" || text.length === 0) {
    throw new Error("informe o campo 'text' (string não vazia)");
  }

  var bytes = [];
  for (var i = 0; i < text.length; i++) {
    var c = text.charCodeAt(i);
    if (c > 0x7e) {
      throw new Error("caractere não ASCII na posição " + i + ": '" + text.charAt(i) + "'");
    }
    bytes.push(c);
  }

  return bytes;
}
$encoder$,

       updated_at = now()
 WHERE name ILIKE :'filter'
RETURNING name AS atualizado;

COMMIT;
SQL

# -----------------------------------------------------------------------------
# 5. Conferência
# -----------------------------------------------------------------------------
echo
echo "== Estado após o update =="
psql_exec <<'SQL'
SELECT name,
       payload_codec,
       length(payload_decoder_script) AS decoder_chars,
       length(payload_encoder_script) AS encoder_chars,
       updated_at
  FROM device_profile
 WHERE name ILIKE :'filter'
 ORDER BY name;
SQL

echo
echo ">> Pronto. Para reverter, use o backup: ${BACKUP}"
