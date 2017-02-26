# docker

## Docker and Compose versions.

These setups use version 2 for the docker-compose.yml file, so Docker 1.10.0+ and Compose 1.6.0+ are needed.

https://docs.docker.com/compose/compose-file/#/version-2

Tested on Docker version 1.12.1 and docker-compose versions 1.8.0 and 1.9.0.

Feel free to comment if you are getting errors, or if things are not working as expected.

## Using the Dockerfile to build your own image

You can use the Dockerfiles provided here to create your own images. It can be useful if you have modified the entrypoint.sh file, for instance, or even if you want to build a container to upload to your own repo. You can follow these 3 steps to do so:

1- Build the image:
```
cd /path/to/.../docker/sysbench/oltp/
docker build -t <user_name>/<container_name>:<version/tag> .
```
E.g.: `docker build -t guriandoro/sysbench:0.5-6.1 .`

2- Login with your Docker Hub account:
```
docker login 
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: guriandoro
Password: 
Login Succeeded
```

3- Upload the image
```
docker push guriandoro/sysbench:0.5-6.1
```

4- Optionally, logout from your Docker Hub (especially if it's a shared server):
```
docker logout
```
