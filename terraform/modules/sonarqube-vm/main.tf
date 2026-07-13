resource "tls_private_key" "admin" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  name                 = "snet-${var.name_prefix}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.subnet_address_prefixes
}

resource "azurerm_network_security_group" "this" {
  name                = "nsg-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "AllowSshFromAdminIps"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.allowed_source_ip_ranges
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this.name
}

resource "azurerm_network_security_rule" "http" {
  name                        = "AllowHttpPublic"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = var.public_http_source_address_prefix
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this.name
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_public_ip" "this" {
  name                = "pip-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "this" {
  name                = "nic-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

locals {
  cloud_init = <<-CLOUD_INIT
    #cloud-config
    package_update: true
    packages:
      - docker.io
      - nginx
    write_files:
      - path: /etc/sysctl.d/99-sonarqube.conf
        owner: root:root
        permissions: "0644"
        content: |
          vm.max_map_count=262144
          fs.file-max=65536
      - path: /usr/local/bin/start-sonarqube.sh
        owner: root:root
        permissions: "0755"
        content: |
          #!/usr/bin/env bash
          set -euo pipefail
          sysctl --system
          systemctl enable --now docker
          systemctl enable --now nginx
          mkdir -p /opt/sonarqube/data /opt/sonarqube/extensions /opt/sonarqube/logs
          chown -R 1000:0 /opt/sonarqube
          docker rm -f sonarqube >/dev/null 2>&1 || true
          docker pull ${var.sonarqube_image}
          docker run -d \
            --name sonarqube \
            --restart unless-stopped \
            --ulimit nofile=131072:131072 \
            --ulimit nproc=8192:8192 \
            -p 127.0.0.1:9000:9000 \
            -v /opt/sonarqube/data:/opt/sonarqube/data \
            -v /opt/sonarqube/extensions:/opt/sonarqube/extensions \
            -v /opt/sonarqube/logs:/opt/sonarqube/logs \
            ${var.sonarqube_image}
          cat >/etc/nginx/sites-available/sonarqube <<'NGINX'
          server {
              listen 80 default_server;
              listen [::]:80 default_server;
              server_name _;

              client_max_body_size 64m;

              location / {
                  proxy_pass http://127.0.0.1:9000;
                  proxy_http_version 1.1;
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Proto $scheme;
              }
          }
          NGINX
          rm -f /etc/nginx/sites-enabled/default
          ln -sf /etc/nginx/sites-available/sonarqube /etc/nginx/sites-enabled/sonarqube
          nginx -t
          systemctl reload nginx
    runcmd:
      - /usr/local/bin/start-sonarqube.sh
  CLOUD_INIT
}

resource "azurerm_linux_virtual_machine" "this" {
  name                            = "vm-${var.name_prefix}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.this.id]
  custom_data                     = base64encode(local.cloud_init)
  tags                            = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.admin.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
