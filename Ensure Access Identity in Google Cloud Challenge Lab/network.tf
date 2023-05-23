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

resource "google_compute_subnetwork" "mgmt-subnet" {
  name          = "orca-mgmt-subnet"
  ip_cidr_range = "192.169.1.0/24"
  region        = var.region
  network       = google_compute_network.custom.id
}

resource "google_compute_address" "bastion_ip" {
  project      = var.project_id
  address_type = "INTERNAL"
  region       = var.region
  subnetwork   = google_compute_subnetwork.mgmt-subnet.self_link
  name         = "orca-bastion-ip"
  address      = "192.169.1.1"
  description  = "An internal IP address for orca bastion host"
}

resource "google_compute_instance" "default" {
  project      = var.project_id
  zone         = var.zone
  name         = "orca-jumphost"
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

  metadata_startup_script = data.template_file.default.rendered
  depends_on = [ google_container_node_pool.primary_nodes, google_container_cluster.primary ]
}

data "template_file" "default" {
  template = file("${path.module}/assets/startup.sh")
  vars = {
    CLUSTER_NAME = google_container_cluster.primary.name
    PROJECT_ID   = var.project_id
    CLUSTER_ZONE = var.zone
  }
}

resource "google_compute_router" "router" {
  project = var.project_id
  name    = "orca-nat-router"
  network = google_compute_network.custom.self_link
  region  = var.region
}

module "cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 1.2"
  project_id = var.project_id
  region     = var.region
  router     = google_compute_router.router.name
  name       = "orca-nat-config"

}

resource "google_compute_firewall" "rules" {
  project = var.project_id
  name    = "orca-allow-ssh"
  network = google_compute_network.custom.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.O.O"]
}
