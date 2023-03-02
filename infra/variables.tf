variable "vm_resource_group_name" {
  description = "Resource group for the VM"
  default     = "serv-chal-vm-rg"
}

variable "vm_location" {
  description = "Location for the VM"
  default     = "centralus"
}

variable "db_user" {
  description = "Username for the db user"
  default     = "postgres"
}

variable "db_pass" {
  description = "Password for the db user"
  default     = "L0v3lyD4y$"
  sensitive   = true
}

variable "db_name" {
  description = "Name of the database"
  default     = "somerandomdbbname1273415"
}

