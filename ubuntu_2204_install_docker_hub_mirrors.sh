#!/usr/bin/env bash

# This script should be run via curl:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/ubuntu_2204_install_sber_certs.sh)"
# or wget:
#   sh -c "$(wget -qO- https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/ubuntu_2204_install_sber_certs.sh)"
#
# As an alternative, you can first download the install script and run it afterwards:
#   wget https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/ubuntu_2204_install_sber_certs.sh
#   sh install.sh

read -r -p "Install docker hub mirrors? (y/n): " INIT
case "${INIT}" in
[yY][eE][sS] | [yY])
  echo "Start."
  date
  ;;
*)
  echo "Ok. Exit."
  exit 0
  ;;
esac

sudo sh -c "cat << EOF > /etc/docker/daemon.json
{
  \"registry-mirrors\": [
    \"https://mirror.gcr.io\",
    \"https://daocloud.io\",
    \"https://c.163.com/\",
    \"https://registry.docker-cn.com\"
  ]
}
EOF"

echo "Ready.\n"
echo "For check run: docker run hello-world"
