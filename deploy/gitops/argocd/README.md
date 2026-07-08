# Redacta Local GitOps

These manifests define the local Argo CD deployment model for Redacta.

Apply order:

1. Install Argo CD into the `argocd` namespace.
2. Create the manual runtime Secrets in `redacta`.
3. Apply `projects/redacta-local-project.yaml`.
4. Apply `root/redacta-local-root.yaml`.
5. Manually sync child Applications in this order: infra, monitoring, app.

The Applications sync three independent layers:

- `redacta-infra-local`: Postgres, Keycloak, and Traefik
- `redacta-app-local`: frontend and backend application services
- `redacta-monitoring-local`: kube-prometheus-stack with Prometheus and Grafana

Secrets are intentionally not managed by these GitOps manifests. For local work,
create `redacta-infra-secrets` and `redacta-app-runtime-secrets` manually before
syncing the Applications.

Automated sync is intentionally disabled for local adoption. Enable automated
sync only after the manually installed Helm releases are adopted cleanly and all
Applications are `Synced` and `Healthy`.
