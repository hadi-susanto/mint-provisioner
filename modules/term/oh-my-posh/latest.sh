#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"

if ! version="$(curl -fsSL "https://cdn.ohmyposh.dev/releases/latest/version.txt")"; then
    tlog_error "latest:$CANONICAL_ID" "Failed to query the latest Oh My Posh version"

    exit 1
fi

version="${version//[[:space:]]/}"

if [[ ! "$version" =~ ^v?[0-9]+\.[0-9]+ ]]; then
    tlog_error "latest:$CANONICAL_ID" "Received an unexpected version value: %s" "${version:-<empty>}"

    exit 1
fi

printf '%s\n' "$version"
