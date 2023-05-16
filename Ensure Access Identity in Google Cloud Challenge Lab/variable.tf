variable "project_id" {
  type        = string
  description = "The project ID"
}

variable "region" {
  type        = string
  description = "Region where resources will be created"
}

variable "custom_role_id" {
  type        = string
  description = "Custom role id"
}

variable "sa_id" {
  type        = string
  description = "Service Account ID"
}

variable "sa_display_name" {
  type        = string
  description = "Service Account display name"
}
