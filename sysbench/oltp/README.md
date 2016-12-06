## Usage.

If you have a container running mysql, you will need to check on what network it is, and what IP address it has assigned.
You can do so with the following command:

```
# docker inspect agustin_N_PXC_pxc_node01
...
            "Networks": {
                "agustinnpxc_pxc_network": {
                    "IPAMConfig": {
                        "IPv4Address": "172.29.0.2"
                    },
...
```

Then, you can run this container like:

```
# docker run -d --name agustin-sysbench \
--network=agustinnpxc_pxc_network \
-e MYSQL_HOST=172.29.0.2 \
guriandoro/sysbench:0.5-6 /entrypoint.sh
```

If you are using the default network, you can ommit the `--network` argument.

## Checking its status

You can use `docker logs -f <container_name>` to check on its status. You should see something like the following, if successful:

```
# docker logs -f agustin-sysbench
======= Using the following variables =======
OLTP_TEST /usr/share/doc/sysbench/tests/db/oltp.lua
OLTP_TABLE_SIZE 250000
MYSQL_HOST 172.29.0.2
MYSQL_USER root
MYSQL_PASS root
MYSQL_DB test
REPORT_INTERVAL 1
MAX_REQUESTS 0
TX_RATE 10

======= Executing sysbench [OPTIONS] prepare =======
sysbench 0.5:  multi-threaded system evaluation benchmark

Creating table 'sbtest1'...
Inserting 250000 records into 'sbtest1'

======= Executing sysbench [OPTIONS] run =======


[   1s] threads: 1, tps: 11.00, reads: 153.98, writes: 44.00, response time: 13.01ms (95%), errors: 0.00, reconnects:  0.00
[   2s] threads: 1, tps: 17.00, reads: 238.00, writes: 68.00, response time: 10.68ms (95%), errors: 0.00, reconnects:  0.00
[   3s] threads: 1, tps: 10.00, reads: 140.00, writes: 40.00, response time: 14.42ms (95%), errors: 0.00, reconnects:  0.00
[   4s] threads: 1, tps: 12.00, reads: 168.01, writes: 48.00, response time: 10.69ms (95%), errors: 0.00, reconnects:  0.00
[   5s] threads: 1, tps: 9.00, reads: 126.00, writes: 36.00, response time: 12.60ms (95%), errors: 0.00, reconnects:  0.00
```

You can get error messages if you don't set any of the variables to what they should be, like:

```
======= Executing sysbench [OPTIONS] prepare =======
sysbench 0.5:  multi-threaded system evaluation benchmark

FATAL: unable to connect to MySQL server, aborting...
FATAL: error 1045: Access denied for user 'noroot'@'172.29.0.3' (using password: YES)
FATAL: failed to execute function `prepare': /usr/share/doc/sysbench/tests/db/common.lua:103: Failed to connect to the database

======= Executing sysbench [OPTIONS] run =======
PANIC: unprotected error in call to Lua API (Failed to connect to the database)
```
