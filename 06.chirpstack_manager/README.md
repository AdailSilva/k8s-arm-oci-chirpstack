# ChirpStack Manager

Painel web para administrar o **ChirpStack v4** pela REST API, com login próprio, controle de acesso por perfil, auditoria, **controle e monitoramento de visitantes**, **controle de logoff** e **backup/restauração com agendamento e envio ao Google Drive**.

| Camada | Tecnologia |
|---|---|
| Backend (BFF) | Spring Boot **4.1.1** · Java 21 · Spring Security 7 (JWT HS256) · Spring Data JPA · Flyway · PostgreSQL (staging/production) / H2 (development) |
| Frontend | Angular 21 · PrimeNG 21 · tema **Avalon** · Tailwind · Chart.js |
| Integração | REST API do ChirpStack (**chirpstack-rest-api v4.19.0**, compatível com o ChirpStack 4.19.x) |
| Deploy | Docker multi-arquitetura (amd64/arm64) · Kubernetes (Ingress NGINX + cert-manager) |

---

## Arquitetura

```
Navegador ──HTTPS──> Ingress ──> chirpstack-manager-web (NGINX + Angular)
                                     │  /api/*
                                     ▼
                           chirpstack-manager-api (Spring Boot) ──> PostgreSQL
                                     │  Grpc-Metadata-Authorization: Bearer <API key>
                                     ▼
                     https://chirpstack-v4-rest-api.adailsilva.com.br  (ChirpStack REST v4.19)
```

O navegador **nunca vê a API key do ChirpStack**: ela fica só no backend (Secret do Kubernetes). O frontend fala apenas com `/api/v1/**` do backend, que autentica o usuário, confere o perfil e só então chama o ChirpStack.

---

## Segurança

| Item | Como foi feito |
|---|---|
| API key do ChirpStack | Somente no backend (`CHIRPSTACK_API_TOKEN`). Nenhuma rota repassa o cabeçalho para o navegador. |
| Sem proxy aberto | Cada uma das 77 operações do ChirpStack tem um endpoint explícito. Não existe repasse genérico de caminho. |
| Validação de IDs | UUID, EUI-64 (DevEUI/Gateway ID), Relay ID e tipo de integração são validados por regex antes de montar a URL. |
| Login | E-mail e senha com BCrypt. A mensagem de erro é a mesma para e-mail inexistente e senha errada, e o tempo de resposta também é igual. |
| Força bruta | A conta é bloqueada por 15 min após 5 falhas seguidas. Há também um limite de 20 tentativas por IP a cada 5 min, e o Ingress limita requisições por segundo. |
| Sessão | **Access token** JWT de 15 min, guardado só em memória no navegador. **Refresh token** de 256 bits num cookie `HttpOnly; Secure; SameSite=Strict` restrito a `/api/v1/auth`. No banco fica só o hash SHA-256 do refresh token. |
| Rotação | Cada renovação gera um refresh token novo. Se um token já trocado for reutilizado (sinal de roubo), todas as sessões do usuário são encerradas. |
| Troca de senha / desativação | Todas as sessões do usuário são revogadas. |
| Sessões vivas | Cada login abre uma sessão (`tb_sessao`) cujo id vai no JWT (`sid`). Toda requisição confere se ela continua aberta: encerrar pelo ADMIN, bloquear, trocar a senha ou restaurar um backup derruba a sessão **na hora**, sem esperar o token vencer. A resposta vem com `X-Sessao-Status: ENCERRADA` e o navegador vai direto ao login mostrando o motivo. |
| Logoff | Inatividade, duração máxima, sessões simultâneas e "manter conectado" definidos pelo ADMIN. O navegador avisa antes e o servidor confere as mesmas regras ao renovar o token. |
| Segredos do Google | Refresh token da conta Google e Client Secret gravados cifrados (AES-256-GCM, chave em `APP_CHAVE_CIFRAGEM`, fora do banco). Escopo `drive.file`: o sistema só vê o que ele mesmo criou no Drive. |
| Perfis | `ADMIN`, `OPERADOR` e `VISUALIZADOR`, aplicados com `@PreAuthorize` em **cada** operação no backend. O frontend apenas esconde o que o perfil não pode usar. |
| Segredos de rede | Chaves OTAA, sessão ABP, configuração de integrações, chaves multicast e certificados: somente ADMIN e OPERADOR. |
| Auditoria | Logins (sucesso e falha), logout e **toda escrita** no ChirpStack e nos usuários do painel. Corpos não são gravados, pois podem conter chaves. |
| IP real | `forward-headers-strategy: native` (RemoteIpValve): o `X-Forwarded-For` só é aceito quando vem de proxy interno, então o cliente não consegue forjar o IP. |
| Cabeçalhos | API: HSTS, `nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy`, CSP `default-src 'none'`. Web: CSP restritiva sem script inline. |
| Erros do ChirpStack | Os códigos gRPC viram mensagens em português. Se o ChirpStack recusar a credencial, a resposta é **502**, não 401, para o usuário não ser deslogado por engano. |
| Containers | Usuário sem root, `readOnlyRootFilesystem` e `capabilities: drop ALL`. |

