# Sysbench containers


## Usage.

To use the containers, you can check the README files inside each directory, for information on each of these specifically.

The idea behind this is to make the tests as autonomous and generic as possible, so some default variables are used, like:

```
mysql_user=root
mysql_password=root
mysql_port=3306
```

They can all be overridden via environment variables in the `docker run` command, like:

```
docker run -d --name=agustin-sysbench \
...
-e MYSQL_HOST=172.29.0.2 \
-e MYSQL_USER=msandbox \
-e MYSQL_PASSWORD=msandbox \
...
```
To see a full list of variables, check the entrypoint.sh file, or each container's documentation (disclaimer: may be incomplete).
