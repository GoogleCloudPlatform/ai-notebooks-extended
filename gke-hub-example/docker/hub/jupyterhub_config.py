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

import os, re
import requests
import socket
import string, random

from tornado import web

from google.cloud import secretmanager_v1beta1 as secretmanager

from kubespawner import KubeSpawner


def access_secret_version(project_id, secret_id, version_id):
    """
  Accesses the payload for the given secret version if one exists. The version
  can be a version number as a string (e.g. "5") or an alias (e.g. "latest").
  """
    client = secretmanager.SecretManagerServiceClient()
    name = client.secret_version_path(project_id, secret_id, version_id)
    response = client.access_secret_version(name)
    payload = response.payload.data.decode('UTF-8')
    return payload


def is_true(boolstring: str):
    """ Converts an environment variables to a Python boolean. """
    if boolstring.lower() in ('true', 'True', '1', True):
        return True
    return False


######################################################
# JupyterHub Configuration
# Includes spawner and authenticator
######################################################

# Must be 8080 to meet Inverting Proxy requirements.
c.JupyterHub.port = 8080

# Multiple single user server per user.
c.JupyterHub.allow_named_servers = True

# Listens on all interfaces.
c.JupyterHub.hub_ip = '0.0.0.0'

# Port can not be 8001. Conflicts with another one process.
c.ConfigurableHTTPProxy.api_url = 'http://127.0.0.1:8005'

# Hostname that Cloud Dataproc can access to connect to the Hub.
c.JupyterHub.hub_connect_ip = socket.gethostbyname(socket.gethostname())

# Template for the user form.
c.JupyterHub.template_paths = ['/etc/jupyterhub/templates']

# Opens on JupyterLab instead of Jupyter's tree
c.Spawner.default_url = os.environ.get('SPAWNER_DEFAULT_URL', '/lab')

# The port that the spawned notebook listens on for the hub to connect
c.Spawner.port = 8080

# c.NotebookApp.ip = '0.0.0.0'
# c.NotebookApp.port = 8080
# c.NotebookApp.open_browser = False

c.JupyterHub.spawner_class = 'kubespawner.KubeSpawner'

# An admin can set its own profiles here. For example:
# {
#   'display_name': 'Base Notebook',
#   'kubespawner_override': {
#     'image': 'jupyter/base-notebook',
#     'cpu_limit': 0.5,
#     'mem_limit': '512M',
#   }
# }
c.KubeSpawner.profile_list = []

# Appends additional list of images provided as env variables by the admin when
# setting up the container. Helpful when testing but does not support limits.
spawnable_profiles = os.environ.get('spawnable_profiles', '')
if spawnable_profiles:
    for profile in spawnable_profiles.split(','):
        c.KubeSpawner.profile_list.append({
            'display_name': re.sub('://|/|:|_|\.', '-', profile.lower()),
            'kubespawner_override': {
                'image': profile,
            }
        })

# Authenticator
# Uses a custom user proxy authenticator that leverage headers set by the
# Inverting Proxy to verify the identity of the user.
# c.JupyterHub.authenticator_class = 'dummyauthenticator.DummyAuthenticator'
from gcpproxiesauthenticator.gcpproxiesauthenticator import GCPProxiesAuthenticator
c.JupyterHub.authenticator_class = GCPProxiesAuthenticator
c.GCPProxiesAuthenticator.check_header = 'X-Inverting-Proxy-User-Id'
c.GCPProxiesAuthenticator.dummy_email = 'test@example.com'
c.GCPProxiesAuthenticator.template_to_render = 'welcome.html'

# c.Authenticator.admin_users = {'<USERNAME>'}
# c.Authenticator.whitelist = {'<USERNAME>', '<USERNAME1>'}
