output "public_ip_address" {
  description = "Public IP address of the SonarQube VM."
  value       = azurerm_public_ip.this.ip_address
}

output "url" {
  description = "SonarQube URL."
  value       = "https://${var.sonarqube_hostname}"
}

output "admin_username" {
  description = "VM admin username."
  value       = var.admin_username
}

output "admin_private_key_pem" {
  description = "Generated SSH private key for the SonarQube VM admin user."
  value       = tls_private_key.admin.private_key_pem
  sensitive   = true
}
