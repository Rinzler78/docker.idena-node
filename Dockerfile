# Use a specific Ubuntu LTS version for reproducibility
FROM ubuntu:22.04

# Set DEBIAN_FRONTEND to noninteractive to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies: open-ssh server, Wget, Curl, Htop, and apt-utils
# Combine RUN instructions and clean up apt cache to reduce image size
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
        apt-utils \
        openssh-server \
        wget \
        curl \
        htop \
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
# IMPORTANT: These are default values. Override them at build time for production.
# DO NOT use default passwords in production environments.
ARG IDENA_USER_ACCOUNT_NAME=idenaClient
ARG IDENA_USER_ACCOUNT_PASS=idenaClientPassword

# Environment variables
# IDENA_USER_ACCOUNT_NAME will be taken from the ARG passed during build or its default.
ENV IDENA_USER_ACCOUNT_NAME=${IDENA_USER_ACCOUNT_NAME}
# Note: Storing passwords in ENV variables is not ideal for production.
# Consider using Docker secrets or injecting them at runtime.
ENV IDENA_USER_ACCOUNT_PASS=${IDENA_USER_ACCOUNT_PASS}
ENV RUN_TIMEOUT=86400
# Add tools directory to PATH
ENV PATH=/tools:$PATH

# Copy tools and set permissions
COPY tools/*.* /tools/
RUN chmod +x /tools/*.sh

# Diagnostic before update.sh (optional, consider removing for production image)
RUN ls -l /tools && ls -l /bin && echo "PATH=$PATH"

# Embed idena node binary (ensure update.sh handles permissions if needed or run as root before switching user)
# If update.sh needs root, run it before USER ${APP_USER_NAME}
RUN /tools/update.sh

# Expose idena-node ports and SSH port
EXPOSE 22 40405 9999

# Healthcheck for SSH service (will run as root)
HEALTHCHECK --interval=1s --timeout=1s --start-period=1s --retries=60 \
  CMD bash -c '</dev/tcp/localhost/22 && curl --fail http://localhost:9009/ || exit 1'

# Start command (will run as root, start.sh handles user creation if needed)
CMD ["/tools/start.sh"]