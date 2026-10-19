# =====================================================================
#  ChirpStack Manager API - imagem multi-arquitetura (amd64 / arm64)
#
#  Perfil escolhido no build (padrão: production):
#    docker buildx build --platform linux/amd64,linux/arm64 \
#      -t <registro>/chirpstack-manager-api:<versão> api_chirpstack_manager_backend/
#    docker build --build-arg PERFIL=staging -t chirpstack-manager-api:staging api_chirpstack_manager_backend/
#
#  Portas: development 8081 · staging 8082 · production 8083 · actuator 8084 (todos)
# =====================================================================
FROM maven:3.9-eclipse-temurin-21 AS build
ARG PERFIL=production
WORKDIR /src
COPY pom.xml .
RUN mvn -B -q -P${PERFIL} dependency:go-offline
COPY src ./src
RUN mvn -B -q -P${PERFIL} -DskipTests package

FROM eclipse-temurin:21-jre-alpine
ARG PERFIL=production
# postgresql17-client: pg_dump, pg_restore e psql do módulo de backup (mesma versão do servidor
# PostgreSQL 17 do painel; o pg_dump precisa ser igual ou mais novo que o servidor).
# tzdata: fuso horário da grade do backup automático (APP_TIMEZONE).
RUN apk add --no-cache postgresql17-client tzdata \
    && addgroup -S app && adduser -S -G app -u 10001 app \
    && mkdir -p /var/backups/chirpstack-manager \
    && chown 10001:app /var/backups/chirpstack-manager
WORKDIR /app
COPY --from=build /src/target/chirpstack-manager-api.jar app.jar
USER 10001
# 8081/8082/8083 = aplicação (development/staging/production) | 8084 = actuator/probes
EXPOSE 8081 8082 8083 8084
ENV SPRING_PROFILES_ACTIVE=${PERFIL} \
    APP_BACKUP_DIR=/var/backups/chirpstack-manager \
    JAVA_OPTS="-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError"
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s CMD wget -qO- http://127.0.0.1:8084/actuator/health/liveness || exit 1
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
