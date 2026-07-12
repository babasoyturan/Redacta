variable "name_prefix" {
  type        = string
  description = "Prefix used for Application Gateway resources."
}

variable "location" {
  type        = string
  description = "Azure region for Application Gateway resources."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where Application Gateway resources are created."
}

variable "subnet_id" {
  type        = string
  description = "Dedicated Application Gateway subnet ID."
}

variable "waf_mode" {
  type        = string
  description = "WAF policy mode."

  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "waf_mode must be Detection or Prevention."
  }
}

variable "min_capacity" {
  type        = number
  description = "Minimum autoscale capacity for Application Gateway."
}

variable "max_capacity" {
  type        = number
  description = "Maximum autoscale capacity for Application Gateway."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to Application Gateway resources."
  default     = {}
}
