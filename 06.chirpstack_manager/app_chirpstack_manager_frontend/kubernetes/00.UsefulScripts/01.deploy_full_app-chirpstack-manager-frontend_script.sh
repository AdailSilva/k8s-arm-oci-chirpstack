#!/bin/bash

# Build Project
# docker buildx build --platform 'linux/arm64' --tag gru.ocir.io/griszz3l82u1/app-chirpstack-manager-frontend_platform_linux-arm64:latest --no-cache --push .


# ChirpStack-Manager (frontend) deployment on K8S.
# Rode depois do deploy do backend: o NGINX do frontend encaminha /api para o
# Service chirpstack-manager-api:8083.

set -euo pipefail

K8S_DIR=~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/06.chirpstack_manager/app_chirpstack_manager_frontend/kubernetes
NS=chirpstack-manager

echo "Start deploying the ChirpStack-Manager frontend pod/service."

kubectl apply -f $K8S_DIR/01.create__Namespace.yaml
kubectl apply -f $K8S_DIR/02.app-chirpstack-manager-frontend__Deployment.yaml
kubectl apply -f $K8S_DIR/03.app-chirpstack-manager-frontend__Service.yaml

# Ingress principal (2 MB) e o da restauracao de backup (512 MB, so nessa rota).
kubectl apply -f $K8S_DIR/06.app-chirpstack-manager__Ingress.yaml
kubectl apply -f $K8S_DIR/07.app-chirpstack-manager-restauracao__Ingress.yaml

echo "Waiting for the ChirpStack-Manager frontend..."
kubectl -n $NS rollout status deployment/chirpstack-manager-web --timeout=300s

echo "Successfully completed deployment of ChirpStack-Manager frontend pod/service."
