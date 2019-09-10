# Инициализация нового сервера на ubuntu

## При первом подключении под root
```
# git clone https://github.com/skodnik/new_ubuntu_server_init.git ~/init
# apt install make
# cd ~/init
# vim Makefile
# make s0
# reboot
```

## Песле загрузки под новым пользователем
```
# git clone https://github.com/skodnik/new_ubuntu_server_init.git init
# make s1
# make s2
```