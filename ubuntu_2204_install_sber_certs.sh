#!/usr/bin/env bash

# This script should be run via curl:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/ubuntu_2204_install_sber_certs.sh)"
# or wget:
#   sh -c "$(wget -qO- https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/ubuntu_2204_install_sber_certs.sh)"
#
# As an alternative, you can first download the install script and run it afterwards:
#   wget https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/ubuntu_2204_install_sber_certs.sh
#   sh install.sh

echo "https://www.sberbank.com/ru/certificates"

read -r -p "Install certs now? (y/n): " INIT
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

wget https://gu-st.ru/content/lending/russian_trusted_root_ca_pem.crt
wget https://gu-st.ru/content/lending/russian_trusted_sub_ca_pem.crt

cp russian_trusted_root_ca_pem.crt /usr/local/share/ca-certificates/russian_trusted_root_ca_pem.crt
cp russian_trusted_sub_ca_pem.crt /usr/local/share/ca-certificates/russian_trusted_sub_ca_pem.crt

update-ca-certificates
