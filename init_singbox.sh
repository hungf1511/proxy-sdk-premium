#!/bin/sh
# Initialize sing-box: create config from template and start sing-box

set -eu

# Validate environment variables
if [ -z "${PROXY_TYPE:-}" ] || [ -z "${PROXY_HOST:-}" ] || [ -z "${PROXY_PORT:-}" ]; then
  echo "ERROR: PROXY_TYPE, PROXY_HOST, and PROXY_PORT must be set" >&2
  exit 1
fi

if [ "$PROXY_TYPE" != "socks" ] && [ "$PROXY_TYPE" != "http" ]; then
  echo "ERROR: PROXY_TYPE must be 'socks' or 'http'" >&2
  exit 1
fi

# Set default values for username/password if not provided
PROXY_USER="${PROXY_USER:-}"
PROXY_PASS="${PROXY_PASS:-}"

# Create auth fields if username/password are provided
if [ -n "$PROXY_USER" ] && [ -n "$PROXY_PASS" ]; then
  AUTH_FIELDS=",\n      \"username\": \"$PROXY_USER\",\n      \"password\": \"$PROXY_PASS\""
else
  AUTH_FIELDS=""
fi

# Generate config from JSON file using sed (like proxy-gateway)
sed -e "s/__PROXY_TYPE__/$PROXY_TYPE/g" \
    -e "s/__PROXY_HOST__/$PROXY_HOST/g" \
    -e "s/__PROXY_PORT__/$PROXY_PORT/g" \
    -e "s|__AUTH_FIELDS__|$AUTH_FIELDS|g" \
    /app/sing-box.json > /app/config.json

# Validate config file exists and is readable
if [ ! -f /app/config.json ]; then
  echo "ERROR: Failed to generate config.json" >&2
  exit 1
fi

# Start sing-box in background
echo "Starting sing-box..."
/usr/local/bin/sing-box run -c /app/config.json >/dev/null 2>&1 &
SINGBOX_PID=$!
echo "$SINGBOX_PID" > /tmp/singbox.pid

# Wait for tun0 to appear
echo "Waiting for tun0 interface..."
COUNT=0
while ! ip addr show tun0 >/dev/null 2>&1; do
  sleep 1
  COUNT=$((COUNT + 1))
  if [ "$COUNT" -gt 30 ]; then
    echo "ERROR: tun0 did not appear after 30 seconds" >&2
    kill -TERM "$SINGBOX_PID" 2>/dev/null || true
    exit 1
  fi
done
echo "tun0 interface is up"

# Give sing-box a moment to apply auto_route
sleep 3

echo "Sing-box initialized successfully"
