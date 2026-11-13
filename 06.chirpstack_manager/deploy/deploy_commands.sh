#!/bin/bash

echo "Deploy ChirpStack-Manager App..."

# Build local das imagens e subida da stack (stack_chirpstack-manager, perfil production).
# Em produção quem publica é o pipeline (.github/workflows/main.yml) + ArgoCD.
# Antes: cp .env.example .env e preencha CHIRPSTACK_API_TOKEN e os segredos.

cd ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/06.chirpstack_manager/api_chirpstack_manager_backend/ && \
mvn clean install -U -DskipTests -Pproduction && \
#docker build --tag adailsilva/api-chirpstack-manager-backend_platform_linux-x86_64:latest --no-cache . && \
docker build --tag adailsilva/api-chirpstack-manager-backend_platform_linux-arm_64:latest --no-cache . && \

cd ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/06.chirpstack_manager/app_chirpstack_manager_frontend/ && \
npm run build && \
#docker build --tag adailsilva/app-chirpstack-manager-frontend_platform_linux-x86_64:latest --no-cache . && \
docker build --tag adailsilva/app-chirpstack-manager-frontend_platform_linux-arm_64:latest --no-cache . && \

cd ~/Apps/OracleCloud/03.k8s-on-arm-oci-always-free_chirpstack/06.chirpstack_manager/stack_chirpstack-manager/ && \
docker compose --env-file ../.env up --build -d

echo "Implementation completed successfully! :-)"
