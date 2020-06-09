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


set -x

readonly metadata_base_url="http://metadata.google.internal/computeMetadata/v1"

# 'append-config-ain'
# Adds content to jupyterhub_config.py so JupyterHub
# can run on an AI Platform Notebook instance.
function append-config-ain {
  cat <<EOT >> jupyterhub_config.py
## Start of configuration for JupyterHub on AI Notebooks ##
c.Spawner.spawner_host_type = 'ain'

# Must be 8080 to meet Inverting Proxy requirements.
c.JupyterHub.port = 8080

# Authenticator
from gcpproxiesauthenticator.gcpproxiesauthenticator import GCPProxiesAuthenticator
c.JupyterHub.authenticator_class = GCPProxiesAuthenticator
c.GCPProxiesAuthenticator.check_header = "X-Inverting-Proxy-User-Id"
c.GCPProxiesAuthenticator.template_to_render = "welcome.html"

admins = os.environ.get('ADMINS', '')
if admins:
  c.Authenticator.admin_users = admins.split(',')

# Port can not be 8001. Conflicts with another one process.
c.ConfigurableHTTPProxy.api_url = 'http://127.0.0.1:8005'

# Option on Dataproc Notebook server to allow authentication.
c.Spawner.args = ['--NotebookApp.disable_check_xsrf=True']

# Passes a Hub URL accessible by Dataproc. Without this AI Notebook passes a 
# local address. Used by the overwritter get_env().
metadata_base_url = "http://metadata.google.internal/computeMetadata/v1"
headers = {'Metadata-Flavor': 'Google'}
params = ( ('recursive', 'true'), ('alt', 'text') )
instance_ip = requests.get(
    f'{metadata_base_url}/instance/network-interfaces/0/ip', 
    params=params, 
    headers=headers
).text

c.Spawner.env_keep = ['NEW_JUPYTERHUB_API_URL']
c.Spawner.environment = {
  'NEW_JUPYTERHUB_API_URL': f'http://{instance_ip}:8080/hub/api'
}  
EOT
}

# 'append-config-mig'
# Adds content to jupyterhub_config.py so JupyterHub
# can run on a GCE Managed Instance Group.
function append-config-mig {
  cat <<EOT >> jupyterhub_config.py
## Start of configuration for JupyterHub on a GCE Managed Instance Group. ##
c.Spawner.spawner_host_type = 'mig'

# Generally 8080 but can be customized.
c.JupyterHub.port = int(os.environ.get('PROXY_PORT', 8080))

# Reads metadata required for IAP verification.
metadata_base_url = "http://metadata.google.internal/computeMetadata/v1"
headers = {'Metadata-Flavor': 'Google'}
params = ( ('recursive', 'true'), ('alt', 'text') )

project_number = requests.get(
    f'{metadata_base_url}/project/numeric-project-id', 
    params=params, 
    headers=headers
).text

project_id = requests.get(
    f'{metadata_base_url}/project/project-id', 
    params=params, 
    headers=headers
).text

# Authenticator.
# Ensures that the chosen authentication method receives the proper headers and
# sets up the required parameters for the authenticator.
# - If user provides a backend service name, assumes that it is because IAP is
#   set up. So tries to log into JupyterHub transparently using IAP's headers.
# - If user does not provide a backend service, falls back to normal Oauth using
#   the provided Oauth details set for the project.
# - If there is not oauth details, returns an error.

backend_service_name = os.environ.get('BACKEND_SERVICE_NAME', '')

oauth_google_clientid = os.environ.get('OAUTH_GOOGLE_CLIENTID', '')
oauth_google_clientsecret = os.environ.get('OAUTH_GOOGLE_CLIENTSECRET', '')
oauth_google_callback_url = os.environ.get('OAUTH_GOOGLE_CALLBACK_URL', '')
oauth_google_domain = os.environ.get('OAUTH_GOOGLE_DOMAIN', '')

has_oauth = (oauth_google_clientid and oauth_google_clientsecret and 
             oauth_google_callback_url and oauth_google_domain)

if backend_service_name:
  from gcpproxiesauthenticator.gcpproxiesauthenticator import GCPProxiesAuthenticator
  c.JupyterHub.authenticator_class = GCPProxiesAuthenticator
  c.GCPProxiesAuthenticator.check_header = "X-Goog-IAP-JWT-Assertion"
  c.GCPProxiesAuthenticator.project_id = project_id
  c.GCPProxiesAuthenticator.project_number = project_number
  c.GCPProxiesAuthenticator.backend_service_name = backend_service_name
  c.GCPProxiesAuthenticator.template_to_render = "welcome.html"

elif has_oauth:
  from oauthenticator.google import GoogleOAuthenticator

  c.JupyterHub.authenticator_class = GoogleOAuthenticator
  c.GoogleOAuthenticator.oauth_callback_url = oauth_google_callback_url
  c.GoogleOAuthenticator.client_id = access_secret_version(
      os.environ['PROJECT'], 
      oauth_google_clientid, 
      'latest')
  c.GoogleOAuthenticator.client_secret = access_secret_version(
      os.environ['PROJECT'], 
      oauth_google_clientsecret, 
      'latest')
  c.GoogleOAuthenticator.hosted_domain = oauth_google_domain.split(',')
  c.GoogleOAuthenticator.login_service = 'your Google Cloud Platform domain.'

else:
  raise web.HTTPError(401, f'Missing one or more parameters for authenticator.')
  #raise RuntimeError(f'Missing one or more parameters for authenticator.')

admins = os.environ.get('ADMINS', '')
if admins:
  c.Authenticator.admin_users = admins.split(',')

# PostgreSQL
# If all the environment variables related to PostgreSQL are set, extracts the
# password from the secret store and sets up the database connection reference.

pg_host = os.environ.get('POSTGRES_HOST', '')
pg_user = os.environ.get('POSTGRES_USER', '')
pg_pass_key = os.environ.get('POSTGRES_PASS', '')

if not (pg_host and pg_user and pg_pass_key):
  raise web.HTTPError(401, f'Missing one or more database parameters..')

pg_pass = access_secret_version(os.environ['PROJECT'], pg_pass_key, 'latest')
c.JupyterHub.db_url = 'postgresql://{}:{}@{}:5432/jupyterhub'.format(
    pg_user, pg_pass, pg_host
)
EOT
}

