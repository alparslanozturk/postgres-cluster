
# 1. alias eklenerek de herhangi bir docker a bağlanılabilir. 

```
$ alias db1='docker exec -it --user postgres db1 bash -c "cd ~; bash "'

$ db1
postgres@pgbackrest:~$
postgres@pgbackrest:~$
postgres@pgbackrest:~$
```


# 2. Postgresql cluster replication kurulumu

docker ile postgresql replication kurulumu yapılacaktır. 


![image](https://user-images.githubusercontent.com/9527118/155673474-f1e87e5c-899c-4b69-b1e4-351faa27c16b.png)


1. Aynı extension kurulu olmalıdır. 
2. "postgres" kullanıcı için pg_hba.conf a bir satır girilmelidir.
3. "repuser" gibi bir role acilaiblir. tüm yetkileri readonly olacaktir. 
  

docker exec -it --user postgres db1 bash

create role repuser password 'parola' login replication;

-> pg_hba.conf;

host   replication     all             7.7.7.0/24              trust
  


```
select pg_drop_replication_slot('db2');
select * from pg_stat_replication;
select * from pg_replication_slots;

default(replica) isneirse -> alter system set wal_level TO 'logical';
select pg_conf_reload();

select pg_drop_replication_slot('db2')
```


# DB2
docker exec -it --user postgres db2 bash 

rm -rf /var/lib/postgresql/data/*

pg_basebackup  -D /var/lib/postgresql/data/ -Fp -R -C -S db2 -h 7.7.7.11 -P -v

docker start db2 


# DB3

docker exec -it db2 bash 

rm -rf /var/lib/postgresql/data/*

pg_basebackup  -D /var/lib/postgresql/data/ -Fp -R -C -S db3 -h 7.7.7.11 -P -v

docker start db3




### backup 

Aşağıdaki hata görüyorsanız "pgbacrest --stanza=??? backup komudunu pgbackreset sunucu üzerinden çalıştırın diyor.

```
postgres@db2:~$ pgbackrest --stanza=db2 backup
2022-03-09 16:26:30.534 P00   INFO: backup command begin 2.37: --exec-id=101-70c3d7ee --log-level-console=info --pg1-path=/var/lib/postgresql/data --repo1-host=7.7.7.100 --repo1-host-user=postgres --repo1-retention-full=5 --stanza=db2
ERROR: [072]: backup command must be run on the repository host
```



