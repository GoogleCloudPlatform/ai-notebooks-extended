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

provider "local" {

}

provider "google" {
  version = "~> 2.20.2"
}

provider "google-beta" {
  version = ">= 3.18.0"
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

# Environment file for Dataproc Hub
resource "local_file" "env_file" {
  content  = <<EOF
# Do not add double quotes for strings.
DATAPROC_CONFIGS=${google_storage_bucket.gcs_working.name}/configs/cluster-single-noimage.yaml
DATAPROC_LOCATIONS_LIST=${var.dataproc_locations_list}
EOF
  filename = "${var.local_working_location}/env-hub.list"
}

resource "google_storage_bucket_object" "env_file" {
  name     = "env-hub.list"
  source   = "${var.local_working_location}/env-hub.list"
  bucket   = google_storage_bucket.gcs_working.name
}

# Dataproc Hub instance
resource "google_compute_instance" "hub" {
  project      = var.project_id
  name         = var.instance_name
  machine_type = "n1-standard-1"
  zone         = var.zone

  tags = ["deeplearning-vm"]

  boot_disk {
    initialize_params {
      image = "projects/deeplearning-platform-release/global/images/common-container-experimental-20200518"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    proxy-mode = "service_account",
    container = "gcr.io/cloud-dataproc/dataproc-spawner:prod",
    agent-health-check-path = "/hub/health",
    jupyterhub-host-type = "ain",
    framework = "Dataproc Hub",
    agent-env-file = "gs://dataproc-spawner-dist/env-agent",
    container-env-file = "gs://${google_storage_bucket.gcs_working.name}/env-hub.list",
    container-use-host-network = "True"
    # post-startup-script = "gs://deeplearning-platform-ui-public/extension-manager/extension-manager-post-startup-script.sh"
    # proxy-registration-url = "https://datalab-us-west1.cloud.google.com/tun/m/4592f092208ecc84946b8f8f8016274df1b36a14"
    # proxy-url = "4ea54575f755bb4a-dot-us-west1.notebooks.googleusercontent.com"
    # shutdown-script = "/opt/deeplearning/bin/shutdown_script.sh"
    # title = "Base.Container"
    # version = "51"
  }

  metadata_startup_script = "echo hi > /test.txt"

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/userinfo.email"
    ]
  }
}

