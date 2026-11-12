# syntax=docker/dockerfile:1
#
# Porta UDP por parametro (28/10/2026) -- antes ficava fixa no CMD e a imagem da
# porta 1710 exigia editar este arquivo. Agora:
#   docker buildx build --platform linux/arm64 --build-arg UDP_PORT=1700 -t .../udp-health-check-server-1700_platform_linux-arm64:latest --push .
#   docker buildx build --platform linux/arm64 --build-arg UDP_PORT=1710 -t .../udp-health-check-server-1710_platform_linux-arm64:latest --push .
# Em tempo de execucao a variavel UDP_PORT (definida nos manifestos) tem prioridade
# sobre o valor gravado na imagem.

FROM --platform=$BUILDPLATFORM eclipse-temurin:17-jdk AS build
WORKDIR /src
COPY UdpHealthCheckServer.java .
RUN javac UdpHealthCheckServer.java

FROM eclipse-temurin:17-jre
ARG UDP_PORT=1700
ENV UDP_PORT=${UDP_PORT}
WORKDIR /app
COPY --from=build /src/UdpHealthCheckServer.class .
# exec: o java vira o PID 1 e recebe o SIGTERM do Kubernetes direto.
CMD ["sh", "-c", "exec java UdpHealthCheckServer \"$UDP_PORT\""]
