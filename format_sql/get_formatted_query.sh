#!/bin/bash
# This is a simple wrapper for docker, call like:
# ./get_formatted_query.sh "SELECT 1 FROM DUAL;"

docker run --rm \
  --name=temp_sql_format_container \
  --network=none \
  guriandoro/sqlparse:0.3.1 "$@"

