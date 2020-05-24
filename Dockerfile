#Download base image ubuntu 16.04
FROM ubuntu:latest

# Install open-ssh server, Wget
RUN apt-get update && apt-get -y upgrade && apt-get install -y openssh-server wget curl

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
CMD /startIdena.sh