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


# TODO(mayran): Currently, roles are set at the project level. 
# For buckets and service accounts, do at the resource level.
variable "project_id" {
  description = "Project ID."
}

variable "jupyterhub_sa_id" {
  description = "Jupyterhub Service Account ID."
}

# 'compute.viewer' for docker to run compute.backendServices.get().
variable "jupyterhub_sa_roles" {
  description = "The list of roles to assign to the Jupyterhub service account."
  default     = ["storage.admin",
                 "storage.objectViewer",
                 "dataproc.admin",
                 "cloudsql.admin",
                 "cloudkms.cryptoKeyDecrypter",
                 "iam.serviceAccountUser",
                 "secretmanager.secretAccessor",
                 "compute.viewer"]
}

variable "dataproc_sa_id" {
    description = "Cloud Dataproc Service Account ID."
}
variable "dataproc_sa_roles" {
  description = "The list of roles to assign to the Cloud Dataproc service account."
  default     = ["storage.admin",
                 "dataproc.worker",
                 "bigquery.admin",
                 "compute.imageUser"]
}

