variable "frontend_image" {
  type    = string
  default = "saifgharbi/gharbisaif_5arctic8_gestionprojets-frontend:13"
}

resource "kubernetes_deployment_v1" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace_v1.devops.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          app = "frontend"
        }
      }

      spec {
        container {
          name  = "frontend"
          image = var.frontend_image

          port {
            container_port = 80
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }

          startup_probe {
            http_get {
              path = "/"
              port = 80
            }
            period_seconds    = 5
            timeout_seconds   = 3
            failure_threshold = 60
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            period_seconds  = 10
            timeout_seconds = 3
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service_v1.backend]

  timeouts {
    create = "15m"
    update = "15m"
  }
}

resource "kubernetes_service_v1" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace_v1.devops.metadata[0].name
  }

  spec {
    selector = {
      app = "frontend"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}