### Perfis de acesso

| Recurso | ADMIN | OPERADOR | VISUALIZADOR |
|---|:-:|:-:|:-:|
| Painel, listas e métricas | ✅ | ✅ | ✅ |
| Aplicações, dispositivos, gateways, perfis, multicast, relays, integrações (criar/alterar/excluir) | ✅ | ✅ | — |
| Chaves OTAA, ativação ABP, segredos de integração/multicast, certificados TLS | ✅ | ✅ | — |
| Templates de perfil (escrita) | ✅ | — | — |
| Perfis globais e catálogo de dispositivos (alterar/excluir) · verificação de prefixos de DevAddr | ✅ | — | — |
| Tenants, usuários do ChirpStack, usuários do tenant | ✅ | — | — |
| Usuários do painel e auditoria | ✅ | — | — |
| Visitantes, controle de sessão, backup e Google Drive | ✅ | — | — |

---

## Funcionalidades (todas as 132 operações / 86 rotas da REST API v4.19)

| Tela | Operações do ChirpStack |
|---|---|
| **Painel** | Resumo do tenant: gateways online/offline, dispositivos ativos em 24 h, dispositivos por aplicação |
| **Tenants** | Listar, criar, editar, excluir · **prefixos de DevAddr** com verificação de sobreposição entre tenants (4.19) · usuários do tenant: listar, adicionar, editar permissões, remover |
| **Usuários do ChirpStack** | Listar, criar (com vínculo a tenants), editar, excluir, alterar senha |
| **Aplicações** | Listar, criar, editar, excluir · perfis e tags em uso · *measurement keys* |
| ↳ **Integrações** | HTTP, InfluxDB (1/2/3), ThingsBoard, myDevices, GCP Pub/Sub, AWS SNS, Azure Service Bus, Pilot Things, IFTTT, Blynk (criar, editar, remover) · certificado de cliente MQTT |
| ↳ **Dispositivos** | Listar (busca, ordenação e **filtro por tags**), criar, editar, excluir · métricas de enlace (pacotes, RSSI, SNR, frequência, DR, erros) e medições do codec |
| ↳ ↳ **Chaves OTAA** | Consultar, cadastrar, alterar, excluir; limpar DevNonces. Trata AppKey em LoRaWAN 1.0.x × NwkKey/AppKey em 1.1 |
| ↳ ↳ **Ativação** | Ver a sessão atual, ativar/reativar por ABP, gerar DevAddr, desativar, próximo FCntDown |
| ↳ ↳ **Fila de downlink** | Listar, enfileirar (hex, base64, texto ou JSON pelo codec), limpar |
| ↳ **Relays** (4.19) | Relays TS011 da aplicação · dispositivos atendidos por cada relay: listar, adicionar, remover |
| ↳ **Grupos multicast** | Listar (por aplicação, por tenant ou pelos grupos de um dispositivo), criar, editar, excluir · adicionar/remover dispositivos e gateways · fila (listar, enfileirar, limpar) |
| **Gateways** | Listar (estado e ordenação), cadastrar, editar (com localização e **prioridade de downlink**), excluir · métricas RX/TX por frequência, DR e status · duty-cycle · certificado TLS de cliente |
| **Relay gateways** | Listar, editar, excluir |
| **Perfis de dispositivo** | Listar (do tenant + globais, só do tenant, só globais ou por modelo do catálogo), criar, editar, excluir · **data rates de uplink suportados** e **classe B só downlink** (4.19). Abas: geral, join OTAA/ABP, classe B, classe C, codec (com exemplo JS), medições, relay (TS011), camada de aplicação (TS003/004/005) e tags · **importar de template** · algoritmos ADR |
| **Templates de perfil** | Listar, criar, editar, excluir |
| **Catálogo de dispositivos** (4.19) | Fabricantes (Vendor ID, OUIs, metadados) e modelos importados com `chirpstack import-device-profiles` · perfis globais de cada modelo · excluir (ADMIN) · busca de perfil pelo ProfileID do TR0005 (`/device-profiles/por-perfil-fabricante/{vendorId}/{vendorProfileId}`) |
| **Grupos multicast** | Todos os grupos do tenant, com a aplicação de cada um |
| **Sistema** | Usuários do painel (CRUD, desbloqueio), auditoria com filtros, meu perfil e troca de senha |

