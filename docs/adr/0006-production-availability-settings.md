# ADR 0006: Production Availability Settings

## Status

Accepted

## Context

Production must present an availability story that is stronger than a single pod per service. Development can remain smaller because it is used for validation and cost control.

## Decision

Production cloud values set Redacta application services to three replicas, enable HPA with a minimum of three replicas and a maximum of five replicas, apply PodDisruptionBudgets with `minAvailable: 2`, and use topology spread constraints across nodes where capacity allows. Development keeps one replica per service to reduce cost.

## Consequences

Production can tolerate individual pod failures and rolling updates more credibly. The tradeoff is higher production compute usage, so node pool capacity and Azure quota must be monitored when production is active.
