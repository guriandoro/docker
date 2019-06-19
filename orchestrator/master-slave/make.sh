#!/bin/bash

MASTER_NODE='orchestrator_master'
SLAVE01_NODE='orchestrator_slave01'
SLAVE02_NODE='orchestrator_slave02'
ORCHESTRATOR_NODE='orchestrator_orchestrator'

EXEC_MASTER="docker exec ${MASTER_NODE} mysql -uroot -proot -e "
EXEC_SLAVE01="docker exec ${SLAVE01_NODE} mysql -uroot -proot -e "
EXEC_SLAVE02="docker exec ${SLAVE02_NODE} mysql -uroot -proot -e "

docker-compose up -d

echo "---> Waiting 10 seconds for nodes to be up..."
sleep 10;

${EXEC_MASTER} "CREATE USER 'repl'@'%' IDENTIFIED BY 'repl'"
${EXEC_MASTER} "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%'"

#${EXEC_MASTER} "show master status"

${EXEC_SLAVE01} "CHANGE MASTER TO MASTER_HOST='${MASTER_NODE}', \
MASTER_USER='repl', MASTER_PASSWORD='repl', \
MASTER_LOG_FILE='mysql-bin.000003', MASTER_LOG_POS=595, MASTER_CONNECT_RETRY=1"

${EXEC_SLAVE01} "START SLAVE"

${EXEC_SLAVE02} "CHANGE MASTER TO MASTER_HOST='${MASTER_NODE}', \
MASTER_USER='repl', MASTER_PASSWORD='repl', \
MASTER_LOG_FILE='mysql-bin.000003', MASTER_LOG_POS=595, MASTER_CONNECT_RETRY=1"

${EXEC_SLAVE02} "START SLAVE"

${EXEC_MASTER} "CREATE USER 'orcUser'@'%' IDENTIFIED BY 'orcPass1234#'"
${EXEC_MASTER} "GRANT SUPER, PROCESS, REPLICATION SLAVE, REPLICATION CLIENT, RELOAD ON *.* TO 'orcUser'@'%'"
${EXEC_MASTER} "GRANT DROP ON _pseudo_gtid_.* to 'orcUser'@'%'"
${EXEC_MASTER} "GRANT SELECT ON mysql.slave_master_info TO 'orcUser'@'%'"
${EXEC_MASTER} "GRANT SELECT ON meta.* TO 'orcUser'@'%'"
${EXEC_MASTER} "CREATE DATABASE meta;"
${EXEC_MASTER} "CREATE TABLE IF NOT EXISTS meta.cluster (anchor TINYINT NOT NULL, cluster_name VARCHAR(128) \
CHARSET ascii NOT NULL DEFAULT '', cluster_domain VARCHAR(128) CHARSET ascii NOT NULL DEFAULT '', \
PRIMARY KEY (anchor))"
${EXEC_MASTER} "INSERT INTO meta.cluster VALUES (1, 'percona', 'support')"

docker exec ${ORCHESTRATOR_NODE} orchestrator -c discover -i "${MASTER_NODE}"

docker-compose ps

