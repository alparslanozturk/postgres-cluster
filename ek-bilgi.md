
# stanza-create: tüm sunucular açılınca yapmak lazım .

```
$ docker exec -it --user postgres pgbackrest bash

postgres@pgbackrest:/$ pgbackrest --stanza=demo --log-level-console=info stanza-create
```

# root olarak bağlanmak 
```
$ docker exec -it db1 bash
```

# postgres olarak bağlanmak 

```
$ docker exec -it --user postgres db1 bash
```

# psql çalıştırmak 

```
$ docker exec -it --user postgres db1 psql 
```

# sunucular arasında ssh yapmak 

```
$ docker exec -it --user postgres pgbackrest bash
postgres@pgbackrest:/$ ssh db1
postgres@db1's password:
Linux db1 5.10.93.2-microsoft-standard-WSL2 #1 SMP Wed Jan 26 22:38:54 UTC 2022 x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Wed Mar  2 15:11:50 2022 from 7.7.7.100
postgres@db1:~$
```



# pgbackrest ayarları kontrol

```
$ docker exec -it --user postgres db1 psql
psql (14.1 (Debian 14.1-1.pgdg110+1))
Type "help" for help.

postgres=# show archive_mode;
 archive_mode
--------------
 on
(1 row)

postgres=# show archive_command;
             archive_command
------------------------------------------
 pgbackreset --stanza=demo arhive-push %p
(1 row)

postgres=# \q
```
