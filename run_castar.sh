#!/bin/sh
set -eu

CASTAR_KEY_VALUE="${CASTAR_SDK_KEY:-${CASTAR_KEY:-${KEY:-}}}"

if [ -z "$CASTAR_KEY_VALUE" ]; then
  echo "[CastarSDK] CASTAR_SDK_KEY not provided. Skipping."
  tail -f /dev/null
fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)        BIN="CastarSdk_amd64" ;;
  aarch64|arm64) BIN="CastarSdk_arm" ;;
  i386|i686)     BIN="CastarSdk_386" ;;
  *) echo "[CastarSDK] Unsupported arch $ARCH"; tail -f /dev/null ;;
esac

BIN_PATH="/opt/castar/$BIN"
[ -f "$BIN_PATH" ] || { echo "[CastarSDK] Binary $BIN_PATH not found"; tail -f /dev/null; }

chmod +x "$BIN_PATH" || true
echo "[CastarSDK] Starting $BIN with key length ${#CASTAR_KEY_VALUE}"
exec "$BIN_PATH" -key="$CASTAR_KEY_VALUE"



