#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"

if ! response="$(curl -fsSL "https://pypi.org/pypi/openconnect-saml/json")"; then
    tlog_error "latest:$CANONICAL_ID" "Failed to query the latest openconnect-saml version from PyPI"

    exit 1
fi

if command -v jq >/dev/null 2>&1; then
    version="$(jq -r '.info.version // empty' <<<"$response" 2>/dev/null || true)"
else
    # Without jq, rely on info.version being the first "version" key in the response.
    version="$(grep -o -m 1 '"version": *"[^"]*"' <<<"$response" | head -n 1 || true)"
    version="${version%\"}"
    version="${version##*\"}"
fi

if [[ ! "$version" =~ ^[0-9]+(\.[0-9A-Za-z]+)+$ ]]; then
    tlog_error "latest:$CANONICAL_ID" "Failed to determine the latest openconnect-saml version"

    exit 1
fi

printf '%s\n' "$version"
