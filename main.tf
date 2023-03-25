terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_container_cluster" "primary" {
  name              = "my-gke-cluster"
  location          = "us-west1"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  cluster    = google_container_cluster.primary.name
  location   = google_container_cluster.primary.location
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-medium"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "kn" {
  metadata {
    name = "kn-app"
  }
}

resource "kubernetes_deployment" "kd" {
  metadata {
    name = "kd-app"
    namespace = kubernetes_namespace.kn.metadata.0.name
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "kd-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "kd-app"
        }
      }

      spec {
        container {
          image = var.docker_image
          name  = "kd-app"
          port {
            container_port = 3000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "ks" {
  metadata {
    name = "ks-app"
    namespace = kubernetes_namespace.kn.metadata.0.name
  }

  spec {
    selector = {
      app = kubernetes_deployment.kd.spec.0.template.0.metadata.0.labels.app
    }

    port {
      port        = 80 # to use the default port for the application
      target_port = 3000
    }

    type = "LoadBalancer"
  }
}
