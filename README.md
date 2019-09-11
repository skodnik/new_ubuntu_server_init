# Инициализация нового сервера на ubuntu

## При первом подключении под root
```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-init.sh)"
```

## После загрузки под новым пользователем
```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/skodnik/new_ubuntu_server_init/master/server-start.sh)"
```

## При первом подключении под root
```
# git clone https://github.com/skodnik/new_ubuntu_server_init.git ~/init && apt install make && cd ~/init && make s0
# reboot
```

## Песле загрузки под новым пользователем
```
$ sudo git clone https://github.com/skodnik/new_ubuntu_server_init.git init && cd ~/init && sudo make s1
$ sudo make s2
```