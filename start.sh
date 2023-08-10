#!/bin/bash

DB_HOST=127.0.0.1
DB_NAME=test_base
DB_USER=root
DB_PASSWORD=Qwerty123~
DB_PORT=33060

docker run --rm -p ${DB_PORT}:3306 -e MYSQL_DATABASE=${DB_NAME} -e MYSQL_ROOT_PASSWORD=${DB_PASSWORD} -d mysql:8.1

echo 'Waiting for mysql ...'
counter=1
while ! mysql --protocol TCP --host=${DB_HOST} --port=${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "show databases;" > /dev/null 2>&1; do
    sleep 1
    counter=`expr $counter + 1`
    if [ $counter -gt 60 ]; then
        >&2 echo "We have been waiting for MySQL too long already; failing."
        exit 1
    fi;
done

echo 'Creating tables ...'

mysql --host=${DB_HOST} --port=${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} ${DB_NAME} < ./sql/00001_schema.sql

echo 'Done'
