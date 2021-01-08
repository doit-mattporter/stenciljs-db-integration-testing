#!/usr/bin/env bash
# Install basic Linux tools
apt-get dist-upgrade

# Install Node.js + NPM + Express and nodemon
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
exec bash # Needed to discover nvm
nvm install stable

# Install code via ZIP file from GitHub
mkdir /code/
cd /code/ || exit
gsutil cp gs://$CODE_BUCKET/stenciljs_project.zip /code/
unzip stenciljs_project.zip -d stenciljs_project/
rm -f stenciljs_project.zip

# Set up app directory
cd /code/stenciljs_project/ || exit
npm init
npm install stencil
(nohup nodemon /code/stenciljs_project/app.js > /code/stenciljs_project.log 2> /code/stenciljs_project_err.log &)
sleep 0.5
rm -f nohup.out
