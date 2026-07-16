# Redacta Cloud Runbook

This runbook describes how to deploy, verify, and recover the Azure cloud version of Redacta.

## Current Cloud Strategy

Redacta uses two cloud environments:

- Development: driven by the `dev` branch
- Production: driven by the `main` branch

Development is the staging environment. Production is the promoted environment for the final presentation and is driven by the `main` branch.

Public entrypoints:

```text
development: https://dev.redacta.site
production:  https://redacta.site
sonarqube:   https://sonar.redacta.site
```

The selected Azure region is `swedencentral`. Resource names use the `swec` suffix, which stands for Sweden Central.

## Branch and Promotion Model

The project uses one image version file:

```text
deploy/helm/redacta/versions.yaml
```

Development image builds update this file on `dev`. Production does not rebuild separate images. When `dev` is merged into `main`, production receives the same tested image versions.

Argo CD reads:

```text
development: targetRevision dev  + values-cloud-development.yaml + versions.yaml
production:  targetRevision main + values-cloud-production.yaml  + versions.yaml
```

## GitHub Configuration

Required repository or environment variables:

```text
AZURE_LOCATION=swedencentral
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
TFSTATE_STORAGE_ACCOUNT_NAME
ACR_NAME
ACR_LOGIN_SERVER
AZURE_CLIENT_ID_ACR_PUSH
AZURE_CLIENT_ID_TERRAFORM_SHARED
AZURE_CLIENT_ID_TERRAFORM_DEVELOPMENT
AZURE_CLIENT_ID_TERRAFORM_PRODUCTION
AKS_API_SERVER_AUTHORIZED_IP_RANGES
PLATFORM_ADMIN_OBJECT_IDS
DEVELOPMENT_HOSTNAME
PRODUCTION_HOSTNAME
SONAR_HOST_URL
```

Required GitHub secrets:

```text
SQL_ADMIN_PASSWORD_DEVELOPMENT
SQL_ADMIN_PASSWORD_PRODUCTION
```

Optional GitHub secret for SonarQube scanning:

```text
SONAR_TOKEN
```

The workflows use these self-hosted SonarQube project keys:

```text
redacta-backend
redacta-frontend
```

`SONAR_TOKEN` and `SONAR_HOST_URL` enable backend and frontend SonarQube analysis. If either value is missing, the workflows emit a warning and skip SonarQube for that run so deployment automation is not blocked. When both values are configured, the scanner must run successfully, but `sonar.qualitygate.wait=false` keeps the quality gate non-blocking while the application code is still being improved.

## Infrastructure Flow

Shared infrastructure is applied from `dev`:

```text
shared stack:
  resource group
  ACR
  GitHub Actions federated identities
  optional DNS zone
  shared identities and registries used by both environments
```

Development infrastructure is applied from `dev`:

```text
development stack:
  VNet and subnets
  AKS
  Application Gateway WAF_v2
  Azure SQL
  Azure Files
  Key Vault
  Workload Identity
  Azure Monitor / Managed Prometheus / Managed Grafana
```

Production infrastructure is applied from `main`. Production uses the same tested image versions that were promoted from `dev` to `main`, then applies production-specific Terraform outputs and Helm values.

After every successful development or production apply, the infrastructure workflow exports Terraform outputs and updates the matching Helm values file. This prevents stale SQL, Key Vault, storage, and Workload Identity placeholders.

## Key Vault Secrets

Application secrets are not committed to Git.

Because Key Vault network access is restricted, secret seeding should be done from an authorized admin machine/IP after Terraform creates the Key Vault.

Development Key Vault:

```powershell
$vaultName = "kv-redacta-dev-swec"

az keyvault secret set --vault-name $vaultName --name sql-admin-username --value "<sql-admin-username>"
az keyvault secret set --vault-name $vaultName --name sql-admin-password --value "<sql-admin-password>"
az keyvault secret set --vault-name $vaultName --name datasource-username --value "<app-db-username>"
az keyvault secret set --vault-name $vaultName --name datasource-password --value "<app-db-password>"
az keyvault secret set --vault-name $vaultName --name keycloak-db-username --value "<keycloak-db-username>"
az keyvault secret set --vault-name $vaultName --name keycloak-db-password --value "<keycloak-db-password>"
az keyvault secret set --vault-name $vaultName --name keycloak-admin-username --value "<keycloak-admin-username>"
az keyvault secret set --vault-name $vaultName --name keycloak-admin-password --value "<keycloak-admin-password>"
az keyvault secret set --vault-name $vaultName --name keycloak-client-secret --value "<keycloak-client-secret>"
az keyvault secret set --vault-name $vaultName --name openai-api-key --value "<openai-api-key>"
```

