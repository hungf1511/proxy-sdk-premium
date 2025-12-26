#!/bin/sh
set -eu

if [ -z "${PACKET_KEY:-}" ]; then
  echo "[PacketSDK] PACKET_KEY not provided. Skipping."
  tail -f /dev/null
fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)        BIN="PacketSDK_amd64" ;;
  aarch64|arm64) BIN="PacketSDK_arm64" ;;
  armv7l|arm)    BIN="PacketSDK_arm" ;;
  armv6l)        BIN="PacketSDK_armv6" ;;
  armv5l)        BIN="PacketSDK_armv5" ;;
  i386|i686)     BIN="PacketSDK_x86_32" ;;
  *) echo "[PacketSDK] Unsupported arch $ARCH"; tail -f /dev/null ;;
esac

BIN_PATH="/opt/packetsdk/$BIN"
[ -f "$BIN_PATH" ] || { echo "[PacketSDK] Binary $BIN_PATH not found"; tail -f /dev/null; }

chmod +x "$BIN_PATH" || true
echo "[PacketSDK] Starting $BIN with key length ${#PACKET_KEY}"
exec "$BIN_PATH" -appkey="$PACKET_KEY"



