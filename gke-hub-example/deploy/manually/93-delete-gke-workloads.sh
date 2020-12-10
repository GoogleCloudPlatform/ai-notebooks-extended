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
# Usage: bash 90-delete-gke-workloads.sh TARGET
# Example: bash 90-delete-gke-workloads.sh local
# Example: bash 90-delete-gke-workloads.sh gke

source 10-set-variables.sh

TARGET=$1

if [ "$TARGET" == "gke" ]; then

  kustomize build ${FOLDER_MANIFESTS_GKE} | kubectl delete -f -
  rm ${FOLDER_MANIFESTS_GKE}/patch_gke.yaml


elif [ "$TARGET" == "local" ]; then

  kustomize build ${FOLDER_MANIFESTS_LOCAL} | kubectl delete -f -
  rm ${FOLDER_MANIFESTS_LOCAL}/patch_local.yaml

else

  echo "Target ${TARGET} not supported."

fi

kubectl delete configmaps inverse-proxy-config-hub
