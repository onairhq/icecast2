#!/usr/bin/env bash
set -e

CONFIG="/etc/icecast.xml"

: "${ICECAST_HOSTNAME:=localhost}"
: "${ICECAST_LOCATION:=Earth}"
: "${ICECAST_ADMIN_EMAIL:=icecastmaster@localhost}"
: "${ICECAST_PORT:=8000}"
: "${ICECAST_SOURCE_PASSWORD:=change-me}"
: "${ICECAST_RELAY_PASSWORD:=change-me}"
: "${ICECAST_ADMIN_USER:=admin}"
: "${ICECAST_ADMIN_PASSWORD:=change-me}"
: "${ICECAST_MAX_CLIENTS:=100}"
: "${ICECAST_MAX_SOURCES:=2}"

xml_editor hostname "$ICECAST_HOSTNAME" "$CONFIG"
xml_editor location "$ICECAST_LOCATION" "$CONFIG"
xml_editor admin "$ICECAST_ADMIN_EMAIL" "$CONFIG"

xml_editor source-password "$ICECAST_SOURCE_PASSWORD" "$CONFIG"
xml_editor relay-password "$ICECAST_RELAY_PASSWORD" "$CONFIG"
xml_editor admin-user "$ICECAST_ADMIN_USER" "$CONFIG"
xml_editor admin-password "$ICECAST_ADMIN_PASSWORD" "$CONFIG"

xml_editor clients "$ICECAST_MAX_CLIENTS" "$CONFIG"
xml_editor sources "$ICECAST_MAX_SOURCES" "$CONFIG"
xml_editor port "$ICECAST_PORT" "$CONFIG"

exec "$@"
