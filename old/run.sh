

docker rm db1 db2 db3 --force 
docker network rm db
docker network create db --subnet 7.7.7.0/24



for i in 1 2 3
do 


docker run -d --name db$i -h db$i --network db --ip 7.7.7.1$i \
  -p 5432$i:5432 \
  -e POSTGRES_HOST_AUTH_METHOD=scram-sha-256 \
  -e POSTGRES_PASSWORD="parola" \
  -e POSTGRES_INITDB_ARGS="--data-checksums" \
  -e TZ="Europe/Istanbul" \
  -e PGTZ="Europe/Istanbul" \
  postgres 


docker exec db$i bash -c 'apt update && apt install iproute2 procps netcat sudo curl nano vim pgbackrest -y'
docker exec db$i bash -c 'touch /var/lib/postgresql/.psql_history && chown postgres: /var/lib/postgresql/.psql_history'


done
