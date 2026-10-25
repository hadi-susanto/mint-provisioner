#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"

if ! response="$(curl -fsSL "https://dl.pstmn.io/api/version/latest?platform=linux64")"; then
    tlog_error "latest:$CANONICAL_ID" "Failed to query the latest Postman version"

    exit 1
fi

if command -v jq >/dev/null 2>&1; then
    version="$(jq -r '.version // empty' <<<"$response" 2>/dev/null || true)"
else
    version="$(sed -n 's/.*"version" *: *"\([0-9][0-9A-Za-z.+-]*\)".*/\1/p' <<<"$response")"
fi

if [[ -z "$version" ]]; then
    tlog_error "latest:$CANONICAL_ID" "Failed to determine the latest Postman version"

    exit 1
fi

printf '%s\n' "$version"
