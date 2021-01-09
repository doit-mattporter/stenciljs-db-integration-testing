#!/usr/bin/env bash
export PROJECT_ID="ticket37519"
export CODE_BUCKET="ticket37519-code-bucket"
export MYSQL_ROOT_PWD=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
export MYSQL_CONTACT_USER_PWD=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
