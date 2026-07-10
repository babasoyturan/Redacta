variable "name_prefix" {
  type        = string
  description = "Prefix used for AKS resources."
}

variable "location" {
  type        = string
  description = "Azure region for AKS resources."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where AKS is created."
}

variable "tenant_id" {
  type        = string
  description = "Microsoft Entra tenant ID used for AKS Azure RBAC."
}

variable "aks_subnet_id" {
  type        = string
  description = "Subnet ID used by AKS node pools."
}

variable "application_gateway_id" {
  type        = string
  description = "Application Gateway ID used by the AKS-managed AGIC add-on."
}

variable "acr_id" {
  type        = string
  description = "ACR resource ID for AcrPull role assignment."
  default     = null
  nullable    = true
}

variable "api_server_authorized_ip_ranges" {
  type        = list(string)
  description = "Public CIDR ranges allowed to access the AKS API server."
}

variable "kubernetes_version" {
  type        = string
  description = "AKS Kubernetes version. Null lets Azure choose the default stable version."
  default     = null
  nullable    = true
}

variable "pod_cidr" {
  type        = string
  description = "Azure CNI Overlay pod CIDR."
}

variable "service_cidr" {
  type        = string
  description = "AKS service CIDR."
}

variable "dns_service_ip" {
  type        = string
  description = "AKS DNS service IP from the service CIDR."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID used by AKS Container Insights."
  default     = null
  nullable    = true
}

variable "managed_prometheus_enabled" {
  type        = bool
  description = "Enable AKS managed metrics collection."
  default     = true
}

variable "system_node_vm_size" {
  type        = string
  description = "VM size for the system node pool."
  default     = "Standard_B2als_v2"
}

variable "system_node_count" {
  type        = number
  description = "Initial node count for the system node pool."
}

variable "system_node_min_count" {
  type        = number
  description = "Minimum autoscaler count for the system node pool."
}

variable "system_node_max_count" {
  type        = number
  description = "Maximum autoscaler count for the system node pool."
}

variable "user_node_vm_size" {
  type        = string
  description = "VM size for the user node pool."
  default     = "Standard_B2als_v2"
}

variable "user_node_count" {
  type        = number
  description = "Initial node count for the user node pool."
}

variable "user_node_min_count" {
  type        = number
  description = "Minimum autoscaler count for the user node pool."
}

variable "user_node_max_count" {
  type        = number
  description = "Maximum autoscaler count for the user node pool."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to AKS resources."
  default     = {}
}
