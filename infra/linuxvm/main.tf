terraform {
  required_version = ">=1.1.0"
    required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.36.0"
    }
    }
}



resource "azurerm_public_ip" "serv-chal-sc-pip" {
  name                    = "${var.vm_hostname}-pip"
  location                = "${var.vm_location}"
  resource_group_name     = "${var.vm_resource_group_name}"
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  count = var.vm_public_ip == true ? 1: 0

}

resource "azurerm_network_interface" "serv-chal-sc-nic" {
  name                = "${var.vm_hostname}-nic"
  location            = "${var.vm_location}"
  resource_group_name = "${var.vm_resource_group_name}"

  ip_configuration {
    name                          = "ipconfiguration1"
    subnet_id                     = "${var.vm_vnet_subnet_id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = var.vm_public_ip == true ? azurerm_public_ip.serv-chal-sc-pip[0].id: null
  }
}

resource "azurerm_virtual_machine" "serv-chal-sc-vm" {
  name                  = "${var.vm_hostname}"
  location              = "${var.vm_location}"
  resource_group_name   = "${var.vm_resource_group_name}"
  network_interface_ids = [azurerm_network_interface.serv-chal-sc-nic.id]
  vm_size               = "${var.vm_size}"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
   delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
   delete_data_disks_on_termination = true

  os_profile {
    computer_name  = "${var.vm_hostname}"
    admin_username = "${var.vm_admin_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.vm_admin_username}/.ssh/authorized_keys"
      key_data = "${file("${var.vm_ssh_key}")}"
    }
  }

  storage_image_reference {
    publisher = "${var.vm_os_publisher}"
    offer     = "${var.vm_os_offer}"
    sku       = "${var.vm_os_sku}"
    version   = "${var.vm_os_version}"
  }
  storage_os_disk {
    name              = "${var.vm_hostname}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  zones = var.vm_zone == null? null: [var.vm_zone]

}

resource "local_file" "public_ip" {
    content  = azurerm_public_ip.serv-chal-sc-pip[0].ip_address
    filename = "${var.vm_hostname}-public-ip"
    count = var.vm_public_ip == true ? 1: 0
}

resource "local_file" "private_ip" {
    content  = azurerm_network_interface.serv-chal-sc-nic.private_ip_address
    filename = "${var.vm_hostname}-private-ip"

}

