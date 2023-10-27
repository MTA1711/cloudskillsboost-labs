resource "google_project_service" "project_services" {
  for_each = toset([
    "iap.googleapis.com"
  ])
  project = var.project_id
  service = each.value
}