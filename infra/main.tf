terraform {
  required_version = ">=1.1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.36.0"
    }
  }
  #backend "azurerm" {
  #resource_group_name  = ""
  #storage_account_name = ""
  #container_name       = ""
  #key                  = ""
  #Above are commented to keep things simple for this challenge
  #}
}

provider "azurerm" {
  features {}
  subscription_id = "96a83b50-c77d-40ae-b8b9-4930e9787e23"
}

locals {
  app   = "serv-chal"
  owner = "Community Team"
  common-res-tags = {
    environment = "Production"
    product     = local.app
  }
}


resource "azurerm_resource_group" "serv-chal-net-rg" {
  name     = "${local.app}-net-rg"
  location = "centralus"
}

resource "azurerm_network_security_group" "serv-chal-pub-nsg" {
  name                = "${local.app}-pub-sg"
  location            = azurerm_resource_group.serv-chal-net-rg.location
  resource_group_name = azurerm_resource_group.serv-chal-net-rg.name
}

resource "azurerm_network_security_group" "serv-chal-pvt-app-nsg" {
  name                = "${local.app}-pri-app-sg"
  location            = azurerm_resource_group.serv-chal-net-rg.location
  resource_group_name = azurerm_resource_group.serv-chal-net-rg.name
}

resource "azurerm_network_security_group" "serv-chal-pvt-db-nsg" {
  name                = "${local.app}-pri-db-sg"
  location            = azurerm_resource_group.serv-chal-net-rg.location
  resource_group_name = azurerm_resource_group.serv-chal-net-rg.name
}

resource "azurerm_virtual_network" "serv-chal-vnet" {
  name                = "${local.app}-vnet"
  location            = azurerm_resource_group.serv-chal-net-rg.location
  resource_group_name = azurerm_resource_group.serv-chal-net-rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  tags = local.common-res-tags
}

resource "azurerm_subnet" "serv-chal-subnet1" {
  name                 = "${local.app}-subnet1"
  address_prefixes     = ["10.0.1.0/24"]
  virtual_network_name = azurerm_virtual_network.serv-chal-vnet.name
  resource_group_name  = azurerm_resource_group.serv-chal-net-rg.name
}

resource "azurerm_subnet" "serv-chal-subnet2" {
  name                 = "${local.app}-subnet2"
  address_prefixes     = ["10.0.2.0/24"]
  virtual_network_name = azurerm_virtual_network.serv-chal-vnet.name
  resource_group_name  = azurerm_resource_group.serv-chal-net-rg.name
}

resource "azurerm_subnet" "serv-chal-subnet3" {
  name                 = "${local.app}-subnet3"
  address_prefixes     = ["10.0.3.0/24"]
  virtual_network_name = azurerm_virtual_network.serv-chal-vnet.name
  resource_group_name  = azurerm_resource_group.serv-chal-net-rg.name
}

resource "azurerm_subnet_network_security_group_association" "serv-chal-nsg-assoc1" {
  subnet_id                 = azurerm_subnet.serv-chal-subnet1.id
  network_security_group_id = azurerm_network_security_group.serv-chal-pub-nsg.id
}
resource "azurerm_subnet_network_security_group_association" "serv-chal-nsg-assoc2" {
  subnet_id                 = azurerm_subnet.serv-chal-subnet2.id
  network_security_group_id = azurerm_network_security_group.serv-chal-pvt-app-nsg.id
}
resource "azurerm_subnet_network_security_group_association" "serv-chal-nsg-assoc3" {
  subnet_id                 = azurerm_subnet.serv-chal-subnet3.id
  network_security_group_id = azurerm_network_security_group.serv-chal-pvt-db-nsg.id
}

#Creating Jump Server With Public IP
module "jump_server1" {
  source            = "./linuxvm"
  vm_hostname       = "jumpserver01"
  vm_public_ip      = true
  vm_ssh_key        = "./jump_serv_id_rsa.pub"
  vm_vnet_subnet_id = azurerm_subnet.serv-chal-subnet1.id
  depends_on = [
    azurerm_virtual_network.serv-chal-vnet
  ]
}

#Creating Application Server hosts
module "app_server1" {
  source            = "./linuxvm"
  vm_hostname       = "appserver01"
  vm_ssh_key        = "./app_serv_id_rsa.pub"
  vm_vnet_subnet_id = azurerm_subnet.serv-chal-subnet2.id
  depends_on = [
    azurerm_virtual_network.serv-chal-vnet
  ]
}
module "app_server2" {
  source            = "./linuxvm"
  vm_hostname       = "appserver02"
  vm_ssh_key        = "./app_serv_id_rsa.pub"
  vm_vnet_subnet_id = azurerm_subnet.serv-chal-subnet2.id
  depends_on = [
    azurerm_virtual_network.serv-chal-vnet
  ]
}