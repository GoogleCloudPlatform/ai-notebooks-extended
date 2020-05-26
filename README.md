# AI Notebook Extended

Although GCP provides several solutions to run Notebooks, some customers might need to extend existing capabilities. 

This repository leverages some open-source software including:

  - [JupyterHub][jupyterhub]: Helps administrator manage users and notebooks configuration centrally.
  - Spawners: Create notebook servers either on the same infrastructure as JupyterHub or on remote servers. [KubeSpawner][kubespawner] and [DataprocSpawner][dataprocspawner] are two possible options amongst others.
  - Authenticators: There are multiple options to log into the JupyterHub interface. The examples of this repository runs on Google Cloud and leverage either Cloud Identity Aware Proxy or the Inverting Proxy. In both cases, authentication is done through the [User Proxy Authenticator for GCP][authenticator]
  
Google Cloud provide the following tools to run Notebooks:

  - AI Plaform Notebooks: Runs single-instance Jupyter notebooks on Compute Engine instances.
  - Dataproc Notebooks: Runs notebooks (Zeppeline, Jupyter) in a Spark context.
  - Dataproc Hub: Enables administrator to centrally manage Dataproc cluster configurations for their users. End users can choose from a curated list of option and quickly start their own single-user development environment in a Spark context with the libraries that need being pre-installed.


In some case, you might need additional customization options. If this is the case, this repository provide some examples:

  - [dataproc-hub-example](./dataproc-hub-example/): Extends Dataproc Hub with additional features. See Dataproc Hub [README](./dataproc-hub-example/README.md) for more details.

    - Runs JupyterHub on a [Managed Instance Group][mig]
    - Provides authentication through [Cloud Identity Aware Proxy][iap]
    - Create notebooks servers on [Dataproc][dataproc]

  - gke-hub-example -- COMING SOON --: Extends AI Platform Notebooks to [Google Kubernetes Engine][gke]

    - Runs JupyterHub on a Google Kubernetes Engine cluster
    - Provides authentication through [Inverting Proxy][inverting_proxy]
    - Create notebooks servers on Google Kubernetes Engine

# Disclaimer

[This is not an official Google product](https://opensource.google.com/docs/releasing/publishing/#disclaimer)

The examples of this repository are not supported by Google. If you need to deploy them in production, reach out to a Google [Cloud certified partners](partners) or your local sales team.

[jupyterhub]: https://jupyterhub.readthedocs.io/en/stable/
[kubespawner]: https://github.com/jupyterhub/kubespawner
[dataprocspawner]: https://github.com/GoogleCloudDataproc/jupyterhub-dataprocspawner
[authenticator]: https://github.com/GoogleCloudPlatform/jupyterhub-gcp-proxies-authenticator
[iap]: https://cloud.google.com/iap/docs/
[inverting_proxy]: https://github.com/google/inverting-proxy
[mig]: https://cloud.google.com/compute/docs/instance-groups
[dataproc]: https://cloud.google.com/dataproc/docs
[gke]: https://cloud.google.com/kubernetes-engine/docs
[partners]: https://cloud.google.com/partners
