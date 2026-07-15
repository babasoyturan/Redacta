# ADR 0004: Kubernetes Network Isolation

## Status

Accepted

## Context

The application contains multiple services and supporting bootstrap jobs. Without NetworkPolicy, any pod in the namespace could attempt to reach backend services. That weakens the isolation story and makes it harder to prove service boundaries.

## Decision

The Helm chart applies a default deny policy for both ingress and egress to Redacta pods. Explicit allow policies are then added for required traffic only:

- Application Gateway can reach the public frontend and API backend services.
- Frontend-labeled pods can reach the backend API services.
- GenAI service can reach the anonymization service.
- Application services and Keycloak bootstrap can reach Keycloak.
- Services that need SQL can reach the Azure SQL private endpoint subnet on TCP 1433 and the Azure SQL redirect range 11000-11999.
- Redacta pods can reach cluster DNS.
- GenAI can reach external HTTPS endpoints for OpenAI-compatible API calls.
- Azure Monitor can scrape metrics endpoints.

## Consequences

Unexpected pod-to-pod traffic is blocked by default, and allowed paths are explicit in Helm. The main tradeoff is that NetworkPolicy cannot express FQDN allowlists for external APIs, so GenAI HTTPS egress is controlled at TCP/443 CIDR level.
