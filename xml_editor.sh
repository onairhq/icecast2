#!/usr/bin/env bash

set -e

xml_editor() {
    local tag="$1"
    local value="$2"
    local file="$3"

    sed -i "s|<${tag}>[^<]*</${tag}>|<${tag}>${value}</${tag}>|" "$file"
}

xml_editor "$@"