Use the production Key Vault name from Terraform outputs when production is created.

The SQL admin password in Key Vault and the Azure SQL server admin password must match. If they drift, update Azure SQL to the Key Vault value before rerunning the SQL bootstrap job.

## Argo CD Bootstrap

Get AKS credentials:

```powershell
az aks get-credentials `
  --resource-group rg-redacta-development `
  --name aks-redacta-dev-swec `
  --overwrite-existing
```

Install Argo CD if it is not installed:

```powershell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/crds/applicationset-crd.yaml
kubectl get pods -n argocd
```

Apply the development GitOps project and application:

```powershell
kubectl apply -f deploy/gitops/argocd/development/project.yaml
kubectl apply -f deploy/gitops/argocd/development/kyverno.yaml
kubectl wait --for=condition=available deployment/kyverno-admission-controller -n kyverno --timeout=5m
kubectl apply -f deploy/gitops/argocd/development/security.yaml
kubectl apply -f deploy/gitops/argocd/development/application.yaml
```

Production uses:

```powershell
kubectl apply -f deploy/gitops/argocd/production/project.yaml
kubectl apply -f deploy/gitops/argocd/production/kyverno.yaml
kubectl wait --for=condition=available deployment/kyverno-admission-controller -n kyverno --timeout=5m
kubectl apply -f deploy/gitops/argocd/production/security.yaml
kubectl apply -f deploy/gitops/argocd/production/application.yaml
```

Only apply production GitOps manifests after production Key Vault secrets are ready.

Kyverno must be installed before the Redacta security policy because the `ClusterPolicy` CRD is created by the Kyverno chart. The security policy verifies Redacta ACR images with cosign keyless signatures from the repository's GitHub Actions workflows and runs in `Enforce` mode.

## DNS and Public Access

The project uses the purchased domain `redacta.site`.

```text
dev.redacta.site -> development Application Gateway public IP
redacta.site     -> production Application Gateway public IP
sonar.redacta.site -> SonarQube public IP
```

Get the Application Gateway IPs:

```powershell
az network public-ip show `
  --resource-group rg-redacta-development `
  --name pip-redacta-dev-swec-agw `
  --query ipAddress `
  -o tsv

az network public-ip show `
  --resource-group rg-redacta-production `
  --name pip-redacta-prod-swec-agw `
  --query ipAddress `
  -o tsv
```

If DNS propagation is still in progress during an emergency demo, a local hosts-file mapping can be used only as a fallback:

```text
<development-app-gateway-ip> dev.redacta.site
<production-app-gateway-ip> redacta.site
```

Then open:

```text
https://dev.redacta.site/
https://redacta.site/
```

## Verification

Check Argo CD:

```powershell
kubectl get application redacta-development -n argocd `
  -o jsonpath="{.status.sync.status} {.status.health.status} {.status.sync.revision}"
```

Expected:

```text
Synced Healthy <git-revision>
```

Check pods:

```powershell
kubectl get pods -n redacta -o wide
```

Expected application pods:

```text
keycloak
redacta-frontend
redacta-document-service
redacta-authentication-service
redacta-anonymization-service
redacta-genai-service
```

Check ingress:

```powershell
kubectl get ingress -n redacta -o wide
```

Check frontend through Application Gateway:

```powershell
curl.exe -I https://dev.redacta.site/
curl.exe -I https://redacta.site/
```

Expected:

```text
HTTP/1.1 200 OK
```

Recommended application smoke tests:

- Register a new user
- Login with that user
- Call protected document and anonymization list endpoints
- Run one minimal GenAI summary request
- Upload a small PDF manually from the browser and verify anonymization/summarization

Check SonarQube:

