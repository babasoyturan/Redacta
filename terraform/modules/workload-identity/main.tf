resource "azurerm_user_assigned_identity" "this" {
  for_each = var.workload_identities

  name                = "id-${var.name_prefix}-${each.value.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "this" {
  for_each = var.workload_identities

  name                = "fic-${var.name_prefix}-${each.value.name_suffix}"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.this[each.key].id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.oidc_issuer_url
  subject             = "system:serviceaccount:${var.kubernetes_namespace}:${each.value.service_account_name}"
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  for_each = var.workload_identities

  scope                            = var.key_vault_id
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = azurerm_user_assigned_identity.this[each.key].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