# 'append-config-local'
# Adds content to jupyterhub_config.py so JupyterHub
# can run locally, generally for testing purposes.
function append-config-local {
  cat <<EOT >> jupyterhub_config.py
## Start of configuration for JupyterHub on local machine ##

# Generally 8080 but can be customized.
c.JupyterHub.port = int(os.environ.get('PROXY_PORT', 8080))

# Authenticator
from gcpproxiesauthenticator.gcpproxiesauthenticator import GCPProxiesAuthenticator
c.JupyterHub.authenticator_class = GCPProxiesAuthenticator
c.GCPProxiesAuthenticator.check_header = "X-Inverting-Proxy-User-Id"
c.GCPProxiesAuthenticator.template_to_render = "welcome.html"
c.GCPProxiesAuthenticator.dummy_email = "test@example.com"  
EOT
}


# 'append-to-jupyterhub-config'
# Checks where JupyterHub is hosted and appends the 
# relevant configuration content to jupyterhub_config.py.
function append-to-jupyterhub-config {
  
  # Checks if JupyterHub runs on a GCP instance by trying to fetch the instance metadata.
  status_gcp=$( curl -o /dev/null -s -w "%{http_code}\n" ${metadata_base_url}/instance/hostname -H "Metadata-Flavor: Google" )
  if [ $status_gcp != "200" ]; then
    echo "Running locally." 
    append-config-local
    return 0
  fi

  # Sets default project and regions because JupyterHub is hosted on GCP.
  export PROJECT=$( curl -s ${metadata_base_url}/project/project-id -H "Metadata-Flavor: Google")
  set-region-and-zone-from-metadata
  set-default-subnet
  set-default-configs
  
  # Checks if runs on AI Notebook by reading a metadata passed as an environment variable.
  jupyterhub_host_type=$( curl -s ${metadata_base_url}/instance/attributes/jupyterhub-host-type -H "Metadata-Flavor: Google" )
  if [ "$jupyterhub_host_type" == "ain" ]; then
    echo "Running on AI Notebook."
    append-config-ain
    return 0 
  fi
  
  # Instance runs on GCP but not an on AI Notebook, so most likely on a MIG
  # TODO(developer): If you run JupyterHub somewhere else, adapt this part to the chosen host.
  echo "Running on MIG."
  append-config-mig
  return 0
}


