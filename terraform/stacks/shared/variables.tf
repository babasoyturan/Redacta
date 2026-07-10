variable "location" {
  type        = string
  description = "Azure region for shared resources."
  default     = "swedencentral"
}

variable "resource_group_name" {
  type        = string
  description = "Shared resource group name."
  default     = "rg-redacta-shared"
}

variable "acr_name" {
  type        = string
  description = "Globally unique Azure Container Registry name."
  default     = "acrredacta7t9"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.acr_name))
    error_message = "ACR name must be 5-50 alphanumeric characters."
  }
}

variable "acr_sku" {
  type        = string
  description = "Azure Container Registry SKU."
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}

variable "dns_zone_name" {
  type        = string
  description = "Public DNS zone name managed in the shared stack."
  default     = null
  nullable    = true
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to shared resources."
  default     = {}
}
