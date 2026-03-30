# Use a specific Ubuntu LTS version for reproducibility
FROM ubuntu:22.04

# Set DEBIAN_FRONTEND to noninteractive to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies: open-ssh server, wget, curl, and apt-utils
# Combine RUN instructions and clean up apt cache to reduce image size
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
        apt-utils \
        openssh-server \
        wget \
        curl \
        jq \
        ca-certificates && \
    update-ca-certificates --fresh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create directories for data and tools
RUN mkdir /datadir && mkdir /tools

# Volume configuration
VOLUME ["/datadir"]

# Arguments for build-time configuration
# IMPORTANT: These are default values. Override them at runtime for production.
# DO NOT use default passwords in production environments.
ARG IDENA_USER_ACCOUNT_NAME=idenaClient
ARG IDENA_USER_ACCOUNT_PASS=idenaClientPassword
ARG IDENA_SSH_EXPOSE_PORT=22
ARG IDENA_P2P_EXPOSE_PORT=40405
ARG IDENA_API_EXPOSE_PORT=9009

# Environment variables
# IDENA_USER_ACCOUNT_NAME will be taken from the ARG passed during build or its default.
ENV IDENA_USER_ACCOUNT_NAME=${IDENA_USER_ACCOUNT_NAME}
ENV RUN_TIMEOUT=86400
# Add tools directory to PATH
ENV PATH=/tools:$PATH

# Copy tools and set permissions
COPY tools/*.* /tools/
RUN chmod +x /tools/*.sh

# Apply system package updates during image build for deterministic startups
RUN /tools/update-dist.sh

# Embed idena node binary (ensure update.sh handles permissions if needed or run as root before switching user)
# If update.sh needs root, run it before USER ${APP_USER_NAME}
RUN /tools/update.sh

# Expose container ports as image metadata. Host-side ports remain configurable
# through docker run or docker compose port mappings.
EXPOSE ${IDENA_SSH_EXPOSE_PORT} ${IDENA_P2P_EXPOSE_PORT} ${IDENA_API_EXPOSE_PORT}

# Healthcheck for SSH service (will run as root)
HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=12 \
  CMD bash -c '</dev/tcp/localhost/22'

# Start command (will run as root, start.sh handles user creation if needed)
CMD ["/tools/start.sh"]
