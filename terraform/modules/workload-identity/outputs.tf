output "client_ids" {
  description = "Managed identity client IDs keyed by application component."
  value       = { for key, identity in azurerm_user_assigned_identity.this : key => identity.client_id }
}

output "principal_ids" {
  description = "Managed identity principal IDs keyed by application component."
  value       = { for key, identity in azurerm_user_assigned_identity.this : key => identity.principal_id }
}

output "service_account_names" {
  description = "Kubernetes service account names keyed by application component."
  value       = { for key, identity in var.workload_identities : key => identity.service_account_name }
}
