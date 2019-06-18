#!/bin/bash

MASTER_NODE='orchestrator_master'
SLAVE01_NODE='orchestrator_slave01'
SLAVE02_NODE='orchestrator_slave02'

docker-compose up -d

sleep 15;

docker exec ${MASTER_NODE} mysql -uroot -proot -e "CREATE USER 'repl'@'%' IDENTIFIED BY 'repl'"
docker exec ${MASTER_NODE} mysql -uroot -proot -e "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%'"

docker exec ${MASTER_NODE} mysql -uroot -proot -e "show master status"

docker exec ${SLAVE01_NODE} mysql -uroot -proot -e "CHANGE MASTER TO MASTER_HOST='${MASTER_NODE}', \
MASTER_USER='repl', MASTER_PASSWORD='repl', \
MASTER_LOG_FILE='mysql-bin.000003', MASTER_LOG_POS=595"

docker exec ${SLAVE01_NODE} mysql -uroot -proot -e "START SLAVE"

docker exec ${SLAVE02_NODE} mysql -uroot -proot -e "CHANGE MASTER TO MASTER_HOST='${MASTER_NODE}', \
MASTER_USER='repl', MASTER_PASSWORD='repl', \
MASTER_LOG_FILE='mysql-bin.000003', MASTER_LOG_POS=595"

docker exec ${SLAVE02_NODE} mysql -uroot -proot -e "START SLAVE"

