#!/bin/bash

if [ -z "$MYSQL_HOST" ]; then
	echo >&2 'Error: MYSQL_HOST needs to be specified.'
	exit 1
fi

MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASS="${MYSQL_PASS:-root}"
MYSQL_DB="${MYSQL_DB:-test}"
MYSQL_PORT="${MYSQL_PORT:-3306}"

OLTP_TEST="${OLTP_TEST:-/usr/share/doc/sysbench/tests/db/oltp.lua}"
OLTP_TABLE_SIZE="${OLTP_TABLE_SIZE:-250000}"
OLTP_TABLES_COUNT="${OLTP_TABLES_COUNT:-1}"

NUM_THREADS="${NUM_THREADS:-1}"
REPORT_INTERVAL="${REPORT_INTERVAL:-1}"
MAX_REQUESTS="${MAX_REQUESTS:-0}"
MAX_TIME="${MAX_TIME:-0}"
TX_RATE="${TX_RATE:-10}"

NO_PREPARE="${NO_PREPARE:-0}"
NO_RUN="${NO_RUN:-0}"

echo ======= Using the following variables =======

echo OLTP_TEST $OLTP_TEST
echo OLTP_TABLE_SIZE $OLTP_TABLE_SIZE
echo OLTP_TABLES_COUNT $OLTP_TABLES_COUNT
echo MYSQL_HOST $MYSQL_HOST
echo MYSQL_USER $MYSQL_USER
echo MYSQL_PASS $MYSQL_PASS
echo MYSQL_DB $MYSQL_DB
echo MYSQL_PORT $MYSQL_PORT
echo NUM_THREADS $NUM_THREADS
echo REPORT_INTERVAL $REPORT_INTERVAL
echo MAX_REQUESTS $MAX_REQUESTS
echo MAX_TIME $MAX_TIME
echo TX_RATE $TX_RATE
echo NO_PREPARE $NO_PREPARE
echo NO_RUN $NO_RUN
  
echo

if [ "$NO_PREPARE" -eq 1 ]; then
  echo Skipping sysbench prepare phase.
else
  echo ======= Executing sysbench [OPTIONS] prepare =======

  sysbench --test=$OLTP_TEST \
  --mysql-host=$MYSQL_HOST \
  --mysql-user=$MYSQL_USER \
  --mysql-password=$MYSQL_PASS \
  --mysql-db=$MYSQL_DB \
  --mysql-port=$MYSQL_PORT \
  --oltp-table-size=$OLTP_TABLE_SIZE \
  --oltp-tables-count=$OLTP_TABLES_COUNT \
  --num-threads=$NUM_THREADS \
  prepare
fi

echo

if [ "$NO_RUN" -eq 1 ]; then
  echo Skipping sysbench run phase.
else
  echo ======= Executing sysbench [OPTIONS] run =======

  sysbench --test=$OLTP_TEST \
  --mysql-host=$MYSQL_HOST \
  --mysql-user=$MYSQL_USER \
  --mysql-password=$MYSQL_PASS \
  --mysql-db=$MYSQL_DB \
  --mysql-port=$MYSQL_PORT \
  --oltp-table-size=$OLTP_TABLE_SIZE  \
  --oltp-tables-count=$OLTP_TABLES_COUNT \
  --num-threads=$NUM_THREADS \
  --report-interval=$REPORT_INTERVAL \
  --max-requests=$MAX_REQUESTS \
  --max-time=$MAX_TIME \
  --tx-rate=$TX_RATE \
  run
fi

exit 0
