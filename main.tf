resource "azurerm_resource_group" "RG" {
  name     = "web-RG"
  location = var.location
}

#  calling the subnet
data "azurerm_subnet" "subnet" {
  name                 = var.subnet
  virtual_network_name = "VNet-App-NP"
  resource_group_name  = "resource_group-App-NP"

}
# create the publicIp address

resource "azurerm_public_ip" "public_ip" {
  name                = "PIP-IP"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method   = "Dynamic"
}

# create the NIC

resource "azurerm_network_interface" "NIC" {
  name                = "Web-NIC"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  ip_configuration {
    name                          = "IPConfig"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}
// create a new VM 

resource "azurerm_virtual_machine" "main" {
  name                  = "cia-dc"
  location              = azurerm_resource_group.RG.location
  resource_group_name   = azurerm_resource_group.RG.name
  network_interface_ids = [azurerm_network_interface.NIC.id]
  vm_size               = var.size

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "VM-OSDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "VM-OSDisk"
    admin_username = var.username
    admin_password = var.password
  }
  os_profile_windows_config {
    provision_vm_agent = true
  }
  tags = {
    environment = "Non-production"
    testing     = "true"
  }
}
# add data disk

# resource "azurerm_managed_disk" "data_disk" {
#   count                = var.vmcount
#   name                 = "datadisk-${var.server_type}-${var.env}"
#   location             = azurerm_resource_group.RG.location
#   resource_group_name  = azurerm_resource_group.RG.name
#   storage_account_type = "Standard_LRS"
#   create_option        = "Empty"
#   disk_size_gb         = 16
# }

# install nginx and ansible on the virtual machine using file URIs

# resource "azurerm_virtual_machine_extension" "nginx_ansible" {
#   count                      = var.vmcount
#   name                       = "nginx-ansible"
#   virtual_machine_id         = element(azurerm_virtual_machine.main.*.id, count.index)
#   publisher                  = "Microsoft.Azure.Extensions"
#   type                       = "CustomScript"
#   type_handler_version       = "2.1"
#   auto_upgrade_minor_version = true

#   settings = <<SETTINGS
#     {
#         "fileUris": ["https://raw.githubusercontent.com/mustafamj9/artifacts/main/nginx.sh"]
#     }
# SETTINGS

#   protected_settings = <<PROTECTED_SETTINGS
#     {
#             "commandToExecute": "./nginx.sh"
#     }
# PROTECTED_SETTINGS
# }
