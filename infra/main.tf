terraform {
  required_version = ">= 1.1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.36.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = ""
    storage_account_name = ""
    container_name       = ""
    key                  = ""
  }
}

locals {
  app = "serv=chal"
  owner        = "Community Team"
  common-res-tags = {
    environment = "Production"
    product = local.app
  }
}


resource "azurerm_resource_group" "${local.app}-net-rg" {
  name     = "${local.app}-net-rg"
  location = "Central US"
}

resource "azurerm_network_security_group" "${local.app}-pub-sg" {
  name                = "${local.app}-pub-sg"
  location            = azurerm_resource_group.${local.app}-net-rg.location
  resource_group_name = azurerm_resource_group.${local.app}-net-rg.name
}

resource "azurerm_network_security_group" "${local.app}-pvt-app-sg" {
  name                = "${local.app}-pri-app-sg"
  location            = azurerm_resource_group.${local.app}-net-rg.location
  resource_group_name = azurerm_resource_group.${local.app}-net-rg.name
}

resource "azurerm_network_security_group" "${local.app}-pvt-db-sg" {
  name                = "${local.app}-pri-db-sg"
  location            = azurerm_resource_group.${local.app}-net-rg.location
  resource_group_name = azurerm_resource_group.${local.app}-net-rg.name
}

resource "azurerm_virtual_network" "${local.app}-vnet" {
  name                = "${local.app}-vnet"
  location            = azurerm_resource_group.${local.app}-net-rg.location
  resource_group_name = azurerm_resource_group.${local.app}-net-rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  subnet {
    name           = "${local.app}-pub-subnet1"
    address_prefix = "10.0.1.0/24"
    security_group = azurerm_network_security_group.${local.app}-net-rg.id
  }

  subnet {
    name           = "${local.app}-pvt-subnet1"
    address_prefix = "10.0.2.0/24"
    security_group = azurerm_network_security_group.${local.app}-net-rg.id
  }

  subnet {
    name           = "${local.app}-pvt-subnet1"
    address_prefix = "10.0.3.0/24"
    security_group = azurerm_network_security_group.${local.app}-net-rg.id
  }

  tags = local.common-res-tags
}