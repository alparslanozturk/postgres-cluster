

# Postgresql cluster replication kurulumu

docker ile postgresql replication kurulumu anlatılacaktır. 

1. Aynı extension kurulu olmalıdır. 
2. "postgres" kullanıcı için pg_hba.conf a bir satır girilmelidir.
3. "repuser" gibi bir role acilaiblir. tüm yetkileri readonly olacaktir. 
  

docker exec -it --user postgres db1 bash
create role repuser password 'parola' login replication;

-> pg_hba.conf;
host   replication     all             7.7.7.0/24              trust
  


```
select pg_drop_replication_slot('kuheylan');
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
