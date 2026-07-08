# Local Kubernetes Runbook

This runbook describes the local-first deployment path for Redacta before the cloud subscription is available.

## Scope

The local Kubernetes environment runs the same application routing model planned for cloud:

- Browser traffic reaches one domain, for example `redacta.local`.
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
kind load docker-image redacta-document-service:local
kind load docker-image redacta-authentication-service:local
kind load docker-image redacta-anonymization-service:local
kind load docker-image redacta-genai-service:local
kind load docker-image redacta-frontend:local
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
    openaiApiKey: "<openai-api-key>"
```

For the current imported realm, `keycloakClientSecret` must match the confidential backend client secret in `keycloak/myrealm.json`.

## Install Infrastructure

```powershell
kubectl create namespace redacta

helm upgrade --install redacta-infra deploy/helm/redacta-infra `
  --namespace redacta `
  -f deploy/helm/redacta-infra/values-local.yaml `
  --set-file keycloak.realmImport.content=keycloak/myrealm.json
```

Check infrastructure pods:

```powershell
kubectl get pods -n redacta
kubectl get svc -n redacta
```

## Install Application

```powershell
helm upgrade --install redacta deploy/helm/redacta `
  --namespace redacta `
  -f deploy/helm/redacta/values-local.yaml
```

Check application pods:

```powershell
kubectl get pods -n redacta
kubectl get ingress -n redacta
```

## Local DNS

Point `redacta.local` to the local Traefik entrypoint address.

For Docker Desktop Kubernetes this is usually:

```text
127.0.0.1 redacta.local
```

For kind or minikube, use the Traefik service address or port-forwarding depending on the local cluster networking mode.

## Verification

The expected public entrypoint is:

```text
http://redacta.local/
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
kubectl logs -n redacta deploy/traefik
kubectl logs -n redacta deploy/keycloak
kubectl logs -n redacta deploy/redacta-authentication-service
```
