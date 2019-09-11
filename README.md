# Инициализация нового сервера на ubuntu

## При первом подключении под root
```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init.sh)"
```

## После загрузки под новым пользователем
### Настройка zsh и oh-my-zsh
```
zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && wget https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/configs/zshrc_example && cp zshrc_example ~/.zshrc && rm zshrc_example && source ~/.zshrc
```