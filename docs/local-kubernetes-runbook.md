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
