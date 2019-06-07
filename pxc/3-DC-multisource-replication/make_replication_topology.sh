#!/bin/bash

NAME=`whoami`
PWD_MD5=`pwd|md5sum`
NAME="${NAME}.${PWD_MD5:1:6}"

CONTAINER_UNIQUE_NAME=${1:-$NAME}
RUN_MYSQL_COMMAND="run_mysql_"${CONTAINER_UNIQUE_NAME}

echo "--> Create repl users on nodes 01"
./${RUN_MYSQL_COMMAND}_clusterA_node01 -e "CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY 'repl'"
./${RUN_MYSQL_COMMAND}_clusterA_node01 -e "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%'"
./${RUN_MYSQL_COMMAND}_clusterB_node01 -e "CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY 'repl'"
./${RUN_MYSQL_COMMAND}_clusterB_node01 -e "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%'"
./${RUN_MYSQL_COMMAND}_clusterC_node01 -e "CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY 'repl'"
./${RUN_MYSQL_COMMAND}_clusterC_node01 -e "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%'"

echo "--> Check GRANTs on nodes 02"
./${RUN_MYSQL_COMMAND}_clusterA_node01 -e "SHOW MASTER STATUS"
./${RUN_MYSQL_COMMAND}_clusterB_node01 -e "SHOW MASTER STATUS"
./${RUN_MYSQL_COMMAND}_clusterC_node01 -e "SHOW MASTER STATUS"

MYSQLA_MASTER_FILE=`./${RUN_MYSQL_COMMAND}_clusterA_node01 -e "SHOW MASTER STATUS"|grep bin|awk '{print $2}'`
MYSQLA_LOG_POS=`./${RUN_MYSQL_COMMAND}_clusterA_node01 -e "SHOW MASTER STATUS"|grep bin|awk '{print $4}'`
MYSQLB_MASTER_FILE=`./${RUN_MYSQL_COMMAND}_clusterB_node01 -e "SHOW MASTER STATUS"|grep bin|awk '{print $2}'`
MYSQLB_LOG_POS=`./${RUN_MYSQL_COMMAND}_clusterB_node01 -e "SHOW MASTER STATUS"|grep bin|awk '{print $4}'`
MYSQLC_MASTER_FILE=`./${RUN_MYSQL_COMMAND}_clusterC_node01 -e "SHOW MASTER STATUS"|grep bin|awk '{print $2}'`
MYSQLC_LOG_POS=`./${RUN_MYSQL_COMMAND}_clusterC_node01 -e "SHOW MASTER STATUS"|grep bin|awk '{print $4}'`

echo "--> Run CHANGE MASTER TO on nodes 01"
./${RUN_MYSQL_COMMAND}_clusterA_node01 -e "CHANGE MASTER TO master_host='${CONTAINER_UNIQUE_NAME}_clusterB_node01', master_port=3306, master_user='repl', master_password='repl', master_log_file='${MYSQLB_MASTER_FILE}', master_log_pos=${MYSQLB_LOG_POS} FOR CHANNEL 'clstrB'"
./${RUN_MYSQL_COMMAND}_clusterA_node01 -e "CHANGE MASTER TO master_host='${CONTAINER_UNIQUE_NAME}_clusterC_node01', master_port=3306, master_user='repl', master_password='repl', master_log_file='${MYSQLC_MASTER_FILE}', master_log_pos=${MYSQLC_LOG_POS} FOR CHANNEL 'clstrC'"
./${RUN_MYSQL_COMMAND}_clusterB_node01 -e "CHANGE MASTER TO master_host='${CONTAINER_UNIQUE_NAME}_clusterA_node01', master_port=3306, master_user='repl', master_password='repl', master_log_file='${MYSQLA_MASTER_FILE}', master_log_pos=${MYSQLA_LOG_POS} FOR CHANNEL 'clstrA'"
./${RUN_MYSQL_COMMAND}_clusterB_node01 -e "CHANGE MASTER TO master_host='${CONTAINER_UNIQUE_NAME}_clusterC_node01', master_port=3306, master_user='repl', master_password='repl', master_log_file='${MYSQLC_MASTER_FILE}', master_log_pos=${MYSQLC_LOG_POS} FOR CHANNEL 'clstrC'"
./${RUN_MYSQL_COMMAND}_clusterC_node01 -e "CHANGE MASTER TO master_host='${CONTAINER_UNIQUE_NAME}_clusterA_node01', master_port=3306, master_user='repl', master_password='repl', master_log_file='${MYSQLA_MASTER_FILE}', master_log_pos=${MYSQLA_LOG_POS} FOR CHANNEL 'clstrA'"
./${RUN_MYSQL_COMMAND}_clusterC_node01 -e "CHANGE MASTER TO master_host='${CONTAINER_UNIQUE_NAME}_clusterB_node01', master_port=3306, master_user='repl', master_password='repl', master_log_file='${MYSQLB_MASTER_FILE}', master_log_pos=${MYSQLB_LOG_POS} FOR CHANNEL 'clstrB'"

echo "--> Start slave threads on nodes 01"
./${RUN_MYSQL_COMMAND}_clusterA_node01 -e "START SLAVE"
./${RUN_MYSQL_COMMAND}_clusterB_node01 -e "START SLAVE"
./${RUN_MYSQL_COMMAND}_clusterC_node01 -e "START SLAVE"

echo "--> sleeping for 3 seconds"
sleep 3;

echo "--> Stop slaves, reconfigure to use master_auto_position, and restart slave threads"
./${RUN_MYSQL_COMMAND}_clusterA_node01 -e "STOP SLAVE; CHANGE MASTER TO master_auto_position=1 FOR CHANNEL 'clstrB'"
./${RUN_MYSQL_COMMAND}_clusterA_node01 -e "CHANGE MASTER TO master_auto_position=1 FOR CHANNEL 'clstrC'; START SLAVE"
./${RUN_MYSQL_COMMAND}_clusterB_node01 -e "STOP SLAVE; CHANGE MASTER TO master_auto_position=1 FOR CHANNEL 'clstrA'"
./${RUN_MYSQL_COMMAND}_clusterB_node01 -e "CHANGE MASTER TO master_auto_position=1 FOR CHANNEL 'clstrC'; START SLAVE"
./${RUN_MYSQL_COMMAND}_clusterC_node01 -e "STOP SLAVE; CHANGE MASTER TO master_auto_position=1 FOR CHANNEL 'clstrA'"
./${RUN_MYSQL_COMMAND}_clusterC_node01 -e "CHANGE MASTER TO master_auto_position=1 FOR CHANNEL 'clstrB'; START SLAVE"

echo "--> Check SLAVE STATUS on nodes 01"
./${RUN_MYSQL_COMMAND}_clusterA_node01 -e "SHOW SLAVE STATUS\G"
./${RUN_MYSQL_COMMAND}_clusterB_node01 -e "SHOW SLAVE STATUS\G"
./${RUN_MYSQL_COMMAND}_clusterC_node01 -e "SHOW SLAVE STATUS\G"

