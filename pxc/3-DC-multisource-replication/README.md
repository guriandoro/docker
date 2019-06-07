# Percona XtraDB Cluster cluster with three nodes.

## Usage.

To start all 3-node clusters issue:

`shell> ./make_all_clusters.sh up`

This will start all three nodes in all the clusters (clusterA, clusterB and clusterC) and will then generate some scripts for easy access to functionality.

To stop the clusters, and delete everything associated to them (like the docker network and generated scripts), issue:

`shell> ./make_all_clusters.sh down`

And that's it!

The topology being used is the following:

```
    Cluster A       Cluster B       Cluster C
                                
|->  Node 01   <-->  Node 01  <-->   Node 01  <-|
|-----------------------------------------------|
                                        
     Node 02         Node 02         Node 02
                                                                             
     Node 03         Node 03         Node 03
```   

This is: three different PXC clusters in which Node 01, Node 02, and Node 03 are its members; and then multi-source replication between each Node 01 for each Cluster.

