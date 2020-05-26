# Dataproc Hub extended

## Deploy Dataproc Hub

### On a GCE instance

You have two options:

1. For testing, you can run the code from the [Dataproc spawner repository][spawner]
1. For production, we recommend to use the official [Dataproc Hub product][hub]

### On a Managed Instance Group

This option provides additional customizations that extend the official Dataproc Hub product.

Follow the steps in the [mig](./build/infrastructure-builder/mig) folder.

If you want to customize the spawner further than the provided configuration options:

1. Fork https://github.com/GoogleCloudDataproc/jupyterhub-dataprocspawner
1. Edit the code as needed
1. Create an image of the new spawner in your project
1. Update the [Dockerfile](./dataproc-hub-example/docker/Dockerfile) with the path to your Dataproc spawner image
1. Redeploy


## Disclaimer

[This is not an official Google product](https://opensource.google.com/docs/releasing/publishing/#disclaimer)

The examples of this repository are not supported by Google. If you need to deploy them in production, reach out to a Google [Cloud certified partners](partners) or your local sales team.

[spawner]: https://github.com/GoogleCloudDataproc/jupyterhub-dataprocspawner
[hub]: https://cloud.google.com/dataproc/docs/tutorials/dataproc-hub-admins
