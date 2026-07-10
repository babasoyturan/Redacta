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

output "aks_cluster_name" {
  description = "Development AKS cluster name."
  value       = module.aks.cluster_name
}

output "aks_oidc_issuer_url" {
  description = "Development AKS OIDC issuer URL."
  value       = module.aks.oidc_issuer_url
}

output "managed_grafana_endpoint" {
  description = "Development Managed Grafana endpoint."
  value       = module.observability.managed_grafana_endpoint
}

output "key_vault_uri" {
  description = "Development Key Vault URI."
  value       = module.key_vault.key_vault_uri
}

output "documents_storage_account_name" {
  description = "Development documents storage account name."
  value       = module.storage.storage_account_name
}
