# Generate 2 Vms inside one vnet

module "virtual_machine" {
  source         = "github.com/kuba-b-labs/terraform-playground//modules//virtual_machine"
  region         = "switzerlandnorth"
  vnet_name      = "iac-vnet"
  vm_name        = "iac-vm"
  admin_username = "kuba"
  kind           = "Linux"
  vm_size        = "Standard_B2ats_v2"
  ssh_key        = var.ssh_public_key
  rg_name        = "dev"
  create_vnet    = true
  create_rg      = false
}

module "container_group" {
  source              = "github.com/Azure/terraform-azurerm-avm-res-containerinstance-containergroup"
  location            = "switzerlandnorth"
  name                = "iac-container-group"
  resource_group_name = "dev"
  restart_policy      = "OnFailure"
  os_type             = "Linux"
  enable_telemetry    = false
  containers = {
    grafana = {
      image  = "grafana/grafana:latest"
      cpu    = 0.5
      memory = 1.5
      ports = [{
        port     = 3000
        protocol = "TCP"
      }]
      secure_environment_variables = {
        GF_SECURITY_ADMIN_USER     = var.grafana_user
        GF_SECURITY_ADMIN_PASSWORD = var.grafana_password
      }
    }
    prometheus = {
      image  = "prom/prometheus:latest"
      cpu    = 0.5
      memory = 1.5
      ports = [{
        port     = 9090
        protocol = "TCP"
      }]
    }
  }
  subnet_ids = [azurerm_subnet.containers_subnet.id]
  depends_on = [azurerm_subnet.containers_subnet]
}

resource "azurerm_subnet" "containers_subnet" {
  name                 = "iac-subnet"
  resource_group_name  = "dev"
  virtual_network_name = "iac-vnet"
  address_prefixes     = ["10.0.2.0/24"]
  delegation {
    name = "aci-delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
  depends_on = [module.virtual_machine]
}