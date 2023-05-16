resource "google_compute_network" "default" {
  name                    = "orca-build-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges" {
  name          = "orca-build-subnet"
  ip_cidr_range = "10.2.0.0/16"
  region        = var.region
  network       = google_compute_network.default.id

  secondary_ip_range {
    range_name    = "orca-build-subnet-secondary-range"
    ip_cidr_range = "192.168.10.0/24"
  }
}
