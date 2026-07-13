output "resource_group_name" {
  value = data.azurerm_resource_group.development.name
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

output "application_gateway_name" {
  description = "Development Application Gateway name."
  value       = module.application_gateway.application_gateway_name
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

output "sonarqube_url" {
  description = "Development SonarQube URL."
  value       = "http://${var.sonarqube_dns_record_name}.${var.sonarqube_dns_zone_name}"
}

output "sonarqube_public_ip_address" {
  description = "Development SonarQube public IP address."
  value       = module.sonarqube.public_ip_address
}

output "sonarqube_admin_username" {
  description = "Development SonarQube VM admin username."
  value       = module.sonarqube.admin_username
}

output "sonarqube_admin_private_key_pem" {
  description = "Generated SSH private key for the development SonarQube VM admin user."
  value       = module.sonarqube.admin_private_key_pem
  sensitive   = true
}

output "key_vault_uri" {
  description = "Development Key Vault URI."
  value       = module.key_vault.key_vault_uri
}

output "key_vault_name" {
  description = "Development Key Vault name."
  value       = module.key_vault.key_vault_name
}

output "documents_storage_account_name" {
  description = "Development documents storage account name."
  value       = module.storage.storage_account_name
}

output "documents_share_name" {
  description = "Development Azure Files share name."
  value       = module.storage.documents_share_name
}

output "sql_server_name" {
  description = "Development SQL logical server name."
  value       = module.sql.sql_server_name
}

output "sql_server_fqdn" {
  description = "Development SQL server FQDN."
  value       = module.sql.sql_server_fqdn
}

output "workload_identity_client_ids" {
  description = "Development workload identity client IDs keyed by application component."
  value       = module.workload_identity.client_ids
}

output "workload_identity_service_account_names" {
  description = "Development workload identity Kubernetes service accounts keyed by application component."
  value       = module.workload_identity.service_account_names
}
