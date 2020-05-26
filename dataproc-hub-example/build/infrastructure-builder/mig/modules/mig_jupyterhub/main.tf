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

locals {
#   google_load_balancer_ip_ranges = [
#     "130.211.0.0/22",
#     "35.191.0.0/16",
#   ]
  target_tags = ["container-vm-mig"]
}

module "gce_container" {
  source = "github.com/terraform-google-modules/terraform-google-container-vm"
  container = {
    image = var.image
    env = var.container_env
  }

  restart_policy = "Always"
}

module "jupyterhub_mig_template" {
  source               = "terraform-google-modules/vm/google//modules/instance_template"
  project_id           = var.project_id
  version              = "~> 2.1.0"
  subnetwork           = var.subnetwork
  
  service_account      = var.service_account
  name_prefix          = "jupyterhub"
  source_image_family  = "cos-stable"
  source_image_project = "cos-cloud"
  source_image         = reverse(split("/", module.gce_container.source_image))[0]
  metadata             = merge(var.additional_metadata, map("gce-container-declaration", module.gce_container.metadata_value))
  tags                 = local.target_tags
  labels               = {
    "container-vm" = module.gce_container.vm_container_label
  }
}

resource "google_compute_region_instance_group_manager" "jupyterhub_mig" {
  provider = google-beta
  name = "jupyterhub-mig-${var.region}"
  project = var.project_id

  base_instance_name = "jupyterhub"
  region             = var.region

  version {
    name               = "jupyterhub-mig-template"
    instance_template  = module.jupyterhub_mig_template.self_link
  }

  target_size  = var.mig_instance_count

  named_port {
    name = "http-jupyterhub"
    port = var.image_port
  }

  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 4
    max_unavailable_fixed = 0
    min_ready_sec         = 20
  }
}