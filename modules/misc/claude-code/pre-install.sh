#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"

install_asc_key \
    "$CANONICAL_ID" \
    "https://downloads.claude.ai/keys/claude-code.asc" \
    "https://downloads.claude.ai/claude-code/apt/stable" \
    "stable" \
    "main"
