terraform {
  backend "azurerm" {
    resource_group_name  = "storageaccounts"
    storage_account_name = "terraformremotebackendjb"
    container_name       = "azure-iac-lab"
    key                  = "terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.1.0, <4.40.0"
    }
  }
  required_version = ">= 0.13"
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.sub_id
  use_oidc        = true
}