#!/bin/bash
echo USAGE:
echo "- first argument: 'up' or 'down'"
echo 

UP_OR_DOWN=${1}
PROXY_UP=${2}

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
  echo "ERROR: argument should be either 'up' or 'down'."
  exit 1
fi

echo "--> Setting COMPOSE_PROJECT_NAME in .env file..."
echo


NAME=`whoami`
PWD_MD5=`pwd|md5sum`
NAME="${NAME}.${PWD_MD5:1:6}"

grep -v COMPOSE_PROJECT_NAME .env > .env.swp
echo COMPOSE_PROJECT_NAME=${NAME} >> .env.swp
mv .env.swp .env

echo "PROJECT NAME: ${NAME}"

INIT_NODE_WAIT_TIME=5
SECONDARY_NODE_WAIT_TIME=5

if [ "${UP_OR_DOWN}" == "up" ]; then
  docker-compose up -d etcd_node
  sleep 5;

  docker-compose up -d clusterA_node01
  docker-compose up -d clusterB_node01
  docker-compose up -d clusterC_node01
  echo "--> Waiting ${INIT_NODE_WAIT_TIME} seconds for first nodes to be up..."
  sleep ${INIT_NODE_WAIT_TIME};

  docker-compose up -d clusterA_node02
  docker-compose up -d clusterB_node02
  docker-compose up -d clusterC_node02
  echo "--> Waiting ${SECONDARY_NODE_WAIT_TIME} seconds for second nodes to be up..."
  sleep ${SECONDARY_NODE_WAIT_TIME};

  docker-compose up -d clusterA_node03
  docker-compose up -d clusterB_node03
  docker-compose up -d clusterC_node03
  echo "--> Waiting ${SECONDARY_NODE_WAIT_TIME} seconds for third nodes to be up..."
  sleep ${SECONDARY_NODE_WAIT_TIME};

  echo
  echo "Use the following commands to access BASH, MySQL, docker inspect and logs -f on each node:"
  echo 
  for CONTAINER in `docker-compose ps|grep Up|grep -v etcd|grep -v proxysql|awk '{print $1}'`; do
    echo "run_bash_${CONTAINER}"
    create_script run_bash_${CONTAINER} "docker exec -it ${CONTAINER} bash"
    echo "run_mysql_${CONTAINER}"
    create_script run_mysql_${CONTAINER} "docker exec -it ${CONTAINER} mysql -uroot -proot \"\$@\""
    #echo "run_inspect_${CONTAINER}"
    #create_script run_inspect_${CONTAINER} "docker inspect ${CONTAINER}"
    #echo "run_logs_${CONTAINER}"
    #create_script run_logs_${CONTAINER} "docker logs -f ${CONTAINER}"
    echo
  done;

  chmod +x run_*_*
  docker-compose ps

  echo
  echo "--> RUNNING REPLICATION SETUP SCRIPT"
  ./make_replication_topology.sh agustin.gallego.8a3057

else 
  if [ "${UP_OR_DOWN}" == "down" ]; then
    echo "--> Stopping containers and cleaning up..."
    docker-compose down

    echo "--> Deleting run_* scripts..."
    rm -f run_bash_* run_mysql_* run_inspect_* run_logs_*
  fi
fi

exit 0

