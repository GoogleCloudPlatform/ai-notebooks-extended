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

variable "project_id" {
    description = "The GCP project ID."
}

variable "region" {
  description = "Region where to deploy the Hub and related resources."
  default = "us-central1"
}

variable "zone" {
  description = "Zone where to deploy the Hub"
  default = "us-central1-a"
}

variable "instance_name" {
  description = "Name of the Hub instance."
}

variable "dataproc_locations_list" {
  description = "List of zone letters where Dataproc can be deployed. Ex: b,c,d"
}


variable "files_dataproc_configs" {
  description = "Autoscaling policies files to upload from locals.local_cluster_autoscaling_location to gs://gcs_working/configs/"
}

variable "gcs_buckets_location" {
  description = "Geo location where to create buckets."
  default = "US"
}

variable "gcs_suffix" {
  description = "String to differentiate bucket name within the same project."
  default = "ain"
}

locals {
  gcs_bucket_prefix   = "${var.project_id}-${var.gcs_suffix}" 
  gcs_working         = "${local.gcs_bucket_prefix}-working"
  gcs_notebooks       = "${local.gcs_bucket_prefix}-notebooks"
}

variable "local_working_location" {
  description = "Local files location for cluster configs"
  type        = string
  default     = "files/gcs_working_folder"
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