#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"

install_asc_key \
    "$CANONICAL_ID" \
    "https://cli.github.com/packages/githubcli-archive-keyring.gpg" \
    "https://cli.github.com/packages" \
    "stable" \
    "main"
