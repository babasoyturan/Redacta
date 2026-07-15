# ADR 0002: GitOps Application Delivery

## Status

Accepted

## Context

The project must show automated delivery from repository changes to Kubernetes, while keeping manual cluster changes to a minimum. The same application must be deployable to development and production.

## Decision

We use Argo CD as the GitOps controller. Application manifests are generated from the `deploy/helm/redacta` Helm chart. Development reads the cloud development values file and production reads the cloud production values file. Image versions are stored in a single `versions.yaml` file and promoted by Git branch flow rather than by maintaining separate version files.

The workflow is:

1. Code changes are merged to `dev`.
2. CI validates, builds, scans, signs, and pushes images.
3. CI updates `versions.yaml`.
4. Argo CD syncs development from `dev`.
5. After validation, `dev` is merged to `main`.
6. Production Argo CD syncs from `main` using the same promoted image versions.

## Consequences

Git remains the source of truth, and the cluster state can be recreated from the repository. The tradeoff is that GitOps writeback must be carefully serialized to avoid concurrent commits to `versions.yaml`.
