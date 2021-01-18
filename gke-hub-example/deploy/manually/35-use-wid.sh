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

# Creates Kustmomize `GKE` patches for the Hub
cat <<EOT > ${FOLDER_MANIFESTS_GKE}/patch_gke.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jupyterlab-hub
spec:
  template:
    spec:
      containers:
      - name: jupyterlab-hub
        image: ${DOCKER_HUB_GKE}
        imagePullPolicy: Always
        env:
        - name: spawnable_profiles
          value: ${DOCKERS_JUPYTER_GKE}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: proxy-agent-hub
spec:
  template:
    spec:
      containers:
      - name: proxy-agent-hub
        image: ${DOCKER_AGENT_GKE}
        imagePullPolicy: Always
---
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    iam.gke.io/gcp-service-account: ${SA_GKE_HUB}@${PROJECT_ID}.iam.gserviceaccount.com
  name: agent-runner
  namespace: default
---
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    iam.gke.io/gcp-service-account: ${SA_GKE_HUB}@${PROJECT_ID}.iam.gserviceaccount.com
  name: hub-runner
  namespace: default
---
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    iam.gke.io/gcp-service-account: ${SA_GKE_SU}@${PROJECT_ID}.iam.gserviceaccount.com
  name: singleuser-runner
  namespace: default
EOT

# Deploys.
kustomize build ${FOLDER_MANIFESTS_GKE} | kubectl apply -f -
