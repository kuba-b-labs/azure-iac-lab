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
  priority       = "Spot"
  security_rules = [
    {
      name                       = "SSH"
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = var.my_ip
      destination_address_prefix = "*"
    },
    {
      name                       = "allowHTTP"
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = var.my_ip
      destination_address_prefix = "*"
    },
    {
      name                       = "allowPrometheus"
      priority                   = 1003
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "9100"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name = "allowNginxExporter"
      priority                   = 1004
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "9113"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
  ]
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
      volumes = {
        datasources = {
          name                 = "datasources"
          mount_path           = "/etc/grafana/provisioning/datasources"
          read_only            = true
          storage_account_name = "containerstoragejb"
          storage_account_key  = var.storage_account_key
          share_name           = "grafana"
        },
        data = {
          name                 = "data"
          mount_path           = "/var/lib/grafana"
          read_only            = false
          storage_account_name = "containerstoragejb"
          storage_account_key  = var.storage_account_key
          share_name           = "grafana-data"
        }
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
      volumes = {
        config = {
          name                 = "config"
          mount_path           = "/etc/prometheus/"
          read_only            = true
          storage_account_name = "containerstoragejb"
          storage_account_key  = var.storage_account_key
          share_name           = "prometheus"
        }
      }
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
  service_endpoints    = ["Microsoft.Storage"]
  depends_on = [module.virtual_machine]
}
