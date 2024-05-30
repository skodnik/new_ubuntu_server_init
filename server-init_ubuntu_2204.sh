#!/usr/bin/env bash

# This script should be run via curl:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init_ubuntu_2204.sh)"
# or wget:
#   sh -c "$(wget -qO- https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init_ubuntu_2204.sh)"
#
# As an alternative, you can first download the install script and run it afterwards:
#   wget https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init_ubuntu_2204.sh
#   sh install.sh

REPORT_FILE="report.txt"

uname -a

{ echo "date: $(date)"
  echo ""
  echo "uname: $(uname -a)"
  echo ""
} >> "${REPORT_FILE}"

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

section_message() {
  echo -e "\n${YELLOW}${DELIMITER} $1 ${DELIMITER}${RESET}\n"
}

error_message_and_exit() {
  echo "${RED}$1${RESET}"
  exit 1
}

success_message() {
  echo "${GREEN}$1${RESET}"
}

############################################################
# System apt update, upgrade                               #
############################################################
section_message "apt update, upgrade"
df --print-type --human-readable
apt update && apt list --upgradable && apt upgrade --yes

############################################################
# Setup hostname                                           #
############################################################
section_message "hostname"
read -r -p "Setup hostname? (y/n): " SETUP_HOSTNAME
if [ "${SETUP_HOSTNAME}" = "y" ]; then
  hostname
  echo "New hostname (only '-' allowed, example: new-host-name):"
  read -r NEW_HOST_NAME
  hostname "${NEW_HOST_NAME}"
fi

############################################################
# Create swap file                                         #
############################################################
section_message "swap"
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
section_message "umask"
read -r -p "Add umask 002? (y/n): " UMASK_002
if [ "${UMASK_002}" = "y" ]; then
  umask 002
  echo "umask 002" >> /etc/profile
  source /etc/profile
  success_message "umask 002 added to /etc/profile"
fi

{ echo ""
  echo "umask: $(umask)"
  echo ""
} >> "${REPORT_FILE}"

############################################################
# Install system base apps                                 #
############################################################
section_message "install ufw fail2ban make ntp restic"
apt install --yes ufw fail2ban make ntp restic bat

############################################################
# Setup git                                                #
############################################################
section_message "setup git"
read -r -p "Install and setup git? (y/n): " GIT_SETUP
if [ "${GIT_SETUP}" = "y" ]; then
  apt install --yes git

  echo "Git user name:"
  read -r GIT_USER

  git config --global user.name "${GIT_USER}"

  echo "Git user email:"
  read -r GIT_USER_EMAIL

  git config --global user.email "${GIT_USER_EMAIL}"
  git config --global credential.helper cache
  git config --global credential.helper 'cache --timeout=3600'
  git config --global core.fileMode false

  git --version

  { echo ""
    echo "git --version: $(git --version)"
    echo "git config --global --list: $(git config --global --list)"
    echo ""
  } >> "${REPORT_FILE}"
fi

############################################################
# Add new user with sudo privilege                         #
############################################################
section_message "new sudo user setting up"
echo "New sudo user name:"
read -r NEW_USER

# Create user
if ! adduser --debug "${NEW_USER}"; then
  error_message_and_exit "Something wrong with making sudo user!"
fi

# Add user to sudo group
if ! usermod --append --groups sudo "${NEW_USER}"; then
  error_message_and_exit "Something wrong with adding ${NEW_USER} in sudo group!"
fi

# Adding public key for new user
read -r -p "Add ${NEW_USER} public key? (y/n): " NEW_USER_PUBLIC_KEY_ANSWER
if [ "${NEW_USER_PUBLIC_KEY_ANSWER}" = "y" ]; then
  mkdir /home/"${NEW_USER}"/.ssh && chmod 700 /home/"${NEW_USER}"/.ssh
  touch /home/"${NEW_USER}"/.ssh/authorized_keys && chmod 600 /home/"${NEW_USER}"/.ssh/authorized_keys

  echo "Public key:"
  read -r NEW_USER_PUBLIC_KEY

  echo "${NEW_USER_PUBLIC_KEY}" >>/home/"${NEW_USER}"/.ssh/authorized_keys
  chown -R "${NEW_USER}":"${NEW_USER}" /home/"${NEW_USER}"/.ssh

  success_message "Key added to /home/${NEW_USER}/.ssh/authorized_keys!"
