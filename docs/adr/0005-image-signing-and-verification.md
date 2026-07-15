# ADR 0005: Image Signing and Verification

## Status

Accepted

## Context

The CI/CD pipeline already scans images and generates SBOMs. The remaining supply-chain gap is proving that images deployed to Kubernetes were produced by the repository workflows.

## Decision

Backend and frontend image publish jobs sign pushed images with cosign keyless signing using GitHub OIDC. The same jobs attach CycloneDX SBOM attestations to the pushed images.

Kyverno is installed in each AKS environment through a dedicated Argo CD Application. Redacta admission policies are deployed from the separate `deploy/helm/redacta-security` chart after Kyverno is ready. The policy uses `verifyImages` in `Enforce` mode for Redacta images from the project ACR and accepts only signatures issued by the GitHub Actions workflows for this repository.

## Consequences

Images in ACR carry signatures and SBOM attestations without storing a long-lived signing private key. Kubernetes admission blocks new Redacta pods if their images are not signed by the approved workflows. The tradeoff is that the Kyverno controller must be installed before the security policy is applied, so the runbook and GitOps manifests keep Kyverno and Redacta security policies as separate Argo CD applications.
