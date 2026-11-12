# Homepage — chirpstack.adailsilva.com.br

Site de apresentação deste repositório (**AdailSilva/k8s-arm-oci-chirpstack**): ChirpStack **v3** e **v4** em Kubernetes ARM64 na Oracle Cloud usando somente recursos **Always Free**. Os textos, versões, portas e hosts do site seguem o `README.md` da raiz do repositório.

| Item | Valor |
|---|---|
| Stack | Angular 21 · PrimeNG 21 · template Avalon 21 (standalone components) · Tailwind 4 |
| Servidor | nginx (`nginx:alpine`) servindo o build estático |
| URL | `https://chirpstack.adailsilva.com.br` |
| Namespace | `chirpstack-homepage` |
| Imagem | `gru.ocir.io/<namespace>/app-chirpstack-homepage-frontend_platform_linux-arm64:<versão>` |

## Páginas

| Rota | Conteúdo | Componente |
|---|---|---|
| `/` | Início: arquitetura, comparativo v3 × v4, mapa de serviços, AU915 e classes, MQTT, aplicações, FAQ | `src/app/pages/home/` |
| `/v3` | ChirpStack v3: componentes, acesso, ordem de implantação e recursos do namespace `chirpstack-v3` | `src/app/pages/versao/` |
| `/v4` | ChirpStack v4: idem para o namespace `chirpstack-v4` | `src/app/pages/versao/` |
| `/infraestrutura` | Cluster: nós, NLB, componentes, módulos Terraform/OpenTofu e CI/CD | `src/app/pages/infraestrutura/` |

Qualquer outra rota redireciona para `/`.

## Onde editar o conteúdo

Os componentes só leem dados; os textos ficam em `src/app/core/site.config.ts`:

| Constante | Conteúdo | Seção do README da raiz |
|---|---|---|
| `VERSOES` | Componentes, imagens, portas, acessos, passos e recursos de cada versão | 03. ChirpStack v3 / 04. ChirpStack v4 |
| `COMPARATIVO` | Tabela v3 × v4 | Comparativo v3 vs v4 |
| `SERVICOS_WEB`, `SERVICOS_REDE` | Hosts HTTPS e portas do NLB | Mapa de Serviços e Links de Acesso |
| `SUB_BANDAS`, `CLASSES` | Plano AU915 e classes A/B/C | Plano de canais AU915 / Classes de dispositivos |
| `TOPICOS_MQTT`, `EXEMPLO_DOWNLINK_*` | Tópicos e exemplos `mosquitto_pub`/`mosquitto_sub` | Envio de Downlinks via MQTT |
| `CLUSTER` | Nós, portas do NLB, componentes, módulos e etapas do pipeline | Arquitetura / Recursos Always Free / CI/CD |
| `CONTATOS`, `REPOSITORIO` | Canais de contato e link do repositório | — |

Ao mudar uma versão, porta ou host no README da raiz, atualize também esta constante.

## Rodar localmente

```bash
npm ci
npm start                    # perfil development → http://localhost:4411
npm run start:staging        # http://localhost:4412
npm run start:production     # http://localhost:4413
```

## Build

```bash
npm run build:production     # saída em dist/app-chirpstack-homepage-frontend/browser
npm run format               # Prettier
```

Imagem Docker (a mesma que o pipeline gera), a partir desta pasta:

```bash
docker buildx build --platform linux/arm64 -t chirpstack-homepage:local --load .
docker run --rm -p 8080:80 chirpstack-homepage:local      # http://localhost:8080
```

O `Dockerfile` é multi-stage (`node:22-alpine` → `nginx:alpine`) e roda `npm run build:production`. O `nginx.conf` faz o fallback da SPA (`try_files ... /index.html`), expõe `/healthz`, define cache longo para os assets e cabeçalhos de segurança.

## Deploy

Automático pelo job `app_chirpstack_homepage_frontend` do `.github/workflows/main.yml` a cada push que altere esta pasta (ou `workflow_dispatch` com `target=app_chirpstack_homepage_frontend`). Para forçar um deploy sem mudar código: `./force_deploy.sh homepage` na raiz do repositório.

1. Tag Git `app-chirpstack-homepage-frontend-X.Y` e build ARM64 → OCIR (`X.Y` e `latest`). O repositório do OCIR é criado no compartimento na primeira execução, se ainda não existir.
2. Aplica `kubernetes/01` (Namespace), `03` (Service) e `04` (Ingress) e o `oci-registry-secret`.
3. Grava a versão no `kubernetes/kustomization.yaml` **só no runner** (sem commit) e roda `kubectl apply -k`; espera o rollout e confere a imagem em execução.

**Antes do primeiro deploy:** crie o registro DNS `A` de `chirpstack.adailsilva.com.br` apontando para o IP do NLB — sem ele o cert-manager não emite o certificado.

```bash
kubectl get pods,svc,ingress -n chirpstack-homepage
kubectl get certificate -n chirpstack-homepage
```
