resource "azurerm_mssql_server" "this" {
  name                          = var.sql_server_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = "12.0"
  administrator_login           = var.administrator_login
  administrator_login_password  = var.administrator_login_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  tags                          = var.tags
}

resource "azurerm_mssql_elasticpool" "this" {
  name                = "sqlep-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  server_name         = azurerm_mssql_server.this.name
  license_type        = "LicenseIncluded"
  tags                = var.tags

  sku {
    name     = "BasicPool"
    tier     = "Basic"
    capacity = var.elastic_pool_capacity
  }

  per_database_settings {
    min_capacity = var.per_database_min_capacity
    max_capacity = var.per_database_max_capacity
  }
}

resource "azurerm_mssql_database" "databases" {
  for_each = var.database_names

  name                 = each.value
  server_id            = azurerm_mssql_server.this.id
  elastic_pool_id      = azurerm_mssql_elasticpool.this.id
  max_size_gb          = 2
  collation            = "SQL_Latin1_General_CP1_CI_AS"
  geo_backup_enabled   = false
  storage_account_type = "Local"
  tags                 = var.tags

  short_term_retention_policy {
    retention_days = 7
  }
}

resource "azurerm_private_dns_zone" "this" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "pdnslink-${var.name_prefix}-sql"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "this" {
  name                = "pe-${var.name_prefix}-sql"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.name_prefix}-sql"
    private_connection_resource_id = azurerm_mssql_server.this.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.this.id]
  }
}
