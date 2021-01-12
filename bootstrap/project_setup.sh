#!/usr/bin/env bash
# NOTE: If you have not done so, run: git clone https://github.com/doit-mattporter/stenciljs-db-integration-testing.git

# Source environment variables
source stenciljs-db-integration-testing/bootstrap/project_variables.sh

# Enable service APIs
nohup gcloud services enable cloudresourcemanager.googleapis.com &
nohup gcloud services enable compute.googleapis.com &
nohup gcloud services enable secretmanager.googleapis.com &
# Service networking is required to create the MySQL DB with a private IP
nohup gcloud services enable servicenetworking.googleapis.com &
nohup gcloud services enable sqladmin.googleapis.com &

# Begin archiving the code directory while we wait for APIs to enable
tar -czf stenciljs_demo.tar.gz stenciljs-db-integration-testing/
# Create bucket where NodeJS code will be placed for bootstrapping onto StencilJS Demo server.
gsutil mb -p $PROJECT_ID -l $REGION -b on gs://$CODE_BUCKET/
gsutil cp stenciljs_demo.tar.gz gs://$CODE_BUCKET/

wait

# Create a Secret Manager secret holding the Cloud SQL admin password
echo $MYSQL_ROOT_PWD | gcloud secrets create wfe-mysql-root --data-file=-
echo $MYSQL_CONTACT_USER_PWD | gcloud secrets create wfe-mysql-contact-user --data-file=-
# Create MySQL server hosted on Cloud SQL with a private IP
gcloud compute addresses create google-managed-services-default \
    --global \
    --purpose=VPC_PEERING \
    --prefix-length=20 \
    --network="projects/$PROJECT_ID/global/networks/default"

gcloud services vpc-peerings connect \
    --service=servicenetworking.googleapis.com \
    --ranges=google-managed-services-default \
    --network="default" \
    --project=$PROJECT_ID

gcloud beta sql instances create wfe-mysql \
    --database-version=MYSQL_8_0 \
    --tier=db-n1-standard-1 \
    --zone=$ZONE \
    --network="projects/$PROJECT_ID/global/networks/default" \
    --root-password=$MYSQL_ROOT_PWD

# Run queries for MySQL from Cloud Shell through Cloud SQL Proxy
wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy
chmod +x cloud_sql_proxy
nohup ./cloud_sql_proxy -instances=$PROJECT_ID:$REGION:wfe-mysql=tcp:3306 &
sleep 3

# Initialize MySQL VM with empty contactdb database, Contacts table, and contact_form_write_user user
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
mysql -u root -p$MYSQL_CONTACT_USER_PWD --host 127.0.0.1 contactdb -e "$sql_cmd"

# Create NodeJS service account for StencilJS demo
gcloud iam service-accounts create stenciljs-demo-sa \
    --description="Service account for StencilJS Demo running on GCE" \
    --display-name="StencilJS Demo Service Account"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:stenciljs-demo-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:stenciljs-demo-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/storage.objectViewer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:stenciljs-demo-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/cloudsql.client"

# Create firewall rules for the StencilJS demo VM
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
    --target-tags=mysql-client

# Create StencilJS demo VM
# Bootstrap code used in VM metadata:
# gsutil cp gs://$CODE_BUCKET/stenciljs_demo.tar.gz .
# tar -C /opt/ -zxf stenciljs_demo.tar.gz
# chmod +x /opt/stenciljs-db-integration-testing/bootstrap/nodejs_bootstrap_part*.sh
# /opt/stenciljs-db-integration-testing/bootstrap/nodejs_bootstrap_part1.sh
# /opt/stenciljs-db-integration-testing/bootstrap/nodejs_bootstrap_part2.sh
gcloud compute --project=$PROJECT_ID instances create nodejs-stenciljs \
    --zone=$ZONE \
    --machine-type=e2-medium \
    --subnet=default \
    --network-tier=PREMIUM \
    --metadata=startup-script=gsutil\ cp\ gs://\$CODE_BUCKET/stenciljs_demo.tar.gz\ .$'\n'tar\ -C\ /opt/\ -zxf\ stenciljs_demo.tar.gz$'\n'chmod\ \+x\ /opt/stenciljs-db-integration-testing/bootstrap/nodejs_bootstrap_part\*.sh$'\n'/opt/stenciljs-db-integration-testing/bootstrap/nodejs_bootstrap_part1.sh$'\n'/opt/stenciljs-db-integration-testing/bootstrap/nodejs_bootstrap_part2.sh \
    --maintenance-policy=MIGRATE \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --service-account=stenciljs-demo-sa@$PROJECT_ID.iam.gserviceaccount.com \
    --tags=http-server,https-server,mysql-client \
    --image=debian-10-buster-v20201216 \
    --image-project=debian-cloud \
    --boot-disk-size=10GB \
    --boot-disk-type=pd-standard \
    --boot-disk-device-name=nodejs-stenciljs-root \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --reservation-affinity=any
