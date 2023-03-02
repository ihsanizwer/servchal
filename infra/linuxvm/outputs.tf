
output "public_ip" {
  value = azurerm_public_ip.serv-chal-sc-pip.*.ip_address
}