### Visitantes, logoff e backup

| Tela | O que faz |
|---|---|
| **Visitantes** | Indicadores (on-line agora, acessos e visitantes únicos de hoje e da semana, recusas de login, bloqueados), acessos por dia, horário dos acessos, dispositivos e como as sessões terminaram. Abas: **On-line agora** (atualiza a cada 10 s; situação on-line/ausente, dispositivo, IP, tempo sem interação), **Por usuário** (frequência, último acesso), **Histórico de acessos** (filtros por usuário, situação, período e texto) e **Tentativas recusadas**. Ações: encerrar uma sessão, encerrar as sessões de um usuário, **desconectar todos** (menos você), **bloquear acesso** temporário (até data/hora, com motivo exibido no login) ou permanente (desativa) e desbloquear. |
| **Controle de sessão** | Política de logoff: tempo sem uso (com aviso e contagem regressiva), duração máxima desde o login, limite de sessões simultâneas por usuário e "manter conectado ao fechar o navegador". Opção de aplicar na hora encerrando as sessões abertas. |
| **Topo da tela** | Indicador com o tempo até o logoff por inatividade; amarelo no aviso e vermelho no último minuto. Diálogo "Sua sessão vai expirar" com *Continuar conectado* / *Sair agora*; aviso do tempo máximo. A inatividade é contada em todas as abas abertas e o logoff em uma aba vale para todas. |
| **Backup & Restauração** | **Backup**: gerar `.backup` (pg_dump custom) e/ou `.sql`, enviar opcionalmente ao Drive, verificação do ambiente (utilitários, banco, volume, Drive), lista de arquivos com baixar / restaurar / excluir. **Restaurar**: upload com confirmação digitada, backup de segurança automático antes, transação única (se falhar, nada muda), migrações aplicadas depois e todos desconectados ao final. **Agendamento**: grade semanal com vários horários por dia, formatos, destinos (servidor e/ou Drive), retenção por dias com mínimo garantido, *Executar agora*, próximas e últimas execuções. **Google Drive**: credenciais OAuth, conectar/reconectar/desconectar a conta, testar envio, pasta (com níveis), retenção no Drive. **Histórico** de todas as execuções. |

Como o backup funciona:

- `pg_dump`/`pg_restore`/`psql` rodam **dentro do pod da API** (pacote `postgresql17-client` na imagem), direto no serviço do PostgreSQL: sem `kubectl` e sem RBAC extra.
- Arquivos em `/var/backups/chirpstack-manager/{manuais,agendados,seguranca}` (PVC próprio). Nomes validados; nenhum caminho vem do navegador.
- Uma operação por vez no cluster; o progresso fica em `tb_backup_job` (consultável de qualquer réplica). Execuções interrompidas por reinício viram erro.
- O relógio do agendamento roda a cada minuto em todas as réplicas, mas só uma executa cada horário (UPDATE condicional em `ultimo_disparo`). Horários perdidos por até 10 minutos ainda rodam; se já houver outra operação, o horário é registrado como **Ignorado**.
- Envio ao Drive por upload *resumable* em blocos de 8 MiB (retoma após queda de rede). Se o único destino for o Drive e o envio falhar, os arquivos ficam guardados em `agendados/`.
- No perfil `development` (H2) o backup usa `SCRIPT`/`RUNSCRIPT` e só o formato `.sql`.
- O backup cobre o **banco do painel** (usuários, sessões, auditoria e configurações). Os dados da rede LoRaWAN ficam no próprio ChirpStack.

