output "storage_account_id" {
  description = "Storage account resource ID."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Storage account name."
  value       = azurerm_storage_account.this.name
}

output "documents_share_name" {
  description = "Documents Azure Files share name."
  value       = azurerm_storage_share.documents.name
}
