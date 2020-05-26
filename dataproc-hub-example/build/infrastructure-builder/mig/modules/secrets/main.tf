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

# postgres_pass
resource "google_secret_manager_secret" "postgres_pass" {
  provider = google-beta
  project  = var.project_id
  
  secret_id   = "postgres-pass"

  replication {
    automatic = true
  }
}
resource "google_secret_manager_secret_version" "postgres_pass_version" {
  provider = google-beta
  secret   = google_secret_manager_secret.postgres_pass.name

  secret_data = var.postgres_pass
}

# Oauth client id
resource "google_secret_manager_secret" "oauth_google_clientid" {
  provider = google-beta
  project  = var.project_id
  
  secret_id   = "oauth-google-clientid"

  replication {
    automatic = true
  }
}
resource "google_secret_manager_secret_version" "oauth_google_clientid_version" {
  provider = google-beta
  secret   = google_secret_manager_secret.oauth_google_clientid.name

  secret_data = var.oauth_google_clientid
}

# Oauth client secret
resource "google_secret_manager_secret" "oauth_google_clientsecret" {
  provider = google-beta
  project  = var.project_id
  
  secret_id   = "oauth-google-clientsecret"

  replication {
    automatic = true
  }
}
resource "google_secret_manager_secret_version" "oauth_google_clientsecret_version" {
  provider = google-beta
  secret   = google_secret_manager_secret.oauth_google_clientsecret.name

  secret_data = var.oauth_google_clientsecret
}
