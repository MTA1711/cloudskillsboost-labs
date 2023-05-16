resource "google_project_iam_custom_role" "default" {
  role_id     = var.custom_role_id
  title       = "Orca Cloud Storage Bucket Writer Role"
  description = "Role that allows a principal to add and update objects in Google Cloud Storage buckets"
  permissions = [
    "storage.buckets.get",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.update",
    "storage.objects.create",
  ]
  project = var.project_id
}

resource "google_service_account" "default" {
  account_id   = var.sa_id
  display_name = var.sa_display_name
  project      = var.project_id
}

resource "google_project_iam_member" "default" {
  for_each = toset([
    google_project_iam_custom_role.default.id,
    "roles/monitoring.viewer",
    "roles/monitoring.metricWriter",
    "roles/logging.logWriter",
  ])
  role    = each.value
  member  = "serviceAccount:${google_service_account.default.email}"
  project = var.project_id
}

