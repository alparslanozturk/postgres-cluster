#!/bin/bash 

### docker re-create
docker rm pgbackrest --force 
docker rm db1 db2 db3 --force 
docker network rm db
docker network create db --subnet 7.7.7.0/24 --ipv6=false

### pgbackrest
docker run -d --name pgbackrest -h pgbackrest --network db --ip 7.7.7.100 \
  --sysctl "net.ipv6.conf.all.disable_ipv6=1" \
  --shm-size=1g \
  -e POSTGRES_HOST_AUTH_METHOD=scram-sha-256 \
  -e POSTGRES_PASSWORD="parola" \
  -e POSTGRES_INITDB_ARGS="--data-checksums" \
  -e TZ="Europe/Istanbul" \
  -e PGTZ="Europe/Istanbul" \
  postgres

### root user fix bla bla...
docker exec pgbackrest bash -c " 
localedef -c -f UTF-8 -i en_US en_US.UTF-8
localedef -c -f UTF-8 -i tr_TR tr_TR.UTF-8
apt update && apt install iproute2 procps netcat sudo curl nano openssh-server pgbackrest -y 
touch /var/lib/postgresql/.psql_history && chown postgres: /var/lib/postgresql/.psql_history
mkdir /var/lib/postgresql/.ssh
cat >/var/lib/postgresql/.ssh/config<<EOF
Host *
        StrictHostKeyChecking no
        UserKnownHostsFile=/dev/null
        LogLevel quiet
EOF
chown postgres: /etc/pgbackrest.conf /var/lib/pgbackrest
echo 'postgres:parola'|chpasswd
echo 'postgres ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/postgres
sed -i '2 i sudo /etc/init.d/ssh start' /usr/local/bin/docker-entrypoint.sh
"
docker cp ssh/id_rsa pgbackrest:/var/lib/postgresql/.ssh/
docker cp ssh/id_rsa.pub pgbackrest:/var/lib/postgresql/.ssh/
docker cp ssh/authorized_keys pgbackrest:/var/lib/postgresql/.ssh/
docker cp ssh/config pgbackrest:/var/lib/postgresql/.ssh/
docker exec pgbackrest bash -c " chown -R postgres: /var/lib/postgresql/.ssh "
docker exec pgbackrest bash -c " chmod 600 /var/lib/postgresql/.ssh/* "

### psql user fix bla bla...
docker exec --user postgres pgbackrest psql -c "alter system set archive_mode to on"
docker exec --user postgres pgbackrest psql -c "alter system set archive_command to 'pgbackrest --stanza=demo archive-push %p'"
docker exec --user postgres pgbackrest psql -c "select pg_reload_conf()"
docker restart pgbackrest
sleep 5
docker exec --user postgres pgbackrest bash -c " 
sed -i '/^host all all all scram-sha-256/i host replication all 7.7.7.0/24 trust' /var/lib/postgresql/data/pg_hba.conf
sed -i '/^host all all all scram-sha-256/i host all all 7.7.7.0/24 trust' /var/lib/postgresql/data/pg_hba.conf
sed -i '/::1/d' /var/lib/postgresql/data/pg_hba.conf
cat > /etc/pgbackrest.conf<<EOF
[global]
repo1-path=/var/lib/pgbackrest
repo1-retention-full=5
log-level-console=info
start-fast=y
[dbs]
pg1-host=7.7.7.11
pg1-path=/var/lib/postgresql/data
pg1-user=postgres
pg2-host=7.7.7.12
pg2-path=/var/lib/postgresql/data
pg2-user=postgres
pg3-host=7.7.7.13
pg3-path=/var/lib/postgresql/data
pg3-user=postgres
#recovery-option=primary_conninfo=host=7.7.7.11 user=postgres
EOF
"
docker stop pgbackrest 
docker start pgbackrest







for i in 1 2 3
do 
### db
docker run -d --name db$i -h db$i --network db --ip 7.7.7.1$i \
  --sysctl "net.ipv6.conf.all.disable_ipv6=1" \
  --shm-size=1g \
  -p 5432$i:5432 \
  -e POSTGRES_HOST_AUTH_METHOD=scram-sha-256 \
  -e POSTGRES_PASSWORD="parola" \
  -e POSTGRES_INITDB_ARGS="--data-checksums" \
  -e TZ="Europe/Istanbul" \
  -e PGTZ="Europe/Istanbul" \
  postgres 

