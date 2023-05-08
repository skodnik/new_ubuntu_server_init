#!/usr/bin/env bash

# This script should be run via curl:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init_ubuntu_2204.sh)"
# or wget:
#   sh -c "$(wget -qO- https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init_ubuntu_2204.sh)"
#
# As an alternative, you can first download the install script and run it afterwards:
#   wget https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init_ubuntu_2004.sh
#   sh install.sh

uname -a

read -r -p "Init server now? (y/n): " INIT
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

DELIMITER="----------"

setup_color


############################################################
# System apt update, upgrade                               #
############################################################
echo -e "\n${YELLOW}${DELIMITER} apt update, upgrade ${DELIMITER}${RESET}\n"
df --print-type --human-readable
apt update && apt list --upgradable && apt upgrade --yes


############################################################
# Create swap file                                         #
############################################################
read -r -p "Make swap? (y/n): " MAKE_SWAP
if [ "${MAKE_SWAP}" = "y" ]; then
  echo "Swap size (example: 2G):"
  read -r SWAP_SIZE
  fallocate --length "${SWAP_SIZE}" /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo "/swapfile none swap sw 0 0" >>/etc/fstab
  free --human
fi


############################################################
# Setup umask 022 -> 002                                   #
############################################################
read -r -p "Add umask 002? (y/n): " UMASK_002
if [ "${UMASK_002}" = "y" ]; then
  echo "umask 002" >> /etc/profile
  source /etc/profile
  echo "${GREEN}umask 002 added to /etc/profile!${RESET}"
fi


############################################################
# Install system base apps                                 #
############################################################
echo -e "\n${YELLOW}${DELIMITER} install ufw fail2ban make ntp ${DELIMITER}${RESET}\n"
apt install --yes ufw fail2ban make ntp


############################################################
# Setup git                                                #
############################################################
read -r -p "Install and setup git? (y/n): " GIT_SETUP
if [ "${GIT_SETUP}" = 'y' ]; then
  apt install --yes git

  echo "Git user name:"
  read -r GIT_USER

  git config --global user.name "${GIT_USER}"

  echo "Git user email:"
  read -r GIT_USER_EMAIL

  git config --global user.email "${GIT_USER_EMAIL}"
  git config --global credential.helper cache
  git config --global credential.helper 'cache --timeout=3600'

  git --version
fi


############################################################
# Add new user with sudo privilege                         #
############################################################
echo -e "\n${YELLOW}${DELIMITER} new sudo user setting up ${DELIMITER}${RESET}\n"
echo "New sudo user name:"
read -r NEW_USER

# Create user
if ! adduser --debug "${NEW_USER}"; then
  echo "${RED}Something wrong with making sudo user!${RESET}"
  exit 1
fi

# Add user to sudo group
if ! usermod --append --groups sudo "${NEW_USER}"; then
  echo "${RED}Something wrong with adding ${NEW_USER} in sudo group!${RESET}"
  exit 1
fi

# Adding public key for new user
read -r -p "Add ${NEW_USER} public key? (y/n): " NEW_USER_PUBLIC_KEY_ANSWER
if [ "${NEW_USER_PUBLIC_KEY_ANSWER}" = "y" ]; then
  mkdir /home/"${NEW_USER}"/.ssh && chmod 700 /home/"${NEW_USER}"/.ssh
  touch /home/"${NEW_USER}"/.ssh/authorized_keys && chmod 600 /home/"${NEW_USER}"/.ssh/authorized_keys

  echo "Public key:"
  read -r NEW_USER_PUBLIC_KEY

  echo "${NEW_USER_PUBLIC_KEY}" >> /home/"${NEW_USER}"/.ssh/authorized_keys
  chown -R "${NEW_USER}":"${NEW_USER}" /home/"${NEW_USER}"/.ssh

  echo "${GREEN}Key added to /home/${NEW_USER}/.ssh/authorized_keys!${RESET}"
