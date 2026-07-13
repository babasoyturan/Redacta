variable "name_prefix" {
  type        = string
  description = "Prefix used for SonarQube VM resources."
}

variable "location" {
  type        = string
  description = "Azure region for SonarQube resources."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where SonarQube resources are created."
}

variable "address_space" {
  type        = list(string)
  description = "VNet address space for SonarQube tooling."
}

variable "subnet_address_prefixes" {
  type        = list(string)
  description = "Subnet CIDR ranges for the SonarQube VM."
}

variable "allowed_source_ip_ranges" {
  type        = list(string)
  description = "CIDR ranges allowed to access SSH."
}

variable "vm_size" {
  type        = string
  description = "Azure VM size for the SonarQube VM."
}

variable "admin_username" {
  type        = string
  description = "Admin username for the SonarQube VM."
}

variable "sonarqube_image" {
  type        = string
  description = "SonarQube Docker image to run."
}

variable "public_http_source_address_prefix" {
  type        = string
  description = "Source address prefix allowed to access the public SonarQube HTTP endpoint."
  default     = "*"
}

variable "os_disk_size_gb" {
  type        = number
  description = "OS disk size in GB."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to SonarQube resources."
  default     = {}
}
