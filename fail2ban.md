# fail2ban

```shell
sudo fail2ban-client --version
```

Текущий статус службы Fail2Ban, включая её состояние (запущена или остановлена) и логи работы.

```shell
sudo systemctl status fail2ban
```

Общая информация о состоянии Fail2Ban, включая активные тюрьмы (jails) и количество заблокированных IP-адресов.

```shell
sudo fail2ban-client status
```

Рестарт Fail2Ban, применяя изменения в настройках и сбрасывая текущие блокировки.

```shell
sudo systemctl restart fail2ban
```

```shell
sudo systemctl status fail2ban
```

Конфиг.

```shell
sudo vim /etc/fail2ban/fail2ban.conf
```

Если в статусе `loaded (/lib/systemd/system/fail2ban.service; disabled; vendor preset: enabled)`, т.е. disabled:

```shell
sudo systemctl enable fail2ban
```
