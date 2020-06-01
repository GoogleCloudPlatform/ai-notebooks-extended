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

source 10-set-variables.sh

gcloud beta container clusters create ${CLUSTER_NAME} \
--project ${PROJECT_ID} \
--zone ${ZONE} \
--release-channel regular \
--enable-ip-alias \
--scopes "https://www.googleapis.com/auth/cloud-platform" \
--num-nodes 1 \
--machine-type n1-standard-4

gcloud container clusters get-credentials ${CLUSTER_NAME} \
--project ${PROJECT_ID} \
--zone ${ZONE}