#!/bin/bash

echo USAGE:
echo "- first argument: 'up' or 'down'"
echo

UP_OR_DOWN=${1}

function create_script {
# first argument : script name
# second argument: script content
SCRIPT_NAME=${1}
SCRIPT_CONTENT=${2}

# DANGER! will overwrite existing file, if any
echo "#!/bin/bash" > ${SCRIPT_NAME}
echo "" >> ${SCRIPT_NAME}
echo "${SCRIPT_CONTENT}" >>  ${SCRIPT_NAME}
echo "" >> ${SCRIPT_NAME}
}


if [ "$#" -lt 1 ]; then
  echo "ERROR: Specify 'up' or 'down'."
  exit 1
fi

if [ "${UP_OR_DOWN}" != "up" ] && [ "${UP_OR_DOWN}" != "down" ]; then
  echo "ERROR: first argument should be either 'up' or 'down'."
  exit 1
fi


# ------- Set docker-compose project name -------
NAME=`whoami|cut -d '.' -f 1`
#NAME=`whoami`
PWD_MD5=`pwd|md5sum`
NAME="${NAME}.${PWD_MD5:1:6}"

grep -v COMPOSE_PROJECT_NAME .env > .env.swp
echo COMPOSE_PROJECT_NAME=${NAME} >> .env.swp
mv .env.swp .env
# -------

if [ "${UP_OR_DOWN}" == "down" ]; then
  echo "Stopping containers and cleaning up..."
  docker-compose down

  echo "Deleting run_* scripts..."
  rm -f run_bash_* run_mysql_* run_inspect_* run_logs_*

  exit 0
fi

MASTER_NODE="orchestrator_${NAME}_master"
SLAVE01_NODE="orchestrator_${NAME}_slave01"
SLAVE02_NODE="orchestrator_${NAME}_slave02"
ORCHESTRATOR_NODE="orchestrator_${NAME}_orchestrator"

EXEC_MASTER="docker exec ${MASTER_NODE} mysql -uroot -proot -e "
EXEC_SLAVE01="docker exec ${SLAVE01_NODE} mysql -uroot -proot -e "
EXEC_SLAVE02="docker exec ${SLAVE02_NODE} mysql -uroot -proot -e "

sed -i "s/report-host=\".*\"/report-host=\"${MASTER_NODE}\"/" cnf_files/my.cnf.master
sed -i "s/report-host=\".*\"/report-host=\"${SLAVE01_NODE}\"/" cnf_files/my.cnf.slave01
sed -i "s/report-host=\".*\"/report-host=\"${SLAVE02_NODE}\"/" cnf_files/my.cnf.slave02

docker-compose up -d

echo "---> Waiting 30 seconds for nodes to be up..."
sleep 30;

echo "---> Creating repl user in master"
${EXEC_MASTER} "CREATE USER 'repl'@'%' IDENTIFIED BY 'repl'"
${EXEC_MASTER} "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%'"

#${EXEC_MASTER} "show master status"

echo "---> Executing CHANGE MASTER TO"
${EXEC_SLAVE01} "CHANGE MASTER TO MASTER_HOST='${MASTER_NODE}', \
MASTER_USER='repl', MASTER_PASSWORD='repl', \
MASTER_LOG_FILE='mysql-bin.000003', MASTER_LOG_POS=154, MASTER_CONNECT_RETRY=1"

${EXEC_SLAVE01} "START SLAVE"

${EXEC_SLAVE02} "CHANGE MASTER TO MASTER_HOST='${MASTER_NODE}', \
MASTER_USER='repl', MASTER_PASSWORD='repl', \
MASTER_LOG_FILE='mysql-bin.000003', MASTER_LOG_POS=154, MASTER_CONNECT_RETRY=1"

${EXEC_SLAVE02} "START SLAVE"

echo "---> Setting up Orchestrator"
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

docker exec ${ORCHESTRATOR_NODE} /usr/local/orchestrator/orchestrator -c discover -i "${MASTER_NODE}"

echo
echo "Use the following commands to access BASH, MySQL, docker inspect and logs -f on each node:"
echo
for CONTAINER in `docker-compose ps|grep Up|grep -v etcd|grep -v proxysql|awk '{print $1}'`; do
  echo "run_bash_${CONTAINER}"
  create_script run_bash_${CONTAINER} "docker exec -it ${CONTAINER} bash"
  echo "run_mysql_${CONTAINER}"
  create_script run_mysql_${CONTAINER} "docker exec -it ${CONTAINER} mysql -uroot -proot \"\$@\""
  echo "run_inspect_${CONTAINER}"
  create_script run_inspect_${CONTAINER} "docker inspect ${CONTAINER}"
  echo "run_logs_${CONTAINER}"
  create_script run_logs_${CONTAINER} "docker logs -f ${CONTAINER}"
  echo
done;

chmod +x run_*_*
docker-compose ps

exit 0

