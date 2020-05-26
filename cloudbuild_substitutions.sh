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
# If you run things manually, do not forget the trailing / for the folders in _BUILD_FOLDERS.

SUBSTITUTIONS=\
_BUILD_FOLDERS="dataproc-hub-example/build/dataproc-custom-image-builder/",\
_BUILD_FOLDERS_SEP="#",\
_FOLDER_DATAPROCHUB="dataproc-hub-example/build",\
_FOLDER_GKEHUB="gke-hub-example/build",\
_DCI_PROJECT_ID=${PROJECT_ID},\
_DCI_CUSTOM_IMAGE_NAME="dataprochub-dataproc-base-$(date +"%Y%m%d%k%M%S")",\
_DCI_DATAPROC_VERSION="1.4.16-debian9",\
_DCI_ZONE="us-central1-a",\
_DCI_CUSTOMIZATION_SCRIPT_PATH="dataproc-hub-example/build/dataproc-custom-image-builder/customization-script.sh",\
_DCI_GCS_LOGS="${GCS_DATAPROC_CUSTOM_IMAGES}/logs",\
_DCI_DISK_SIZE="100",\
_DHB_UPDATE_MIG=false,\
_DHB_BASE_IMAGE="dataprochub",\
_DHB_TAG="latest",\
_DHB_MIG_NAME="jupyterhub-mig",\
_DHB_REGION="europe-west1",\
_MIG_TERRAFORM_VERSION="0.12.24",\
_MIG_TERRAFORM_STATE_BUCKET="${GCS_TFSTATE}"