resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_in_days
  daily_quota_gb      = var.daily_quota_gb
  tags                = var.tags
}

resource "azurerm_monitor_workspace" "this" {
  name                          = "amw-${var.name_prefix}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  public_network_access_enabled = true
  tags                          = var.tags
}

resource "azurerm_dashboard_grafana" "this" {
  name                              = "graf-${var.name_prefix}"
  location                          = var.location
  resource_group_name               = var.resource_group_name
  grafana_major_version             = 11
  api_key_enabled                   = false
  deterministic_outbound_ip_enabled = true
  public_network_access_enabled     = true
  sku                               = "Standard"
  tags                              = var.tags

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.this.id
  }
}

resource "azurerm_role_assignment" "grafana_monitor_reader" {
  scope                = azurerm_monitor_workspace.this.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.this.identity[0].principal_id
}
