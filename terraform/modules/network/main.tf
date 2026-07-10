resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-${var.name_prefix}-aks"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.aks_subnet_address_prefixes
}

resource "azurerm_subnet" "application_gateway" {
  name                 = "snet-${var.name_prefix}-agw"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.application_gateway_subnet_address_prefixes
}

resource "azurerm_subnet" "private_endpoints" {
  name                              = "snet-${var.name_prefix}-pe"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = var.private_endpoint_subnet_address_prefixes
  private_endpoint_network_policies = "Disabled"
}
