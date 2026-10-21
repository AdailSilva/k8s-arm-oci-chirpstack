#!/usr/bin/env bash
# =============================================================================
# Atualiza o codec (JavaScript) de TODOS os device-profiles do ChirpStack v4,
# direto no PostgreSQL do ChirpStack.
#
# Tabela: device_profile (banco único do v4, normalmente "chirpstack")
#   payload_codec_runtime -> 'JS'   ("JavaScript functions" no frontend)
#   payload_codec_script  -> script ÚNICO com decodeUplink + encodeDownlink
#
# A tabela device_profile_template (templates do repositório de devices)
# NÃO é alterada.
#
# Uso:
#   ./update_codecs_chirpstack_v4.sh                 # lista, faz backup, pede confirmação
#   DRY_RUN=1 ./update_codecs_chirpstack_v4.sh       # só lista (SELECT), não altera nada
#   FILTER='%AU915_1%' ./update_codecs_chirpstack_v4.sh   # só perfis cujo nome casa (ILIKE)
#   NAMESPACE=chirpstack-v4 ./update_codecs_chirpstack_v4.sh  # força o namespace
#   POD_MATCH='^meu-postgres' ./update_codecs_chirpstack_v4.sh # regex do nome do pod
#   PGPORT=5432 ./update_codecs_chirpstack_v4.sh     # força a porta (senão testa 5432/5433)
#   PGDB=chirpstack ./update_codecs_chirpstack_v4.sh # força o banco (senão detecta sozinho)
#   YES=1 ./update_codecs_chirpstack_v4.sh           # não pergunta (CI)
# =============================================================================
set -euo pipefail

# Regex do nome do pod do PostgreSQL do v4. O sufixo (-<hash>-<id>) muda a cada
# recriação do pod; por isso a busca é por padrão, refeita a cada execução.
POD_MATCH="${POD_MATCH:-^chirpstack-v4.*postgres}"
NAMESPACE="${NAMESPACE:-}"
FILTER="${FILTER:-%}"
DRY_RUN="${DRY_RUN:-0}"
YES="${YES:-0}"

# -----------------------------------------------------------------------------
# 1. Localiza o pod (somente pods em Running: ignora pods antigos em rollout)
# -----------------------------------------------------------------------------
NS_ARGS=(-A)
[[ -n "$NAMESPACE" ]] && NS_ARGS=(-n "$NAMESPACE")

read -r FOUND_NS POD < <(kubectl get pods "${NS_ARGS[@]}" \
       --field-selector=status.phase=Running --no-headers \
       -o custom-columns=:metadata.namespace,:metadata.name,:metadata.deletionTimestamp \
     | awk -v p="$POD_MATCH" '$2 ~ p && $3 == "<none>" {print $1, $2; exit}') || true

if [[ -z "${POD:-}" ]]; then
  echo "ERRO: nenhum pod em Running casando com '${POD_MATCH}'." >&2
  echo "      Pods de PostgreSQL no cluster:" >&2
  kubectl get pods -A --no-headers | grep -i postgres >&2 || true
  echo "      Rode com POD_MATCH='^<prefixo-do-pod>'." >&2
  exit 1
fi
NAMESPACE="$FOUND_NS"
echo ">> Pod: ${NAMESPACE}/${POD}"

# Container principal (evita o aviso "Defaulted container" e init containers)
CONTAINER="${CONTAINER:-$(kubectl get pod -n "$NAMESPACE" "$POD" -o jsonpath='{.spec.containers[0].name}')}"

kx() { kubectl exec -n "$NAMESPACE" "$POD" -c "$CONTAINER" -- "$@"; }

PGUSER="${PGUSER:-$(kx printenv POSTGRES_USER 2>/dev/null || echo postgres)}"

# -----------------------------------------------------------------------------
# 2. Porta: usa PGPORT se informado; senão testa 5432 e 5433
# -----------------------------------------------------------------------------
PORT_FOUND=""
for p in ${PGPORT:-} 5432 5433; do
  if kx psql -U "$PGUSER" -d postgres -p "$p" -tAc 'SELECT 1' >/dev/null 2>&1; then
    PORT_FOUND="$p"; break
  fi
done
if [[ -z "$PORT_FOUND" ]]; then
  echo "ERRO: não conectou no Postgres (portas testadas: ${PGPORT:-} 5432 5433). Confira PGUSER/PGPORT." >&2
  exit 1
fi
PGPORT="$PORT_FOUND"