fi

mkdir /home/"${NEW_USER}"/scripts
mkdir /home/"${NEW_USER}"/backups

success_message "User ${NEW_USER} has become sudo!"

############################################################
# Add new system user for git                              #
############################################################
section_message "system user for vcs"
read -r -p "Setup new system user for git? (y/n): " GIT_SYSTEM_USER_SETUP
if [ "${GIT_SYSTEM_USER_SETUP}" = "y" ]; then
  echo "System git user name (example: vcs):"
  read -r GIT_SYSTEM_USER

  # Create system git user
  if ! adduser --debug "${GIT_SYSTEM_USER}"; then
    error_message_and_exit "Something wrong with making system ${GIT_SYSTEM_USER} user!"
  fi

  # Add system git user to new user group
  if ! usermod --append --groups "${NEW_USER}" "${GIT_SYSTEM_USER}"; then
    error_message_and_exit "Something wrong with adding ${GIT_SYSTEM_USER} in ${NEW_USER} group!"
  fi

  success_message "User ${GIT_SYSTEM_USER} added and added to group ${NEW_USER}!"

  # If git installed, add git shell to shells list and make it shell active for this user
  if [ "${GIT_SETUP}" = "y" ]; then
    which git-shell >>/etc/shells
    chsh "${GIT_SYSTEM_USER}" -s "$(which git-shell)"
  fi

  # Add new user to system git user group
  if ! usermod --append --groups "${GIT_SYSTEM_USER}" "${NEW_USER}"; then
    error_message_and_exit "Something wrong with adding ${NEW_USER} in ${GIT_SYSTEM_USER} group!"
  fi

  success_message "User ${NEW_USER} added and added to group ${GIT_SYSTEM_USER}!"

  # Adding public key for system git user
  read -r -p "Add ${GIT_SYSTEM_USER} public key? (y/n): " GIT_USER_PUBLIC_KEY_ANSWER
  if [ "${GIT_USER_PUBLIC_KEY_ANSWER}" = "y" ]; then
    mkdir /home/"${GIT_SYSTEM_USER}"/.ssh && chmod 700 /home/"${GIT_SYSTEM_USER}"/.ssh
    touch /home/"${GIT_SYSTEM_USER}"/.ssh/authorized_keys && chmod 600 /home/"${GIT_SYSTEM_USER}"/.ssh/authorized_keys

    echo "Public key:"
    read -r GIT_USER_PUBLIC_KEY

    echo "no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ${GIT_USER_PUBLIC_KEY}" >>/home/"${GIT_SYSTEM_USER}"/.ssh/authorized_keys
    chown -R "${GIT_SYSTEM_USER}":"${GIT_SYSTEM_USER}" /home/"${GIT_SYSTEM_USER}"/.ssh

    success_message "Key added to /home/${GIT_SYSTEM_USER}/.ssh/authorized_keys!"
  fi

  # Create dir for git --bare repos
  mkdir /srv/"${GIT_SYSTEM_USER}"

  mkdir /home/"${GIT_SYSTEM_USER}"/apps
  mkdir /home/"${GIT_SYSTEM_USER}"/repos
  mkdir /home/"${GIT_SYSTEM_USER}"/backups

  chown -R "${GIT_SYSTEM_USER}":"${GIT_SYSTEM_USER}" /home/"${GIT_SYSTEM_USER}"

  success_message "Created dir /srv/${GIT_SYSTEM_USER}"

  # Make the git user the owner of the new directory
  if ! chown -R "${GIT_SYSTEM_USER}":"${GIT_SYSTEM_USER}" /srv/"${GIT_SYSTEM_USER}"; then
    error_message_and_exit "Something wrong with making ${GIT_SYSTEM_USER} the owner of the /srv/${GIT_SYSTEM_USER}!"
  fi
fi

