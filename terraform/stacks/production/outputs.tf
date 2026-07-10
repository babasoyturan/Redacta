output "resource_group_name" {
  value = azurerm_resource_group.production.name
}
output "virtual_network_id" {
  description = "Production VNet resource ID."
  value       = module.network.virtual_network_id
}

output "aks_subnet_id" {
  description = "Production AKS subnet resource ID."
  value       = module.network.aks_subnet_id
}

output "application_gateway_id" {
  description = "Production Application Gateway resource ID."
  value       = module.application_gateway.application_gateway_id
}

output "application_gateway_public_ip_address" {
  description = "Production Application Gateway public IP address."
  value       = module.application_gateway.public_ip_address
}
