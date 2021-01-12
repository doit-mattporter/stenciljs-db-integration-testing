# stenciljs-db-integration-testing

Within a new GCP project, following the automated deployment instructions below will create a basic NodeJS + Bootstrap 4 web server utilizing StencilJS components that interacts with a MySQL database on Cloud SQL. The web server demonstrates (1) writes to a MySQL DB hosted on Cloud SQL via a Contact form page, and (2) reads from that database via the Homepage.

## GCP Project setup

Create a new GCP project, open up Cloud Shell, and run the following:

```bash
git clone https://github.com/doit-mattporter/stenciljs-db-integration-testing.git
# If desired, edit stenciljs-db-integration-testing/bootstrap/project_variables.sh
chmod +x stenciljs-db-integration-testing/bootstrap/project_setup.sh
./stenciljs-db-integration-testing/bootstrap/project_setup.sh
```

## Compute Engine StencilJS VM

The web server listens at: `http://<vm_public_ip>:8080`

To manually restart nodemon, SSH onto the VM and run: `nodemon /opt/stenciljs-db-integration-testing/server.js`. Make sure nodemon is not already running.
