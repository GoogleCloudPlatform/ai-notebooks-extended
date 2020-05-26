project_id      = "[YOUR_PROJECT_ID]"                           # abcd-123
// domain       = "[YOUR_DOMAIN]"                               # example.com
domain_name     = "[YOUR_DOMAIN_NAME]"                          # jupyterhub.example.com
gcs_suffix      = ""                                            # Suffix for organizing GCs files


use_iap = true                                                  # true,false
support_email   = "[YOUR_SUPPORT_EMAIL]"                        # support@example.com

# Leave empty unless you use Cloud DNS zone and want
# Terraform to create a record for the zone automatically,
dns_zone        = "[YOUR_ZONE]"                                 # example-zone

gcs_buckets_location = "US"                                     # Default location for buckets.       
gcs_terraform_state  = "[YOUR_TFSTATE_BUCKET]"                  # GCS bucket name where to store Terraform state.

jupyterhub_region               = "[YOUR_GCP_REGION]"           # Region for resources. ex: us-central1
jupyterhub_container_image      = "[YOUR_REGISTRY_PATH]"        # gcr.io/[PROJECT]/jupyterhub:latest

# Make sure to change this after a destroy. SQL instance name are reserved for 7 days after deletion
cloudsql_instance_name_prefix   = "[YOUR_CLOUDSQL_INSTANCE]"    # jupyterhub-xyz.

# Comma-separated list of GCP zones where a user can create a
# Cloud Dataproc cluster. Provided by an admin. A Dataproc 
# cluster must be in the same region as JupyterHub instances.
dataproc_locations_list  = "[YOUR_ZONE_LETTERS]"                # b,c

# Used in variables.tf to create env var for JupyterHub.
files_dataproc_configs    = [
    "cluster-single-noimage.yaml",
    "cluster-standard-cpu.yaml",
    "cluster-standard-pvm.yaml",
    "cluster-standard-v100.yaml"
]

# Default page to display when JupyterLab open. If none provided, defaults on tree.
spawner_default_url = "/lab"

# Email domain for Oauth. Must match your Oauth setup.
oauth_google_domain = "[YOUR_OAUTH_DOMAIN]"                     # example.com            

# Secrets
oauth_google_clientid     = "[YOUR_OAUTH_CLIENTID]"             # abc.apps.googleusercontent.com
oauth_google_clientsecret = "[YOUR_OAUTH_CLIENTSECRET]"         # abc123DEF456ghi
postgres_pass             = "[YOUR_CLOUDSQL_PASSWORD]"          # password