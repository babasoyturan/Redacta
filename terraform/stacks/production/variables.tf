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

variable "application_namespace" {
  type        = string
  description = "Kubernetes namespace for the production Redacta application."
  default     = "redacta"
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
  default     = 0
}

variable "application_gateway_max_capacity" {
  type        = number
  description = "Production Application Gateway maximum autoscale capacity."
  default     = 2
}

variable "tfstate_storage_account_name" {
  type        = string
  description = "Terraform state storage account used for cross-stack outputs."
  default     = "stredactatfstate7t9"
}

variable "api_server_authorized_ip_ranges" {
  type        = list(string)
  description = "CIDR ranges allowed to access the production AKS API server."
}

variable "pod_cidr" {
  type        = string
  description = "Production AKS overlay pod CIDR."
  default     = "10.245.0.0/16"
}

variable "service_cidr" {
  type        = string
  description = "Production AKS service CIDR."
  default     = "10.31.0.0/16"
}

variable "dns_service_ip" {
  type        = string
  description = "Production AKS DNS service IP."
  default     = "10.31.0.10"
}

variable "system_node_count" {
  type        = number
  description = "Production system node initial count."
  default     = 1
}

variable "system_node_min_count" {
  type        = number
  description = "Production system node minimum count."
  default     = 1
}

variable "system_node_max_count" {
  type        = number
  description = "Production system node maximum count."
  default     = 1
}

variable "user_node_count" {
  type        = number
  description = "Production user node initial count."
  default     = 1
}

variable "user_node_min_count" {
  type        = number
  description = "Production user node minimum count."
  default     = 1
}

variable "user_node_max_count" {
  type        = number
  description = "Production user node maximum count."
  default     = 1
}

variable "storage_account_name" {
  type        = string
  description = "Production storage account name."
  default     = "stredactaprod7t9"
}

variable "sql_server_name" {
  type        = string
  description = "Production Azure SQL logical server name."
  default     = "sql-redacta-prod-7t9"
}

variable "sql_administrator_login_password" {
  type        = string
  description = "Production SQL administrator password supplied from secure automation."
  sensitive   = true
}