# -----------------------------------------------------------------------------
# 3. Banco: o que tem device_profile COM a coluna payload_codec_script (v4)
# -----------------------------------------------------------------------------
if [[ -z "${PGDB:-}" ]]; then
  echo ">> Procurando o banco do ChirpStack v4..."
  for db in $(kx psql -U "$PGUSER" -d postgres -p "$PGPORT" -tAc \
                "SELECT datname FROM pg_database WHERE NOT datistemplate ORDER BY datname"); do
    ok="$(kx psql -U "$PGUSER" -d "$db" -p "$PGPORT" -tAc \
          "SELECT 1 FROM information_schema.columns
            WHERE table_schema='public' AND table_name='device_profile'
              AND column_name='payload_codec_script' LIMIT 1" 2>/dev/null || true)"
    echo "   - ${db}: $([[ "$ok" == "1" ]] && echo 'device_profile do v4 encontrada' || echo 'não')"
    if [[ "$ok" == "1" && -z "${PGDB:-}" ]]; then
      PGDB="$db"
    fi
  done
fi

if [[ -z "${PGDB:-}" ]]; then
  echo "ERRO: nenhum banco com device_profile.payload_codec_script neste servidor." >&2
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
# 4. SELECT: todos os device-profiles (com tenant) e o codec atual
# -----------------------------------------------------------------------------
echo
echo "== Device-profiles encontrados (filtro: ${FILTER}) =="
psql_exec <<'SQL'
SELECT dp.id,
       t.name                         AS tenant,
       dp.name,
       dp.region,
       dp.payload_codec_runtime       AS codec,
       length(dp.payload_codec_script) AS script_chars,
       dp.updated_at
  FROM device_profile dp
  JOIN tenant t ON t.id = dp.tenant_id
 WHERE dp.name ILIKE :'filter'
 ORDER BY t.name, dp.name;
SQL

if [[ "$DRY_RUN" == "1" ]]; then
  echo ">> DRY_RUN=1: nada foi alterado."
  exit 0
fi

# -----------------------------------------------------------------------------
# 5. Backup dos codecs atuais (CSV local)
# -----------------------------------------------------------------------------
BACKUP="device_profile_codecs_v4_backup_$(date +%Y%m%d_%H%M%S).csv"
psql_exec -q <<'SQL' > "$BACKUP"
COPY (
  SELECT id, tenant_id, name, payload_codec_runtime, payload_codec_script, updated_at
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
# 6. UPDATE (transação única). Script em dollar-quoting: sem escapes de aspas.
# -----------------------------------------------------------------------------
psql_exec <<'SQL'
BEGIN;

UPDATE device_profile
   SET payload_codec_runtime = 'JS',
       payload_codec_script  = $codec$
/**
 * Codec ChirpStack v4 — payload ASCII
 *
 * Uplink : bytes -> { text, length, hex, fPort }
 *   ex.: "QWRhaWxTaWx2YS1Jb1Q=" -> { "text": "AdailSilva-IoT", ... }
 * Downlink: { "text": "LED ON" } -> bytes ASCII
 */

function decodeUplink(input) {
  var bytes = input.bytes || [];
  var warnings = [];

  if (bytes.length === 0) {
    return { errors: ["payload vazio"] };
  }

  var text = "";
  var hex = [];
  var nonPrintable = 0;

  for (var i = 0; i < bytes.length; i++) {
    var b = bytes[i] & 0xff;
    hex.push((b < 16 ? "0" : "") + b.toString(16));

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

  if (nonPrintable > 0) {
    warnings.push(nonPrintable + " byte(s) fora do ASCII imprimível substituído(s) por '?'");
  }

  return {
    data: {
      text: text,
      length: bytes.length,
      hex: hex.join(""),
      fPort: input.fPort
    },
    warnings: warnings
  };
}

function encodeDownlink(input) {
  var text = input.data && input.data.text;

  if (typeof text !== "string" || text.length === 0) {
    return { errors: ["informe o campo 'text' (string não vazia)"] };
  }

  var bytes = [];
  for (var i = 0; i < text.length; i++) {
    var c = text.charCodeAt(i);
    if (c > 0x7e) {
      return { errors: ["caractere não ASCII na posição " + i + ": '" + text.charAt(i) + "'"] };
    }
    bytes.push(c);
  }

  return { bytes: bytes };
}
$codec$,
       updated_at = now()
 WHERE name ILIKE :'filter'
RETURNING name AS atualizado;

COMMIT;
SQL

# -----------------------------------------------------------------------------
# 7. Conferência
# -----------------------------------------------------------------------------
echo
echo "== Estado após o update =="
psql_exec <<'SQL'
SELECT t.name AS tenant,
       dp.name,
       dp.payload_codec_runtime        AS codec,
       length(dp.payload_codec_script) AS script_chars,
       dp.updated_at
  FROM device_profile dp
  JOIN tenant t ON t.id = dp.tenant_id
 WHERE dp.name ILIKE :'filter'
 ORDER BY t.name, dp.name;
SQL

echo
echo ">> Pronto. Para reverter, use o backup: ${BACKUP}"
