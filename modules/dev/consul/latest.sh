#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"

if ! response="$(curl -fsSL "https://checkpoint-api.hashicorp.com/v1/check/consul")"; then
    tlog_error "latest:$CANONICAL_ID" "Failed to query the latest Consul version"

    exit 1
fi

if command -v jq >/dev/null 2>&1; then
    version="$(jq -r '.current_version // empty' <<<"$response" 2>/dev/null || true)"
else
    version="$(sed -n 's/.*"current_version" *: *"\([0-9][0-9A-Za-z.+-]*\)".*/\1/p' <<<"$response")"
fi

if [[ -z "$version" ]]; then
    tlog_error "latest:$CANONICAL_ID" "Failed to determine the latest Consul version"

    exit 1
fi

printf '%s\n' "$version"
