#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"

download_page="https://deadbeef.sourceforge.io/download.html"

if ! page="$(curl -fsSL "$download_page")"; then
    tlog_error "latest:$CANONICAL_ID" "Failed to inspect %s" "$download_page"

    exit 1
fi

# The version includes the build suffix, such as 1.10.3-1.
version="$(grep -oP 'deadbeef-static_\K[0-9][0-9A-Za-z.+-]*(?=_x86_64\.tar\.bz2)' <<<"$page" | head -n 1 || true)"

if [[ -z "$version" ]]; then
    tlog_error "latest:$CANONICAL_ID" "Failed to determine the latest DeaDBeeF version"

    exit 1
fi

printf '%s\n' "$version"