---

## Configuração (variáveis de ambiente do backend)

| Variável | Obrigatória | Descrição |
|---|:-:|---|
| `CHIRPSTACK_BASE_URL` | | URL da chirpstack-rest-api (padrão: produção) |
| `CHIRPSTACK_API_TOKEN` | ✅ | API key **de administrador** do ChirpStack |
| `APP_JWT_SECRET` | ✅ production | Segredo HS256 com ≥ 32 caracteres (`openssl rand -base64 48`) |
| `APP_ADMIN_EMAIL` / `APP_ADMIN_PASSWORD` | | Primeiro administrador, criado só se a base estiver vazia. Sem senha definida, uma é gerada e mostrada **uma vez** no log |
| `APP_CORS_ALLOWED_ORIGINS` | | Origens permitidas (padrão `http://localhost:4201` em development e `:4202` em staging; só é necessário se o frontend estiver em outro domínio) |
| `APP_COOKIE_SECURE` | | `true` em produção (HTTPS) |
| `APP_ACCESS_TOKEN_TTL` / `APP_REFRESH_TOKEN_TTL` | | Padrão: `15m` / `7d` |
| `SPRING_PROFILES_ACTIVE` | | `development`, `staging` ou `production` (veja **Perfis**) |
| `SERVER_PORT` / `MANAGEMENT_PORT` | | Sobrescrevem a porta do perfil (8081/8082/8083) e a do actuator (8084) |
| `DB_URL` / `DB_USERNAME` / `DB_PASSWORD` | staging/production | PostgreSQL (o usuário precisa poder recriar o schema `public` na restauração; o `POSTGRES_USER` da imagem oficial já pode) |
| `APP_CHAVE_CIFRAGEM` | recomendado | Chave AES-256 dos segredos do Google Drive (`openssl rand -base64 32`). Sem ela, deriva do `APP_JWT_SECRET` |
| `APP_TIMEZONE` | | Fuso da grade de backup, dos nomes de arquivo e dos indicadores (padrão `America/Fortaleza`) |
| `APP_BACKUP_DIR` | | Volume dos backups (imagem: `/var/backups/chirpstack-manager`; development: `./data/backups`; staging: `./data-staging/backups`) |
| `APP_BACKUP_MAX_UPLOAD` / `APP_BACKUP_TEMPO_LIMITE` | | Maior arquivo aceito na restauração (`512MB`) e tempo máximo de um dump/restore (`30m`) |
| `GOOGLE_DRIVE_REDIRECT_URI` | Drive | Endereço público do callback (`https://<host>/api/v1/backup/google-drive/callback`); cadastre-o igual no cliente OAuth |
| `GOOGLE_DRIVE_CLIENT_ID` / `GOOGLE_DRIVE_CLIENT_SECRET` | | Opcionais: também podem ser cadastrados na tela (que tem prioridade) |
| `APP_SESSAO_RETENCAO_DIAS` | | Por quanto tempo o histórico de visitantes é mantido (padrão 365) |

**Gerar a API key:** no ChirpStack, entre como administrador e vá em *Network Server → API keys → Add API key*. Copie o token gerado para `CHIRPSTACK_API_TOKEN`; ele só aparece uma vez.

---

## Perfis (development, staging e production)

Mesmo esquema do CSLab WEB, CardsControl e BackOffice: cada perfil tem a sua porta, no backend e no frontend, então os três podem rodar ao mesmo tempo na mesma máquina.

| Perfil | Uso | Backend | Actuator | Frontend (`ng serve`) | Banco | Cookie `Secure` |
|---|---|:-:|:-:|:-:|---|:-:|
| `development` | máquina do desenvolvedor | **8081** | 8084 | **4201** | H2 em arquivo (`./data`) | não |
| `staging` | homologação | **8082** | 8084 | **4202** | PostgreSQL local (`chirpstack_manager_staging`) | não |
| `production` | Kubernetes / Docker | **8083** | 8084 | **4203** | PostgreSQL do cluster | sim |

