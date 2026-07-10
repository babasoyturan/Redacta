variable "location" {
  type        = string
  description = "Azure region for production resources."
  default     = "swedencentral"
}

variable "resource_group_name" {
  type        = string
  description = "Production resource group name."
  default     = "rg-redacta-production"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to production resources."
  default     = {}
}

variable "name_prefix" {
  type        = string
  description = "Name prefix for production resources."
  default     = "redacta-prod-swec"
}

variable "address_space" {
  type        = list(string)
  description = "Production VNet address space."
  default     = ["10.30.0.0/16"]
}

variable "aks_subnet_address_prefixes" {
  type        = list(string)
  description = "Production AKS subnet CIDR ranges."
  default     = ["10.30.0.0/20"]
}

variable "application_gateway_subnet_address_prefixes" {
  type        = list(string)
  description = "Production Application Gateway subnet CIDR ranges."
  default     = ["10.30.16.0/24"]
}

variable "private_endpoint_subnet_address_prefixes" {
  type        = list(string)
  description = "Production private endpoint subnet CIDR ranges."
  default     = ["10.30.17.0/24"]
}

variable "application_gateway_min_capacity" {
  type        = number
  description = "Production Application Gateway minimum autoscale capacity."
  default     = 1
}

variable "application_gateway_max_capacity" {
  type        = number
  description = "Production Application Gateway maximum autoscale capacity."
  default     = 4
}
