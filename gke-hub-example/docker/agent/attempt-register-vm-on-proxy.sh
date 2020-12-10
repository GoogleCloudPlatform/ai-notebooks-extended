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

set -ex

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd)"

env

function run-proxy-agent {  
  # Should run something similar to this
  # -
  # /opt/bin/proxy-forwarding-agent \
  # --debug=false \s
  # --session-cookie-name=_xsrf \
  # --forward-user-id=true \
  # --proxy=https://datalab-staging.cloud.google.com/tun/m/4592f092208ecc84946b8f8f8016274df1b36a14/ \
  # --proxy-timeout=60s \
  # --backend=546679c9821f4af \
  # --host=localhost:8080 \
  # --shim-websockets=false \
  # --shim-path=websocket-shim \
  # --health-check-path=/hub/health \
  # --health-check-interval-seconds=30 \
  # --health-check-unhealthy-threshold=2
  # -
  
  # Sets JupyterLab Hub service host and port.
  echo ${JUPYTERLAB_HUB_SERVICE_HOST}
  echo ${JUPYTERLAB_HUB_SERVICE_PORT}
  JUPYTERLAB_HUB_SERVICE_HOST=$(kubectl get service ${JUPYTERLAB_HUB_SERVICE_NAME} -o json | jq -r ".spec.clusterIP")
  JUPYTERLAB_HUB_SERVICE_PORT=$(kubectl get service ${JUPYTERLAB_HUB_SERVICE_NAME} -o json | jq -r ".spec.ports[0].port")
  echo ${JUPYTERLAB_HUB_SERVICE_HOST}
  echo ${JUPYTERLAB_HUB_SERVICE_PORT}

  # Starts the proxy process
  # https://github.com/google/inverting-proxy/blob/master/agent/Dockerfile
  /opt/bin/proxy-forwarding-agent \
        --debug=${DEBUG} \
        --session-cookie-name=_xsrf \
        --forward-user-id=true \
        --proxy=${PROXY_URL}/ \
        --proxy-timeout=${PROXY_TIMEOUT} \
        --backend=${BACKEND_ID} \
        --host="${JUPYTERLAB_HUB_SERVICE_HOST}:${JUPYTERLAB_HUB_SERVICE_PORT}" \
        --shim-websockets=true \
        --shim-path=websocket-shim \
        --health-check-path=${HEALTH_CHECK_PATH} \
        --health-check-interval-seconds=${HEALTH_CHECK_INTERVAL_SECONDS} \
        --health-check-unhealthy-threshold=${HEALTH_CHECK_UNHEALTHY_THRESHOLD}
}

# Checks ConfigMap to see if the cluster already has the proxy agent installed and if
# it already exists, reuse the existing endpoint (a.k.a BACKEND_ID) and same ProxyUrl.
if kubectl get configmap inverse-proxy-config-hub; then
  PROXY_URL=$(kubectl get configmap inverse-proxy-config-hub -o json | jq -r ".data.ProxyUrl")
  BACKEND_ID=$(kubectl get configmap inverse-proxy-config-hub -o json | jq -r ".data.BackendId")
  run-proxy-agent
  exit 0
fi

# This appears to never run.
# Activates service account for gcloud SDK first
if [[ ! -z "${GOOGLE_APPLICATION_CREDENTIALS}" ]]; then
  gcloud auth activate-service-account --key-file="${GOOGLE_APPLICATION_CREDENTIALS}"
fi

INSTANCE_ZONE="/"$(curl http://metadata.google.internal/computeMetadata/v1/instance/zone -H "Metadata-Flavor: Google")
INSTANCE_ZONE="${INSTANCE_ZONE##/*/}"

# Force the proxy URL in some cases (staging for example)
if [[ ! -z "${FORCE_PROXY_URL}" ]]; then
  PROXY_URL=${FORCE_PROXY_URL}
else
  # Gets latest Proxy server URL.
  curl -O https://storage.googleapis.com/dl-platform-public-configs/proxy-agent-config.json
  PROXY_URL=$(python ${DIR}/get_proxy_url.py --config-file-path "proxy-agent-config.json" --location "${INSTANCE_ZONE}" --version "latest")
  if [[ -z "${PROXY_URL}" ]]; then
      echo "Proxy URL for the zone ${INSTANCE_ZONE} no found, exiting."
      exit 1
  fi
fi

echo "Proxy URL from the config: ${PROXY_URL}"

# Registers the proxy agent. 
# Note: If each use needed a unique URL, you need to pass a Google (gmail, gsuite) email in the body with -d
# Here, we don't need it as there is hub for all users and the inverting proxy agent only use the hub deployment.
METADATA_BASE_URL="http://metadata.google.internal/computeMetadata/v1"
VM_ID=$(curl -H 'Metadata-Flavor: Google' "${METADATA_BASE_URL}/instance/service-accounts/default/identity?format=full&audience=${PROXY_URL}/request-service-account-endpoint"  2>/dev/null)
RESULT_JSON=$(curl -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "X-Inverting-Proxy-VM-ID: ${VM_ID}" -d "" "${PROXY_URL}/request-service-account-endpoint" 2>/dev/null)
echo "Response from the registration server: ${RESULT_JSON}"

HOSTNAME=$(echo "${RESULT_JSON}" | jq -r ".hostname")
BACKEND_ID=$(echo "${RESULT_JSON}" | jq -r ".backendID")
echo "Hostname: ${HOSTNAME}"
echo "Backend id: ${BACKEND_ID}"

# Stores the registration information in a ConfigMap
kubectl create configmap inverse-proxy-config-hub \
  --from-literal=ProxyUrl=${PROXY_URL} \
  --from-literal=BackendId=${BACKEND_ID} \
  --from-literal=Hostname=${HOSTNAME}

run-proxy-agent
