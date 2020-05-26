# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

PROJECT_ID=$1
# Enables APIs required by this guide.
gcloud services enable bigquery.googleapis.com --project ${PROJECT_ID}
gcloud services enable bigquerystorage.googleapis.com --project ${PROJECT_ID}
gcloud services enable cloudbuild.googleapis.com --project ${PROJECT_ID}
gcloud services enable cloudkms.googleapis.com --project ${PROJECT_ID}
gcloud services enable cloudresourcemanager.googleapis.com --project ${PROJECT_ID}
gcloud services enable compute.googleapis.com --project ${PROJECT_ID}
gcloud services enable containerregistry.googleapis.com --project ${PROJECT_ID}
gcloud services enable dataproc.googleapis.com --project ${PROJECT_ID}
gcloud services enable dns.googleapis.com --project ${PROJECT_ID}
gcloud services enable iam.googleapis.com --project ${PROJECT_ID}
gcloud services enable secretmanager.googleapis.com --project ${PROJECT_ID}
gcloud services enable servicenetworking.googleapis.com --project ${PROJECT_ID}
gcloud services enable storage-api.googleapis.com --project ${PROJECT_ID}
gcloud services enable storage-component.googleapis.com --project ${PROJECT_ID}
gcloud services enable sqladmin.googleapis.com --project ${PROJECT_ID}
gcloud services enable sql-component.googleapis.com --project ${PROJECT_ID}