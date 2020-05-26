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


PROJECT_ID=$1
# SA_NAME_TERRAFORM="terraform"

# Returns Cloud Build's service account email including serviceAccount:
# ex: `serviceAccount:1234567890@cloudbuild.gserviceaccount.com`
SA_NAME_CLOUDBUILD_EMAIL=$(gcloud projects get-iam-policy ${PROJECT_ID} \
--flatten="bindings[].members" \
--filter="bindings.members:*@cloudbuild.gserviceaccount.com" \
--format='value(bindings.members)' \
--limit=1)

# TODO(mayran). Limit Cloud Build IAM based on enabled APIs and needs.
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member ${SA_NAME_CLOUDBUILD_EMAIL} \
  --role roles/owner

# gcloud projects add-iam-policy-binding ${PROJECT_ID} \
#   --member ${SA_NAME_CLOUDBUILD_EMAIL} \
#   --role roles/iam.serviceAccountKeyAdmin

# # Set up service account and key for Terraform
# gcloud iam service-accounts create ${SA_NAME_TERRAFORM} \
#   --project ${PROJECT_ID} \
#   --display-name "${SA_NAME_TERRAFORM}"

# gcloud projects add-iam-policy-binding ${PROJECT_ID} \
#   --project ${PROJECT_ID} \
#   --member serviceAccount:${SA_NAME_TERRAFORM}@${PROJECT_ID}.iam.gserviceaccount.com \
#   --role roles/owner

# gcloud projects add-iam-policy-binding ${PROJECT_ID} \
#   --project ${PROJECT_ID} \
#   --member serviceAccount:${SA_NAME_TERRAFORM}@${PROJECT_ID}.iam.gserviceaccount.com \
#   --role roles/iam.roleAdmin

# gcloud iam service-accounts keys create tf-credentials.json \
#   --project ${PROJECT_ID} \
#   --iam-account ${SA_NAME_TERRAFORM}@${PROJECT_ID}.iam.gserviceaccount.com
