#!/bin/sh
set -eu

ORIGINAL_CONFIG="/etc/icecast.xml"
RUNTIME_DIR="/var/lib/icecast"
RUNTIME_CONFIG="${RUNTIME_DIR}/icecast.xml"
XML_EDITOR="/usr/local/bin/xml-edit"

# Default values.
: "${ICECAST_HOSTNAME:=localhost}"
: "${ICECAST_LOCATION:=Earth}"
: "${ICECAST_ADMIN_EMAIL:=admin@example.com}"
: "${ICECAST_PORT:=8000}"
: "${ICECAST_SOURCE_PASSWORD:=change-this-source-password}"
: "${ICECAST_RELAY_PASSWORD:=change-this-relay-password}"

# Support both names for the administrator username.
if [ -n "${ICECAST_ADMIN_USER:-}" ]; then
    ICECAST_ADMIN_USERNAME="${ICECAST_ADMIN_USER}"
else
    : "${ICECAST_ADMIN_USERNAME:=admin}"
fi

: "${ICECAST_ADMIN_PASSWORD:=change-this-admin-password}"
: "${ICECAST_MAX_CLIENTS:=100}"
: "${ICECAST_MAX_SOURCES:=2}"

export ICECAST_HOSTNAME
export ICECAST_LOCATION
export ICECAST_ADMIN_EMAIL
export ICECAST_PORT
export ICECAST_SOURCE_PASSWORD
export ICECAST_RELAY_PASSWORD
export ICECAST_ADMIN_USERNAME
export ICECAST_ADMIN_PASSWORD
export ICECAST_MAX_CLIENTS
export ICECAST_MAX_SOURCES

if [ ! -r "$ORIGINAL_CONFIG" ]; then
    echo "ERROR: Cannot read $ORIGINAL_CONFIG" >&2
    exit 1
fi

if [ ! -d "$RUNTIME_DIR" ] || [ ! -w "$RUNTIME_DIR" ]; then
    echo "ERROR: Runtime directory is not writable: $RUNTIME_DIR" >&2
    exit 1
fi

if [ ! -x "$XML_EDITOR" ]; then
    echo "ERROR: XML editor is missing or not executable: $XML_EDITOR" >&2
    exit 1
fi

# Generate a fresh runtime config without modifying /etc/icecast.xml.
umask 077
cp "$ORIGINAL_CONFIG" "$RUNTIME_CONFIG"
chmod 0600 "$RUNTIME_CONFIG"

edit_config() {
    "$XML_EDITOR" "$1" "$2" "$RUNTIME_CONFIG"
}

edit_config hostname "$ICECAST_HOSTNAME"
edit_config location "$ICECAST_LOCATION"
edit_config admin "$ICECAST_ADMIN_EMAIL"
edit_config port "$ICECAST_PORT"
edit_config source-password "$ICECAST_SOURCE_PASSWORD"
edit_config relay-password "$ICECAST_RELAY_PASSWORD"
edit_config admin-user "$ICECAST_ADMIN_USERNAME"
edit_config admin-password "$ICECAST_ADMIN_PASSWORD"
edit_config clients "$ICECAST_MAX_CLIENTS"
edit_config sources "$ICECAST_MAX_SOURCES"

chmod 0600 "$RUNTIME_CONFIG"

echo "Starting Icecast as UID $(id -u), GID $(id -g)"
echo "Using runtime configuration: $RUNTIME_CONFIG"

exec "$@"
