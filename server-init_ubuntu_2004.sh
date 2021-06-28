#!/usr/bin/env bash

# This script should be run via curl:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init_ubuntu_2004.sh)"
# or wget:
#   sh -c "$(wget -qO- https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init_ubuntu_2004.sh)"
#
# As an alternative, you can first download the install script and run it afterwards:
#   wget https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init_ubuntu_2004.sh
#   sh install.sh

uname -a

read -r -p "Init server now? (y/n): " response
case "$response" in
[yY][eE][sS] | [yY])
  echo "Start."
  date
  ;;
*)
  echo "Ok. Exit."
  exit 0
  ;;
esac

MY_IP=$(curl -s wtfismyip.com/text)

setup_color() {
  # Only use colors if connected to a terminal
  if [ -t 1 ]; then
    RED=$(printf '\033[31m')
    GREEN=$(printf '\033[32m')
    YELLOW=$(printf '\033[33m')
    BLUE=$(printf '\033[34m')
    BOLD=$(printf '\033[1m')
    RESET=$(printf '\033[m')
  else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    RESET=""
  fi
}

setup_color

echo "\n${YELLOW}>>>>>>>> apt update, upgrade <<<<<<<<${RESET}\n"
df -Th
apt update && apt list --upgradable && apt upgrade -y

read -r -p "Make swap 2G? (y/n): " MAKE_SWAP
if [ $MAKE_SWAP = 'y' ]; then
  fallocate --length 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
  free -h
fi

echo "\n${YELLOW}>>>>>>>> install ufw fail2ban make ntp <<<<<<<<${RESET}\n"
apt install -y ufw fail2ban make ntp git

echo "\n${YELLOW}>>>>>>>> new sudo user setting up <<<<<<<<${RESET}\n"
echo "New sudo user name:"
read NEW_USER
adduser --debug ${NEW_USER}
if [ $? -ne 0 ]; then
  exit 1
fi
usermod -aG sudo ${NEW_USER}
if [ $? -eq 0 ]; then
  echo "${GREEN}User ${NEW_USER} has become sudo!${RESET}"
else
  echo "${RED}Something wrong with making sudo user!${RESET}"
  exit 1
fi

echo "\n${YELLOW}>>>>>>>> ufw setting up <<<<<<<<${RESET}\n"
read -r -p "Install ufw firewall? (y/n): " UFW_INSTALL
if [ $UFW_INSTALL = 'y' ]; then
  echo "New port for ssh:"
  read SSH_PORT
  echo "Port ${SSH_PORT}" >>/etc/ssh/sshd_config
  echo "PermitRootLogin no" >>/etc/ssh/sshd_config
  echo "MaxAuthTries 3" >>/etc/ssh/sshd_config
  echo "PermitEmptyPasswords no" >>/etc/ssh/sshd_config
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow http
  ufw allow https
  ufw allow ${SSH_PORT}
  ufw deny 22
  ufw enable
  ufw status verbose
fi

echo "\n${YELLOW}>>>>>>>> install mc ncdu zsh htop lnav <<<<<<<<${RESET}\n"
apt install -y mc ncdu zsh htop lnav

echo "\n${YELLOW}>>>>>>>> docker and docker-compose setting up <<<<<<<<${RESET}\n"
read -r -p "Install docker and docker-compose? (y/n): " DOCKER_INSTALL
if [ $DOCKER_INSTALL = 'y' ]; then
  apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt update
  apt install -y docker-ce docker-ce-cli containerd.io
  systemctl enable --now docker
  docker --version
  usermod -aG docker ${NEW_USER}
  curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
  docker-compose --version
fi

echo "\n${YELLOW}>>>>>>>> nginx and certbot setting up <<<<<<<<${RESET}\n"
read -r -p "Install nginx and certbot? (y/n): " NGINX_INSTALL
if [ $NGINX_INSTALL = 'y' ]; then
  apt install -y nginx certbot python3-certbot-nginx
fi

systemctl enable ntp

echo "\n${YELLOW}>>>>>>>> cleaning <<<<<<<<${RESET}\n"
apt -y autoremove
apt -y autoclean
df -Th

echo "\n${YELLOW}>>>>>>>> setup root password expiry <<<<<<<<${RESET}\n"
echo "www-data" >> /etc/cron.deny
passwd --lock root
date

read -r -p "Set timezone Europe/Moscow? (y/n): " SET_TIMEZONE
if [ $SET_TIMEZONE = 'y' ]; then
  timedatectl set-timezone Europe/Moscow
fi

df -Th

cat <<-EOF

    ${GREEN}All done. I hope so...${RESET}

    You'll need to reboot server and connect as a new user ${NEW_USER}.

    ${BLUE}ssh ${NEW_USER}@${MY_IP} -p ${SSH_PORT}${RESET}

EOF

read -r -p "Reboot now? (y/n): " response
case "$response" in
[yY][eE][sS] | [yY])
  echo "Rebooting, see you later."
  reboot
  ;;
*)
  echo "Ok, reboot later."
  ;;
esac