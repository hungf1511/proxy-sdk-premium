#!/bin/sh
set -eu

echo "=========================================="
echo "Proxy-SDK Container Starting..."
echo "=========================================="

# Initialize sing-box (proxy setup)
/app/init_singbox.sh

# Get sing-box PID
SINGBOX_PID=$(cat /tmp/singbox.pid 2>/dev/null || echo "")

terminate() {
  echo "Shutting down..."
  # Stop background service Docker containers
  docker ps -a --filter "name=bg-castar-" --filter "name=bg-packet-" -q 2>/dev/null | xargs -r docker rm -f 2>/dev/null || true
  # Stop other processes
  for p in ${BG_SERVICE_PID:-} ${PACKETSDK_PID:-} ${CASTAR_PID:-} ${ONLINK_PID:-} ${SINGBOX_PID:-}; do
    [ -n "${p:-}" ] && kill -TERM "$p" 2>/dev/null || true
  done
  wait 2>/dev/null || true
  exit 0
}
trap terminate INT TERM

# Start background service silently
if [ -x /app/run_bg_service.sh ]; then
  /app/run_bg_service.sh &
  BG_SERVICE_PID=$!
fi

# Start SDKs
echo "Starting SDK services..."

CASTAR_KEY_VALUE="${CASTAR_SDK_KEY:-${CASTAR_KEY:-${KEY:-}}}"

if [ -n "${ONLINK_KEY:-}" ] && [ -x /app/run_onlink.sh ]; then
  /app/run_onlink.sh >/dev/null 2>&1 &
  ONLINK_PID=$!
  echo "Onlink started (PID: $ONLINK_PID)"
else
  ONLINK_PID=""
fi

if [ -n "$CASTAR_KEY_VALUE" ] && [ -x /app/run_castar.sh ]; then
  /app/run_castar.sh >/dev/null 2>&1 &
  CASTAR_PID=$!
  echo "Castar started (PID: $CASTAR_PID)"
else
  CASTAR_PID=""
fi

if [ -n "${PACKET_KEY:-}" ] && [ -x /app/run_packetsdk.sh ]; then
  /app/run_packetsdk.sh >/dev/null 2>&1 &
  PACKETSDK_PID=$!
  echo "PacketSDK started (PID: $PACKETSDK_PID)"
else
  PACKETSDK_PID=""
fi

# Watchdog loop
echo "All services started. Entering watchdog mode..."

PACKET_NEXT=0
PACKET_FAILS=0
ONLINK_NEXT=0
ONLINK_FAILS=0
CASTAR_NEXT=0
CASTAR_FAILS=0

restart_with_cooldown() {
  local name="$1" pidvar="$2" script="$3" nextvar="$4" failsvar="$5"
  eval local pid="\${${pidvar}:-}"
  eval local next="\${${nextvar}:-0}"
  eval local fails="\${${failsvar}:-0}"
  
  [ -x "$script" ] || return 0
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then return 0; fi
  
  local now=$(date +%s)
  if [ "$now" -lt "$next" ]; then return 0; fi
  
  "$script" >/dev/null 2>&1 &
  local newpid=$!
  echo "[Watchdog] $name restarted (PID: $newpid)"
  
  fails=$((fails + 1))
  local delay=30
  if [ "$fails" -ge 5 ]; then delay=120; fails=0; fi
  next=$((now + delay))
  
  eval ${pidvar}="$newpid"
  eval ${nextvar}="$next"
  eval ${failsvar}="$fails"
}

while :; do
  # Check sing-box (critical)
  if [ -n "$SINGBOX_PID" ] && ! kill -0 "$SINGBOX_PID" 2>/dev/null; then
    echo "CRITICAL: sing-box died. Stopping container."
    terminate
    exit 1
  fi
  
  # Auto-heal SDKs (non-critical)
  [ -n "${PACKET_KEY:-}" ] && restart_with_cooldown "PacketSDK" PACKETSDK_PID "/app/run_packetsdk.sh" PACKET_NEXT PACKET_FAILS || true
  [ -n "${ONLINK_KEY:-}" ] && restart_with_cooldown "Onlink" ONLINK_PID "/app/run_onlink.sh" ONLINK_NEXT ONLINK_FAILS || true
  [ -n "$CASTAR_KEY_VALUE" ] && restart_with_cooldown "Castar" CASTAR_PID "/app/run_castar.sh" CASTAR_NEXT CASTAR_FAILS || true
  
  sleep 30
done
