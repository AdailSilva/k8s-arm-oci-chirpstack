# ─────────────────────────────────────────────────────────────────────────────
# Stage 1 – Build
# Compila o projeto com Maven e gera o JAR executável.
# Usa a imagem eclipse-temurin:21 (suporte nativo a linux/amd64 e linux/arm64).
# ─────────────────────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jdk AS builder

WORKDIR /build

# Copia apenas o pom.xml e o wrapper primeiro para aproveitar o cache de
# dependências do Docker — a camada só é invalidada quando o pom.xml mudar.
COPY .mvn/           .mvn/
COPY mvnw            mvnw
COPY pom.xml         pom.xml

RUN chmod +x mvnw && \
    ./mvnw dependency:go-offline -B --no-transfer-progress

# Copia o restante do código-fonte e compila
COPY src/ src/

RUN ./mvnw package -B --no-transfer-progress -DskipTests && \
    # Renomeia para um nome fixo independente da versão
    cp target/ChirpStack-Consumer-*.jar target/app.jar

# ─────────────────────────────────────────────────────────────────────────────
# Stage 2 – Runtime
# Imagem mínima JRE para executar o JAR.
# ─────────────────────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre

# Metadados da imagem
LABEL maintainer="AdailSilva <adail101@hotmail.com>" \
      app="api-chirpstack-consumer-backend" \
      description="ChirpStack Consumer – Backend Spring Boot"

WORKDIR /app

# Usuário não-root para segurança
RUN groupadd --system appgroup && \
    useradd  --system --gid appgroup --no-create-home appuser

COPY --from=builder /build/target/app.jar app.jar

RUN chown appuser:appgroup app.jar

USER appuser

# Spring Boot embeds Tomcat na porta 8080 por padrão
EXPOSE 8080

# Opções de JVM adequadas para containers (respeita os limites de memória do K8S)
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
