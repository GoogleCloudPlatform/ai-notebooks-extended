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

FROM jupyterhub/jupyterhub:latest

# Install gcloud
RUN apt-get update && apt-get install -y curl apt-transport-https ca-certificates gnupg \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
  && echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && apt-get update && apt-get install -y google-cloud-sdk

RUN apt-get update \
  && apt-get remove -y python3-pycurl \
  && apt-get install -y --no-install-recommends \
    libssl-dev \
    libcurl4-openssl-dev \
    python3-wheel \
    git \
  && apt-get purge \
  && apt-get clean -y

RUN pip install --upgrade pip \
  && pip install --upgrade \
    psycopg2-binary \
    google-api-python-client \
    google-auth-oauthlib \
    google-api-python-client \
    oauth2client \
    google-auth \
    googleapis-common-protos \
    google-auth-httplib2

RUN apt-get update && apt-get install -y libpq-dev \
    && apt-get install -y vim \
    && apt-get install -y iproute2 \
    && apt-get autoremove -y \
    && apt-get clean -y

# Installs the authenticator for IAP and Inverting Proxy && install relevant Spawner
RUN pip install git+https://github.com/GoogleCloudDataproc/jupyterhub-dataprocspawner.git
RUN pip install git+https://github.com/GoogleCloudPlatform/jupyterhub-gcp-proxies-authenticator.git

# JupyterHub design
COPY design/templates/ /etc/jupyterhub/templates/

COPY jupyterhub_config.py .

EXPOSE 8080

COPY jupyterhub.sh /usr/local/bin/
ENTRYPOINT ["bash", "-C", "/usr/local/bin/jupyterhub.sh"]