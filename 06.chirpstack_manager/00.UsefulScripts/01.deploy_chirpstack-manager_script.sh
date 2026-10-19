#!/bin/bash
# =====================================================================
#  Deploy do ChirpStack Manager (namespace chirpstack-manager).
#  O Secret NÃO é aplicado por aqui: o arquivo 02 é só exemplo, com
#  valores "trocar". Crie o Secret real uma vez (veja o README) e este
#  script apenas confere que ele existe.
# =====================================================================
set -euo pipefail

DIR=~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/06.chirpstack_manager/kubernetes
NS=chirpstack-manager

echo "Start ChirpStack-Manager pod/service deploy..."

kubectl apply -f "$DIR/01.create__Namespace.yaml"

if ! kubectl -n "$NS" get secret chirpstack-manager-secrets >/dev/null 2>&1; then
    echo "ERRO: o Secret chirpstack-manager-secrets não existe no namespace $NS."
    echo "Crie-o antes (README > Kubernetes) e rode este script de novo."
    exit 1
fi

kubectl apply -f "$DIR/03.chirpstack-manager__ConfigMap.yaml"

kubectl apply -f "$DIR/04.chirpstack-manager-postgresql__PersistentVolumeClaim.yaml"
kubectl apply -f "$DIR/05.chirpstack-manager-postgresql__StatefulSet.yaml"
kubectl apply -f "$DIR/06.chirpstack-manager-postgresql__Service.yaml"
kubectl -n "$NS" rollout status statefulset/chirpstack-manager-postgres --timeout=180s

kubectl apply -f "$DIR/07.chirpstack-manager-backend__PersistentVolumeClaim.yaml"
kubectl apply -f "$DIR/08.chirpstack-manager-backend__Deployment.yaml"
kubectl apply -f "$DIR/09.chirpstack-manager-backend__Service.yaml"

kubectl apply -f "$DIR/10.chirpstack-manager-frontend__Deployment.yaml"
kubectl apply -f "$DIR/11.chirpstack-manager-frontend__Service.yaml"

kubectl apply -f "$DIR/12.chirpstack-manager__Ingress.yaml"
kubectl apply -f "$DIR/13.chirpstack-manager-restauracao__Ingress.yaml"

kubectl -n "$NS" rollout status deployment/chirpstack-manager-api --timeout=300s
kubectl -n "$NS" rollout status deployment/chirpstack-manager-web --timeout=180s

echo "Deploy completed successfully into the ChirpStack-Manager pod/service."
