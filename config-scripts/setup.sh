#!/usr/bin/env bash
USER_PUB_KEY=$(cat ~/.ssh/id_rsa.pub)

cat > metadata.yaml << EOM
#cloud-config
disable_root: true
timezone: Europe/Moscow
repo_update: true
repo_upgrade: true
apt:
  preserve_sources_list: true

users:
  - name: yc-user
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - $USER_PUB_KEY
runcmd:
  - apt-get -y update
  - apt-get -y install ruby-full ruby-bundler build-essential git
  - wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
  - echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
  - apt-get -y update
  - apt-get -y install mongodb-org
  - systemctl start mongod
  - systemctl enable mongod
  - git clone -b monolith https://github.com/express42/reddit.git /home/yc-user/reddit
  - cd /home/yc-user/reddit
  - bundle install
  - puma -d
EOM

# Create host
yc compute instance create \
  --name reddit-app \
  --hostname reddit-app \
  --memory=4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --metadata-from-file user-data=./metadata.yaml

rm -f metadata.yaml
