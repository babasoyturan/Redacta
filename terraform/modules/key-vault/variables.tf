variable "name_prefix" {
  type        = string
  description = "Prefix used for Key Vault resources."
}

variable "location" {
  type        = string
  description = "Azure region for Key Vault resources."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where Key Vault resources are created."
}

variable "tenant_id" {
  type        = string
  description = "Microsoft Entra tenant ID."
}

variable "admin_object_ids" {
  type        = set(string)
  description = "Object IDs granted Key Vault Administrator on the vault."
}

variable "virtual_network_id" {
  type        = string
  description = "VNet ID linked to the Key Vault private DNS zone."
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID used by the Key Vault private endpoint."
}

variable "admin_ip_rules" {
  type        = list(string)
  description = "Public IP CIDR ranges allowed to administer Key Vault."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to Key Vault resources."
  default     = {}
}
