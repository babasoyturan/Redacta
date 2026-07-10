variable "name_prefix" {
  type        = string
  description = "Prefix used for observability resources."
}

variable "location" {
  type        = string
  description = "Azure region for observability resources."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where observability resources are created."
}

variable "log_retention_in_days" {
  type        = number
  description = "Log Analytics retention in days."
  default     = 30
}

variable "daily_quota_gb" {
  type        = number
  description = "Daily ingestion quota in GB for Log Analytics. A negative value leaves the quota unlimited."
  default     = 1
}

variable "grafana_major_version" {
  type        = number
  description = "Managed Grafana major version supported by Azure for the selected SKU."
  default     = 12
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to observability resources."
  default     = {}
}
