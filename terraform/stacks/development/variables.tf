variable "location" {
  type        = string
  description = "Azure region for development resources."
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