```powershell
curl.exe -I https://sonar.redacta.site/
```

Expected:

```text
HTTP/1.1 200 OK
```

## Argo CD and Kyverno Drift Notes

Expected final application state:

```text
redacta-development          Synced Healthy
redacta-production           Synced Healthy
redacta-security-development Synced Healthy
redacta-security-production  Synced Healthy
kyverno-development          Synced Healthy
kyverno-production           Synced Healthy
```

Kyverno and Redacta security are separate Argo CD Applications because the Redacta security policy depends on Kyverno CRDs. Kyverno CRD specs and generated CRD metadata are ignored in Argo CD diff because the live CRD schemas are normalized by Kubernetes and the Kyverno Helm chart after apply. The CRDs remain managed by the pinned Kyverno chart version.

The Redacta `ClusterPolicy` desired state explicitly includes `admission: true` and `signatureAlgorithm: sha256`. These are Kyverno defaults that otherwise appear as Argo CD drift.

Refresh Argo CD if Git has been updated:

```powershell
kubectl annotate application kyverno-development -n argocd argocd.argoproj.io/refresh=hard --overwrite
kubectl annotate application redacta-security-development -n argocd argocd.argoproj.io/refresh=hard --overwrite
kubectl annotate application kyverno-production -n argocd argocd.argoproj.io/refresh=hard --overwrite
kubectl annotate application redacta-security-production -n argocd argocd.argoproj.io/refresh=hard --overwrite
```

## Performance Validation

Backend capacity proof is stored in:

```text
docs/performance/backend-load-test.md
tests/performance/k6-backend-smoke.js
tests/performance/k8s-k6-backend-smoke-job.yaml
tests/performance/k8s-loadtest-networkpolicy.yaml
```

The preferred proof runs a temporary k6 job inside production AKS at 300 requests per second against the internal anonymization service health endpoint. This avoids measuring browser, internet, TLS, or Application Gateway latency when the question is backend service capacity.

The load-test NetworkPolicy is temporary and must be deleted after the proof. It is not deployed by Argo CD.

## Managed Grafana Dashboards

Terraform creates Azure Managed Grafana and connects it to the Azure Monitor workspace used by AKS managed Prometheus.

The project dashboard definitions are stored in:

```text
deploy/observability/grafana/
```

Import or refresh the dashboards after Managed Grafana exists:

```powershell
.\scripts\import-grafana-dashboards.ps1 -Environment all
```

The script imports these dashboards into both development and production:

- `Redacta Overview`
- `Redacta Application SLO`
- `Redacta Kubernetes Capacity And Scaling`
- `Redacta Security And Delivery Controls`

Get the Managed Grafana URLs:

```powershell
az grafana show -g rg-redacta-development -n graf-redacta-dev-swec --query properties.endpoint -o tsv
az grafana show -g rg-redacta-production -n graf-redacta-prod-swec --query properties.endpoint -o tsv
```

## Cost Control

No cost-control workflow is stored in the repository.

Before the presentation, Azure resources can be manually deleted or recreated using this runbook. Keep the Terraform state storage unless the whole environment is intentionally being reset.

Recommended manual cost-control approach:

```text
keep:
  rg-redacta-tfstate

delete only when not needed:
  rg-redacta-development
  rg-redacta-production
  rg-redacta-shared
  AKS managed resource groups starting with MC_ or MA_
```

Before deleting shared resources, confirm that ACR images and GitHub OIDC identities are no longer needed. For a quick presentation rebuild, it is usually safer to keep shared infrastructure and delete only development/production runtime resources.

## Production Readiness Checklist

Production readiness checklist:

- `SQL_ADMIN_PASSWORD_PRODUCTION` exists in GitHub secrets
- `PRODUCTION_HOSTNAME=redacta.site`
- Production Key Vault secrets are seeded
- Production Terraform apply has completed
- `values-cloud-production.yaml` has been updated by Terraform outputs
- Production Argo CD project/application are applied
- Production ingress points to the production Application Gateway public IP
- TLS certificate is issued for `redacta.site`
- Smoke tests pass through `https://redacta.site`
- Production replica, HPA, PDB, and NetworkPolicy settings are active
