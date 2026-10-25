#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"

metadata_url="https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/maven-metadata.xml"

if ! metadata="$(curl -fsSL "$metadata_url")"; then
    tlog_error "latest:$CANONICAL_ID" "Failed to query Apache Maven release metadata"

    exit 1
fi

# Keep only final x.y.z releases; the metadata also lists alpha, beta and rc builds.
version="$(
    sed -n 's/.*<version>\([0-9]*\.[0-9]*\.[0-9]*\)<\/version>.*/\1/p' <<<"$metadata" |
        sort -V |
        tail -n 1
)"

if [[ -z "$version" ]]; then
    tlog_error "latest:$CANONICAL_ID" "Failed to determine the latest Apache Maven version"

    exit 1
fi

printf '%s\n' "$version"
