# ADR 0001: Terraform Stack Boundaries

## Status

Accepted

## Context

Redacta needs repeatable infrastructure for development and production while keeping shared resources, environment resources, and Terraform state separated. The project also has a limited Azure budget, so the infrastructure must support clean teardown and recreation without losing the overall deployment model.

## Decision

We split Terraform into separate stacks:

- `tfstate` owns the remote state storage.
- `shared` owns resources reused by both environments, such as the container registry.
- `development` owns the development AKS, networking, SQL, storage, Key Vault, monitoring, SonarQube VM, and environment-specific identities.
- `production` owns the production AKS, networking, SQL, storage, Key Vault, monitoring, and environment-specific identities.

Each environment keeps its own VNet CIDR ranges, AKS cluster, Application Gateway, Azure SQL server, Key Vault, storage account, and managed identities.

## Consequences

This design avoids accidental coupling between development and production, makes teardown safer, and keeps Terraform plans easier to review. The tradeoff is more Terraform code and more environment variables/secrets in GitHub Actions.
