# Functional tests for the key vault overlay.
#
# These use mock_provider, so they execute WITHOUT Azure credentials and are
# safe to run on pull requests from forks in a public repository.

mock_provider "azurerm" {
  mock_data "azurerm_resource_group" {
    defaults = {
      location = "eastus"
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing"
    }
  }

  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "11111111-1111-1111-1111-111111111111"
      subscription_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {
  alias = "hub"
}

mock_provider "azapi" {}

mock_provider "popsrox" {
  mock_data "popsrox_resource_name" {
    defaults = {
      result = "anoaeustestdevkv"
    }
  }
}

override_module {
  target = module.mod_azure_region_lookup
  outputs = {
    location_cli   = "eastus"
    location_short = "eus"
  }
}

variables {
  location                     = "eastus"
  environment                  = "public"
  deploy_environment           = "dev"
  workload_name                = "testworkload"
  org_name                     = "anoa"
  existing_resource_group_name = "rg-existing"
  tenant_id                    = "11111111-1111-1111-1111-111111111111"
}

# ---------------------------------------------------------------------------
# Naming precedence
# ---------------------------------------------------------------------------

run "generated_key_vault_name_is_used_when_no_custom_name_given" {
  command = plan

  assert {
    condition     = azurerm_key_vault.this[0].name == "anoaeustestdevkv"
    error_message = "Expected the generated popsrox name when custom_kv_name is unset, got: ${azurerm_key_vault.this[0].name}"
  }
}

run "custom_key_vault_name_overrides_generated_name" {
  command = plan

  variables {
    custom_kv_name = "explicit-kv-name"
  }

  assert {
    condition     = azurerm_key_vault.this[0].name == "explicit-kv-name"
    error_message = "custom_kv_name must take precedence over the generated name, got: ${azurerm_key_vault.this[0].name}"
  }
}

run "empty_custom_key_vault_name_falls_through_to_generated_name" {
  command = plan

  variables {
    custom_kv_name = ""
  }

  assert {
    condition     = azurerm_key_vault.this[0].name == "anoaeustestdevkv"
    error_message = "An empty custom_kv_name must fall through to the generated name, got: ${azurerm_key_vault.this[0].name}"
  }
}

# ---------------------------------------------------------------------------
# Conditional resources
# ---------------------------------------------------------------------------

run "key_vault_is_created_and_hsm_is_not_created_by_default" {
  command = plan

  assert {
    condition     = length(azurerm_key_vault.this) == 1
    error_message = "managed_hardware_security_module_enabled defaults to false, so one key vault should be planned"
  }

  assert {
    condition     = length(azurerm_key_vault_managed_hardware_security_module.keyvault_hsm) == 0
    error_message = "managed_hardware_security_module_enabled defaults to false, so no managed HSM should be planned"
  }
}

run "managed_hsm_replaces_key_vault_when_enabled" {
  command = plan

  variables {
    managed_hardware_security_module_enabled = true
    custom_hsm_name                          = "explicit-hsm-name"
  }

  assert {
    condition     = length(azurerm_key_vault.this) == 0
    error_message = "Enabling managed_hardware_security_module_enabled should suppress the normal key vault"
  }

  assert {
    condition     = length(azurerm_key_vault_managed_hardware_security_module.keyvault_hsm) == 1
    error_message = "Enabling managed_hardware_security_module_enabled should plan exactly one managed HSM"
  }

  assert {
    condition     = azurerm_key_vault_managed_hardware_security_module.keyvault_hsm[0].name == "explicit-hsm-name"
    error_message = "custom_hsm_name must be applied to the managed HSM"
  }
}

run "locks_are_not_created_by_default" {
  command = plan

  assert {
    condition     = length(azurerm_management_lock.key_vault_level_lock) == 0
    error_message = "enable_resource_locks defaults to false, so no key vault lock should be planned"
  }
}

run "enabling_locks_creates_exactly_one_key_vault_lock" {
  command = plan

  variables {
    enable_resource_locks = true
  }

  assert {
    condition     = length(azurerm_management_lock.key_vault_level_lock) == 1
    error_message = "enable_resource_locks = true must create exactly one key vault lock"
  }

  assert {
    condition     = azurerm_management_lock.key_vault_level_lock[0].lock_level == "CanNotDelete"
    error_message = "lock_level should default to CanNotDelete"
  }

  assert {
    condition     = azurerm_management_lock.key_vault_level_lock[0].name == "anoaeustestdevkv-CanNotDelete-lock"
    error_message = "Lock name must be derived from the key vault name and lock level, got: ${azurerm_management_lock.key_vault_level_lock[0].name}"
  }
}

run "lock_level_is_configurable" {
  command = plan

  variables {
    enable_resource_locks = true
    lock_level            = "ReadOnly"
  }

  assert {
    condition     = azurerm_management_lock.key_vault_level_lock[0].lock_level == "ReadOnly"
    error_message = "lock_level must be honoured when supplied"
  }
}

# ---------------------------------------------------------------------------
# Tagging and location passthrough
# ---------------------------------------------------------------------------

run "default_and_caller_supplied_tags_are_merged_in" {
  command = plan

  variables {
    add_tags = {
      costCenter = "cc-1234"
    }
  }

  assert {
    condition     = azurerm_key_vault.this[0].tags["deployedBy"] == "AzureNoOpsTF [default]"
    error_message = "Default tags should include the deployedBy workspace tag"
  }

  assert {
    condition     = azurerm_key_vault.this[0].tags["environment"] == "public"
    error_message = "Default tags should include the environment input"
  }

  assert {
    condition     = azurerm_key_vault.this[0].tags["costCenter"] == "cc-1234"
    error_message = "Tags passed via add_tags must appear on the key vault"
  }
}

run "location_is_passed_through_from_existing_resource_group" {
  command = plan

  assert {
    condition     = azurerm_key_vault.this[0].location == "eastus"
    error_message = "The key vault location must come from the selected resource group location"
  }
}