- **Backend:** blocos `on-profile` no `application.yml` e perfis Maven de mesmo nome (`-Pdevelopment` é o padrão). O jar é o mesmo nos três; em container o perfil vem de `SPRING_PROFILES_ACTIVE` (a imagem usa `production`, ou `--build-arg PERFIL=staging`).
- **Actuator:** `/actuator/health/*` sai da porta da aplicação e fica na **8084** em todos os perfis. As probes do Kubernetes usam essa porta, que não entra no Service nem no Ingress. Liveness = só a JVM; readiness = JVM + banco.
- **Frontend:** `environment.<perfil>.ts`, `src/proxy-config.<perfil>.json` (encaminha `/api` para a porta do backend do mesmo perfil) e configurações `development`/`staging`/`production` no `angular.json`. Em desenvolvimento e homologação aparece um selo no topo da tela.

## Desenvolvimento local

```bash
# Backend
cd api_chirpstack_manager_backend
export CHIRPSTACK_API_TOKEN='<sua API key>'
export APP_ADMIN_PASSWORD='Admin12345'
mvn spring-boot:run                 # development -> http://localhost:8081
mvn spring-boot:run -Pstaging       # staging     -> http://localhost:8082 (crie antes: createdb -U postgres chirpstack_manager_staging)
mvn spring-boot:run -Pproduction    # production  -> http://localhost:8083 (exige DB_URL/DB_PASSWORD e APP_JWT_SECRET)

# Frontend
cd app_chirpstack_manager_frontend
npm install
npm start                           # development -> http://localhost:4201 (proxy /api -> :8081)
npm run start:staging               # staging     -> http://localhost:4202 (proxy /api -> :8082)
npm run start:production            # production  -> http://localhost:4203 (proxy /api -> :8083)
npm run build:staging               # build de um perfil (development | staging | production)
```

Testes do backend: `mvn verify` (sobe o contexto com H2, valida as migrations e a criação do admin).

## Docker Compose

```bash
cp .env.example .env           # preencha os segredos
docker compose -f docker/docker-compose.yaml --env-file .env up -d --build   # http://localhost:8080 (perfil production)
```

## Kubernetes (cluster OCI ARM64)

```bash
# Imagens multi-arquitetura
docker buildx build --platform linux/amd64,linux/arm64 -t gru.ocir.io/griszz3l82u1/chirpstack-manager-api:0.1.0 --push api_chirpstack_manager_backend/
docker buildx build --platform linux/amd64,linux/arm64 -t gru.ocir.io/griszz3l82u1/chirpstack-manager-web:0.1.0 --push app_chirpstack_manager_frontend/

# Secret real (uma única vez; o arquivo 02 é só exemplo e não é aplicado pelo script)
kubectl apply -f kubernetes/01.create__Namespace.yaml
kubectl -n chirpstack-manager create secret generic chirpstack-manager-secrets \
  --from-literal=CHIRPSTACK_API_TOKEN='<API key>' \
  --from-literal=APP_JWT_SECRET="$(openssl rand -base64 48)" \
  --from-literal=APP_ADMIN_PASSWORD='<senha inicial>' \
  --from-literal=DB_PASSWORD="$(openssl rand -base64 24)" \
  --from-literal=APP_CHAVE_CIFRAGEM="$(openssl rand -base64 32)"

# Deploy (aplica os manifests na ordem e espera os rollouts)
./00.UsefulScripts/01.deploy_chirpstack-manager_script.sh
```

Scripts em `00.UsefulScripts/`:

| Script | O que faz |
|---|---|
| `01.deploy_…` | Aplica os manifests 01, 03 a 13 na ordem (confere antes se o Secret existe) e espera os rollouts |
| `02.destroy_…` | Remove pods, serviços e Ingress **mantendo** banco, backups, Secret e namespace. `--tudo` apaga também os dados, com confirmação |
| `03.back-up_…` | `pg_dump` direto do pod do PostgreSQL para esta máquina (`~/Backups/chirpstack-manager`), sem depender da API |
| `04.restore_…` | Restaura um `.backup` desta máquina: para a API, restaura em transação única num schema limpo, encerra as sessões e sobe a API de novo |

