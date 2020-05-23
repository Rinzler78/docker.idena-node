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
 - IDENA_USER_ACCOUNT_NAME : Contains account name that will be created to allow ssh connection.
 - IDENA_USER_ACCOUNT_PASS : Contains the acccount password.

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
## datadir directory
Create a directory on your docker host to be linked to the container datadir. Exemple : ~/MyDockers/idena-node/datadir

## Api.key
Copy your api.key into the datadir directory. Exemple : ~/MyDockers/idena-node/datadir/api.key

## Existing node datas
In case your allready using idena-node (locally or in a VPS), and you want to use the docker, just copy all files and directories from your current datadir to the datadir created on your docker host.

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

Exemple : 
docker run -d \
-p 60022:22 \
-p 40405:40405 \
-p 9999:9999 \
-v docker/idena-node/datadir:/datadir \
-e IDENA_USER_ACCOUNT_NAME=idenaUser \
-e IDENA_USER_ACCOUNT_PASS=idenaUserPassword \
--name idena-node idena-node

# Docker public container
Public container is available at https://hub.docker.com/repository/docker/rinzlerfr/idena-node

# Synology idena-node docker installation
## Install docker
if not installed, go to the package center, search docker and install it.

## Search idena-node image
Go to docker GUI and search "rinzlerfr/idena-node" in the register page.
Once found download it.

## Create datadir directory
Using File station, create a directory on your syno to link to the container datadir. Exemple : docker/idena-node/datadir

## Api.key
Copy your api.key into the datadir directory. Exemple : docker/idena-node/datadir/api.key

## Existing node datas
In case your allready using idena-node (locally or in a VPS), and you want to use the docker, just copy all files and directories, from your current datadir, to the datadir created on your syno.

## Configure image and start container
Back to docker GUI, in Images. Select the "rinzlerfr/idena-node" image, and click launch.
- Give a name to your container. Exemple : idena-node
- Enable resources limitation : 
-- Put processor priority to high.
-- Put 1024 MB limitation
- Click to advanced parameters
- Enable auto restart.

- Go to Volume, click Add directory, select the datadir directory created on your syno. Exemple : docker/idena-node/datadir
-- Then put /datadir on the rigth and validate

- Go to ports configuration
-- On the first line, replace Auto by the port number your want to redirect to the 22 (ssh). Exemple : 60022
-- On the second line, replace Auto by 40405.
-- On the third line, replace Auto by 9999.

- Go to the environment tab
-- Replace idenaClient by the desired account name that will be create.
-- Replace idenaClientPassword by the desired password of the account.

Then validate and launch the container.

Hav fun !! ;)

