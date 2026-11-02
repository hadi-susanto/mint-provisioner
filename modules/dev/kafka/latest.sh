#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"

index_url="https://downloads.apache.org/kafka/"

if ! index="$(curl -fsSL "$index_url")"; then
    tlog_error "latest:$CANONICAL_ID" "Failed to query the Apache Kafka release index"

    exit 1
fi

# The index lists only supported releases as x.y.z/ directories.
version="$(
    sed -n 's/.*href="\([0-9]*\.[0-9]*\.[0-9]*\)\/".*/\1/p' <<<"$index" |
        sort -V |
        tail -n 1
)"

if [[ -z "$version" ]]; then
    tlog_error "latest:$CANONICAL_ID" "Failed to determine the latest Apache Kafka version"

    exit 1
fi

printf '%s\n' "$version"
