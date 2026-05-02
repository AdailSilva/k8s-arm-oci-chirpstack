# ☸️ Kubernetes on ARM — OCI Always Free · ChirpStack

> Implantação **totalmente automatizada** de um cluster Kubernetes em arquitetura **ARM (AArch64)** na Oracle Cloud Infrastructure, utilizando exclusivamente os recursos **Always Free** — sem nenhum custo. Este repositório documenta a implantação do stack LoRaWAN **ChirpStack** em suas versões **v3** e **v4** sobre o cluster, detalhando ricamente cada componente, configuração, diferença de arquitetura e procedimento de operação.
> A infraestrutura é provisionada como código via **Terraform** / **OpenTofu**, e todas as aplicações são gerenciadas com manifests Kubernetes organizados por módulo.

---

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Arquitetura](#arquitetura)
- [Módulos de Infraestrutura](#módulos-de-infraestrutura)
- [Aplicações Padrão do Cluster](#aplicações-padrão-do-cluster)
  - [00. Homepage (nginx)](#00-homepage-nginx)
  - [01. Metrics Server](#01-metrics-server)
  - [02. UDP Health Check — NLB OCI](#02-udp-health-check--nlb-oci)
- [Pré-requisitos](#pré-requisitos)
- [Recursos Always Free Utilizados](#recursos-always-free-utilizados)
- [Tecnologias e Componentes](#tecnologias-e-componentes)
- [Estrutura do Repositório](#estrutura-do-repositório)
- [Configuração de DNS — Subdomínios Obrigatórios](#configuração-de-dns--subdomínios-obrigatórios)
  - [Quando cadastrar os subdomínios](#quando-cadastrar-os-subdomínios)
  - [Subdomínios necessários neste projeto](#subdomínios-necessários-neste-projeto)
  - [Exemplo prático — Registro .com.br (Registro.br)](#exemplo-prático--registro-combr-registrobr)
  - [Verificar a propagação do DNS](#verificar-a-propagação-do-dns)
  - [Atualizar os subdomínios nos manifestos](#atualizar-os-subdomínios-nos-manifestos-antes-do-deploy)
- [Configuração Inicial](#configuração-inicial)
- [Implantação da Infraestrutura](#implantação-da-infraestrutura)
- [Implantando as Aplicações Padrão](#implantando-as-aplicações-padrão)
- [Pré-requisito: OCI File Storage Service (FSS)](#pré-requisito-oci-file-storage-service-fss)
  - [Por que o FSS é necessário](#por-que-o-fss-é-necessário)
  - [Criando o FSS no console OCI](#criando-o-fss-no-console-oci)
  - [Script de montagem e preparação dos diretórios](#script-de-montagem-e-preparação-dos-diretórios)
  - [Como executar em todos os nós](#como-executar-em-todos-os-nós)
  - [Tornar a montagem permanente (fstab)](#tornar-a-montagem-permanente-fstab)
- [03. ChirpStack v3](#03-chirpstack-v3)
- [04. ChirpStack v4](#04-chirpstack-v4)
  - [MQTT com TLS — Passo a Passo Completo](#mqtt-com-tls--diferencial-em-relação-ao-v3)
  - [Expor o MQTT TLS externamente via Ingress NGINX](#expor-o-mqtt-tls-externamente-via-ingress-nginx-tcp-passthrough)
  - [Distribuir a CA para gateways externos](#distribuir-a-ca-interna-para-os-gateways-lorawan-externos)
  - [Diagnóstico de problemas de TLS](#diagnóstico-de-problemas-comuns-de-tls)
- [Comparativo v3 vs v4](#comparativo-v3-vs-v4)
- [Mapa de Serviços e Links de Acesso](#mapa-de-serviços-e-links-de-acesso)
  - [Serviços HTTP/HTTPS — acesso pelo navegador](#serviços-httphttps--acesso-pelo-navegador)
  - [Serviços de rede — acesso direto via IP/porta](#serviços-de-rede--acesso-direto-via-ipporta)
  - [Serviços internos ao cluster — port-forward](#serviços-internos-ao-cluster--acesso-via-kubectl)
  - [Configuração dos gateways LoRaWAN físicos](#configuração-dos-gateways-lorawan-físicos--packet-forwarder)
- [Configuração dos Gateways no ChirpStack](#configuração-dos-gateways-no-chirpstack)
  - [ChirpStack v3 — Network Server, Profiles e Gateways](#chirpstack-v3--configuração-completa)
  - [ChirpStack v4 — Templates, Profiles e Gateways](#chirpstack-v4--configuração-completa)
  - [Diferenças no cadastro v3 vs v4](#diferenças-no-cadastro-v3-vs-v4)
- [Acesso ao Cluster](#acesso-ao-cluster)
- [CI/CD com GitHub Actions](#cicd-com-github-actions)
- [OCI Container Registry](#oci-container-registry)
- [Destruindo a Infraestrutura](#destruindo-a-infraestrutura)
- [Troubleshooting](#troubleshooting)
- [Contribuindo](#contribuindo)
- [Licença](#licença)

---

## Visão Geral

Este projeto provisiona um cluster Kubernetes completo e funcional na **Oracle Cloud Infrastructure (OCI)** sem nenhum custo, aproveitando o plano **Always Free** da Oracle — que inclui instâncias ARM Ampere A1 com até 4 OCPUs e 24 GB de RAM por conta.

O foco deste repositório é a implantação e operação do **ChirpStack** — a plataforma de servidor de rede LoRaWAN open-source mais utilizada no mundo — em suas duas versões principais, **v3** e **v4**, sobre o cluster Kubernetes ARM. Ambas as versões são documentadas com profundidade: arquitetura, componentes, configurações, volumes persistentes, TLS, regiões LoRaWAN, backup/restore e procedimentos de troubleshooting.

Além do ChirpStack, o projeto inclui as três aplicações de infraestrutura base que compõem o ambiente operacional mínimo do cluster:

- **Homepage** — página de apresentação do domínio, servida via NGINX com TLS automático pelo cert-manager e Let's Encrypt
- **Metrics Server** — coleta de métricas de CPU e memória dos nós e pods, necessário para o Kubernetes Dashboard e para o `kubectl top`
- **UDP Health Check** — servidor UDP em Java que responde a requisições `PING/PONG`, necessário para liberar as verificações de saúde UDP no Network Load Balancer da OCI e manter o Overall Health `OK`

---

## Arquitetura

```
Internet
    │
    ▼
┌──────────────────────────────────────────────────────────────┐
│              IP Público Reservado (OCI)                      │
│                                                              │
│          Network Load Balancer (Always Free)                 │
│   ┌──────────────────────────────────────────────────────┐   │
│   │  TCP :22    → leader        (SSH)                    │   │
│   │  TCP :6443  → leader        (kubectl / API Server)   │   │
│   │  TCP :80    → workers       (NodePort 30080 - HTTP)  │   │
│   │  TCP :443   → workers       (NodePort 30443 - HTTPS) │   │
│   │  UDP :1700  → workers       (UDP Health Check)       │   │
│   │  UDP :1710  → workers       (UDP Health Check)       │   │
│   └──────────────────────────────────────────────────────┘   │
│                                                              │
│   Virtual Cloud Network (VCN) — 10.0.0.0/16                 │
│   ┌──────────────────────────────────────────────────────┐   │
│   │  Subnet Pública — 10.0.0.0/24                       │   │
│   │                                                      │   │
│   │  ┌──────────────────────────────────────────────┐   │   │
│   │  │  leader (Control Plane)                      │   │   │
│   │  │  VM.Standard.A1.Flex · Ubuntu 24.04 ARM64    │   │   │
│   │  │  1 OCPU · 3 GB RAM · 50 GB Boot Volume       │   │   │
│   │  └──────────────────────────────────────────────┘   │   │
│   │                                                      │   │
│   │  ┌────────────┐  ┌────────────┐  ┌────────────┐    │   │
│   │  │  worker-0  │  │  worker-1  │  │  worker-2  │    │   │
│   │  │  A1.Flex   │  │  A1.Flex   │  │  A1.Flex   │    │   │
│   │  │  1 OCPU    │  │  1 OCPU    │  │  1 OCPU    │    │   │
│   │  │  7 GB RAM  │  │  7 GB RAM  │  │  7 GB RAM  │    │   │
│   │  │  50 GB     │  │  50 GB     │  │  50 GB     │    │   │
│   │  └────────────┘  └────────────┘  └────────────┘    │   │
│   └──────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘

Total ARM: 4 OCPUs + 24 GB RAM → exatamente no limite Always Free

Namespace oci-devops
├── Homepage (nginx-deployment)         → k8s.seudominio.com.br/
├── UDP Health Check :1700 (DaemonSet)  → Libera porta UDP 1700 no NLB
└── UDP Health Check :1710 (DaemonSet)  → Libera porta UDP 1710 no NLB

Namespace kube-system
└── Metrics Server                      → kubectl top / Kubernetes Dashboard
```

> O acesso SSH aos workers é feito via **SSH jump** através do `leader`, que serve como bastion host. O Load Balancer roteia a porta 22 diretamente ao `leader`.

---

## Módulos de Infraestrutura

O código Terraform é organizado em módulos executados sequencialmente:

| Módulo | Diretório | Responsabilidade |
|---|---|---|
| `compartment` | `./compartment` | Cria o compartimento OCI `k8s-on-arm-oci-always-free` |
| `network` | `./network` | VCN, subnet pública, Security Lists, Load Balancer, IP reservado |
| `compute` | `./compute` | Instâncias ARM: 1 leader + 3 workers (Ubuntu 24.04 AArch64) |
| `k8s` | `./k8s` | Bootstrap via kubeadm, join dos workers, CNI Flannel, kubeconfig |
| `k8s_scaffold` | `./k8s-scaffold` | Apps de scaffolding: Ingress NGINX, cert-manager, Dashboard, LetsEncrypt |
| `oci-infra_ci_cd` | `./oci_artifacts_container_repository` | Repositórios ARM64 no OCI Container Registry |

---

## Aplicações Padrão do Cluster

Após a infraestrutura estar de pé, três aplicações são implantadas manualmente no namespace **`oci-devops`** usando os manifests organizados em `00.homepage/`, `01.metrics_server/` e `02.udp_health_check-nlb_oci/`. Cada uma possui scripts de deploy e destroy prontos.

### 00. Homepage (nginx)

Serve a página de apresentação do domínio principal do cluster, acessível via HTTPS com certificado TLS emitido automaticamente pelo **cert-manager + Let's Encrypt**.

**Fluxo de acesso:**
```
https://k8s.seudominio.com.br
    → NLB :443
    → NodePort 30443 (workers)
    → Ingress NGINX
    → Service nginx-service :80 (ClusterIP)
    → Pod nginx-deployment (imagem ARM64 do OCI Container Registry)
```

**Tecnologias:** NGINX, cert-manager v1.12.3, Let's Encrypt (produção e staging), Ingress NGINX

**Imagem:** `gru.ocir.io/<namespace>/homepage-80_platform_linux-arm64:latest`

**Kubernetes resources (namespace `oci-devops`):**

| Kind | Nome | Descrição |
|---|---|---|
| `Namespace` | `oci-devops` | Namespace principal das aplicações do projeto |
| `Deployment` | `nginx-deployment` | 1 réplica do NGINX servindo o `index.html` |
| `Service` | `nginx-service` | ClusterIP na porta 80 |
| `Ingress` | `nginx-ingress` | TLS via `letsencrypt-prod`, host `k8s.seudominio.com.br` |
| `ClusterIssuer` | `letsencrypt-prod` | Emissão de certificados via ACME HTTP-01 |
| `ClusterIssuer` | `letsencrypt-staging` | Ambiente de testes do Let's Encrypt |

**Deploy / Destroy:**
```bash
cd 00.homepage/00.UsefulScripts/

chmod +x 01.deploy_homepage-nginx_script.sh
bash 01.deploy_homepage-nginx_script.sh

# Para remover:
chmod +x 02.destroy_homepage-nginx_script.sh
bash 02.destroy_homepage-nginx_script.sh
```

**Build da imagem (ARM64) para o OCI Container Registry:**
```bash
# Autenticar no OCI Registry
docker login -u <namespace>/<seu_email> -p "<auth_token>" gru.ocir.io

# Build e push para ARM64
docker buildx build \
  --platform linux/arm64 \
  -t gru.ocir.io/<namespace>/homepage-80_platform_linux-arm64:latest \
  --no-cache --push .
```

---

### 01. Metrics Server

Instala o **Metrics Server** no cluster, habilitando a coleta de métricas de uso de CPU e memória de nós e pods. É um pré-requisito para o funcionamento pleno do **Kubernetes Dashboard** e do comando `kubectl top`.

> O Metrics Server é configurado com `--kubelet-insecure-tls` e `--kubelet-preferred-address-types=InternalIP` para funcionar corretamente com as instâncias ARM da OCI, onde os certificados do kubelet não possuem SAN validável externamente.

**Kubernetes resources (namespace `kube-system`):**

| Kind | Nome | Versão da imagem |
|---|---|---|
| `ServiceAccount` | `metrics-server` | — |
| `ClusterRole` | `system:aggregated-metrics-reader` + `metrics-server` | — |
| `ClusterRoleBinding` | `metrics-server` | — |
| `RoleBinding` | `metrics-server-auth-reader` | — |
| `Deployment` | `metrics-server` | `registry.k8s.io/metrics-server/metrics-server:v0.7.2` |
| `Service` | `metrics-server` | ClusterIP :443 |
| `APIService` | `v1beta1.metrics.k8s.io` | Registra a API de métricas no cluster |

**Deploy / Destroy:**
```bash
cd 01.metrics_server/00.UsefulScripts/

chmod +x 01.deploy_metrics_server_script.sh
bash 01.deploy_metrics_server_script.sh

# Para remover:
chmod +x 02.destroy_metrics_server_script.sh
bash 02.destroy_metrics_server_script.sh
```

**Verificar funcionamento:**
```bash
kubectl top nodes
kubectl top pods -A
```

---

### 02. UDP Health Check — NLB OCI

#### Por que este serviço é necessário

O **Network Load Balancer (NLB) da Oracle Cloud** monitora continuamente a saúde de cada listener configurado. Para cada porta — incluindo portas UDP — o NLB executa verificações de saúde periódicas nos backends (os nós workers). Enquanto essas verificações não passarem, o status do NLB fica em **`Overall Health: Critical`** no console da OCI, e o tráfego destinado àquelas portas não é roteado.

O problema com UDP é que, ao contrário do TCP, não há handshake — o NLB precisa que a aplicação escutando na porta responda ativamente a um pacote de verificação. Sem uma resposta, o backend é marcado como **unhealthy** e a porta permanece bloqueada, mantendo o Overall Health em estado crítico mesmo com o cluster e as outras portas TCP funcionando perfeitamente.

```
Estado sem o UDP Health Check:
┌─────────────────────────────────────────────┐
│  NLB Overall Health: ⚠️  CRITICAL            │
│                                             │
│  Listener TCP  :22   → ✅ Healthy           │
│  Listener TCP  :6443 → ✅ Healthy           │
│  Listener TCP  :80   → ✅ Healthy           │
│  Listener TCP  :443  → ✅ Healthy           │
│  Listener UDP  :1700 → ❌ Critical          │  ← sem resposta UDP
│  Listener UDP  :1710 → ❌ Critical          │  ← sem resposta UDP
└─────────────────────────────────────────────┘

Estado com o UDP Health Check implantado:
┌─────────────────────────────────────────────┐
│  NLB Overall Health: ✅ OK                  │
│                                             │
│  Listener TCP  :22   → ✅ Healthy           │
│  Listener TCP  :6443 → ✅ Healthy           │
│  Listener TCP  :80   → ✅ Healthy           │
│  Listener TCP  :443  → ✅ Healthy           │
│  Listener UDP  :1700 → ✅ Healthy           │  ← PONG recebido
│  Listener UDP  :1710 → ✅ Healthy           │  ← PONG recebido
└─────────────────────────────────────────────┘
```

> ⚠️ **O Overall Health do NLB só fica `OK` quando todos os listeners estão saudáveis.** Enquanto as portas UDP 1700 e 1710 estiverem sem resposta, o status permanece `Critical` — mesmo que todo o tráfego TCP esteja fluindo normalmente. Este serviço é, portanto, **obrigatório** para um ambiente operacional limpo na OCI.

#### Como funciona

O `UdpHealthCheckServer.java` é um servidor UDP minimalista em Java que:
1. Abre um socket UDP na porta configurada
2. Aguarda um pacote com a mensagem `PING`
3. Responde imediatamente com `PONG` ao remetente
4. Repete o ciclo indefinidamente

```
Ciclo de verificação do NLB (a cada ~10 segundos):

NLB OCI
 ├── Listener UDP :1700
 │     ├── Health Check → envia "PING" UDP para worker-0 :1700
 │     │                       └── UdpHealthCheckServer (hostNetwork: true)
 │     │                               └── recebe "PING" → responde "PONG"
 │     │                                       └── ✅ worker-0 marcado como Healthy
 │     ├── Health Check → envia "PING" UDP para worker-1 :1700
 │     │                       └── UdpHealthCheckServer (hostNetwork: true)
 │     │                               └── recebe "PING" → responde "PONG"
 │     │                                       └── ✅ worker-1 marcado como Healthy
 │     └── Health Check → envia "PING" UDP para worker-2 :1700
 │                             └── UdpHealthCheckServer (hostNetwork: true)
 │                                     └── recebe "PING" → responde "PONG"
 │                                             └── ✅ worker-2 marcado como Healthy
 │
 └── Listener UDP :1710
       ├── Health Check → envia "PING" UDP para worker-0 :1710  → ✅ Healthy
       ├── Health Check → envia "PING" UDP para worker-1 :1710  → ✅ Healthy
       └── Health Check → envia "PING" UDP para worker-2 :1710  → ✅ Healthy

Resultado: todos os 6 backends (3 workers × 2 portas) Healthy → Overall Health: ✅ OK
```

O uso de `hostNetwork: true` nos pods é intencional e essencial: faz com que o servidor UDP escute diretamente no IP da interface de rede do nó worker, tornando-o alcançável pelo NLB sem intermediação do kube-proxy — que não funciona com UDP da mesma forma que com TCP.

#### Kubernetes resources (namespace `oci-devops`)

| Kind | Nome | Porta | Réplicas / Escopo | Descrição |
|---|---|---|---|---|
| `Deployment` | `udp-app-with-healthcheck-1700-deployment` | UDP 1700 | 1 réplica | Pod com `hostNetwork: true` |
| `DaemonSet` | `udp-app-with-healthcheck-1700-daemon-set` | UDP 1700 | Todos os workers | Garante presença em cada nó |
| `Service` | `udp-1700-app-service` | UDP 1700 | ClusterIP | Seletor para o Deployment |
| `Service` | `udp-1700-daemon-set-service` | UDP 1700 | ClusterIP | Seletor para o DaemonSet |
| `Deployment` | `udp-app-with-healthcheck-1710-deployment` | UDP 1710 | 1 réplica | Pod com `hostNetwork: true` |
| `DaemonSet` | `udp-app-with-healthcheck-1710-daemon-set` | UDP 1710 | Todos os workers | Garante presença em cada nó |
| `Service` | `udp-1710-app-service` | UDP 1710 | ClusterIP | Seletor para o Deployment |
| `Service` | `udp-1710-daemon-set-service` | UDP 1710 | ClusterIP | Seletor para o DaemonSet |

#### Imagens no OCI Container Registry

```
gru.ocir.io/<DOCKER_OBJECT_STORAGE_NAMESPACE>/udp-health-check-server-1700_platform_linux-arm64:latest
gru.ocir.io/<DOCKER_OBJECT_STORAGE_NAMESPACE>/udp-health-check-server-1710_platform_linux-arm64:latest
```

#### Passo 1 — Build das imagens ARM64

Antes de implantar, as imagens precisam existir no OCI Container Registry.

```bash
# Habilitar suporte a ARM64 no Docker (apenas uma vez por máquina)
docker run --privileged --rm tonistiigi/binfmt --install all

# Autenticar no OCI Container Registry
docker login -u '<DOCKER_OBJECT_STORAGE_NAMESPACE>/<seu_email>' \
             -p '<auth_token>' \
             gru.ocir.io

# Entrar na pasta da aplicação UDP
cd 02.udp_health_check-nlb_oci/

# Build e push — imagem para a porta 1700
docker buildx build \
  --platform linux/arm64 \
  -t gru.ocir.io/<DOCKER_OBJECT_STORAGE_NAMESPACE>/udp-health-check-server-1700_platform_linux-arm64:latest \
  --no-cache --push .

# Build e push — imagem para a porta 1710
docker buildx build \
  --platform linux/arm64 \
  -t gru.ocir.io/<DOCKER_OBJECT_STORAGE_NAMESPACE>/udp-health-check-server-1710_platform_linux-arm64:latest \
  --no-cache --push .
```

#### Passo 2 — Criar o Secret de acesso ao OCI Registry

O Kubernetes precisa de credenciais para fazer pull das imagens privadas do OCI Registry:

```bash
# Criar o namespace se ainda não existir
kubectl create namespace oci-devops --dry-run=client -o yaml | kubectl apply -f -

# Criar o Secret de autenticação no namespace oci-devops
kubectl create secret docker-registry oci-registry-secret \
  --docker-server=gru.ocir.io \
  --docker-username='<DOCKER_OBJECT_STORAGE_NAMESPACE>/<seu_email>' \
  --docker-password='<auth_token>' \
  --docker-email='<seu_email>' \
  -n oci-devops

# Confirmar a criação
kubectl get secret oci-registry-secret -n oci-devops
```

#### Passo 3 — Implantar os serviços UDP

```bash
cd 02.udp_health_check-nlb_oci/00.UsefulScripts/

chmod +x 01.deploy_udp_health_check_server_nlb_oci_script.sh
bash 01.deploy_udp_health_check_server_nlb_oci_script.sh
```

Ou aplicar os manifests manualmente na ordem correta:

```bash
cd 02.udp_health_check-nlb_oci/kubernetes/

kubectl apply -f 01.create__Namespace.yaml
kubectl apply -f 02.udp-health-check-server-1700__Deployment.yaml    -n oci-devops
kubectl apply -f 03.udp-health-check-server-1700__Service.yaml        -n oci-devops
kubectl apply -f 04.udp-health-check-server-1700__DaemonSet.yaml      -n oci-devops
kubectl apply -f 05.udp-health-check-server-1700__Service-DaemonSet.yaml -n oci-devops
kubectl apply -f 06.udp-health-check-server-1710__Deployment.yaml    -n oci-devops
kubectl apply -f 07.udp-health-check-server-1710__Service.yaml        -n oci-devops
kubectl apply -f 08.udp-health-check-server-1710__DaemonSet.yaml      -n oci-devops
kubectl apply -f 09.udp-health-check-server-1710__Service-DaemonSet.yaml -n oci-devops
```

#### Passo 4 — Verificar o estado dos pods

```bash
# Listar todos os pods do namespace oci-devops
kubectl get pods -n oci-devops -o wide

# Verificar os DaemonSets (deve haver 1 pod por worker = 3 pods por DaemonSet)
kubectl get daemonset -n oci-devops

# Saída esperada:
# NAME                                      DESIRED   CURRENT   READY   NODE SELECTOR
# udp-app-with-healthcheck-1700-daemon-set  3         3         3       <none>
# udp-app-with-healthcheck-1710-daemon-set  3         3         3       <none>

# Descrever um pod para confirmar hostNetwork: true
kubectl describe pod -l app=udp-1700 -n oci-devops | grep -A2 "Host Network"
```

#### Passo 5 — Testar o PING/PONG manualmente

Para confirmar que o servidor está respondendo antes de aguardar o NLB:

```bash
# A partir de qualquer máquina com acesso à rede (substituir pelo IP de um worker)
echo "PING" | nc -u -w2 <IP_DO_WORKER> 1700
# Resposta esperada: PONG

echo "PING" | nc -u -w2 <IP_DO_WORKER> 1710
# Resposta esperada: PONG

# Ou a partir de dentro do cluster (em um pod de debug)
kubectl run debug --image=busybox --restart=Never -it --rm -- \
  sh -c 'echo "PING" | nc -u -w2 <IP_DO_WORKER> 1700'
```

#### Passo 6 — Confirmar o Overall Health no console da OCI

Após implantar os serviços e aguardar de 1 a 2 minutos para o NLB executar as verificações:

1. Acesse o **Console OCI** → **Networking → Load Balancers → Network Load Balancers**
2. Selecione o NLB do cluster (`k8s-arm-oci-always-free` ou o nome configurado)
3. Verifique o campo **Overall Health** — deve exibir `OK` (verde)
4. Em **Backend Sets**, confirme que todos os backends nas portas 1700 e 1710 estão com status `Healthy`

#### Remover os serviços UDP

```bash
cd 02.udp_health_check-nlb_oci/00.UsefulScripts/

chmod +x 02.destroy_udp_health_check_server_nlb_oci_script.sh
bash 02.destroy_udp_health_check_server_nlb_oci_script.sh
```

> ⚠️ Remover estes serviços sem antes remover os listeners UDP do NLB fará o **Overall Health voltar para `Critical`** imediatamente.

---

## Pré-requisitos

### Conta Oracle Cloud

- Conta ativa na [Oracle Cloud](https://cloud.oracle.com) com o plano **Always Free** disponível
- Tenancy OCID, User OCID, API Key Fingerprint e chave privada configurados
- Verifique os limites da sua região em **Governance → Limits, Quotas and Usage** — o limite de 4 OCPUs ARM é compartilhado por toda a conta

### Ferramentas Locais

| Ferramenta | Versão Mínima | Descrição |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | `>= 1.3` | Provisionamento IaC (ou use OpenTofu) |
| [OpenTofu](https://opentofu.org/docs/intro/install/) | `>= 1.6` | Fork open-source do Terraform |
| [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) | `>= 3.x` | Interação com a OCI via terminal |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | `>= 1.31` | Gerenciamento do cluster |
| [Docker](https://docs.docker.com/engine/install/) com Buildx | `>= 24.x` | Build de imagens ARM64 via `docker buildx` |
| [Git](https://git-scm.com/) | `>= 2.x` | Controle de versão |

> O projeto usa o **provider OCI** `>= 6.35.0` e o **provider null** `3.1.0`.

### Chave SSH (Ed25519)

```bash
ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -C "seu_email@seudominio.com"
```

Caminhos esperados:
- **Linux/macOS:** `~/.ssh/id_ed25519` e `~/.ssh/id_ed25519.pub`
- **Windows:** `C:\Users\..\.ssh\id_ed25519` e `C:\Users\..\.ssh\id_ed25519.pub`

### Chave de API OCI

```bash
mkdir -p ~/.oci
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem
```

Adicione `oci_api_key_public.pem` em **Identity → Users → (seu usuário) → API Keys → Add API Key** e copie o fingerprint exibido.

---

## Recursos Always Free Utilizados

| Recurso OCI | Shape / Tipo | Configuração | Qtd |
|---|---|---|---|
| **Instância ARM (leader)** | `VM.Standard.A1.Flex` | 1 OCPU · 3 GB RAM · 50 GB Boot Volume | 1 |
| **Instância ARM (workers)** | `VM.Standard.A1.Flex` | 1 OCPU · 7 GB RAM · 50 GB Boot Volume | 3 |
| **Network Load Balancer** | Always Free NLB | 10 Mbps | 1 |
| **IP Público Reservado** | `RESERVED` | Fixo, persistente mesmo após destroy | 1 |
| **Virtual Cloud Network** | VCN + Subnet Pública | CIDR `10.0.0.0/16` / `10.0.0.0/24` | 1 |
| **OCI Container Registry** | Always Free | Repositórios de imagens ARM64 | Ilimitado* |

**Total ARM:** 4 OCPUs + 24 GB RAM — exatamente no limite Always Free.

> ⚠️ O **IP Público Reservado** e as **instâncias de compute** possuem `prevent_destroy = true` no código Terraform, protegendo contra destruição acidental. Para removê-los é necessário editar os arquivos `.tf` antes de executar o `destroy`.

---

## Tecnologias e Componentes

### Infraestrutura

| Tecnologia | Detalhe | Função |
|---|---|---|
| **Terraform / OpenTofu** | OCI Provider `>= 6.35.0`, null `3.1.0` | IaC — provisionamento completo |
| **Oracle Cloud (OCI)** | Ampere A1 ARM | Plataforma de nuvem |
| **Ubuntu Server** | `24.04 LTS (AArch64)` | SO das instâncias |
| **Image OCI** | `Canonical-Ubuntu-24.04-aarch64-2026.02.28-0` | Imagem base utilizada |

### Kubernetes (Bootstrap)

| Componente | Versão | Função |
|---|---|---|
| **kubeadm** | `v1.31` (canal estável) | Bootstrap do cluster |
| **kubelet** | `v1.31` | Agente em cada nó |
| **kubectl** | `v1.31` | CLI de gerenciamento |
| **containerd** | Via Docker APT | Container runtime (CRI) |
| **Flannel** | Última estável | CNI — rede dos Pods (`10.244.0.0/16`) |

> O `kubeadm init` usa `--ignore-preflight-errors=NumCPU,Mem` para contornar os requisitos mínimos padrão, viabilizando o uso das shapes Always Free.

### Aplicações do Scaffold (Terraform)

| Aplicação | Namespace | Função |
|---|---|---|
| **NGINX Ingress Controller** | `ingress-nginx` | Ingress HTTP/HTTPS (NodePort 30080/30443) |
| **cert-manager** | `cert-manager` | Gerenciamento automático de certificados TLS |
| **Let's Encrypt Issuer** | `cert-manager` | Certificados HTTPS gratuitos via ACME |
| **Kubernetes Dashboard** | `kubernetes-dashboard` | Interface Web do cluster |

### Aplicações Padrão (Manifests)

| Aplicação | Namespace | Versão / Imagem | Função |
|---|---|---|---|
| **Homepage (NGINX)** | `oci-devops` | `nginx:latest` (ARM64) | Página de apresentação do domínio |
| **Metrics Server** | `kube-system` | `metrics-server:v0.7.2` | Métricas de CPU/RAM para Dashboard e `kubectl top` |
| **UDP Health Check :1700** | `oci-devops` | Java (ARM64, OCI Registry) | Libera porta UDP 1700 no NLB (PING/PONG) |
| **UDP Health Check :1710** | `oci-devops` | Java (ARM64, OCI Registry) | Libera porta UDP 1710 no NLB (PING/PONG) |

---

## Estrutura do Repositório

```
.
├── README.md
├── LICENSE
│
├── main.tf                          # Orquestra todos os módulos Terraform
├── inputs.tf                        # Variáveis globais
├── providers.tf                     # Providers OCI (>= 6.35.0) e null (3.1.0)
├── variables.auto.tfvars            # Suas credenciais reais (não versionar!)
├── variables.auto.tfvars.example    # Template para novos usuários
│
├── compartment/                     # Módulo: Compartimento OCI
├── network/                         # Módulo: VCN, Subnet, LB, IP
├── compute/                         # Módulo: VMs ARM leader + workers
├── k8s/                             # Módulo: Bootstrap Kubernetes
│   └── scripts/                     # Scripts de init/join/reset/network
├── k8s-scaffold/                    # Módulo: Apps de scaffolding
│   └── apps/                        # YAMLs: Ingress, cert-manager, Dashboard
├── oci_artifacts_container_repository/  # Módulo: OCI Container Registry
│
├── 00.homepage/                     # App: Página inicial do domínio
│   ├── Dockerfile                   # FROM nginx:latest + index.html
│   ├── index.html                   # Página HTML da homepage
│   ├── ci_cd.yaml                   # GitHub Actions: build ARM64 + deploy
│   ├── docker/                      # docker-compose para teste local
│   ├── 00.UsefulScripts/            # Scripts de deploy e destroy
│   │   ├── 01.deploy_homepage-nginx_script.sh
│   │   └── 02.destroy_homepage-nginx_script.sh
│   └── kubernetes/
│       ├── 01.homepage-nginx__Namespace.yaml          # Namespace oci-devops
│       ├── 02.homepage-nginx__Deployment.yaml         # Deployment NGINX ARM64
│       ├── 03.homepage-nginx__Service.yaml            # Service ClusterIP :80
│       ├── 04.homepage-nginx-cert-manager__...yaml    # cert-manager v1.12.3 completo
│       ├── 05.homepage-nginx-letsencrypt-issuer__...yaml  # ClusterIssuers prod + staging
│       └── 06.homepage-nginx__Ingress.yaml            # Ingress TLS letsencrypt-prod
│
├── 01.metrics_server/               # App: Metrics Server
│   ├── 00.UsefulScripts/
│   │   ├── 01.deploy_metrics_server_script.sh
│   │   └── 02.destroy_metrics_server_script.sh
│   └── kubernetes/
│       ├── 00.metrics-server__Full.yaml               # Manifesto único completo
│       ├── 01.metrics-server__Namespace.yaml
│       ├── 02.metrics-server__ServiceAccount.yaml
│       ├── 03.metrics-server__ClusterRole.yaml
│       ├── 04.metrics-server__RoleBinding.yaml
│       ├── 05.metrics-server__ClusterRoleBinding.yaml
│       ├── 06.metrics-server__Deployment.yaml         # metrics-server:v0.7.2
│       ├── 07.metrics-server__Service.yaml
│       └── 08.metrics-server__ApiService.yaml         # v1beta1.metrics.k8s.io
│
├── 02.udp_health_check-nlb_oci/     # App: UDP Health Check para NLB OCI
│   ├── 00.UsefulScripts/
│   │   ├── 01.deploy_udp_health_check_server_nlb_oci_script.sh
│   │   └── 02.destroy_udp_health_check_server_nlb_oci_script.sh
│   └── kubernetes/
│       ├── 01.create__Namespace.yaml
│       ├── 02.udp-health-check-server-1700__Deployment.yaml   # hostNetwork: true
│       ├── 03.udp-health-check-server-1700__Service.yaml      # UDP ClusterIP :1700
│       ├── 04.udp-health-check-server-1700__DaemonSet.yaml    # 1 pod por worker
│       ├── 05.udp-health-check-server-1700__Service-DaemonSet.yaml
│       ├── 06.udp-health-check-server-1710__Deployment.yaml
│       ├── 07.udp-health-check-server-1710__Service.yaml      # UDP ClusterIP :1710
│       ├── 08.udp-health-check-server-1710__DaemonSet.yaml    # 1 pod por worker
│       ├── 09.udp-health-check-server-1710__Service-DaemonSet.yaml
│       ├── Dockerfile                                # Build da imagem Java ARM64
│       └── UdpHealthCheckServer.java                 # Servidor UDP PING/PONG em Java
│
├── 03.chirpstack_v3/                # App: ChirpStack v3 — Namespace chirpstack-v3
│   ├── 00.UsefulScripts/
│   │   ├── 00.pgpass__move_to_user_directory        # Arquivo .pgpass (sem senha no psql)
│   │   ├── 01.deploy_chirpstack-v3_script.sh        # Deploy completo com kubectl wait
│   │   ├── 02.destroy_chirpstack-v3_script.sh       # Remove todos os recursos
│   │   ├── 03.back-up_chirpstack-v3_script.sh       # Backup dos 2 bancos PostgreSQL
│   │   └── 04.restore_chirpstack-v3_script.sh       # Restore dos backups
│   ├── 00.useful_commands.txt                       # Comandos úteis do dia a dia
│   ├── docker/
│   │   └── docker-compose.yaml                      # Stack local para testes
│   └── kubernetes/
│       ├── 01.create__Namespace.yaml                # Namespace chirpstack-v3
│       ├── 02.chirpstack-v3-mosquitto__ConfigMap.yaml        # mosquitto.conf (sem TLS)
│       ├── 03.chirpstack-v3-mosquitto__Deployment.yaml       # eclipse-mosquitto:2.0.22
│       ├── 04.chirpstack-v3-mosquitto__Service.yaml          # TCP :1888→1883
│       ├── 05.chirpstack-v3-ns-as-postgresql-claim0__        # PVC initdb scripts (100Mi)
│       │     StorageClass__PersistentVolume__PersistentVolumeClaim.yaml
│       ├── 06.chirpstack-v3-ns-as-create-attach-pvc__Pod.yaml  # Pod auxiliar de init
│       ├── 07.chirpstack-v3-postgresql/             # Scripts SQL de inicialização dos bancos
│       │   ├── 001.init-chirpstack-v3_ns.sh         # Cria DB + usuário chirpstack_ns
│       │   ├── 002.init-chirpstack-v3_as.sh         # Cria DB + usuário chirpstack_as
│       │   ├── 003.chirpstack-v3_as_trgm.sh         # Extensão pg_trgm no AS
│       │   └── 004.chirpstack-v3_as_hstore.sh       # Extensão hstore no AS
│       ├── 08.chirpstack-v3-ns-postgresql-data__    # PV + PVC dados PostgreSQL NS (10Gi)
│       │     StorageClass__PersistentVolume__PersistentVolumeClaim.yaml
│       ├── 09.chirpstack-v3-as-postgresql-data__    # PV + PVC dados PostgreSQL AS (10Gi)
│       │     StorageClass__PersistentVolume__PersistentVolumeClaim.yaml
│       ├── 10.chirpstack-v3-ns-as-postgresql__ConfigMap.yaml  # Scripts init via ConfigMap
│       ├── 11.chirpstack-v3-ns-postgresql__Deployment.yaml    # postgres:14-alpine — NS
│       ├── 12.chirpstack-v3-ns-postgresql__Service.yaml       # TCP :5437→5432
│       ├── 13.chirpstack-v3-as-postgresql__Deployment.yaml    # postgres:14-alpine — AS
│       ├── 14.chirpstack-v3-as-postgresql__Service.yaml       # TCP :5438→5433
│       ├── 15.chirpstack-v3-redis-data__            # PV + PVC dados Redis (1Gi)
│       │     StorageClass__PersistentVolume__PersistentVolumeClaim.yaml
│       ├── 16.chirpstack-v3-redis__Deployment.yaml            # redis:7.2
│       ├── 17.chirpstack-v3-redis__Service.yaml               # TCP :6384→6379
│       ├── 18.chirpstack-v3-gateway-bridge__ConfigMap.yaml    # Config TOML — banda AU915
│       ├── 19.chirpstack-v3-gateway-bridge__Deployment.yaml   # chirpstack-gateway-bridge:3.14.8
│       ├── 20.chirpstack-v3-gateway-bridge__Service.yaml      # UDP :1700
│       ├── 21.chirpstack-v3-network-server__ConfigMap.yaml    # Config TOML — NetID FFFFFF
│       ├── 22.chirpstack-v3-network-server__Deployment.yaml   # chirpstack-network-server:3.16.8
│       ├── 23.chirpstack-v3-network-server__Service.yaml      # TCP :8000
│       ├── 24.chirpstack-v3-application-server__Deployment.yaml   # (sem Secret — comentado)
│       ├── 25.chirpstack-v3-application-server__ConfigMap.yaml    # Config TOML — jwt_secret
│       ├── 26.chirpstack-v3-application-server__Secret.yaml       # DSNs + JWT + MQTT creds
│       ├── 27.chirpstack-v3-application-server__Deployment.yaml   # chirpstack-app-server:3.17.9
│       ├── 28.chirpstack-v3-application-server__Service.yaml      # TCP :8001/:8003/:443/:8101
│       ├── 29.chirpstack-v3-application-server-cert-manager__...yaml  # (comentado — no scaffold)
│       ├── 30.chirpstack-v3-application-server-letsencrypt-issuer__...yaml  # (comentado)
│       ├── 31.chirpstack-v3-application-server__Ingress.yaml      # HTTPS + TLS Let's Encrypt
│       └── 32.chirpstack-v3-toolbox__Deployment.yaml              # nicolaka/netshoot (debug)
│
└── 04.chirpstack_v4/                # App: ChirpStack v4 — Namespace chirpstack-v4
    ├── 00.UsefulScripts/
    │   ├── 00.pgpass__move_to_user_directory        # Arquivo .pgpass (sem senha no psql)
    │   ├── 01.deploy_chirpstack-v4_script.sh        # Deploy completo com kubectl wait
    │   ├── 02.destroy_chirpstack-v4_script.sh       # Remove todos os recursos
    │   ├── 03.back-up_chirpstack-v4_script.sh       # Backup do banco PostgreSQL
    │   └── 04.restore_chirpstack-v4_script.sh       # Restore do backup
    ├── 00.useful_commands.txt                       # Comandos úteis do dia a dia
    ├── docker/
    │   └── docker-compose.yaml                      # Stack local para testes
    ├── mqtt-certs/                                  # Certificados TLS do Mosquitto (CA própria)
    │   ├── ca.key                    🔒 NÃO versionar — chave privada da CA
    │   ├── ca.crt                    ✅ Distribuir aos clientes (ChirpStack, gateways)
    │   ├── ca.srl                       Número serial da CA
    │   ├── server-openssl.cnf           Config OpenSSL com SANs internos + domínio público
    │   ├── server.key                   Chave privada do servidor Mosquitto
    │   ├── server.csr                   Requisição de assinatura (intermediário)
    │   ├── server.crt                ✅ Certificado do servidor (assinado pela CA)
    │   └── passwd                       Usuários MQTT com hash bcrypt
    └── kubernetes/
        ├── 01.create__Namespace.yaml                # Namespace chirpstack-v4
        ├── 02.chirpstack-v4-mosquitto__ConfigMap.yaml        # mosquitto.conf (TLS :8883)
        ├── 03.chirpstack-v4-mosquitto__Deployment.yaml       # eclipse-mosquitto:2.0.22
        ├── 04.chirpstack-v4-mosquitto__Service.yaml          # TCP :8883 (MQTTS)
        ├── 05.chirpstack-v4-postgresql__             # PV + PVC dados PostgreSQL (10Gi)
        │     StorageClass__PersistentVolume__PersistentVolumeClaim.yaml
        ├── 06.chirpstack-v4-postgresql__ConfigMap.yaml       # Script de init do banco único
        ├── 07.chirpstack-v4-postgresql__Deployment.yaml      # postgres:17.5
        ├── 08.chirpstack-v4-postgresql__Service.yaml         # TCP :5442→5432
        ├── 09.chirpstack-v4-redis__                 # PV + PVC dados Redis (1Gi)
        │     StorageClass__PersistentVolume__PersistentVolumeClaim.yaml
        ├── 10.chirpstack-v4-redis__Deployment.yaml           # redis:7.2
        ├── 11.chirpstack-v4-redis__Service.yaml              # TCP :6389→6379
        ├── 12.chirpstack-v4-bridge-gateway__ConfigMap.yaml   # Config TOML — MQTTS AU915
        ├── 13.chirpstack-v4-bridge-gateway__Deployment.yaml  # chirpstack-gateway-bridge:4.1
        ├── 14.chirpstack-v4-bridge-gateway__Service.yaml     # UDP :1710→1700
        ├── 15.chirpstack-v4__                        # PV + PVC dados dispositivos (500Mi)
        │     StorageClass__PersistentVolume__PersistentVolumeClaim.yaml
        ├── 16.chirpstack-v4__ConfigMap.yaml          # chirpstack.toml + regiões LoRaWAN
        ├── 17.chirpstack-v4__Deployment.yaml         # chirpstack/chirpstack:4.15
        ├── 18.chirpstack-v4__Service.yaml            # TCP :443→8080
        ├── 19.chirpstack-v4-cert-manager__...yaml    # (comentado — já no scaffold)
        ├── 20.chirpstack-v4-letsencrypt-issuer__...yaml  # (comentado)
        ├── 21.chirpstack-v4__Ingress.yaml            # HTTPS + TLS Let's Encrypt (UI + gRPC)
        ├── 22.chirpstack-v4-rest-api__Deployment.yaml    # chirpstack-rest-api:4.15
        ├── 23.chirpstack-v4-rest-api__Service.yaml       # TCP :443→8090
        ├── 24.chirpstack-v4-rest-api-cert-manager__...yaml  # (comentado)
        ├── 25.chirpstack-v4-rest-api-letsencrypt-issuer__...yaml  # (comentado)
        ├── 26.chirpstack-v4-rest-api__Ingress.yaml   # HTTPS + TLS Let's Encrypt (REST API)
        └── 27.chirpstack-v4-toolbox__Deployment.yaml # nicolaka/netshoot (debug)
```

---

## Configuração de DNS — Subdomínios Obrigatórios

### Por que o registro DNS é obrigatório

Todos os serviços expostos via HTTPS neste cluster dependem do **cert-manager + Let's Encrypt** para emissão automática de certificados TLS. O Let's Encrypt usa o desafio **ACME HTTP-01**: ele acessa uma URL específica no seu domínio para provar que você é o dono antes de emitir o certificado.

Isso significa que **cada subdomínio precisa existir no seu DNS público e apontar para o IP do Load Balancer antes do deploy dos serviços**. Se o registro não existir ou ainda não propagou, o cert-manager ficará em loop tentando emitir o certificado e o Ingress não servirá HTTPS.

```
Let's Encrypt (ACME HTTP-01)
    │
    ├── Acessa http://chirpstack-v3.seudominio.com.br/.well-known/acme-challenge/...
    │         └── Resolve DNS → deve apontar para o IP do Load Balancer OCI
    │                  └── NLB :80 → worker NodePort 30080 → Ingress NGINX → cert-manager
    │                          └── ✅ Desafio aprovado → certificado emitido
    │
    └── Se o DNS não existir ou não apontar para o NLB → ❌ timeout → certificado não emitido
```

> O MQTT com TLS (porta `8883`) usa CA interna própria e **não depende de DNS público** para funcionar — apenas os serviços HTTP/HTTPS via Ingress precisam de registro DNS.

### Quando cadastrar os subdomínios

O momento ideal é **durante a execução do `tofu apply` (ou `terraform apply`)**, não depois. O módulo `network` — segundo a ser executado — provisiona o IP Público Reservado e o Load Balancer em poucos segundos após o início do apply. Assim que o IP aparecer no console OCI, você já pode cadastrar os registros DNS, e a propagação ocorrerá em paralelo ao restante do provisionamento do cluster.

```
tofu apply -parallelism=1
     │
     ├── ~30s → NLB + IP criados  ← 📌 CADASTRE OS REGISTROS DNS AQUI
     │                                  (propagação TTL=300 leva ~5 minutos)
     ├── ~5min  → VMs provisionadas
     ├── ~10min → cluster Kubernetes operacional
     ├── ~15min → cert-manager tenta emitir certificados
     │               └── ✅ DNS já propagado → certificados emitidos
     └── ~20-30min → apply concluído com tudo pronto
```

> Veja como obter o IP durante o apply na seção [Como obter o IP durante o apply](#como-obter-o-ip-durante-o-apply), dentro de **Implantação da Infraestrutura → Terraform → Passo 6**.

---

### Subdomínios necessários neste projeto

Abaixo estão todos os subdomínios que precisam ser cadastrados no seu provedor DNS, apontando para o **IP Público Reservado** do Load Balancer OCI:

| Subdomínio | Serviço | Tipo de registro | TTL sugerido |
|---|---|---|---|
| `k8s.seudominio.com.br` | Homepage NGINX + Kubernetes Dashboard | `A` | 300 |
| `chirpstack-v3.seudominio.com.br` | ChirpStack v3 — Application Server (UI) | `A` | 300 |
| `chirpstack-v4.seudominio.com.br` | ChirpStack v4 — Interface Web + API gRPC | `A` | 300 |
| `chirpstack-v4-rest-api.seudominio.com.br` | ChirpStack v4 — REST API | `A` | 300 |

> Todos os registros são do tipo `A` apontando para o mesmo IP — o IP Público Reservado do NLB, obtido com `terraform output -raw cluster_public_ip`.

---

### Como obter o IP do Load Balancer

```bash
# Via output do Terraform/OpenTofu
terraform output -raw cluster_public_ip

# Via kubectl (após o cluster estar de pé)
kubectl get service -n ingress-nginx ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Também disponível no console OCI:
# Networking → Load Balancers → Network Load Balancers → (seu NLB) → IP Address
```

---

### Exemplo prático — Registro `.com.br` (Registro.br)

No Registro.br, o gerenciamento de DNS é feito em **registro.br → Domínios → (seu domínio) → Editar zona DNS**.

> ⚠️ **Atenção — Modo Avançado obrigatório:** por padrão, o painel do Registro.br opera no **modo básico**, que não permite cadastrar subdomínios personalizados. Para adicionar os registros `A` necessários para este cluster, é preciso ativar o **Modo Avançado** na seção de zona DNS.
>
> Acesse: [registro.br → Painel → Domínios → (seu domínio) → DNS → Configurar zona DNS](https://registro.br/painel/dominios/) e procure pela opção **"Modo Avançado"** ou **"Edição avançada de zona"**.
>
> **A ativação do modo avançado pode levar em média 2 horas para ser processada pelo Registro.br** — portanto, ative-o com antecedência, idealmente antes mesmo de iniciar o provisionamento do cluster, para que quando o IP do NLB estiver disponível o painel já esteja liberado para edição.

```
Fluxo recomendado de tempo:

Dia anterior (ou horas antes):
└── Ativar Modo Avançado no Registro.br  ← aguardar ~2 horas para processar

Durante o tofu apply (~30 segundos após iniciar):
└── NLB + IP criados → cadastrar os registros A na zona DNS
        └── propagação TTL=300 (~5 minutos)

Ao final do apply (~20-30 min):
└── Cluster pronto + DNS propagado + certificados TLS emitidos ✅
```

Para cada subdomínio, adicione uma entrada do tipo `A`:

```
Registro.br — Zona DNS de seudominio.com.br
┌──────────────────────────────────────────┬──────┬───────────────────┬─────┐
│ Nome                                     │ Tipo │ Valor             │ TTL │
├──────────────────────────────────────────┼──────┼───────────────────┼─────┤
│ k8s                                      │  A   │ <IP_DO_NLB>       │ 300 │
│ chirpstack-v3                            │  A   │ <IP_DO_NLB>       │ 300 │
│ chirpstack-v4                            │  A   │ <IP_DO_NLB>       │ 300 │
│ chirpstack-v4-rest-api                   │  A   │ <IP_DO_NLB>       │ 300 │
└──────────────────────────────────────────┴──────┴───────────────────┴─────┘
```

> No Registro.br, o campo "Nome" aceita apenas o prefixo do subdomínio — sem o domínio raiz. Ou seja, para criar `chirpstack-v3.seudominio.com.br`, preencha o campo Nome com `chirpstack-v3` apenas.

**Passo a passo no painel do Registro.br:**

1. Acesse [registro.br](https://registro.br) e faça login
2. Clique em **Domínios** e selecione o seu domínio
3. Acesse **DNS → Configurar zona DNS**
4. Ative o **Modo Avançado** (se ainda não estiver ativo) — aguarde até 2 horas para o processamento
5. Com o modo avançado ativo, clique em **Adicionar entrada** para cada subdomínio
6. Selecione o tipo `A`, preencha o **Nome** (ex: `chirpstack-v3`) e o **Valor** com o IP do NLB
7. Clique em **Salvar**
8. Aguarde a propagação (TTL de 300 segundos = 5 minutos para a maioria dos resolvedores)

---

### Verificar a propagação do DNS

Antes de fazer o deploy do ChirpStack, confirme que todos os registros propagaram:

```bash
# Verificar cada subdomínio — todos devem retornar o IP do NLB
dig +short k8s.seudominio.com.br
dig +short chirpstack-v3.seudominio.com.br
dig +short chirpstack-v4.seudominio.com.br
dig +short chirpstack-v4-rest-api.seudominio.com.br

# Verificar de um servidor DNS público (confirma propagação global)
dig +short k8s.seudominio.com.br @8.8.8.8         # Google DNS
dig +short chirpstack-v3.seudominio.com.br @1.1.1.1  # Cloudflare DNS

# Verificar propagação completa via ferramenta online:
# https://dnschecker.org
```

**Resultado esperado:** todos os subdomínios devem retornar o mesmo IP do Load Balancer OCI.

---

### Outros provedores de DNS

A lógica é a mesma independente do provedor. A única diferença é a interface:

| Provedor | Onde acessar |
|---|---|
| **Registro.br** | registro.br → Domínios → Editar zona DNS |
| **Cloudflare** | dash.cloudflare.com → DNS → Records → Add record |
| **GoDaddy** | godaddy.com → Meus Domínios → DNS → Adicionar registro |
| **AWS Route 53** | console.aws.amazon.com → Route 53 → Hosted zones → Create record |
| **Google Domains** | domains.google → DNS → Gerenciar registros personalizados |

> Se estiver usando o **OCI DNS** (Oracle Cloud Infrastructure DNS), os registros podem ser criados diretamente no console em **Networking → DNS Management → Zones → (sua zona) → Add Record**.

---

### Atualizar os subdomínios nos manifestos antes do deploy

Os arquivos Ingress do projeto precisam ser editados com seus subdomínios reais **antes** de aplicar os manifests. Localize e substitua em cada arquivo:

**Homepage:**
```bash
# Arquivo: 00.homepage/kubernetes/06.homepage-nginx__Ingress.yaml
# Substituir: k8s.adailsilva.com.br → k8s.seudominio.com.br
sed -i 's/k8s.adailsilva.com.br/k8s.seudominio.com.br/g' \
  00.homepage/kubernetes/06.homepage-nginx__Ingress.yaml
```

**ChirpStack v3:**
```bash
# Arquivo: 03.chirpstack_v3/kubernetes/31.chirpstack-v3-application-server__Ingress.yaml
sed -i 's/chirpstack-v3.adailsilva.com.br/chirpstack-v3.seudominio.com.br/g' \
  03.chirpstack_v3/kubernetes/31.chirpstack-v3-application-server__Ingress.yaml
```

**ChirpStack v4:**
```bash
# Arquivo: 04.chirpstack_v4/kubernetes/21.chirpstack-v4__Ingress.yaml
sed -i 's/chirpstack-v4.adailsilva.com.br/chirpstack-v4.seudominio.com.br/g' \
  04.chirpstack_v4/kubernetes/21.chirpstack-v4__Ingress.yaml

# Arquivo: 04.chirpstack_v4/kubernetes/26.chirpstack-v4-rest-api__Ingress.yaml
sed -i 's/chirpstack-v4-rest-api.adailsilva.com.br/chirpstack-v4-rest-api.seudominio.com.br/g' \
  04.chirpstack_v4/kubernetes/26.chirpstack-v4-rest-api__Ingress.yaml
```

**Variável do Terraform (cluster principal):**
```hcl
# variables.auto.tfvars
cluster_public_dns_name = "k8s.seudominio.com.br"
```

**ConfigMap do ChirpStack v4 (servidor-openssl.cnf — SAN público do MQTT):**
```bash
# Passo 3 do MQTT TLS — substituir o domínio público no server-openssl.cnf
sed -i 's/chirpstack-v4.adailsilva.com.br/chirpstack-v4.seudominio.com.br/g' \
  ~/chirpstack/mqtt-certs/server-openssl.cnf
```

---

## Configuração Inicial

### 1. Clone o repositório

```bash
git clone https://github.com/AdailSilva/Kubernetes_at_Oracle_Cloud_Always_Free.git
cd Kubernetes_at_Oracle_Cloud_Always_Free
```

### 2. Configure as variáveis

```bash
cp variables.auto.tfvars.example variables.auto.tfvars
```

Edite `variables.auto.tfvars`:

```hcl
# ─── OCI API ───────────────────────────────────────────────────────────────
tenancy_ocid     = "ocid1.tenancy.oc1..xxxxxxxxxx"
user_ocid        = "ocid1.user.oc1..xxxxxxxxxx"
fingerprint      = "xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
private_key_path = "/home/seu_usuario/.oci/oci_api_key.pem"
# Windows: private_key_path = "C:\\Users\\...\\.oci\\oci-tf.pem"
# private_key_password = ""   # descomente se a chave tiver senha
region           = "sa-saopaulo-1"

# ─── SSH ───────────────────────────────────────────────────────────────────
# Gerado com: ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519
ssh_key_path     = "/home/seu_usuario/.ssh/id_ed25519"
ssh_key_pub_path = "/home/seu_usuario/.ssh/id_ed25519.pub"
# Windows:
# ssh_key_path     = "C:\\Users\\...\\.ssh\\id_ed25519"
# ssh_key_pub_path = "C:\\Users\\...\\.ssh\\id_ed25519.pub"

# ─── Cluster ───────────────────────────────────────────────────────────────
# Necessário para TLS com Let's Encrypt. Mudanças causam recriação do cluster.
cluster_public_dns_name = "k8s.seudominio.com.br"

# E-mail para registro no Let's Encrypt
letsencrypt_registration_email = "seu_email@seudominio.com"

# ─── Debug / Configurações locais ──────────────────────────────────────────
# Cria admin-user no Dashboard e exibe o token no output do Terraform
debug_create_cluster_admin = true

# Sobrescreve ~/.kube/config local com o kubeconfig do cluster
linux_overwrite_local_kube_config = true
# Windows: windows_overwrite_local_kube_config = true
```

### Referência completa de variáveis

| Variável | Tipo | Obrigatória | Default | Descrição |
|---|---|---|---|---|
| `tenancy_ocid` | string | ✅ | — | OCID da tenancy OCI |
| `user_ocid` | string | ✅ | — | OCID do usuário OCI |
| `fingerprint` | string | ✅ | — | Fingerprint da API Key |
| `private_key_path` | string | ✅ | — | Caminho da chave privada OCI |
| `private_key_password` | string | — | `""` | Senha da chave privada OCI |
| `region` | string | ✅ | — | Região OCI (ex: `sa-saopaulo-1`) |
| `ssh_key_path` | string | ✅ | — | Chave privada SSH para as VMs |
| `ssh_key_pub_path` | string | ✅ | — | Chave pública SSH para as VMs |
| `cluster_public_dns_name` | string | — | `null` | DNS público do cluster |
| `letsencrypt_registration_email` | string | ✅ | — | E-mail para certificados TLS |
| `debug_create_cluster_admin` | bool | — | `false` | Cria admin-user e exibe token |
| `linux_overwrite_local_kube_config` | bool | — | `false` | Sobrescreve `~/.kube/config` |

---

## Implantação da Infraestrutura

> Todos os comandos abaixo funcionam tanto com **Terraform** quanto com **OpenTofu**. Escolha a ferramenta de sua preferência — a sintaxe e o comportamento são equivalentes. OpenTofu é o fork open-source mantido pela comunidade; Terraform é mantido pela HashiCorp sob licença BSL.

---

### Terraform

#### 1. Instalar o Terraform

```bash
# Linux (Ubuntu/Debian)
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# macOS (Homebrew)
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Verificar instalação
terraform version
```

#### 2. Inicializar o projeto

Baixa os providers declarados (`oci >= 6.35.0`, `null 3.1.0`) e prepara o diretório de trabalho:

```bash
terraform init
```

#### 3. Formatar o código (opcional)

Aplica formatação padrão em todos os arquivos `.tf`:

```bash
terraform fmt -recursive
```

#### 4. Validar a configuração

Verifica erros de sintaxe e configuração sem acessar a API da OCI:

```bash
terraform validate
```

#### 5. Visualizar o plano de execução

Exibe todos os recursos que serão criados, modificados ou destruídos:

```bash
terraform plan
```

Para salvar o plano em arquivo (útil para revisão antes de aplicar em produção):

```bash
terraform plan -out=tfplan
```

#### 6. Aplicar a infraestrutura

```bash
terraform apply
```

Aplicar sem confirmação interativa (use com cuidado):

```bash
terraform apply -auto-approve
```

Aplicar a partir de um plano salvo anteriormente:

```bash
terraform apply tfplan
```

Aplicar com paralelismo limitado a **1 operação por vez**:

```bash
terraform apply -parallelism=1
```

> Por padrão, o Terraform (e o OpenTofu) executam até **10 operações em paralelo**. O flag `-parallelism=1` força a criação dos recursos de forma **estritamente sequencial**, um por vez. Isso é especialmente útil neste projeto porque a API do Network Load Balancer da OCI é suscetível a race conditions ao criar múltiplos listeners, backend sets e backends simultaneamente — o que pode causar erros intermitentes do tipo `409-Conflict` ou `412-PreconditionFailed`. Usar `-parallelism=1` resolve esses conflitos ao garantir que cada recurso do NLB seja criado e confirmado antes do próximo iniciar. A desvantagem é que o tempo total de provisionamento aumenta; use esta opção apenas quando o `apply` padrão falhar com erros de concorrência na OCI.

> 💡 **Momento ideal para cadastrar os subdomínios no DNS:** o módulo `network` é o segundo a ser executado e provisiona o IP Público Reservado e o Load Balancer em poucos segundos após o início do `apply`. Você **não precisa aguardar os 15–30 minutos** do provisionamento completo — assim que a criação do NLB aparecer nos logs do Terraform/OpenTofu, o IP já estará disponível no console OCI e pode ser copiado para cadastrar os registros DNS. Dessa forma, quando o cluster terminar de subir, os subdomínios já estarão propagados e o cert-manager conseguirá emitir os certificados TLS imediatamente. Veja a seção [Como obter o IP durante o apply](#como-obter-o-ip-durante-o-apply) logo abaixo.

#### Como obter o IP durante o apply

Enquanto o `terraform apply` ou `tofu apply` ainda está em execução, abra um **segundo terminal** e use qualquer uma das opções abaixo para obter o IP imediatamente após os recursos de rede serem criados:

**Opção 1 — Console OCI (mais rápido, sem dependências):**
1. Acesse **OCI Console → Networking → Load Balancers → Network Load Balancers**
2. O NLB `k8s-arm-oci-always-free` (ou o nome configurado) aparecerá com status `Creating` em segundos
3. Clique nele — o **IP Address** já estará preenchido mesmo com o NLB ainda provisionando
4. Copie o IP e vá direto ao painel do seu provedor DNS para criar os registros

**Opção 2 — OCI CLI (no segundo terminal):**
```bash
# Listar os IPs públicos reservados da sua tenancy
oci network public-ip list \
  --compartment-id <COMPARTMENT_OCID> \
  --scope REGION \
  --query 'data[?"lifecycle-state"==`AVAILABLE`].{"IP": "ip-address", "Nome": "display-name"}' \
  --output table

# Ou buscar diretamente o IP do NLB pelo nome
oci nlb network-load-balancer list \
  --compartment-id <COMPARTMENT_OCID> \
  --query 'data.items[0]."ip-addresses"[0]."ip-address"' \
  --raw-output
```

**Opção 3 — Terraform/OpenTofu state (após o módulo network concluir):**
```bash
# Enquanto o apply ainda corre, em outro terminal, dentro do diretório do projeto:
terraform output cluster_public_ip 2>/dev/null || \
  terraform state show module.network.oci_core_public_ip.cluster_public_ip \
  | grep "ip_address"

# OpenTofu:
tofu output cluster_public_ip 2>/dev/null || \
  tofu state show module.network.oci_core_public_ip.cluster_public_ip \
  | grep "ip_address"
```

**Fluxo recomendado:**

```
tofu apply -parallelism=1  (Terminal 1 — deixa rodando)
     │
     ├── ~30s → módulo network concluído → NLB + IP criados
     │               └── Terminal 2: copie o IP do console OCI
     │                       └── Cadastre os registros DNS no Registro.br
     │                               (propagação leva ~5 minutos com TTL=300)
     │
     ├── ~5min → módulo compute concluído → VMs provisionadas
     ├── ~10min → módulo k8s concluído → cluster Kubernetes operacional
     ├── ~15min → módulo k8s_scaffold → cert-manager tenta emitir certificados
     │               └── ✅ DNS já propagado → certificados emitidos com sucesso
     └── ~20-30min → apply concluído
```

> Cadastrar os registros DNS **durante o apply** — e não depois — é a forma mais eficiente de garantir que os certificados TLS estejam prontos assim que o cluster terminar de subir, sem precisar aguardar propagação adicional.

#### 7. Consultar os outputs após a implantação

```bash
# Todos os outputs de uma vez
terraform output

# Outputs específicos
terraform output cluster_public_ip       # IP público do Load Balancer
terraform output cluster_public_address  # DNS do cluster
terraform output admin_token             # Token do Dashboard (se debug_create_cluster_admin = true)
```

Para extrair um valor em texto puro (útil em scripts):

```bash
terraform output -raw cluster_public_ip
terraform output -raw admin_token
```

#### 8. Consultar o estado atual

Listar todos os recursos gerenciados:

```bash
terraform state list
```

Inspecionar um recurso específico:

```bash
terraform state show <resource_address>
# Exemplo:
terraform state show module.compute.oci_core_instance.leader
```

#### 9. Destruir a infraestrutura

```bash
terraform destroy
```

Destruir sem confirmação interativa:

```bash
terraform destroy -auto-approve
```

---

### OpenTofu

#### 1. Instalar o OpenTofu

```bash
# Linux (Ubuntu/Debian) — via repositório oficial
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh | bash -s -- --install-method deb

# macOS (Homebrew)
brew install opentofu

# Windows (Winget)
winget install OpenTofu.OpenTofu

# Verificar instalação
tofu version
```

#### 2. Inicializar o projeto

Baixa os providers declarados e prepara o diretório de trabalho:

```bash
tofu init
```

Forçar o re-download dos providers (útil após atualização de versão):

```bash
tofu init -upgrade
```

#### 3. Formatar o código (opcional)

```bash
tofu fmt -recursive
```

#### 4. Validar a configuração

```bash
tofu validate
```

#### 5. Visualizar o plano de execução

```bash
tofu plan
```

Salvar o plano em arquivo:

```bash
tofu plan -out=tfplan
```

#### 6. Aplicar a infraestrutura

```bash
tofu apply
```

Aplicar sem confirmação interativa:

```bash
tofu apply -auto-approve
```

Aplicar a partir de um plano salvo:

```bash
tofu apply tfplan
```

Aplicar com paralelismo limitado a **1 operação por vez**:

```bash
tofu apply -parallelism=1
```

> Por padrão, o OpenTofu (e o Terraform) executam até **10 operações em paralelo**. O flag `-parallelism=1` força a criação dos recursos de forma **estritamente sequencial**, um por vez. Isso é especialmente útil neste projeto porque a API do Network Load Balancer da OCI é suscetível a race conditions ao criar múltiplos listeners, backend sets e backends simultaneamente — o que pode causar erros intermitentes do tipo `409-Conflict` ou `412-PreconditionFailed`. Usar `-parallelism=1` resolve esses conflitos ao garantir que cada recurso do NLB seja criado e confirmado antes do próximo iniciar. A desvantagem é que o tempo total de provisionamento aumenta; use esta opção apenas quando o `apply` padrão falhar com erros de concorrência na OCI.

> 💡 **Momento ideal para cadastrar os subdomínios no DNS:** o módulo `network` conclui em poucos segundos após o início do `apply` e o IP do Load Balancer já está disponível no console OCI antes do cluster terminar de subir. Cadastre os registros DNS nesse intervalo para que a propagação ocorra em paralelo ao provisionamento. Veja o fluxo detalhado na seção [Como obter o IP durante o apply](#como-obter-o-ip-durante-o-apply) acima (seção Terraform — o procedimento é idêntico para OpenTofu).

#### 7. Consultar os outputs após a implantação

```bash
# Todos os outputs de uma vez
tofu output

# Outputs específicos
tofu output cluster_public_ip
tofu output cluster_public_address
tofu output admin_token
```

Extrair valor em texto puro:

```bash
tofu output -raw cluster_public_ip
tofu output -raw admin_token
```

#### 8. Consultar o estado atual

```bash
tofu state list
tofu state show <resource_address>
```

#### 9. Destruir a infraestrutura

```bash
tofu destroy
```

Destruir sem confirmação interativa:

```bash
tofu destroy -auto-approve
```

---

### Comandos adicionais úteis (ambas as ferramentas)

Estes comandos têm sintaxe idêntica no Terraform e no OpenTofu, bastando trocar `terraform` por `tofu`:

```bash
# Limitar o paralelismo a 1 operação por vez (evita race conditions no NLB da OCI)
terraform apply -parallelism=1
tofu apply -parallelism=1

# Combinar com -target para recriar um módulo de forma segura e sequencial
terraform apply -parallelism=1 -target=module.k8s_scaffold
tofu apply -parallelism=1 -target=module.k8s_scaffold

# Recarregar apenas um módulo específico (útil para recriar recursos isolados)
terraform apply -target=module.k8s
tofu apply -target=module.k8s

# Recarregar apenas um recurso específico
terraform apply -target=module.compute.oci_core_instance.leader
tofu apply -target=module.compute.oci_core_instance.leader

# Importar um recurso existente na OCI para o estado do Terraform/OpenTofu
terraform import <resource_address> <resource_ocid>
tofu import <resource_address> <resource_ocid>

# Remover um recurso do estado sem destruí-lo na OCI
terraform state rm <resource_address>
tofu state rm <resource_address>

# Verificar diferenças entre o estado e a infraestrutura real
terraform refresh
tofu refresh

# Exibir o grafo de dependências entre módulos (requer graphviz)
terraform graph | dot -Tsvg > grafo.svg
tofu graph | dot -Tsvg > grafo.svg
```

---

### Sequência de execução dos módulos

Independente da ferramenta, a ordem de provisionamento é sempre:

```
compartment → network → compute → k8s → k8s_scaffold → oci-infra_ci_cd
```

Cada módulo depende do anterior via `depends_on`. O Terraform e o OpenTofu gerenciam essa ordem automaticamente.

> ⏱️ O processo completo leva entre **15 e 30 minutos**:
> - Recursos OCI (compartimento, rede, VMs): ~5 min
> - Bootstrap do Control Plane (kubeadm init): ~5 min
> - Join dos 3 Workers (paralelo): ~10 min
> - Instalação das aplicações scaffold: ~5 min

---

## Implantando as Aplicações Padrão

Após a infraestrutura estar operacional, execute as aplicações na seguinte ordem recomendada:

### 1. Metrics Server

```bash
cd 01.metrics_server/00.UsefulScripts/
bash 01.deploy_metrics_server_script.sh

# Verificar:
kubectl top nodes
kubectl get pods -n kube-system | grep metrics
```

### 2. UDP Health Check

> Necessário antes de adicionar listeners UDP no NLB para que o health check passe.

```bash
# Criar o Secret de acesso ao OCI Registry
kubectl create secret docker-registry oci-registry-secret \
  --docker-server=gru.ocir.io \
  --docker-username='<namespace>/<seu_email>' \
  --docker-password='<auth_token>' \
  --docker-email='<seu_email>' \
  -n oci-devops

cd 02.udp_health_check-nlb_oci/00.UsefulScripts/
bash 01.deploy_udp_health_check_server_nlb_oci_script.sh

# Verificar:
kubectl get pods -n oci-devops
kubectl get daemonset -n oci-devops
```

### 3. Homepage

```bash
# Garantir que o Secret de Registry exista no namespace oci-devops
kubectl get secret oci-registry-secret -n oci-devops

cd 00.homepage/00.UsefulScripts/
bash 01.deploy_homepage-nginx_script.sh

# Verificar:
kubectl get pods,svc,ingress -n oci-devops
kubectl get certificate -n oci-devops
```

---

## Pré-requisito: OCI File Storage Service (FSS)

### Por que o FSS é necessário

O ChirpStack v3 e v4 utilizam **volumes persistentes** para armazenar dados dos bancos PostgreSQL, do Redis e dos dispositivos cadastrados. No cluster ARM da OCI, esses volumes são provisionados via **OCI File Storage Service (FSS)** — um sistema de arquivos NFS gerenciado pela Oracle, disponível dentro da própria VCN.

Sem os diretórios do FSS criados e com as permissões corretas **antes** do deploy do ChirpStack, os Pods que utilizam `PersistentVolumeClaim` falharão na inicialização com erros de permissão (`permission denied`) ou ficarão presos em `Pending` por não conseguir montar o volume.

```
OCI File Storage Service
  └── Mount Target (IP interno da VCN, ex: 10.0.0.143)
        └── Export: /FileSystem-K8S
              ├── chirpstack-v3-ns/          → PostgreSQL NS (v3) — 10Gi
              ├── chirpstack-v3-as/          → PostgreSQL AS (v3) — 10Gi
              ├── chirpstack-v3-redis-data/  → Redis (v3)         —  1Gi
              ├── docker-entrypoint-initdb.d/→ Scripts SQL init   — 100Mi
              ├── chirpstack-v4-ns-as/       → PostgreSQL (v4)    — 10Gi
              ├── chirpstack-v4-redis-data/  → Redis (v4)         —  1Gi
              └── chirpstack-v4-devices/     → Dispositivos (v4)  — 500Mi
```

### Criando o FSS no console OCI

Antes de executar o script abaixo, o FSS precisa existir na OCI:

1. Acesse **Storage → File Storage → File Systems → Create File System**
2. Crie um **Mount Target** dentro da subnet pública do cluster (mesma subnet das VMs)
3. Anote o **IP do Mount Target** (ex: `10.0.0.143`) — ele será usado no script
4. Crie um **Export** apontando para o caminho `/FileSystem-K8S`
5. Nas **Security Lists** da subnet, libere a porta `2049` (NFS) nas regras de ingress e egress para o CIDR `10.0.0.0/24`

### Script de montagem e preparação dos diretórios

O script abaixo deve ser executado **em cada um dos 4 nós do cluster** (leader e workers) antes do deploy do ChirpStack. Ele:

1. Instala o cliente NFS (`nfs-common`) no Ubuntu
2. Cria o ponto de montagem local `/mnt/oci-fss`
3. Monta o export NFS com as opções recomendadas pela Oracle para FSS
4. Verifica se a montagem foi bem-sucedida
5. Cria cada subdiretório de volume com o `UID:GID` correto para o processo que vai usá-lo

> Os `UID:GID` são importantes: o PostgreSQL roda como usuário `999:999` (usuário `postgres` dentro do container), e um diretório com dono errado causará falha na inicialização do banco.

```bash
#!/bin/bash
# mount-oci-fss-chirpstack.sh
# Monta o OCI File Storage Service e prepara os diretórios de volumes
# necessários para o ChirpStack v3 e v4 no cluster Kubernetes ARM.
#
# Execute este script em CADA NÓ do cluster (leader e workers):
#   ssh ubuntu@<IP_DO_NO> 'bash -s' < mount-oci-fss-chirpstack.sh
#
# Pré-requisito: FSS criado na OCI com Mount Target acessível via VCN.

set -euo pipefail

echo ">>> Iniciando montagem do OCI FSS para ChirpStack..."

# ─── Configuração ─────────────────────────────────────────────────────────────
MOUNT_IP="10.0.0.143"          # IP do Mount Target OCI (ajuste conforme seu ambiente)
EXPORT_PATH="/FileSystem-K8S"  # Export configurado no OCI FSS
LOCAL_MOUNT="/mnt/oci-fss"     # Ponto de montagem local nos nós
# ──────────────────────────────────────────────────────────────────────────────

# 1. Instala nfs-common se não estiver presente
echo ">>> [1/5] Instalando nfs-common..."
sudo apt update -y && sudo apt install -y nfs-common

# 2. Cria o ponto de montagem local
echo ">>> [2/5] Criando ponto de montagem ${LOCAL_MOUNT}..."
sudo mkdir -p "${LOCAL_MOUNT}"

# 3. Monta o NFS com opções otimizadas para OCI FSS
# Referência: https://docs.oracle.com/en-us/iaas/Content/File/Tasks/mountingfilesystems.htm
echo ">>> [3/5] Montando ${MOUNT_IP}:${EXPORT_PATH} em ${LOCAL_MOUNT}..."
sudo mount -t nfs \
  -o rw,bg,hard,nointr,rsize=1048576,wsize=1048576,proto=tcp,timeo=600,retrans=2 \
  "${MOUNT_IP}:${EXPORT_PATH}" "${LOCAL_MOUNT}"

# 4. Verifica se a montagem foi bem-sucedida
echo ">>> [4/5] Verificando montagem..."
if ! mountpoint -q "${LOCAL_MOUNT}"; then
  echo "❌ ERRO: Falha ao montar ${MOUNT_IP}:${EXPORT_PATH} em ${LOCAL_MOUNT}"
  echo "   Verifique: IP do Mount Target, Export Path, regras de Security List (porta 2049)."
  exit 1
fi
echo "✅ FSS montado com sucesso em ${LOCAL_MOUNT}"

# 5. Cria os diretórios de volumes com dono e permissões corretos
# UID:GID 999:999 → usuário 'postgres' dentro dos containers PostgreSQL e Redis
echo ">>> [5/5] Criando diretórios de volumes do ChirpStack..."

# ── ChirpStack v3 ──────────────────────────────────────────────────────────────

# Scripts de inicialização do PostgreSQL NS e AS (init-db)
# Estes scripts SQL são copiados para cá e executados na primeira inicialização
sudo mkdir -p "${LOCAL_MOUNT}/docker-entrypoint-initdb.d"
sudo chown -R 999:999 "${LOCAL_MOUNT}/docker-entrypoint-initdb.d"
sudo chmod 700 "${LOCAL_MOUNT}/docker-entrypoint-initdb.d"
echo "    ✔ docker-entrypoint-initdb.d (scripts SQL de init)"

# Dados do PostgreSQL do Network Server (chirpstack_ns)
sudo mkdir -p "${LOCAL_MOUNT}/chirpstack-v3-ns"
sudo chown -R 999:999 "${LOCAL_MOUNT}/chirpstack-v3-ns"
sudo chmod 700 "${LOCAL_MOUNT}/chirpstack-v3-ns"
echo "    ✔ chirpstack-v3-ns (PostgreSQL Network Server — 10Gi)"

# Dados do PostgreSQL do Application Server (chirpstack_as)
sudo mkdir -p "${LOCAL_MOUNT}/chirpstack-v3-as"
sudo chown -R 999:999 "${LOCAL_MOUNT}/chirpstack-v3-as"
sudo chmod 700 "${LOCAL_MOUNT}/chirpstack-v3-as"
echo "    ✔ chirpstack-v3-as (PostgreSQL Application Server — 10Gi)"

# Dados do Redis v3
sudo mkdir -p "${LOCAL_MOUNT}/chirpstack-v3-redis-data"
sudo chown -R 999:999 "${LOCAL_MOUNT}/chirpstack-v3-redis-data"
sudo chmod 700 "${LOCAL_MOUNT}/chirpstack-v3-redis-data"
echo "    ✔ chirpstack-v3-redis-data (Redis — 1Gi)"

# ── ChirpStack v4 ──────────────────────────────────────────────────────────────

# Dados do PostgreSQL unificado (chirpstack — NS + AS em um único banco)
sudo mkdir -p "${LOCAL_MOUNT}/chirpstack-v4-ns-as"
sudo chown -R 999:999 "${LOCAL_MOUNT}/chirpstack-v4-ns-as"
sudo chmod 700 "${LOCAL_MOUNT}/chirpstack-v4-ns-as"
echo "    ✔ chirpstack-v4-ns-as (PostgreSQL unificado — 10Gi)"

# Dados do Redis v4
sudo mkdir -p "${LOCAL_MOUNT}/chirpstack-v4-redis-data"
sudo chown -R 999:999 "${LOCAL_MOUNT}/chirpstack-v4-redis-data"
sudo chmod 700 "${LOCAL_MOUNT}/chirpstack-v4-redis-data"
echo "    ✔ chirpstack-v4-redis-data (Redis — 1Gi)"

# Dados de dispositivos cadastrados no ChirpStack v4
# (arquivos de configuração de região e estado dos devices)
sudo mkdir -p "${LOCAL_MOUNT}/chirpstack-v4-devices"
sudo chown -R 999:999 "${LOCAL_MOUNT}/chirpstack-v4-devices"
sudo chmod 700 "${LOCAL_MOUNT}/chirpstack-v4-devices"
echo "    ✔ chirpstack-v4-devices (Dispositivos — 500Mi)"

# ── Sumário final ──────────────────────────────────────────────────────────────
echo ""
echo "::: Diretórios criados no FSS :::"
ls -lhta "${LOCAL_MOUNT}/"
echo ""
echo ">>> Montagem e preparação concluídas com sucesso."
echo ">>> Repita este script nos demais nós do cluster antes de fazer o deploy."
```

### Como executar em todos os nós

Salve o script como `mount-oci-fss-chirpstack.sh` e execute remotamente em cada nó via SSH:

```bash
# Tornar executável localmente
chmod +x mount-oci-fss-chirpstack.sh

# Executar no leader
ssh -i ~/.ssh/id_ed25519 ubuntu@<IP_PUBLICO> 'bash -s' < mount-oci-fss-chirpstack.sh

# Executar nos workers (via jump através do leader)
for WORKER_IP in <IP_WORKER_0> <IP_WORKER_1> <IP_WORKER_2>; do
  echo ">>> Configurando ${WORKER_IP}..."
  ssh -i ~/.ssh/id_ed25519 \
      -J ubuntu@<IP_PUBLICO> \
      ubuntu@${WORKER_IP} 'bash -s' < mount-oci-fss-chirpstack.sh
done
```

### Tornar a montagem permanente (fstab)

Para que o FSS seja remontado automaticamente após reinicializações dos nós, adicione a entrada no `/etc/fstab` de cada nó:

```bash
# Adicionar ao /etc/fstab (execute em cada nó)
echo "10.0.0.143:/FileSystem-K8S /mnt/oci-fss nfs rw,bg,hard,nointr,rsize=1048576,wsize=1048576,proto=tcp,timeo=600,retrans=2,_netdev 0 0" \
  | sudo tee -a /etc/fstab

# Testar sem reiniciar
sudo mount -a
mountpoint -q /mnt/oci-fss && echo "✅ OK" || echo "❌ Falhou"
```

> A opção `_netdev` é essencial: indica ao sistema operacional que este dispositivo depende de rede, garantindo que ele só seja montado após as interfaces de rede estarem ativas durante o boot.

### Verificar montagem em todos os nós

```bash
# Verificar se o FSS está montado em cada nó
kubectl get nodes -o wide | awk 'NR>1 {print $6}' | while read IP; do
  echo -n "Node ${IP}: "
  ssh -i ~/.ssh/id_ed25519 \
      -J ubuntu@<IP_PUBLICO> \
      ubuntu@${IP} 'mountpoint -q /mnt/oci-fss && echo "✅ Montado" || echo "❌ NÃO montado"'
done
```

---

## Serviços LoRaWAN — ChirpStack

Este repositório documenta a implantação do **ChirpStack** — a plataforma de servidor de rede LoRaWAN open-source mais utilizada no mundo — em suas versões **v3** e **v4** sobre o cluster Kubernetes ARM da OCI. Ambas as versões podem coexistir no mesmo cluster, pois operam em namespaces e portas completamente distintos.

### O que é o ChirpStack?

O [ChirpStack](https://www.chirpstack.io/) é uma plataforma open-source de servidor de rede LoRaWAN que gerencia:

- **Gateways LoRaWAN** — recebem mensagens de rádio dos dispositivos e as encaminham ao servidor
- **Dispositivos IoT (end-devices)** — sensores, rastreadores e qualquer dispositivo LoRaWAN
- **Uplink / Downlink** — roteamento dos dados entre dispositivos e aplicações externas
- **OTAA / ABP** — gerenciamento de ativação de dispositivos
- **ADR** — controle adaptativo de taxa de dados

A v3 e a v4 diferem significativamente em arquitetura: a v3 usa componentes separados (Network Server + Application Server), enquanto a v4 unifica tudo em um único binário.

---

## 03. ChirpStack v3

### Visão Geral da Arquitetura (v3)

O ChirpStack v3 é composto por **cinco serviços principais** que se comunicam entre si via MQTT e gRPC, além de dois bancos de dados e um cache:

```
Gateway físico (LoRa)
    │
    │ UDP :1700 (Semtech Packet Forwarder)
    ▼
┌─────────────────────────────────────────────────────────────────┐
│  Namespace: chirpstack-v3                                       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Gateway Bridge (chirpstack/chirpstack-gateway-bridge:  │   │
│  │  3.14.8)                                                │   │
│  │  Escuta UDP :1700 ← Packet Forwarder do gateway         │   │
│  │  Publica no MQTT → gateway/{id}/event/{type}            │   │
│  └────────────────────────┬────────────────────────────────┘   │
│                           │ MQTT (TCP :1883)                    │
│  ┌────────────────────────▼────────────────────────────────┐   │
│  │  Mosquitto (eclipse-mosquitto:2.0.22)                   │   │
│  │  Broker MQTT — allow_anonymous true                     │   │
│  │  Service: chirpstack-v3-mosquitto-service :1888→1883    │   │
│  └────────┬───────────────────────────────────┬────────────┘   │
│           │ MQTT                              │ MQTT            │
│  ┌────────▼─────────┐             ┌───────────▼──────────────┐ │
│  │  Network Server  │             │  Application Server       │ │
│  │  v3.16.8         │◄── gRPC ───►│  v3.17.9                 │ │
│  │  API: :8000      │  :8001      │  API interna:  :8001     │ │
│  │  Join: →AS :8003 │             │  Join server:  :8003     │ │
│  │  Banda: AU915    │             │  UI + REST:    :8080→443 │ │
│  │  NetID: FFFFFF   │             │  Monitoring:   :8101     │ │
│  └────────┬─────────┘             └──────────────────────────┘ │
│           │                                │                    │
│  ┌────────▼─────────┐             ┌────────▼──────────────┐    │
│  │  PostgreSQL NS   │             │  PostgreSQL AS        │    │
│  │  postgres:14-    │             │  postgres:14-alpine   │    │
│  │  alpine          │             │  DB: chirpstack_as    │    │
│  │  DB: chirpstack_ │             │  Extensions:          │    │
│  │  ns              │             │  pg_trgm + hstore     │    │
│  │  Port: :5437     │             │  Port: :5438          │    │
│  │  PV: 10Gi OCI FSS│             │  PV: 10Gi OCI FSS     │    │
│  └──────────────────┘             └───────────────────────┘    │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Redis (redis:7.2) — Cache de sessões de dispositivos    │  │
│  │  Port: :6384→6379  |  PV: 1Gi OCI FSS                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Toolbox (nicolaka/netshoot) — Pod de debug de rede      │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Ingress (NGINX + TLS Let's Encrypt):                          │
│  https://chirpstack-v3.seudominio.com.br → AS Service :443     │
└─────────────────────────────────────────────────────────────────┘
```

### Kubernetes Resources (namespace `chirpstack-v3`)

| Kind | Nome | Imagem | Porta(s) |
|---|---|---|---|
| `Namespace` | `chirpstack-v3` | — | — |
| `ConfigMap` | `chirpstack-v3-mosquitto-config-map` | — | Configuração do broker |
| `Deployment` | `chirpstack-v3-mosquitto-deployment` | `eclipse-mosquitto:2.0.22` | TCP 1883 |
| `Service` | `chirpstack-v3-mosquitto-service` | — | TCP 1888→1883 |
| `StorageClass` + `PV` + `PVC` | `oci-fss-postgresql-claim0-chirpstack-v3` | — | initdb scripts (100Mi) |
| `StorageClass` + `PV` + `PVC` | `oci-fss-postgresql-data-chirpstack-v3-ns` | — | Dados do NS PostgreSQL (10Gi) |
| `StorageClass` + `PV` + `PVC` | `oci-fss-postgresql-data-chirpstack-v3-as` | — | Dados do AS PostgreSQL (10Gi) |
| `ConfigMap` | `chirpstack-v3-postgresql-config-map` | — | Scripts de init do banco |
| `Deployment` | `chirpstack-v3-ns-postgresql-deployment` | `postgres:14-alpine` | TCP 5437→5432 |
| `Service` | `chirpstack-v3-ns-postgresql-service` | — | TCP 5437→5432 |
| `Deployment` | `chirpstack-v3-as-postgresql-deployment` | `postgres:14-alpine` | TCP 5438→5433 |
| `Service` | `chirpstack-v3-as-postgresql-service` | — | TCP 5438→5433 |
| `StorageClass` + `PV` + `PVC` | `oci-fss-redis-data-chirpstack-v3` | — | Dados do Redis (1Gi) |
| `Deployment` | `chirpstack-v3-redis-deployment` | `redis:7.2` | TCP 6384→6379 |
| `Service` | `chirpstack-v3-redis-service` | — | TCP 6384→6379 |
| `ConfigMap` | `chirpstack-v3-gateway-bridge-config-map` | — | Config TOML do Gateway Bridge |
| `Deployment` | `chirpstack-v3-gateway-bridge-deployment` | `chirpstack/chirpstack-gateway-bridge:3.14.8` | UDP 1700 |
| `Service` | `chirpstack-v3-gateway-bridge-service` | — | UDP 1700 |
| `ConfigMap` | `chirpstack-v3-network-server-config-map` | — | Config TOML do Network Server |
| `Deployment` | `chirpstack-v3-network-server-deployment` | `chirpstack/chirpstack-network-server:3.16.8` | TCP 8000 |
| `Service` | `chirpstack-v3-network-server-service` | — | TCP 8000 |
| `ConfigMap` | `chirpstack-v3-application-server-config-map` | — | Config TOML do Application Server |
| `Secret` | `chirpstack-v3-application-server-secrets` | — | JWT, DSNs, credenciais MQTT |
| `Deployment` | `chirpstack-v3-application-server-deployment` | `chirpstack/chirpstack-application-server:3.17.9` | TCP 8001, 8003, 8080→443, 8101 |
| `Service` | `chirpstack-v3-application-server-service` | — | TCP 8001, 8003, 443→8080, 8101 |
| `Ingress` | `chirpstack-v3-application-server-ingress` | — | HTTPS, TLS Let's Encrypt |
| `Deployment` | `toolbox` | `nicolaka/netshoot:latest` | — (debug) |

### Configurações importantes (v3)

#### Banco de dados

O v3 usa **dois bancos PostgreSQL separados** — um para o Network Server e outro para o Application Server — cada um com seu próprio Deployment, Service, StorageClass, PersistentVolume e PersistentVolumeClaim:

| Banco | Usuário | Senha | Porta ClusterIP | Extensões |
|---|---|---|---|---|
| `chirpstack_ns` | `chirpstack_ns` | `chirpstack_ns` | `:5437` | — |
| `chirpstack_as` | `chirpstack_as` | `chirpstack_as` | `:5438` | `pg_trgm`, `hstore` |

> Os scripts de inicialização dos bancos (`001.init-chirpstack-v3_ns.sh`, `002.init-chirpstack-v3_as.sh`, `003.chirpstack-v3_as_trgm.sh`, `004.chirpstack-v3_as_hstore.sh`) são injetados via ConfigMap e executados automaticamente na primeira inicialização do container PostgreSQL.

#### Região LoRaWAN configurada

```toml
[network_server.band]
name = "AU915"

[network_server.network_settings]
enabled_uplink_channels = [8, 9, 10, 11, 12, 13, 14, 15, 65]  # Sub-banda 2
```

> Para alterar a região (ex: para `US915`, `EU868`, `AS923`), edite o ConfigMap `chirpstack-v3-network-server-config-map` antes do deploy.

#### JWT Secret do Application Server

O campo `jwt_secret` no ConfigMap do Application Server é usado para autenticação de usuários e APIs. Para produção, gere um valor seguro:

```bash
openssl rand -base64 32
```

Substitua o valor padrão no arquivo `25.chirpstack-v3-application-server__ConfigMap.yaml` antes de aplicar.

#### Armazenamento persistente (OCI File Storage Service)

Todos os volumes persistentes usam a StorageClass `oci-fss-*` que aponta para o **OCI File Storage Service (FSS)**, montado no caminho `/FileSystem-K8S/` nos nós workers:

| Volume | Caminho no FSS | Tamanho |
|---|---|---|
| initdb scripts | `/FileSystem-K8S/docker-entrypoint-initdb.d` | 100Mi |
| Dados NS PostgreSQL | `/FileSystem-K8S/chirpstack-v3-ns` | 10Gi |
| Dados AS PostgreSQL | `/FileSystem-K8S/chirpstack-v3-as` | 10Gi |
| Dados Redis | `/FileSystem-K8S/chirpstack-v3-redis-data` | 1Gi |

> O OCI FSS precisa ser configurado previamente no console da OCI, montado em todos os nós do cluster e com os diretórios preparados antes do deploy. Consulte a seção [Pré-requisito: OCI File Storage Service (FSS)](#pré-requisito-oci-file-storage-service-fss) para o passo a passo completo incluindo o script de montagem.

### Estrutura de arquivos (v3)

```
03.chirpstack_v3/
├── 00.UsefulScripts/
│   ├── 00.pgpass__move_to_user_directory   # Arquivo .pgpass para acesso psql sem senha
│   ├── 01.deploy_chirpstack-v3_script.sh   # Deploy completo na ordem correta
│   ├── 02.destroy_chirpstack-v3_script.sh  # Remove todos os recursos
│   ├── 03.back-up_chirpstack-v3_script.sh  # Backup dos bancos PostgreSQL
│   └── 04.restore_chirpstack-v3_script.sh  # Restore dos backups
├── 00.useful_commands.txt                  # Comandos úteis do dia a dia
├── docker/docker-compose.yaml              # Versão Docker Compose para testes locais
└── kubernetes/
    ├── 01.create__Namespace.yaml
    ├── 02.chirpstack-v3-mosquitto__ConfigMap.yaml
    ├── 03.chirpstack-v3-mosquitto__Deployment.yaml
    ├── 04.chirpstack-v3-mosquitto__Service.yaml
    ├── 05.chirpstack-v3-ns-as-postgresql-claim0__...yaml   # PVC initdb (comentado no script)
    ├── 06.chirpstack-v3-ns-as-create-attach-pvc__Pod.yaml  # Pod auxiliar (comentado no script)
    ├── 07.chirpstack-v3-postgresql/                        # Scripts SQL de inicialização
    │   ├── 001.init-chirpstack-v3_ns.sh
    │   ├── 002.init-chirpstack-v3_as.sh
    │   ├── 003.chirpstack-v3_as_trgm.sh
    │   └── 004.chirpstack-v3_as_hstore.sh
    ├── 08.chirpstack-v3-ns-postgresql-data__...yaml
    ├── 09.chirpstack-v3-as-postgresql-data__...yaml
    ├── 10.chirpstack-v3-ns-as-postgresql__ConfigMap.yaml
    ├── 11.chirpstack-v3-ns-postgresql__Deployment.yaml
    ├── 12.chirpstack-v3-ns-postgresql__Service.yaml
    ├── 13.chirpstack-v3-as-postgresql__Deployment.yaml
    ├── 14.chirpstack-v3-as-postgresql__Service.yaml
    ├── 15.chirpstack-v3-redis-data__...yaml
    ├── 16.chirpstack-v3-redis__Deployment.yaml
    ├── 17.chirpstack-v3-redis__Service.yaml
    ├── 18.chirpstack-v3-gateway-bridge__ConfigMap.yaml
    ├── 19.chirpstack-v3-gateway-bridge__Deployment.yaml
    ├── 20.chirpstack-v3-gateway-bridge__Service.yaml
    ├── 21.chirpstack-v3-network-server__ConfigMap.yaml
    ├── 22.chirpstack-v3-network-server__Deployment.yaml
    ├── 23.chirpstack-v3-network-server__Service.yaml
    ├── 24.chirpstack-v3-application-server__Deployment.yaml   # (versão sem Secret, comentada)
    ├── 25.chirpstack-v3-application-server__ConfigMap.yaml
    ├── 26.chirpstack-v3-application-server__Secret.yaml
    ├── 27.chirpstack-v3-application-server__Deployment.yaml   # (versão com Secret — usada)
    ├── 28.chirpstack-v3-application-server__Service.yaml
    ├── 29.chirpstack-v3-application-server-cert-manager__...yaml  # (comentado — já no scaffold)
    ├── 30.chirpstack-v3-application-server-letsencrypt-issuer__...yaml  # (comentado)
    ├── 31.chirpstack-v3-application-server__Ingress.yaml
    └── 32.chirpstack-v3-toolbox__Deployment.yaml
```

### Passo a Passo de Implantação (v3)

O script de deploy aguarda automaticamente que Mosquitto, ambos os PostgreSQL e Redis estejam `Ready` antes de subir o Network Server e o Application Server. Esse controle é feito com `kubectl wait`.

#### Opção A — Script automático

```bash
cd 03.chirpstack_v3/00.UsefulScripts/
chmod +x 01.deploy_chirpstack-v3_script.sh
bash 01.deploy_chirpstack-v3_script.sh
```

#### Opção B — Manifests na ordem correta

```bash
cd 03.chirpstack_v3/kubernetes/

# 1. Namespace
kubectl apply -f 01.create__Namespace.yaml

# 2. Mosquitto (broker MQTT)
kubectl apply -f 02.chirpstack-v3-mosquitto__ConfigMap.yaml
kubectl apply -f 03.chirpstack-v3-mosquitto__Deployment.yaml
kubectl apply -f 04.chirpstack-v3-mosquitto__Service.yaml

# 3. Armazenamento e PostgreSQL (NS e AS)
kubectl apply -f 08.chirpstack-v3-ns-postgresql-data__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml
kubectl apply -f 09.chirpstack-v3-as-postgresql-data__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml
kubectl apply -f 10.chirpstack-v3-ns-as-postgresql__ConfigMap.yaml
kubectl apply -f 11.chirpstack-v3-ns-postgresql__Deployment.yaml
kubectl apply -f 12.chirpstack-v3-ns-postgresql__Service.yaml
kubectl apply -f 13.chirpstack-v3-as-postgresql__Deployment.yaml
kubectl apply -f 14.chirpstack-v3-as-postgresql__Service.yaml

# 4. Redis
kubectl apply -f 15.chirpstack-v3-redis-data__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml
kubectl apply -f 16.chirpstack-v3-redis__Deployment.yaml
kubectl apply -f 17.chirpstack-v3-redis__Service.yaml

# 5. Gateway Bridge
kubectl apply -f 18.chirpstack-v3-gateway-bridge__ConfigMap.yaml
kubectl apply -f 19.chirpstack-v3-gateway-bridge__Deployment.yaml
kubectl apply -f 20.chirpstack-v3-gateway-bridge__Service.yaml

# 6. Aguardar dependências ficarem Ready
kubectl wait --namespace chirpstack-v3 --for=condition=ready pod \
  --selector=app=chirpstack-v3-mosquitto-deployment --timeout=300s
kubectl wait --namespace chirpstack-v3 --for=condition=ready pod \
  --selector=app=chirpstack-v3-ns-postgresql-deployment --timeout=300s
kubectl wait --namespace chirpstack-v3 --for=condition=ready pod \
  --selector=app=chirpstack-v3-as-postgresql-deployment --timeout=300s
kubectl wait --namespace chirpstack-v3 --for=condition=ready pod \
  --selector=app=chirpstack-v3-redis-deployment --timeout=300s

# 7. Network Server
kubectl apply -f 21.chirpstack-v3-network-server__ConfigMap.yaml
kubectl apply -f 22.chirpstack-v3-network-server__Deployment.yaml
kubectl apply -f 23.chirpstack-v3-network-server__Service.yaml

# 8. Application Server (com Secret)
kubectl apply -f 25.chirpstack-v3-application-server__ConfigMap.yaml
kubectl apply -f 26.chirpstack-v3-application-server__Secret.yaml
kubectl apply -f 27.chirpstack-v3-application-server__Deployment.yaml
kubectl apply -f 28.chirpstack-v3-application-server__Service.yaml

# 9. Ingress (TLS via Let's Encrypt)
kubectl apply -f 31.chirpstack-v3-application-server__Ingress.yaml

# 10. Toolbox (debug)
kubectl apply -f 32.chirpstack-v3-toolbox__Deployment.yaml
```

#### Verificar o estado do deploy

```bash
# Todos os pods do namespace
kubectl get pods -n chirpstack-v3 -o wide

# Saída esperada (todos Running):
# NAME                                                  READY   STATUS    RESTARTS
# chirpstack-v3-mosquitto-deployment-xxx                1/1     Running   0
# chirpstack-v3-ns-postgresql-deployment-xxx            1/1     Running   0
# chirpstack-v3-as-postgresql-deployment-xxx            1/1     Running   0
# chirpstack-v3-redis-deployment-xxx                    1/1     Running   0
# chirpstack-v3-gateway-bridge-deployment-xxx           1/1     Running   0
# chirpstack-v3-network-server-deployment-xxx           1/1     Running   0
# chirpstack-v3-application-server-deployment-xxx       1/1     Running   0
# toolbox-xxx                                           1/1     Running   0

# Verificar Services e Ingress
kubectl get svc,ingress -n chirpstack-v3

# Verificar certificado TLS
kubectl get certificate -n chirpstack-v3
kubectl describe certificate chirpstack-v3-tls -n chirpstack-v3

# Verificar logs do Application Server
kubectl logs -l app=chirpstack-v3-application-server-deployment -n chirpstack-v3 --tail=50
```

### Acesso à Interface Web (v3)

Após o certificado TLS ser emitido (aguarde até 2 minutos após o Ingress ser criado):

```
URL:      https://chirpstack-v3.seudominio.com.br
Usuário:  admin
Senha:    admin   ← altere imediatamente após o primeiro acesso
```

> O domínio deve ser ajustado no arquivo `31.chirpstack-v3-application-server__Ingress.yaml` antes do deploy, substituindo `chirpstack-v3.adailsilva.com.br` pelo seu subdomínio. O registro DNS deve estar propagado e apontando para o IP do NLB antes do deploy — consulte a seção [Configuração de DNS — Subdomínios Obrigatórios](#configuração-de-dns--subdomínios-obrigatórios) para o passo a passo completo.

### Backup e Restore (v3)

```bash
# Backup dos dois bancos PostgreSQL
cd 03.chirpstack_v3/00.UsefulScripts/
chmod +x 03.back-up_chirpstack-v3_script.sh
bash 03.back-up_chirpstack-v3_script.sh
# Os arquivos são salvos em: 00.UsefulScripts/_.backups/

# Restore
chmod +x 04.restore_chirpstack-v3_script.sh
bash 04.restore_chirpstack-v3_script.sh
```

### Remover ChirpStack v3

```bash
cd 03.chirpstack_v3/00.UsefulScripts/
chmod +x 02.destroy_chirpstack-v3_script.sh
bash 02.destroy_chirpstack-v3_script.sh
```

> ⚠️ O destroy **não remove** os PersistentVolumes do OCI FSS. Os dados permanecem no File Storage Service. Para apagá-los, acesse o console OCI e remova os arquivos manualmente.

---

## 04. ChirpStack v4

### Visão Geral da Arquitetura (v4)

O ChirpStack v4 representa uma **refatoração completa** em relação ao v3. Os serviços de Network Server e Application Server foram unificados em um **único binário**, o que simplifica drasticamente a operação. Outra diferença fundamental é o suporte a **múltiplas regiões LoRaWAN simultaneamente** em uma única instância.

A v4 também adiciona **TLS ao broker MQTT** (Mosquitto na porta `8883` com autenticação por usuário/senha e certificado), e expõe uma **REST API** separada além da interface Web.

```
Gateway físico (LoRa)
    │
    │ UDP :1700 (Semtech Packet Forwarder)
    ▼
┌──────────────────────────────────────────────────────────────────┐
│  Namespace: chirpstack-v4                                        │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Gateway Bridge (chirpstack/chirpstack-gateway-bridge:   │   │
│  │  4.1)                                                    │   │
│  │  Escuta UDP :1700 ← Packet Forwarder do gateway          │   │
│  │  Publica no MQTT (TLS) → au915_1/gateway/{id}/event/{t} │   │
│  │  Service: UDP :1710→1700                                 │   │
│  └────────────────────────┬─────────────────────────────────┘   │
│                           │ MQTTS (SSL :8883)                   │
│  ┌────────────────────────▼─────────────────────────────────┐   │
│  │  Mosquitto (eclipse-mosquitto:2.0.22)                    │   │
│  │  TLS habilitado — listener 8883                          │   │
│  │  Autenticação: usuário/senha (arquivo passwd)            │   │
│  │  Certificados: CA + server.crt + server.key              │   │
│  │  allow_anonymous false                                   │   │
│  │  Service: TCP :8883                                      │   │
│  └────────────────────────┬─────────────────────────────────┘   │
│                           │ MQTTS (SSL :8883)                   │
│  ┌────────────────────────▼─────────────────────────────────┐   │
│  │  ChirpStack v4 (chirpstack/chirpstack:4.15)              │   │
│  │  Servidor unificado: NS + AS                             │   │
│  │  Regiões habilitadas: AS923, AU915, EU868, US915 e mais  │   │
│  │  API + UI: :8080→443                                     │   │
│  │  CA MQTT montada em: /etc/chirpstack/certs/ca.crt        │   │
│  │  Storage: PV 500Mi (dispositivos) no OCI FSS             │   │
│  └────────────────────────┬─────────────────────────────────┘   │
│                           │                                     │
│  ┌────────────────────────▼─────────────────────────────────┐   │
│  │  ChirpStack REST API (chirpstack/chirpstack-rest-api:    │   │
│  │  4.15)                                                   │   │
│  │  Proxy gRPC → REST HTTP                                  │   │
│  │  Port: :8090→443                                         │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  PostgreSQL (postgres:17.5)                              │   │
│  │  DB único: chirpstack                                    │   │
│  │  Usuário: chirpstack / Senha: chirpstack                 │   │
│  │  Port: :5442→5432  |  PV: 10Gi OCI FSS                  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Redis (redis:7.2)                                       │   │
│  │  Port: :6389→6379  |  PV: 1Gi OCI FSS                   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Toolbox (nicolaka/netshoot) — Pod de debug de rede      │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  Ingress (NGINX + TLS Let's Encrypt):                           │
│  https://chirpstack-v4.seudominio.com.br        → CS :443       │
│  https://chirpstack-v4-rest-api.seudominio.com.br → REST :443   │
└──────────────────────────────────────────────────────────────────┘
```

### Kubernetes Resources (namespace `chirpstack-v4`)

| Kind | Nome | Imagem | Porta(s) |
|---|---|---|---|
| `Namespace` | `chirpstack-v4` | — | — |
| `ConfigMap` | `chirpstack-v4-mosquitto-config-map` | — | Config Mosquitto com TLS |
| `Deployment` | `chirpstack-v4-mosquitto-deployment` | `eclipse-mosquitto:2.0.22` | TCP 8883 (MQTTS) |
| `Service` | `chirpstack-v4-mosquitto-service` | — | TCP 8883 |
| `StorageClass` + `PV` + `PVC` | `oci-fss-postgresql-data-chirpstack-v4-ns-as` | — | Dados PostgreSQL (10Gi) |
| `ConfigMap` | `chirpstack-v4-postgresql-config-map` | — | Script de init do banco |
| `Deployment` | `chirpstack-v4-ns-as-postgresql-deployment` | `postgres:17.5` | TCP 5442→5432 |
| `Service` | `chirpstack-v4-postgresql-service` | — | TCP 5442→5432 |
| `StorageClass` + `PV` + `PVC` | `oci-fss-redis-data-chirpstack-v4` | — | Dados Redis (1Gi) |
| `Deployment` | `chirpstack-v4-redis-deployment` | `redis:7.2` | TCP 6389→6379 |
| `Service` | `chirpstack-v4-redis-service` | — | TCP 6389→6379 |
| `ConfigMap` | `chirpstack-v4-gateway-bridge-config-map` | — | Config TOML do Gateway Bridge v4 |
| `Deployment` | `chirpstack-v4-gateway-bridge-deployment` | `chirpstack/chirpstack-gateway-bridge:4.1` | UDP 1700 |
| `Service` | `chirpstack-v4-gateway-bridge-service` | — | UDP :1710→1700 |
| `StorageClass` + `PV` + `PVC` | `oci-fss-chirpstack-devices-chirpstack-v4` | — | Dados de dispositivos (500Mi) |
| `ConfigMap` | `chirpstack-v4-config-map` | — | Config TOML ChirpStack + regiões |
| `Deployment` | `chirpstack-v4-deployment` | `chirpstack/chirpstack:4.15` | TCP 8080→443 |
| `Service` | `chirpstack-v4-service` | — | TCP 443→8080 |
| `Ingress` | `chirpstack-v4-ingress` | — | HTTPS, TLS Let's Encrypt |
| `Deployment` | `chirpstack-v4-rest-api-deployment` | `chirpstack/chirpstack-rest-api:4.15` | TCP 8090→443 |
| `Service` | `chirpstack-v4-rest-api-service` | — | TCP 443→8090 |
| `Ingress` | `chirpstack-v4-rest-api-ingress` | — | HTTPS, TLS Let's Encrypt |
| `Deployment` | `toolbox` | `nicolaka/netshoot:latest` | — (debug) |

### Configurações importantes (v4)

#### MQTT com TLS — Diferencial em relação ao v3

O ChirpStack v4 usa o Mosquitto com **TLS obrigatório na porta `8883`** e autenticação por usuário/senha — sem conexões anônimas permitidas. Esta é a principal diferença em relação ao v3, que opera na porta `1883` sem criptografia.

O TLS é gerenciado por uma **CA interna própria** (autoassinada), o que significa que:
- Nenhum certificado público (Let's Encrypt, etc.) é necessário para a camada MQTT
- A `ca.key` **nunca sobe para o cluster** — fica apenas na máquina de administração
- A `ca.crt` é distribuída a todos os clientes (ChirpStack, Gateway Bridge, gateways externos) para que possam validar o broker
- O certificado do servidor (`server.crt`) usa **Subject Alternative Names (SANs)** para cobrir tanto os nomes DNS internos do Kubernetes quanto o domínio público do cluster

```
mqtt-certs/                     (diretório local na máquina de administração)
├── ca.key              🔒 NÃO sobe ao cluster — chave privada da CA interna
├── ca.crt              ✅ Sobe ao cluster e é distribuído aos clientes
├── ca.srl                 Número serial de controle da CA
├── server-openssl.cnf     Configuração OpenSSL com SANs do servidor
├── server.key             Chave privada do servidor Mosquitto
├── server.csr             Requisição de assinatura (intermediário)
└── server.crt          ✅ Certificado do servidor assinado pela CA interna
```

O arquivo `passwd` com as credenciais dos usuários MQTT é gerado separadamente via `mosquitto_passwd` e injetado como Secret independente dos certificados TLS.

---

#### Passo 1 — Preparar o diretório de trabalho

```bash
mkdir -p ~/chirpstack/mqtt-certs
cd ~/chirpstack/mqtt-certs
```

---

#### Passo 2 — Criar a CA interna

> Execute este passo **apenas uma vez**. Se já existir `ca.crt` e `ca.key` de uma emissão anterior, pule para o Passo 3.

```bash
# Gerar a chave privada da CA (4096 bits para maior segurança)
openssl genrsa -out ca.key 4096

# Gerar o certificado autoassinado da CA (válido por 10 anos)
openssl req -x509 -new -nodes \
  -key ca.key \
  -sha256 -days 3650 \
  -out ca.crt \
  -subj "/CN=chirpstack-internal-mqtt-ca"
```

---

#### Passo 3 — Criar o arquivo de configuração do certificado do servidor (SANs)

O campo **SAN (Subject Alternative Name)** é o que clientes TLS modernos verificam para validar o nome do servidor — o campo CN sozinho não é suficiente. Sem SAN correto, a conexão falha com `certificate is not valid for any names` ou `NotValidForName`.

O arquivo abaixo cobre **todos os formatos de DNS** pelos quais o Service do Mosquitto pode ser acessado dentro do cluster Kubernetes, além do **domínio público** para acesso de gateways externos:

```bash
cat > server-openssl.cnf <<'EOF'
[ req ]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn
req_extensions     = req_ext

[ dn ]
CN = chirpstack-v4.seudominio.com.br

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
# Domínio público (NLB / DNS externo — usado pelos gateways LoRaWAN físicos)
DNS.1 = chirpstack-v4.seudominio.com.br

# DNS interno do Kubernetes (usado pelo ChirpStack v4 e Gateway Bridge dentro do cluster)
DNS.2 = chirpstack-v4-mosquitto-service
DNS.3 = chirpstack-v4-mosquitto-service.chirpstack-v4
DNS.4 = chirpstack-v4-mosquitto-service.chirpstack-v4.svc
DNS.5 = chirpstack-v4-mosquitto-service.chirpstack-v4.svc.cluster.local
EOF
```

> Substitua `chirpstack-v4.seudominio.com.br` pelo seu domínio público real. Se usar um domínio dedicado para MQTT (ex: `mqtt.seudominio.com.br`), adicione-o como `DNS.6`.

---

#### Passo 4 — Gerar a chave e o CSR do servidor Mosquitto

```bash
# Chave privada do servidor (2048 bits)
openssl genrsa -out server.key 2048

# Requisição de assinatura usando o arquivo de configuração com SANs
openssl req -new \
  -key server.key \
  -out server.csr \
  -config server-openssl.cnf
```

---

#### Passo 5 — Assinar o certificado do servidor com a CA interna

```bash
openssl x509 -req \
  -in server.csr \
  -CA ca.crt \
  -CAkey ca.key \
  -CAcreateserial \
  -out server.crt \
  -days 825 \
  -sha256 \
  -extensions req_ext \
  -extfile server-openssl.cnf
```

> O prazo de 825 dias é o máximo aceito pela maioria dos clientes modernos. Após o vencimento, repita os Passos 3 a 5 com a mesma CA (não é necessário recriar a CA).

**Arquivos resultantes que sobem ao cluster:**

| Arquivo | Destino | Uso |
|---|---|---|
| `ca.crt` | Secrets no cluster + gateways externos | Clientes validam o broker com este arquivo |
| `server.crt` | Secret `chirpstack-v4-mosquitto-tls` | Certificado público do broker Mosquitto |
| `server.key` | Secret `chirpstack-v4-mosquitto-tls` | Chave privada do broker Mosquitto |

---

#### Passo 6 — Gerar o arquivo de senhas do Mosquitto (bcrypt)

O Mosquitto usa um arquivo `passwd` com hashes bcrypt — **não armazene senhas em texto puro**. A forma correta de gerar esse arquivo é via o utilitário `mosquitto_passwd`, executado dentro do próprio container:

```bash
# Gerar o arquivo passwd com bcrypt usando o container oficial do Mosquitto
docker run --rm -it eclipse-mosquitto:2.0.22 sh -lc \
  'mosquitto_passwd -c -b /tmp/passwd adailsilva "H@cker101" && cat /tmp/passwd' \
  > passwd
```

---

#### Passo 7 — Criar os Secrets no Kubernetes

São necessários **4 Secrets distintos**, cada um com uma responsabilidade clara:

```bash
# 1. Secret TLS do Mosquitto (broker) — certificados do servidor
#    Montado em /mosquitto/certs/ dentro do pod do Mosquitto
kubectl -n chirpstack-v4 delete secret chirpstack-v4-mosquitto-tls --ignore-not-found

kubectl -n chirpstack-v4 create secret generic chirpstack-v4-mosquitto-tls \
  --from-file=ca.crt=./ca.crt \
  --from-file=tls.crt=./server.crt \
  --from-file=tls.key=./server.key

# 2. Secret de autenticação do Mosquitto — arquivo passwd (bcrypt)
#    Montado em /mosquitto/auth/passwd dentro do pod do Mosquitto
kubectl -n chirpstack-v4 delete secret mosquitto-auth --ignore-not-found

kubectl -n chirpstack-v4 create secret generic mosquitto-auth \
  --from-file=passwd=./passwd

# 3. Secret da CA interna — para o ChirpStack v4 confiar no broker MQTT
#    Montado em /etc/chirpstack/certs/ca.crt dentro do pod do ChirpStack
kubectl -n chirpstack-v4 delete secret chirpstack-mqtt-ca --ignore-not-found

kubectl -n chirpstack-v4 create secret generic chirpstack-mqtt-ca \
  --from-file=ca.crt=./ca.crt

# 4. Secret de credenciais MQTT — usuário/senha para o ChirpStack v4 autenticar no broker
kubectl -n chirpstack-v4 delete secret chirpstack-mqtt-credentials --ignore-not-found

kubectl -n chirpstack-v4 create secret generic chirpstack-mqtt-credentials \
  --from-literal=MQTT_USERNAME=adailsilva \
  --from-literal=MQTT_PASSWORD='H@cker101'
```

> O Secret `mosquitto-auth` e o `chirpstack-mqtt-credentials` são intencionalmente separados: o primeiro é o arquivo `passwd` que o **broker** usa para autenticar clientes; o segundo são as credenciais que o **cliente** (ChirpStack v4) envia ao broker.

---

#### Passo 8 — Configuração do Mosquitto (ConfigMap)

O `mosquitto.conf` no ConfigMap deve ter exatamente estas diretivas para o listener TLS:

```conf
listener 8883
protocol mqtt
allow_anonymous false
password_file /mosquitto/auth/passwd

cafile   /mosquitto/certs/ca.crt
certfile /mosquitto/certs/tls.crt
keyfile  /mosquitto/certs/tls.key

tls_version tlsv1.2
```

---

#### Passo 9 — Configuração do ChirpStack v4 (chirpstack.toml)

O ChirpStack precisa montar a CA interna e apontar para ela no TOML. No Deployment, inclua:

```yaml
volumeMounts:
  - name: mqtt-ca
    mountPath: /etc/chirpstack/certs
    readOnly: true

volumes:
  - name: mqtt-ca
    secret:
      secretName: chirpstack-mqtt-ca
```

E no ConfigMap `chirpstack.toml`, na seção de integração MQTT:

```toml
[integration.mqtt]
  server = "ssl://chirpstack-v4-mosquitto-service.chirpstack-v4.svc.cluster.local:8883"
  username = "adailsilva"
  password = "H@cker101"
  ca_cert  = "/etc/chirpstack/certs/ca.crt"
```

---

#### Passo 10 — Verificar a montagem dos arquivos dentro dos pods

Após o deploy, confirme que os Secrets foram montados corretamente:

```bash
# Verificar certs e auth dentro do pod do Mosquitto
kubectl -n chirpstack-v4 exec -it deploy/chirpstack-v4-mosquitto-deployment -- \
  sh -lc 'ls -l /mosquitto/certs && echo "----" && ls -l /mosquitto/auth'

# Verificar o conteúdo do arquivo passwd (deve mostrar o hash bcrypt)
kubectl -n chirpstack-v4 exec -it deploy/chirpstack-v4-mosquitto-deployment -- \
  sh -lc 'cat /mosquitto/auth/passwd'

# Verificar a CA montada no pod do ChirpStack
kubectl -n chirpstack-v4 exec -it deploy/chirpstack-v4-deployment -- \
  sh -lc 'ls -l /etc/chirpstack/certs && openssl x509 -in /etc/chirpstack/certs/ca.crt -noout -subject -dates'
```

---

#### Passo 11 — Reiniciar os deployments para aplicar

```bash
# Reiniciar o Mosquitto para carregar os novos Secrets
kubectl -n chirpstack-v4 rollout restart deployment chirpstack-v4-mosquitto-deployment

# Aguardar ficar Ready
kubectl -n chirpstack-v4 rollout status deployment chirpstack-v4-mosquitto-deployment

# Reiniciar o ChirpStack v4
kubectl -n chirpstack-v4 rollout restart deployment chirpstack-v4-deployment
kubectl -n chirpstack-v4 rollout status deployment chirpstack-v4-deployment
```

---

#### Passo 12 — Validar o handshake TLS dentro do cluster

```bash
# Teste de handshake TLS usando pod temporário Alpine
kubectl -n chirpstack-v4 run tlscheck --rm -it --restart=Never --image=alpine:3.20 -- sh -lc '
  apk add --no-cache openssl >/dev/null 2>&1
  echo | openssl s_client \
    -connect chirpstack-v4-mosquitto-service.chirpstack-v4.svc.cluster.local:8883 \
    -servername chirpstack-v4-mosquitto-service.chirpstack-v4.svc.cluster.local \
    2>/dev/null \
  | openssl x509 -noout -subject -issuer -ext subjectAltName
'
```

**Resultado esperado:** o campo `subjectAltName` deve conter todos os DNS configurados no Passo 3. Se aparecer, o TLS está funcionando corretamente.

---

#### Passo 13 — Validar autenticação e roteamento de tópicos MQTT

```bash
# Teste de subscribe com CA interna + usuário/senha
# (execute na máquina com kubectl configurado — não no gateway LoRaWAN)
kubectl -n chirpstack-v4 run mosqtest --rm -it --restart=Never \
  --image=eclipse-mosquitto:2.0.22 -- sh -lc '
    # Injeta a CA interna no pod temporário
    cat <<CA_EOF >/tmp/ca.crt
-----BEGIN CERTIFICATE-----
<cole aqui o conteúdo de ca.crt>
-----END CERTIFICATE-----
CA_EOF
    mosquitto_sub \
      -h chirpstack-v4-mosquitto-service.chirpstack-v4.svc.cluster.local \
      -p 8883 \
      --cafile /tmp/ca.crt \
      -u "adailsilva" -P "H@cker101" \
      -t "au915_1/gateway/+/event/#" -v -d
  '
```

**Resultado esperado:**
- ✅ Conecta na porta `8883` com TLS
- ✅ Sem erros `NotValidForName` ou `unknown ca`
- ✅ Sem `connection reset`
- ✅ Aguardando mensagens no tópico `au915_1/gateway/+/event/#`

Para testar a partir de um **gateway LoRaWAN externo** (fora do cluster), use o hostname público e o `ca.crt` copiado para o gateway:

```bash
mosquitto_sub \
  -h chirpstack-v4.seudominio.com.br \
  -p 8883 \
  --cafile /etc/chirpstack-gateway-bridge/certs/ca.crt \
  -u "adailsilva" -P "H@cker101" \
  -t "au915_1/gateway/+/event/#" -v -d
```

---

#### Distribuir a CA interna para os gateways LoRaWAN externos

Gateways físicos fora do cluster precisam do `ca.crt` para validar o broker MQTT. O certificado precisa ser copiado para cada gateway e o serviço do ChirpStack Gateway Bridge deve ser reiniciado para que a nova CA seja carregada.

**Passo 1 — Copiar o `ca.crt` para cada gateway via `scp`**

Ajuste os IPs e caminhos conforme o seu ambiente:

```bash
# Formato genérico
scp ~/chirpstack/mqtt-certs/ca.crt <usuario>@<IP_GATEWAY>:/home/<usuario>/chirpstack/chirpstack-gateway-bridge/
```

Exemplo com os gateways deste ambiente (IPs da rede local):

```bash
scp /home/adailsilva/Apps/OracleCloud/00.Useful/mqtt-certs/ca.crt \
  adailsilva@192.168.18.201:/home/adailsilva/chirpstack/chirpstack-gateway-bridge/

scp /home/adailsilva/Apps/OracleCloud/00.Useful/mqtt-certs/ca.crt \
  adailsilva@192.168.18.202:/home/adailsilva/chirpstack/chirpstack-gateway-bridge/

scp /home/adailsilva/Apps/OracleCloud/00.Useful/mqtt-certs/ca.crt \
  adailsilva@192.168.18.203:/home/adailsilva/chirpstack/chirpstack-gateway-bridge/

scp /home/adailsilva/Apps/OracleCloud/00.Useful/mqtt-certs/ca.crt \
  adailsilva@192.168.18.204:/home/adailsilva/chirpstack/chirpstack-gateway-bridge/

scp /home/adailsilva/Apps/OracleCloud/00.Useful/mqtt-certs/ca.crt \
  adailsilva@192.168.18.205:/home/adailsilva/chirpstack/chirpstack-gateway-bridge/
```

**Passo 2 — Em cada gateway, mover o `ca.crt` para o diretório de certs**

Acesse cada gateway via SSH e execute:

```bash
# Criar o diretório de certs e ajustar permissões
sudo mkdir -p /etc/chirpstack-gateway-bridge/certs/
sudo chown -R adailsilva:adailsilva /etc/chirpstack-gateway-bridge/certs/
sudo chmod 750 /etc/chirpstack-gateway-bridge/certs/

# Copiar o certificado para o local definitivo configurado no chirpstack-gateway-bridge.toml
# Formato genérico:
sudo cp /home/<usuario>/chirpstack/chirpstack-gateway-bridge/ca.crt \
  /etc/chirpstack-gateway-bridge/certs/

# Exemplo deste ambiente:
sudo cp /home/adailsilva/chirpstack/chirpstack-gateway-bridge/ca.crt \
  /etc/chirpstack-gateway-bridge/certs/

# Confirmar o dono e permissões do diretório e do arquivo copiado
ls -ld /etc/chirpstack-gateway-bridge/certs/
ls -lh /etc/chirpstack-gateway-bridge/certs/
```

> Usamos `cp` em vez de `mv` para preservar o arquivo original no diretório de staging (`~/chirpstack/chirpstack-gateway-bridge/`), que serve como cópia de referência e backup local no gateway.

**Passo 3 — Reiniciar os serviços no gateway**

> Após copiar o `ca.crt`, os serviços do gateway **precisam ser reiniciados** para que o novo certificado seja carregado. Sem o restart, o Gateway Bridge continua usando a configuração anterior e a conexão MQTT com TLS falhará.

Acesse o gateway via SSH e reinicie os dois serviços — primeiro o Packet Forwarder, depois o Gateway Bridge:

```bash
# Acessar o gateway
ssh adailsilva@192.168.18.201   # ajuste o IP conforme o gateway

# Reiniciar o Semtech UDP Packet Forwarder
sudo systemctl restart adailsilva_lorawan_semtech_udp_packet_forwarder.service

# Reiniciar o ChirpStack Gateway Bridge
sudo systemctl restart adailsilva_lorawan_chirpstack_gateway_bridge.service
```

Repita o mesmo procedimento para cada gateway:

```bash
# Loop para reiniciar em todos os gateways (ajuste os IPs)
for IP in 192.168.18.201 192.168.18.202 192.168.18.203 192.168.18.204 192.168.18.205; do
  echo ">>> Reiniciando serviços em ${IP}..."
  ssh adailsilva@${IP} "
    sudo systemctl restart adailsilva_lorawan_semtech_udp_packet_forwarder.service &&
    sudo systemctl restart adailsilva_lorawan_chirpstack_gateway_bridge.service &&
    echo '✅ Serviços reiniciados em ${IP}'
  "
done
```

> Os nomes dos serviços (`adailsilva_lorawan_semtech_udp_packet_forwarder.service` e `adailsilva_lorawan_chirpstack_gateway_bridge.service`) são os nomes dos units do systemd configurados neste ambiente. Substitua pelos nomes corretos do seu ambiente caso sejam diferentes — o padrão da instalação oficial do ChirpStack usa `chirpstack-gateway-bridge.service`.

**Passo 4 — Inspecionar os logs dos serviços**

Após o restart, monitore os logs de cada serviço com `journalctl -f` para confirmar que a conexão MQTT com TLS foi estabelecida com sucesso.

```bash
# Logs do Semtech UDP Packet Forwarder (recepção de pacotes dos dispositivos LoRa)
sudo journalctl -u adailsilva_lorawan_semtech_udp_packet_forwarder.service -f

# Logs do ChirpStack Gateway Bridge (conexão MQTT com o cluster)
sudo journalctl -u adailsilva_lorawan_chirpstack_gateway_bridge.service -f
```

Para inspecionar os logs de um serviço com nome diferente, basta substituir o nome do unit:

```bash
# Formato genérico
sudo journalctl -u <nome-do-servico>.service -f

# Exemplo com o nome padrão da instalação oficial do ChirpStack
sudo journalctl -u chirpstack-gateway-bridge.service -f
```

Nos logs do **Gateway Bridge**, procure pelas seguintes linhas indicando sucesso:

```
level=info msg="connecting to mqtt broker" server="ssl://chirpstack-v4.seudominio.com.br:8883"
level=info msg="connected to mqtt broker"
level=info msg="subscribing to topic" topic="au915_1/gateway/<EUI>/command/#"
```

Se aparecerem erros como `x509: certificate signed by unknown authority` ou `tls: bad certificate`, o `ca.crt` não foi carregado corretamente — verifique o caminho configurado no `chirpstack-gateway-bridge.toml` e repita o Passo 2.

---

#### Resumo rápido — sequência completa por gateway

Para facilitar a execução no dia a dia, abaixo está a sequência mínima e completa de comandos necessários para distribuir a CA e reativar a conexão MQTT TLS em um gateway. O exemplo usa o gateway `192.168.18.201` — repita a sequência substituindo o IP para cada gateway do ambiente:

```bash
# 1. Copiar o ca.crt da máquina de administração para o gateway
scp /home/adailsilva/Apps/OracleCloud/00.Useful/mqtt-certs/ca.crt \
  adailsilva@192.168.18.201:/home/adailsilva/chirpstack/chirpstack-gateway-bridge/

# 2. Acessar o gateway via SSH
ssh adailsilva@192.168.18.201

# 3. Mover o certificado para o diretório de certs do Gateway Bridge
#    (sem sudo pois o usuário já é dono do diretório de destino)
cp /home/adailsilva/chirpstack/chirpstack-gateway-bridge/ca.crt \
  /etc/chirpstack-gateway-bridge/certs/

# 4. Reiniciar o serviço do ChirpStack Gateway Bridge
sudo systemctl restart adailsilva_lorawan_chirpstack_gateway_bridge.service

# 5. Acompanhar os logs em tempo real para confirmar a conexão
sudo journalctl -u adailsilva_lorawan_chirpstack_gateway_bridge.service -f
```

> Note que no Passo 3 o comando é `cp` **sem** `sudo` — isso é possível porque o diretório `/etc/chirpstack-gateway-bridge/certs/` foi criado com `chown` para o usuário `adailsilva` no Passo 2 da seção anterior. Se o seu ambiente usar outro usuário ou permissões diferentes, adicione `sudo` conforme necessário.

---



Se o domínio público mudar ou um novo gateway precisar de um hostname diferente, atualize o `server-openssl.cnf` com os novos SANs e reemita **apenas o certificado do servidor** — a CA interna permanece a mesma:

```bash
cd ~/chirpstack/mqtt-certs/

# 1. Atualizar server-openssl.cnf com os novos SANs
# 2. Reemitir chave e certificado do servidor
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -config server-openssl.cnf
openssl x509 -req \
  -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt -days 825 -sha256 \
  -extensions req_ext -extfile server-openssl.cnf

# 3. Atualizar o Secret no Kubernetes
kubectl -n chirpstack-v4 delete secret chirpstack-v4-mosquitto-tls --ignore-not-found
kubectl -n chirpstack-v4 create secret generic chirpstack-v4-mosquitto-tls \
  --from-file=ca.crt=./ca.crt \
  --from-file=tls.crt=./server.crt \
  --from-file=tls.key=./server.key

# 4. Reiniciar o Mosquitto para aplicar
kubectl -n chirpstack-v4 rollout restart deployment chirpstack-v4-mosquitto-deployment
```

> A `ca.crt` não muda neste processo — os clientes (ChirpStack, gateways) não precisam ser reconfigurados. Apenas o broker Mosquitto recebe o novo certificado.

---

#### Diagnóstico de problemas comuns de TLS

| Sintoma | Causa mais provável | Solução |
|---|---|---|
| `NotValidForName` | Hostname usado na conexão não está nos SANs | Adicionar o hostname ao `server-openssl.cnf` e reemitir o `server.crt` |
| `unknown ca` | Cliente usando CA diferente da que assinou o servidor | Verificar se o `ca.crt` do cliente é o mesmo usado para assinar o `server.crt` |
| `connection reset` | Configuração errada no `mosquitto.conf` | Verificar caminhos de `cafile`, `certfile`, `keyfile` |
| `bad username or password` | Hash bcrypt desatualizado ou Secret errado montado | Recriar o arquivo `passwd` e o Secret `mosquitto-auth` |
| Pod em `CrashLoopBackOff` | Arquivo de certificado inválido ou Secret não montado | Verificar com `kubectl describe pod` e `kubectl logs` |

Para confirmar qual certificado o servidor está servindo (antes de qualquer debug):

```bash
echo | openssl s_client \
  -connect chirpstack-v4.seudominio.com.br:8883 \
  -servername chirpstack-v4.seudominio.com.br \
  2>/dev/null \
| openssl x509 -noout -subject -ext subjectAltName
```

---

#### Expor o MQTT TLS externamente via Ingress NGINX (TCP passthrough)

Após toda a configuração do TLS no Mosquitto, a porta `8883` ainda não está acessível de fora do cluster por padrão. O Ingress NGINX não roteará tráfego TCP/TLS automaticamente — é necessário configurar o **TCP Services ConfigMap** do Ingress Controller para que ele faça o passthrough da porta `8883` diretamente ao Service do Mosquitto.

> **Por que TCP passthrough e não um Ingress normal?** O protocolo MQTT não é HTTP. O Ingress NGINX em modo padrão só roteia HTTP/HTTPS. Para TCP puro (como MQTT/MQTTS), o controller usa um ConfigMap de serviços TCP que instrui o pod a abrir a porta e encaminhar os pacotes diretamente — sem inspecionar o conteúdo (passthrough). O TLS é terminado pelo próprio Mosquitto, não pelo Ingress.

```
Gateway LoRaWAN externo (ou cliente MQTT)
    │
    │ TCP :8883 (MQTTS)
    ▼
NLB OCI  →  worker NodePort  →  Ingress NGINX (TCP passthrough :8883)
                                      │
                                      └── chirpstack-v4/chirpstack-v4-mosquitto-service:8883
                                                │
                                                └── Pod Mosquitto (TLS termina aqui)
```

**Passo 1 — Descomentar a entrada do MQTTS no manifesto do Ingress Controller**

Abra o arquivo do Ingress Controller do projeto:

```
k8s_scaffold/apps/ingress-controller.yaml
```

Localize o bloco do ConfigMap `tcp-services` e descomente a linha referente à porta `8883`:

```yaml
# Antes (comentado):
# 8883: "chirpstack-v4/chirpstack-v4-mosquitto-service:8883"

# Depois (descomentado):
8883: "chirpstack-v4/chirpstack-v4-mosquitto-service:8883"
```

O formato é `<porta-externa>: "<namespace>/<nome-do-service>:<porta-do-service>"`.

**Passo 2 — Aplicar o manifesto do Ingress Controller manualmente**

```bash
kubectl apply -f k8s_scaffold/apps/ingress-controller.yaml
```

> Este manifesto recria o Ingress Controller com a nova configuração de TCP Services. O `kubectl apply` é idempotente — recursos já existentes são atualizados, não recriados do zero.

**Passo 3 — Verificar se a porta foi registrada no pod do Ingress**

```bash
# Listar as portas abertas no pod do Ingress NGINX
kubectl get pod -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -o jsonpath=\
  '{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].ports[*].containerPort}{"\n"}{end}'

# Verificar o ConfigMap tcp-services
kubectl get configmap tcp-services -n ingress-nginx -o yaml

# Saída esperada no ConfigMap:
# data:
#   "8883": chirpstack-v4/chirpstack-v4-mosquitto-service:8883
```

**Passo 4 — Verificar o Service do Ingress NGINX para a porta NodePort**

```bash
# O Service do Ingress deve ter a porta 8883 mapeada como NodePort
kubectl get svc ingress-nginx-controller -n ingress-nginx -o yaml | grep -A3 "8883"
```

**Passo 5 — Confirmar conectividade externa**

Com a porta exposta, teste a partir de uma máquina fora do cluster (ex: o gateway LoRaWAN físico ou sua máquina local):

```bash
# Handshake TLS pelo endereço público do cluster
echo | openssl s_client \
  -connect chirpstack-v4.seudominio.com.br:8883 \
  -CAfile ~/chirpstack/mqtt-certs/ca.crt \
  -servername chirpstack-v4.seudominio.com.br \
  2>/dev/null \
| openssl x509 -noout -subject -ext subjectAltName

# Subscribe externo com CA + credenciais
mosquitto_sub \
  -h chirpstack-v4.seudominio.com.br \
  -p 8883 \
  --cafile ~/chirpstack/mqtt-certs/ca.crt \
  -u "adailsilva" -P "H@cker101" \
  -t "au915_1/gateway/+/event/#" \
  -v -d
```

**Resultado esperado:**
```
Client mosq-xxxx sending CONNECT
Client mosq-xxxx received CONNACK (0)   ← 0 = conexão aceita com TLS
Client mosq-xxxx sending SUBSCRIBE
Client mosq-xxxx received SUBACK        ← inscrito — broker externo OK
```

> Se o CONNACK retornar código diferente de `0`, consulte a tabela de diagnóstico na seção [Diagnóstico de problemas comuns de TLS](#diagnóstico-de-problemas-comuns-de-tls).

---

#### Banco de dados (v4 — banco único)

Ao contrário do v3, o v4 usa **um único banco PostgreSQL** chamado `chirpstack`:

| Banco | Usuário | Senha | Porta ClusterIP |
|---|---|---|---|
| `chirpstack` | `chirpstack` | `chirpstack` | `:5442` |

#### Regiões LoRaWAN habilitadas

O v4 suporta múltiplas regiões simultaneamente no mesmo ConfigMap principal (`chirpstack.toml`):

```toml
[network]
  enabled_regions = [
    "as923", "as923_2", "as923_3", "as923_4",
    "au915_0", "au915_1",
    "cn470_10", "cn779",
    "eu433", "eu868",
    "in865", "ism2400",
    "kr920", "ru864",
    "us915_0", "us915_1"
  ]
```

Cada região tem seu próprio arquivo TOML de configuração (`region_au915_0.toml`, `region_au915_1.toml`, etc.) dentro do mesmo ConfigMap, permitindo ajuste fino por região sem redeployar os outros.

#### API Secret

```toml
[api]
  bind = "0.0.0.0:8080"
  secret = "you-must-replace-this"
```

> Para produção, gere um secret seguro: `openssl rand -base64 32`. Altere no ConfigMap `16.chirpstack-v4__ConfigMap.yaml` antes do deploy.

#### Armazenamento persistente (OCI FSS)

| Volume | Caminho no FSS | Tamanho |
|---|---|---|
| Dados PostgreSQL | `/FileSystem-K8S/chirpstack-v4-ns-as` | 10Gi |
| Dados Redis | `/FileSystem-K8S/chirpstack-v4-redis-data` | 1Gi |
| Dados de dispositivos | `/FileSystem-K8S/chirpstack-v4-devices` | 500Mi |

> Todos estes diretórios devem ser criados com as permissões corretas antes do deploy. Consulte a seção [Pré-requisito: OCI File Storage Service (FSS)](#pré-requisito-oci-file-storage-service-fss) para o script de montagem e preparação.

```
04.chirpstack_v4/
├── 00.UsefulScripts/
│   ├── 00.pgpass__move_to_user_directory    # Arquivo .pgpass para acesso psql sem senha
│   ├── 01.deploy_chirpstack-v4_script.sh    # Deploy completo na ordem correta
│   ├── 02.destroy_chirpstack-v4_script.sh   # Remove todos os recursos
│   ├── 03.back-up_chirpstack-v4_script.sh   # Backup do banco PostgreSQL
│   └── 04.restore_chirpstack-v4_script.sh   # Restore do backup
├── 00.useful_commands.txt                   # Comandos úteis do dia a dia
├── docker/docker-compose.yaml               # Versão Docker Compose para testes locais
├── mqtt-certs/                              # Certificados TLS do Mosquitto
│   ├── ca.crt / ca.key / ca.srl
│   ├── server-openssl.cnf
│   ├── server.crt / server.csr / server.key
│   └── passwd                              # Arquivo de autenticação Mosquitto
└── kubernetes/
    ├── 01.create__Namespace.yaml
    ├── 02.chirpstack-v4-mosquitto__ConfigMap.yaml
    ├── 03.chirpstack-v4-mosquitto__Deployment.yaml
    ├── 04.chirpstack-v4-mosquitto__Service.yaml
    ├── 05.chirpstack-v4-postgresql__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml
    ├── 06.chirpstack-v4-postgresql__ConfigMap.yaml
    ├── 07.chirpstack-v4-postgresql__Deployment.yaml
    ├── 08.chirpstack-v4-postgresql__Service.yaml
    ├── 09.chirpstack-v4-redis__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml
    ├── 10.chirpstack-v4-redis__Deployment.yaml
    ├── 11.chirpstack-v4-redis__Service.yaml
    ├── 12.chirpstack-v4-bridge-gateway__ConfigMap.yaml
    ├── 13.chirpstack-v4-bridge-gateway__Deployment.yaml
    ├── 14.chirpstack-v4-bridge-gateway__Service.yaml
    ├── 15.chirpstack-v4__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml
    ├── 16.chirpstack-v4__ConfigMap.yaml         # Config principal + regiões
    ├── 17.chirpstack-v4__Deployment.yaml
    ├── 18.chirpstack-v4__Service.yaml
    ├── 19.chirpstack-v4-cert-manager__...yaml   # (comentado — já no scaffold)
    ├── 20.chirpstack-v4-letsencrypt-issuer__...yaml  # (comentado)
    ├── 21.chirpstack-v4__Ingress.yaml
    ├── 22.chirpstack-v4-rest-api__Deployment.yaml
    ├── 23.chirpstack-v4-rest-api__Service.yaml
    ├── 24.chirpstack-v4-rest-api-cert-manager__...yaml  # (comentado)
    ├── 25.chirpstack-v4-rest-api-letsencrypt-issuer__...yaml  # (comentado)
    ├── 26.chirpstack-v4-rest-api__Ingress.yaml
    └── 27.chirpstack-v4-toolbox__Deployment.yaml
```

### Passo a Passo de Implantação (v4)

#### Pré-requisito: Secrets TLS e autenticação

Antes de executar o deploy, os Secrets de TLS e autenticação do Mosquitto **precisam existir** no namespace `chirpstack-v4`. Crie-os conforme descrito na seção [Criar os Secrets TLS](#criar-os-secrets-tls-e-de-autenticação-no-kubernetes).

#### Opção A — Script automático

```bash
cd 04.chirpstack_v4/00.UsefulScripts/
chmod +x 01.deploy_chirpstack-v4_script.sh
bash 01.deploy_chirpstack-v4_script.sh
```

#### Opção B — Manifests na ordem correta

```bash
cd 04.chirpstack_v4/kubernetes/

# 1. Namespace
kubectl apply -f 01.create__Namespace.yaml

# 2. Mosquitto com TLS
kubectl apply -f 02.chirpstack-v4-mosquitto__ConfigMap.yaml
kubectl apply -f 03.chirpstack-v4-mosquitto__Deployment.yaml
kubectl apply -f 04.chirpstack-v4-mosquitto__Service.yaml

# 3. PostgreSQL (banco único chirpstack)
kubectl apply -f 05.chirpstack-v4-postgresql__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml
kubectl apply -f 06.chirpstack-v4-postgresql__ConfigMap.yaml
kubectl apply -f 07.chirpstack-v4-postgresql__Deployment.yaml
kubectl apply -f 08.chirpstack-v4-postgresql__Service.yaml

# 4. Redis
kubectl apply -f 09.chirpstack-v4-redis__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml
kubectl apply -f 10.chirpstack-v4-redis__Deployment.yaml
kubectl apply -f 11.chirpstack-v4-redis__Service.yaml

# 5. Gateway Bridge v4
kubectl apply -f 12.chirpstack-v4-bridge-gateway__ConfigMap.yaml
kubectl apply -f 13.chirpstack-v4-bridge-gateway__Deployment.yaml
kubectl apply -f 14.chirpstack-v4-bridge-gateway__Service.yaml

# 6. Aguardar dependências ficarem Ready
kubectl wait --namespace chirpstack-v4 --for=condition=ready pod \
  --selector=app=chirpstack-v4-mosquitto-deployment --timeout=300s
kubectl wait --namespace chirpstack-v4 --for=condition=ready pod \
  --selector=app=chirpstack-v4-ns-as-postgresql-deployment --timeout=300s
kubectl wait --namespace chirpstack-v4 --for=condition=ready pod \
  --selector=app=chirpstack-v4-redis-deployment --timeout=300s

# 7. ChirpStack v4 (servidor unificado)
kubectl apply -f 15.chirpstack-v4__StorageClass__PersistentVolume__PersistentVolumeClaim.yaml
kubectl apply -f 16.chirpstack-v4__ConfigMap.yaml
kubectl apply -f 17.chirpstack-v4__Deployment.yaml
kubectl apply -f 18.chirpstack-v4__Service.yaml

# 8. Ingress principal (UI + API gRPC)
kubectl apply -f 21.chirpstack-v4__Ingress.yaml

# 9. REST API
kubectl apply -f 22.chirpstack-v4-rest-api__Deployment.yaml
kubectl apply -f 23.chirpstack-v4-rest-api__Service.yaml
kubectl apply -f 26.chirpstack-v4-rest-api__Ingress.yaml

# 10. Toolbox (debug)
kubectl apply -f 27.chirpstack-v4-toolbox__Deployment.yaml
```

#### Verificar o estado do deploy

```bash
# Todos os pods do namespace
kubectl get pods -n chirpstack-v4 -o wide

# Saída esperada (todos Running):
# NAME                                                READY   STATUS    RESTARTS
# chirpstack-v4-mosquitto-deployment-xxx              1/1     Running   0
# chirpstack-v4-ns-as-postgresql-deployment-xxx       1/1     Running   0
# chirpstack-v4-redis-deployment-xxx                  1/1     Running   0
# chirpstack-v4-gateway-bridge-deployment-xxx         1/1     Running   0
# chirpstack-v4-deployment-xxx                        1/1     Running   0
# chirpstack-v4-rest-api-deployment-xxx               1/1     Running   0
# toolbox-xxx                                         1/1     Running   0

# Services e Ingress
kubectl get svc,ingress -n chirpstack-v4

# Certificados TLS
kubectl get certificate -n chirpstack-v4

# Logs do servidor ChirpStack
kubectl logs -l app=chirpstack-v4-deployment -n chirpstack-v4 --tail=50

# Logs do Gateway Bridge
kubectl logs -l app=chirpstack-v4-gateway-bridge-deployment -n chirpstack-v4 --tail=30
```

### Acesso à Interface Web e REST API (v4)

```
UI + API gRPC:  https://chirpstack-v4.seudominio.com.br
REST API:       https://chirpstack-v4-rest-api.seudominio.com.br

Usuário padrão:  admin
Senha padrão:    admin   ← altere imediatamente após o primeiro acesso
```

> Atualize os domínios nos arquivos `21.chirpstack-v4__Ingress.yaml` e `26.chirpstack-v4-rest-api__Ingress.yaml` antes do deploy, substituindo `chirpstack-v4.adailsilva.com.br` e `chirpstack-v4-rest-api.adailsilva.com.br` pelos seus subdomínios. Ambos os registros DNS precisam estar propagados antes do deploy para que o cert-manager consiga emitir os certificados TLS. Consulte a seção [Configuração de DNS — Subdomínios Obrigatórios](#configuração-de-dns--subdomínios-obrigatórios).

### Backup e Restore (v4)

```bash
# Backup do banco PostgreSQL
cd 04.chirpstack_v4/00.UsefulScripts/
chmod +x 03.back-up_chirpstack-v4_script.sh
bash 03.back-up_chirpstack-v4_script.sh
# Arquivo salvo em: 00.UsefulScripts/_.backups/

# Restore
chmod +x 04.restore_chirpstack-v4_script.sh
bash 04.restore_chirpstack-v4_script.sh
```

### Remover ChirpStack v4

```bash
cd 04.chirpstack_v4/00.UsefulScripts/
chmod +x 02.destroy_chirpstack-v4_script.sh
bash 02.destroy_chirpstack-v4_script.sh
```

---

## Comparativo v3 vs v4

| Aspecto | ChirpStack v3 | ChirpStack v4 |
|---|---|---|
| **Arquitetura** | Microserviços separados (NS + AS) | Servidor unificado (NS + AS em um binário) |
| **Banco de dados** | 2 instâncias PostgreSQL (NS e AS) | 1 instância PostgreSQL (chirpstack) |
| **PostgreSQL** | `14-alpine` | `17.5` |
| **Gateway Bridge** | `3.14.8` | `4.1` |
| **MQTT** | Sem TLS — porta `1883`, anônimo | Com TLS — porta `8883`, usuário/senha |
| **Regiões LoRaWAN** | 1 região por instância | Múltiplas regiões simultâneas |
| **REST API** | Integrada ao Application Server | Serviço separado (`chirpstack-rest-api`) |
| **Namespace** | `chirpstack-v3` | `chirpstack-v4` |
| **UI** | `https://chirpstack-v3.dominio.com.br` | `https://chirpstack-v4.dominio.com.br` |
| **gRPC** | `:8000` (NS) e `:8001` (AS) | `:8080` (unificado) |
| **Porta Gateway UDP** | `:1700` | `:1710→1700` |
| **Armazenamento total** | ~21,1 Gi | ~11,5 Gi |
| **Coexistência** | ✅ Sim — namespaces distintos | ✅ Sim — namespaces distintos |


---

## Mapa de Serviços e Links de Acesso

Referência rápida de todos os serviços disponíveis no cluster após o provisionamento e deploy completos. Substitua `seudominio.com.br` pelo seu domínio real.

### Serviços HTTP/HTTPS — acesso pelo navegador

| Serviço | URL | Credenciais padrão | Namespace |
|---|---|---|---|
| **Homepage** | `https://k8s.seudominio.com.br` | — (pública) | `oci-devops` |
| **Kubernetes Dashboard** | `https://k8s.seudominio.com.br/dashboard` | Token via `terraform output admin_token` | `kubernetes-dashboard` |
| **ChirpStack v3 — UI** | `https://chirpstack-v3.seudominio.com.br` | `admin` / `admin` | `chirpstack-v3` |
| **ChirpStack v3 — API (Swagger)** | `https://chirpstack-v3.seudominio.com.br/api` | JWT via UI → Profile → API Keys | `chirpstack-v3` |
| **ChirpStack v4 — UI** | `https://chirpstack-v4.seudominio.com.br` | `admin` / `admin` | `chirpstack-v4` |
| **ChirpStack v4 — REST API** | `https://chirpstack-v4-rest-api.seudominio.com.br` | Bearer token via UI | `chirpstack-v4` |

> ⚠️ Altere as senhas padrão `admin/admin` do ChirpStack imediatamente após o primeiro acesso.

---

### Serviços de rede — acesso direto via IP/porta

| Serviço | Endereço | Protocolo | Observação |
|---|---|---|---|
| **SSH — leader** | `<IP_NLB>:22` | TCP | Acesso direto ao Control Plane |
| **kubectl / API Server** | `<IP_NLB>:6443` | TCP | Requer kubeconfig configurado |
| **Ingress HTTP** | `<IP_NLB>:80` | TCP | Redireciona para HTTPS |
| **Ingress HTTPS** | `<IP_NLB>:443` | TCP | Todos os serviços web |
| **MQTT v3 — Broker** | `<IP_NLB>:1888` | TCP | Sem TLS — `allow_anonymous true` |
| **MQTT v4 — Broker (TLS)** | `<IP_NLB>:8883` | TCP/TLS | Com certificado CA própria |
| **Gateway Bridge v3 — UDP** | `<IP_NLB>:1700` | UDP | Packet Forwarder dos gateways |
| **Gateway Bridge v4 — UDP** | `<IP_NLB>:1710` | UDP | Packet Forwarder dos gateways |
| **UDP Health Check** | `<IP_NLB>:1700` e `:1710` | UDP | PING → PONG (NLB health check) |

---

### Serviços internos ao cluster — acesso via kubectl

Estes serviços não são expostos externamente mas podem ser acessados via `kubectl port-forward` para debug:

| Serviço | Namespace | Porta interna | Comando port-forward |
|---|---|---|---|
| **PostgreSQL NS (v3)** | `chirpstack-v3` | `5437` | `kubectl port-forward svc/chirpstack-v3-ns-postgresql-service 5437:5437 -n chirpstack-v3` |
| **PostgreSQL AS (v3)** | `chirpstack-v3` | `5438` | `kubectl port-forward svc/chirpstack-v3-as-postgresql-service 5438:5438 -n chirpstack-v3` |
| **Redis (v3)** | `chirpstack-v3` | `6384` | `kubectl port-forward svc/chirpstack-v3-redis-service 6384:6384 -n chirpstack-v3` |
| **Network Server gRPC (v3)** | `chirpstack-v3` | `8000` | `kubectl port-forward svc/chirpstack-v3-network-server-service 8000:8000 -n chirpstack-v3` |
| **Application Server gRPC (v3)** | `chirpstack-v3` | `8001` | `kubectl port-forward svc/chirpstack-v3-application-server-service 8001:8001 -n chirpstack-v3` |
| **PostgreSQL (v4)** | `chirpstack-v4` | `5442` | `kubectl port-forward svc/chirpstack-v4-postgresql-service 5442:5442 -n chirpstack-v4` |
| **Redis (v4)** | `chirpstack-v4` | `6389` | `kubectl port-forward svc/chirpstack-v4-redis-service 6389:6389 -n chirpstack-v4` |
| **Mosquitto MQTT TLS (v4)** | `chirpstack-v4` | `8883` | `kubectl port-forward svc/chirpstack-v4-mosquitto-service 8883:8883 -n chirpstack-v4` |
| **ChirpStack v4 — gRPC** | `chirpstack-v4` | `8080` | `kubectl port-forward svc/chirpstack-v4-service 8080:8080 -n chirpstack-v4` |
| **ChirpStack v4 — REST API** | `chirpstack-v4` | `8090` | `kubectl port-forward svc/chirpstack-v4-rest-api-service 8090:8090 -n chirpstack-v4` |
| **Metrics Server** | `kube-system` | `443` | `kubectl port-forward svc/metrics-server 4443:443 -n kube-system` |

#### Testando o MQTT com TLS via port-forward

O port-forward do Mosquitto v4 é especialmente útil para testar a conectividade TLS e a autenticação **a partir da sua máquina local**, sem depender do NLB ou de DNS público. O tráfego é tunelado via `kubectl` diretamente ao pod do Mosquitto dentro do cluster.

**Passo 1 — Abrir o tunnel (Terminal 1, deixar rodando):**

```bash
kubectl port-forward svc/chirpstack-v4-mosquitto-service 8883:8883 -n chirpstack-v4
# Saída esperada: Forwarding from 127.0.0.1:8883 -> 8883
```

**Passo 2 — Testar o handshake TLS (Terminal 2):**

```bash
# Verificar o certificado servido pelo Mosquitto via port-forward
echo | openssl s_client \
  -connect localhost:8883 \
  -CAfile ~/chirpstack/mqtt-certs/ca.crt \
  -servername chirpstack-v4-mosquitto-service.chirpstack-v4.svc.cluster.local \
  2>/dev/null \
| openssl x509 -noout -subject -issuer -ext subjectAltName
```

> O `-servername` deve ser um dos DNS presentes nos SANs do certificado. Embora a conexão seja feita em `localhost` via port-forward, o TLS valida o certificado pelo nome indicado em `-servername`.

**Resultado esperado:**
```
subject=CN=chirpstack-v4.seudominio.com.br
issuer=CN=chirpstack-internal-mqtt-ca
X509v3 Subject Alternative Name:
    DNS:chirpstack-v4.seudominio.com.br,
    DNS:chirpstack-v4-mosquitto-service,
    DNS:chirpstack-v4-mosquitto-service.chirpstack-v4,
    DNS:chirpstack-v4-mosquitto-service.chirpstack-v4.svc,
    DNS:chirpstack-v4-mosquitto-service.chirpstack-v4.svc.cluster.local
```

**Passo 3 — Testar autenticação e subscribe via port-forward:**

```bash
# Subscribe em tópico de eventos de gateways via localhost (requer mosquitto-clients instalado)
mosquitto_sub \
  -h localhost \
  -p 8883 \
  --cafile ~/chirpstack/mqtt-certs/ca.crt \
  --insecure \
  -u "adailsilva" -P "H@cker101" \
  -t "au915_1/gateway/+/event/#" \
  -v -d
```

> A flag `--insecure` é necessária aqui porque a conexão é feita em `localhost`, que não está nos SANs do certificado. Ela desabilita apenas a validação do hostname, mantendo a criptografia TLS ativa. **Use `--insecure` somente em testes locais via port-forward** — nunca em produção ou ao conectar pelo endereço real do cluster.

**Resultado esperado:**
```
Client mosq-xxxx sending CONNECT
Client mosq-xxxx received CONNACK (0)          ← 0 = conexão aceita
Client mosq-xxxx sending SUBSCRIBE             ← autenticação OK
Client mosq-xxxx received SUBACK               ← inscrito no tópico
```

**Passo 4 — Testar publish (opcional):**

```bash
# Publicar uma mensagem de teste no tópico
mosquitto_pub \
  -h localhost \
  -p 8883 \
  --cafile ~/chirpstack/mqtt-certs/ca.crt \
  --insecure \
  -u "adailsilva" -P "H@cker101" \
  -t "test/port-forward" \
  -m "ping-via-port-forward" \
  -d
```

**Instalar o mosquitto-clients localmente (se necessário):**

```bash
# Ubuntu / Debian
sudo apt install -y mosquitto-clients

# macOS
brew install mosquitto
```

---

### Configuração dos gateways LoRaWAN físicos — Packet Forwarder

Para apontar um gateway físico ao cluster, configure o **Semtech UDP Packet Forwarder** (`global_conf.json` ou equivalente) com o IP do NLB e a porta correta para cada versão:

**ChirpStack v3 — porta UDP 1700:**
```json
{
  "gateway_conf": {
    "server_address": "<IP_NLB>",
    "serv_port_up": 1700,
    "serv_port_down": 1700
  }
}
```

**ChirpStack v4 — porta UDP 1710:**
```json
{
  "gateway_conf": {
    "server_address": "<IP_NLB>",
    "serv_port_up": 1710,
    "serv_port_down": 1710
  }
}
```

> O Gateway Bridge do v4 usa a porta externa `1710` (redirecionada para `1700` internamente no container), permitindo que v3 e v4 coexistam no mesmo cluster sem conflito de porta UDP no NLB.

---

## Configuração dos Gateways no ChirpStack

Após o cluster estar operacional e os serviços do ChirpStack implantados, é necessário realizar o cadastro dos gateways, perfis de dispositivo e demais configurações dentro da interface do ChirpStack. Esta seção documenta a configuração completa para o ambiente com **6 gateways** físicos operando na região **AU915**, sub-banda 1 (canais 8–15 + 65).

---

### ChirpStack v3 — Configuração completa

#### Network Server

Acesse **Network Servers → Add** e configure:

| Campo | Valor |
|---|---|
| **Nome** | `ChirpStack-v3_NS` |
| **Servidor** | `chirpstack-v3-network-server-service.chirpstack-v3.svc.cluster.local:8000` |

> O endereço interno do Kubernetes é usado pois o Application Server acessa o Network Server via Service DNS interno do cluster, sem passar pelo NLB.

#### Gateway Discovery

Ainda nas configurações do Network Server, habilite o Gateway Discovery:

| Campo | Valor |
|---|---|
| **Habilitar** | ✅ Sim |
| **Intervalo (por dia)** | `24` |
| **Frequência TX (Hz)** | `916800000` |
| **Data-rate TX** | `5` |

---

#### Gateway Profiles

Acesse **Gateway Profiles → Create** e cadastre os dois perfis:

**Perfil para Sub-banda 0 (canais 0–7 + 64):**

| Campo | Valor |
|---|---|
| **Nome** | `ChirpStack-v3_GP_AU915_0` |
| **Stats interval (segundos)** | `30` |
| **Canais habilitados** | `0, 1, 2, 3, 4, 5, 6, 7, 64` |
| **Network Server** | `ChirpStack-v3_NS` |

**Perfil para Sub-banda 1 (canais 8–15 + 65):**

| Campo | Valor |
|---|---|
| **Nome** | `ChirpStack-v3_GP_AU915_1` |
| **Stats interval (segundos)** | `30` |
| **Canais habilitados** | `8, 9, 10, 11, 12, 13, 14, 15, 65` |
| **Network Server** | `ChirpStack-v3_NS` |

> Os gateways deste ambiente operam na **sub-banda 1 (AU915_1)**. O perfil AU915_0 é cadastrado para uso futuro com gateways de sub-banda diferente.

---

#### Organization

Acesse **Organizations → Add**:

| Campo | Valor |
|---|---|
| **Nome** | `chirpstack` |
| **Display Name** | `ChirpStack` |
| **Pode ter gateways** | ✅ Sim |

---

#### Service Profile

Acesse **Service Profiles → Create**:

| Campo | Valor |
|---|---|
| **Nome** | `ChirpStack-v3_SP` |
| **Network Server** | `ChirpStack-v3_NS` |
| **Add gateway meta-data** | ✅ Sim |
| **Enable network geolocation** | ✅ Sim |
| **Report device battery level** | ✅ Sim |
| **Report device link margin** | ✅ Sim |
| **Min data-rate** | `0` |
| **Max data-rate** | `5` |
| **Private gateways** | ☐ Não |

---

#### Device Profiles

Acesse **Device Profiles → Create**. Cadastre os quatro perfis abaixo — dois por sub-banda, dois por revisão de parâmetros regionais (A e B):

| Nome | Sub-banda | MAC Version | Revisão | OTAA | Class-B | Class-C | Timeout C | Codec |
|---|---|---|---|---|---|---|---|---|
| `Device Profile - AU915_0 - 1.0.3 - A` | AU915_0 | 1.0.3 | A | ✅ | ☐ | ✅ | 5s | JavaScript |
| `Device Profile - AU915_1 - 1.0.3 - A` | AU915_1 | 1.0.3 | A | ✅ | ☐ | ✅ | 5s | JavaScript |
| `Device Profile - AU915_0 - 1.0.3 - B` | AU915_0 | 1.0.3 | B | ✅ | ☐ | ✅ | 5s | JavaScript |
| `Device Profile - AU915_1 - 1.0.3 - B` | AU915_1 | 1.0.3 | B | ✅ | ☐ | ✅ | 5s | JavaScript |

Configurações comuns a todos os perfis:

| Campo | Valor |
|---|---|
| **Network Server** | `ChirpStack-v3_NS` |
| **ADR Algorithm** | `Default ADR algorithm (LoRa only)` |
| **Max EIRP** | `30` |
| **Uplink interval (segundos)** | `60` |

---

#### Gateways

Acesse **Gateways → Create** e cadastre cada gateway. O **Gateway ID (EUI)** deve ser obtido da etiqueta física do equipamento ou do arquivo de configuração do Packet Forwarder (`local_conf.json`):

| # | Nome | Descrição | Modelo | Canais | Network Server | Service Profile | Gateway Profile |
|---|---|---|---|---|---|---|---|
| 001 | `001-gtw-rak831-001` | RAK831 RPi3 com GPS | Multi-canal | AU915_1 | `ChirpStack-v3_NS` | `ChirpStack-v3_SP` | `ChirpStack-v3_GP_AU915_1` |
| 002 | `002-gtw-radioenge-001` | Radioenge RPi3-RD43HATGPS | Multi-canal | AU915_1 | `ChirpStack-v3_NS` | `ChirpStack-v3_SP` | `ChirpStack-v3_GP_AU915_1` |
| 003 | `003-gtw-radioenge-002` | Radioenge RPi3-RD43HATGPS | Multi-canal | AU915_1 | `ChirpStack-v3_NS` | `ChirpStack-v3_SP` | `ChirpStack-v3_GP_AU915_1` |
| 004 | `004-gtw-radioenge-003` | Radioenge RPi3-RD43HATGPS | Multi-canal | AU915_1 | `ChirpStack-v3_NS` | `ChirpStack-v3_SP` | `ChirpStack-v3_GP_AU915_1` |
| 005 | `005-gtw-elecrow-001` | Elecrow RPi4 com GPS | Multi-canal | AU915_1 | `ChirpStack-v3_NS` | `ChirpStack-v3_SP` | `ChirpStack-v3_GP_AU915_1` |
| 006 | `006-gtw-dragino_lg02-001` | Dragino LG02 | Dual-canal | AU915_1 | `ChirpStack-v3_NS` | `ChirpStack-v3_SP` | `ChirpStack-v3_GP_AU915_1` |

Para todos os gateways, habilite também:

| Campo | Valor |
|---|---|
| **Gateway Discovery habilitado** | ✅ Sim |

> O Gateway EUI de cada dispositivo é único e identificado na etiqueta física do hardware ou no arquivo `local_conf.json` do Packet Forwarder (campo `gateway_ID`). Nunca compartilhe publicamente os EUIs dos seus gateways.

---

### ChirpStack v4 — Configuração completa

O v4 possui uma estrutura simplificada em relação ao v3: não existe mais a separação entre Network Server e Application Server, e muitos conceitos foram reorganizados. Gateways são cadastrados diretamente no painel sem necessidade de vincular a um Network Server separado.

#### Device Profile Templates

Acesse **Device profile templates → Add** e cadastre os dois templates base:

**Template A (Revisão A):**

| Campo | Valor |
|---|---|
| **ID** | `Device_Profile_Template_AU915_1_0_3_A` |
| **Nome** | `Device Profile Template - AU915 - 1.0.3 - A` |
| **Vendor** | `<Sua organização>` |
| **Firmware version** | `1.0` |
| **Descrição** | `Device Profile Template Region AU915 - MAC version LoRaWAN 1.0.3 - Regional parameters revision A` |
| **Supports Class-C** | ✅ Sim — timeout `5s` |
| **Payload codec** | `JavaScript functions` |

**Template B (Revisão B):**

| Campo | Valor |
|---|---|
| **ID** | `Device_Profile_Template_AU915_1_0_3_B` |
| **Nome** | `Device Profile Template - AU915 - 1.0.3 - B` |
| **Vendor** | `<Sua organização>` |
| **Firmware version** | `1.0` |
| **Descrição** | `Device Profile Template Region AU915 - MAC version LoRaWAN 1.0.3 - Regional parameters revision B` |
| **Supports Class-C** | ✅ Sim — timeout `5s` |
| **Payload codec** | `JavaScript functions` |

---

#### Device Profiles

Acesse **Device profiles → Add** e cadastre os quatro perfis. Todos compartilham as mesmas configurações de Class, OTAA e codec — diferindo apenas na sub-banda e revisão de parâmetros regionais:

| Nome | Sub-banda | Revisão | OTAA | Class-B | Class-C | Timeout C | Codec |
|---|---|---|---|---|---|---|---|
| `Device Profile - AU915_0 - 1.0.3 - A` | AU915_0 | A | ✅ Sim | ☐ Não | ✅ Sim | 5s | JavaScript |
| `Device Profile - AU915_1 - 1.0.3 - A` | AU915_1 | A | ✅ Sim | ☐ Não | ✅ Sim | 5s | JavaScript |
| `Device Profile - AU915_0 - 1.0.3 - B` | AU915_0 | B | ✅ Sim | ☐ Não | ✅ Sim | 5s | JavaScript |
| `Device Profile - AU915_1 - 1.0.3 - B` | AU915_1 | B | ✅ Sim | ☐ Não | ✅ Sim | 5s | JavaScript |

Descrições sugeridas (para facilitar a identificação):

| Perfil | Descrição |
|---|---|
| `AU915_0 - 1.0.3 - A` | `Device Profile Region AU915 - Region configuration 0 - MAC version LoRaWAN 1.0.3 - Regional parameters revision A` |
| `AU915_1 - 1.0.3 - A` | `Device Profile Region AU915 - Region configuration 1 - MAC version LoRaWAN 1.0.3 - Regional parameters revision A` |
| `AU915_0 - 1.0.3 - B` | `Device Profile Region AU915 - Region configuration 0 - MAC version LoRaWAN 1.0.3 - Regional parameters revision B` |
| `AU915_1 - 1.0.3 - B` | `Device Profile Region AU915 - Region configuration 1 - MAC version LoRaWAN 1.0.3 - Regional parameters revision B` |

---

#### Gateways

Acesse **Gateways → Add** e cadastre cada gateway. O Gateway EUI deve ser obtido da etiqueta física do equipamento ou do `local_conf.json` do Packet Forwarder:

| # | Nome | Descrição | Modelo | Canais |
|---|---|---|---|---|
| 001 | `001-gtw-rak831-001` | RAK831 RPi3 com GPS | Multi-canal | AU915_1 |
| 002 | `002-gtw-radioenge-001` | Radioenge RPi3-RD43HATGPS | Multi-canal | AU915_1 |
| 003 | `003-gtw-radioenge-002` | Radioenge RPi3-RD43HATGPS | Multi-canal | AU915_1 |
| 004 | `004-gtw-radioenge-003` | Radioenge RPi3-RD43HATGPS | Multi-canal | AU915_1 |
| 005 | `005-gtw-elecrow-001` | Elecrow RPi4 com GPS | Multi-canal | AU915_1 |
| 006 | `006-gtw-dragino_lg02-001` | Dragino LG02 | Dual-canal | AU915_1 |

> No v4 não há mais vinculação de gateway a Network Server, Service Profile ou Gateway Profile — esses conceitos foram unificados. O gateway simplesmente se conecta ao cluster via UDP e o ChirpStack o reconhece automaticamente pelo EUI quando ele começa a enviar pacotes.

---

### Diferenças no cadastro v3 vs v4

| Etapa | ChirpStack v3 | ChirpStack v4 |
|---|---|---|
| **Network Server** | Cadastro manual obrigatório | Não existe — unificado no servidor |
| **Gateway Profile** | Obrigatório (define canais habilitados) | Não existe — configurado por região no TOML |
| **Service Profile** | Obrigatório (define comportamento de serviço) | Não existe — simplificado |
| **Device Profile Templates** | Não existe | ✅ Disponível como base reutilizável |
| **Vinculação do gateway** | NS + SP + GP obrigatórios | Apenas EUI + Nome |
| **Reconhecimento do gateway** | Após cadastro manual com EUI | Automático ao receber o primeiro pacote |
| **Canais da sub-banda** | Configurado no Gateway Profile | Configurado no `chirpstack.toml` por região |

---

## Acesso ao Cluster

O `kubeconfig` externo é salvo em `.terraform/.kube/config-external`. Se `linux_overwrite_local_kube_config = true`, é copiado automaticamente para `~/.kube/config`.

```bash
# Verificar todos os nós
kubectl get nodes -o wide

# Saída esperada:
# NAME       STATUS   ROLES           AGE   VERSION   OS-IMAGE
# leader     Ready    control-plane   10m   v1.31.x   Ubuntu 24.04 LTS
# worker-0   Ready    worker          8m    v1.31.x   Ubuntu 24.04 LTS
# worker-1   Ready    worker          8m    v1.31.x   Ubuntu 24.04 LTS
# worker-2   Ready    worker          8m    v1.31.x   Ubuntu 24.04 LTS

# Verificar pods de todos os namespaces relevantes
kubectl get pods -n kube-system        # Sistema + Metrics Server
kubectl get pods -n ingress-nginx      # Ingress Controller
kubectl get pods -n cert-manager       # Gerenciador de certificados TLS
kubectl get pods -n oci-devops         # Homepage + UDP Health Check
kubectl get pods -n chirpstack-v3      # ChirpStack v3 (se implantado)
kubectl get pods -n chirpstack-v4      # ChirpStack v4 (se implantado)

# Verificar certificados TLS em todos os namespaces
kubectl get certificate -A

# Verificar Ingress em todos os namespaces
kubectl get ingress -A
```

### Acesso SSH

```bash
# Acesso direto ao leader (porta 22 do Load Balancer)
ssh -i ~/.ssh/id_ed25519 ubuntu@<IP_PUBLICO_RESERVADO>

# Acesso a um worker (via jump através do leader)
ssh -i ~/.ssh/id_ed25519 \
    -J ubuntu@<IP_PUBLICO_RESERVADO> \
    ubuntu@<IP_PRIVADO_WORKER>
```

### Kubernetes Dashboard

Acessível em `https://<cluster_public_dns_name>/dashboard`.

```bash
# Obter o token de acesso
terraform output admin_token
```

---

## CI/CD com GitHub Actions

O projeto inclui um workflow de CI/CD em `00.homepage/ci_cd.yaml` que automatiza o build da imagem Docker ARM64 e o deploy da homepage no cluster Kubernetes a cada push na branch `master` com alterações dentro da pasta `app/`. O pipeline também pode ser disparado manualmente via `workflow_dispatch`.

### Gatilhos do pipeline

```yaml
on:
  push:
    branches:
      - master
    paths:
      - app/**        # Só dispara quando há mudanças na pasta app/
  workflow_dispatch:  # Permite execução manual pela interface do GitHub
```

### Etapas do pipeline

| # | Step | Descrição |
|---|---|---|
| 1 | **Checkout** | Clona o repositório no runner |
| 2 | **Set up QEMU** | Habilita emulação ARM64 no runner x86 |
| 3 | **Set up Docker Buildx** | Configura o builder multi-plataforma |
| 4 | **Install OCI CLI** | Instala o OCI CLI e escreve as credenciais a partir dos Secrets |
| 5 | **Install kubectl** | Instala o `kubectl` e configura o kubeconfig do cluster |
| 6 | **Currently running services** | Exibe os pods em `oci-devops` antes do deploy |
| 7 | **Login to Docker registry** | Autentica no OCI Container Registry |
| 8 | **Available platforms** | Lista as plataformas disponíveis no Buildx |
| 9 | **Build** | Faz build e push da imagem para `linux/amd64` e `linux/arm64` |
| 10 | **Deploy to K8S** | Aplica o manifesto `02.homepage-nginx__Deployment.yaml` no cluster |
| 11 | **Restart nginx** | Executa `rollout restart` no Deployment `nginx` em `oci-devops` |

### Secrets do repositório GitHub

Todos os valores abaixo devem ser cadastrados em **Settings → Secrets and variables → Actions → New repository secret** no seu repositório.

| Secret | Valor esperado | Como obter |
|---|---|---|
| `OCI_CONFIG` | Conteúdo completo do arquivo `~/.oci/config` | Gerado automaticamente ao configurar a OCI CLI (`oci setup config`) |
| `OCI_KEY_FILE` | Conteúdo da chave privada OCI (`oci_api_key.pem`) | Arquivo gerado em `~/.oci/oci_api_key.pem` |
| `KUBECONFIG` | Conteúdo do kubeconfig externo do cluster | Gerado pelo Terraform em `.terraform/.kube/config-external` após o `apply` |
| `DOCKER_URL` | URL do OCI Container Registry | Ex: `gru.ocir.io` (varia por região) |
| `DOCKER_USERNAME` | Username de autenticação no OCI Registry | Formato: `<namespace>/<seu_email>` — ex: `griszz3l82u1/adail101@hotmail.com` |
| `DOCKER_PASSWORD` | Auth token do OCI Registry | Gerado em **OCI Console → Identity → Users → Auth Tokens → Generate Token** |
| `DOCKER_OBJECT_STORAGE_NAMESPACE` | Namespace do OCI Object Storage | Encontrado em **OCI Console → Object Storage → Namespace** ou via `oci os ns get` |

### Como obter cada Secret

**`OCI_CONFIG`** — exiba e copie o conteúdo do arquivo de configuração da OCI CLI:
```bash
cat ~/.oci/config
```
O arquivo tem o formato abaixo. O campo `key_file` deve apontar para `/home/runner/.oci/key.pem` (caminho usado pelo runner no GitHub Actions):
```ini
[DEFAULT]
user=ocid1.user.oc1..xxxxxxxxxx
fingerprint=xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx
tenancy=ocid1.tenancy.oc1..xxxxxxxxxx
region=sa-saopaulo-1
key_file=/home/runner/.oci/key.pem
```

**`OCI_KEY_FILE`** — exiba e copie o conteúdo da chave privada:
```bash
cat ~/.oci/oci_api_key.pem
```

**`KUBECONFIG`** — após o `terraform apply`, exiba o kubeconfig externo:
```bash
cat .terraform/.kube/config-external
# ou, se você usou linux_overwrite_local_kube_config = true:
cat ~/.kube/config
```

**`DOCKER_URL`** — URL do OCI Registry de acordo com a região:

| Região OCI | URL do Registry |
|---|---|
| São Paulo (`sa-saopaulo-1`) | `gru.ocir.io` |
| Ashburn (`us-ashburn-1`) | `iad.ocir.io` |
| Phoenix (`us-phoenix-1`) | `phx.ocir.io` |
| Frankfurt (`eu-frankfurt-1`) | `fra.ocir.io` |

**`DOCKER_OBJECT_STORAGE_NAMESPACE`** — obtenha via OCI CLI:
```bash
oci os ns get --query 'data' --raw-output
```

**`DOCKER_PASSWORD` (Auth Token)** — gere no console OCI:
1. Acesse **Identity & Security → Users → (seu usuário)**
2. Clique em **Auth Tokens → Generate Token**
3. Copie o token gerado (ele é exibido apenas uma vez)

### Como o pipeline constrói e implanta a imagem

O step de **Build** usa o Docker Buildx para criar a imagem simultaneamente para `linux/amd64` e `linux/arm64`, fazendo push direto ao OCI Registry:

```bash
docker build --push \
  --platform linux/amd64,linux/arm64 \
  -t gru.ocir.io/<DOCKER_OBJECT_STORAGE_NAMESPACE>/homepage-80_platform_linux-arm64:latest \
  app/.
```

O step de **Deploy** substitui o placeholder `<DOCKER_OBJECT_STORAGE_NAMESPACE>` no manifesto com o valor real antes de aplicar:

```bash
sed -i 's/<DOCKER_OBJECT_STORAGE_NAMESPACE>/${{ secrets.DOCKER_OBJECT_STORAGE_NAMESPACE }}/g' \
  app/02.homepage-nginx__Deployment.yaml

kubectl apply -f app/02.homepage-nginx__Deployment.yaml -n oci-devops
```

Por fim, o **Restart** força o rollout para que os pods sejam recriados com a nova imagem:

```bash
kubectl rollout restart deployment nginx -n oci-devops
```

### Estrutura esperada da pasta `app/`

O workflow monitora mudanças em `app/**` e espera encontrar:

```
app/
├── Dockerfile                          # FROM nginx:latest + index.html
├── index.html                          # Conteúdo da homepage
└── 02.homepage-nginx__Deployment.yaml  # Manifesto com placeholder <DOCKER_OBJECT_STORAGE_NAMESPACE>
```

O manifesto de Deployment deve conter o placeholder que será substituído pelo pipeline:

```yaml
containers:
  - name: nginx
    image: gru.ocir.io/<DOCKER_OBJECT_STORAGE_NAMESPACE>/homepage-80_platform_linux-arm64:latest
```

### Verificar a execução do pipeline

Após um push ou execução manual, acompanhe em **Actions → CI/CD** no GitHub. Para verificar no cluster:

```bash
# Checar o status do rollout
kubectl rollout status deployment/nginx -n oci-devops

# Ver os pods atualizados
kubectl get pods -n oci-devops -o wide

# Ver os eventos recentes
kubectl describe deployment nginx -n oci-devops
```

---

## OCI Container Registry

O módulo `oci-infra_ci_cd` cria repositórios privados no **OCI Container Registry** para armazenar imagens Docker **ARM64** do cluster:

| Repositório | Arquitetura | Aplicação |
|---|---|---|
| `homepage-80_platform_linux-arm64` | ARM64 | Homepage NGINX |
| `udp-health-check-server-1700_platform_linux-arm64` | ARM64 | UDP Health Check porta 1700 |
| `udp-health-check-server-1710_platform_linux-arm64` | ARM64 | UDP Health Check porta 1710 |

Novos repositórios podem ser adicionados em `oci_artifacts_container_repository/oci_artifacts_container_repository.tf`.

---

## Destruindo a Infraestrutura

> ⚠️ As instâncias de compute e o IP reservado possuem `prevent_destroy = true`. Edite os respectivos arquivos `.tf` antes de executar o destroy se quiser remover todos os recursos.

```bash
terraform destroy   # ou: tofu destroy
```

O script `reset.sh` é executado automaticamente em cada nó antes da destruição, realizando uma limpeza ordenada do cluster Kubernetes.

---

## Troubleshooting

### ❌ `Out of capacity for shape VM.Standard.A1.Flex`

A região está sem capacidade ARM disponível.

**Solução:** Mude a variável `region` para `us-ashburn-1` ou `us-phoenix-1` e execute `terraform apply` novamente.

---

### ❌ `NotAuthenticated` — Falha na autenticação OCI

**Solução:** Confirme que o `fingerprint` no `.tfvars` é idêntico ao exibido no console OCI após o upload da API Key. Verifique também o caminho correto da chave privada.

---

### ❌ Nós em estado `NotReady`

O CNI (Flannel) pode não ter inicializado ainda.

```bash
kubectl describe node <nome-do-no>
kubectl get pods -n kube-flannel -o wide

# Ver logs de inicialização na VM
ssh -i ~/.ssh/id_ed25519 ubuntu@<IP_PUBLICO> \
  "sudo tail -100 /var/log/cloud-init-output.log"
```

---

### ❌ Preflight errors no `kubeadm init` (NumCPU / Mem)

Já contornado automaticamente com `--ignore-preflight-errors=NumCPU,Mem` no script `setup-control-plane.sh`.

---

### ❌ Let's Encrypt não emite certificado

A causa mais comum é que o registro DNS do subdomínio ainda não existe ou ainda não propagou. O cert-manager usa o desafio **ACME HTTP-01**, que exige que o subdomínio resolva para o IP do NLB no momento da verificação.

**1. Confirmar que o DNS está propagado e aponta para o IP correto:**

```bash
# Obter o IP do NLB
terraform output -raw cluster_public_ip

# Verificar cada subdomínio — deve retornar o IP do NLB
dig +short k8s.seudominio.com.br
dig +short chirpstack-v3.seudominio.com.br
dig +short chirpstack-v4.seudominio.com.br
dig +short chirpstack-v4-rest-api.seudominio.com.br

# Confirmar propagação via DNS público
dig +short chirpstack-v3.seudominio.com.br @8.8.8.8
dig +short chirpstack-v3.seudominio.com.br @1.1.1.1
```

> Se o DNS não retornar o IP correto, cadastre ou corrija o registro no seu provedor (ex: Registro.br) e aguarde a propagação. Consulte a seção [Configuração de DNS — Subdomínios Obrigatórios](#configuração-de-dns--subdomínios-obrigatórios).

**2. Verificar o status do certificado e do desafio ACME:**

```bash
# Status geral dos certificados em todos os namespaces
kubectl get certificate -A

# Detalhes do certificado — procure por "Message" e "Reason"
kubectl describe certificate -n chirpstack-v3
kubectl describe certificate -n chirpstack-v4

# Detalhes do desafio HTTP-01 — procure pelo campo "Presented" e "Reason"
kubectl describe challenges -A

# Verificar o CertificateRequest
kubectl describe certificaterequest -A
```

**3. Verificar se o Ingress NGINX está roteando o desafio corretamente:**

```bash
# O cert-manager cria um Ingress temporário durante o desafio
kubectl get ingress -A | grep cm-acme

# Os pods do Ingress devem estar Running
kubectl get pods -n ingress-nginx
```

**4. Verificar se o subdomínio está correto no manifesto Ingress:**

```bash
# O host no Ingress deve bater exatamente com o registro DNS
kubectl get ingress -n chirpstack-v3 -o yaml | grep host
kubectl get ingress -n chirpstack-v4 -o yaml | grep host
```

---

### ❌ Pods com `ImagePullBackOff` no namespace `oci-devops`

O Secret de acesso ao OCI Registry pode estar faltando ou incorreto.

```bash
# Verificar se o Secret existe
kubectl get secret oci-registry-secret -n oci-devops

# Recriar o Secret
kubectl delete secret oci-registry-secret -n oci-devops
kubectl create secret docker-registry oci-registry-secret \
  --docker-server=gru.ocir.io \
  --docker-username='<namespace>/<seu_email>' \
  --docker-password='<auth_token>' \
  --docker-email='<seu_email>' \
  -n oci-devops
```

---

### ❌ NLB Overall Health: Critical — portas UDP 1700 ou 1710

O **Overall Health do NLB fica `Critical`** enquanto qualquer listener não tiver backends saudáveis. Para as portas UDP, a causa mais comum é que o `UdpHealthCheckServer` não está rodando ou não está acessível diretamente no IP do nó.

**1. Verificar se os pods estão Running:**

```bash
kubectl get pods -n oci-devops -o wide
kubectl get daemonset -n oci-devops

# Todos os DaemonSets devem ter DESIRED = CURRENT = READY = 3
```

**2. Confirmar que `hostNetwork: true` está ativo:**

```bash
kubectl get pod <nome-do-pod-udp-1700> -n oci-devops -o jsonpath='{.spec.hostNetwork}'
# Saída esperada: true
```

**3. Testar o PING/PONG diretamente nos workers:**

```bash
# Obter os IPs dos workers
kubectl get nodes -o wide | grep worker

# Testar porta 1700
echo "PING" | nc -u -w2 <IP_DO_WORKER> 1700
# Resposta esperada: PONG

# Testar porta 1710
echo "PING" | nc -u -w2 <IP_DO_WORKER> 1710
# Resposta esperada: PONG
```

**4. Verificar as Security Lists da subnet no console OCI:**

As portas UDP 1700 e 1710 precisam estar liberadas nas **Ingress Rules** da Security List da subnet pública:

- Protocolo: `UDP`
- Porta de destino: `1700` e `1710`
- Origem: `0.0.0.0/0` (ou o CIDR do NLB)

**5. Verificar os logs do pod:**

```bash
kubectl logs -l app=udp-1700 -n oci-devops --tail=50
# Log esperado: "UDP Health Check Server listening on port 1700..."
```

**6. Reimplantar se necessário:**

```bash
kubectl rollout restart deployment udp-app-with-healthcheck-1700-deployment -n oci-devops
kubectl rollout restart deployment udp-app-with-healthcheck-1710-deployment -n oci-devops
```

**7. Confirmar a recuperação no console OCI:**

Após corrigir o problema, aguarde 1 a 2 minutos e acesse **Networking → Load Balancers → Network Load Balancers → (seu NLB) → Overall Health**. O status deve mudar de `Critical` para `OK`.

---

### ❌ Timeout de SSH durante o `terraform apply`

O Load Balancer pode levar alguns minutos para propagar os listeners. O Terraform aguarda automaticamente (timeout de 5 minutos). Se persistir, re-execute `terraform apply` — o processo é idempotente.

---

## Contribuindo

Contribuições são bem-vindas! Para contribuir:

1. Faça um **fork** do repositório
2. Crie uma branch: `git checkout -b feat/minha-melhoria`
3. Faça commits claros seguindo [Conventional Commits](https://www.conventionalcommits.org/pt-br/)
4. Faça push: `git push origin feat/minha-melhoria`
5. Abra um **Pull Request** descrevendo a mudança e a motivação

---

## Licença

Este projeto está licenciado sob a **MIT License**. Veja o arquivo [LICENSE](LICENSE) para os termos completos.

---

<div align="center">

**☸️ Kubernetes · 🦾 ARM · ☁️ Oracle Cloud · 🆓 Always Free**

Feito para a comunidade brasileira de Cloud e DevOps.

</div>
