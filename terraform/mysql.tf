variable "mysql_password" {
  description = "Password for the application database user"
  type        = string
  sensitive   = true
}

variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
  sensitive   = true
}

resource "kubernetes_secret_v1" "mysql" {
  metadata {
    name      = "mysql-credentials"
    namespace = kubernetes_namespace_v1.devops.metadata[0].name
  }

  data = {
    MYSQL_ROOT_PASSWORD = var.mysql_root_password
    MYSQL_PASSWORD      = var.mysql_password
  }
}

resource "kubernetes_persistent_volume_claim_v1" "mysql" {
  metadata {
    name      = "mysql-data"
    namespace = kubernetes_namespace_v1.devops.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "standard"

    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_deployment_v1" "mysql" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace_v1.devops.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mysql"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }

      spec {
        container {
          name  = "mysql"
          image = "mysql:8.4"

          port {
            container_port = 3306
          }

          env {
            name  = "MYSQL_DATABASE"
            value = "test_db"
          }

          env {
            name  = "MYSQL_USER"
            value = "devops"
          }

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.mysql.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "768Mi"
            }
          }

          volume_mount {
            name       = "mysql-data"
            mount_path = "/var/lib/mysql"
          }

          startup_probe {
            exec {
              command = ["mysqladmin", "ping", "-h", "127.0.0.1"]
            }
            period_seconds    = 5
            failure_threshold = 60
          }

          readiness_probe {
            exec {
              command = ["mysqladmin", "ping", "-h", "127.0.0.1"]
            }
            period_seconds = 10
          }
        }

        volume {
          name = "mysql-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.mysql.metadata[0].name
          }
        }
      }
    }
  }

  timeouts {
    create = "10m"
    update = "10m"
  }
}

resource "kubernetes_service_v1" "mysql" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace_v1.devops.metadata[0].name
  }

  spec {
    selector = {
      app = "mysql"
    }

    port {
      port        = 3306
      target_port = 3306
    }

    type = "ClusterIP"
  }
}
