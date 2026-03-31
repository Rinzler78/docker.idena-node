# ── Stage 1 : fetch and strip the idena-node binary ──────────────────────────
FROM debian:bullseye-slim AS binary-fetcher
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        binutils \
        upx-ucl \
        wget \
        jq \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* \
           /usr/share/doc/* \
           /usr/share/man/*

RUN mkdir /tools
COPY tools/update.sh tools/version.locale.sh tools/version.remote.sh tools/url.releases.txt /tools/
RUN chmod +x /tools/*.sh
# Download, strip debug symbols, then compress with UPX (-1 = fast, ~44% ratio)
RUN /tools/update.sh && strip --strip-all /bin/idena-node && upx -7 /bin/idena-node

# ── Stage 2 : glibc provider (source des .so) ────────────────────────────────
FROM debian:bookworm-slim AS glibc-provider

# ── Stage 3 : runtime Alpine ──────────────────────────────────────────────────
FROM alpine:latest
ENV PATH=/tools:$PATH

# Arguments for build-time configuration
# IMPORTANT: These are default values. Override them at runtime for production.
# DO NOT use default passwords in production environments.
ARG IDENA_USER_ACCOUNT_NAME=idenaClient
ARG IDENA_USER_ACCOUNT_PASS=idenaClientPassword
ENV IDENA_USER_ACCOUNT_NAME=${IDENA_USER_ACCOUNT_NAME}
ENV RUN_TIMEOUT=86400

# Installer les dépendances runtime Alpine
RUN apk add --no-cache \
        dropbear \
        jq \
        ca-certificates && \
    rm -rf /usr/share/doc/* \
           /usr/share/man/* \
           /usr/share/locale/*

# Copier les librairies glibc depuis Debian (nécessaires pour le binaire idena-node)
COPY --from=glibc-provider /lib/x86_64-linux-gnu/libc.so.6            /lib/x86_64-linux-gnu/
COPY --from=glibc-provider /lib/x86_64-linux-gnu/libm.so.6            /lib/x86_64-linux-gnu/
COPY --from=glibc-provider /lib/x86_64-linux-gnu/libpthread.so.0      /lib/x86_64-linux-gnu/
COPY --from=glibc-provider /lib/x86_64-linux-gnu/libdl.so.2           /lib/x86_64-linux-gnu/
COPY --from=glibc-provider /lib/x86_64-linux-gnu/libgcc_s.so.1        /lib/x86_64-linux-gnu/
COPY --from=glibc-provider /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /lib/x86_64-linux-gnu/
RUN mkdir -p /lib64 && \
    ln -sf /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2

# Create directories for data and tools
RUN mkdir /datadir && mkdir /tools
VOLUME ["/datadir"]

# Copy stripped binary from build stage
COPY --from=binary-fetcher /bin/idena-node /bin/idena-node

# Copy tools and set permissions
COPY tools/*.* /tools/
RUN chmod +x /tools/*.sh

# Expose fixed container ports. Host-side ports remain configurable through
# docker run or docker compose port mappings.
EXPOSE 22 40405 9009

HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=12 \
  CMD sh -c 'nc -w1 127.0.0.1 22 </dev/null >/dev/null 2>&1 && nc -w1 127.0.0.1 9009 </dev/null >/dev/null 2>&1'

CMD ["/tools/start.sh"]
