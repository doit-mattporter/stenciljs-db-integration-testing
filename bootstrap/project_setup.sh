#!/usr/bin/env bash
# Enable service APIs
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable sqladmin.googleapis.com

# Create bucket where NodeJS code resides. Will get bootstraped onto server.
gsutil mb -p $PROJECT_ID -l us-central1 -b on gs://$CODE_BUCKET/

# Create NodeJS service demo'ing StencilJS elements
gcloud iam service-accounts create stenciljs-demo-sa \
    --description="Service account for StencilJS Demo running on GCE" \
    --display-name="StencilJS Demo Service Account"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:stenciljs-demo-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:stenciljs-demo-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.objectViewer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:stenciljs-demo-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.objectViewer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:stenciljs-demo-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/cloudsql.client"

gcloud compute --project=$PROJECT_ID instances create nodejs-stenciljs \
    --zone=us-central1-a \
    --machine-type=e2-medium \
    --subnet=default \
    --network-tier=PREMIUM \
    --metadata=startup-script=echo\ \"Bootstrap\ script\ here\" \
    --maintenance-policy=MIGRATE \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --service-account=
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

gcloud compute --project=$PROJECT_ID firewall-rules create default-allow-http \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server

gcloud compute --project=$PROJECT_ID firewall-rules create default-allow-https \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:443 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=https-server

gcloud compute --project=$PROJECT_ID firewall-rules create default-allow-mysql \
    --direction=EGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:3306 \
    --target-tags=https-server

# Create a Secret Manager secret holding the Cloud SQL admin password
echo $MYSQL_ROOT_PWD | gcloud secrets create wfe-mysql-root --data-file=-
echo $MYSQL_CONTACT_USER_PWD | gcloud secrets create wfe-mysql-contact-user --data-file=-

# Create MySQL server hosted on Cloud SQL
gcloud sql instances create wfe-mysql-2 \
    --database-version=MYSQL_8_0 \
    --tier=db-n1-standard-1 \
    --zone=us-central1-a \
    --root-password=$MYSQL_ROOT_PWD

gcloud sql --project=$PROJECT_ID databases create contactdb --instance=wfe-mysql
gcloud sql --project=$PROJECT_ID users create contact_form_write_user --instance=wfe-mysql --host="%" --password=$MYSQL_CONTACT_USER_PWD

sql_cmd="
CREATE TABLE Contacts (
    ContactID int NOT NULL AUTO_INCREMENT,
    FirstName varchar(75) NOT NULL,
    LastName varchar(75) NOT NULL,
    Email varchar(100),
    Message varchar(1000),
    PRIMARY KEY (ContactID)
);"
MYSQL_IP_STR=`gcloud sql instances describe wfe-mysql --project $PROJECT_ID --format 'value(ipAddresses.ipAddress)'`
MYSQL_IP_ARRAY=(${MYSQL_IP_STR//;/ })
mysql -u root -p$MYSQL_CONTACT_USER_PWD -h ${MYSQL_IP_ARRAY[0]} contactdb -e "${sql_cmd}"
