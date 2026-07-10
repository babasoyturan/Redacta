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

output "aks_cluster_name" {
  description = "Production AKS cluster name."
  value       = module.aks.cluster_name
}

output "aks_oidc_issuer_url" {
  description = "Production AKS OIDC issuer URL."
  value       = module.aks.oidc_issuer_url
}

output "managed_grafana_endpoint" {
  description = "Production Managed Grafana endpoint."
  value       = module.observability.managed_grafana_endpoint
}

output "key_vault_uri" {
  description = "Production Key Vault URI."
  value       = module.key_vault.key_vault_uri
}

output "documents_storage_account_name" {
  description = "Production documents storage account name."
  value       = module.storage.storage_account_name
}

output "sql_server_fqdn" {
  description = "Production SQL server FQDN."
  value       = module.sql.sql_server_fqdn
}

output "workload_identity_client_ids" {
  description = "Production workload identity client IDs keyed by application component."
  value       = module.workload_identity.client_ids
}

output "workload_identity_service_account_names" {
  description = "Production workload identity Kubernetes service accounts keyed by application component."
  value       = module.workload_identity.service_account_names
}
