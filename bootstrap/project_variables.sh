#!/usr/bin/env bash
export PROJECT_ID=`gcloud config get-value project`
export REGION="us-central1"
export ZONE="us-central1-a"
export CODE_BUCKET="$PROJECT_ID-code-bucket"
export MYSQL_ROOT_PWD=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
export MYSQL_CONTACT_USER_PWD=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
