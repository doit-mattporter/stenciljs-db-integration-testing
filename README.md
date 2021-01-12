# stenciljs-db-integration-testing

Demo of an automated GCP deployment for a basic NodeJS + Bootstrap4 server utilizing StencilJS components which interacts with a MySQL database on Cloud SQL

## GCP Project setup

Create a new GCP project, open up Cloud Shell, and run the following:

```
git clone https://github.com/doit-mattporter/stenciljs-db-integration-testing.git
# If desired, edit stenciljs-db-integration-testing/bootstrap/project_variables.sh
chmod +x stenciljs-db-integration-testing/bootstrap/project_setup.sh
./stenciljs-db-integration-testing/bootstrap/project_setup.sh
```

This

## Compute Engine StencilJS VM

The web server listens at: http://<vm_public_ip>:8080

To manually restart nodemon, SSH onto the GCE StencilJS demo VM and run: `nodemon /opt/stenciljs-db-integration-testing/server.js`. Make sure nodemon is not already running.
