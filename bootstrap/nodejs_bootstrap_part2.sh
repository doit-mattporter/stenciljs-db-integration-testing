#!/usr/bin/env bash

# Install NodeJS
nvm install stable

# Install nodemon and required npm packages
git remote rm origin
npm init
npm install body-parser \
child-process \
cluster \
ejs \
express \
google-auth-library \
@google-cloud/secret-manager \
http \
mysql \
@stencil/core@latest \
--save-exact

npm install -g nodemon

# Launch web server
(nohup nodemon /opt/stenciljs-db-integration-testing/server.js > /opt/stenciljs_demo.log 2> /opt/stenciljs_demo_err.log &)
sleep 0.5
rm -f nohup.out
