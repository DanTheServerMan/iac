# Defines the name of our resource group
# Defines the location of this resource group
resource "azurerm_resource_group" "terraform-minecraft" {
  name     = "terraform-minecraft"
  location = "eastus"
}

# Next we're going to request a static public IP
resource "azurerm_public_ip" "terraform-minecraft-publicip" {
  name                = "terraform-minecraft-publicip"
  resource_group_name = azurerm_resource_group.terraform-minecraft.name
  location            = azurerm_resource_group.terraform-minecraft.location
  allocation_method   = "Static"
}

# Defines the vnet for internal use
resource "azurerm_virtual_network" "terraform-minecraft-vnet-internal" {
  name                = "terraform-minecraft-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.terraform-minecraft.location
  resource_group_name = azurerm_resource_group.terraform-minecraft.name
}

resource "azurerm_subnet" "terraform-minecraft-subnet-internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.terraform-minecraft.name
  virtual_network_name = azurerm_virtual_network.terraform-minecraft-vnet-internal.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "terraform-minecraft-nic" {
  name                = "terraform-minecraft-nic"
  location            = azurerm_resource_group.terraform-minecraft.location
  resource_group_name = azurerm_resource_group.terraform-minecraft.name

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.terraform-minecraft-subnet-internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terraform-minecraft-publicip.id
  }
}

resource "azurerm_network_security_group" "terraform-minecraft-nsg" {
  name                = "terraform-minecraft-nsg"
  location            = azurerm_resource_group.terraform-minecraft.location
  resource_group_name = azurerm_resource_group.terraform-minecraft.name

  security_rule {
    name                       = "Allow-SSH-From-Specific-IP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.whitelist_ip
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "Allow-Minecraft-From-Specific-IP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "25565"
    source_address_prefix      = var.whitelist_ip 
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "terraform-minecraft-nic-nsg" {
  network_interface_id      = azurerm_network_interface.terraform-minecraft-nic.id
  network_security_group_id = azurerm_network_security_group.terraform-minecraft-nsg.id
}

resource "azurerm_linux_virtual_machine" "minecraft-server" {
  name                = "minecraft-vm"
  resource_group_name = azurerm_resource_group.terraform-minecraft.name
  location            = azurerm_resource_group.terraform-minecraft.location
  size                = "Standard_F2s_v2"
  admin_username      = var.username
  zone                = "1"
  network_interface_ids = [
    azurerm_network_interface.terraform-minecraft-nic.id,
  ]

  admin_ssh_key {
    username   = var.username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

# Failing to have a sleep here can cause the playbook to fail, as the VM is still booting, returning "Connection refused"
# Adding in a arg to accept new host keys, by default it will sit and wait for you to accept the new key. If you don't sit and watch it'll cause a timeout.
  provisioner "local-exec" {
    command = "sleep 10 && ansible-playbook -i ${azurerm_linux_virtual_machine.minecraft-server.public_ip_address}, -u var.username --private-key ~/.ssh/id_rsa ../ansible/configure-minecraft.yml --ssh-common-args='-o StrictHostKeyChecking=accept-new'"
  }
}