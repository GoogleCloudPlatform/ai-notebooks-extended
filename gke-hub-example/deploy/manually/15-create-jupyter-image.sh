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
# Usage: bash 15-create-jupyter-image.sh TARGET DOCKER_FOLDER IMAGE_JUPYTER_TAG
# Example: bash 15-create-jupyter-image.sh local jupyter-mine-basic jupyter-mine-basic
# Example: bash 15-create-jupyter-image.sh gke jupyter-mine-basic gcr.io/mam-nooage/jupyter-mine-basic

source 10-set-variables.sh

TARGET=$1
DOCKER_FOLDER=${DOCKER_FOLDER_JUPYTER}/$2
IMAGE_JUPYTER_TAG=$3

if [ "$TARGET" == "gke" ]; then

  gcloud builds submit -t ${IMAGE_JUPYTER_TAG} ${DOCKER_FOLDER}

elif [ "$TARGET" == "local" ]; then

  docker build -t ${IMAGE_JUPYTER_TAG} ${DOCKER_FOLDER}

else

  echo "echo Target ${TARGET} not supported."

fi