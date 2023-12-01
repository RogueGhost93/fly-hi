#!/bin/bash -x
set -euo pipefail

version=$(cat /etc/issue.net | awk '{print tolower($1)}')

sudo apt update
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

sudo mkdir -p /etc/apt/keyrings
#sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$version/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$version \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update

sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
getent group docker &>/dev/null || groupadd docker &>/dev/null
sudo usermod -aG docker $USER || true

sudo curl -L https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

newgrp docker
#sudo su $USER --session-command "./install.sh"
