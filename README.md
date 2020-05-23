# Purpose

This sources allow to create and start dedicated idena-node docker container.

For more informations on the idena project lets go to => https://idena.io/

# DockerFile
## Base container
This container is based on an ubuntu:latest.

## Packages
Following packages are installed : 
 - wget => Allow to download the idena-node binary from github link => https://github.com/idena-network/idena-go/releases
 - openssh-server => Allow client connection to the node through ssh.

## idena-node installation
idena-node binary is downloaded, put at /bin/idena-node and make executable.

## Exposed ports
Following ports are exposed : (https://idena.io/?view=guide#guide-remote-1)
 - 22
 - 40405
 - 9999

## Volumes
datadir directory is created at root directory => /datadir.

It must be linked to directory outside the container.

## Environments variables
 - IDENA_USER_ACCOUNT_NAME : Contains the name of the account that will be created to allow ssh connection.
 - IDENA_USER_ACCOUNT_PASS : Contains the password of the the account.

## Start script
startIdena.sh file is a bash script called at container startup.
It performs following actions : 
 - Create the ssh user IDENA_USER_ACCOUNT_NAME (With IDENA_USER_ACCOUNT_PASS password) if its not exists.
 - Create config.json file in /datadir, if not exist.
 - Start ssh service, to allow connection through ssh.
 - Start idena-node binary

# Build instruction
docker build -t idena-node . 

# Before run
## Api.key
Create a directory on your docker host to be linked to the container datadir. Exemple : ~/MyDockers/idena-node/datadir

Copy your api.key into the datadir directory. Exemple : ~/MyDockers/idena-node/datadir/api.key
## Config.json

# Run instructions
docker run -d \
-p {SshPort}:22 \
-p 40405:40405 \
-p 9999:9999 \
-v {Your directory}:/datadir \
-e IDENA_USER_ACCOUNT_NAME={User Account} \
-e IDENA_USER_ACCOUNT_PASS={User Account Password} \
--name idena-node idena-node

-- {SshPort} => SSH port to open

-- {Your directory} => Your datadir directory on the docker host

-- {User Account} => The ssh user account used to connect client to node

-- {User Account Password} => The ssh user account password.

# Docker public container
Public container is available at https://hub.docker.com/repository/docker/rinzlerfr/idena-node
