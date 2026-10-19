#!/bin/bash
# =====================================================================
#  Remove os pods, serviços e Ingress do ChirpStack Manager.
#
#  Os VOLUMES (banco e backups), o Secret, o ConfigMap e o namespace são
#  mantidos por padrão: apagar o namespace apaga junto os PVCs, ou seja,
#  o banco do painel e todos os backups do servidor.
#
#  Para apagar TUDO, inclusive os dados:  ./02.destroy_chirpstack-manager_script.sh --tudo
# =====================================================================
set -uo pipefail

DIR=~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/06.chirpstack_manager/kubernetes

echo "Start ChirpStack-Manager pod/service destroy..."

kubectl delete --ignore-not-found -f "$DIR/13.chirpstack-manager-restauracao__Ingress.yaml"
kubectl delete --ignore-not-found -f "$DIR/12.chirpstack-manager__Ingress.yaml"

kubectl delete --ignore-not-found -f "$DIR/11.chirpstack-manager-frontend__Service.yaml"
kubectl delete --ignore-not-found -f "$DIR/10.chirpstack-manager-frontend__Deployment.yaml"

kubectl delete --ignore-not-found -f "$DIR/09.chirpstack-manager-backend__Service.yaml"
kubectl delete --ignore-not-found -f "$DIR/08.chirpstack-manager-backend__Deployment.yaml"

kubectl delete --ignore-not-found -f "$DIR/06.chirpstack-manager-postgresql__Service.yaml"
kubectl delete --ignore-not-found -f "$DIR/05.chirpstack-manager-postgresql__StatefulSet.yaml"

if [ "${1:-}" = "--tudo" ]; then
    read -r -p "Apagar também o BANCO e os BACKUPS (PVCs), Secret, ConfigMap e namespace? Digite APAGAR: " ok
    if [ "$ok" = "APAGAR" ]; then
        kubectl delete --ignore-not-found -f "$DIR/07.chirpstack-manager-backend__PersistentVolumeClaim.yaml"
        kubectl delete --ignore-not-found -f "$DIR/04.chirpstack-manager-postgresql__PersistentVolumeClaim.yaml"
        kubectl delete --ignore-not-found -f "$DIR/03.chirpstack-manager__ConfigMap.yaml"
        kubectl -n chirpstack-manager delete secret chirpstack-manager-secrets --ignore-not-found
        kubectl delete --ignore-not-found -f "$DIR/01.create__Namespace.yaml"
    else
        echo "Dados mantidos."
    fi
fi

echo "Destroy completed successfully into the ChirpStack-Manager pod."
