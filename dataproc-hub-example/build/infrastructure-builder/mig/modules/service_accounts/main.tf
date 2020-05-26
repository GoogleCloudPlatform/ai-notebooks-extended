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

# Configures the Jupyterhub service account.
resource "google_service_account" "jupyterhub_sa" {
  project      = var.project_id
  account_id   = var.jupyterhub_sa_id
  display_name = "Jupyterhub Service Account"
}

resource "google_project_iam_member" "jupyterhub_sa_roles" {
  project  = var.project_id
  for_each = toset(var.jupyterhub_sa_roles)
  role     = format("roles/%s", each.value)
  member   = format("serviceAccount:%s", google_service_account.jupyterhub_sa.email)
}

resource "google_service_account_key" "jupyterhub_sa_key" {
  service_account_id = google_service_account.jupyterhub_sa.name
}

# Configures the Cloud Dataproc service account.
resource "google_service_account" "dataproc_sa" {
  project      = var.project_id
  account_id   = var.dataproc_sa_id
  display_name = "Cloud Dataproc Service Account"
}

resource "google_project_iam_member" "dataproc_sa_roles" {
  project  = var.project_id
  for_each = toset(var.dataproc_sa_roles)
  role     = format("roles/%s", each.value)
  member   = format("serviceAccount:%s", google_service_account.dataproc_sa.email)
}

resource "google_service_account_key" "dataproc_sa_key" {
  service_account_id = google_service_account.dataproc_sa.name
}