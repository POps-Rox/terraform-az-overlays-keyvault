# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resource "azurerm_role_assignment" "rbac_keyvault_administrator" {
  for_each = toset(var.rbac_authorization_enabled && !var.managed_hardware_security_module_enabled ? var.admin_objects_ids : [])

  scope                = one(azurerm_key_vault.this[*].id)
  role_definition_name = "Key Vault Administrator"
  principal_id         = each.value
  principal_type       = var.role_assignment_principal_type
}

resource "azurerm_role_assignment" "rbac_keyvault_secrets_users" {
  for_each = toset(var.rbac_authorization_enabled && !var.managed_hardware_security_module_enabled ? var.reader_objects_ids : [])

  scope                = one(azurerm_key_vault.this[*].id)
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
  principal_type       = var.role_assignment_principal_type
}

resource "azurerm_role_assignment" "rbac_keyvault_reader" {
  for_each = toset(var.rbac_authorization_enabled && !var.managed_hardware_security_module_enabled ? var.reader_objects_ids : [])

  scope                = one(azurerm_key_vault.this[*].id)
  role_definition_name = "Key Vault Reader"
  principal_id         = each.value
  principal_type       = var.role_assignment_principal_type
}