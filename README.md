
# 1. alias eklenerek de herhangi bir docker a bağlanılabilir. 
```
alias db1='docker exec -it --user postgres db1 bash -c "cd ~; bash "'
alias db2='docker exec -it --user postgres db2 bash -c "cd ~; bash "'        
alias db3='docker exec -it --user postgres db3 bash -c "cd ~; bash "'
alias rst='docker exec -it --user postgres pgbackrest bash -c "cd ~; bash "' 

$ db1
postgres@db1:~$
```

Note: docker run komudu ile --shm-size=1g gibi vermek çok iyi olacaktır. default 64M gibi bir şey sanırım. pgbackrest ve diğer komutlarda sorun yaşanabilir...


# 2. Postgresql cluster replication kurulumu

run.sh çalıştırıldıktan sonra postgresql replication kurulumu yapılacaktır. Bu işlem için DB1 ve DB2 üzerinde 
DATA dizini silinip pg_basebackup komudu çalıştırlması yeterlidir. Eski sistemlerde kullanılan recovery.conf ve diğer ayarlara gerek yoktur. 



select * from pg_stat_replication \watch
![image](https://user-images.githubusercontent.com/9527118/155673474-f1e87e5c-899c-4b69-b1e4-351faa27c16b.png)


- Aynı extension kurulu olmalıdır. 
- "postgres" kullanıcı için pg_hba.conf girilen "all all" kesinlikle yeterli degildir. Dockerlarda replication için satır girilmiştir. 
- "repuser" gibi bir role acilaiblir. tüm yetkileri readonly olacaktir. 
  
  
```
docker exec -it --user postgres db1 bash
$psql
postgres=#create role repuser password 'parola' login replication;
```

pg_hba.conf
```
host   replication     all             7.7.7.0/24              trust
```


diğer örnekler;
```
select pg_drop_replication_slot('db2');
select * from pg_stat_replication;
select * from pg_replication_slots;

default(replica) isneirse -> alter system set wal_level TO 'logical';
select pg_conf_reload();

select pg_drop_replication_slot('db2')
```

Sunucular çok uzun süre kapalı kalırsa, pgbacrest wal'ları arşive kaldıracak ve aradaki kayıplar kapatılamayacaktır. Bu durumda tekrardan Slotlar silinir ve replication kurulabilir. 

Stream replicaiton active durumu false olduğu görülebilir:
![image](https://user-images.githubusercontent.com/9527118/159441043-682b341c-bb4f-404f-aaaf-96ba58711d64.png)

```
2022-03-22 11:37:10.377 +03 [495] DETAIL:  The primary's identifier is 7076434890037256232, the standby's identifier is 7076435427321561129.
2022-03-22 11:37:15.381 +03 [496] FATAL:  database system identifier differs between the primary and standby
2022-03-22 11:37:15.381 +03 [496] DETAIL:  The primary's identifier is 7076434890037256232, the standby's identifier is 7076435427321561129.
2022-03-22 11:37:20.391 +03 [497] FATAL:  database system identifier differs between the primary and standby
```

## db1 üzerinde
```
select pg_drop_replication_slot('db2');
select pg_drop_replication_slot('db3');
```
tekrardan aşağıdaki adımlar yapılır....


# DB2
docker exec -it --user postgres db2 bash 

```
rm -rf /var/lib/postgresql/data/*
pg_basebackup  -D /var/lib/postgresql/data/ -Fp -R -C -S db2 -h 7.7.7.11 -P -v
```

docker start db2 



# DB3

docker exec -it db2 bash 

```
rm -rf /var/lib/postgresql/data/*
pg_basebackup  -D /var/lib/postgresql/data/ -Fp -R -C -S db3 -h 7.7.7.11 -P -v
```

docker start db3

### Sonuc
```
docker exec --user postgres db1 psql -xc "select * from pg_stat_replication "
```


# "aplication_name" hk. 

postgres@db2:~$ nano  /var/lib/postgresql/data/postgresql.auto.conf
![image](https://user-images.githubusercontent.com/9527118/157861242-7c0c9da3-e30a-4753-92d4-0305f2162b15.png)


 ```
 postgres@db1:~$ psql
psql (14.1 (Debian 14.1-1.pgdg110+1))
Type "help" for help.

postgres=# \x
Expanded display is on.
postgres=# select * from pg_stat_replication;
-[ RECORD 1 ]----+------------------------------
pid              | 590
usesysid         | 10
usename          | postgres
application_name | db2
client_addr      | 7.7.7.12
client_hostname  |
client_port      | 59980
backend_start    | 2022-03-11 14:48:40.315767+03
backend_xmin     |
state            | streaming
sent_lsn         | 0/F000148
write_lsn        | 0/F000148
flush_lsn        | 0/F000148
replay_lsn       | 0/F000148
write_lag        |
flush_lag        |
replay_lag       |
sync_priority    | 0
sync_state       | async
reply_time       | 2022-03-11 14:59:27.831192+03
-[ RECORD 2 ]----+------------------------------
pid              | 584
usesysid         | 10
usename          | postgres
application_name | walreceiver
client_addr      | 7.7.7.13
client_hostname  |
client_port      | 39164
backend_start    | 2022-03-11 14:44:20.876102+03
backend_xmin     |
state            | streaming
sent_lsn         | 0/F000148
write_lsn        | 0/F000148
flush_lsn        | 0/F000148
replay_lsn       | 0/F000148
write_lag        |
flush_lag        |
replay_lag       |
sync_priority    | 0
sync_state       | async
reply_time       | 2022-03-11 14:59:27.831188+03

postgres=#

```



# Backup

Aşağıdaki hata görüyorsanız "pgbacrest --stanza=??? backup komudunu pgbackreset sunucu üzerinden çalıştırın diyor.

```
postgres@db2:~$ pgbackrest --stanza=db2 backup
2022-03-09 16:26:30.534 P00   INFO: backup command begin 2.37: --exec-id=101-70c3d7ee --log-level-console=info --pg1-path=/var/lib/postgresql/data --repo1-host=7.7.7.100 --repo1-host-user=postgres --repo1-retention-full=5 --stanza=db2
ERROR: [072]: backup command must be run on the repository host
```



