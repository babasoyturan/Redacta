output "resource_group_name" {
  value = azurerm_resource_group.development.name
}
output "virtual_network_id" {
  description = "Development VNet resource ID."
  value       = module.network.virtual_network_id
}

output "aks_subnet_id" {
  description = "Development AKS subnet resource ID."
  value       = module.network.aks_subnet_id
}

output "application_gateway_id" {
  description = "Development Application Gateway resource ID."
  value       = module.application_gateway.application_gateway_id
}

output "application_gateway_public_ip_address" {
  description = "Development Application Gateway public IP address."
  value       = module.application_gateway.public_ip_address
}
