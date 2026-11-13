# Rollback

## A) Git (recomendado)

Edite o `newTag` em `<app>/kubernetes/kustomization.yaml`, faça `git commit -m "rollback: <componente> X.Y [skip ci]"` e push. O ArgoCD sincroniza.

```bash
# Versões disponíveis de um componente (tags Git)
git fetch --tags
git tag --list 'app-chirpstack-site-frontend-*' | sort -V | tail -10
git tag --list 'api-chirpstack-consumer-backend-*' | sort -V | tail -10
git tag --list 'app-chirpstack-consumer-frontend-*' | sort -V | tail -10
git tag --list 'api-chirpstack-manager-backend-*' | sort -V | tail -10
git tag --list 'app-chirpstack-manager-frontend-*' | sort -V | tail -10
```

| Componente | `kustomization.yaml` | Application |
|---|---|---|
| `app-chirpstack-site-frontend` | `00.homepage/app_chirpstack_site_frontend/kubernetes/` | `chirpstack-site-frontend` |
| `api-chirpstack-consumer-backend` | `05.chirpstack_consumer/api_chirpstack_consumer_backend/kubernetes/` | `chirpstack-consumer-backend` |
| `app-chirpstack-consumer-frontend` | `05.chirpstack_consumer/app_chirpstack_consumer_frontend/kubernetes/` | `chirpstack-consumer-frontend` |
| `api-chirpstack-manager-backend` | `06.chirpstack_manager/api_chirpstack_manager_backend/kubernetes/` | `chirpstack-manager-backend` |
| `app-chirpstack-manager-frontend` | `06.chirpstack_manager/app_chirpstack_manager_frontend/kubernetes/` | `chirpstack-manager-frontend` |

O **próximo build** daquele componente volta a gravar o `newTag` da versão nova — para manter o rollback, congele o app (`# chirpstack-release-congelado: <motivo>` na `kustomization.yaml`) ou não faça push de código do componente até corrigir.

## B) UI do ArgoCD — evite

**History and Rollback** existe (20 pontos de histórico), mas com `automated` + `selfHeal` o ArgoCD volta ao que está no Git logo em seguida. Use A.

## C) Emergência (sem ArgoCD)

```bash
kubectl set image deployment/<deployment> <container>=gru.ocir.io/<namespace>/<repositório>:X.Y -n <namespace>
```

O `selfHeal` tende a reverter para o Git; para um hotfix que precisa ficar, use A.

## Pré-requisito

As versões precisam existir no OCI Registry: não apague as tags `X.Y` antigas (mantenha pelo menos as ~10 últimas de cada repositório).
