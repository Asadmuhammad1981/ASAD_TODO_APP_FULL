resource "azurerm_resource_group" "rg-frontend" {
  name     = "rg-frontend"
  location = "westus2"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "virtual-network-dev"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg-frontend.location
  resource_group_name = azurerm_resource_group.rg-frontend.name
}

resource "azurerm_subnet" "subnet1" {
  depends_on = [azurerm_virtual_network.vnet]
  name                 = "subnet-frontend-dev"
  resource_group_name  = azurerm_resource_group.rg-frontend.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet2" {
  depends_on = [azurerm_virtual_network.vnet]
  name                 = "subnet-backend-dev"
  resource_group_name  = azurerm_resource_group.rg-frontend.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "subnet3" {
  depends_on = [azurerm_virtual_network.vnet]
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg-frontend.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.4.0/26"]
}

resource "azurerm_network_interface" "nic1" {
  name                = "frontend-nic-dev"
  location            = azurerm_resource_group.rg-frontend.location
  resource_group_name = azurerm_resource_group.rg-frontend.name

  ip_configuration {
    name                          = "internal1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_interface" "nic2" {
  name                = "backend-nic-dev"
  location            = azurerm_resource_group.rg-frontend.location
  resource_group_name = azurerm_resource_group.rg-frontend.name

  ip_configuration {
    name                          = "internal2"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pip2.id
  }
}

# resource "tls_private_key" "ssh" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

#output "private_key" {
#  value     = tls_private_key.ssh.private_key_pem
#  sensitive = true
#}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "vm-frontend-dev"
  resource_group_name = azurerm_resource_group.rg-frontend.name
  location            = azurerm_resource_group.rg-frontend.location
  size                = "Standard_D2s_v3"
   admin_username      = nonsensitive(var.admin_username)
  admin_password = var.admin_password

   allow_extension_operations = true
   
 disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic1.id
  ]

  # admin_ssh_key {
  #   username   = "adminuser1"
  #  public_key = tls_private_key.ssh.public_key_openssh
  # }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts-gen2"   # ← Critical change
  version   = "latest"
}
}

resource "azurerm_network_security_group" "nsg1" {
  name                = "nsg-frontend-dev"
  location            = azurerm_resource_group.rg-frontend.location
  resource_group_name = azurerm_resource_group.rg-frontend.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "public-ip-frontend-dev"
  location            = azurerm_resource_group.rg-frontend.location
  resource_group_name = azurerm_resource_group.rg-frontend.name
  allocation_method   = "Static"   # Or "Dynamic"
  sku                 = "Standard" # ← Critical change

  lifecycle {
    create_before_destroy = true  # ← Add this block
  }

}

resource "azurerm_subnet_network_security_group_association" "nsga1" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

resource "azurerm_linux_virtual_machine" "vm2" {
  name                = "vm-backend-dev"
  resource_group_name = azurerm_resource_group.rg-frontend.name
  location            = azurerm_resource_group.rg-frontend.location
  size                = "Standard_D2s_v3"
  admin_username      = nonsensitive(var.admin_username)
  admin_password = var.admin_password

  allow_extension_operations = true

disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic2.id,
  ]

  # admin_ssh_key {
  #   username   = "adminuser2"
  #  public_key = tls_private_key.ssh.public_key_openssh
  # }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts-gen2"   # ← Critical change
  version   = "latest"
}
}

resource "azurerm_network_security_group" "nsg2" {
  name                = "nsg-backend-dev"
  location            = azurerm_resource_group.rg-frontend.location
  resource_group_name = azurerm_resource_group.rg-frontend.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_public_ip" "pip2" {
  name                = "public-ip-backendtend-dev"
  location            = azurerm_resource_group.rg-frontend.location
  resource_group_name = azurerm_resource_group.rg-frontend.name
  allocation_method   = "Static"   # Or "Dynamic"
  sku                 = "Standard" # ← Critical change

  lifecycle {
    create_before_destroy = true  # ← Add this block
  }

}

resource "azurerm_public_ip" "pip3" {
  name                = "public-ip-bastion-dev"
  location            = azurerm_resource_group.rg-frontend.location
  resource_group_name = azurerm_resource_group.rg-frontend.name
  allocation_method   = "Static"   # Or "Dynamic"
  sku                 = "Standard" # ← Critical change

  lifecycle {
    create_before_destroy = true  # ← Add this block
  }

}

resource "azurerm_subnet_network_security_group_association" "nsga2" {
  subnet_id                 = azurerm_subnet.subnet2.id
  network_security_group_id = azurerm_network_security_group.nsg2.id
}

# resource "local_file" "ssh_private_key" {
#   filename        = "${path.module}/id_rsa.pem"
#   content         = tls_private_key.ssh.private_key_pem
#   file_permission = "0600"
# }

resource "azurerm_mssql_server" "sqlserver" {
  name                         = "todo-dev-sqlserver"
  resource_group_name          = azurerm_resource_group.rg-frontend.name
  location                     = azurerm_resource_group.rg-frontend.location
  version                      = "12.0"
  administrator_login          = "AdminUser"
  administrator_login_password = "@Ericsson1212"
}

resource "azurerm_mssql_database" "sqldatabase" {
  name         = "todo-dev-db"
  server_id    = azurerm_mssql_server.sqlserver.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = "S0"
  enclave_type = "VBS"

  tags = {
    foo = "bar"
  }

  # prevent the possibility of accidental data loss
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_bastion_host" "Dev_bastion" {

  name                = "bastion-dev"
  location            = azurerm_resource_group.rg-frontend.location
  resource_group_name = azurerm_resource_group.rg-frontend.name

  ip_configuration {
    name                 = "bastion-ip-dev"
    subnet_id            = azurerm_subnet.subnet3.id
    public_ip_address_id = azurerm_public_ip.pip3.id
  }
}