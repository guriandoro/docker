#!/bin/bash

source ../../common_functions.sh
# Functions used:
#   set_docker_compose_project_name
#   check_mysql_online
#   create_script

UP_OR_DOWN=${1}
MASTER_NODE=${2}

if [ "${UP_OR_DOWN}" != "up" ] && [ "${UP_OR_DOWN}" != "down" ]; then
  echo "ERROR: first argument should be either 'up' or 'down'."
  exit 1
fi

if [ "${UP_OR_DOWN}" == "down" ]; then
  echo "Stopping containers and cleaning up..."
  docker-compose down

  echo "Deleting run_* scripts..."
  rm -f run_bash_* run_mysql_* run_inspect_* run_logs_*

  exit 0
fi


if [ "$#" -lt 2 ]; then
  echo "USAGE:"
  echo "- first argument: 'up' or 'down'"
  echo "- second argument: MySQL master container name"
  exit 1
fi

NAME=$(set_docker_compose_project_name .env)

ORCHESTRATOR_NODE_1="orchestrator_${NAME}_orchestrator_1"
ORCHESTRATOR_NODE_2="orchestrator_${NAME}_orchestrator_2"
ORCHESTRATOR_NODE_3="orchestrator_${NAME}_orchestrator_3"

EXEC_MASTER="docker exec ${MASTER_NODE} mysql -uroot -proot -e "

# Create configuration files for each Orchestrator node
# For now it's hard-coded to three nodes, but we may implement some kind of dynamic way in the future
ORCHESTRATOR_NODES_ARRAY="\"${ORCHESTRATOR_NODE_1}\",\"${ORCHESTRATOR_NODE_2}\",\"${ORCHESTRATOR_NODE_3}\""

for i in 1 2 3; do
  rm cnf_files/orchestrator_$i.cnf 2>/dev/null
  cp cnf_files/orchestrator.cnf cnf_files/orchestrator_$i.cnf
  sed -i "s/RAFT_NODES_ARRAY/${ORCHESTRATOR_NODES_ARRAY}/" cnf_files/orchestrator_$i.cnf
done

sed -i "s/THIS_NODE_IP_ADDRESS/${ORCHESTRATOR_NODE_1}/" cnf_files/orchestrator_1.cnf
sed -i "s/THIS_NODE_IP_ADDRESS/${ORCHESTRATOR_NODE_2}/" cnf_files/orchestrator_2.cnf
sed -i "s/THIS_NODE_IP_ADDRESS/${ORCHESTRATOR_NODE_3}/" cnf_files/orchestrator_3.cnf

docker-compose up -d

echo "---> Waiting for MYSQL master node to be up..."
check_mysql_online ${MASTER_NODE}

echo "---> Setting up Orchestrator on MySQL master node"

${EXEC_MASTER} "CREATE USER 'orcUser'@'%' IDENTIFIED BY 'orcPass1234#'" 2>&1 | grep -v "Using a password"
${EXEC_MASTER} "GRANT SUPER, PROCESS, REPLICATION SLAVE, REPLICATION CLIENT, RELOAD ON *.* TO 'orcUser'@'%'" \
2>&1 | grep -v "Using a password"
${EXEC_MASTER} "GRANT DROP ON _pseudo_gtid_.* to 'orcUser'@'%'" 2>&1 | grep -v "Using a password"
${EXEC_MASTER} "GRANT SELECT ON mysql.slave_master_info TO 'orcUser'@'%'" 2>&1 | grep -v "Using a password"
${EXEC_MASTER} "GRANT SELECT ON meta.* TO 'orcUser'@'%'" 2>&1 | grep -v "Using a password"
${EXEC_MASTER} "CREATE DATABASE meta;" 2>&1 | grep -v "Using a password"
${EXEC_MASTER} "CREATE TABLE IF NOT EXISTS meta.cluster (anchor TINYINT NOT NULL, cluster_name VARCHAR(128) \
CHARSET ascii NOT NULL DEFAULT '', cluster_domain VARCHAR(128) CHARSET ascii NOT NULL DEFAULT '', \
PRIMARY KEY (anchor))" 2>&1 | grep -v "Using a password"
${EXEC_MASTER} "INSERT INTO meta.cluster VALUES (1, 'percona', 'support')" 2>&1 | grep -v "Using a password"

echo "---> Running Orchestrator discovery on MySQL master node"

docker exec -e ORCHESTRATOR_API="http://localhost:3000/api" ${ORCHESTRATOR_NODE_1} \
  /usr/local/orchestrator/resources/bin/orchestrator-client -c discover -i "${MASTER_NODE}"

echo
echo "Use the following commands to access BASH, MySQL, docker inspect and logs -f on each node:"
echo
for CONTAINER in `docker-compose ps|grep Up|grep -v etcd|grep -v proxysql|awk '{print $1}'`; do
  echo "run_bash_${CONTAINER}"
  create_script run_bash_${CONTAINER} "docker exec -it ${CONTAINER} bash"
  echo "run_inspect_${CONTAINER}"
  create_script run_inspect_${CONTAINER} "docker inspect ${CONTAINER}"
  echo "run_logs_${CONTAINER}"
  create_script run_logs_${CONTAINER} "docker logs -f ${CONTAINER}"
  echo
done;

chmod +x run_*_*
docker-compose ps

exit 0
