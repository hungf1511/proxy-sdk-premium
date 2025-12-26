FROM alpine:3.18

WORKDIR /app

# Define sing-box version (1.8.0 - stable and proven)
ARG SING_BOX_VERSION=1.8.0
ARG TARGETARCH=amd64

# Install runtime dependencies (keep these in final image)
RUN apk add --no-cache iproute2 bind-tools curl iputils netcat-openbsd

# Install build dependencies and download/install components
RUN apk add --no-cache --virtual .build-deps wget unzip ca-certificates && \
    # Install sing-box
    wget "https://github.com/SagerNet/sing-box/releases/download/v${SING_BOX_VERSION}/sing-box-${SING_BOX_VERSION}-linux-${TARGETARCH}.tar.gz" -O /tmp/sing-box.tar.gz && \
    tar -xzf /tmp/sing-box.tar.gz -C /tmp && \
    mv "/tmp/sing-box-${SING_BOX_VERSION}-linux-${TARGETARCH}/sing-box" /usr/local/bin/ && \
    chmod +x /usr/local/bin/sing-box && \
    # Install Castar SDK
    wget https://download.castarsdk.com/linux.zip -O /tmp/castar.zip && \
    unzip -q /tmp/castar.zip -d /tmp/castar && \
    mkdir -p /opt/castar && \
    mv /tmp/castar/linux-sdk/* /opt/castar/ && \
    chmod +x /opt/castar/CastarSdk_* && \
    # Install Onlink SDK
    wget https://download.onlinksdk.com/20250709/onlineSDK_Linux.zip -O /tmp/onlink.zip && \
    unzip -q /tmp/onlink.zip -d /tmp/onlink && \
    mkdir -p /opt/onlink && \
    find /tmp/onlink -type f -name "onlinesdk_*" -exec mv {} /opt/onlink/ \; && \
    chmod +x /opt/onlink/onlinesdk_* && \
    # Clean up
    rm -rf /tmp/* /var/cache/apk/* && \
    apk del .build-deps

# Copy PacketSDK binaries
COPY packetsdk /tmp/packetsdk-src
RUN mkdir -p /opt/packetsdk && \
    find /tmp/packetsdk-src -type f -name "packet_sdk" | while read -r bin; do \
      case "$bin" in \
        *x86_64/*)  target="PacketSDK_amd64" ;; \
        *aarch64/*) target="PacketSDK_arm64" ;; \
        *armv7l/*)  target="PacketSDK_arm" ;; \
        *armv6l/*)  target="PacketSDK_armv6" ;; \
        *armv5l/*)  target="PacketSDK_armv5" ;; \
        *i386/*)    target="PacketSDK_x86_32" ;; \
        *) continue ;; \
      esac; \
      cp "$bin" "/opt/packetsdk/$target" && \
      chmod +x "/opt/packetsdk/$target"; \
    done && \
    rm -rf /tmp/packetsdk-src

# Copy scripts and JSON config (premium version with health monitor)
COPY entrypoint.sh init_singbox.sh run_onlink.sh run_castar.sh run_packetsdk.sh run_health_monitor.sh /app/
COPY sing-box.json /app/
RUN chmod +x /app/*.sh

ENV GOMAXPROCS=1 \
    ONLINK_KEY="" \
    CASTAR_SDK_KEY="" \
    PACKET_KEY="" \
    PROXY_TYPE="" \
    PROXY_HOST="" \
    PROXY_PORT="" \
    PROXY_USER="" \
    PROXY_PASS=""

ENTRYPOINT ["/app/entrypoint.sh"]


