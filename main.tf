provider "azurerm" {
  features {}
  subscription_id = "a30a52db-8113-40dc-8278-de0b99f07a57"
}

resource "azurerm_resource_group" "terraform_rg1" {
  name     = "terraform_rg_azure_1"
  location = "Central India"
}


# Define the virtual network
resource "azurerm_virtual_network" "ample" {
  name                = "ample-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.terraform_rg1.location
  resource_group_name = azurerm_resource_group.terraform_rg1.name
}

# Define the subnet
resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.terraform_rg1.name
  virtual_network_name = azurerm_virtual_network.ample.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "example-public-ip"
  location            = azurerm_resource_group.terraform_rg1.location
  resource_group_name = azurerm_resource_group.terraform_rg1.name
  allocation_method   = "Static"
}

# Define the network interface
resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.terraform_rg1.location
  resource_group_name = azurerm_resource_group.terraform_rg1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "example-vm"
  resource_group_name = azurerm_resource_group.terraform_rg1.name
  location            = azurerm_resource_group.terraform_rg1.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  network_interface_ids = [azurerm_network_interface.example.id]

  # Define the OS disk configuration
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest" # You can specify the latest version or a fixed version if needed
  }
}

output "public_ip" {
  value = azurerm_public_ip.example.ip_address
}
