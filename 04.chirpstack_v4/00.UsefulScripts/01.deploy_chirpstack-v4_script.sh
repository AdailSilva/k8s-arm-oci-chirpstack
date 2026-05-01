#!/bin/bash

echo "Start ChirpStack-v4 pod/service deploy..."

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/01.create__Namespace.yaml && \

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/02.chirpstack-v4-mosquitto__ConfigMap.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/03.chirpstack-v4-mosquitto__Deployment.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/04.chirpstack-v4-mosquitto__Service.yaml && \

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/05.chirpstack-v4-postgresql__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml && \

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/06.chirpstack-v4-postgresql__ConfigMap.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/07.chirpstack-v4-postgresql__Deployment.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/08.chirpstack-v4-postgresql__Service.yaml && \

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/09.chirpstack-v4-redis__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml && \

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/10.chirpstack-v4-redis__Deployment.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/11.chirpstack-v4-redis__Service.yaml && \

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/12.chirpstack-v4-bridge-gateway__ConfigMap.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/13.chirpstack-v4-bridge-gateway__Deployment.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/14.chirpstack-v4-bridge-gateway__Service.yaml && \

echo "Waiting for Mosquitto, Postgres and Redis Services to become available to start ChirpStack-v4 Service..."
kubectl wait --namespace chirpstack-v4 --for=condition=ready pod --selector=app=chirpstack-v4-mosquitto-deployment --timeout=300s && \
kubectl wait --namespace chirpstack-v4 --for=condition=ready pod --selector=app=chirpstack-v4-ns-as-postgresql-deployment --timeout=300s && \
kubectl wait --namespace chirpstack-v4 --for=condition=ready pod --selector=app=chirpstack-v4-redis-deployment --timeout=300s && \
echo "Mosquitto, Postgres and Redis Services are operational, starting ChirpStack-v4 Service..."

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/15.chirpstack-v4__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml && \

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/16.chirpstack-v4__ConfigMap.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/17.chirpstack-v4__Deployment.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/18.chirpstack-v4__Service.yaml && \

#kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/19.chirpstack-v4-cert-manager__v1.12.3__Components_Full.yaml && \
#kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/20.chirpstack-v4-letsencrypt-issuer_with_e-mail_ACME_registration__ClusterIssuer.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/21.chirpstack-v4__Ingress.yaml && \

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/22.chirpstack-v4-rest-api__Deployment.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/23.chirpstack-v4-rest-api__Service.yaml && \

#kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/24.chirpstack-v4-rest-api-cert-manager__v1.12.3__Components_Full.yaml && \
#kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/25.chirpstack-v4-rest-api-letsencrypt-issuer_with_e-mail_ACME_registration__ClusterIssuer.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/26.chirpstack-v4-rest-api__Ingress.yaml && \

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/04.chirpstack_v4/kubernetes/27.chirpstack-v4-toolbox__Deployment.yaml && \

echo "Deploy completed successfully into the ChirpStack-v4 pod/service."
