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


# ANACONDA_HOME="${ANACONDA_HOME:-/opt/anaconda3}"
# ANACONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
# ANACONDA_INSTALLER=anaconda_installer.sh

# wget $ANACONDA_URL -O $ANACONDA_INSTALLER

# chmod +x $ANACONDA_INSTALLER
# ./$ANACONDA_INSTALLER -b -p "${ANACONDA_HOME}"
# rm "${ANACONDA_INSTALLER}"

function retry_command() {
  cmd="$1"
  for ((i = 0; i < 10; i++)); do
    if eval "$cmd"; then
      return 0
    fi
    sleep 5
  done
  return 1
}

function update_apt_get() {
  retry_command "apt-get update"
}

function install_apt_get() {
  pkgs="$*"
  retry_command "apt-get install -y $pkgs"
}

function err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
  exit 1
}

export ANACONDA_HOME="/opt/conda/anaconda"
export ANACONDA_BIN_DIR="${ANACONDA_HOME}/bin"

chmod -R ugo+w "${ANACONDA_HOME}"
. ${ANACONDA_HOME}/etc/profile.d/conda.sh

# conda activate base
# conda update -y python
# conda update -y -n base -c defaults conda
conda update --all

${ANACONDA_BIN_DIR}/pip install --upgrade tensorflow

gsutil cp gs://spark-lib/bigquery/spark-bigquery-latest.jar /usr/lib/spark/jars/

conda install -y --override-channels -c main -c conda-forge jupyterlab jupyterlab-git

conda install -y --override-channels -c main "nbconvert>=5.5.0"
${ANACONDA_BIN_DIR}/pip install --no-cache-dir --upgrade --upgrade-strategy only-if-needed nbconvert
conda install -y --override-channels -c main -c conda-forge nodejs tqdm
conda install -y --override-channels -c main notebook nb_conda nb_conda_kernels nbpresent
conda install -y --override-channels -c main -c conda-forge ipywidgets

${ANACONDA_BIN_DIR}/pip install --no-cache-dir --upgrade  \
  google-api-python-client \
  google-cloud-bigquery \
  google-cloud-dataproc \
  google-cloud-language \
  google-cloud-logging \
  google-cloud-storage \
  google-cloud-translate \
  google-cloud-iam \
  google-cloud-core

${ANACONDA_BIN_DIR}/pip install --no-cache-dir --upgrade \
  bcolz \
  cookiecutter \
  datalab \
  fairing \
  grpcio \
  httplib2 \
  ipython-sql \
  jupyter_contrib_nbextensions \
  jupyter_http_over_ws \
  jupyterlab-git \
  Markdown \
  nbdime \
  oauth2client \
  opencv-python \
  pandas-profiling \
  papermill[gcs] \
  Pillow-SIMD \
  protobuf \
  pyarrow \
  pyasn1 \
  pyasn1-modules \
  pydot \
  rsa \
  uritemplate \
  virtualenv

curl -sL https://deb.nodesource.com/setup_13.x | bash -
update_apt_get || err 'Failed to update apt-get'
install_apt_get nodejs || err 'Unable to install nodejs.'

${ANACONDA_BIN_DIR}/jupyter nbextension install nb_conda --py --sys-prefix --symlink
${ANACONDA_BIN_DIR}/jupyter nbextension enable nb_conda --py --sys-prefix
${ANACONDA_BIN_DIR}/jupyter nbextension enable widgetsnbextension --py --sys-prefix
${ANACONDA_BIN_DIR}/jupyter nbextension install nbdime --py --sys-prefix
${ANACONDA_BIN_DIR}/jupyter nbextension enable nbdime --py --sys-prefix
${ANACONDA_BIN_DIR}/jupyter serverextension enable nb_conda --py --sys-prefix
${ANACONDA_BIN_DIR}/jupyter serverextension enable jupyterlab_git --py --sys-prefix
${ANACONDA_BIN_DIR}/jupyter serverextension enable nbdime --py --sys-prefix
${ANACONDA_BIN_DIR}/jupyter labextension install @jupyter-widgets/jupyterlab-manager
${ANACONDA_BIN_DIR}/jupyter labextension install @jupyterlab/git
${ANACONDA_BIN_DIR}/jupyter labextension install @jupyterlab/celltags
${ANACONDA_BIN_DIR}/jupyter labextension install nbdime-jupyterlab

# Returns error $HOME not set.
# nbdime config-git --enable --global

${ANACONDA_BIN_DIR}/jupyter lab build
${ANACONDA_BIN_DIR}/jupyter lab clean

conda clean -y -a