output "resource_group_name" {
  value = azurerm_resource_group.shared.name
}

output "acr_name" {
  value = azurerm_container_registry.shared.name
}

output "acr_id" {
  value = azurerm_container_registry.shared.id
}

output "acr_login_server" {
  value = azurerm_container_registry.shared.login_server
}

output "dns_zone_name" {
  value = try(azurerm_dns_zone.shared[0].name, null)
}

output "dns_zone_name_servers" {
  value = try(azurerm_dns_zone.shared[0].name_servers, null)
}

output "github_actions_acr_push_client_id" {
  description = "Client ID used by GitHub Actions OIDC jobs to push Redacta images to ACR."
  value       = azurerm_user_assigned_identity.github_actions_acr_push.client_id
}

output "github_actions_acr_push_principal_id" {
  description = "Principal ID assigned AcrPush on the shared ACR."
  value       = azurerm_user_assigned_identity.github_actions_acr_push.principal_id
}

output "github_actions_federated_subjects" {
  description = "GitHub OIDC subjects allowed to use the ACR push identity."
  value       = local.github_actions_federated_subjects
}

output "github_actions_terraform_client_ids" {
  description = "Client IDs used by GitHub Actions OIDC jobs to run Terraform."
  value       = { for key, identity in azurerm_user_assigned_identity.github_actions_terraform : key => identity.client_id }
}

output "github_actions_terraform_principal_ids" {
  description = "Principal IDs used by GitHub Actions OIDC jobs to run Terraform."
  value       = { for key, identity in azurerm_user_assigned_identity.github_actions_terraform : key => identity.principal_id }
}

output "github_actions_terraform_subjects" {
  description = "GitHub OIDC subjects allowed to use the Terraform identities."
  value       = local.github_actions_terraform_subjects
}
