#!/bin/bash

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
  # arguments: container to run on, username and pass for mysql
  CONTAINER_NAME=${1}
  MYSQL_USERNAME=${2}
  MYSQL_PASSWORD=${3}
  while [ true ]; do
    echo -n "."
    docker exec ${CONTAINER_NAME} mysqladmin -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} ping 2>/dev/null | grep "mysqld is alive"
    RUN_SCRIPT_RET=$?
    if [ ${RUN_SCRIPT_RET} -eq 0 ]; then
      break;
    fi
    sleep 1;
  done
  echo
}

