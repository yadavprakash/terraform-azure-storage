provider "azurerm" {
  features {}
}

##-----------------------------------------------------------------------------
## Resource Group module call
## Resource group in which all resources will be deployed.
##-----------------------------------------------------------------------------
module "resource_group" {
  source      = "git::https://github.com/yadavprakash/terraform-azure-resource-group.git?ref=v1.0.0"
  name        = "app111"
  environment = "test"
  location    = "Canada Central"
}

#-----------------------------------------------------------------------------
## Storage module call.
## Here default storage will be deployed i.e. storage account without cmk encryption.
##-----------------------------------------------------------------------------
module "storage" {
  source                        = "../.."
  name                          = "app"
  environment                   = "test"
  default_enabled               = true
  resource_group_name           = module.resource_group.resource_group_name
  location                      = "North Europe"
  storage_account_name          = "tes3dfjg"
  public_network_access_enabled = true
  ##   Storage Container
  containers_list = [
    { name = "app-test", access_type = "private" },
    { name = "app2", access_type = "private" },
  ]
  ##   Storage File Share
  file_shares = [
    { name = "fileshare1", quota = 5 },
  ]
  ##   Storage Tables
  tables = ["table1"]
  ## Storage Queues
  queues                  = ["queue1"]
  enable_private_endpoint = false
}
