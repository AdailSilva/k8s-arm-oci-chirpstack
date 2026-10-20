#!/bin/bash

# Build Project
# docker buildx build --platform 'linux/arm64' --tag gru.ocir.io/griszz3l82u1/chirpstack-manager-api:0.1.0 --no-cache --push .


# ChirpStack-Manager (backend) deployment on K8S.
#
# Ordem: Namespace -> confere o Secret (criado a mao, uma vez) -> ConfigMap ->
# PostgreSQL (volume, StatefulSet, Service) -> espera o banco ficar Ready ->
# volume de backups -> backend -> Service.
# As migracoes rodam no boot da API (Flyway). Frontend e Ingress ficam em
# app_chirpstack_manager_frontend/kubernetes (deploy do frontend depois deste).

set -euo pipefail

K8S_DIR=~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/06.chirpstack_manager/api_chirpstack_manager_backend/kubernetes
NS=chirpstack-manager

echo "Start deploying the ChirpStack-Manager backend pod/service."

# ------------------------------------------------------------------------------
# 01 -- Namespace.
# ------------------------------------------------------------------------------
kubectl apply -f $K8S_DIR/01.create__Namespace.yaml

# ------------------------------------------------------------------------------
# 02 -- Secret. O arquivo e so um EXEMPLO (valores "trocar"): o Secret real e
# criado a mao, uma vez (comando no cabecalho do 02). Sem ele nem o PostgreSQL
# sobe, entao o deploy para aqui com a instrucao.
# ------------------------------------------------------------------------------
if ! kubectl -n $NS get secret chirpstack-manager-secrets >/dev/null 2>&1; then
  echo ""
  echo ">> ERRO: Secret chirpstack-manager-secrets nao existe no namespace $NS."
  echo ">>       Crie-o antes (comando completo no cabecalho de:"
  echo ">>       $K8S_DIR/02.api-chirpstack-manager__Secret_Example.yaml)"
  exit 1
fi

for chave in CHIRPSTACK_API_TOKEN APP_JWT_SECRET APP_ADMIN_PASSWORD DB_PASSWORD; do
  if [ -z "$(kubectl -n $NS get secret chirpstack-manager-secrets -o jsonpath="{.data.$chave}" 2>/dev/null)" ]; then
    echo ">> ERRO: o Secret chirpstack-manager-secrets nao tem a chave $chave."
    exit 1
  fi
done

# ------------------------------------------------------------------------------
# 03 -- ConfigMap (variaveis nao sensiveis; SPRING_PROFILES_ACTIVE=production).
# ------------------------------------------------------------------------------
kubectl apply -f $K8S_DIR/03.api-chirpstack-manager__ConfigMap.yaml

# ------------------------------------------------------------------------------
# 04 a 06 -- PostgreSQL PROPRIO do ChirpStack-Manager.
# ------------------------------------------------------------------------------
kubectl apply -f $K8S_DIR/04.api-chirpstack-manager-postgresql__PersistentVolumeClaim.yaml
kubectl apply -f $K8S_DIR/05.api-chirpstack-manager-postgresql__StatefulSet.yaml
kubectl apply -f $K8S_DIR/06.api-chirpstack-manager-postgresql__Service.yaml

echo "Waiting for Postgres to become available to start ChirpStack-Manager backend..."
kubectl -n $NS rollout status statefulset/chirpstack-manager-postgres --timeout=300s

# ------------------------------------------------------------------------------
# 07 a 09 -- Volume de backups, backend e Service.
# ------------------------------------------------------------------------------
kubectl apply -f $K8S_DIR/07.api-chirpstack-manager-backend__PersistentVolumeClaim.yaml
kubectl apply -f $K8S_DIR/08.api-chirpstack-manager-backend__Deployment.yaml
kubectl apply -f $K8S_DIR/09.api-chirpstack-manager-backend__Service.yaml

echo "Waiting for the ChirpStack-Manager backend..."
kubectl -n $NS rollout status deployment/chirpstack-manager-api --timeout=600s

echo "Successfully completed deployment of ChirpStack-Manager backend pod/service."
