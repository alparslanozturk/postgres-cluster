#!/bin/bash 


psql  -U postgres -h 7.7.7.11 -c "create database testdb"
pgbench -U postgres -h 7.7.7.11 -i testdb                 
pgbench -U postgres -h 7.7.7.11 -c 10 -j 2 -t 1000 testdb

