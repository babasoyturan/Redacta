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

variable "waf_exclusions" {
  type = list(object({
    match_variable          = string
    selector                = string
    selector_match_operator = string
  }))
  description = "Managed rule exclusions for request fields that carry user document content."
  default     = []

  validation {
    condition = alltrue([
      for exclusion in var.waf_exclusions :
      contains([
        "RequestArgKeys",
        "RequestArgNames",
        "RequestArgValues",
        "RequestCookieKeys",
        "RequestCookieNames",
        "RequestCookieValues",
        "RequestHeaderKeys",
        "RequestHeaderNames",
        "RequestHeaderValues"
      ], exclusion.match_variable)
    ])
    error_message = "waf_exclusions match_variable must be a supported Application Gateway WAF exclusion variable."
  }

  validation {
    condition = alltrue([
      for exclusion in var.waf_exclusions :
      contains(["Contains", "EndsWith", "Equals", "EqualsAny", "StartsWith"], exclusion.selector_match_operator)
    ])
    error_message = "waf_exclusions selector_match_operator must be Contains, EndsWith, Equals, EqualsAny, or StartsWith."
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
