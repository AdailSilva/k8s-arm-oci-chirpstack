# Site ChirpStack — chirpstack.adailsilva.com.br

Site de apresentação deste repositório (**AdailSilva/k8s-arm-oci-chirpstack**): ChirpStack **v3** e **v4** em Kubernetes ARM64 na Oracle Cloud usando somente recursos **Always Free**. Os textos, versões, portas e hosts do site seguem o `README.md` da raiz do repositório.

| Item | Valor |
|---|---|
| Stack | Angular 21 · PrimeNG 21 · template Avalon 21 (standalone components) · Tailwind 4 |
| Servidor | nginx (`nginx:alpine`) servindo o build estático |
| URL | `https://chirpstack.adailsilva.com.br` |
| Namespace | `chirpstack-site` |
| Imagem | `gru.ocir.io/<namespace>/app-chirpstack-site-frontend_platform_linux-arm64:<versão>` |

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
npm run build:production     # saída em dist/app-chirpstack-site-frontend/browser
npm run format               # Prettier
```

Imagem Docker (a mesma que o pipeline gera), a partir desta pasta:

```bash
docker buildx build --platform linux/arm64 -t chirpstack-site:local --load .
docker run --rm -p 8080:80 chirpstack-site:local      # http://localhost:8080
```

O `Dockerfile` é multi-stage (`node:22-alpine` → `nginx:alpine`) e roda `npm run build:production`. O `nginx.conf` faz o fallback da SPA (`try_files ... /index.html`), expõe `/healthz`, define cache longo para os assets e cabeçalhos de segurança.

## Deploy

Automático pelo job `app_chirpstack_site_frontend` do `.github/workflows/main.yml` a cada push nesta pasta (ou `workflow_dispatch` com `target=app-chirpstack-site-frontend`, ou `./force_deploy.sh site` na raiz do repositório) — mesmo job dos outros 4 repositórios:

1. Tag Git `app-chirpstack-site-frontend-X.Y`.
2. Garante o repositório OCIR `app-chirpstack-site-frontend_platform_linux-arm64` (cria se ainda não existir; depois rode `oci_artifacts_container_repository/import_existing_repositories.sh` antes do próximo `terraform apply`).
3. Build ARM64 → OCIR (`X.Y` e `latest`).
4. Aplica `kubernetes/01` (Namespace `chirpstack-site`), `03` (Service), `06` (Ingress) e o `oci-registry-secret`.
5. Troca o `newTag` em `kubernetes/kustomization.yaml` (commit `[skip ci]`); o ArgoCD (Application `chirpstack-site-frontend`) aplica o `02` (Deployment).

Os manifestos `04` (cert-manager) e `05` (ClusterIssuer) são cópias de referência — o scaffold do Terraform já instala ambos. Rollback e congelamento de versão: [`gitops/ROLLBACK.md`](../../gitops/ROLLBACK.md).

```bash
kubectl get pods,svc,ingress -n chirpstack-site
kubectl get certificate -n chirpstack-site
kubectl -n argocd get application chirpstack-site-frontend
```
