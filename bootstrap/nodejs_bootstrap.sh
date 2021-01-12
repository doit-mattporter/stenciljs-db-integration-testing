#!/usr/bin/env bash
# Install basic Linux tools
apt-get update
apt-get -y dist-upgrade
apt-get -y install git
# Install MariaDB to enable MySQL client connectivity
apt-get -y install mariadb-server

# Install Node.js + NPM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
source /.nvm/nvm.sh # Needed to discover nvm
nvm install stable

# Install nodemon and required npm packages
cd /opt/stenciljs-db-integration-testing/ || exit
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
