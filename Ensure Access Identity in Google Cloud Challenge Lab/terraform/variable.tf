variable "project_id" {
  type        = string
  description = "The project ID"
}

variable "region" {
  type        = string
  description = "Region where resources will be created"
}

variable "zone" {
  type        = string
  description = "Zone where resources will be created"
}

variable "custom_role_id" {
  type        = string
  description = "Custom role id"
  default     = "orca-custom-role"
}

variable "sa_id" {
  type        = string
  description = "Service Account ID"
  default     = "orca-sa"
}

variable "sa_display_name" {
  type        = string
  description = "Service Account display name"
  default     = "GKE cluster Node SA"
}

variable "cluster_name" {
  type        = string
  description = "Orca cluster name"
  default     = "orca-gke-cluster"
}

variable "cluster_machine_type" {
  type        = string
  description = "Orca GKE cluster machine type"
  default     = "e2-medium"
}
