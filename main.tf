resource "azurerm_resource_group" "main" {
  location = var.location
  name     = "${replace(lower(var.location), " ", "-")}-${var.env}"
}

resource "azurerm_virtual_network" "main" {
  name                = var.env
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.address_space
}

# resource "azurerm_subnet" "example" {
#   name                 = "example-subnet"
#   resource_group_name  = azurerm_resource_group.main.name
#   virtual_network_name = azurerm_virtual_network.main.name
#   address_prefixes     = ["10.0.1.0/24"]
#
#   delegation {
#     name = "delegation"
#
#     service_delegation {
#       name    = "Microsoft.ContainerInstance/containerGroups"
#       actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
#     }
#   }
# }


