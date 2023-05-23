resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone

  network                  = google_compute_network.custom.name
  subnetwork               = google_compute_subnetwork.custom.name
  remove_default_node_pool = true
  initial_node_count       = 1

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "192.168.30.0/28"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.custom.secondary_ip_range.1.range_name
    services_secondary_range_name = google_compute_subnetwork.custom.secondary_ip_range.0.range_name
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "192.169.1.1/32"
      display_name = "net1"
    }
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = google_container_cluster.primary.name
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 3

  node_config {
    labels = {
      env = "dev"
    }

    machine_type = var.cluster_machine_type
    preemptible  = true

    service_account = google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
  lifecycle {
    ignore_changes = [node_config]
  }
}