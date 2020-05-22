#Download base image ubuntu 16.04
FROM ubuntu:latest

# Update Ubuntu Software repository
RUN apt-get update
#RUN apt-get -y upgrade

# Install open-ssh server
RUN apt-get install -y openssh-server

# Install wget
RUN apt-get install -y wget

# Download idena-node
ARG IDENA_NODE_BIN_URL=https://github.com/idena-network/idena-go/releases/download/v0.20.0/idena-node-linux-0.20.0
RUN wget --output-document=idena-node ${IDENA_NODE_BIN_URL}
RUN mv idena-node /bin/idena-node

# Expose idena-nodes ports
EXPOSE 22 40405 9999

# Volume configuration
RUN mkdir /datadir
VOLUME ["/datadir"]
COPY config.json /datadir/config.json
