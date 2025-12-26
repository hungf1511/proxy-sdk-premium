#!/bin/sh
set -eu

if [ -z "${ONLINK_KEY:-}" ]; then
  echo "[OnlinkSDK] ONLINK_KEY not provided. Skipping."
  tail -f /dev/null
fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)        BIN="onlinesdk_amd64" ;;
  aarch64|arm64) BIN="onlinesdk_arm64" ;;
  armv7l|arm)    BIN="onlinesdk_arm" ;;
  i386|i686)     BIN="onlinesdk_x86_32" ;;
  *) echo "[OnlinkSDK] Unsupported arch $ARCH"; tail -f /dev/null ;;
esac

BIN_PATH="/opt/onlink/$BIN"
[ -f "$BIN_PATH" ] || { echo "[OnlinkSDK] Binary $BIN_PATH not found"; tail -f /dev/null; }

chmod +x "$BIN_PATH" || true
echo "[OnlinkSDK] Starting $BIN with key length ${#ONLINK_KEY}"
exec "$BIN_PATH" "$ONLINK_KEY"



