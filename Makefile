# vars
NEW_USER=master
SSH_PORT=303

# basic install
s0:
	apt update && apt upgrade -y
	apt install -y ufw fail2ban
	@echo ">>>>>>>> Creating new sudo user: $(NEW_USER) <<<<<<<<"
	adduser $(NEW_USER)
	usermod -a -G sudo $(NEW_USER)
	echo "Port $(SSH_PORT)" >> /etc/ssh/sshd_config
	ufw default deny incoming
	ufw default allow outgoing
	ufw allow http
	ufw allow https
	ufw allow $(SSH_PORT)
	ufw deny 22
	ufw enable
	ufw status verbose
	@echo ">>>>>>>> Now you need to reboot server. Next connection param: ssh $(NEW_USER)@***.***.***.*** -p $(SSH_PORT) <<<<<<<<"

s1:
	rm -R /root/init
	passwd -l root
	apt install -y docker docker-compose mc
	systemctl enable docker
	@echo ">>>>>>>> root passwd was removed. docker docker-compose mc was installed. <<<<<<<<"

s2:
	apt install -y zsh
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
	git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
	echo "plugins=(git zsh-autosuggestions zsh-syntax-highlighting docker docker-compose)" >> ~/.zshrc
	cp ./configs/zshrc_example ~/.zshrc

st:
	chsh -s $(which zsh) $(whoami)
	grep $(NEW_USER) /etc/passwd
	PASSWORD ?= $(shell stty -echo; read -p "Password: " pwd; stty echo; echo $$pwd)
