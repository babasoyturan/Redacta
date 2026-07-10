output "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID."
  value       = azurerm_log_analytics_workspace.this.id
}

output "monitor_workspace_id" {
  description = "Azure Monitor workspace resource ID."
  value       = azurerm_monitor_workspace.this.id
}

output "managed_grafana_id" {
  description = "Azure Managed Grafana resource ID."
  value       = azurerm_dashboard_grafana.this.id
}

output "managed_grafana_endpoint" {
  description = "Azure Managed Grafana endpoint."
  value       = azurerm_dashboard_grafana.this.endpoint
}
