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
# Usage: bash 30-deploy-gke-workloads.sh TARGET MUST_BUILD"
# Example: bash 30-deploy-gke-workloads.sh local true"
# Example: bash 30-deploy-gke-workloads.sh gke true"

source 10-set-variables.sh

TARGET=$1
MUST_BUILD=$2

echo "Deploying for TARGET:${TARGET}"
echo "Working with cluster: ${CLUSTER_NAME}"
echo "Image to build MUST_BUILD: ${MUST_BUILD}"
echo "Working Identity is set to: ${WID}"
echo "--------------------------------"

###################################
# Deploys on GKE
###################################
if [ "$TARGET" == "gke" ]; then

  # Resets GKE environment if used Minikube
  if [[ "$(minikube status | grep host)" == "host: Running" ]]; then
    minikube stop
  
    gcloud container clusters get-credentials ${CLUSTER_NAME} \
      --project ${PROJECT_ID} \
      --zone ${ZONE}
  fi 

  # Create images if asked
  if [ "$MUST_BUILD" == "hub" ]; then
    gcloud builds submit -t ${DOCKER_HUB_GKE} ${DOCKER_FOLDER_HUB}
  fi

  if [ "$MUST_BUILD" == "agent" ]; then
    gcloud builds submit -t ${DOCKER_AGENT_GKE} ${DOCKER_FOLDER_AGENT}
  fi

  if [ "$MUST_BUILD" == "true" ]; then
    gcloud builds submit -t ${DOCKER_HUB_GKE} ${DOCKER_FOLDER_HUB}
    gcloud builds submit -t ${DOCKER_AGENT_GKE} ${DOCKER_FOLDER_AGENT}
  fi

  # Deploys the workloads.

  # NOTE: Workload Identity is disable for the default pool
  # because inverting proxy requires VMID obtained from GCE_METADATA server.
  source 35-use-wid.sh

###################################
# Deploys locally
###################################
elif [ "$TARGET" == "local" ]; then

  # Sets Minikube environment
  USER=$(id -un)
  if [ "$(minikube status | grep host)" != "host: Running" ]; then
    minikube start --disk-size=100g
  fi

  eval $(minikube docker-env)

  # Create images if asked
  if [ "$MUST_BUILD" == "hub" ]; then
    docker build -t ${IMAGE_HUB_NAME:IMAGE_HUB_TAG} ${DOCKER_FOLDER_HUB}
  fi

  if [ "$MUST_BUILD" == "true" ]; then
    docker build -t ${IMAGE_HUB_NAME:IMAGE_HUB_TAG} ${DOCKER_FOLDER_HUB}

    # Build the jupyter images after minikube docker-env
    for image_jupyter in "${IMAGES_JUPYTER[@]}"; do
      echo "Building Jupyter profile ${image_jupyter}"
      bash 15-create-jupyter-image.sh local ../../docker/jupyter/${image_jupyter} ${image_jupyter}
    done
  fi

  source 35-use-minikube.sh

###################################
# Catch all target.
###################################
else
  echo "echo Target ${TARGET} not supported."
fi