# 'set-region-and-zone-from-metadata'
# If region environment variable is not set, then infer from
# the region part of the zone obtained from instance metadata.
# If the DATAPROC_LOCATIONS_LIST environment variable is not set,
# then infer a valid suffix from the current zone
function set-region-and-zone-from-metadata {
  zone_uri=$( curl -s ${metadata_base_url}/instance/zone -H "Metadata-Flavor: Google") 
  region=$( echo $zone_uri | sed -En 's:^projects/.+/zones/([a-z]+-[a-z]+[0-9]+)-([a-z])$:\1:p' )
  zone_suffix=$( echo $zone_uri | sed -En 's:^projects/.+/zones/([a-z]+-[a-z]+[0-9]+)-([a-z])$:\2:p' )
  if [ -z "$JUPYTERHUB_REGION" ];
  then
    export JUPYTERHUB_REGION="${region}"
  fi
  if [ -z "$DATAPROC_LOCATIONS_LIST" ];
  then
    echo "DATAPROC_LOCATIONS_LIST not specified, using Hub instance zone suffix -${zone_suffix}"
    export DATAPROC_LOCATIONS_LIST="${zone_suffix}"
  fi
}


# 'set-default-subnet'
# Set the DATAPROC_DEFAULT_SUBNET environment variable
# Call this function only after JUPYTERHUB_REGION has been set
# Multiple fallbacks for backwards compatibility if users don't specify a subnet
# 1. If the subnet is explicitly set by the user, respect that
# 2. If the instance subnet is specified in metadata (by the UI), use that
# 3. Attempt to call Compute API to determine which subnet this instance is in
# 4. If all else fails, set the default subnet to 'default' for the region
#    that the instance is in and hope for the best
function set-default-subnet() {
  # Respect default subnet if explicitly set
  if [ ! -z "${DATAPROC_DEFAULT_SUBNET}" ];
  then
    return 0
  fi

  # If subnet set in metadata, use that
  echo "No Dataproc default subnet specified in environment, trying to get subnet URI from instance metadata"
  local metadata_subnet
  metadata_subnet=$( curl -s --fail ${metadata_base_url}/instance/attributes/instance-subnet-uri -H "Metadata-Flavor: Google" )
  local metadata_call_ret=$?
  if [ "${metadata_call_ret}" -eq "0" ];
  then
    echo "Inferred subnet from metadata: ${metadata_subnet}"
    export DATAPROC_DEFAULT_SUBNET="${metadata_subnet}"
    return 0
  fi

  # Attempt to call compute API to determine which subnet this instance is on
  echo "Couldn't determine subnet from metadata, trying to get subnet URI from compute API."
  local name=$( curl -s ${metadata_base_url}/instance/name -H "Metadata-Flavor: Google" )
  local zone=$( curl -s ${metadata_base_url}/instance/zone -H "Metadata-Flavor: Google" | \
                sed -En 's:^projects/.+/zones/([a-z]+-[a-z]+[0-9]+-[a-z])$:\1:p' )
  local compute_api_subnet
  compute_api_subnet=$( gcloud compute instances describe "${name}" --zone="${zone}" --format='value[](networkInterfaces.subnetwork)' )
  local compute_api_ret=$?
  if [ "${compute_api_ret}" -eq "0" ];
  then
    echo "Inferred subnet by calling Compute API: ${compute_api_subnet}"
    export DATAPROC_DEFAULT_SUBNET="${compute_api_subnet}"
    return 0
  fi

  # As a last-ditch effort, assume the default subnet exists for this project
  echo "Couldn't get subnet from compute API, falling back to using 'default' subnet."
  local subnet="https://www.googleapis.com/compute/v1/projects/${PROJECT}/regions/${JUPYTERHUB_REGION}/subnetworks/default"
  echo "Setting subnet to ${subnet}"
  export DATAPROC_DEFAULT_SUBNET="${subnet}"
}


# 'set-default-configs'
# If the user didn't specify any relevant configs, point them torwards a fixed
# set of public example configs
function set-default-configs() {
  if [ -z "${DATAPROC_CONFIGS}" ];
  then
    echo "Dataproc configs not specified, falling back to public configs"
    export DATAPROC_CONFIGS="gs://dataproc-spawner-dist/example-configs/single-node-cluster.yaml,gs://dataproc-spawner-dist/example-configs/standard-cluster.yaml"
  fi
}

append-to-jupyterhub-config

# Starts JupyterHub.
jupyterhub
