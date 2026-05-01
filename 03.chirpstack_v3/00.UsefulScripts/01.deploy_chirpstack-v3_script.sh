#!/bin/bash

echo "Start ChirpStack-v3 pod/service deploy..."

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/01.create__Namespace.yaml && \

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/02.chirpstack-v3-mosquitto__ConfigMap.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/03.chirpstack-v3-mosquitto__Deployment.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/04.chirpstack-v3-mosquitto__Service.yaml && \

#kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/05.chirpstack_v3/05.chirpstack-v3-ns-as-postgresql-claim0__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml && \

#kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/06.chirpstack-v3-ns-as-create-attach-pvc__Pod.yaml && \

#echo "Waiting for the attach-pvc service to become available to continue with the ChirpStack-v3 service deployment..."
#kubectl wait --namespace chirpstack-v3 --for=condition=ready pod --selector=app=attach-pvc --timeout=300s && \
#echo "The attach-pvc service is operational, continuing with the deployment of the ChirpStack-v3 service..."

#echo "Starting file transfer into the Cluster..."
#kubectl cp -n chirpstack-v3 ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/07.chirpstack-postgresql/001.init-chirpstack-v3_ns.sh attach-pvc:/docker-entrypoint-initdb.d/001.init-chirpstack-v3_ns.sh && \
#kubectl cp -n chirpstack-v3 ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/07.chirpstack-postgresql/002.init-chirpstack-v3_as.sh attach-pvc:/docker-entrypoint-initdb.d/002.init-chirpstack-v3_as.sh && \
#kubectl cp -n chirpstack-v3 ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/07.chirpstack-postgresql/003.chirpstack-v3_as_trgm.sh attach-pvc:/docker-entrypoint-initdb.d/003.chirpstack-v3_as_trgm.sh && \
#kubectl cp -n chirpstack-v3 ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/07.chirpstack-postgresql/004.chirpstack-v3_as_hstore.sh attach-pvc:/docker-entrypoint-initdb.d/004.chirpstack-v3_as_hstore.sh && \
#echo "Transfer completed successfully into the attach-pvc pod."

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/08.chirpstack-v3-ns-postgresql-data__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/09.chirpstack-v3-as-postgresql-data__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml && \

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/10.chirpstack-v3-ns-as-postgresql__ConfigMap.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/11.chirpstack-v3-ns-postgresql__Deployment.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/12.chirpstack-v3-ns-postgresql__Service.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/13.chirpstack-v3-as-postgresql__Deployment.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/14.chirpstack-v3-as-postgresql__Service.yaml && \

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/15.chirpstack-v3-redis-data__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml && \

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/16.chirpstack-v3-redis__Deployment.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/17.chirpstack-v3-redis__Service.yaml && \

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/18.chirpstack-v3-gateway-bridge__ConfigMap.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/19.chirpstack-v3-gateway-bridge__Deployment.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/20.chirpstack-v3-gateway-bridge__Service.yaml && \

echo "Waiting for Mosquitto, Postgres and Redis services to become available to start ChirpStack-v3 service..."
kubectl wait --namespace chirpstack-v3 --for=condition=ready pod --selector=app=chirpstack-v3-mosquitto-deployment --timeout=300s && \
kubectl wait --namespace chirpstack-v3 --for=condition=ready pod --selector=app=chirpstack-v3-ns-postgresql-deployment --timeout=300s && \
kubectl wait --namespace chirpstack-v3 --for=condition=ready pod --selector=app=chirpstack-v3-as-postgresql-deployment --timeout=300s && \
kubectl wait --namespace chirpstack-v3 --for=condition=ready pod --selector=app=chirpstack-v3-redis-deployment --timeout=300s && \
echo "Mosquitto, Postgres and Redis services are operational, starting ChirpStack-v3 service..."

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/21.chirpstack-v3-network-server__ConfigMap.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/22.chirpstack-v3-network-server__Deployment.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/23.chirpstack-v3-network-server__Service.yaml && \

#kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/24.chirpstack-v3-application-server__Deployment.yaml && \

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/25.chirpstack-v3-application-server__ConfigMap.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/26.chirpstack-v3-application-server__Secret.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/27.chirpstack-v3-application-server__Deployment.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/28.chirpstack-v3-application-server__Service.yaml && \

#kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/29.chirpstack-v3-application-server-cert-manager__v1.12.3__Components_Full.yaml && \
#kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/30.chirpstack-v3-application-server-letsencrypt-issuer_with_e-mail_ACME_registration__ClusterIssuer.yaml && \
kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/31.chirpstack-v3-application-server__Ingress.yaml && \

kubectl apply -f ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/03.chirpstack_v3/kubernetes/32.chirpstack-v3-toolbox__Deployment.yaml && \

echo "Deploy completed successfully into the ChirpStack-v3 pod/service."
