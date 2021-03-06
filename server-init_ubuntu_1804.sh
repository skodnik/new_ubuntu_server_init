#!/usr/bin/env bash

# This script should be run via curl:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init_ubuntu_1804.sh)"
# or wget:
#   sh -c "$(wget -qO- https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init_ubuntu_1804.sh)"
#
# As an alternative, you can first download the install script and run it afterwards:
#   wget https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init_ubuntu_1804.sh
#   sh install.sh

uname -a

read -r -p "Init server now? (y/n): " response
case "$response" in
    [yY][eE][sS]|[yY])
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

echo "\n${YELLOW}>>>>>>>> install ufw fail2ban make ntp <<<<<<<<${RESET}\n"
apt install -y ufw fail2ban make ntp

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
echo "New port for ssh:"
read SSH_PORT
#echo -e "Port ${SSH_PORT}\nPermitRootLogin no" >> /etc/ssh/sshd_config
echo "Port ${SSH_PORT}" >> /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
ufw default deny incoming
ufw default allow outgoing
ufw allow http
ufw allow https
ufw allow ${SSH_PORT}
ufw deny 22
ufw enable
ufw status verbose

echo "\n${YELLOW}>>>>>>>> install docker docker-compose mc ncdu zsh <<<<<<<<${RESET}\n"
#apt install -y docker docker-compose mc ncdu zsh
apt install -y mc ncdu zsh

#echo "Install docker and docker-compose? (y/n): "
#read DOCKER_INSTALL

read -r -p "Install docker and docker-compose? (y/n): " DOCKER_INSTALL
if [ $DOCKER_INSTALL = 'y' ]
then
    # https://docs.docker.com/install/linux/docker-ce/ubuntu/
    apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    apt-key fingerprint 0EBFCD88
    add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
       $(lsb_release -cs) \
       stable"
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io

    # https://docs.docker.com/compose/install/
    curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    usermod -aG docker ${NEW_USER}

    systemctl enable docker
fi

systemctl enable ntp

echo "\n${YELLOW}>>>>>>>> cleaning <<<<<<<<${RESET}\n"
apt -y autoremove
apt -y autoclean
df -Th

echo "\n${YELLOW}>>>>>>>> settingup root password expiry information change <<<<<<<<${RESET}\n"
passwd -l root
date

read -r -p "Set timezone Europe/Moscow? (y/n): " SET_TIMEZONE
if [ $SET_TIMEZONE = 'y' ]
then
    timedatectl set-timezone Europe/Moscow
fi

cat <<-EOF

    ${GREEN}All done. I hope so...${RESET}

    You'll need to reboot server and connect as a new user ${NEW_USER}.

    ${BLUE}ssh ${NEW_USER}@${MY_IP} -p ${SSH_PORT}${RESET}

EOF

read -r -p "Reboot now? (y/n): " response
case "$response" in
    [yY][eE][sS]|[yY])
        echo "Rebooting, see you later."
        reboot
        ;;
    *)
        echo "Ok, reboot later."
        ;;
esac