# ─────────────────────────────────────────────────────────────────────────────
# Stage 1 – Build
# Instala dependências e compila o projeto Angular (chirpstack-consumer) em modo produção.
# Output gerado em: dist/chirpstack-consumer/browser
# ─────────────────────────────────────────────────────────────────────────────
FROM node:22-alpine AS builder

WORKDIR /build

# Copia apenas os manifests de dependências primeiro para cache eficiente
COPY package.json package-lock.json* ./

RUN npm ci --prefer-offline --no-audit --no-fund

# Copia o restante do fonte e compila
COPY . .

RUN npx ng build --configuration production

# ─────────────────────────────────────────────────────────────────────────────
# Stage 2 – Runtime
# Imagem Nginx mínima para servir os arquivos estáticos gerados.
# ─────────────────────────────────────────────────────────────────────────────
FROM nginx:alpine

# Metadados da imagem
LABEL maintainer="AdailSilva <adail101@hotmail.com>" \
      app="app-chirpstack-consumer-frontend" \
      description="ChirpStack Consumer – Frontend Angular"

# Remove configuração padrão do Nginx e substitui pela customizada
RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copia os arquivos buildados para o diretório de serviço do Nginx
# Angular 17+ gera os assets em dist/<project>/browser
COPY --from=builder /build/dist/chirpstack-consumer/browser /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
