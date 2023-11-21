#!/bin/bash -x
getent group docker &>/dev/null || groupadd docker &>/dev/null
sudo usermod -aG docker $USER || true
newgrp docker
