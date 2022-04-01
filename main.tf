terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/google"
      version = ">= 2.5.0"
    }
  }
  backend "gcs" {
    credentials = "/Users/jnimmala/Downloads/gcp-montego-project-bc6765945842.json"
    bucket      = "my-bucket-70870eb"
    prefix      = "terraform/state"
  }
}

provider "google" {
  credentials = var.gcp_credentials_json_path
  project     = var.gcp_project_id
  region      = var.gcp_region
}

resource "google_compute_network" "custom" {
  project                 = var.gcp_project_id
  name                    = "gke-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "custom" {
  name          = "gke-subnet"
  ip_cidr_range = "172.16.0.0/16"
  project       = var.gcp_project_id
  region        = var.gcp_region
  network       = google_compute_network.custom.id
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.1.0.0/24"
  }
  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "192.168.0.0/22"
  }
}

resource "google_container_cluster" "primary" {
  provider = "google-beta"
  project  = var.gcp_project_id
  name     = "gcp-montego-gke"
  location = var.gcp_zone

  # Use a separately managed node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  network                = google_compute_network.custom.id
  subnetwork             = google_compute_subnetwork.custom.id
  enable_shielded_nodes  = true
  #enable_binary_authorization = true
  #enable_tpu                  = true

  ip_allocation_policy {}

  # Creating a cluster without master authorized networks is not possible, so we just mimic
  # openness by allowing access from anywhere, see https://issuetracker.google.com/issues/123071694
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "allow_any"
    }
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    istio_config {
      disabled = false
    }
  }
  #lifecycle {
  #  prevent_destroy = true
  #}
}

resource "google_container_node_pool" "primary" {
  project            = var.gcp_project_id
  name               = "gcp-montego-node-pool"
  location           = "${var.gcp_zone}"
  initial_node_count = "${google_container_cluster.primary.initial_node_count}"
  cluster            = "${google_container_cluster.primary.name}"

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      env       = "dev"
      terraform = "true"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }

    machine_type = "n1-standard-1"
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    min_node_count = "1"
    max_node_count = "2"
  }
}