Antes de aplicar, ajuste nos manifests:

- o host do Ingress (`chirpstack-manager.adailsilva.com.br`);
- o nome do `ClusterIssuer`;
- o `storageClassName` do PostgreSQL (`04…PersistentVolumeClaim.yaml`) e do volume de backups (`07…PersistentVolumeClaim.yaml`);
- o `GOOGLE_DRIVE_REDIRECT_URI` no ConfigMap;
- o `imagePullSecrets` do OCIR.

---

## Estrutura

```
06.chirpstack_manager/
├── 00.UsefulScripts/               deploy, destroy, backup e restore pelo kubectl
├── api_chirpstack_manager_backend/ Spring Boot 4.1.1 (Java 21)
│   └── src/main/java/br/com/adailsilva/chirpstackmanager/
│       ├── auth/                   login, refresh, logout, rate limit, tokens
│       ├── usuario/                usuários do painel (CRUD)
│       ├── auditoria/              registro e consulta
│       ├── sessao/                 sessões, política de logoff, filtro de sessão encerrada
│       ├── visitante/              monitoramento de visitantes e ações do administrador
│       ├── backup/                 backup/restauração (PostgreSQL e H2), agendamento, histórico
│       │   └── drive/              OAuth e upload resumable para o Google Drive
│       ├── chirpstack/             cliente REST + exceção gRPC
│       │   └── api/                controllers: tenants, users, applications, device-profiles,
│       │                           device-profile-templates, devices, gateways, relay-gateways,
│       │                           multicast-groups, resumo
│       ├── config/                 segurança, propriedades, bootstrap do admin
│       └── web/                    tratamento de erros, paginação
├── app_chirpstack_manager_frontend/ Angular 21 + Avalon
│   └── src/app/
│       ├── core/                   api (models, services), auth (interceptor, guards, monitor de sessão), util
│       ├── shared/                 componentes reutilizáveis (tabelas paginadas, campos hex, gráficos...)
│       ├── features/               telas por módulo (sistema/: visitantes, controle de sessão, backup)
│       └── layout/ pages/          tema Avalon adaptado (menu, topo, login)
├── docker/docker-compose.yaml      ambiente local completo
├── kubernetes/                     manifests, um objeto por arquivo (01 a 13)
└── docs/telas/                     capturas de tela
```

## Próximos passos sugeridos

- Eventos em tempo real (uplinks/joins) via integração MQTT do ChirpStack + WebSocket no backend.
- Mapa de gateways e dispositivos (Leaflet/OpenStreetMap).
- Importação de dispositivos em lote (CSV).
- Login único com os usuários do ChirpStack (via gRPC `InternalService`, que a REST API não expõe).

## Telas

As capturas em [`docs/telas/`](docs/telas) foram feitas com o frontend real, rodando contra uma simulação do backend e do ChirpStack 4.15 (as telas da 4.19 seguem o mesmo padrão) com dados de exemplo.

| | |
|---|---|
| ![Login](docs/telas/01-login.png) | ![Painel](docs/telas/02-painel.png) |
| ![Dispositivo](docs/telas/04-dispositivo-metricas.png) | ![Gateway](docs/telas/08-gateway.png) |
| ![Perfil](docs/telas/09-perfil-dispositivo.png) | ![Integrações](docs/telas/07-integracoes.png) |

### Visitantes, logoff e backup

| | |
|---|---|
| ![Visitantes](docs/telas/16-visitantes.png) | ![Por usuário](docs/telas/17-visitantes-usuarios.png) |
| ![Bloqueio](docs/telas/18-visitantes-bloqueio.png) | ![Histórico de acessos](docs/telas/19-visitantes-historico.png) |
| ![Controle de sessão](docs/telas/21-controle-sessao.png) | ![Aviso de inatividade](docs/telas/22-aviso-inatividade.png) |
| ![Login após encerramento](docs/telas/20-login-encerrada-admin.png) | ![Backup](docs/telas/25-backup.png) |
| ![Agendamento](docs/telas/26-backup-agendamento.png) | ![Google Drive](docs/telas/27-backup-google-drive.png) |
| ![Histórico de backups](docs/telas/28-backup-historico.png) | ![Restaurar](docs/telas/29-backup-restaurar.png) |
