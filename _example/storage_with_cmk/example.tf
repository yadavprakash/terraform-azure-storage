provider "azurerm" {
  features {}
}

##-----------------------------------------------------------------------------
## Resource Group module call
##-----------------------------------------------------------------------------
module "resource_group" {
  source      = "git::https://github.com/opsstation/terraform-azure-resource-group.git?ref=v1.0.0"
  name        = "app"
  environment = "tested"
  location    = "North Europe"
}


##-----------------------------------------------------------------------------
## Virtual Network module call.
##-----------------------------------------------------------------------------
module "vnet" {
  source              = "git::https://github.com/opsstation/terraform-azure-vnet.git?ref=v1.0.0"
  name                = "app"
  environment         = "test"
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  address_spaces      = ["10.0.0.0/16"]
}

##-----------------------------------------------------------------------------
## Subnet module call.
##-----------------------------------------------------------------------------
module "subnet" {
  source = "git::https://github.com/opsstation/terraform-azure-subnet.git?ref=v1.0.1"

  name                 = "app"
  environment          = "test"
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  virtual_network_name = join("", module.vnet[*].vnet_name)

  #subnet
  subnet_names    = ["subnet1"]
  subnet_prefixes = ["10.0.1.0/24"]

  # route_table
  enable_route_table = true
  route_table_name   = "default_subnet"
  routes = [
    {
      name           = "rt-test"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
    }
  ]
}

##-----------------------------------------------------------------------------
## Key Vault module call.
##-----------------------------------------------------------------------------
module "vault" {
  depends_on                  = [module.vnet]
  source                      = "git::https://github.com/opsstation/terraform-azure-key-vault.git?ref=v1.0.0"
  name                        = "app"
  environment                 = "test"
  sku_name                    = "standard"
  resource_group_name         = module.resource_group.resource_group_name
  subnet_id                   = module.subnet.subnet_id[0]
  virtual_network_id          = module.vnet.vnet_id
  enable_private_endpoint     = true
  enable_rbac_authorization   = true
  purge_protection_enabled    = true
  enabled_for_disk_encryption = false
  principal_id                = ["xxxx-xxx-4a4c-xxxx-xxxx"]
  role_definition_name        = ["Key Vault Administrator"]

}

##    Storage Account
module "storage-with-cmk" {
  source                   = "../.."
  name                     = "app"
  environment              = "test"
  label_order              = ["name", "environment", ]
  resource_group_name      = module.resource_group.resource_group_name
  location                 = module.resource_group.resource_group_location
  storage_account_name     = "stogkqp0896"
  account_kind             = "BlockBlobStorage"
  account_tier             = "Premium"
  identity_type            = "UserAssigned"
  object_id                = ["xxxxx-xxx-4a4c-xxxx-xxxxx"]
  account_replication_type = "ZRS"

  ###customer_managed_key can only be set when the account_kind is set to StorageV2 or account_tier set to Premium, and the identity type is UserAssigned.
  key_vault_id = module.vault.id

  ##   Storage Container
  containers_list = [
    { name = "app-test", access_type = "private" },
  ]

  virtual_network_id = module.vnet.vnet_id
  subnet_id          = module.subnet.subnet_id[0]

}
