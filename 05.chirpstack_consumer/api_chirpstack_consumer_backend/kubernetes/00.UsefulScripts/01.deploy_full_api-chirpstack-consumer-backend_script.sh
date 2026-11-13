#!/bin/bash

# Build Project
# docker buildx build --platform 'linux/arm64' --tag gru.ocir.io/griszz3l82u1/api-chirpstack-consumer-backend_platform_linux-arm64:latest --no-cache --push .


# ChirpStack-Consumer Backend deployment on K8S.

echo "Start deploying the ChirpStack-Consumer Backend pod/service."

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/api_chirpstack_consumer_backend/kubernetes/01.create__Namespace.yaml && \

# Deployment pela kustomization.yaml: o 02__Deployment.yaml tem a imagem com placeholder
# (<OCI_REGISTRY_URL>/...:latest); o -k aplica o mesmo que o ArgoCD (registry real + newTag do GitOps).
kubectl apply -k ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/api_chirpstack_consumer_backend/kubernetes && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/api_chirpstack_consumer_backend/kubernetes/03.api-chirpstack-consumer-backend__Service.yaml && \

echo "Successfully completed deployment of ChirpStack-Consumer Backend pod/service."
