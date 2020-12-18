#!/usr/bin/env bash
sudo apt-get -y update
sudo apt-get -y install apt-transport-https wget ca-certificates
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
sudo apt-get -y update
sudo apt-get -y install mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
