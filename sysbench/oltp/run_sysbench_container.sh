#!/bin/bash

if [ -z "$MYSQL_HOST" ]; then
	echo >&2 'Error: MYSQL_HOST needs to be specified.'
	exit 1
fi

echo 'This is a sample on how to run the container with minimal arguments.'
echo 'Other variables can be set, check /entrypoint.sh on the container for more on this.'
echo

docker run -d --name agustin-sysbench \
-e MYSQL_HOST=$MYSQL_HOST \
guriandoro/sysbench:0.5-6 /entrypoint.sh

