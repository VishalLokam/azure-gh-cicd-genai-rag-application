variable "subscription_id" {
  description = "Subscription id of the Azure subscription"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token with permission to manage Actions secrets in the repository"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "github_owner" {
  description = "GitHub username that owns the personal repository"
  type        = string
}

variable "repository_name" {
  description = "Name of the github repository"
  type        = string
}

variable "application_display_name" {
  description = "display of the application registration"
  type        = string
}

variable "github_issuer" {
  description = "Federated credential Issuer"
  type        = string
}

variable "default_audience_name" {
  description = "Federated credential audiences"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for bootstrap resources"
  type        = string
}

variable "location" {
  description = "Location for bootstrap resources"
  type        = string
}

variable "backend_storage_account_name" {
  description = "Globally unique storage account name for the remote backend (3-24 lowercase letters or numbers)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.backend_storage_account_name))
    error_message = "backend_storage_account_name must contain 3-24 lowercase letters or numbers."
  }
}

variable "backend_storage_container_name" {
  description = "Storage container for remote backend"
  type        = string
}

