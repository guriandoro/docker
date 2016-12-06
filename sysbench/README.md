# Sysbench containers


## Usage.

To use the containers, you can check the README files inside each directory, for information on each of these specifically.

The idea behind this is to make the tests as autonomous and generic as possible, so some default variables are used, like:

mysql_user=root
mysql_password=root
mysql_port=3306

They can all be overriden via environment variables in the `docker run` command.

In future versions, it will be possible to set arguments for the sysbench command in the `docker run` command.
