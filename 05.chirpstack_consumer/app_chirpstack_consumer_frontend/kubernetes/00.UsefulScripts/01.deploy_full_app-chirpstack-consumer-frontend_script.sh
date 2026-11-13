#!/bin/bash

# Build Project
# docker buildx build --platform 'linux/arm64' --tag gru.ocir.io/griszz3l82u1/app-chirpstack-consumer-frontend_platform_linux-arm64:latest --no-cache --push .


# ChirpStack-Consumer Frontend deployment on K8S.

echo "Start deploying the ChirpStack-Consumer Frontend pod/service."

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/app_chirpstack_consumer_frontend/kubernetes/01.create__Namespace.yaml && \

# Deployment pela kustomization.yaml: o 02__Deployment.yaml tem a imagem com placeholder
# (<OCI_REGISTRY_URL>/...:latest); o -k aplica o mesmo que o ArgoCD (registry real + newTag do GitOps).
kubectl apply -k ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/app_chirpstack_consumer_frontend/kubernetes && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/app_chirpstack_consumer_frontend/kubernetes/03.app-chirpstack-consumer-frontend__Service.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/app_chirpstack_consumer_frontend/kubernetes/06.app-chirpstack-consumer__Ingress.yaml && \

echo "Successfully completed deployment of ChirpStack-Consumer Frontend pod/service."