### root user fix bla bla...
docker exec db$i bash -c "
localedef -c -f UTF-8 -i en_US en_US.UTF-8
localedef -c -f UTF-8 -i tr_TR tr_TR.UTF-8
apt update && apt install iproute2 procps netcat sudo curl nano openssh-server pgbackrest -y
touch /var/lib/postgresql/.psql_history && chown postgres: /var/lib/postgresql/.psql_history
mkdir /var/lib/postgresql/.ssh 
cat >/var/lib/postgresql/.ssh/config<<EOF
Host *
        StrictHostKeyChecking no
        UserKnownHostsFile=/dev/null
        LogLevel quiet
EOF
echo 'postgres ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/postgres
echo 'postgres:parola'|chpasswd
sed -i '2 i sudo /etc/init.d/ssh start' /usr/local/bin/docker-entrypoint.sh
"
docker cp ssh/id_rsa db$i:/var/lib/postgresql/.ssh/
docker cp ssh/id_rsa.pub db$i:/var/lib/postgresql/.ssh/
docker cp ssh/authorized_keys db$i:/var/lib/postgresql/.ssh/
docker cp ssh/config db$i:/var/lib/postgresql/.ssh/
docker exec -it db$i bash -c " chown -R postgres: /var/lib/postgresql/.ssh "
docker exec -it db$i bash -c " chmod 600 /var/lib/postgresql/.ssh/* "

### psql user fix bla bla...
docker exec --user postgres db$i psql -c "alter system set archive_mode to on"
docker exec --user postgres db$i psql -c "alter system set archive_command to 'pgbackrest --stanza=dbs archive-push %p'"
docker exec --user postgres db$i psql -c "select pg_reload_conf()"
docker restart db$i
sleep 5
docker exec --user postgres db$i bash -c " 
sed -i '/^host all all all scram-sha-256/i host replication all 7.7.7.0/24 trust' /var/lib/postgresql/data/pg_hba.conf
sed -i '/^host all all all scram-sha-256/i host all all 7.7.7.0/24 trust' /var/lib/postgresql/data/pg_hba.conf
sed -i '/::1/d' /var/lib/postgresql/data/pg_hba.conf
cat >/etc/pgbackrest.conf<<EOF
[global]
repo1-host=7.7.7.100
repo1-host-user=postgres
repo1-retention-full=5
log-level-console=info
start-fast=y
[dbs]
pg1-host=7.7.7.11
pg1-path=/var/lib/postgresql/data
pg1-user=postgres
pg2-host=7.7.7.12
pg2-path=/var/lib/postgresql/data
pg2-user=postgres
pg3-host=7.7.7.13
pg3-path=/var/lib/postgresql/data
pg3-user=postgres
#recovery-option=primary_conninfo=host=7.7.7.11 user=postgres
EOF
"
docker stop db$i
docker start db$i
done


### stanza-create=dbs
docker exec --user postgres pgbackrest bash -c "pgbackrest --stanza=dbs stanza-create"
docker exec --user postgres pgbackrest bash -c "pgbackrest --stanza=dbs info"
sleep 7 

### stream replication on db2,db3
for i in 2 3
do
docker exec --user postgres db1 psql -c " select pg_drop_replication_slot('db$i'); "
docker exec --user postgres db$i bash -c "
rm -rf /var/lib/postgresql/data
pg_basebackup -D /var/lib/postgresql/data/ -Fp -R -C -S db$i -h 7.7.7.11 -P -v
"
sleep 5
docker exec --user postgres db$i bash -c " sed -i 's/user=postgres/application_name=db$i user=postgres/g' /var/lib/postgresql/data/postgresql.auto.conf "
docker restart db$i
sleep 5
docker restart db$i
done

sleep 10

### msrs database create
docker exec --user postgres db1 psql -c "create database msrs locale='tr_TR.UTF8' template template0;"
docker exec --user postgres db1 psql -c "select * from pg_replication_slots "
docker exec --user postgres db1 psql -c "select * from pg_stat_replication  "
