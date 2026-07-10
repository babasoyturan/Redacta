variable "location" {
  type        = string
  description = "Azure region for development resources."
  default     = "swedencentral"
}

variable "resource_group_name" {
  type        = string
  description = "Development resource group name."
  default     = "rg-redacta-development"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to development resources."
  default     = {}
}

variable "name_prefix" {
  type        = string
  description = "Name prefix for development resources."
  default     = "redacta-dev-swec"
}

variable "address_space" {
  type        = list(string)
  description = "Development VNet address space."
  default     = ["10.20.0.0/16"]
}

variable "aks_subnet_address_prefixes" {
  type        = list(string)
  description = "Development AKS subnet CIDR ranges."
  default     = ["10.20.0.0/20"]
}

variable "application_gateway_subnet_address_prefixes" {
  type        = list(string)
  description = "Development Application Gateway subnet CIDR ranges."
  default     = ["10.20.16.0/24"]
}

variable "private_endpoint_subnet_address_prefixes" {
  type        = list(string)
  description = "Development private endpoint subnet CIDR ranges."
  default     = ["10.20.17.0/24"]
}

variable "application_gateway_min_capacity" {
  type        = number
  description = "Development Application Gateway minimum autoscale capacity."
  default     = 0
}

variable "application_gateway_max_capacity" {
  type        = number
  description = "Development Application Gateway maximum autoscale capacity."
  default     = 2
}
