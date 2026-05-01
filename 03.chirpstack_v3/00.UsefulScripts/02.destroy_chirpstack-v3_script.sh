#!/bin/bash

echo "Start ChirpStack-v3 pod/service destroy..."

kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/32.chirpstack-v3-toolbox__Deployment.yaml && \

kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/31.chirpstack-v3-application-server__Ingress.yaml && \
#kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/30.chirpstack-v3-application-server-letsencrypt-issuer_with_e-mail_ACME_registration__ClusterIssuer.yaml && \
#kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/29.chirpstack-v3-application-server-cert-manager__v1.12.3__Components_Full.yaml && \

kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/28.chirpstack-v3-application-server__Service.yaml && \
kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/27.chirpstack-v3-application-server__Deployment.yaml && \
kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/26.chirpstack-v3-application-server__Secret.yaml && \
kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/25.chirpstack-v3-application-server__ConfigMap.yaml && \

#kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/24.chirpstack-v3-application-server__Deployment.yaml && \

kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/23.chirpstack-v3-network-server__Service.yaml && \
kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/22.chirpstack-v3-network-server__Deployment.yaml && \
kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/21.chirpstack-v3-network-server__ConfigMap.yaml && \

kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/20.chirpstack-v3-gateway-bridge__Service.yaml && \
kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/19.chirpstack-v3-gateway-bridge__Deployment.yaml && \
kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/18.chirpstack-v3-gateway-bridge__ConfigMap.yaml && \

kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/17.chirpstack-v3-redis__Service.yaml && \
kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/16.chirpstack-v3-redis__Deployment.yaml && \
kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/15.chirpstack-v3-redis-data__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml && \


kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/14.chirpstack-v3-as-postgresql__Service.yaml && \
kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/13.chirpstack-v3-as-postgresql__Deployment.yaml && \
kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/12.chirpstack-v3-ns-postgresql__Service.yaml && \
kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/11.chirpstack-v3-ns-postgresql__Deployment.yaml && \
kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/10.chirpstack-v3-ns-as-postgresql__ConfigMap.yaml && \
kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/09.chirpstack-v3-as-postgresql-data__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml && \
kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/08.chirpstack-v3-ns-postgresql-data__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml && \

# ... 07 ...

#kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/06.chirpstack-v3-ns-as-create-attach-pvc__Pod.yaml && \
#kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/05.chirpstack-v3-ns-as-postgresql-claim0__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml && \

kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/04.chirpstack-v3-mosquitto__Service.yaml && \
kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/03.chirpstack-v3-mosquitto__Deployment.yaml && \
kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/02.chirpstack-v3-mosquitto__ConfigMap.yaml && \

kubectl delete -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/01.create__Namespace.yaml && \

echo "Destroy completed successfully into the ChirpStack-v3 pod."