############################################################
# Install ufw and setting up and change default ssh port   #
############################################################
section_message "ufw setting up and change default ssh port"
read -r -p "Install ufw firewall and setup ssh config? (y/n): " UFW_INSTALL
if [ "${UFW_INSTALL}" = "y" ]; then
  echo "New port for ssh:"
  read -r SSH_PORT

  SSHD_CONFIG="/etc/ssh/sshd_config"

  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
  success_message "Created ssh config backup /etc/ssh/sshd_config.bak"

  # Disable root login
  sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' "${SSHD_CONFIG}"

  # Setup max auth tries
  sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/g' "${SSHD_CONFIG}"

  # Disable empty passwords
  sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/g' "${SSHD_CONFIG}"

  # Change ssh port
  sed -i "s/#Port 22/Port ${SSH_PORT}/g" "${SSHD_CONFIG}"

  # Disable X11Forwarding
  sed -i "s/X11Forwarding yes/X11Forwarding no/g" "${SSHD_CONFIG}"

  # Users who allow to connect
  {
    echo "AllowUsers ${NEW_USER} ${GIT_SYSTEM_USER}"
  } >>/etc/ssh/sshd_config

  read -r -p "Disable password auth for ssh (y/n): " DISABLE_PASSWORD_FOR_SSH
  if [ "${DISABLE_PASSWORD_FOR_SSH}" = "y" ]; then
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
  fi

  ufw default deny incoming
  ufw default allow outgoing
  ufw allow http
  ufw allow https
  ufw allow "${SSH_PORT}"
  ufw deny 22
  ufw enable
  ufw status verbose

  { echo ""
    echo "ufw --version: $(ufw --version)"
    echo ""
  } >> "${REPORT_FILE}"
fi

############################################################
# Install mc ncdu composer zsh htop lnav composer jq       #
############################################################
section_message "install mc ncdu composer zsh htop lnav composer jq"
apt install -y mc ncdu zsh htop lnav composer jq

############################################################
# Install docker and docker-compose setting up             #
############################################################
section_message "docker and docker-compose setting up"
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

  { echo ""
    echo "docker --version: $(docker --version)"
    echo "docker-compose --version: $(docker-compose --version)"
    echo ""
  } >> "${REPORT_FILE}"

  read -r -p "Install docker hub mirrors? (y/n): " DOCKER_HUB_MIRRORS_INSTALL
  if [ "${DOCKER_INSTALL}" = "y" ]; then
    cat << EOF > /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://mirror.gcr.io"
  ]
}
EOF

    { echo ""
      echo "Docker hub mirrors installed"
      echo ""
    } >> "${REPORT_FILE}"
  fi
fi

############################################################
# Install nginx and certbot setting up                     #
############################################################
section_message "nginx and certbot setting up"
read -r -p "Install nginx and certbot? (y/n): " NGINX_INSTALL
if [ "${NGINX_INSTALL}" = "y" ]; then
  apt install --yes nginx certbot python3-certbot-nginx

  # Add new user to www-data group
  if ! usermod --append --groups www-data "${NEW_USER}"; then
    error_message_and_exit "Something wrong with adding ${NEW_USER} in www-data group!"
  fi

  # Add www-data to new user group
  if ! usermod --append --groups "${NEW_USER}" www-data; then
    error_message_and_exit "Something wrong with adding www-data in ${NEW_USER} group!"
  fi

  if [ "${GIT_SYSTEM_USER_SETUP}" = "y" ]; then
    # Add git system user to www-data group
    if ! usermod --append --groups www-data "${GIT_SYSTEM_USER}"; then
      error_message_and_exit "Something wrong with adding ${GIT_SYSTEM_USER} in www-data group!"
    fi

    # Add www-data to git system user group
    if ! usermod --append --groups "${GIT_SYSTEM_USER}" www-data; then
      error_message_and_exit "Something wrong with adding www-data in ${GIT_SYSTEM_USER} group!"
    fi
  fi

  { echo ""
    echo "nginx -v: $(nginx -v)"
    echo "certbot --version: $(certbot --version)"
    echo ""
  } >> "${REPORT_FILE}"
fi

############################################################
# Enable ntp                                               #
############################################################
section_message "ntp"
systemctl enable ntp

############################################################
# Cleaning up                                              #
############################################################
section_message "cleaning"
apt --yes autoremove
apt --yes autoclean
df --print-type --human-readable

############################################################
# Setup root password expiry                               #
############################################################
section_message "setup root password expiry"
passwd --lock root

############################################################
# Deny cron for www-data user                              #
############################################################
section_message "deny cron for www-data user"
echo "www-data" >>/etc/cron.deny

