# Инициализация нового сервера на Ubuntu 18.04

## При первом подключении под root

1. Устанавливает ufw fail2ban make.
2. Спрашивает имя нового пользователя и создает его, добавляет в группу sudo.
3. Настраивает ufw фаервол. Спрашивает новый порт для ssh.
4. Устанавливает docker docker-compose mc zsh.
5. systemctl enable docker
6. "Сбрасывает" пароль для рута.

```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init.sh)"
```

## После загрузки под новым пользователем

1. Запуск zsh.
2. Установка и запуск oh-my-zsh.
3. Установка плагинов цветового выделения команд и автоподстановки.
4. Перезапись имеющихся настроек на удобные мне настройки (тема, автоисправление и пр.).
5. Применение новых настроек.

### Настройка zsh и oh-my-zsh
```
zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && wget https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/configs/zshrc_example && cp zshrc_example ~/.zshrc && rm zshrc_example && source ~/.zshrc
```