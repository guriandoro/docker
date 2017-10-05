# Legacy documentation.

Everything that comes below has been deprecated by the new README.md file, and applies for a previous version when only one cluster with N nodes was supported. I will leave it here, because it may be of help when trying to understand how some files were conceived.

## TL;DR

Start the first node, and wait for mysql to start:

```
# docker-compose up node01
```

Start the other nodes. For a 3-node cluster, issue:

```
# docker-compose scale nodeN=2
```

Access the first node:

```
# docker exec -it agustin_N_PXC_pxc_node01 mysql -uroot -proot
```

## Usage.

To use this setup, you just need to edit the variables in the .env file.

You can change the `COMPOSE_PROJECT_NAME` variable to be able to identify the
network and containers created by name, in case you need to do housekeeping
later on (check below on how to remove all created containers, networks
and volumes).

You can also modify the PXC images used by editing the IMAGE and TAG variables in
the .env file. You can find the supported tags for percona/percona-xtradb-cluster
in the following link:

https://hub.docker.com/r/percona/percona-xtradb-cluster/tags/


### Starting the first node:

After you edit the .env file, you have to start the first node:

```
# docker-compose up node01
```

or 

```
# docker-compose up -d node01
```

to spawn the process in the background (in detached mode).

As an alternative to using the -d switch, you can just CTRL-Z at the end of the process,
and use `bg` to leave it as a background job.


### Starting other nodes:

There are two ways in which you can do this, either starting all the nodes you want at once,
or starting them one at a time. Starting them all at once may result in errors due to
timeouts, since -for now- all the new nodes will connect to node01 using its IP address for
CLUSTER_JOIN.

To start 5 nodes at once, issue:

```
# docker-compose scale nodeN=5
```

To start 5 nodes incrementally, issue:

```
# docker-compose scale nodeN=1
... wait for the SST to finish

# docker-compose scale nodeN=2
... wait for the SST to finish
... etcetera

# docker-compose scale nodeN=5
```

You can check cluster size and state, so you know when it's ok to start the other nodes
with:

```
# docker exec -it agustin_N_PXC_pxc_node01 /usr/bin/mysql -uroot -proot -e "SHOW STATUS LIKE 'wsrep_cluster_s%'";
```

You can adjust the total number of running nodes by incrementing or decrementing this scale
argument.

```
# docker-compose up -d node01
Creating network "agustinnpxc_pxc_network" with driver "bridge"
Creating agustin_N_PXC_pxc_node01

# docker-compose scale nodeN=1
Creating and starting agustinnpxc_nodeN_1 ... done

# docker-compose scale nodeN=2
Creating and starting agustinnpxc_nodeN_2 ... done

# docker-compose scale nodeN=3
Creating and starting agustinnpxc_nodeN_3 ... done

# docker-compose scale nodeN=1
Stopping and removing agustinnpxc_nodeN_2 ... done
Stopping and removing agustinnpxc_nodeN_3 ... done

# docker-compose scale nodeN=5
Creating and starting agustinnpxc_nodeN_2 ... done
Creating and starting agustinnpxc_nodeN_3 ... done
Creating and starting agustinnpxc_nodeN_4 ... done
Creating and starting agustinnpxc_nodeN_5 ... done
```

You can check what containers are running via `docker-compose` with:

```
# docker-compose ps
```

To stop and remove all containers, networks and volumes created:

```
# docker-compose down
```


## What if a node fails to start?

If a node refuses to start, you can terminate it via `docker stop <container_name>`. This will be
picked up by `docker-compose`, so you can issue another `docker-compose scale nodeN=N` command to
restart it.

```
# docker stop agustinnpxc_nodeN_2
agustinnpxc_nodeN_2

# docker-compose ps
          Name                 Command       State               Ports             
----------------------------------------------------------------------------------
agustin_N_PXC_pxc_node01   /entrypoint.sh    Up       3306/tcp, 4567/tcp, 4568/tcp 
agustinnpxc_nodeN_1        /entrypoint.sh    Up       3306/tcp, 4567/tcp, 4568/tcp 
agustinnpxc_nodeN_2        /entrypoint.sh    Exit 0                                
agustinnpxc_nodeN_3        /entrypoint.sh    Up       3306/tcp, 4567/tcp, 4568/tcp 
agustinnpxc_nodeN_4        /entrypoint.sh    Up       3306/tcp, 4567/tcp, 4568/tcp 
agustinnpxc_nodeN_5        /entrypoint.sh    Up       3306/tcp, 4567/tcp, 4568/tcp 

# docker-compose scale nodeN=5
Starting agustinnpxc_nodeN_2 ... done
```

Remember you can check the logs for each container with `docker logs <container_name>`.


## All the nodes are up! How can I access them?

Simple enough, you can use `docker exec` to attach to any of them. For instance, to attach to node01:

```
#docker exec -it agustin_N_PXC_pxc_node01 /usr/bin/mysql -uroot -proot
Warning: Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 26
Server version: 5.6.30-76.3-56 Percona XtraDB Cluster (GPL), Release rel76.3, Revision aa929cb, WSREP version 25.16, wsrep_25.16

Copyright (c) 2009-2016 Percona LLC and/or its affiliates
Copyright (c) 2000, 2016, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> quit                                                                                                                                                                     
Bye
```

Or just run bash, and operate from within the container directly:

```
# docker exec -it agustin_N_PXC_pxc_node01 /bin/bash
```
