# Local Kubernetes Runbook

This runbook describes the local-first deployment path for Redacta. The local deployment must be validated before the same Kubernetes and Helm model is promoted to cloud.

## Scope

The local Kubernetes environment runs the same application routing model planned for cloud:

- Browser traffic reaches one public entrypoint, for example `localhost:8080` in the included kind setup or `redacta.local:8080` if a hosts entry is used.
- Traefik receives the public HTTP request.
- Traefik routes `/api/v1/...` paths to backend services.
- Traefik routes `/` to the frontend service.
- The frontend keeps using relative API paths and does not know backend service ports.

## Requirements

- Docker Desktop, kind, minikube, or another local Kubernetes runtime
- Docker image build support
- `kubectl`
- `helm`

Docker must be running before image build or Kubernetes deployment checks can work.

Recommended runtime gate:

```powershell
docker context use desktop-linux
docker info
docker run --rm hello-world
kubectl version --client
helm version
kind version
```

Continue only after Docker reports a running Linux engine and the `hello-world` container exits successfully.

## Create a kind Cluster

For kind-based local testing, the repository includes `deploy/local/kind-config.yaml`.

```powershell
kind create cluster --config deploy/local/kind-config.yaml
kubectl config use-context kind-redacta-local
kubectl get nodes
kubectl get pods -A
```

This maps local host port `8080` to the kind node port `30080`.

## Build Local Images

Run these commands from the repository root:

```powershell
docker build -f backend/document-service/Dockerfile backend -t redacta-document-service:local
docker build -f backend/authentication-service/Dockerfile backend -t redacta-authentication-service:local
docker build -f backend/anonymization-service/Dockerfile backend -t redacta-anonymization-service:local
docker build -f backend/genai-service/Dockerfile backend/genai-service -t redacta-genai-service:local
docker build -f frontend/Dockerfile frontend -t redacta-frontend:local
```

For kind-based clusters, load the images into the cluster after building them:

```powershell
kind load docker-image redacta-document-service:local --name redacta-local
kind load docker-image redacta-authentication-service:local --name redacta-local
kind load docker-image redacta-anonymization-service:local --name redacta-local
kind load docker-image redacta-genai-service:local --name redacta-local
kind load docker-image redacta-frontend:local --name redacta-local
```

Verify the images inside the kind node:

```powershell
docker exec redacta-local-control-plane crictl images
```

## Local Secrets

Local secret values are intentionally not committed. Use `values-local.yaml` files under the Helm chart folders; these filenames are ignored by Git.

The infra chart needs:

```yaml
secrets:
  create: true
  values:
    postgresPassword: "<local-postgres-password>"
    keycloakAdminUsername: "<local-keycloak-admin-user>"
    keycloakAdminPassword: "<local-keycloak-admin-password>"

keycloak:
  realmImport:
    enabled: true
```

The app chart needs:

```yaml
secrets:
  create: true
  values:
    datasourceUsername: "redacta"
    datasourcePassword: "<same-local-postgres-password>"
    keycloakClientSecret: "<secret-from-keycloak-realm-client>"
    keycloakAdminUsername: "<same-local-keycloak-admin-user>"
    keycloakAdminPassword: "<same-local-keycloak-admin-password>"
```

For the current imported realm, `keycloakClientSecret` must match the confidential backend client secret in `keycloak/myrealm.json`.

For the app chart, prefer a Kubernetes Secret that is managed outside Helm. This mirrors the later cloud approach better and avoids committing or storing API keys in chart values:

```powershell
kubectl create secret generic redacta-app-runtime-secrets -n redacta `
  --from-literal=datasource-username=redacta `
  --from-literal=datasource-password="<same-local-postgres-password>" `
  --from-literal=keycloak-client-secret="<secret-from-keycloak-realm-client>" `
  --from-literal=keycloak-admin-username="<same-local-keycloak-admin-user>" `
  --from-literal=keycloak-admin-password="<same-local-keycloak-admin-password>" `
  --from-literal=openai-api-key="<openai-api-key-or-local-placeholder>"
```

Then point the app chart at that manually managed Secret:

```yaml
secrets:
  create: false
  name: redacta-app-runtime-secrets

genaiService:
  localFallback: false
  openaiModel: gpt-4.1-mini
```

If no OpenAI key is available, keep `openai-api-key` as a local placeholder and set `genaiService.localFallback: true`. That mode is only for local demos and avoids external AI calls.

## Install Infrastructure

```powershell
kubectl create namespace redacta

helm upgrade --install redacta-infra deploy/helm/redacta-infra `
  --namespace redacta `
  -f deploy/helm/redacta-infra/values-local.yaml `
  --set traefik.service.type=NodePort `
  --set traefik.service.nodePort=30080 `
  --set-file keycloak.realmImport.content=keycloak/myrealm.json
