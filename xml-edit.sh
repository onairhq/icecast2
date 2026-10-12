#!/bin/sh
set -eu

usage() {
    echo "Usage: $0 <tag> <value> <file>" >&2
    exit 2
}

[ "$#" -eq 3 ] || usage

tag="$1"
value="$2"
file="$3"

case "$tag" in
    ''|*[!a-zA-Z0-9_-]*)
        echo "ERROR: Invalid XML tag name: $tag" >&2
        exit 2
        ;;
esac

if [ ! -f "$file" ] || [ ! -r "$file" ] || [ ! -w "$file" ]; then
    echo "ERROR: Configuration file must be readable and writable: $file" >&2
    exit 1
fi

case "$value" in
    *'
'*)
        echo "ERROR: Newlines are not supported in XML values" >&2
        exit 2
        ;;
esac

# Escape XML special characters first.
value=$(printf '%s' "$value" |
    sed \
        -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g' \
        -e 's/"/\&quot;/g' \
        -e "s/'/\&apos;/g")

# Escape sed replacement characters. Use | as delimiter.
escaped_value=$(printf '%s' "$value" |
    sed \
        -e 's/\\/\\\\/g' \
        -e 's/|/\\|/g' \
        -e 's/&/\\&/g')

# Require exactly the simple opening/closing tag form.
if ! grep -Eq "<${tag}>[^<]*</${tag}>" "$file"; then
    echo "ERROR: Tag <${tag}>...</${tag}> not found in $file" >&2
    exit 1
fi

dir=$(dirname "$file")
tmp_file=$(mktemp "${dir}/.xml-edit.XXXXXX")

cleanup() {
    rm -f "$tmp_file"
}
trap cleanup EXIT HUP INT TERM

if ! sed \
    "s|<${tag}>[^<]*</${tag}>|<${tag}>${escaped_value}</${tag}>|g" \
    "$file" > "$tmp_file"; then
    echo "ERROR: Failed to edit tag $tag" >&2
    exit 1
fi

# Verify that the requested tag is still present in the result.
if ! grep -Eq "<${tag}>[^<]*</${tag}>" "$tmp_file"; then
    echo "ERROR: Tag $tag was not written correctly" >&2
    exit 1
fi

chmod 0600 "$tmp_file"
mv -f "$tmp_file" "$file"
trap - EXIT HUP INT TERM
