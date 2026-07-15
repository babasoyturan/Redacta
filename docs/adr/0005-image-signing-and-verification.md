# ADR 0005: Image Signing and Verification

## Status

Accepted

## Context

The CI/CD pipeline already scans images and generates SBOMs. The remaining supply-chain gap is proving that images deployed to Kubernetes were produced by the repository workflows.

## Decision

Backend and frontend image publish jobs sign pushed images with cosign keyless signing using GitHub OIDC. The same jobs attach CycloneDX SBOM attestations to the pushed images. A Kyverno `verifyImages` policy template is included in the Helm chart but disabled by default until Kyverno CRDs/controllers are installed in the target clusters.

## Consequences

Images in ACR carry signatures and SBOM attestations without storing a long-lived signing private key. Admission enforcement can be enabled later by installing Kyverno and setting image verification values. The tradeoff is that full admission blocking depends on Kyverno being present in the cluster.
