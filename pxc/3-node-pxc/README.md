# Percona XtraDB Cluster cluster with three nodes.

To use this setup, you just need to edit the variables in the .env file.
You can choose the network and each nodes' IP address within it.

You can change the COMPOSE_PROJECT_NAME variable to be able to identify the
network and containers created by name, in case you need to do housekeeping
later on (check below on how to remove all created containers, networks
and volumes).

You can also modify the PXC container versions by using the PXC_TAG variable.
You can find the supported tags in the following link:

https://hub.docker.com/r/percona/percona-xtradb-cluster/tags/

In future versions, we will support setting other container images.

After you edit the .env file, you can start the cluster by simply running:

```
# docker-compose up
```

or 

```
# docker-compose up -d
```

to spawn the process in the background (in detached mode).

As an alternative to using the -d switch, you can just CTRL-Z at the end of the process,
and use `bg` to leave it as a background job.

You can check what containers are
running via `docker-compose` with:

```
# docker-compose ps
```

To remove all containers, networks and volumes created:

```
# docker-compose down
```

## What if a node fails to start?

You may see something like the following in some cases:

```
agustin_pxc_node02 | MySQL init process in progress...
agustin_pxc_node02 | MySQL init process failed.
agustin_pxc_node03 | MySQL init process in progress...
agustin_pxc_node02 exited with code 1
agustin_pxc_node03 | MySQL init process failed.
agustin_pxc_node03 exited with code 1
```

In which case you can just remove the offending containers with:

```
# docker rm agustin_pxc_node02 agustin_pxc_node03
```

And then start them again one by one:

```
# docker-compose up node02

# docker-compose up node03
```


## All the nodes are up! How can I access them?

Simple enough, you can use `docker exec` to attach to any of them. For instance, to attach to node01:

```
# docker exec -it agustin_pxc_node01 /usr/bin/mysql -uroot -proot
Warning: Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 8
Server version: 5.6.30-76.3-56 Percona XtraDB Cluster (GPL), Release rel76.3, Revision aa929cb, WSREP version 25.16, wsrep_25.16

Copyright (c) 2009-2016 Percona LLC and/or its affiliates
Copyright (c) 2000, 2016, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show status like 'wsrep_cluster_s%';                                                                                                                                     
+--------------------------+--------------------------------------+
| Variable_name            | Value                                |
+--------------------------+--------------------------------------+
| wsrep_cluster_size       | 3                                    |
| wsrep_cluster_state_uuid | 4fece3cf-9d50-11e6-aa91-ba420bf4c1c1 |
| wsrep_cluster_status     | Primary                              |
+--------------------------+--------------------------------------+
3 rows in set (0.00 sec)

mysql> quit
Bye
```

Or just run bash, and operate from within the container directly:

```
docker exec -it agustin_pxc_node01 /bin/bash
```
