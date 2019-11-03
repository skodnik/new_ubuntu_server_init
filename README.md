# Инициализация нового сервера

## При первом подключении под root

1. Устанавливает ufw fail2ban make ntp.
2. Спрашивает имя нового пользователя и создает его, добавляет в группу sudo.
3. Настраивает ufw фаервол. Спрашивает новый порт для ssh.
4. Устанавливает mc ncdu zsh.
5. Спрашивает и устанавливает docker-ec docker-compose из официального Docker репозитория.
5. Спрашивает и устанавливает временную зону Europe/Moscow.
6. "Сбрасывает" пароль для рута.

> todo: Подумать над настройками fail2ban

```
Ubuntu 18.04
sh -c "$(curl -fsSL https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init_ubuntu_1804.sh)"

CentOS 7
sh -c "$(curl -fsSL https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init_centos_7.sh)"
```

## После загрузки под новым пользователем
### Настройка zsh и oh-my-zsh

1. Установка и запуск oh-my-zsh.
```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```
2. Установка плагинов цветового выделения команд и автоподстановки.
3. Перезапись имеющихся настроек на удобные мне настройки (тема, автоисправление и пр.).
4. Применение новых настроек.
```
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && wget https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/configs/zshrc_example && cp zshrc_example ~/.zshrc && rm zshrc_example && source ~/.zshrc
```
```
chsh -s /bin/zsh
```
