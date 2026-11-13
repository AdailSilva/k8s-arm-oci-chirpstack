# GitOps ChirpStack (ArgoCD) — monorepo

O ArgoCD gerencia **somente os 5 Deployments** deste repositório. A versão em execução de cada um é o `newTag` da respectiva `<app>/kubernetes/kustomization.yaml`. Voltar versão = trocar o `newTag` e fazer commit (ver [ROLLBACK.md](ROLLBACK.md)).

Mesmo desenho do CSLab (repositório de referência): o cluster é **compartilhado** pelos 5 repositórios, mas cada um tem o seu app-of-apps e só as suas Applications (prefixo `chirpstack-`).

## Layout (dentro do próprio monorepo)

| Caminho | Conteúdo |
|---|---|
| `gitops/apps/app-of-apps.yaml` | Application `chirpstack-app-of-apps`, que cria as outras 5 |
| `gitops/apps/*.yaml` | `chirpstack-site-frontend`, `chirpstack-consumer-backend`, `chirpstack-consumer-frontend`, `chirpstack-manager-backend`, `chirpstack-manager-frontend` |
| `00.homepage/app_chirpstack_site_frontend/kubernetes/kustomization.yaml` | Site institucional (namespace `chirpstack-site`) |
| `05.chirpstack_consumer/api_chirpstack_consumer_backend/kubernetes/kustomization.yaml` | Consumer — API (namespace `chirpstack-consumer`) |
| `05.chirpstack_consumer/app_chirpstack_consumer_frontend/kubernetes/kustomization.yaml` | Consumer — frontend (namespace `chirpstack-consumer`) |
| `06.chirpstack_manager/api_chirpstack_manager_backend/kubernetes/kustomization.yaml` | Manager — API (namespace `chirpstack-manager`) |
| `06.chirpstack_manager/app_chirpstack_manager_frontend/kubernetes/kustomization.yaml` | Manager — frontend (namespace `chirpstack-manager`) |
| `gitops/bootstrap/` | Instalação do ArgoCD (uma vez por cluster) e credencial deste repositório |

Cada `kustomization.yaml` referencia **só o Deployment** daquele app. No Manager, o PostgreSQL (StatefulSet + PVC), o volume de backups e o Secret ficam de fora de propósito: o ArgoCD nunca recria o banco. Os ChirpStack v3/v4 (`03.`/`04.`) são infraestrutura aplicada pelos scripts e não passam pelo ArgoCD. Namespace, Secrets, ConfigMap, Service e Ingress ficam de fora (o pipeline aplica). Todas as Applications seguem `targetRevision: master`, com `automated: { prune: false, selfHeal: true }`, `ApplyOutOfSyncOnly=true`, `CreateNamespace=true` e `revisionHistoryLimit: 20`.

## Colocar de pé

1. Confira a URL `https://github.com/AdailSilva/k8s-arm-oci-chirpstack.git` nos arquivos de `gitops/apps/` e no Secret do repositório (bootstrap).
2. Rode o pipeline ao menos uma vez por app (`./force_deploy.sh` ou `workflow_dispatch` com `target=ambos`): ele publica a imagem `X.Y` e grava o `newTag`.
3. ArgoCD e credencial do repositório: [bootstrap/00-argocd-install.md](bootstrap/00-argocd-install.md).
4. `kubectl apply -f gitops/apps/app-of-apps.yaml`

## O que o `main.yml` faz

- Build com `--provenance=false --sbom=false`, tags `X.Y` e `latest` (tag Git `<componente>-X.Y`).
- Garante o repositório no OCIR (cria se faltar; depois importe no Terraform com `oci_artifacts_container_repository/import_existing_repositories.sh`).
- Aplica a infraestrutura base (Namespace, Service, Ingress e, quando houver, ConfigMap/PostgreSQL/PVC) e o `oci-registry-secret`.
- Em vez de `kubectl apply`/`rollout restart` do Deployment, o passo **"Fixar versão no GitOps"** troca o `newTag` num worktree criado a partir de `origin/master`, comita `deploy: <componente> <versão> [skip ci]` e faz push (até 5 tentativas, espera aleatória). O ArgoCD sincroniza.
- Congelar um app: acrescente na `kustomization.yaml` a linha `# chirpstack-release-congelado: <motivo>` — a imagem é publicada, mas o `newTag` não muda.
- `concurrency` com `cancel-in-progress: false`: duas execuções não disputam o mesmo push. Cada deploy avança o `origin/master`; faça `git pull --rebase` antes do próximo push (o `force_deploy.sh` já faz).
