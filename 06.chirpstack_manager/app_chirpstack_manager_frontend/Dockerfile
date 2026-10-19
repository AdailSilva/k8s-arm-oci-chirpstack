# =====================================================================
#  ChirpStack Manager Web - Angular + Avalon servido pelo NGINX (sem root)
#  O NGINX também encaminha /api para o backend (API_UPSTREAM).
#
#  Perfil escolhido no build (padrão: production):
#    docker build -t chirpstack-manager-web app_chirpstack_manager_frontend/
#    docker build --build-arg PERFIL=staging -t chirpstack-manager-web:staging app_chirpstack_manager_frontend/
#  Backend de cada perfil: development :8081 · staging :8082 · production :8083
#  (ajuste API_UPSTREAM ao rodar uma imagem que não seja de produção).
# =====================================================================
FROM node:22-alpine AS build
ARG PERFIL=production
WORKDIR /src
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
RUN npx ng build --configuration ${PERFIL}

FROM nginxinc/nginx-unprivileged:1.27-alpine
ENV API_UPSTREAM=http://chirpstack-manager-api:8083
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /src/dist/chirpstack-manager/browser /usr/share/nginx/html
EXPOSE 8080
