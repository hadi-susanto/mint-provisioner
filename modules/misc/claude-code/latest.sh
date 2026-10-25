#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"

if ! version="$(curl -fsSL "https://downloads.claude.ai/claude-code-releases/latest")"; then
    tlog_error "latest:$CANONICAL_ID" "Failed to query the latest Claude Code version"

    exit 1
fi

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+[0-9A-Za-z.+-]*$ ]]; then
    tlog_error "latest:$CANONICAL_ID" "Received an unexpected version value: %s" "${version:-<empty>}"

    exit 1
fi

printf '%s\n' "$version"
