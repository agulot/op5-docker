#!/usr/bin/env bash

## Start the services that are needed fro OP5
service mysqld start
sleep 10
service merlind start
service naemon start
service httpd start

sleep infinity
exit 0

