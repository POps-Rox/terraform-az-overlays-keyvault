# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

module "mod_key_vault" {
  #source  = "github.com/POps-Rox/terraform-az-overlays-keyvault"
  #version = "x.x.x"
  source = "../../.."
  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.hub
  }

  # By default, this module will create a resource group and 
  # provide a name for an existing resource group. If you wish 
  # to use an existing resource group, change the option 
  # to "create_key_vault_resource_group = false." The location of the group 
  # will remain the same if you use the current resource.
  create_key_vault_resource_group = true
  location                        = var.location
  deploy_environment              = var.deploy_environment
  environment                     = var.environment
  org_name                        = var.org_name
  workload_name                   = var.workload_name

  # This is to enable the features of the key vault
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false

  # This is to enable public access to the key vault, since we are not using a private endpoint, we will enable it
  public_network_access_enabled = true

  # Once `Purge Protection` has been Enabled it's not possible to Disable it
  # Deleting the Key Vault with `Purge Protection` enabled will schedule the Key Vault to be deleted
  # The default retention period is 90 days, possible values are from 7 to 90 days
  # use `soft_delete_retention_days` to set the retention period
  enable_purge_protection = false
  # soft_delete_retention_days = 90

  # Key Vault Secrets 
  secrets = [{ name = "secret-1", value = "text" }]

  # Current user should be here to be able to create keys and secrets
  admin_objects_ids = [
    data.azuread_group.admin_group.id
  ]

  # This is to enable resource locks for the key vault. 
  enable_resource_locks = false

  # Tags for Azure Resources
  add_tags = local.tags
}

