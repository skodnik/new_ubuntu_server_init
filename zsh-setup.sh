#!/usr/bin/env bash

git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone https://github.com/agkozak/zsh-z $ZSH_CUSTOM/plugins/zsh-z
git clone https://github.com/supercrabtree/k $ZSH_CUSTOM/plugins/k
wget https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/configs/zshrc_example
cp zshrc_example ~/.zshrc
rm zshrc_example
source ~/.zshrc
chsh -s /bin/zsh
