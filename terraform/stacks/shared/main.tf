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

resource "azurerm_user_assigned_identity" "github_actions_acr_push" {
  name                = "id-redacta-github-acr-push-swec"
  resource_group_name = azurerm_resource_group.shared.name
  location            = azurerm_resource_group.shared.location
  tags                = local.common_tags
}

resource "azurerm_role_assignment" "github_actions_acr_push" {
  scope                            = azurerm_container_registry.shared.id
  role_definition_name             = "AcrPush"
  principal_id                     = azurerm_user_assigned_identity.github_actions_acr_push.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_federated_identity_credential" "github_actions_acr_push" {
  for_each = local.github_actions_federated_subjects

  name                      = "fic-redacta-gha-${each.key}"
  user_assigned_identity_id = azurerm_user_assigned_identity.github_actions_acr_push.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = each.value
}

resource "azurerm_dns_zone" "shared" {
  count = var.dns_zone_name == null || trimspace(var.dns_zone_name) == "" ? 0 : 1

  name                = var.dns_zone_name
  resource_group_name = azurerm_resource_group.shared.name
  tags                = local.common_tags
}
