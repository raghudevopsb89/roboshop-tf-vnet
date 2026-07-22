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

resource "azurerm_subnet" "main" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value]
}


module "db" {
  source = "./modules/vm"

  for_each       = var.vms
  component_name = each.key
  vm_size        = try(each.value["vm_size"], "Standard_B1s")

  rgname    = azurerm_resource_group.main.name
  image_id  = var.image_id
  env       = var.env
  subnet_id = azurerm_subnet.main["db"].id
  vm_count  = 1
}


