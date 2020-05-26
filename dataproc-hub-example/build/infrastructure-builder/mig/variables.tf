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

variable "credentials_path" {
  description = "Local location of the credentials file used by Terraform"
  default = "tf-credentials.json"
}

variable "gcs_terraform_state" {
  description = "Location of Terraform state off local disk."
}

variable "use_iap" {
  default = true
  description = "Use IAP to protect JupyterHub backend service."
}

# GCP-related variables
variable "project_id" {
    description = "The GCP project ID."
}
variable "domain_name" {
    description = "The domain name where Jupyterhub is accessible ie jupyterhub.example.com."
}
variable "support_email" {
    description = "Support email."
}
variable "dns_zone" {
    description = "The DNS zone for this project."
}
variable "gcs_suffix" {
    description = "String that helps identifying GCP buckets related to this setup."
    default = "h2gcp"
}
# Service accounts
variable "jupyterhub_sa_id" {
    description = "Service Account ID for JupyterHub instances."
    default = "jupyterhub-sa"
}
variable "dataproc_sa_id" {
    description = "Service Account ID for Cloud Dataproc."
    default = "dataproc-sa"
}
# Cloud SQL
variable "cloudsql_db_tier" {
    description = "Cloud SQL Database Tier"
    default = "db-f1-micro"
}
variable "cloudsql_user_name" {
  description = "Cloud SQL user name"
  default = "jupyterhub"
}
variable "cloudsql_version" {
  description = "Cloud SQL version"
  default = "POSTGRES_9_6"
}
variable cloudsql_instance_name_prefix {
  description = "Cloud SQL instance name"
  default = "jupyterhub-db"
}
variable cloudsql_db_name {
  description = "Cloud SQL instance name"
  default = "jupyterhub"
}
# Network
variable "network" {
  description = "The GCP network"
  default     = "jupyterhub-network"
}
variable "subnetwork" {
  description = "The name of the subnetwork to deploy instances and Cloud Dataproc into"
  default     = "jupyterhub-subnet"
}
variable "subnet_ip_cidr_range" {
  description = "IP range for the subnetwork."
  default     = "10.123.0.0/20"
}
# Parameter files
variable "files_autoscaling_policies" {
  description = "Autoscaling policies files to upload from locals.local_cluster_configs_location to gs://gcs_working/configs/"
}
variable "files_dataproc_configs" {
  description = "Autoscaling policies files to upload from locals.local_cluster_autoscaling_location to gs://gcs_working/configs/"
}

variable "backend_service_name" {
  description = "Name of the Backend Service for JupyterHub. Required so we can pass it to the app to get the ID for IAP)"
  default = "jupyterhub-backend-service"
}

# OAuth parameters stored using Secret Manager.
variable "oauth_google_domain" {
  description = "Value of the Oauth Google domain"
}
variable "oauth_google_clientid" {
    description = "Value of the Oauth Client ID."
}
variable "oauth_google_clientsecret" {
    description = "Value of the Oauth Client secret."
}

# 
variable "container_image_port" {
  description = "The port the container exposes for HTTP requests"
  type        = number
  default     = 8080
}

variable "local_cluster_configs_location" {
  description = "Local files location for cluster configs"
  type        = string
  default     = "files/gcs_working_folder/configs"
}
variable "local_notebooks_example_location" {
  description = "Local files location for cluster configs"
  type        = string
  default     = "files/gcs_working_folder/examples"
}

# variable "local_cluster_autoscaling_location" {
#   description = "Local files location for autoscaling policies"
#   type        = string
#   default     = "files/gcs_working_folder/autoscaling"
# }

locals {
    # Cloud Storage prefix that ensures bucket name global uniqueness.
    # Does not include gs://
    gcs_bucket_prefix   = "${var.project_id}-${var.gcs_suffix}" 
    gcs_working         = "${local.gcs_bucket_prefix}-working"
    gcs_notebooks       = "${local.gcs_bucket_prefix}-notebooks"

    # Add gcs path prefix to the file name. Can include gs:// or not (JupyterHub image does not care)
    # autoscaling_policies = join(",", formatlist("gs://${local.gcs_working}/autoscaling/%s", var.files_autoscaling_policies))
    dataproc_configs     = join(",", formatlist("gs://${local.gcs_working}/configs/%s", var.files_dataproc_configs))
    
    # Environment variables passed to the container image of the container VM.
    jupyterhub_container_env = {
      PROJECT                        = var.project_id
      GCS_WORKING                    = local.gcs_working
      GCS_NOTEBOOKS                  = local.gcs_notebooks
      JUPYTERHUB_REGION              = var.jupyterhub_region
      DATAPROC_CONFIGS               = local.dataproc_configs
      DATAPROC_DEFAULT_SUBNET        = google_compute_subnetwork.jupyterhub_subnet.self_link
      DATAPROC_SERVICE_ACCOUNT       = module.service_accounts.dataproc_sa.email
      DATAPROC_LOCATIONS_LIST        = var.dataproc_locations_list
      BACKEND_SERVICE_NAME           = tobool(var.use_iap) == true ? var.backend_service_name : ""
      OAUTH_GOOGLE_CALLBACK_URL      = "https://${var.domain_name}/hub/oauth_callback"
      OAUTH_GOOGLE_DOMAIN            = var.oauth_google_domain
      PROXY_PORT                     = var.container_image_port
      SPAWNER_DEFAULT_URL            = var.spawner_default_url
      DATAPROC_ALLOW_CUSTOM_CLUSTERS = var.dataproc_allow_custom_clusters
      DATAPROC_MACHINE_TYPES_LIST    = var.dataproc_machine_types_list
      GCS_EXAMPLES_PATH              = coalesce(var.gcs_examples_path, "${google_storage_bucket.gcs_working.name}/examples")
      
      # Reads secrets reference from Secret Manager
      OAUTH_GOOGLE_CLIENTID     = module.secrets.oauth_google_clientid.secret_id
      OAUTH_GOOGLE_CLIENTSECRET = module.secrets.oauth_google_clientsecret.secret_id
      POSTGRES_PASS             = module.secrets.postgres_pass.secret_id

      POSTGRES_USER             = var.cloudsql_user_name
      POSTGRES_HOST             = google_sql_database_instance.jupyterhub_db.private_ip_address
    }
}

# Cloud SQL PostgreSQL credentials
variable "postgres_pass" {
  description = "Value of the PostgreSQL password."
}

# JupuyterHub variables
variable "proxy_port" {
  description = "Port where JupyterHub is available"
  default     = 8000
}
variable "spawner_default_url" {
  description = "Whether to open the Jupyter interface on Jupyterlab or the directory tree."
}
variable "jupyterhub_container_image" {
  description = "Path to the container image in the registry."
}
variable "gcs_buckets_location" {
  description = "Location where to create buckets."
}
variable "jupyterhub_region" {
  description = "Region where to deploy JupyterHub frontend."
}
variable "dataproc_configs" {
  description = "List to split for possible Cloud Dataproc configs."
}
variable "dataproc_locations_list" {
  description = "List to split for possible Cloud Dataproc zones."
}
variable "dataproc_allow_custom_clusters" {
  description = "Whether user can customize clusters or are limited to pre-defined ones."
  default     = "True"
}
variable "dataproc_machine_types_list" {
  description = "Machine types for Cloud Dataproc. If empty, uses a default list"
}
variable "gcs_examples_path" {
  description = "GCS path to example notebooks that will be loaded to the user's notebooks folder while cluster starting."
}
variable "mig_instance_count" {
  description = "The number of instances to place in the managed instance group"
  type        = string
  default     = "1"
}