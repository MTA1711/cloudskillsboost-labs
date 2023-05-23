resource "google_compute_network" "custom" {
  name                    = "orca-build-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "custom" {
  name          = "orca-build-subnet"
  ip_cidr_range = "192.168.0.0/16"
  region        = var.region
  network       = google_compute_network.custom.id

  secondary_ip_range {
    range_name    = "orca-service-range"
    ip_cidr_range = "192.168.10.0/24"
  }

  secondary_ip_range {
    range_name    = "orca-pod-range"
    ip_cidr_range = "192.168.20.0/24"
  }
}

resource "google_compute_address" "bastion_ip" {
  project      = var.project_id
  address_type = "INTERNAL"
  region       = var.region
  subnetwork   = google_compute_subnetwork.custom.self_link
  name         = "orca-bastion-ip"
  address      = "192.168.1.1"
  description  = "An internal IP address for orca bastion host"
}

resource "google_compute_instance" "default" {
  project      = var.project_id
  zone         = var.zone
  name         = "bastion-host"
  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network    = google_compute_network.custom.self_link
    subnetwork = google_compute_subnetwork.custom.self_link
    network_ip = google_compute_address.bastion_ip.address
  }
}