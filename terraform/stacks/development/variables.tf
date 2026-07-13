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

variable "system_node_vm_size" {
  type        = string
  description = "Development system node VM size."
  default     = "Standard_B2s_v2"
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

variable "user_node_vm_size" {
  type        = string
  description = "Development user node VM size."
  default     = "Standard_B2s_v2"
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

variable "aks_rbac_cluster_admin_object_ids" {
  type        = set(string)
  description = "Additional Microsoft Entra object IDs granted AKS RBAC cluster admin access."
  default     = []
}

variable "platform_admin_object_ids" {
  type        = set(string)
  description = "Stable Microsoft Entra object IDs that keep platform admin access when Terraform runs from CI."
  default     = ["0000df1f-acd9-43ee-98a3-addd4f65b744"]
}

variable "sonarqube_address_space" {
  type        = list(string)
  description = "Development SonarQube tooling VNet address space."
  default     = ["10.40.0.0/24"]
}

variable "sonarqube_subnet_address_prefixes" {
  type        = list(string)
  description = "Development SonarQube tooling subnet CIDR ranges."
  default     = ["10.40.0.0/28"]
}

variable "sonarqube_allowed_source_ip_ranges" {
  type        = list(string)
  description = "CIDR ranges allowed to access development SonarQube VM SSH."
  default     = ["185.91.210.72/32"]
}

variable "sonarqube_dns_zone_name" {
  type        = string
  description = "DNS zone where the development SonarQube record is created."
  default     = "redacta.site"
}

variable "sonarqube_dns_record_name" {
  type        = string
  description = "DNS record name for development SonarQube."
  default     = "sonar"
}

variable "sonarqube_vm_size" {
  type        = string
  description = "VM size for development self-hosted SonarQube."
  default     = "Standard_B2s_v2"
}

variable "sonarqube_admin_username" {
  type        = string
  description = "Admin username for the development SonarQube VM."
  default     = "redactaadmin"
}

variable "sonarqube_image" {
  type        = string
  description = "SonarQube Docker image."
  default     = "sonarqube:community"
}

variable "sonarqube_os_disk_size_gb" {
  type        = number
  description = "Development SonarQube VM OS disk size."
  default     = 64
}
