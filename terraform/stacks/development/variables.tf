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

variable "application_namespace" {
  type        = string
  description = "Kubernetes namespace for the development Redacta application."
  default     = "redacta"
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

variable "tfstate_storage_account_name" {
  type        = string
  description = "Terraform state storage account used for cross-stack outputs."
  default     = "stredactatfstate7t9"
}

variable "api_server_authorized_ip_ranges" {
  type        = list(string)
  description = "CIDR ranges allowed to access the development AKS API server."
}

variable "pod_cidr" {
  type        = string
  description = "Development AKS overlay pod CIDR."
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  type        = string
  description = "Development AKS service CIDR."
  default     = "10.21.0.0/16"
}

variable "dns_service_ip" {
  type        = string
  description = "Development AKS DNS service IP."
  default     = "10.21.0.10"
}

variable "system_node_count" {
  type        = number
  description = "Development system node initial count."
  default     = 1
}

variable "system_node_min_count" {
  type        = number
  description = "Development system node minimum count."
  default     = 1
}

variable "system_node_max_count" {
  type        = number
  description = "Development system node maximum count."
  default     = 1
}

variable "user_node_count" {
  type        = number
  description = "Development user node initial count."
  default     = 1
}

variable "user_node_min_count" {
  type        = number
  description = "Development user node minimum count."
  default     = 1
}

variable "user_node_max_count" {
  type        = number
  description = "Development user node maximum count."
  default     = 1
}

variable "storage_account_name" {
  type        = string
  description = "Development storage account name."
  default     = "stredactadev7t9"
}

variable "sql_server_name" {
  type        = string
  description = "Development Azure SQL logical server name."
  default     = "sql-redacta-dev-7t9"
}

variable "sql_administrator_login_password" {
  type        = string
  description = "Development SQL administrator password supplied from secure automation."
  sensitive   = true
}
