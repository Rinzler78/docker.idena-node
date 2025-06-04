# Use Ubuntu latest (update comment)
FROM ubuntu:latest

# Install open-ssh server, Wget, Curl, Htop
RUN apt-get update && apt-get -y upgrade && apt-get install -y apt-utils openssh-server wget curl htop

# Expose idena-node ports
EXPOSE 22 40405 9999

# Volume configuration
RUN mkdir /datadir
VOLUME ["/datadir"]

# Arguments for build-time configuration (not recommended for secrets)
ARG IDENA_USER_ACCOUNT_NAME=idenaClient
ARG IDENA_USER_ACCOUNT_PASS=idenaClientPassword

# Environment variables (prefer to override at runtime for secrets)
ENV IDENA_USER_ACCOUNT_NAME=${IDENA_USER_ACCOUNT_NAME}
ENV IDENA_USER_ACCOUNT_PASS=${IDENA_USER_ACCOUNT_PASS}

# Running timeout : Default 24H
ENV RUN_TIMEOUT 86400

# Update PATH
ENV PATH /tools:$PATH

# Tools
RUN mkdir /tools
COPY tools/*.* /tools/
RUN chmod +x /tools/*.sh

# Embed idena node binary
RUN update.sh

# Healthcheck for SSH service (pure bash, no netcat required)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD bash -c '</dev/tcp/localhost/22' || exit 1

# Start
CMD start.sh