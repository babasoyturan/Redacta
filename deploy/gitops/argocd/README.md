# Redacta Local GitOps

These manifests define the local Argo CD deployment model for Redacta.

Apply order:

1. Install Argo CD into the `argocd` namespace.
2. Create the manual runtime Secrets in `redacta`.
3. Apply `projects/redacta-local-project.yaml` and `projects/redacta-monitoring-local-project.yaml`.
4. Apply `root/redacta-local-root.yaml`.
5. Manually sync child Applications in this order: infra, monitoring, app.

The Applications sync three independent layers:

- `redacta-infra-local`: Postgres, Keycloak, and Traefik
- `redacta-app-local`: frontend and backend application services
- `redacta-monitoring-local`: kube-prometheus-stack with Prometheus and Grafana

Monitoring uses a separate Argo CD project because kube-prometheus-stack manages
some scrape helper Services in `kube-system`. The application and infrastructure
project stays limited to `argocd` and `redacta`.

The GitHub repository is referenced with SSH:

```text
git@github.com:babasoyturan/Redacta.git
```

For a private repository, create a dedicated read-only GitHub deploy key and
register its private key in Argo CD as a repository Secret in the `argocd`
namespace. Do not commit that Secret or private key.

Secrets are intentionally not managed by these GitOps manifests. For local work,
create `redacta-infra-secrets` and `redacta-app-runtime-secrets` manually before
syncing the Applications.

Automated sync is intentionally disabled for local adoption. Enable automated
sync only after the manually installed Helm releases are adopted cleanly and all
Applications are `Synced` and `Healthy`.
