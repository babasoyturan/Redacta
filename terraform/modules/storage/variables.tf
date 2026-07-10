variable "name_prefix" {
  type        = string
  description = "Prefix used for storage resources."
}

variable "location" {
  type        = string
  description = "Azure region for storage resources."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where storage resources are created."
}

variable "storage_account_name" {
  type        = string
  description = "Globally unique storage account name."

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "virtual_network_id" {
  type        = string
  description = "VNet ID linked to the Azure Files private DNS zone."
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID used by the Azure Files private endpoint."
}

variable "admin_ip_rules" {
  type        = list(string)
  description = "Public IP CIDR ranges allowed to administer the storage account."
  default     = []
}

variable "documents_share_quota_gb" {
  type        = number
  description = "Azure Files quota for document storage."
  default     = 20
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to storage resources."
  default     = {}
}
