resource "azurerm_resource_group" "development" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

module "network" {
  source = "../../modules/network"

  name_prefix                                 = var.name_prefix
  location                                    = azurerm_resource_group.development.location
  resource_group_name                         = azurerm_resource_group.development.name
  address_space                               = var.address_space
  aks_subnet_address_prefixes                 = var.aks_subnet_address_prefixes
  application_gateway_subnet_address_prefixes = var.application_gateway_subnet_address_prefixes
  private_endpoint_subnet_address_prefixes    = var.private_endpoint_subnet_address_prefixes
  tags                                        = local.common_tags
}

module "application_gateway" {
  source = "../../modules/application-gateway"

  name_prefix         = var.name_prefix
  location            = azurerm_resource_group.development.location
  resource_group_name = azurerm_resource_group.development.name
  subnet_id           = module.network.application_gateway_subnet_id
  waf_mode            = "Detection"
  min_capacity        = var.application_gateway_min_capacity
  max_capacity        = var.application_gateway_max_capacity
  tags                = local.common_tags
}
