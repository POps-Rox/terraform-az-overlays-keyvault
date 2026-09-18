# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

data "azurerm_client_config" "current_config" {
}

data "azurerm_private_dns_zone" "hub" {
  provider = azurerm.hub
  count    = var.enable_private_endpoint && var.connect_to_dns_in_hub_subscription && var.existing_private_dns_zone != null ? 1 : 0

  name                = var.existing_private_dns_zone
  resource_group_name = var.existing_private_dns_zone_resource_group_name
}

data "azurerm_private_dns_zone" "existing" {
  count = var.enable_private_endpoint && var.existing_private_dns_zone != null ? 1 : 0

  name                = var.existing_private_dns_zone
  resource_group_name = local.resource_group_name
}
