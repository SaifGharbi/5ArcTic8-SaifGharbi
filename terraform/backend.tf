variable "backend_image" {
  type    = string
  default = "saifgharbi/gharbisaif_5arctic8_gestionprojets-backend:13"
}

resource "kubernetes_deployment_v1" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace_v1.devops.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend"
        }
      }

      spec {
        container {
          name  = "backend"
          image = var.backend_image

          port {
            container_port = 8080
          }

          env {
            name  = "SERVER_PORT"
            value = "8080"
          }

          env {
            name  = "SPRING_DATASOURCE_URL"
            value = "jdbc:mysql://mysql:3306/test_db"
          }

          env {
            name  = "SPRING_DATASOURCE_USERNAME"
            value = "devops"
          }

          env {
            name = "SPRING_DATASOURCE_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.mysql.metadata[0].name
                key  = "MYSQL_PASSWORD"
              }
            }
          }

          env {
            name  = "JAVA_TOOL_OPTIONS"
            value = "-XX:MaxRAMPercentage=65.0"
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1"
              memory = "1Gi"
            }
          }

          startup_probe {
            tcp_socket {
              port = 8080
            }
            period_seconds    = 10
            timeout_seconds   = 3
            failure_threshold = 60
          }

          readiness_probe {
            tcp_socket {
              port = 8080
            }
            period_seconds  = 10
            timeout_seconds = 3
          }
        }
      }
    }
  }

  depends_on = [kubernetes_deployment_v1.mysql]

  timeouts {
    create = "15m"
    update = "15m"
  }
}

resource "kubernetes_service_v1" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace_v1.devops.metadata[0].name
  }

  spec {
    selector = {
      app = "backend"
    }

    port {
      port        = 8080
      target_port = 8080
    }

    type = "ClusterIP"
  }
}
