#!/bin/bash

# ChirpStack-Consumer Frontend destroy on K8S.

echo "Start destroying the ChirpStack-Consumer Frontend pod/service."

kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/app_chirpstack_consumer_frontend/kubernetes/06.app-chirpstack-consumer__Ingress.yaml --ignore-not-found && \
kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/app_chirpstack_consumer_frontend/kubernetes/03.app-chirpstack-consumer-frontend__Service.yaml --ignore-not-found && \
kubectl delete -k ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/app_chirpstack_consumer_frontend/kubernetes --ignore-not-found && \

# O Namespace chirpstack-consumer e compartilhado com o outro app do modulo: nao e apagado aqui.
# kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/app_chirpstack_consumer_frontend/kubernetes/01.create__Namespace.yaml

echo "Successfully completed destroy of ChirpStack-Consumer Frontend pod/service."
