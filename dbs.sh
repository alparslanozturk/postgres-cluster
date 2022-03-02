#!/bin/bash 

docker rm db1 db2 db3 --force 
#docker network rm db
#docker network create db --subnet 7.7.7.0/24

for i in 1 2 3
do 

### docker create
docker run -d --name db$i -h db$i --network db --ip 7.7.7.1$i \
  -p 5432$i:5432 \
  -e POSTGRES_HOST_AUTH_METHOD=scram-sha-256 \
  -e POSTGRES_PASSWORD="parola" \
  -e POSTGRES_INITDB_ARGS="--data-checksums" \
  -e TZ="Europe/Istanbul" \
  -e PGTZ="Europe/Istanbul" \
  postgres 

### bash root user
docker exec db$i bash -c "
apt update && apt install iproute2 procps netcat sudo curl nano openssh-server pgbackrest -y
touch /var/lib/postgresql/.psql_history && chown postgres: /var/lib/postgresql/.psql_history
mkdir /var/lib/postgresql/.ssh 
echo 'postgres ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/postgres
echo 'postgres:parola'|chpasswd
sed -i '2 i sudo /etc/init.d/ssh start' /usr/local/bin/docker-entrypoint.sh
"
docker cp ssh/id_rsa db$i:/var/lib/postgresql/.ssh/
docker cp ssh/id_rsa.pub db$i:/var/lib/postgresql/.ssh/
docker cp ssh/authorized_keys db$i:/var/lib/postgresql/.ssh/
docker exec -it db$i bash -c " chown -R postgres: /var/lib/postgresql/.ssh "
docker exec -it db$i bash -c " chmod 600 /var/lib/postgresql/.ssh/* "

### bash postgres user
docker exec --user postgres db$i bash -c " 
echo  'host replication all 7.7.7.0/24 trust' >> /var/lib/postgresql/data/pg_hba.conf 
cat >/etc/pgbackrest.conf<<EOF
[global]
repo1-host=7.7.7.100
repo1-host-user=postgres
[demo]
pg$i-path=/var/lib/postgresql/data
EOF
#pgbackrest --stanza=demo --log-level-console=info stanza-create
pgbackrest --stanza=demo --log-level-console=info check
"
### psql 
docker exec --user postgres db$i psql -c "alter system set archive_mode to on"
docker exec --user postgres db$i psql -c "alter system set archive_command to 'pgbackrest --stanza=demo arhive-push %p'"


docker stop db$i
docker start db$i


done
