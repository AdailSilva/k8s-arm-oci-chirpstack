# ArgoCD — instalação (uma vez por cluster) e ligação deste repositório

Os 5 repositórios (Standart, ChirpStack, CSLab, 3T Sensors e ASE Soluções) rodam **no mesmo cluster**.
O ArgoCD é instalado **uma única vez** (passos 1 e 2, por qualquer um dos repositórios). Cada
repositório só acrescenta a **sua** credencial (passo 3) e o **seu** app-of-apps (passo 4), que cria
apenas as Applications dele — os nomes têm o prefixo do projeto (`chirpstack-*`) e não colidem com os
dos outros repositórios.

## 1. Instalar (só se o namespace `argocd` ainda não existir)

```bash
kubectl get namespace argocd || {
  kubectl create namespace argocd
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
}
```

## 2. Senha inicial (admin)

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

Troque a senha no primeiro acesso.

## 3. Credencial do repositório PRIVADO (obrigatório, uma por repositório)

O ArgoCD precisa ler o monorepo `k8s-arm-oci-chirpstack` (privado). Crie o Secret com um Personal Access Token do GitHub — de preferência um **fine-grained só de leitura**: *Resource owner* `AdailSilva`, *Only select repositories* → `k8s-arm-oci-chirpstack`, *Contents: Read-only*. O `GH_PAT` do pipeline também funciona, mas dá ao ArgoCD escrita em todos os repositórios.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: repo-chirpstack-monorepo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: https://github.com/AdailSilva/k8s-arm-oci-chirpstack.git     # mesma URL usada nas Applications
  username: AdailSilva
  password: <SEU_GH_PAT>
```

```bash
kubectl apply -f esse-secret.yaml   # não versione este arquivo
```

## 4. Ligar este repositório (App-of-Apps)

```bash
kubectl apply -f gitops/apps/app-of-apps.yaml
kubectl -n argocd get applications | grep '^chirpstack-'
# chirpstack-app-of-apps, chirpstack-site-frontend, chirpstack-consumer-backend, chirpstack-consumer-frontend, chirpstack-manager-backend, chirpstack-manager-frontend
```

> Aplique **depois** do primeiro deploy de cada app pelo pipeline: as `kustomization.yaml` nascem com `newTag: "latest"` (ou com a última versão publicada), que o pipeline troca pela versão `X.Y`. Se aplicar antes, os pods podem ficar em `ImagePullBackOff` ou `Pending` (Secrets/PVC ainda inexistentes) até o primeiro build.

## 5. UI

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443   # → https://localhost:8080
```

Ou crie um Ingress para `argocd.<seu-domínio>` → Service `argocd-server` (443), com a anotação `nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"` (e o registro DNS correspondente).

## 6. Economia (opcional, cluster apertado)

```bash
kubectl -n argocd scale deploy argocd-dex-server --replicas=0
kubectl -n argocd scale deploy argocd-notifications-controller --replicas=0
```

## 7. Sem tela de Releases

No CSLab existe um `02-argocd-conta-backoffice.md` com a conta `cslab-backoffice` usada pela tela de Releases do BackOffice. Este repositório não tem BackOffice: as versões são trocadas pelo pipeline ou por commit no `newTag` ([../ROLLBACK.md](../ROLLBACK.md)), sem conta adicional no ArgoCD.
