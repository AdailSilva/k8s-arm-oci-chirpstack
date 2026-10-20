#!/bin/bash
# =====================================================================
#  Restaura o banco do ChirpStack Manager a partir de um arquivo .backup
#  desta máquina, direto no pod do PostgreSQL. Para recuperação quando a
#  tela de restauração não está disponível (no dia a dia, prefira a tela).
#
#  Uso: ./04.restore_api-chirpstack-manager-backend_script.sh caminho/do/arquivo.backup
#
#  Passos: para a API, restaura em transação única sobre um schema limpo
#  (se falhar, nada muda) e sobe a API de novo (o Flyway aplica as
#  migrações pendentes). Todos os usuários precisam entrar novamente.
# =====================================================================
set -euo pipefail

NS=chirpstack-manager
POD=chirpstack-manager-postgres-0
ARQ=${1:?Informe o arquivo .backup}

[ -f "$ARQ" ] || { echo "Arquivo não encontrado: $ARQ"; exit 1; }
[ "$(head -c 5 "$ARQ")" = "PGDMP" ] || { echo "O arquivo não é um dump do pg_dump (formato custom)."; exit 1; }

read -r -p "Isto SUBSTITUI todo o banco do ChirpStack Manager. Digite RESTAURAR para continuar: " ok
[ "$ok" = "RESTAURAR" ] || { echo "Cancelado."; exit 0; }

echo "Parando a API..."
kubectl -n "$NS" scale deployment/chirpstack-manager-api --replicas=0
kubectl -n "$NS" wait --for=delete pod -l app=chirpstack-manager-api --timeout=120s || true

echo "Copiando o arquivo para o pod..."
kubectl -n "$NS" cp "$ARQ" "$POD:/tmp/restauracao.backup"

echo "Restaurando..."
if kubectl -n "$NS" exec "$POD" -- sh -c '
    set -e
    pg_restore --no-owner --no-privileges --file=/tmp/restauracao.sql /tmp/restauracao.backup
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" --quiet --single-transaction --set=ON_ERROR_STOP=1 \
         --command="DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;" \
         --file=/tmp/restauracao.sql \
         --command="DO \$\$ BEGIN
             IF to_regclass('"'"'public.tb_sessao'"'"') IS NOT NULL THEN
                 UPDATE public.tb_sessao SET encerrada_em = now(), motivo_encerramento = '"'"'RESTAURACAO_BACKUP'"'"',
                        encerrada_por = '"'"'script de restauração'"'"' WHERE encerrada_em IS NULL;
             END IF;
             UPDATE public.tb_refresh_token SET revogado = TRUE WHERE revogado = FALSE;
         END \$\$;" > /dev/null
    rm -f /tmp/restauracao.backup /tmp/restauracao.sql'; then
    echo "Banco restaurado."
else
    kubectl -n "$NS" exec "$POD" -- rm -f /tmp/restauracao.backup /tmp/restauracao.sql || true
    echo "ERRO na restauração: o banco não foi alterado."
fi

echo "Subindo a API..."
kubectl -n "$NS" scale deployment/chirpstack-manager-api --replicas=1
kubectl -n "$NS" rollout status deployment/chirpstack-manager-api --timeout=300s
