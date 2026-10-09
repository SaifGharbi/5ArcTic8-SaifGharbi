terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
  }
}

provider "kubernetes" {
  config_path    = pathexpand("~/.kube/config")
  config_context = "minikube"
}

resource "kubernetes_namespace_v1" "devops" {
  metadata {
    name = "devops"
  }
}

output "namespace" {
  value = kubernetes_namespace_v1.devops.metadata[0].name
}