```

Check infrastructure pods:

```powershell
kubectl get pods -n redacta
kubectl get svc -n redacta
```

## Install Application

Create the app runtime Secret before installing the app chart.

```powershell
helm upgrade --install redacta deploy/helm/redacta `
  --namespace redacta `
  -f deploy/helm/redacta/values-local.yaml `
  --wait `
  --timeout 5m
```

Check application pods:

```powershell
kubectl get pods -n redacta
kubectl get ingress -n redacta
```

## Metrics Server And HPA

The app chart supports optional HorizontalPodAutoscaler resources. HPA needs Kubernetes Metrics Server.

Install Metrics Server:

```powershell
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

For kind, Metrics Server usually needs insecure kubelet TLS enabled. One PowerShell-safe way to patch it is:

```powershell
$patch = @'
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "metrics-server",
            "args": [
              "--cert-dir=/tmp",
              "--secure-port=10250",
              "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
              "--kubelet-use-node-status-port",
              "--metric-resolution=15s",
              "--kubelet-insecure-tls"
            ]
          }
        ]
      }
    }
  }
}
'@

$patchPath = Join-Path $env:TEMP "metrics-server-kind-patch.json"
$patch | Set-Content -Path $patchPath -NoNewline
kubectl patch deployment metrics-server -n kube-system --type=strategic --patch-file $patchPath
Remove-Item -LiteralPath $patchPath
kubectl rollout status deployment/metrics-server -n kube-system --timeout=2m
kubectl top nodes
```

Enable HPA in `deploy/helm/redacta/values-local.yaml`:

```yaml
autoscaling:
  enabled: true
  minReplicas: 1
  maxReplicas: 2
  targetCPUUtilizationPercentage: 70
```

When HPA is enabled, the chart does not render `spec.replicas` for autoscaled Deployments. HPA becomes the owner of replica count and Helm avoids conflicts with the Kubernetes scale controller.

Verify:

```powershell
kubectl get hpa -n redacta
kubectl top pods -n redacta
```

## CI Workflow Validation

The repository has separate GitHub Actions workflows for frontend and backend validation:

- `.github/workflows/frontend-ci.yml` runs `npm ci`, frontend lint, frontend build, and frontend Docker image build validation.
- `.github/workflows/backend-ci.yml` runs Java 21 tests, GenAI pytest, and Docker image build validation for all backend services.

These workflows intentionally do not deploy anything. Deployment is handled by Helm locally and later by GitOps/Argo CD.

Equivalent local checks:

```powershell
cd frontend
npm ci
npm run lint
npm run build
docker build -t redacta-frontend:ci-test .
cd ..

cd backend
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-21.0.10.7-hotspot"
.\gradlew.bat :document-service:test :authentication-service:test :anonymization-service:test --console=plain
cd ..

docker build -t redacta-document-service:ci-test -f backend/document-service/Dockerfile backend
docker build -t redacta-authentication-service:ci-test -f backend/authentication-service/Dockerfile backend
docker build -t redacta-anonymization-service:ci-test -f backend/anonymization-service/Dockerfile backend
docker build -t redacta-genai-service:ci-test backend/genai-service
docker run --rm -v "${PWD}\backend\genai-service\tests:/app/tests:ro" redacta-genai-service:ci-test python -m pytest tests -q
```

## Prometheus And Grafana

Local monitoring uses the official `kube-prometheus-stack` Helm chart, not a custom monitoring chart.

Install or upgrade it:

```powershell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic monitoring-grafana-admin `
  --namespace monitoring `
  --from-literal=admin-user=admin `
  --from-literal=admin-password="<local-grafana-password>" `
  --dry-run=client `
  -o yaml |
kubectl apply -f -

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack `
  --namespace monitoring `
  --create-namespace `
  --set fullnameOverride=monitoring `
  --set grafana.admin.existingSecret=monitoring-grafana-admin `
  --set grafana.admin.userKey=admin-user `
  --set grafana.admin.passwordKey=admin-password `
  --set grafana.service.type=ClusterIP `
  --set prometheus.prometheusSpec.retention=6h `
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false `
  --set-json prometheus.prometheusSpec.serviceMonitorNamespaceSelector='{}' `
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false `
  --set-json prometheus.prometheusSpec.podMonitorNamespaceSelector='{}' `
  --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false `
  --set-json prometheus.prometheusSpec.ruleNamespaceSelector='{}' `
  --wait `
  --timeout 10m
```

After the monitoring CRDs exist, enable ServiceMonitor rendering in the app chart:

```yaml
monitoring:
  serviceMonitor:
    enabled: true
    interval: 15s
    scrapeTimeout: 10s
```

Verify:

```powershell
kubectl get pods -n monitoring
kubectl get servicemonitor -A
kubectl port-forward -n monitoring svc/monitoring-grafana 3001:80
```

Grafana is then available at `http://localhost:3001` with the local demo credentials configured above.

