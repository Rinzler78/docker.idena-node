# ── Stage 1 : fetch and strip the idena-node binary ──────────────────────────
FROM ubuntu:22.04 AS binary-fetcher
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
        binutils \
        curl \
        jq \
        ca-certificates && \
    update-ca-certificates --fresh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /tools
COPY tools/update.sh tools/version.locale.sh tools/version.remote.sh tools/url.releases.txt /tools/
RUN chmod +x /tools/*.sh
# Download the idena-node binary and strip debug symbols to reduce size
RUN /tools/update.sh && strip --strip-all /bin/idena-node

# ── Stage 2 : runtime image ───────────────────────────────────────────────────
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Arguments for build-time configuration
# IMPORTANT: These are default values. Override them at runtime for production.
# DO NOT use default passwords in production environments.
ARG IDENA_USER_ACCOUNT_NAME=idenaClient
ARG IDENA_USER_ACCOUNT_PASS=idenaClientPassword
ENV IDENA_USER_ACCOUNT_NAME=${IDENA_USER_ACCOUNT_NAME}
ENV RUN_TIMEOUT=86400
ENV PATH=/tools:$PATH

# Install runtime dependencies and clean up apt cache to reduce image size
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
        openssh-server \
        curl \
        jq \
        ca-certificates && \
    update-ca-certificates --fresh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create directories for data and tools
RUN mkdir /datadir && mkdir /tools
VOLUME ["/datadir"]

# Copy stripped binary from build stage
COPY --from=binary-fetcher /bin/idena-node /bin/idena-node

# Copy tools and set permissions
COPY tools/*.* /tools/
RUN chmod +x /tools/*.sh

# Apply system package updates during image build for deterministic startups
RUN /tools/update-dist.sh

# Expose fixed container ports. Host-side ports remain configurable through
# docker run or docker compose port mappings.
EXPOSE 22 40405 9009

HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=12 \
  CMD bash -c '</dev/tcp/localhost/22 && </dev/tcp/localhost/9009'

CMD ["/tools/start.sh"]
