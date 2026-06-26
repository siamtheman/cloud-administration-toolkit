# Define the Providers.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = false
    }
  }
}

# Fetch your current public IP address automatically.
data "http" "my_public_ip" {
  url = "https://api.ipify.org"
}

# Retrieve current client/tenant details for deployment authority.
data "azurerm_client_config" "current" {}

# Create a Resource Group.
resource "azurerm_resource_group" "rg" {
  name     = "your_resource_group"
  location = "West US"
}

# Create the Virtual Network.
resource "azurerm_virtual_network" "vnet" {
  name                = "your_domain_name"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create a Subnet.
resource "azurerm_subnet" "subnet" {
  name                 = "your_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.KeyVault"]
}

# Deploy a User-Assigned Managed Identity for your workload/VM.
resource "azurerm_user_assigned_identity" "script_identity" {
  name                = "id-automation-runner"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Helper to ensure Key Vault name uniqueness.
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Deploy an Azure Key Vault with strict firewall rules.
resource "azurerm_key_vault" "kv" {
  name                       = "kv-secure-secrets-${random_string.suffix.result}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = [chomp(data.http.my_public_ip.response_body)]
    virtual_network_subnet_ids = [azurerm_subnet.subnet.id]
  }
}

# Grant your Managed Identity explicit "Key Vault Secrets User" rights via Azure RBAC.
resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.script_identity.principal_id
}

# Grant yourself "Key Vault Secrets Officer" rights so you can add secrets via CLI/Terraform.
resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Create the Log Analytics Workspace (LAW).
resource "azurerm_log_analytics_workspace" "security_law" {
  name                = "your_workspace_name"
  location            = "westus" # Match your existing resource group location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018" # Standard tier required for Sentinel
  retention_in_days   = 30
}

# Onboard Microsoft Sentinel onto the Workspace.
resource "azurerm_log_analytics_solution" "sentinel_onboarding" {
  solution_name         = "SecurityInsights"
  location              = azurerm_log_analytics_workspace.security_law.location
  resource_group_name   = azurerm_log_analytics_workspace.security_law.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.security_law.id
  workspace_name        = azurerm_log_analytics_workspace.security_law.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityInsights"
  }
}

# Connect Entra ID Sign-In Logs directly to your Sentinel Workspace.
resource "azurerm_monitor_aad_diagnostic_setting" "entra_to_sentinel" {
  name                       = "entra-signins-to-sentinel"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.security_law.id
# Captures standard user interactive sign-ins.
  enabled_log {
    category = "SignInLogs"
  }
# Captures service principal / non-interactive logins (automation scripts).
  enabled_log {
    category = "NonInteractiveUserSignInLogs"
  }
}
