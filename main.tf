# Define the provider and required variables
provider "google" {
  project = "rosy-crawler-389806"
  region  = "europe-west1"
}

variable "backend_service_name" {
  description = "Name of the backend service"
  default = "backend"
}

variable "certificate_name" {
  description = "Name of the SSL certificate"
  default = "certificate"
}

variable "domain_name" {
  default="cloudsecurity.team"
}

# Enable the Compute Engine API
resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
  project = "147439111951"
}

# Create a backend service
resource "google_compute_backend_service" "my_backend_service" {
  name        = var.backend_service_name
  protocol    = "HTTPS"
  timeout_sec = 30

  health_checks = ["my-helth-check"]

  backend {
    group = "my-instance-group"
  }
}

# Create a URL map
resource "google_compute_url_map" "my_url_map" {
  name            = "my-url-map"
  default_service = google_compute_backend_service.my_backend_service.self_link
}

resource "google_compute_managed_ssl_certificate" "lb_default" {
  provider = google-beta
  name     = "myservice-ssl-cert"

  managed {
    domains = [var.domain_name]
  }
}

# Create a target HTTPS proxy
resource "google_compute_target_https_proxy" "my_target_https_proxy" {
  name        = "my-target-https-proxy"
  url_map     = google_compute_url_map.my_url_map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.self_link]
}



# Configure the forwarding rule
resource "google_compute_global_forwarding_rule" "my_forwarding_rule" {
  name                  = "my-forwarding-rule"
  target                = google_compute_target_https_proxy.my_target_https_proxy.self_link
  port_range            = "443"
  ip_address            = "0.0.0.0"
  ip_protocol           = "TCP"
}

# Configure the HTTPS health check
resource "google_compute_health_check" "my_health_check" {
  name                = "my-helth-check"
  timeout_sec         = 10
  check_interval_sec  = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  https_health_check {
    port               = 443
    request_path       = "/"
    response            = "HTTP_200"
  }
}