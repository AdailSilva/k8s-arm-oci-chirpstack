### Deploy as SPA - Single Page Application
# syntax=docker/dockerfile:1

# ── Stage 1: Builder ──────────────────────────────────────────────────────────
FROM node:22-alpine AS builder
WORKDIR /app

COPY package.json package-lock.json ./

RUN --mount=type=cache,target=/root/.npm \
    npm ci --prefer-offline

RUN --mount=type=cache,target=/root/.npm \
    npm install -g @angular/cli@21

COPY . .

# Perfil explícito: troca src/environments/environment.ts por environment.production.ts
# (não depende do defaultConfiguration do angular.json).
# Comando antigo — o npm não repassava a opção ao "ng"; saía em produção só porque
# production era o defaultConfiguration:
# RUN npm run build --configuration=production
RUN npm run build:production

# ── Stage 2: Servidor Nginx ───────────────────────────────────────────────────
FROM nginx:alpine

# Metadados da imagem
LABEL maintainer="AdailSilva <adail101@hotmail.com>" \
      app="app-chirpstack-homepage-frontend" \
      description="Homepage ChirpStack v3/v4 – chirpstack.adailsilva.com.br – Frontend Angular"

COPY --from=builder /app/dist/app-chirpstack-homepage-frontend/browser /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
COPY mime.types /etc/nginx/mime.types

EXPOSE 80/tcp
CMD ["nginx", "-g", "daemon off;"]