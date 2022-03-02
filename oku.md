

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
