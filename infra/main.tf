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
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
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

resource "azurerm_resource_group" "serv-chal-vm-rg" {
  name     = var.vm_resource_group_name
  location = var.vm_location
}

#Creating NSGs

resource "azurerm_network_security_group" "serv-chal-pub-nsg" {
  name                = "${local.app}-pub-sg"
  location            = azurerm_resource_group.serv-chal-net-rg.location
  resource_group_name = azurerm_resource_group.serv-chal-net-rg.name
}
resource "azurerm_network_security_group" "serv-chal-pub-nsg2" {
  name                = "${local.app}-pub-sg2"
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

#Creating VNet and Subnets

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
  service_endpoints    = ["Microsoft.Sql"]
}

resource "azurerm_subnet" "serv-chal-subnet4" {
  name                 = "${local.app}-subnet4"
  address_prefixes     = ["10.0.4.0/24"]
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

resource "azurerm_subnet_network_security_group_association" "serv-chal-nsg-assoc4" {
  subnet_id                 = azurerm_subnet.serv-chal-subnet4.id
  network_security_group_id = azurerm_network_security_group.serv-chal-pub-nsg2.id
}
#Creating NSG rules

resource "azurerm_network_security_rule" "allow-public-ssh-to-jumpserver1" {
  name                        = "allow-public-ssh-to-jumpserver1"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.serv-chal-net-rg.name
  network_security_group_name = azurerm_network_security_group.serv-chal-pub-nsg.name
}
#Below is required by app_gw
resource "azurerm_network_security_rule" "allow-public-ports" {
  name                        = "allow-public-ssh-to-jumpserver1"
  priority                    = 400
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.serv-chal-net-rg.name
  network_security_group_name = azurerm_network_security_group.serv-chal-pub-nsg2.name
}

resource "azurerm_network_security_rule" "allow-public-http-to-loadbalancer" {
  name                        = "allow-public-http-to-loadbalancer"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.serv-chal-net-rg.name
  network_security_group_name = azurerm_network_security_group.serv-chal-pub-nsg2.name
}

resource "azurerm_network_security_rule" "allow-ssh-to-appserver1" {
  name                        = "allow-ssh-to-appserver1"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "10.0.1.0/24"
  destination_address_prefix  = "10.0.2.0/24"
  resource_group_name         = azurerm_resource_group.serv-chal-net-rg.name
  network_security_group_name = azurerm_network_security_group.serv-chal-pvt-app-nsg.name
}

resource "azurerm_network_security_rule" "allow-http-to-lb" {
  name                        = "allow-http-to-lb"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "10.0.1.0/24"
  destination_address_prefix  = "10.0.2.0/24"
  resource_group_name         = azurerm_resource_group.serv-chal-net-rg.name
  network_security_group_name = azurerm_network_security_group.serv-chal-pvt-app-nsg.name
}

resource "azurerm_network_security_rule" "allow-appserver1-to-db" {
  name                        = "allow-appserver1-to-db"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = "10.0.2.0/24"
  destination_address_prefix  = "10.0.3.0/24"
  resource_group_name         = azurerm_resource_group.serv-chal-net-rg.name
  network_security_group_name = azurerm_network_security_group.serv-chal-pvt-db-nsg.name
}

#resource "azurerm_network_security_rule" "allow-ssh-to-dbservers" {
#  name                        = "allow-ssh-to-dbservers"
#  priority                    = 300
#  direction                   = "Inbound"
#  access                      = "Allow"
#  protocol                    = "Tcp"
#  source_port_range           = "*"
#  destination_port_range      = "22"
#  source_address_prefix       = "10.0.1.0/24"
#  destination_address_prefix  = "10.0.3.0/24"
#  resource_group_name         = azurerm_resource_group.serv-chal-net-rg.name
#  network_security_group_name = azurerm_network_security_group.serv-chal-pvt-db-nsg.name
#}
#Commented above as using managed postgresql

#Creating Jump Server With Public IP
module "jump_server1" {
  source                 = "./linuxvm"
  vm_hostname            = "jumpserver01"
  vm_public_ip           = true
  vm_ssh_key             = "./jump_serv_id_rsa.pub"
  vm_vnet_subnet_id      = azurerm_subnet.serv-chal-subnet1.id
  vm_os_offer            = "0001-com-ubuntu-server-focal"
  vm_os_publisher        = "Canonical"
  vm_os_sku              = "20_04-lts-gen2"
  vm_os_version          = "latest"
  vm_resource_group_name = var.vm_resource_group_name
  vm_location            = var.vm_location
  depends_on = [
    azurerm_virtual_network.serv-chal-vnet
  ]
}

#Creating Application Server hosts
module "app_server1" {
  source                 = "./linuxvm"
  vm_hostname            = "appserver01"
  vm_ssh_key             = "./app_serv_id_rsa.pub"
  vm_vnet_subnet_id      = azurerm_subnet.serv-chal-subnet2.id
  vm_resource_group_name = var.vm_resource_group_name
  vm_location            = var.vm_location
  depends_on = [
    azurerm_virtual_network.serv-chal-vnet
  ]
  vm_zone = "1"
}
module "app_server2" {
  source                 = "./linuxvm"
  vm_hostname            = "appserver02"
  vm_ssh_key             = "./app_serv_id_rsa.pub"
  vm_vnet_subnet_id      = azurerm_subnet.serv-chal-subnet2.id
  vm_resource_group_name = var.vm_resource_group_name
  vm_location            = var.vm_location
  depends_on = [
    azurerm_virtual_network.serv-chal-vnet
  ]
  vm_zone = "2"
}


resource "azurerm_resource_group" "serv-chal-db" {
  name     = "serv-chal-db"
  location = "centralus"
}

#Creating database

resource "azurerm_postgresql_server" "serv-chall" {
  name                = var.db_name
  location            = azurerm_resource_group.serv-chal-db.location
  resource_group_name = azurerm_resource_group.serv-chal-db.name

  administrator_login          = var.db_user
  administrator_login_password = var.db_pass

  sku_name   = "GP_Gen5_2"
  version    = "11"
  storage_mb = 5120

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = false

  public_network_access_enabled    = false
  ssl_enforcement_enabled          = false
  ssl_minimal_tls_version_enforced = "TLSEnforcementDisabled"
}

#resource "azurerm_postgresql_virtual_network_rule" "serv-chal-db-rule" {
#  name                                 = "postgresql-vnet-rule"
#  resource_group_name                  = azurerm_resource_group.serv-chal-db.name
#  server_name                          = azurerm_postgresql_server.serv-chall.name
#  subnet_id                            = azurerm_subnet.serv-chal-subnet3.id
#  ignore_missing_vnet_service_endpoint = true
#}

resource "azurerm_private_endpoint" "example" {
  name                = "example"
  location            = azurerm_resource_group.serv-chal-net-rg.location
  resource_group_name = azurerm_resource_group.serv-chal-net-rg.name
  subnet_id           = azurerm_subnet.serv-chal-subnet3.id

  private_service_connection {
    name                           = "example-privateserviceconnection"
    private_connection_resource_id = azurerm_postgresql_server.serv-chall.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }
}

#resource "azurerm_postgresql_firewall_rule" "server-chall-db-firewall" {
#  name                = "allow-app-server"
#  resource_group_name = azurerm_resource_group.serv-chal-db.name
#  server_name         = azurerm_postgresql_server.serv-chall.name
#  start_ip_address    = "10.0.2.0"
#  end_ip_address      = "10.0.2.255"
#}

# Getting hold of the network NICs

data "azurerm_network_interface" "appnic1" {
  name                = "appserver01-nic"
  resource_group_name = var.vm_resource_group_name
  depends_on = [
    module.app_server1
  ]
}
data "azurerm_network_interface" "appnic2" {
  name                = "appserver02-nic"
  resource_group_name = var.vm_resource_group_name
  depends_on = [
    module.app_server2
  ]
}


#Creating loadbalancer

resource "azurerm_public_ip" "loadbalancer-ip" {
  name                = "loadbalancer-ip"
  resource_group_name = azurerm_resource_group.serv-chal-net-rg.name
  location            = azurerm_resource_group.serv-chal-net-rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.serv-chal-vnet.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.serv-chal-vnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.serv-chal-vnet.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.serv-chal-vnet.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.serv-chal-vnet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.serv-chal-vnet.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.serv-chal-vnet.name}-rdrcfg"
  probe_name_app1                = "${azurerm_virtual_network.serv-chal-vnet.name}-probe1"
  probe_name_app2                = "${azurerm_virtual_network.serv-chal-vnet.name}-probe2"
  url_path_map                   = "${azurerm_virtual_network.serv-chal-vnet.name}-path-map1"

}

