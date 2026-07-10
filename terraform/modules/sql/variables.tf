variable "name_prefix" {
  type        = string
  description = "Prefix used for SQL resources."
}

variable "location" {
  type        = string
  description = "Azure region for SQL resources."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where SQL resources are created."
}

variable "sql_server_name" {
  type        = string
  description = "Globally unique Azure SQL logical server name."
}

variable "administrator_login" {
  type        = string
  description = "Azure SQL server administrator login."
  default     = "redactasqladmin"
}

variable "administrator_login_password" {
  type        = string
  description = "Azure SQL server administrator password supplied from secure automation."
  sensitive   = true
}

variable "virtual_network_id" {
  type        = string
  description = "VNet ID linked to the Azure SQL private DNS zone."
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID used by the Azure SQL private endpoint."
}

variable "database_names" {
  type        = set(string)
  description = "Databases created in the environment SQL elastic pool."
  default = [
    "documentdb",
    "authdb",
    "anonymizationdb",
    "keycloakdb"
  ]
}

variable "elastic_pool_capacity" {
  type        = number
  description = "Elastic pool capacity."
  default     = 50
}

variable "elastic_pool_max_size_gb" {
  type        = number
  description = "Maximum storage size for the SQL elastic pool."
  default     = 4.8828125
}

variable "per_database_min_capacity" {
  type        = number
  description = "Minimum DTU capacity per database."
  default     = 0
}

variable "per_database_max_capacity" {
  type        = number
  description = "Maximum DTU capacity per database."
  default     = 5
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to SQL resources."
  default     = {}
}
