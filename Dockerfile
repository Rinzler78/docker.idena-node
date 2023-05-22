#Download base image ubuntu 16.04
FROM ubuntu:latest

# Install open-ssh server, Wget
RUN apt-get update && apt-get -y upgrade && apt-get install -y apt-utils openssh-server wget curl htop

# Expose idena-nodes ports
EXPOSE 22 40405 9999

# Volume configuration
RUN mkdir /datadir
VOLUME ["/datadir"]

# Create the ssh user
ENV IDENA_USER_ACCOUNT_NAME idenaClient
ENV IDENA_USER_ACCOUNT_PASS idenaClientPassword

# Tools
ENV TOOLS_DIRECTORY /tools

# Update PATH
ENV PATH $TOOLS_DIRECTORY:$PATH

## Tools
RUN mkdir $TOOLS_DIRECTORY
COPY tools/*.* $TOOLS_DIRECTORY/
RUN chmod +x $TOOLS_DIRECTORY/*.sh

# Update distro script
RUN update-dist.sh

# Update script
RUN chmod +x update.sh

# Embed idena node binary
RUN update.sh

#Start
CMD start.sh