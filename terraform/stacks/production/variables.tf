variable "location" {
  type        = string
  description = "Azure region for production resources."
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
