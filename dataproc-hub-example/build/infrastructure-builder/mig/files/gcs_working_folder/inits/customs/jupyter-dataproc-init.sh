#! /usr/bin/bash
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


set -exo pipefail

function restart_service_gracefully {
  while true; do
    if systemctl status "$1" | grep -q 'Active: active (running)'; then
      systemctl restart "$1"
      break;
    fi
    echo 'sleep'
    sleep 5;
  done
}

# Reads variables from the metadata.
[ -z "${CONDA_CHANNELS}" ] && CONDA_CHANNELS=$(/usr/share/google/get_metadata_value attributes/CONDA_CHANNELS || true)
[ -z "${CONDA_PACKAGES}" ] && CONDA_PACKAGES=$(/usr/share/google/get_metadata_value attributes/CONDA_PACKAGES || true)
[ -z "${PIP_PACKAGES}" ] && PIP_PACKAGES=$(/usr/share/google/get_metadata_value attributes/PIP_PACKAGES || true)

# pip packages
if [[ -n "${PIP_PACKAGES}" ]]; then

  # TODO(mayran): Probably better to let user write their own script 
  # and only handles pip upgrade failure here. For now, lets them install 
  # using the PIP_PACKAGES variable
  if [[ $PIP_PACKAGES == *"tensorflow==2.0"* ]]; then
    conda upgrade --all
  fi

  pip install --upgrade ${PIP_PACKAGES}
fi

# Required channels and packages
conda config --add channels conda-forge
conda install jupyterlab==1.1.4 nodejs jupyterlab-git nbdime

# Channels and packages asked by the admin user if any. 
# They should be request in the configs/xxx.yaml 
if [ -n "${CONDA_CHANNELS}" ]; then
  IFS=":" read -r -a channels <<<"${CONDA_CHANNELS}"
  echo "Adding custom conda channels '${channels[*]}'"
  for channel in "${channels[@]}"; do
    conda config --add channels "${channel}"
  done
fi

if [ -n "${CONDA_PACKAGES}" ]; then
  IFS=":" read -r -a packages <<<"${CONDA_PACKAGES}"
  echo "Installing custom conda packages '${packages[*]}'"
  conda install "${packages[@]}"
fi

# Makes packages available as a standard.
ROLE=$(/usr/share/google/get_metadata_value attributes/dataproc-role)
if [[ "${ROLE}" == 'Master' ]]; then
  restart_service_gracefully jupyterhub.service    
  jupyter lab build
fi

echo 'Done'