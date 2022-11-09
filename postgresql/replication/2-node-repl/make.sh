#!/bin/bash
echo USAGE:
echo "- first argument: 'up' or 'down'"
#echo "- second argument: "
echo 

source .env

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

echo "Setting COMPOSE_PROJECT_NAME in .env file..."
echo


NAME=`whoami|cut -d '.' -f 1`
PWD_MD5=`pwd|md5sum`
NAME="${NAME}.${PWD_MD5:1:6}"

grep -v COMPOSE_PROJECT_NAME .env > .env.swp
echo COMPOSE_PROJECT_NAME=${NAME} >> .env.swp
mv .env.swp .env

echo "PROJECT NAME: ${NAME}"

INIT_NODE_WAIT_TIME=30
SECONDARY_NODE_WAIT_TIME=15

if [ "${UP_OR_DOWN}" == "up" ]; then
  docker-compose up -d

  echo
  echo "Use the following commands to access BASH and PostgreSQL on each node:"
  echo 
  for CONTAINER in `docker-compose ps|grep Up|awk '{print $1}'`; do
    echo "run_bash_${CONTAINER}"
    create_script run_bash_${CONTAINER} "docker exec -it ${CONTAINER} bash"
    echo "run_psql_${CONTAINER}"
    create_script run_mysql_${CONTAINER} "docker exec -it ${CONTAINER} psql -upostgres \"\$@\""
    echo
  done;

  chmod +x ./run_*
  docker-compose ps

else 
  if [ "${UP_OR_DOWN}" == "down" ]; then
    echo "Stopping containers and cleaning up..."
    docker-compose down

    echo "Deleting run_* scripts..."
    rm -f ./run_*
  fi
fi

exit 0
