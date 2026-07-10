locals {
  admin_ip_rules = [for rule in var.admin_ip_rules : replace(rule, "/32", "")]
}

resource "azurerm_storage_account" "this" {
  name                            = var.storage_account_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
  shared_access_key_enabled       = true
  large_file_share_enabled        = true
  tags                            = var.tags

  network_rules {
    bypass         = ["AzureServices"]
    default_action = "Deny"
    ip_rules       = local.admin_ip_rules
  }

  share_properties {
    retention_policy {
      days = 14
    }
  }
}

resource "azurerm_storage_share" "documents" {
  name               = "redacta-documents"
  storage_account_id = azurerm_storage_account.this.id
  quota              = var.documents_share_quota_gb
  access_tier        = "TransactionOptimized"
}

resource "azurerm_private_dns_zone" "files" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "files" {
  name                  = "pdnslink-${var.name_prefix}-files"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.files.name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "files" {
  name                = "pe-${var.name_prefix}-files"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.name_prefix}-files"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.files.id]
  }
}
