#!/bin/bash
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
#
# Submits a Cloud Build job. 
#
# Usage: bash cloudbuild_manual <YOUR_PROJECT_ID>

PROJECT_ID=$1

GCS_DATAPROC_CUSTOM_IMAGES="${PROJECT_ID}-dataproc-images"
GCS_TFSTATE="${PROJECT_ID}-terraform-state"

# Creates Cloud Storage bucket for Cloud Dataproc custom images
# Not in Cloud Build because part of the development environment.
gsutil mb -p ${PROJECT_ID} gs://${GCS_DATAPROC_CUSTOM_IMAGES}

# TODO(mayran): Move this to terraform-builder/cloudbuild.yaml.
# Creates Cloud Storage bucket for Terraform state
# Not in Cloud Build because part of the development environment.
gsutil mb -p ${PROJECT_ID} gs://${GCS_TFSTATE}

# Creates the SUBSTITUTIONS string variable.
source cloudbuild_substitutions.sh

echo ${SUBSTITUTIONS}

# Submits job.
gcloud builds submit . --config  cloudbuild.yaml \
--substitutions ${SUBSTITUTIONS} \
--timeout 5000 \
--project ${PROJECT_ID}
