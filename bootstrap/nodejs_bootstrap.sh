#!/usr/bin/env bash
# Install basic Linux tools
apt-get update
apt-get -y dist-upgrade
apt-get -y install git
# Install MariaDB to enable MySQL client connectivity
apt-get -y install mariadb-server

# Install Node.js + NPM + Express and nodemon
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
exec bash # Needed to discover nvm
nvm install stable

# Install code via ZIP file from GitHub
# cd /opt/
# gsutil cp gs://$CODE_BUCKET/stenciljs_project.zip /opt/
# unzip stenciljs_project.zip -d stenciljs_project/
# rm -f stenciljs_project.zip

# Set up app directory
git clone https://github.com/ionic-team/stencil-component-starter /opt/stenciljs_demo/
cd /opt/stenciljs_demo/
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
(nohup nodemon /opt/stenciljs_demo/server.js > /opt/stenciljs_demo.log 2> /opt/stenciljs_demo_err.log &)
sleep 0.5
rm -f nohup.out
