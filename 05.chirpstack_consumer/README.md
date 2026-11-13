# ChirpStack Consumer

> Aplicação que consome os eventos do **ChirpStack** e os apresenta em tempo real: API **Spring Boot**
> (WebSocket/STOMP) + painel **Angular 21 / PrimeNG 21 (Avalon 21)**. Sem banco de dados.
> Repositório **`AdailSilva/k8s-arm-oci-chirpstack`** — visão geral do repositório no [README da raiz](../README.md).

## Estrutura (padrão de módulo do CSLab)

```
05.chirpstack_consumer/
├── api_chirpstack_consumer_backend/      ← API Spring Boot (porta 8080), actuator (liveness/readiness)
│   └── kubernetes/                       ← 01 Namespace · 02 Deployment · 03 Service · kustomization.yaml · 00.UsefulScripts/
├── app_chirpstack_consumer_frontend/     ← SPA Angular + NGINX (proxy de /api/ e /ws/ para a API)
│   └── kubernetes/                       ← 01 · 02 Deployment · 03 Service · 04/05 (referência) · 06 Ingress · kustomization.yaml
├── stack_chirpstack-consumer/            ← docker-compose local (API + frontend)
├── deploy/                               ← deploy_commands.sh (build local + compose)
├── planos_implantacao/plano.txt
├── useful_commands_local_deploy/
├── backups/
└── README.md
```

Sem banco de dados, o módulo não tem `scripts_back-up/`, `stack_postgresql_pgAdmin_4/` nem
`useful_commands_backup_and_restore/` (as demais pastas seguem o CSLab).

## Kubernetes (namespace `chirpstack-consumer`)

| Recurso | Nome | Quem aplica |
|---|---|---|
| Namespace | `chirpstack-consumer` | Pipeline (`01.create__Namespace.yaml`) |
| Deployment (API) | `api-chirpstack-consumer-backend-deployment` | **ArgoCD** (Application `chirpstack-consumer-backend`) |
| Service (API) | `api-chirpstack-consumer-backend-service:8080` (ClusterIP, sem Ingress) | Pipeline |
| Deployment (frontend) | `app-chirpstack-consumer-frontend-deployment` | **ArgoCD** (Application `chirpstack-consumer-frontend`) |
| Service (frontend) | `app-chirpstack-consumer-frontend-service:80` | Pipeline |
| Ingress | `app-chirpstack-consumer.adailsilva.com.br` → frontend, TLS `letsencrypt-prod` | Pipeline |

Fluxo: navegador → Ingress → NGINX do frontend → `/api/` e `/ws/` → `api-chirpstack-consumer-backend-service:8080`.

| Item | Valor |
|---|---|
| Imagens OCIR | `api-chirpstack-consumer-backend_platform_linux-arm64`, `app-chirpstack-consumer-frontend_platform_linux-arm64` |
| Tags Git | `api-chirpstack-consumer-backend-X.Y`, `app-chirpstack-consumer-frontend-X.Y` |
| Jobs do pipeline | `api_chirpstack_consumer_backend`, `app_chirpstack_consumer_frontend` |
| Forçar deploy | `./force_deploy.sh consumer` (na raiz do repositório) |

## Rodar localmente

```bash
# API (perfil padrão, porta 8080)
cd api_chirpstack_consumer_backend && ./mvnw spring-boot:run

# Frontend
cd app_chirpstack_consumer_frontend && npm ci && npm start

# Tudo em contêineres (http://localhost:8080)
cd stack_chirpstack-consumer && docker compose up --build -d
```

## Observações

- O `pom.xml` não tem driver JDBC/JPA: as propriedades `spring.datasource.*` dos arquivos
  `application-*.properties` não são usadas. O Deployment não define `SPRING_PROFILES_ACTIVE`
  (a API sobe com a configuração padrão, porta 8080, sem context-path), igual ao comportamento
  anterior à padronização (o antigo `prod` não correspondia a nenhum arquivo de perfil).
- Antes da padronização, os manifestos ficavam em `05.chirpstack_consumer/kubernetes/` (Deployment
  `api-chirpstack-consumer-backend`, Service `api-chirpstack-consumer-backend-svc`). Os comandos para
  remover esses objetos antigos do cluster fazem parte do roteiro de migração da padronização (`_padronizacao/chirpstack_comandos.sh`, entregue junto com o zip).
