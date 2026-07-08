# Redacta

Redacta is a multi-service application that is being developed into a complete DevOps final project.

## Current Delivery Target

The first complete delivery environment is local Kubernetes on Minikube. The project is intentionally being prepared so that the same delivery model can later be migrated to Azure when subscription access becomes available.

The local platform will eventually include:

- Docker containerization
- Kubernetes on Minikube
- Helm
- Traefik
- Sealed Secrets
- Argo CD and GitOps
- GitHub Actions CI/CD
- Docker Hub
- Prometheus, Grafana, and Alertmanager
- Security scanning
- Operational runbooks

Azure migration will be implemented later and will target AKS, ACR, Azure SQL, Azure Files, Key Vault, Application Gateway WAF_v2, AGIC, and Terraform.

## Application Structure

```text
frontend/
backend/
  document-service/
  authentication-service/
  anonymization-service/
  genai-service/
keycloak/
docs/
```

## Application Components

- Frontend: React/Vite
- Document Service: Spring Boot
- Authentication Service: Spring Boot
- Anonymization Service: Spring Boot
- GenAI Service: Python/FastAPI
- Identity Provider: Keycloak
- Local Database: PostgreSQL

## Delivery Model

The project follows a GitOps delivery model:

```text
Developer
  -> GitHub
  -> GitHub Actions
  -> Build, test, scan, and publish images
  -> Update Git deployment state
  -> Argo CD
  -> Kubernetes
```

CI is responsible for validation, image publishing, and updating Git deployment state. CI must not deploy directly to Kubernetes with `kubectl apply`, `helm upgrade`, or direct Argo CD API calls.

## Current Project Status

The repository currently contains only the cleaned application source code and this orientation README.

Dockerfiles, Docker Compose files, Helm charts, Kubernetes manifests, CI/CD workflows, Argo CD definitions, monitoring configuration, and other DevOps delivery artifacts will be added incrementally in later implementation stages.
