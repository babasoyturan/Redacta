# Redacta

Redacta is a multi-service document anonymization and summarization application prepared as a DevOps final project.

The current delivery target is Azure Kubernetes Service with GitOps-based deployment. The earlier local Kubernetes work is kept as historical/local validation material, but the active project path is cloud-first.

## Architecture

Redacta is split into five application services:

- Frontend: React/Vite
- Document Service: Spring Boot
- Authentication Service: Spring Boot
- Anonymization Service: Spring Boot
- GenAI Service: Python/FastAPI
- Identity Provider: Keycloak

The Azure platform uses:

- AKS for Kubernetes workloads
- ACR for container images
- Azure SQL for application databases
- Azure Files for uploaded document storage
- Azure Key Vault with Secrets Store CSI Driver and Workload Identity
- Application Gateway WAF_v2 with AGIC for public ingress
- Azure Monitor Managed Prometheus and Managed Grafana
- Terraform for infrastructure
- Argo CD for GitOps deployment
- GitHub Actions for CI/CD

## Repository Layout

```text
frontend/
backend/
  document-service/
  authentication-service/
  anonymization-service/
  genai-service/
keycloak/
deploy/
  helm/redacta/
  gitops/argocd/
terraform/
  modules/
  stacks/
scripts/
docs/
```

## Delivery Model

The repository follows a promotion-based GitOps model:

```text
dev branch
  -> GitHub Actions validates, scans, builds, and publishes images
  -> GitHub Actions updates deploy/helm/redacta/versions.yaml
  -> Argo CD development app syncs dev branch

main branch
  -> receives the already-tested versions.yaml through merge
  -> production uses the same image versions from main
  -> Argo CD production app syncs main branch
```

There is one image version file: `deploy/helm/redacta/versions.yaml`.

Development and production do not maintain separate image version files. Development writes the tested image tags into `versions.yaml`; production receives those exact versions when `dev` is merged into `main`.

## GitHub Actions

Active workflow files:

- `.github/workflows/backend-ci-cd.yml`
- `.github/workflows/frontend-ci-cd.yml`
- `.github/workflows/infrastructure.yml`

Backend and frontend workflows validate code, run security checks, build container images, push them to ACR, generate SBOM artifacts, and update `versions.yaml` on `dev`.

The infrastructure workflow validates Terraform and applies Azure infrastructure. After a successful environment apply, it exports Terraform outputs and updates the matching cloud Helm values file:

- `deploy/helm/redacta/values-cloud-development.yaml`
- `deploy/helm/redacta/values-cloud-production.yaml`

No destroy, recreate, start, or stop workflow is kept in the repository. Cost-control actions are manual and documented in the runbook.

## Current Status

Development cloud is deployed and verified on AKS:

- Argo CD application: `Synced / Healthy`
- Ingress host: `dev.redacta.example.com`
- Public entrypoint: Azure Application Gateway
- Smoke checks covered frontend, authentication, protected API access, and a minimal GenAI summary request.

Production infrastructure is intentionally not deployed yet. The production resource group exists as a low-cost placeholder; production AKS, SQL, Key Vault, Application Gateway, and app deployment should be created when production secrets and final domain values are ready.

## Runbooks

- Cloud deployment and recovery: `docs/cloud-runbook.md`
- Earlier local Kubernetes runbook: `docs/local-kubernetes-runbook.md`
