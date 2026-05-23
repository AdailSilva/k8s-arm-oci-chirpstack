#!/bin/bash

echo "Start ChirpStack-Consumer pod/service deploy..."

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/kubernetes/01.create__Namespace.yaml && \

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/kubernetes/02.chirpstack-consumer__Backend_Deployment.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/kubernetes/03.chirpstack-consumer__Backend_Service.yaml && \

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/kubernetes/04.chirpstack-consumer__Frontend_Deployment.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/kubernetes/05.chirpstack-consumer__Frontend_Service.yaml && \

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/kubernetes/06.chirpstack-consumer__Ingress.yaml && \

echo "Deploy completed successfully into the ChirpStack-Consumer pod/service."
