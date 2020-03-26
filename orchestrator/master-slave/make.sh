#!/bin/bash

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

function check_mysql_online {
  # arguments: container to run on
  RUN_SCRIPT=${1}
  while [ true ]; do
    echo -n "."
    docker exec ${RUN_SCRIPT} mysqladmin -uroot -proot ping 2>/dev/null | grep "mysqld is alive"
    RUN_SCRIPT_RET=$?
    if [ ${RUN_SCRIPT_RET} -eq 0 ]; then
      break;
    fi
    sleep 1;
  done
  echo
}

if [ "$#" -lt 1 ]; then
  echo "USAGE:"
  echo "- first argument: 'up' or 'down'"
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
ORCHESTRATOR_NODE="orchestrator_${NAME}_orchestrator01"

EXEC_MASTER="docker exec ${MASTER_NODE} mysql -uroot -proot -e "
EXEC_SLAVE01="docker exec ${SLAVE01_NODE} mysql -uroot -proot -e "
EXEC_SLAVE02="docker exec ${SLAVE02_NODE} mysql -uroot -proot -e "

sed -i "s/report-host=\".*\"/report-host=\"${MASTER_NODE}\"/" cnf_files/my.cnf.master
sed -i "s/report-host=\".*\"/report-host=\"${SLAVE01_NODE}\"/" cnf_files/my.cnf.slave01
sed -i "s/report-host=\".*\"/report-host=\"${SLAVE02_NODE}\"/" cnf_files/my.cnf.slave02

docker-compose up -d
#docker-compose up -d --scale orchestrator=3

echo "---> Waiting for master node to be up..."
check_mysql_online ${MASTER_NODE}

echo "---> Creating repl user in master"
${EXEC_MASTER} "CREATE USER 'repl'@'%' IDENTIFIED BY 'repl'" 2>&1 | grep -v "Using a password"
${EXEC_MASTER} "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%'" 2>&1 | grep -v "Using a password"

echo "---> Setting up slaves"

echo "---> Waiting for slave01 to be up..."
check_mysql_online ${SLAVE01_NODE}

${EXEC_SLAVE01} "CHANGE MASTER TO MASTER_HOST='${MASTER_NODE}', \
MASTER_USER='repl', MASTER_PASSWORD='repl', \
MASTER_LOG_FILE='mysql-bin.000003', MASTER_LOG_POS=154" 2>&1 | grep -v "Using a password"

${EXEC_SLAVE01} "START SLAVE" 2>&1 | grep -v "Using a password"

echo "---> Waiting for slave02 to be up..."
check_mysql_online ${SLAVE02_NODE}

${EXEC_SLAVE02} "CHANGE MASTER TO MASTER_HOST='${MASTER_NODE}', \
MASTER_USER='repl', MASTER_PASSWORD='repl', \
MASTER_LOG_FILE='mysql-bin.000003', MASTER_LOG_POS=154" 2>&1 | grep -v "Using a password"

${EXEC_SLAVE02} "START SLAVE" 2>&1 | grep -v "Using a password"

echo "---> Setting up Orchestrator"

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


docker exec -e ORCHESTRATOR_API="http://localhost:3000/api" ${ORCHESTRATOR_NODE} \
  /usr/local/orchestrator/resources/bin/orchestrator-client -c discover -i "${MASTER_NODE}"

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
