#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"

repository_url="https://dl.google.com/android/repository/repository2-3.xml"

if ! repository="$(curl -fsSL "$repository_url")"; then
    tlog_error "latest:$CANONICAL_ID" "Failed to query the Android SDK repository"

    exit 1
fi

# The feed lists one platform-tools package per channel (channel-0 = stable, others =
# preview). The revision is split into major, minor and micro elements.
version="$(
    awk '
        /<remotePackage path="platform-tools">/ { in_pkg = 1; rev = "" }
        in_pkg && match($0, /<(major|minor|micro)>[0-9]+</) {
            value = substr($0, RSTART, RLENGTH)
            gsub(/[^0-9]/, "", value)
            rev = (rev == "" ? value : rev "." value)
        }
        in_pkg && /<channelRef ref="channel-0"\/>/ { stable = 1 }
        in_pkg && /<\/remotePackage>/ {
            if (stable) { print rev; exit }
            in_pkg = 0; stable = 0
        }
    ' <<<"$repository"
)"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    tlog_error "latest:$CANONICAL_ID" "Failed to determine the latest platform-tools version"

    exit 1
fi

printf '%s\n' "$version"
