# Инициализация нового сервера на ubuntu

## При первом подключении под root
```
# git clone https://github.com/skodnik/new_ubuntu_server_init.git ~/init && apt install make && cd ~/init
# vim Makefile
# make s0
# reboot
```

## Песле загрузки под новым пользователем
```
$ sudo git clone https://github.com/skodnik/new_ubuntu_server_init.git init && cd ~/init
$ sudo make s1
$ sudo make s2
```