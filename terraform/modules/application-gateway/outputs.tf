output "application_gateway_id" {
  description = "Application Gateway resource ID."
  value       = azurerm_application_gateway.this.id
}

output "application_gateway_name" {
  description = "Application Gateway name."
  value       = azurerm_application_gateway.this.name
}

output "public_ip_id" {
  description = "Application Gateway public IP resource ID."
  value       = azurerm_public_ip.this.id
}

output "public_ip_address" {
  description = "Application Gateway public IP address."
  value       = azurerm_public_ip.this.ip_address
}

output "waf_policy_id" {
  description = "WAF policy resource ID."
  value       = azurerm_web_application_firewall_policy.this.id
}
