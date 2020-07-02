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
# Usage: bash 20-create-infrastructure.sh

source 10-set-variables.sh

gcloud iam service-accounts create ${SA_GKE_NODES} --display-name ${SA_GKE_NODES} --project ${PROJECT_ID}

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member serviceAccount:${SA_GKE_NODES}@${PROJECT_ID}.iam.gserviceaccount.com \
--role roles/owner

if [ "$WID" == "true" ]; then

  echo "---------------------------------------------"
  echo "Creating a Workload Identity enabled cluster."
  echo "---------------------------------------------"

  gcloud beta container clusters create ${CLUSTER_NAME} \
  --project ${PROJECT_ID} \
  --zone ${ZONE} \
  --release-channel regular \
  --enable-ip-alias \
  --num-nodes 1 \
  --scopes cloud-platform,userinfo-email \
  --service-account ${SA_GKE_NODES}@${PROJECT_ID}.iam.gserviceaccount.com \
  --machine-type n1-standard-4 \
  --addons ConfigConnector \
  --workload-pool=${PROJECT_ID}.svc.id.goog \
  --workload-metadata=GCE_METADATA \
  --enable-stackdriver-kubernetes

else

  echo "---------------------------------------------"
  echo "Creating a cluster without Workload Identity."
  echo "---------------------------------------------"

  gcloud beta container clusters create ${CLUSTER_NAME} \
  --project ${PROJECT_ID} \
  --zone ${ZONE} \
  --release-channel regular \
  --enable-ip-alias \
  --num-nodes 1 \
  --scopes cloud-platform,userinfo-email \
  --service-account ${SA_GKE_NODES}@${PROJECT_ID}.iam.gserviceaccount.com \
  --machine-type n1-standard-4

fi

gcloud container clusters get-credentials ${CLUSTER_NAME} \
--project ${PROJECT_ID} \
--zone ${ZONE}