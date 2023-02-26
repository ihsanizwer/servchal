variable "vm_public_ip"{
    description = "whether to assign public IP or not. If true assign. Else dont"
    default = "false"
}

variable "vm_ssh_key"{
    description = "The SSH key to use to set for the VM"
}

variable "prefix"{
    description = "The SSH key to use to set for the VM"
    default = "serv-chal"
}

variable "vm_size" {
  description = "VM Size"
  default = "Standard_B1s"
}

variable "vm_os_publisher" {
  description = "The name of the image publisher you want to deploy. "
  default     = "RedHat"
}

variable "vm_os_offer" {
  description = "The name of the offer of the image that you want to deploy.  "
  default     = "RHEL"
}

variable "vm_os_sku" {
  description = "SKU of the image you want to deploy. "
  default     = "86-gen2"
}

variable "vm_os_version" {
  description = "Image version to deploy  "
  default     = "latest"
}

variable "vm_resource_group_name" {
  description = "Resource group for the VM"
  default     = "serv-chal-vm-rg"
}

variable "vm_location" {
  description = "Location for the VM"
  default = "centralus"
}

variable "vm_vnet_subnet_id" {
  description = "Subnet ID for the VM."
}

variable "vm_admin_username" {
  description = "Admin user of the VM"
  default     = "azureuser"
}

variable "vm_hostname" {
  description = "hostname of the VM"
}