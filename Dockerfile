#Download base image ubuntu 16.04
FROM ubuntu:latest

# Install open-ssh server, Wget
RUN apt-get update && apt-get -y upgrade && apt-get install -y openssh-server wget curl htop

# Expose idena-nodes ports
EXPOSE 22 40405 9999

# Volume configuration
RUN mkdir /datadir
VOLUME ["/datadir"]

# Create the ssh user
ENV IDENA_USER_ACCOUNT_NAME idenaClient
ENV IDENA_USER_ACCOUNT_PASS idenaClientPassword

# Update distro script
COPY update-dist.sh /update-dist.sh
RUN chmod +x /update-dist.sh

# Update script
COPY update.sh /update.sh
RUN chmod +x /update.sh

# Start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

#Start
CMD /start.sh