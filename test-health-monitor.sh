#!/bin/bash
set -e

CONTAINER_NAME="${1:-proxy-sdk-0}"

if [ -z "$1" ]; then
  echo "Usage: $0 <container_name>"
  exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Error: Container '$CONTAINER_NAME' is not running"
  exit 1
fi

PROCESSES=$(docker exec "$CONTAINER_NAME" ps aux 2>/dev/null || echo "")

if echo "$PROCESSES" | grep -qE "CastarSdk_|onlinesdk_|PacketSDK_"; then
  echo "✓ Health monitor is running"
  exit 0
else
  echo "✗ Health monitor is not running"
  exit 1
fi
