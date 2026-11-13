#!/bin/bash

echo "Deploy ChirpStack-Consumer App..."

# Build local das imagens e subida da stack (stack_chirpstack-consumer).
# Em produção quem publica é o pipeline (.github/workflows/main.yml) + ArgoCD.

cd ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/api_chirpstack_consumer_backend/ && \
./mvnw clean install -U -DskipTests && \
#docker build --tag adailsilva/api-chirpstack-consumer-backend_platform_linux-x86_64:latest --no-cache . && \
docker build --tag adailsilva/api-chirpstack-consumer-backend_platform_linux-arm_64:latest --no-cache . && \

cd ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/app_chirpstack_consumer_frontend/ && \
npm run build && \
#docker build --tag adailsilva/app-chirpstack-consumer-frontend_platform_linux-x86_64:latest --no-cache . && \
docker build --tag adailsilva/app-chirpstack-consumer-frontend_platform_linux-arm_64:latest --no-cache . && \

cd ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/05.chirpstack_consumer/stack_chirpstack-consumer/ && \
docker-compose up --build -d

echo "Implementation completed successfully! :-)"
