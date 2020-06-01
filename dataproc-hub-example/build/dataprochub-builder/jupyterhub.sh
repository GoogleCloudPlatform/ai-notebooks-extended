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


set +x

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
  export PROJECT=$( curl ${metadata_base_url}/project/project-id -H "Metadata-Flavor: Google")
  set-region-from-metadata
  
  # Checks if runs on AI Notebook by reading a metadata passed as an environment variable.
  jupyterhub_host_type=$( curl ${metadata_base_url}/instance/attributes/jupyterhub-host-type -H "Metadata-Flavor: Google" )
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


# 'set-region-from-metadata'
# If region environment variable is not set, then infer from
# the region part of the zone obtained from instance metadata.
function set-region-from-metadata {
  if [ -z "$JUPYTERHUB_REGION" ];
  then
    zone_uri=$( curl ${metadata_base_url}/instance/zone -H "Metadata-Flavor: Google") 
    region=$( echo $zone_uri | sed -En 's:^projects/.+/zones/([a-z]+-[a-z]+[0-9]+)(-[a-z])$:\1:p' )
    export JUPYTERHUB_REGION=${region}
  fi
}

append-to-jupyterhub-config

# Starts JupyterHub.
jupyterhub
