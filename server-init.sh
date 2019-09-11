#!/usr/bin/env bash
#
# This script should be run via curl:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init.sh)"
# or wget:
#   sh -c "$(wget -qO- https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init.sh)"
#
# without using cache:
#   sudo sh -c "$(curl -fsSLH 'Cache-Control: no-cache' https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init.sh)"

# As an alternative, you can first download the install script and run it afterwards:
#   wget https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init.sh
#   sh install.sh

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
apt update && apt upgrade -y

echo "\n${YELLOW}>>>>>>>> install ufw fail2ban make <<<<<<<<${RESET}\n"
apt install -y ufw fail2ban make

echo "\n${YELLOW}>>>>>>>> new sudo user setting up <<<<<<<<${RESET}\n"
echo "New sudo user name:"
read NEW_USER
adduser ${NEW_USER}
if [ $? -ne 0 ]; then
    exit 1
fi
usermod -a -G sudo ${NEW_USER}
if [ $? -eq 0 ]; then
    echo "${YELLOW}User ${NEW_USER} has become sudo!${RESET}"
else
    echo "${RED}Something wrong with making sudo user!${RESET}"
    exit 1
fi

echo "\n${YELLOW}>>>>>>>> ufw setting up <<<<<<<<${RESET}\n"
echo "New port for ssh:"
read SSH_PORT
#echo "Port ${SSH_PORT}" >> /etc/ssh/sshd_config