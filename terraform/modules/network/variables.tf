variable "name_prefix" {
  type        = string
  description = "Prefix used for environment network resources."
}

variable "location" {
  type        = string
  description = "Azure region for network resources."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where network resources are created."
}

variable "address_space" {
  type        = list(string)
  description = "VNet address space."
}

variable "aks_subnet_address_prefixes" {
  type        = list(string)
  description = "AKS subnet CIDR ranges."
}

variable "application_gateway_subnet_address_prefixes" {
  type        = list(string)
  description = "Application Gateway subnet CIDR ranges."
}

variable "private_endpoint_subnet_address_prefixes" {
  type        = list(string)
  description = "Private endpoint subnet CIDR ranges."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to network resources."
  default     = {}
}