############################################################
# Set timezone Europe/Moscow                               #
############################################################
section_message "timezone Europe/Moscow"
date
read -r -p "Set timezone Europe/Moscow? (y/n): " SET_TIMEZONE
if [ "${SET_TIMEZONE}" = "y" ]; then
  timedatectl set-timezone Europe/Moscow
  date
fi

############################################################
# Disable welcome banners                                  #
############################################################
section_message "disable welcome banners"
read -r -p "Disable welcome banners (y/n): " DISABLE_WELCOME_BANNERS
if [ "${DISABLE_WELCOME_BANNERS}" = "y" ]; then
  chmod -x /etc/update-motd.d/*

  read -r -p "Enable sysinfo banner (y/n): " ENABLE_SYSINFO_BANNER
  if [ "${ENABLE_SYSINFO_BANNER}" = "y" ]; then
    chmod +x /etc/update-motd.d/50-landscape-sysinfo
  fi
fi

############################################################
# Report                                                   #
############################################################
section_message "report"
df --print-type --human-readable

HOSTNAME=$(hostname)

success_message "Actual ssh config:"
grep "PermitRootLogin" "${SSHD_CONFIG}"
grep "MaxAuthTries" "${SSHD_CONFIG}"
grep "PermitEmptyPasswords" "${SSHD_CONFIG}"
grep "Port" "${SSHD_CONFIG}"
grep "AllowUsers" "${SSHD_CONFIG}"
grep "PasswordAuthentication" "${SSHD_CONFIG}"

{ echo ""
  echo "df --print-type --human-readable: $(df --print-type --human-readable)"
  echo ""
  echo "free --human: $(free --human)"
  echo ""
  echo "ssh config: ${SSHD_CONFIG}"
  grep "PermitRootLogin" "${SSHD_CONFIG}"
  grep "MaxAuthTries" "${SSHD_CONFIG}"
  grep "PermitEmptyPasswords" "${SSHD_CONFIG}"
  grep "Port" "${SSHD_CONFIG}"
  grep "AllowUsers" "${SSHD_CONFIG}"
  grep "PasswordAuthentication" "${SSHD_CONFIG}"
  echo ""
} >> "${REPORT_FILE}"

{ echo ""
  echo "ssh ${NEW_USER}@${MY_IP} -p ${SSH_PORT}"
  echo ""
  echo "~/.ssh/config example:"
  echo "Host ${HOSTNAME}_${NEW_USER}"
  echo "    HostName ${MY_IP}"
  echo "    User ${NEW_USER}"
  echo "    Port ${SSH_PORT}"
  echo "    IdentityFile ~/.ssh/your_main_key"
} >> "${REPORT_FILE}"

cat <<-EOF

${GREEN}All done. I hope so...${RESET}

You'll need to reboot server and connect as a new user ${NEW_USER}.

cli:
${BLUE}ssh ${NEW_USER}@${MY_IP} -p ${SSH_PORT}${RESET}

~/.ssh/config example:
Host ${HOSTNAME}_${NEW_USER}
    HostName ${MY_IP}
    User ${NEW_USER}
    Port ${SSH_PORT}
    IdentityFile ~/.ssh/your_main_key

EOF

if [ "${GIT_SYSTEM_USER_SETUP}" = "y" ]; then

  { echo ""
    echo "Host ${HOSTNAME}_${GIT_SYSTEM_USER}"
    echo "    HostName ${MY_IP}"
    echo "    User ${GIT_SYSTEM_USER}"
    echo "    Port ${SSH_PORT}"
    echo "    IdentityFile ~/.ssh/your_main_key"
  } >> "${REPORT_FILE}"

  cat <<-EOF

${GREEN}Remember! You have ${GIT_SYSTEM_USER} user!${RESET}
https://git-scm.com/book/en/v2/Git-on-the-Server-Setting-Up-the-Server

~/.ssh/config example:
Host ${HOSTNAME}_${GIT_SYSTEM_USER}
    HostName ${MY_IP}
    User ${GIT_SYSTEM_USER}
    Port ${SSH_PORT}
    IdentityFile ~/.ssh/your_main_key

EOF
fi

chown -R "${NEW_USER}":"${NEW_USER}" /home/"${NEW_USER}"

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
