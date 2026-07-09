terraform {
  required_version = ">= 1.8.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name = "rg-redacta-tfstate"
    container_name      = "tfstate"
    key                 = "production/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
