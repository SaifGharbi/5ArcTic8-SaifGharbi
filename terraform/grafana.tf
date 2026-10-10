variable "grafana_admin_password" {
  type      = string
  sensitive = true
}

resource "kubernetes_secret_v1" "grafana" {
  metadata {
    name      = "grafana-credentials"
    namespace = kubernetes_namespace_v1.devops.metadata[0].name
  }

  data = {
    admin_password = var.grafana_admin_password
  }
}

resource "kubernetes_config_map_v1" "grafana" {
  metadata {
    name      = "grafana-datasources"
    namespace = kubernetes_namespace_v1.devops.metadata[0].name
  }

  data = {
    "prometheus.yaml" = yamlencode({
      apiVersion = 1
      datasources = [
        {
          name      = "Prometheus"
          uid       = "prometheus"
          type      = "prometheus"
          access    = "proxy"
          url       = "http://prometheus:9090"
          isDefault = true
          editable  = false
        }
      ]
    })
  }
}

resource "kubernetes_persistent_volume_claim_v1" "grafana" {
  metadata {
    name      = "grafana-data"
    namespace = kubernetes_namespace_v1.devops.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "standard"

    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_deployment_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace_v1.devops.metadata[0].name
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        app = "grafana"
      }
    }

    template {
      metadata {
        labels = {
          app = "grafana"
        }

        annotations = {
          config_checksum = sha256(
            kubernetes_config_map_v1.grafana.data["prometheus.yaml"]
          )
        }
      }

      spec {
        security_context {
          run_as_user  = 472
          run_as_group = 472
          fs_group     = 472
        }

        container {
          name              = "grafana"
          image             = "grafana/grafana:latest"
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 3000
          }

          env {
            name  = "GF_SECURITY_ADMIN_USER"
            value = "admin"
          }

          env {
            name = "GF_SECURITY_ADMIN_PASSWORD"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.grafana.metadata[0].name
                key  = "admin_password"
              }
            }
          }

          env {
            name  = "GF_USERS_ALLOW_SIGN_UP"
            value = "false"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          volume_mount {
            name       = "datasources"
            mount_path = "/etc/grafana/provisioning/datasources"
            read_only  = true
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/grafana"
          }

          startup_probe {
            http_get {
              path = "/api/health"
              port = 3000
            }
            period_seconds    = 5
            timeout_seconds   = 3
            failure_threshold = 60
          }

          readiness_probe {
            http_get {
              path = "/api/health"
              port = 3000
            }
            timeout_seconds = 3
          }
        }

        volume {
          name = "datasources"

          config_map {
            name = kubernetes_config_map_v1.grafana.metadata[0].name
          }
        }

        volume {
          name = "data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.grafana.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service_v1.prometheus]

  timeouts {
    create = "15m"
    update = "15m"
  }
}

resource "kubernetes_service_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace_v1.devops.metadata[0].name
  }

  spec {
    selector = {
      app = "grafana"
    }

    port {
      port        = 3000
      target_port = 3000
    }

    type = "ClusterIP"
  }
}
