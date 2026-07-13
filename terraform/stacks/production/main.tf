data "azurerm_client_config" "current" {}

data "terraform_remote_state" "shared" {
  backend = "azurerm"

  config = {
    resource_group_name  = "rg-redacta-tfstate"
    storage_account_name = var.tfstate_storage_account_name
    container_name       = "tfstate"
    key                  = "shared/terraform.tfstate"
  }
}

data "azurerm_resource_group" "production" {
  name = var.resource_group_name
}

module "network" {
  source = "../../modules/network"

  name_prefix                                 = var.name_prefix
  location                                    = data.azurerm_resource_group.production.location
  resource_group_name                         = data.azurerm_resource_group.production.name
  address_space                               = var.address_space
  aks_subnet_address_prefixes                 = var.aks_subnet_address_prefixes
  application_gateway_subnet_address_prefixes = var.application_gateway_subnet_address_prefixes
  private_endpoint_subnet_address_prefixes    = var.private_endpoint_subnet_address_prefixes
  tags                                        = local.common_tags
}

module "application_gateway" {
  source = "../../modules/application-gateway"

  name_prefix         = var.name_prefix
  location            = data.azurerm_resource_group.production.location
  resource_group_name = data.azurerm_resource_group.production.name
  subnet_id           = module.network.application_gateway_subnet_id
  waf_mode            = "Prevention"
  waf_exclusions      = local.waf_document_content_exclusions
  min_capacity        = var.application_gateway_min_capacity
  max_capacity        = var.application_gateway_max_capacity
  tags                = local.common_tags
}

module "observability" {
  source = "../../modules/observability"

  name_prefix              = var.name_prefix
  location                 = data.azurerm_resource_group.production.location
  resource_group_name      = data.azurerm_resource_group.production.name
  grafana_admin_object_ids = local.platform_admin_object_ids
  tags                     = local.common_tags
}

module "key_vault" {
  source = "../../modules/key-vault"

  name_prefix                = var.name_prefix
  location                   = data.azurerm_resource_group.production.location
  resource_group_name        = data.azurerm_resource_group.production.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  admin_object_ids           = local.platform_admin_object_ids
  virtual_network_id         = module.network.virtual_network_id
  private_endpoint_subnet_id = module.network.private_endpoint_subnet_id
  admin_ip_rules             = var.api_server_authorized_ip_ranges
  tags                       = local.common_tags
}

module "storage" {
  source = "../../modules/storage"

  name_prefix                = var.name_prefix
  location                   = data.azurerm_resource_group.production.location
  resource_group_name        = data.azurerm_resource_group.production.name
  storage_account_name       = var.storage_account_name
  virtual_network_id         = module.network.virtual_network_id
  private_endpoint_subnet_id = module.network.private_endpoint_subnet_id
  admin_ip_rules             = var.api_server_authorized_ip_ranges
  tags                       = local.common_tags
}

module "sql" {
  source = "../../modules/sql"

  name_prefix                  = var.name_prefix
  location                     = data.azurerm_resource_group.production.location
  resource_group_name          = data.azurerm_resource_group.production.name
  sql_server_name              = var.sql_server_name
  administrator_login_password = var.sql_administrator_login_password
  virtual_network_id           = module.network.virtual_network_id
  private_endpoint_subnet_id   = module.network.private_endpoint_subnet_id
  tags                         = local.common_tags
}

module "aks" {
  source = "../../modules/aks"

  name_prefix                     = var.name_prefix
  location                        = data.azurerm_resource_group.production.location
  resource_group_name             = data.azurerm_resource_group.production.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  aks_subnet_id                   = module.network.aks_subnet_id
  application_gateway_id          = module.application_gateway.application_gateway_id
  acr_id                          = data.terraform_remote_state.shared.outputs.acr_id
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges
  pod_cidr                        = var.pod_cidr
  service_cidr                    = var.service_cidr
  dns_service_ip                  = var.dns_service_ip
  log_analytics_workspace_id      = module.observability.log_analytics_workspace_id
  system_node_vm_size             = var.system_node_vm_size
  system_node_count               = var.system_node_count
  system_node_min_count           = var.system_node_min_count
  system_node_max_count           = var.system_node_max_count
  user_node_vm_size               = var.user_node_vm_size
  user_node_count                 = var.user_node_count
  user_node_min_count             = var.user_node_min_count
  user_node_max_count             = var.user_node_max_count
  tags                            = local.common_tags
}

resource "azurerm_role_assignment" "aks_rbac_cluster_admin" {
  for_each = setunion(var.aks_rbac_cluster_admin_object_ids, local.platform_admin_object_ids)

  scope                = module.aks.cluster_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "agic_resource_group_reader" {
  scope                = data.azurerm_resource_group.production.id
  role_definition_name = "Reader"
  principal_id         = module.aks.ingress_application_gateway_identity_object_id
}

resource "azurerm_role_assignment" "agic_resource_group_network_contributor" {
  scope                = data.azurerm_resource_group.production.id
  role_definition_name = "Network Contributor"
  principal_id         = module.aks.ingress_application_gateway_identity_object_id
}

resource "azurerm_role_assignment" "agic_application_gateway_contributor" {
  scope                = module.application_gateway.application_gateway_id
  role_definition_name = "Contributor"
  principal_id         = module.aks.ingress_application_gateway_identity_object_id
}

module "workload_identity" {
  source = "../../modules/workload-identity"

  name_prefix          = var.name_prefix
  location             = data.azurerm_resource_group.production.location
  resource_group_name  = data.azurerm_resource_group.production.name
  oidc_issuer_url      = module.aks.oidc_issuer_url
  kubernetes_namespace = local.application_namespace
  key_vault_id         = module.key_vault.key_vault_id
  workload_identities  = local.workload_identities
  tags                 = local.common_tags
}
