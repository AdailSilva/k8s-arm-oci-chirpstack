#!/bin/bash

# ChirpStack-Manager (backend) destruction on K8S.
#
# Os VOLUMES (banco e backups), o Secret, o ConfigMap e o namespace sao mantidos
# por padrao: apagar o namespace apaga junto os PVCs, ou seja, o banco do painel
# e todos os backups do servidor.
#
# Para apagar TUDO, inclusive os dados:
#   ./02.destroy_full_api-chirpstack-manager-backend_script.sh --tudo
# (rode antes o destroy do frontend, que remove o Ingress)

set -uo pipefail

K8S_DIR=~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/06.chirpstack_manager/api_chirpstack_manager_backend/kubernetes
NS=chirpstack-manager

echo "Start destroying ChirpStack-Manager backend pod/service."

kubectl delete --ignore-not-found -f $K8S_DIR/09.api-chirpstack-manager-backend__Service.yaml
kubectl delete --ignore-not-found -f $K8S_DIR/08.api-chirpstack-manager-backend__Deployment.yaml

kubectl delete --ignore-not-found -f $K8S_DIR/06.api-chirpstack-manager-postgresql__Service.yaml
kubectl delete --ignore-not-found -f $K8S_DIR/05.api-chirpstack-manager-postgresql__StatefulSet.yaml

if [ "${1:-}" = "--tudo" ]; then
  read -r -p "Apagar tambem o BANCO e os BACKUPS (PVCs), Secret, ConfigMap e namespace? Digite APAGAR: " ok
  if [ "$ok" = "APAGAR" ]; then
    kubectl delete --ignore-not-found -f $K8S_DIR/07.api-chirpstack-manager-backend__PersistentVolumeClaim.yaml
    kubectl delete --ignore-not-found -f $K8S_DIR/04.api-chirpstack-manager-postgresql__PersistentVolumeClaim.yaml
    kubectl delete --ignore-not-found -f $K8S_DIR/03.api-chirpstack-manager__ConfigMap.yaml
    kubectl -n $NS delete secret chirpstack-manager-secrets --ignore-not-found
    kubectl delete --ignore-not-found -f $K8S_DIR/01.create__Namespace.yaml
  else
    echo "Dados mantidos."
  fi
fi

echo "Successfully completed destruction of ChirpStack-Manager backend pod/service."
