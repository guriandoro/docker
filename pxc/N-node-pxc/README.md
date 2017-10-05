# Percona XtraDB Cluster cluster(s) with dynamically variable nodes.

## Usage.

The recommended way of managing this docker-compose setup is via `./make_docker_clusters-N-nodes-pxc.sh`. There are three ways in which it can be called:

- Create one cluster with N nodes

```
./make_docker_clusters-N-nodes-pxc.sh up N
```
where N >= 0 (although there are no parameter checks yet, so be careful :))

- Create two clusters. One with N nodes, and the other with M nodes

```
./make_docker_clusters-N-nodes-pxc.sh up N M
```
where N and M >= 0 (again, no parameter checks yet). These two clusters will share the same docker network, so they can be used to test things like async replication between two different clusters.

- Stop the clusters, and delete associated resources

```
./make_docker_clusters-N-nodes-pxc.sh down
```

Container versions (and their underlying Percona XtraDB Cluster versions) used can be tuned via the `.env` file. Only one version is supported for use in all nodes. If needed, one can manually edit the `docker-compose.yml` file to change them, although it's not recommended to mix versions.

The script tries to use a compose project name that is descriptive of the user that started it (mainly for usage in shared testing servers), and a unique string, to avoid name collisions. Feel free to edit how this is done, if it doesn't suit your needs:

```
NAME=`whoami`
PWD_MD5=`pwd|md5sum`
NAME="${NAME}.${PWD_MD5:1:6}"
```

Lastly, the tool creates some scripts that are useful for quick access to functionality for each node like:
- bash access
- mysql client access
- container log outputs
- container inspect command
