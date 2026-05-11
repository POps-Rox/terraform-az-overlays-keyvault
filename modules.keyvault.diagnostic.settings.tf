# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

##-------------------------------------------------------
## Diagnostic setting for key vault and its components. 
##-------------------------------------------------------
module "mod_diagnostic_settings_key_vault" {
  count  = length(var.logs_destinations_ids) > 0 ? 1 : 0
  source = "github.com/POps-Rox/terraform-az-overlays-diagnosticsettings"

  # Resource Group, location, VNet and Subnet details
  location           = var.location
  deploy_environment = var.deploy_environment
  environment        = var.environment
  org_name           = var.org_name
  workload_name      = var.workload_name

  resource_id           = azurerm_key_vault.this.0.id
  logs_destinations_ids = var.logs_destinations_ids
}