fi

echo "${GREEN}User ${NEW_USER} has become sudo!${RESET}"


############################################################
# Add new system user for git                              #
############################################################
read -r -p "Setup new system user for git? (y/n): " GIT_SYSTEM_USER_SETUP
if [ "${GIT_SYSTEM_USER_SETUP}" = 'y' ]; then
  echo -e "\n${YELLOW}${DELIMITER} new git system user setting up ${DELIMITER}${RESET}\n"
  GIT_SYSTEM_USER="git"

  # Create system git user
  if ! adduser --debug "${GIT_SYSTEM_USER}"; then
    echo "${RED}Something wrong with making system ${GIT_SYSTEM_USER} user!${RESET}"
    exit 1
  fi

  # Add system git user to new user group
  if ! usermod --append --groups "${NEW_USER}" "${GIT_SYSTEM_USER}"; then
    echo "${RED}Something wrong with adding ${GIT_SYSTEM_USER} in ${NEW_USER} group!${RESET}"
    exit 1
  fi

  echo "${GREEN}User ${GIT_SYSTEM_USER} added and added to group ${NEW_USER}!${RESET}"

  # If git installed, add git shell to shells list and make it shell active for this user
  if [ "${GIT_SETUP}" = 'y' ]; then
    which git-shell >> /etc/shells
    chsh "${GIT_SYSTEM_USER}" -s "$(which git-shell)"
  fi

  # Add new user to system git user group
  if ! usermod --append --groups "${GIT_SYSTEM_USER}" "${NEW_USER}"; then
    echo "${RED}Something wrong with adding ${NEW_USER} in ${GIT_SYSTEM_USER} group!${RESET}"
    exit 1
  fi

  echo "${GREEN}User ${NEW_USER} added and added to group ${GIT_SYSTEM_USER}!${RESET}"

  # Adding public key for system git user
  read -r -p "Add ${GIT_SYSTEM_USER} public key? (y/n): " GIT_USER_PUBLIC_KEY_ANSWER
  if [ "${GIT_USER_PUBLIC_KEY_ANSWER}" = "y" ]; then
    mkdir /home/"${GIT_SYSTEM_USER}"/.ssh && chmod 700 /home/"${GIT_SYSTEM_USER}"/.ssh
    touch /home/"${GIT_SYSTEM_USER}"/.ssh/authorized_keys && chmod 600 /home/"${GIT_SYSTEM_USER}"/.ssh/authorized_keys

    echo "Public key:"
    read -r GIT_USER_PUBLIC_KEY

    echo "no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ${GIT_USER_PUBLIC_KEY}" >> /home/"${GIT_SYSTEM_USER}"/.ssh/authorized_keys
    chown -R "${GIT_SYSTEM_USER}":"${GIT_SYSTEM_USER}" /home/"${GIT_SYSTEM_USER}"/.ssh

    echo "${GREEN}Key added to /home/${GIT_SYSTEM_USER}/.ssh/authorized_keys!${RESET}"
  fi

  # Create dir for git --bare repos
  mkdir /srv/"${GIT_SYSTEM_USER}"
  echo "${GREEN}Created dir /srv/${GIT_SYSTEM_USER}${RESET}"

  # Make the git user the owner of the new directory
  if ! chown -R "${GIT_SYSTEM_USER}":"${GIT_SYSTEM_USER}" /srv/"${GIT_SYSTEM_USER}"; then
    echo "${RED}Something wrong with making ${GIT_SYSTEM_USER} the owner of the /srv/${GIT_SYSTEM_USER}!${RESET}"
    exit 1
  fi
fi


