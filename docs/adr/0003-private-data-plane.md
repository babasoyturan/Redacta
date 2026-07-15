# ADR 0003: Private Data Plane for State

## Status

Accepted

## Context

Redacta stores documents, authentication data, anonymization data, Keycloak state, and secrets. These resources should not be exposed as public application dependencies.

## Decision

Azure SQL, Azure Storage, and Azure Key Vault are provisioned with private networking controls. AKS workloads reach these services through private endpoint subnets and workload identity where applicable. SQL bootstrap runs inside Kubernetes and creates the required SQL logins/users from secrets mounted through the Secrets Store CSI driver.

## Consequences

The application data plane is kept inside the Azure network boundary instead of relying on broad public access. The tradeoff is that initial bootstrap needs the correct private DNS, workload identity, and NetworkPolicy egress rules.
