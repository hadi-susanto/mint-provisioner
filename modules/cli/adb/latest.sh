#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"

repository_url="https://dl.google.com/android/repository/repository2-3.xml"

if ! repository="$(curl -fsSL "$repository_url")"; then
    tlog_error "latest:$CANONICAL_ID" "Failed to query the Android SDK repository"

    exit 1
fi

# The platform-tools revision is split into major, minor and micro elements.
version="$(
    sed -n '/<remotePackage path="platform-tools">/,/<\/revision>/p' <<<"$repository" |
        sed -n 's/.*<\(major\|minor\|micro\)>\([0-9]*\)<.*/\2/p' |
        paste -sd '.'
)"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    tlog_error "latest:$CANONICAL_ID" "Failed to determine the latest platform-tools version"

    exit 1
fi

printf '%s\n' "$version"
