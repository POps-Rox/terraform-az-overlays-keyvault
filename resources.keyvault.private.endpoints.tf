# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#---------------------------------------------------------
# Private Link for Sql - Default is "false" 
#---------------------------------------------------------
data "azurerm_virtual_network" "vnet" {
  count               = var.enable_private_endpoint && var.existing_virtual_network_name != null ? 1 : 0
  name                = var.existing_virtual_network_name
  resource_group_name = local.resource_group_name
}

data "azurerm_subnet" "snet" {
  count                = var.enable_private_endpoint && var.existing_private_subnet_name != null ? 1 : 0
  name                 = var.existing_private_subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.0.name
  resource_group_name  = local.resource_group_name
}

resource "azurerm_private_endpoint" "pep" {
  count               = var.enable_private_endpoint && var.existing_private_subnet_name != null ? 1 : 0
  name                = format("%s-private-endpoint", local.kv_name)
  location            = local.location
  resource_group_name = local.resource_group_name
  subnet_id           = data.azurerm_subnet.snet.0.id
  tags                = merge({ "Name" = format("%s-private-endpoint", local.kv_name) }, var.add_tags, )

  private_service_connection {
    name                           = "keyvault-privatelink"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.this.0.id
    subresource_names              = ["vault"]
  }
}

#------------------------------------------------------------------
# DNS zone & records for KV Private endpoints - Default is "false" 
#------------------------------------------------------------------
data "azurerm_private_endpoint_connection" "pepc" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = azurerm_private_endpoint.pep.0.name
  resource_group_name = local.resource_group_name
  depends_on          = [azurerm_key_vault.this]
}

resource "azurerm_private_dns_zone" "dns_zone" {
  count               = var.existing_private_dns_zone == null && var.enable_private_endpoint ? 1 : 0
  name                = var.environment == "public" ? "privatelink.vaultcore.azure.net" : "privatelink.vaultcore.usgovcloudapi.net"
  resource_group_name = local.resource_group_name
  tags                = merge({ "Name" = format("%s", "Azure-Key-Vault-Private-DNS-Zone") }, var.add_tags, )
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  count                = var.existing_private_dns_zone == null && var.enable_private_endpoint ? 1 : 0
  name                 = "vnet-private-zone-link"
  private_dns_zone_id  = azurerm_private_dns_zone.dns_zone.0.id
  virtual_network_id   = data.azurerm_virtual_network.vnet.0.id
  registration_enabled = false
  tags                 = merge({ "Name" = format("%s", "vnet-private-zone-link") }, var.add_tags, )
}

resource "azurerm_private_dns_a_record" "a_rec" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = local.private_dns_a_record_name
  private_dns_zone_id = var.existing_private_dns_zone == null ? azurerm_private_dns_zone.dns_zone.0.id : data.azurerm_private_dns_zone.existing.0.id
  ttl                 = 300
  records             = [data.azurerm_private_endpoint_connection.pepc.0.private_service_connection.0.private_ip_address]
}

#----------------------------------------------------------------------------------------------
# DNS zone & records for KV Private endpoints - Different DNS Zone in different subscription
#----------------------------------------------------------------------------------------------

##----------------------------------------------------------------------------- 
## Below resource will create vnet link in existing private dns zone. 
## Vnet link will be created when existing private dns zone is in different subscription. 
##-----------------------------------------------------------------------------
resource "azurerm_private_dns_zone_virtual_network_link" "vent-link-1" {
  provider = azurerm.hub
  count    = var.enable_private_endpoint && var.connect_to_dns_in_hub_subscription == true ? 1 : 0

  name                = var.existing_private_dns_zone == null ? format("%s-pdz-vnet-link-kv", var.org_name) : format("%s-pdz-vnet-link-kv-1", var.org_name)
  private_dns_zone_id = var.existing_private_dns_zone == null ? azurerm_private_dns_zone.dns_zone.0.id : data.azurerm_private_dns_zone.hub.0.id
  virtual_network_id  = var.hub_virtual_network_name
  tags                = local.default_tags
}

##----------------------------------------------------------------------------- 
## Below resource will create dns A record for private ip of private endpoint in private dns zone. 
## This resource will be created when private dns is in different subscription. 
##-----------------------------------------------------------------------------
resource "azurerm_private_dns_a_record" "arecord-1" {
  count = var.enable_private_endpoint && var.connect_to_dns_in_hub_subscription == true ? 1 : 0

  provider            = azurerm.hub
  name                = azurerm_key_vault.this.0.name
  private_dns_zone_id = var.existing_private_dns_zone == null ? azurerm_private_dns_zone.dns_zone.0.id : data.azurerm_private_dns_zone.hub.0.id
  ttl                 = 3600
  records             = [data.azurerm_private_endpoint_connection.pepc.0.private_service_connection.0.private_ip_address]
  tags                = local.default_tags
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}