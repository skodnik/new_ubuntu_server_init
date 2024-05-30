# Инициализация нового сервера

## При первом подключении под root

1. Устанавливает ufw fail2ban make ntp.
2. Спрашивает имя нового пользователя и создает его, добавляет в группу sudo.
3. Настраивает ufw фаервол. Спрашивает новый порт для ssh.
4. Устанавливает mc ncdu zsh.
5. Спрашивает и устанавливает docker-ec docker-compose из официального Docker репозитория.
6. Спрашивает и устанавливает временную зону Europe/Moscow.
7. "Сбрасывает" пароль для рута.

> todo: Подумать над настройками fail2ban

### Ubuntu 22.04

1. Добавляет системного пользователя git.
2. Позволяет для новых пользователей добавлять ssh ключи. Для git с ограниченными правами.
3. Формирует файл отчет в который размещает служебную информацию.

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init_ubuntu_2204.sh)"
```

### Ubuntu 20.04

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init_ubuntu_2004.sh)"
```

### Ubuntu 18.04

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init_ubuntu_1804.sh)"
```

### CentOS 7

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init_centos_7.sh)"
```

## После загрузки под новым пользователем

### Корректировка hostname (если почему-то не изменился)

```shell
sudo hostname new-host-name
```

### Настройка zsh и oh-my-zsh

1. Установка и запуск oh-my-zsh.

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```

1. Установка плагинов цветового выделения команд и автоподстановки.
2. Перезапись имеющихся настроек на удобные мне настройки (тема, автоисправление и пр.).
3. Применение новых настроек.

```shell
umask 022 && \
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions && \
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting && \
git clone https://github.com/agkozak/zsh-z $ZSH_CUSTOM/plugins/zsh-z && \
git clone https://github.com/supercrabtree/k $ZSH_CUSTOM/plugins/k && \
wget https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/configs/zshrc_example && \
cp zshrc_example ~/.zshrc && \
rm zshrc_example && \
source ~/.zshrc
```

## Установка зеркал для docker hub

**Делайте это понимая зачем и почему это нужно!**.

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/ubuntu_2204_install_docker_hub_mirrors.sh)"
```

Проверить доступность образов.

```shell
docker run hello-world
```


## Установка корневых сертификатов Сбер

**Делайте это понимая зачем и почему это нужно!**.

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/ubuntu_2204_install_sber_certs.sh)"
```

Проверить корректность установки.

```shell
curl https://3dsecmt.sberbank.ru/payment/webservices/merchant-ws?wsdl
```
