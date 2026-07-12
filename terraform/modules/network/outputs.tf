output "virtual_network_id" {
  description = "VNet resource ID."
  value       = azurerm_virtual_network.this.id
}

output "virtual_network_name" {
  description = "VNet name."
  value       = azurerm_virtual_network.this.name
}

output "aks_subnet_id" {
  description = "AKS subnet resource ID."
  value       = azurerm_subnet.aks.id
}

output "application_gateway_subnet_id" {
  description = "Application Gateway subnet resource ID."
  value       = azurerm_subnet.application_gateway.id
}

output "private_endpoint_subnet_id" {
  description = "Private endpoint subnet resource ID."
  value       = azurerm_subnet.private_endpoints.id
}
