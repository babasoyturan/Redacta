resource "azurerm_resource_group" "shared" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_container_registry" "shared" {
  name                          = var.acr_name
  resource_group_name           = azurerm_resource_group.shared.name
  location                      = azurerm_resource_group.shared.location
  sku                           = var.acr_sku
  admin_enabled                 = false
  public_network_access_enabled = true
  tags                          = local.common_tags
}

resource "azurerm_dns_zone" "shared" {
  count = var.dns_zone_name == null || trimspace(var.dns_zone_name) == "" ? 0 : 1

  name                = var.dns_zone_name
  resource_group_name = azurerm_resource_group.shared.name
  tags                = local.common_tags
}
