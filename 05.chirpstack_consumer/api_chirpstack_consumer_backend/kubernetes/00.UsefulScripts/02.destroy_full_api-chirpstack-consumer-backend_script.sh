#!/bin/bash

# ChirpStack-Consumer Backend destroy on K8S.

echo "Start destroying the ChirpStack-Consumer Backend pod/service."

kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/api_chirpstack_consumer_backend/kubernetes/03.api-chirpstack-consumer-backend__Service.yaml --ignore-not-found && \
kubectl delete -k ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/api_chirpstack_consumer_backend/kubernetes --ignore-not-found && \

# O Namespace chirpstack-consumer e compartilhado com o outro app do modulo: nao e apagado aqui.
# kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/api_chirpstack_consumer_backend/kubernetes/01.create__Namespace.yaml

echo "Successfully completed destroy of ChirpStack-Consumer Backend pod/service."
