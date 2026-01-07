terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }

backend "azurerm" {
    resource_group_name   = "rg-statefile"
    storage_account_name  = "statefilestorageasad"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }

}

provider "azurerm" {
  # Configuration options

  features {}
  subscription_id = "8b0422c9-d3b4-4ad5-b676-1cd162a61f87"
}