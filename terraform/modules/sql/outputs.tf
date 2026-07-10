output "sql_server_id" {
  description = "Azure SQL logical server resource ID."
  value       = azurerm_mssql_server.this.id
}

output "sql_server_name" {
  description = "Azure SQL logical server name."
  value       = azurerm_mssql_server.this.name
}

output "sql_server_fqdn" {
  description = "Azure SQL server FQDN."
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "database_names" {
  description = "Created database names."
  value       = keys(azurerm_mssql_database.databases)
}
