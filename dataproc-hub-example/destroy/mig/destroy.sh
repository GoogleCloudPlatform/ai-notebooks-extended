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


# Destroys Terraform setup

#!/bin/bash

# Submits a Cloud Build job. Usage example: 
# ./destroy.sh my-project-id "../build/terraform-builder"

PROJECT_ID=$1
TERRAFORM_LOCAL_DIR=$2

GCS_DATAPROC_CUSTOM_IMAGES="${PROJECT_ID}-dataproc-images"
GCS_TFSTATE="${PROJECT_ID}-terraform-state"

SUBSTITUTIONS=\
_TERRAFORM_VERSION="0.12.20",\
_TERRAFORM_STATE_BUCKET="${GCS_TFSTATE}"

# Submits job.
gcloud builds submit ${TERRAFORM_LOCAL_DIR} --config cloudbuild.yaml \
--substitutions ${SUBSTITUTIONS} \
--timeout 3600 \
--project ${PROJECT_ID}