############################################################
# Install ufw and setting up and change default ssh port   #
############################################################
echo -e "\n${YELLOW}${DELIMITER} ufw setting up and change default ssh port ${DELIMITER}${RESET}\n"
read -r -p "Install ufw firewall? (y/n): " UFW_INSTALL
if [ "${UFW_INSTALL}" = 'y' ]; then
  echo "New port for ssh:"
  read -r SSH_PORT

  {
    echo "Port ${SSH_PORT}"
    echo "PermitRootLogin no"
    echo "MaxAuthTries 3"
    echo "PermitEmptyPasswords no"
  } >>/etc/ssh/sshd_config

  ufw default deny incoming
  ufw default allow outgoing
  ufw allow http
  ufw allow https
  ufw allow "${SSH_PORT}"
  ufw deny 22
  ufw enable
  ufw status verbose
fi


############################################################
# Install mc ncdu composer zsh htop lnav composer jq       #
############################################################
echo -e "\n${YELLOW}${DELIMITER} install mc ncdu composer zsh htop lnav composer jq ${DELIMITER}${RESET}\n"
apt install -y mc ncdu zsh htop lnav composer jq


############################################################
# Install docker and docker-compose setting up             #
############################################################
echo -e "\n${YELLOW}${DELIMITER} docker and docker-compose setting up ${DELIMITER}${RESET}\n"
read -r -p "Install docker and docker-compose? (y/n): " DOCKER_INSTALL
if [ "${DOCKER_INSTALL}" = "y" ]; then
  apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  apt update
  apt install --yes docker-ce docker-ce-cli containerd.io
  systemctl enable --now docker
  docker --version
  usermod --append --groups docker "${NEW_USER}"
  curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
  docker-compose --version
fi


############################################################
# Install nginx and certbot setting up                     #
############################################################
echo -e "\n${YELLOW}${DELIMITER} nginx and certbot setting up ${DELIMITER}${RESET}\n"
read -r -p "Install nginx and certbot? (y/n): " NGINX_INSTALL
if [ "${NGINX_INSTALL}" = "y" ]; then
  apt install --yes nginx certbot python3-certbot-nginx
fi


############################################################
# Enable ntp                                               #
############################################################
systemctl enable ntp


############################################################
# Cleaning up                                              #
############################################################
echo -e "\n${YELLOW}${DELIMITER} cleaning ${DELIMITER}${RESET}\n"
apt --yes autoremove
apt --yes autoclean
df --print-type --human-readable


############################################################
# Setup root password expiry                               #
############################################################
echo -e "\n${YELLOW}${DELIMITER} setup root password expiry ${DELIMITER}${RESET}\n"
passwd --lock root


############################################################
# Deny cron for www-data user                              #
############################################################
echo "www-data" >>/etc/cron.deny


############################################################
# Set timezone Europe/Moscow                               #
############################################################
date
read -r -p "Set timezone Europe/Moscow? (y/n): " SET_TIMEZONE
if [ "${SET_TIMEZONE}" = "y" ]; then
  timedatectl set-timezone Europe/Moscow
fi

df --print-type --human-readable

cat <<-EOF

    ${GREEN}All done. I hope so...${RESET}

    You'll need to reboot server and connect as a new user ${NEW_USER}.

    cli:
    ${BLUE}ssh ${NEW_USER}@${MY_IP} -p ${SSH_PORT}${RESET}

    ~/.ssh/config example:
    Host your_host_name
        HostName ${MY_IP}
        User ${NEW_USER}
        Port ${SSH_PORT}
        IdentityFile path_to_private_key

EOF

if [ "${GIT_SYSTEM_USER_SETUP}" = "y" ]; then
cat <<-EOF

    ${GREEN}Remember! You have ${GIT_SYSTEM_USER} user!${RESET}
    https://git-scm.com/book/en/v2/Git-on-the-Server-Setting-Up-the-Server

    ~/.ssh/config example:
    Host your_host_name_GIT
        HostName ${MY_IP}
        User ${GIT_SYSTEM_USER}
        Port ${SSH_PORT}
        IdentityFile path_to_private_key

EOF
fi


############################################################
# Reboot                                                   #
############################################################
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