## GitOps With Argo CD

Argo CD manifests are under `deploy/gitops/argocd`.

The local GitOps model has one root Application and three child Applications:

- `redacta-infra-local`: Postgres, Keycloak, and Traefik from `deploy/helm/redacta-infra`
- `redacta-monitoring-local`: official `kube-prometheus-stack`
- `redacta-app-local`: frontend and backend services from `deploy/helm/redacta`

Monitoring uses a separate Argo CD project:

- `redacta-local`: application and infrastructure resources in `argocd` and `redacta`
- `redacta-monitoring-local`: monitoring resources in `monitoring` and kube-prometheus-stack helper Services in `kube-system`

The monitoring Application uses `ServerSideApply=true` because kube-prometheus-stack CRDs are large enough to hit the Kubernetes client-side apply annotation limit.

Committed GitOps values are secrets-free:

- `deploy/helm/redacta-infra/values-gitops-local.yaml`
- `deploy/helm/redacta/values-gitops-local.yaml`

Do not point Argo CD at ignored `values-local.yaml` files. Those are only for manual local Helm experiments and may contain machine-local secret references.

The Redacta GitHub repository is private, so Argo CD uses an SSH source URL:

```text
git@github.com:babasoyturan/Redacta.git
```

Create a dedicated read-only deploy key for Argo CD:

```powershell
$keyPath = "$env:USERPROFILE\.ssh\redacta_argocd"
ssh-keygen -t ed25519 -C "argocd-redacta-local" -f $keyPath
Get-Content "$keyPath.pub"
```

Add the public key in GitHub under `Settings -> Deploy keys -> Add deploy key`.
Do not enable write access.

After the deploy key is added in GitHub, create the Argo CD repository Secret.
This Secret is cluster-local and must not be committed:

```powershell
kubectl create secret generic redacta-github-repo `
  --namespace argocd `
  --from-literal=type=git `
  --from-literal=url=git@github.com:babasoyturan/Redacta.git `
  --from-file=sshPrivateKey=$keyPath `
  --dry-run=client `
  -o yaml |
kubectl apply -f -

kubectl label secret redacta-github-repo `
  --namespace argocd `
  argocd.argoproj.io/secret-type=repository `
  --overwrite
```

Install Argo CD:

```powershell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl rollout status deployment/argocd-server -n argocd --timeout=5m
```

Apply the project and root Application after the GitOps files are committed and pushed to `main`:

```powershell
kubectl apply -f deploy/gitops/argocd/projects/redacta-local-project.yaml
kubectl apply -f deploy/gitops/argocd/projects/redacta-monitoring-local-project.yaml
kubectl apply -f deploy/gitops/argocd/root/redacta-local-root.yaml
```

Manual sync order for first adoption:

```text
redacta-infra-local
redacta-monitoring-local
redacta-app-local
```

Automated sync is disabled during first local adoption. Enable it only after the Applications are `Synced` and `Healthy`.

## Local DNS

Point `redacta.local` to the local Traefik entrypoint address.

For Docker Desktop Kubernetes this is usually:

```text
127.0.0.1 redacta.local
```

For kind or minikube, use the Traefik service address or port-forwarding depending on the local cluster networking mode.

For the included kind config, the app is reachable directly at `localhost:8080` when the app chart uses `ingress.host: localhost`.

If the app chart uses `ingress.host: redacta.local`, add this hosts entry if it is not already present:

```text
127.0.0.1 redacta.local
```

## Verification

The expected public entrypoint for the current kind setup is:

```text
http://localhost:8080/
```

Expected routing:

```text
/                         -> frontend
/api/v1/documents         -> document-service
/api/v1/authentication    -> authentication-service
/api/v1/anonymization     -> anonymization-service
/api/v1/genai             -> genai-service
```

Useful checks:

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/
kubectl logs -n redacta deploy/traefik
kubectl logs -n redacta deploy/keycloak
kubectl logs -n redacta deploy/redacta-authentication-service
kubectl logs -n redacta deploy/redacta-genai-service
```

Minimal GenAI smoke tests:

```powershell
$summaryBody = @{ originalText = "Turan lives in Baku and works as a backend developer."; level = "medium" } | ConvertTo-Json -Compress
Invoke-RestMethod -Method Post -Uri http://localhost:8080/api/v1/genai/summarize -ContentType "application/json" -Body $summaryBody

$anonymizeBody = @{ originalText = "John Doe lives in Baku."; level = "medium" } | ConvertTo-Json -Compress
Invoke-RestMethod -Method Post -Uri http://localhost:8080/api/v1/genai/anonymize -ContentType "application/json" -Body $anonymizeBody
```

Run real GenAI smoke tests sparingly because each successful request can consume OpenAI API budget.
