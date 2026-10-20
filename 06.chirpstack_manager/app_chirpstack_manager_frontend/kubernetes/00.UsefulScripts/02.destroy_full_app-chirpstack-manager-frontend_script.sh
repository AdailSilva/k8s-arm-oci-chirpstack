#!/bin/bash

# ChirpStack-Manager (frontend) destruction on K8S.
# O namespace NAO e apagado aqui: ele tambem guarda o banco e os backups do
# backend (use o destroy do backend com --tudo para apagar os dados).

set -uo pipefail

K8S_DIR=~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/06.chirpstack_manager/app_chirpstack_manager_frontend/kubernetes

echo "Start destroying ChirpStack-Manager frontend pod/service."

kubectl delete --ignore-not-found -f $K8S_DIR/05.app-chirpstack-manager-restauracao__Ingress.yaml
kubectl delete --ignore-not-found -f $K8S_DIR/04.app-chirpstack-manager__Ingress.yaml
kubectl delete --ignore-not-found -f $K8S_DIR/03.app-chirpstack-manager-frontend__Service.yaml
kubectl delete --ignore-not-found -f $K8S_DIR/02.app-chirpstack-manager-frontend__Deployment.yaml

echo "Successfully completed destruction of ChirpStack-Manager frontend pod/service."
