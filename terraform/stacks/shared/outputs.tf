output "resource_group_name" {
  value = azurerm_resource_group.shared.name
}

output "acr_name" {
  value = azurerm_container_registry.shared.name
}

output "acr_login_server" {
  value = azurerm_container_registry.shared.login_server
}

output "dns_zone_name" {
  value = azurerm_dns_zone.shared.name
}

output "dns_zone_name_servers" {
  value = azurerm_dns_zone.shared.name_servers
}
