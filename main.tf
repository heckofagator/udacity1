# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags = {
    "${var.tag_name}" = "${var.tag_value}"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/24"]
  location            = var.location
  resource_group_name = "${var.prefix}-rg"
  tags = {
    "${var.tag_name}" = "${var.tag_value}"
  }
  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_subnet" "snet" {
  name                 = "${var.prefix}-snet"
  resource_group_name  = "${var.prefix}-rg"
  virtual_network_name = "${var.prefix}-vnet"
  address_prefixes     = ["10.0.0.0/24"]
#  tags = {
#    "${var.tag_name}" = "${var.tag_value}"
#  }
  depends_on = [azurerm_virtual_network.vnet]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = "${var.prefix}-rg"
  tags = {
    "${var.tag_name}" = "${var.tag_value}"
  }
  depends_on = [azurerm_virtual_network.vnet]

  security_rule {
    name           = "deny-all-inbound-from-Internet-all-protocols"
    priority       = 100
    direction      = "Inbound"
    access         = "Deny"
    protocol       = "*"  
    source_port_range = "*" 
    destination_port_range = "*"
    source_address_prefix = "Internet" 
    destination_address_prefix = "VirtualNetwork" 
  }

  security_rule {
    name           = "allow-VMs-to-communicate"
    priority       = 200
    direction      = "Inbound"
    access         = "Allow"
    protocol       = "*"  
    source_port_range = "*" 
    destination_port_range = "*"
    source_address_prefix = "VirtualNetwork" 
    destination_address_prefix = "VirtualNetwork" 
  }
}

resource "azurerm_subnet_network_security_group_association" "internal" {
  subnet_id                 = azurerm_subnet.snet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_lb" "lb" {
  name                = "${var.prefix}-lb"
  resource_group_name = "${var.prefix}-rg"
  location            = var.location
  frontend_ip_configuration {
    name                 = "${var.prefix}-lb-pubip"
    public_ip_address_id = azurerm_public_ip.pubip.id
  }
}

resource "azurerm_availability_set" "as" {
  name                = "${var.prefix}-as"
  location            = var.location
  resource_group_name = "${var.prefix}-rg"
  depends_on          = [azurerm_resource_group.rg]
}

resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "${var.prefix}-nic-${count.index}"
  resource_group_name = "${var.prefix}-rg"
  location            = var.location

  tags = {
    "${var.tag_name}" = "${var.tag_value}"
  }

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.snet.id
    private_ip_address_allocation = "Dynamic"
#moved pubip to LB
#   public_ip_address_id = azurerm_public_ip.pubip.id
  }
}

resource "azurerm_public_ip" "pubip" {
  name                = "${var.prefix}-pubip"
  resource_group_name = "${var.prefix}-rg"
  location            = var.location
  allocation_method   = "Static"

  tags = {
    "${var.tag_name}" = "${var.tag_value}"
  }
  depends_on = [azurerm_virtual_network.vnet]
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                           = var.vm_count
  name                            = "${var.prefix}-vm-${count.index}"
  resource_group_name             = "${var.prefix}-rg"
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id
  ]
  availability_set_id             = azurerm_availability_set.as.id

tags = {
    "${var.tag_name}" = "${var.tag_value}",
    "Project"         = "udacity_project_1"
  }

  source_image_id = "/subscriptions/b6a27b6d-3141-46ad-871e-7a588457c248/resourceGroups/AZUREDEVOPS/providers/Microsoft.Compute/images/myUdacityPackerImage"
  
# Either use std stanza below or can use customer Packer image above from 'az image list'
#  source_image_reference {
#    publisher = "Canonical"
#    offer     = "0001-com-ubuntu-server-jammy"
#    sku       = "22_04-lts"
#    version   = "latest"
#  }

  os_disk {
    storage_account_type = var.storage_account_type
    caching              = "ReadWrite"
  }
}
 
resource "azurerm_managed_disk" "mandisk" {
  count                = var.vm_count
  name                 = "${var.prefix}-data-disk-${count.index}"
  location             = var.location
  resource_group_name  = "${var.prefix}-rg"
  storage_account_type = var.storage_account_type
  create_option        = var.create_option
  disk_size_gb         = var.man_disk_size

  tags = {
    "${var.tag_name}" = "${var.tag_value}"
  }
  depends_on = [azurerm_resource_group.rg]
} 

resource "azurerm_virtual_machine_data_disk_attachment" "attach_disk" {
  count                = var.vm_count
  managed_disk_id      = azurerm_managed_disk.mandisk[count.index].id
  virtual_machine_id   = azurerm_linux_virtual_machine.vm[count.index].id
  lun                  = "${count.index}"
  caching              = var.mandisk_caching
  depends_on = [
    azurerm_resource_group.rg,
    azurerm_linux_virtual_machine.vm,
    azurerm_managed_disk.mandisk
    ]
}

resource "azurerm_lb_backend_address_pool" "be_pool" {
  loadbalancer_id      = azurerm_lb.lb.id
  name                 = "be_pool"
}

resource "azurerm_network_interface_backend_address_pool_association" "be_pool_assoc" {
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = "ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.be_pool.id
}

#resource "azurerm_lb_backend_address_pool_association" "lb_be_pool" {
#  count                   = var.vm_count
#  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_be_pool.id
#  network_interface_id    = azurerm_network_interface.nic[count.index].id
#  ip_configuration_name   = "internal"
#}