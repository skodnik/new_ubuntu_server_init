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

cat <<-EOF

    ${GREEN}Let's the party started!${RESET}

    apt update && apt upgrade

EOF

apt update && apt upgrade -y