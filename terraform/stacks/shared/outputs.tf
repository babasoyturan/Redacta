output "resource_group_name" {
  value = azurerm_resource_group.shared.name
}

output "acr_name" {
  value = azurerm_container_registry.shared.name
}

output "acr_id" {
  value = azurerm_container_registry.shared.id
}

output "acr_login_server" {
  value = azurerm_container_registry.shared.login_server
}

output "dns_zone_name" {
  value = try(azurerm_dns_zone.shared[0].name, null)
}

output "dns_zone_name_servers" {
  value = try(azurerm_dns_zone.shared[0].name_servers, null)
}
