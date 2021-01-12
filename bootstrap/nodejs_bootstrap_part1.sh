#!/usr/bin/env bash
# Install basic Linux tools
apt-get update
apt-get -y dist-upgrade
apt-get -y install git
# Install MariaDB to enable MySQL client connectivity
apt-get -y install mariadb-server

# Install Node.js + NPM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
# exec bash # Needed to discover nvm; doesn't work well with metadata automated bootstrapping. So, run the rest in a second bootstrapping script.
