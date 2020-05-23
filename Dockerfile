#Download base image ubuntu 16.04
FROM ubuntu:latest

# Update Ubuntu Software repository
RUN apt-get update

# Install open-ssh server, Wget
RUN apt-get install -y openssh-server wget

# Download idena-node
ARG IDENA_NODE_BIN_URL=https://github.com/idena-network/idena-go/releases/download/v0.20.0/idena-node-linux-0.20.0
RUN wget --output-document=idena-node ${IDENA_NODE_BIN_URL}
RUN mv idena-node /bin/idena-node
RUN chmod +x /bin/idena-node

# Expose idena-nodes ports
EXPOSE 22 40405 9999

# Volume configuration
RUN mkdir /datadir
VOLUME ["/datadir"]

# Create the ssh user
ENV IDENA_USER_ACCOUNT_NAME idenaClient
ENV IDENA_USER_ACCOUNT_PASS idenaClientPassword

# Start script
COPY startIdena.sh /startIdena.sh
RUN chmod +x /startIdena.sh

#Start
#CMD idena-node --config=/datadir/config.json
CMD /startIdena.sh
#CMD /bin/bash
