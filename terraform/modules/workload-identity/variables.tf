variable "name_prefix" {
  type        = string
  description = "Name prefix for workload identity resources."
}

variable "location" {
  type        = string
  description = "Azure region for workload identity resources."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for workload identity resources."
}

variable "oidc_issuer_url" {
  type        = string
  description = "AKS OIDC issuer URL."
}

variable "kubernetes_namespace" {
  type        = string
  description = "Kubernetes namespace containing the service accounts."
}

variable "key_vault_id" {
  type        = string
  description = "Key Vault resource ID where application secrets are stored."
}

variable "workload_identities" {
  type = map(object({
    name_suffix          = string
    service_account_name = string
  }))
  description = "Workload identities keyed by application component."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to workload identity resources."
  default     = {}
}
