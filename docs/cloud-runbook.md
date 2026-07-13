# Redacta Cloud Runbook

This runbook describes how to deploy, verify, and recover the Azure cloud version of Redacta.

## Current Cloud Strategy

Redacta uses two cloud environments:

- Development: driven by the `dev` branch
- Production: driven by the `main` branch

Development is the active working environment. Production is created only when final secrets, domain values, and cost approval are ready.

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
SONAR_ORGANIZATION
```

Required GitHub secrets:

```text
SQL_ADMIN_PASSWORD_DEVELOPMENT
SQL_ADMIN_PASSWORD_PRODUCTION
SONAR_TOKEN
```

`SONAR_TOKEN` and `SONAR_ORGANIZATION` are required for backend and frontend quality jobs. The scanner must run successfully, but `sonar.qualitygate.wait=false` keeps the quality gate non-blocking while the application code is still being improved.

## Infrastructure Flow

Shared infrastructure is applied from `dev`:

```text
shared stack:
  resource group
  ACR
  GitHub Actions federated identities
  optional DNS zone
  production placeholder resource group
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

Production infrastructure is applied from `main` only after production secrets and domain values are ready.

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
kubectl apply -f deploy/gitops/argocd/development/application.yaml
```

Production uses:

```powershell
kubectl apply -f deploy/gitops/argocd/production/project.yaml
kubectl apply -f deploy/gitops/argocd/production/application.yaml
```

Only apply production GitOps manifests after production Key Vault secrets are ready.

## DNS and Temporary Access

Until a real domain is purchased, use a hosts-file mapping.

Get the development Application Gateway IP:

```powershell
az network public-ip show `
  --resource-group rg-redacta-development `
  --name pip-redacta-dev-swec-agw `
  --query ipAddress `
  -o tsv
```

Temporary hosts entry:

```text
<development-app-gateway-ip> dev.redacta.example.com
```

Then open:

```text
http://dev.redacta.example.com/
```

When a real domain is available, set:

```text
DEVELOPMENT_HOSTNAME=dev.<domain>
PRODUCTION_HOSTNAME=<domain>
```

Then rerun the infrastructure workflow or update the values files through the normal branch flow.

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
curl.exe -I -H "Host: dev.redacta.example.com" http://<development-app-gateway-ip>/
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

Before enabling production:

- `SQL_ADMIN_PASSWORD_PRODUCTION` exists in GitHub secrets
- Production domain is selected
- `PRODUCTION_HOSTNAME` is configured
- Production Key Vault secrets are seeded
- Production Terraform apply has completed
- `values-cloud-production.yaml` has been updated by Terraform outputs
- Production Argo CD project/application are applied
- Production ingress points to the correct Application Gateway public IP
- Smoke tests pass through the production hostname
