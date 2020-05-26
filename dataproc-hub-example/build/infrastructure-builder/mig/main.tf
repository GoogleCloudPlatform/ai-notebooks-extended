/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# GCP context
provider "google" {
  version = "~> 2.20.2"
}

provider "google-beta" {
  version = ">= 3.18.0"
}

# IAP details.
# If importing existing brand (Oauth Consent Screen), make sure 
# that it is set to 'internal' or google_iap_client will fail.
resource "google_project_service" "project_service" {
  project = var.project_id
  service = "iap.googleapis.com"
}

resource "google_iap_brand" "jupyterhub_iap_brand" {
  provider          = google-beta
  support_email     = var.support_email
  application_title = "JupyterHub Brand"
  project           = google_project_service.project_service.project
}

resource "google_iap_client" "jupyterhub_iap_client" {
  count        = tobool(var.use_iap) == true ? 1 : 0
  provider     = google-beta
  display_name = "Jupyterhub IAP Client"
  brand        =  google_iap_brand.jupyterhub_iap_brand.name
}

# Configure service accounts.
module "service_accounts" {
  source           = "./modules/service_accounts"
  project_id       = var.project_id
  jupyterhub_sa_id = var.jupyterhub_sa_id
  dataproc_sa_id   = var.dataproc_sa_id
}

# Buckets
resource "google_storage_bucket" "gcs_working" {
  project  = var.project_id
  name     = local.gcs_working
  location = var.gcs_buckets_location
  bucket_policy_only = true
  force_destroy = true
}
resource "google_storage_bucket" "gcs_notebooks" {
  project  = var.project_id
  name     = local.gcs_notebooks
  location = var.gcs_buckets_location
  bucket_policy_only = true
  force_destroy = true
}

# Uploads GCS Dataproc config from local folder
resource "google_storage_bucket_object" "dataproc_configs" {
  for_each = toset(var.files_dataproc_configs)
  name     = "configs/${each.value}"
  source   = "${var.local_cluster_configs_location}/${each.value}"
  bucket   = google_storage_bucket.gcs_working.name
}

resource "google_storage_bucket_object" "notebooks_examples" {
  for_each = fileset(var.local_notebooks_example_location, "**")
  name     = "examples/${each.value}"
  source   = "${var.local_notebooks_example_location}/${each.value}"
  bucket   = google_storage_bucket.gcs_working.name
}

# Creates autoscaling policies for Cloud Dataproc. Once deployed, can be attached to a
# cluster by the user from the form or by the admin from the dataproc_configs yaml file.
module "autoscaling_policies" {
  source     = "./modules/autoscaling_policies"
  project_id = var.project_id
}

##################################################################################### 
# KMS keys
#####################################################################################
# Sets up secrets.
module "secrets" {
  source                    = "./modules/secrets"
  project_id                = var.project_id
  oauth_google_clientid     = var.oauth_google_clientid
  oauth_google_clientsecret = var.oauth_google_clientsecret
  postgres_pass             = var.postgres_pass
}

##################################################################################### 
# Network
#####################################################################################
resource "google_compute_network" "jupyterhub_vpc" {
  project                 = var.project_id
  name                    = var.network
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "jupyterhub_subnet" {
  project                  = var.project_id
  name                     = var.subnetwork
  ip_cidr_range            = var.subnet_ip_cidr_range
  network                  = google_compute_network.jupyterhub_vpc.self_link
  region                   = var.jupyterhub_region
  # Required for gcr.io access
  private_ip_google_access = true
}

# IPs
resource "google_compute_global_address" "jupyterhub_ip" {
  project = var.project_id 
  name    = "jupyterhub-ip"
}

resource "google_compute_global_address" "cloudsql_private_ip" {
  provider      = google-beta
  project       = var.project_id

  name          = "cloudsql-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.jupyterhub_vpc.self_link
}

# Firewall rules
resource "google_compute_firewall" "default_fwr" {
  project = var.project_id
  name    = "default-fwr"
  network = google_compute_network.jupyterhub_vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "8080", "1000-2000", "8000"]
  }
}

resource "google_compute_firewall" "dataproc_allow_internal" {
  project = var.project_id
  name    = "dataproc-allow-internal"
  network = google_compute_network.jupyterhub_vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [var.subnet_ip_cidr_range]
}

resource "google_compute_firewall" "lb_fwr" {
  ## firewall rules enabling the load balancer health checks  
  project = var.project_id
  name    = "lb-fwr"
  network = google_compute_network.jupyterhub_vpc.name

  description = "Allows Google health checks and network load balancers access"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["1337"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
}

resource "google_compute_firewall" "iap_fwr" {
  ## firewall rules enabling IAP
  project = var.project_id
  name    = "iap-fwr"
  network = google_compute_network.jupyterhub_vpc.name

  description = "Allows IAP traffic."

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
}

# Cloud DNS
resource "google_dns_record_set" "jupyterhub" {
  count = var.dns_zone == "" ? 0 : 1

  project      = var.project_id
  # Do not forget the trailing dot.
  name         = "${var.domain_name}."
  managed_zone = var.dns_zone
  type         = "A"
  ttl          = 60
  rrdatas = [google_compute_global_address.jupyterhub_ip.address]
}

##################################################################################### 
# Cloud SQL
#####################################################################################
resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta
  network                 = google_compute_network.jupyterhub_vpc.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.cloudsql_private_ip.name]
}

