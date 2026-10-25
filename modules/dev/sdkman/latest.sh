#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"

if ! version="$(curl -fsSL "https://api.sdkman.io/2/broker/version/sdkman/script/stable")"; then
    tlog_error "latest:$CANONICAL_ID" "Failed to query the latest SDKMAN! version"

    exit 1
fi

version="${version//[[:space:]]/}"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+ ]]; then
    tlog_error "latest:$CANONICAL_ID" "Received an unexpected version value: %s" "${version:-<empty>}"

    exit 1
fi

printf '%s\n' "$version"
