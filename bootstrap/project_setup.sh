#!/usr/bin/env bash
# Enable service APIs
gcloud services enable compute.googleapis.com
gcloud services enable sqladmin.googleapis.com

# Create bucket where NodeJS code resides. Will get bootstraped onto server.
gsutil mb -p $PROJECT_ID -l us-central1 -b on gs://$CODE_BUCKET/

# Create NodeJS service demo'ing StencilJS elements
gcloud beta compute --project=$PROJECT_ID instances create nodejs-stenciljs \
    --zone=us-central1-a \
    --machine-type=e2-medium \
    --subnet=default \
    --network-tier=PREMIUM \
    --metadata=startup-script=echo\ \"Bootstrap\ script\ here\" \
    --maintenance-policy=MIGRATE \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --tags=http-server,https-server \
    --image=debian-10-buster-v20201216 \
    --image-project=debian-cloud \
    --boot-disk-size=10GB \
    --boot-disk-type=pd-standard \
    --boot-disk-device-name=nodejs-stenciljs-root \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --reservation-affinity=any

gcloud compute \
    --project=$PROJECT_ID firewall-rules create default-allow-http \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server

gcloud compute \
    --project=$PROJECT_ID firewall-rules create default-allow-https \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:443 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=https-server

# Create MySQL server hosted on Cloud SQL
gcloud beta sql instances create wfe-mysql-db \
    --database-version=MYSQL_8_0 \
    --tier=db-n1-standard-1 \
    --zone=us-central1-a \
    --root-password=$MYSQL_ROOT_PWD
