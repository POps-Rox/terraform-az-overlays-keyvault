# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

output "key_vault_id" {
  description = "ID of the Key Vault."
  value       = one(concat(azurerm_key_vault.this[*].id, azurerm_key_vault_managed_hardware_security_module.keyvault_hsm[*].id))
}

output "key_vault_name" {
  description = "Name of the Key Vault."
  value       = one(concat(azurerm_key_vault.this[*].name, azurerm_key_vault_managed_hardware_security_module.keyvault_hsm[*].name))
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = one(azurerm_key_vault.this[*].vault_uri)
}

output "key_vault_hsm_uri" {
  description = "The URI of the Key Vault Managed Hardware Security Module, used for performing operations on keys."
  value       = one(azurerm_key_vault_managed_hardware_security_module.keyvault_hsm[*].hsm_uri)
}

output "keys" {
  value       = { for key in azurerm_key_vault_key.keys : key.name => key }
  description = "Blocks containing configuration of each key."
  # module.MODULE_NAME.keys["KEY_NAME"].id
}

output "secrets" {
  value       = { for secret in azurerm_key_vault_secret.secrets : secret.name => secret }
  description = "Blocks containing configuration of each secret."
  sensitive   = true
  # module.MODULE_NAME.keys["SECRET_NAME"].id
}

output "contacts" {
  value       = azurerm_key_vault_certificate_contacts.this[*].contact
  description = "Blocks containing each contact."
}