resource "azurerm_application_gateway" "network" {
  name                = "example-appgateway"
  resource_group_name = azurerm_resource_group.serv-chal-net-rg.name
  location            = azurerm_resource_group.serv-chal-net-rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.serv-chal-subnet4.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.loadbalancer-ip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }
  probe {
    name                = local.probe_name_app1
    host                = data.azurerm_network_interface.appnic1.private_ip_address
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    protocol            = "Http"
    port                = 80
    path                = "/healthcheck/"
    match { # Optional
      body        = "OK"
      status_code = ["200"]
    }
  }
  probe {
    name                = local.probe_name_app2
    host                = data.azurerm_network_interface.appnic2.private_ip_address
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    protocol            = "Http"
    port                = 80
    path                = "/healthcheck/"
    match { # Optional
      body        = "OK"
      status_code = ["200"]
    }
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 20
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
  # URL Path Map - Define Path based Routing    
  url_path_map {
    name                               = local.url_path_map
    default_backend_address_pool_name  = local.backend_address_pool_name
    default_backend_http_settings_name = local.http_setting_name
    #default_redirect_configuration_name = local.redirect_configuration_name
    path_rule {
      name                       = "app1-rule"
      paths                      = ["/*"]
      backend_address_pool_name  = local.backend_address_pool_name
      backend_http_settings_name = local.http_setting_name
    }
    path_rule {
      name                       = "app2-rule"
      paths                      = ["/api/tasks/*"]
      backend_address_pool_name  = local.backend_address_pool_name
      backend_http_settings_name = local.http_setting_name
    }
  }
}
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "app1" {
  network_interface_id    = data.azurerm_network_interface.appnic1.id
  ip_configuration_name   = "ipconfiguration1"
  backend_address_pool_id = tolist(azurerm_application_gateway.network.backend_address_pool).0.id
}
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "app2" {
  network_interface_id    = data.azurerm_network_interface.appnic2.id
  ip_configuration_name   = "ipconfiguration1"
  backend_address_pool_id = tolist(azurerm_application_gateway.network.backend_address_pool).0.id
}

