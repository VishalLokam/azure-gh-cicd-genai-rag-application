#This repository is for creating resources that should be already present for the project to work
data "azurerm_client_config" "current" {

}

resource "azuread_group" "admin_entraid_group" {
  display_name     = "Platform Administrators"
  owners           = [data.azurerm_client_config.current.object_id]
  members          = [data.azurerm_client_config.current.object_id]
  security_enabled = true
}

resource "azurerm_resource_group" "bootstrap" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "bootstrapsstorageacc" {
  name                     = var.backend_storage_account_name
  resource_group_name      = azurerm_resource_group.bootstrap.name
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = var.location
}

resource "azurerm_storage_container" "terraform_state" {
  name                  = var.backend_storage_container_name
  storage_account_id    = azurerm_storage_account.bootstrapsstorageacc.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "terraform_state_blob_contributor" {
  scope                            = azurerm_storage_container.terraform_state.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azuread_service_principal.github_oidc_sp.object_id
  skip_service_principal_aad_check = true
  principal_type                   = "ServicePrincipal"
}
