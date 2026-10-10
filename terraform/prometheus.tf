resource "kubernetes_config_map_v1" "prometheus" {
  metadata {
    name      = "prometheus-config"
    namespace = kubernetes_namespace_v1.devops.metadata[0].name
  }

  data = {
    "prometheus.yml" = yamlencode({
      global = {
        scrape_interval = "30s"
      }

      scrape_configs = [
        {
          job_name     = "spring-backend"
          metrics_path = "/actuator/prometheus"
          static_configs = [
            {
              targets = ["backend:8080"]
            }
          ]
        },
        {
          job_name = "prometheus"
          static_configs = [
            {
              targets = ["localhost:9090"]
            }
          ]
        }
      ]
    })
  }
}

resource "kubernetes_persistent_volume_claim_v1" "prometheus" {
  metadata {
    name      = "prometheus-data"
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

resource "kubernetes_deployment_v1" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace_v1.devops.metadata[0].name
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        app = "prometheus"
      }
    }

    template {
      metadata {
        labels = {
          app = "prometheus"
        }

        annotations = {
          config_checksum = sha256(
            kubernetes_config_map_v1.prometheus.data["prometheus.yml"]
          )
        }
      }

      spec {
        security_context {
          run_as_user  = 65534
          run_as_group = 65534
          fs_group     = 65534
        }

        container {
          name              = "prometheus"
          image             = "prom/prometheus:latest"
          image_pull_policy = "IfNotPresent"

          args = [
            "--config.file=/etc/prometheus/prometheus.yml",
            "--storage.tsdb.path=/prometheus",
            "--storage.tsdb.retention.time=1d",
            "--storage.tsdb.retention.size=500MB"
          ]

          port {
            container_port = 9090
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
            name       = "config"
            mount_path = "/etc/prometheus"
            read_only  = true
          }

          volume_mount {
            name       = "data"
            mount_path = "/prometheus"
          }

          startup_probe {
            http_get {
              path = "/-/ready"
              port = 9090
            }
            period_seconds    = 5
            timeout_seconds   = 3
            failure_threshold = 60
          }

          readiness_probe {
            http_get {
              path = "/-/ready"
              port = 9090
            }
            timeout_seconds = 3
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map_v1.prometheus.metadata[0].name
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.prometheus.metadata[0].name
          }
        }
      }
    }
  }

  timeouts {
    create = "15m"
    update = "15m"
  }
}

resource "kubernetes_service_v1" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace_v1.devops.metadata[0].name
  }

  spec {
    selector = {
      app = "prometheus"
    }

    port {
      port        = 9090
      target_port = 9090
    }

    type = "ClusterIP"
  }
}
