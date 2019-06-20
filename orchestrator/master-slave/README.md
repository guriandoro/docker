# Orchestrator setup with replication

## Usage.

To start all containers just issue:

`shell> ./make.sh`

This will start the master node, the two slaves, and the orchestrator.

To stop and remove everything, use:

`shell> docker-compose down`

You can change the container versions used in the `.env` file.

The port `3000` will be exposed to a random port in the host, check output of `docker-compose ps` to see which port
was mapped. After that you can create a tunnel to access it locally:

`shell> ssh -L 3000:localhost:3333 user@server`

where port `3333` is the remote port, and `3000` will be the local port. Acces the GUI via browser

`localhost:3000`