// resource "random_id" "db_name_suffix" {
//   byte_length = 4
// }

# TODO(mayran): Rename this jupyterhub_db_instance
resource "google_sql_database_instance" "jupyterhub_db" {
  project          = var.project_id
  name             = "${var.cloudsql_instance_name_prefix}-${var.jupyterhub_region}"
  region           = var.jupyterhub_region
  database_version = var.cloudsql_version

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = var.cloudsql_db_tier
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.jupyterhub_vpc.self_link
    }
  }

  timeouts {
    delete = "10m"
  }
}

resource "google_sql_user" "users" {
  project  = var.project_id
  name     = var.cloudsql_user_name
  instance = google_sql_database_instance.jupyterhub_db.name
  password = var.postgres_pass
}

resource "google_sql_database" "jupyterhub_db" {
  project  = var.project_id
  name     = var.cloudsql_db_name
  instance = google_sql_database_instance.jupyterhub_db.name
}

##################################################################################### 
# JupyterHub
#####################################################################################
# Uses Terraform registry's terraform-google-modules (supports container-based images)
module "mig_jupyterhub" {
    source                = "./modules/mig_jupyterhub"
    project_id            = var.project_id
    image                 = var.jupyterhub_container_image
    region                = var.jupyterhub_region
    image_port            = var.container_image_port
    service_account       = {
      email  = "${module.service_accounts.jupyterhub_sa.email}", 
      scopes = ["cloud-platform"]
    }
    network               = var.network
    subnetwork            = google_compute_subnetwork.jupyterhub_subnet.self_link
    subnet_ip_cidr_range  = var.subnet_ip_cidr_range
    mig_instance_count    = var.mig_instance_count

    # gce_container's env requires a list of {name=, value=}
    container_env         = [
      for k in keys(local.jupyterhub_container_env): {
        name = "${k}", 
        value = lookup(local.jupyterhub_container_env, k, "KO")
      }
    ]
}

# GCLB
resource "google_compute_managed_ssl_certificate" "jupyterhub_cert" {
  provider = google-beta
  project  = var.project_id 
  #name     = "${replace(var.domain_name}, ".", "-")-cert"
  name     = "jupyterhub-clood-dev-cert"

  managed {
    # Do not forget the trailing dot.
    domains = ["${var.domain_name}."]
  }
}

resource "google_compute_global_forwarding_rule" "jupyterhub_http" {
  project    = var.project_id
  name       = "global-http-rule"
  target     = google_compute_target_http_proxy.jupyterhub.self_link
  ip_address = google_compute_global_address.jupyterhub_ip.address
  port_range = "80"
}

resource "google_compute_global_forwarding_rule" "jupyterhub_https" {
  project    = var.project_id
  name       = "global-https-rule"
  target     = google_compute_target_https_proxy.jupyterhub.self_link
  ip_address = google_compute_global_address.jupyterhub_ip.address
  port_range = "443"
}

resource "google_compute_target_http_proxy" "jupyterhub" {
  name    = "jupyterhub-http-target-proxy"
  project = var.project_id
  url_map = google_compute_url_map.jupyterhub_urlmap.self_link
}

resource "google_compute_target_https_proxy" "jupyterhub" {
  provider         = google-beta
  project          = var.project_id
  name             = "jupyterhub-https-target-proxy"
  url_map          = google_compute_url_map.jupyterhub_urlmap.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.jupyterhub_cert.self_link]
}

resource "google_compute_url_map" "jupyterhub_urlmap" {
  project         = var.project_id
  name            = "jupyterhub-urlmap"
  default_service = google_compute_backend_service.jupyterhub_bks.self_link

  host_rule {
    hosts        = ["${var.domain_name}"]
    path_matcher = "anypaths"
  }

  path_matcher {
    name            = "anypaths"
    default_service = google_compute_backend_service.jupyterhub_bks.self_link

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.jupyterhub_bks.self_link
    }
  }
}

resource "google_compute_backend_service" "jupyterhub_bks" {
  project          = var.project_id
  name             = var.backend_service_name
  port_name        = "http-jupyterhub"
  protocol         = "HTTP"
  session_affinity = "GENERATED_COOKIE"
  timeout_sec      = 30
  
  backend {
    group = module.mig_jupyterhub.managed_instance_group
  }
  
  health_checks = [google_compute_health_check.jupyterhub_hc.self_link]

  // Enables IAP only if asked by the admin. Add [0] because the google_iap_client 
  // gets created using a count. Count helps creating dynamically but add an index.
  dynamic "iap" {
    for_each = tobool(var.use_iap) == true ? [1] : []
    content {
      oauth2_client_id     = google_iap_client.jupyterhub_iap_client[0].client_id
      oauth2_client_secret = google_iap_client.jupyterhub_iap_client[0].secret
    }
  }
}

resource "google_compute_health_check" "jupyterhub_hc" {
  name               = "jupyterhub-hc"
  project            = var.project_id
  check_interval_sec = 10
  timeout_sec        = 5
  tcp_health_check {
    port = var.container_image_port
  }
}