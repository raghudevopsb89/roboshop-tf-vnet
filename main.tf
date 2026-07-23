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

resource "azurerm_virtual_network_peering" "default-to-new" {
  name                      = "default2dev"
  resource_group_name       = "denmark-east-rg"
  virtual_network_name      = "workstation-vnet"
  remote_virtual_network_id = azurerm_virtual_network.main.id
}

resource "azurerm_virtual_network_peering" "dev-to-default" {
  name                      = "dev2default"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.main.name
  remote_virtual_network_id = "/subscriptions/3f2e42e1-ca06-4a99-8c56-be8d8ba306db/resourceGroups/denmark-east-rg/providers/Microsoft.Network/virtualNetworks/workstation-vnet"
}

resource "azurerm_public_ip" "nat" {
  name                = "${var.env}-nat-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "main" {
  name                = "${var.env}-nat"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

# Associate NAT gateway to the subnet(s) that need internet
resource "azurerm_subnet_nat_gateway_association" "main" {
  for_each       = azurerm_subnet.main
  subnet_id      = each.value.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

module "db" {
  source = "./modules/vm"

  for_each       = var.vms
  component_name = each.key
  vm_size        = try(each.value["vm_size"], "Standard_B1s")

  rgname    = azurerm_resource_group.main.name
  rgid      = azurerm_resource_group.main.id
  rgloc     = azurerm_resource_group.main.location
  image_id  = var.image_id
  env       = var.env
  subnet_id = azurerm_subnet.main["db"].id
  vm_count  = 1
}


