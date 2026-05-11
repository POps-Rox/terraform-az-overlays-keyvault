# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#------------------------------------------------------------
# Key Vault configuration - Default (required). 
#------------------------------------------------------------
resource "azurerm_key_vault" "this" {
  count = var.managed_hardware_security_module_enabled ? 0 : 1

  name = local.kv_name

  location            = local.location
  resource_group_name = local.resource_group_name

  tenant_id = local.tenant_id

  sku_name = var.sku_name

  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment

  purge_protection_enabled   = var.enable_purge_protection
  soft_delete_retention_days = var.soft_delete_retention_days

  rbac_authorization_enabled = var.rbac_authorization_enabled

  public_network_access_enabled = var.public_network_access_enabled

  dynamic "network_acls" {
    for_each = var.network_acls == null ? [] : [var.network_acls]
    iterator = acl

    content {
      bypass                     = acl.value.bypass
      default_action             = acl.value.default_action
      ip_rules                   = acl.value.ip_rules
      virtual_network_subnet_ids = acl.value.virtual_network_subnet_ids
    }
  }

  dynamic "contact" {
    for_each = var.certificate_contacts
    content {
      email = contact.value.email
      name  = contact.value.name
      phone = contact.value.phone
    }
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }

  tags = merge(local.default_tags, var.add_tags)
}

moved {
  from = azurerm_key_vault.this
  to   = azurerm_key_vault.this[0]
}