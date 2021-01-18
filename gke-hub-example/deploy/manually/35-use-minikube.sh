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

# Creates Kustmomize `local` patches
cat <<EOT > ${FOLDER_MANIFESTS_LOCAL}/patch_local.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jupyterlab-hub
spec:
  template:
    spec:
      containers:
      - name: jupyterlab-hub
        image: ${IMAGE_HUB_NAME}:${IMAGE_HUB_TAG}
        imagePullPolicy: Always
        env:
        - name: spawnable_profiles
          value: ${DOCKERS_JUPYTER_LOCAL}
EOT

# Deploys
kustomize build ${FOLDER_MANIFESTS_LOCAL} | kubectl apply -f -
kubectl delete services jupyterlab-hub
kubectl expose deployment jupyterlab-hub --type=LoadBalancer --port=8080
minikube service --url=false jupyterlab-hub

